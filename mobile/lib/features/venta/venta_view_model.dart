import 'package:flutter/foundation.dart';

import '../../data/models/prenda_ficha.dart';
import '../../data/models/stock_item.dart';
import '../../data/repositories/catalog_failure.dart';
import '../../data/repositories/inventario_repository.dart';
import '../../data/repositories/prenda_repository.dart';
import '../../data/services/connectivity_service.dart';

/// Pasos del descuento de piezas.
enum VentaStatus {
  /// Se elige la existencia y se escribe la cantidad.
  editing,

  /// Se muestran prenda, talla, color y cantidad para confirmar.
  confirming,

  /// La venta se está enviando; el botón queda deshabilitado.
  submitting,

  /// La API aceptó la venta.
  done,

  /// Falló el envío (sin conexión, permiso o servicio); se puede reintentar.
  error,

  /// La API rechazó la venta por existencia insuficiente.
  insufficient,
}

/// ViewModel del descuento de piezas por venta. No conoce widgets.
///
/// Solo valida lo mínimo (un entero positivo). La regla de la existencia la
/// aplica la API: ante un rechazo se consulta la existencia vigente y se
/// informa. La sucursal nunca se envía: la API la toma del usuario.
class VentaViewModel extends ChangeNotifier {
  VentaViewModel(
    this._inventario,
    this._prendas,
    this._connectivity, {
    required this.prendaId,
    required List<StockItem> options,
  }) : _options = List.of(options) {
    _selected = _firstSellable();
  }

  final InventarioRepository _inventario;
  final PrendaRepository _prendas;
  final ConnectivityService _connectivity;

  /// Prenda de la que se descuenta.
  final int prendaId;

  List<StockItem> _options;
  StockItem? _selected;
  String _quantityText = '';
  bool _touched = false;
  VentaStatus _status = VentaStatus.editing;
  String? _errorMessage;
  StockItem? _result;
  PrendaFicha? _latestFicha;
  bool _disposed = false;

  /// Existencias de la sucursal del usuario que se ofrecen para vender.
  List<StockItem> get options => List.unmodifiable(_options);
  StockItem? get selected => _selected;
  VentaStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Existencia que devolvió la API tras una venta aceptada.
  StockItem? get result => _result;

  /// Ficha vigente que se consultó tras un rechazo por existencia insuficiente.
  PrendaFicha? get latestFicha => _latestFicha;

  /// Cantidad válida o `null` si el texto no es un entero positivo.
  int? get quantity => _parse(_quantityText).$1;

  /// Mensaje de la cantidad inválida. Solo aparece después de escribir.
  String? get quantityError => _touched ? _parse(_quantityText).$2 : null;

  /// Aviso (no bloquea) cuando se pide más de lo que se ve; decide la API.
  String? get quantityWarning {
    final value = quantity;
    final item = _selected;
    if (value == null || item == null || value <= item.quantity) return null;
    if (item.quantity <= 0) return 'No quedan piezas de esta talla y color.';
    return 'Solo ${item.quantity == 1 ? 'hay 1 pieza' : 'hay ${item.quantity} piezas'}.';
  }

  /// `true` si se puede pasar a la confirmación.
  bool get canContinue =>
      _status == VentaStatus.editing && _selected != null && quantity != null;

  /// `true` si se puede enviar. Se deshabilita mientras hay un envío en curso.
  bool get canSubmit =>
      _status == VentaStatus.confirming || _status == VentaStatus.error;

  /// Resumen para la confirmación, por ejemplo `Talla M · Rosa · 2 piezas`.
  String get summary {
    final item = _selected;
    final value = quantity;
    if (item == null || value == null) return '';
    return 'Talla ${item.size} · ${item.color} · $value ${value == 1 ? 'pieza' : 'piezas'}';
  }

  /// Elige la existencia de la que se descuenta. Solo acepta las ofrecidas y
  /// que tengan piezas.
  void select(StockItem item) {
    if (_status != VentaStatus.editing) return;
    final match = _options.where((option) => option.id == item.id);
    if (match.isEmpty || match.first.quantity <= 0) return;
    _selected = match.first;
    _notify();
  }

  /// Guarda el texto de la cantidad y lo valida.
  void setQuantity(String text) {
    _quantityText = text;
    _touched = true;
    _notify();
  }

  /// Pasa a la confirmación si la cantidad es válida.
  void confirm() {
    if (!canContinue) return;
    _status = VentaStatus.confirming;
    _errorMessage = null;
    _notify();
  }

  /// Vuelve a editar la cantidad o la existencia.
  void backToEditing() {
    if (_status == VentaStatus.submitting || _status == VentaStatus.done) return;
    _status = VentaStatus.editing;
    _errorMessage = null;
    _notify();
  }

  /// Envía la venta. Ignora toques mientras hay un envío en curso.
  Future<void> submit() async {
    if (!canSubmit) return;
    final item = _selected;
    final value = quantity;
    if (item == null || value == null) return;

    _status = VentaStatus.submitting;
    _errorMessage = null;
    _notify();

    try {
      if (!await _connectivity.isOnline()) {
        _fail(const CatalogFailure(CatalogFailureType.network).message);
        return;
      }
      final updated = await _inventario.sell(item.id, value);
      _result = updated;
      _replace(updated);
      _status = VentaStatus.done;
    } on CatalogFailure catch (failure) {
      switch (failure.type) {
        case CatalogFailureType.insufficientStock:
          await _onInsufficient(item);
        case CatalogFailureType.forbidden:
          _fail('No tienes permiso para vender de esta sucursal.');
          return;
        default:
          _fail(failure.message);
          return;
      }
    } catch (_) {
      _fail(const CatalogFailure(CatalogFailureType.server).message);
      return;
    }
    _notify();
  }

  /// La API rechazó la venta: consulta la existencia vigente para informarla.
  Future<void> _onInsufficient(StockItem item) async {
    var message = const CatalogFailure(CatalogFailureType.insufficientStock).message;
    try {
      final ficha = await _prendas.getById(prendaId);
      _latestFicha = ficha;
      final current = ficha.stock.where((s) => s.id == item.id);
      if (current.isNotEmpty) {
        final quantity = current.first.quantity;
        _replace(current.first);
        message = quantity <= 0
            ? 'Ya no quedan piezas de esta talla y color.'
            : (quantity == 1 ? 'Solo queda 1 pieza.' : 'Solo quedan $quantity piezas.');
      }
    } on CatalogFailure {
      // Sin la existencia vigente se deja el aviso general.
    } catch (_) {
      // Igual que arriba.
    }
    _errorMessage = message;
    _status = VentaStatus.insufficient;
  }

  void _fail(String message) {
    _errorMessage = message;
    _status = VentaStatus.error;
    _notify();
  }

  /// Reemplaza una existencia por su valor más reciente.
  void _replace(StockItem updated) {
    _options = [for (final o in _options) o.id == updated.id ? updated : o];
    if (_selected?.id == updated.id) _selected = updated;
  }

  StockItem? _firstSellable() {
    for (final option in _options) {
      if (option.quantity > 0) return option;
    }
    return null;
  }

  /// Interpreta el texto: devuelve la cantidad o el mensaje de error.
  (int?, String?) _parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return (null, 'Escribe la cantidad.');
    if (!RegExp(r'^-?\d+$').hasMatch(text)) {
      return (null, 'Escribe un número entero.');
    }
    final value = int.tryParse(text);
    if (value == null) return (null, 'Escribe un número entero.');
    if (value <= 0) return (null, 'La cantidad debe ser mayor que cero.');
    return (value, null);
  }

  /// Limpia todo el estado (por ejemplo, al cerrar sesión).
  void reset() {
    _quantityText = '';
    _touched = false;
    _status = VentaStatus.editing;
    _errorMessage = null;
    _result = null;
    _latestFicha = null;
    _selected = _firstSellable();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
