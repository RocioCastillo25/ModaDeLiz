import 'package:flutter/foundation.dart';

import '../../data/models/prenda_ficha.dart';
import '../../data/models/stock_item.dart';
import '../../data/repositories/catalog_failure.dart';
import '../../data/repositories/prenda_repository.dart';
import '../auth/session_view_model.dart';

/// Estado visible de la ficha: cargando, con datos o con error.
enum FichaStatus { loading, data, error }

/// ViewModel de la ficha de una prenda. No conoce widgets.
///
/// Hay uno por ficha abierta: se crea con una fábrica y se descarta al salir.
class FichaViewModel extends ChangeNotifier {
  FichaViewModel(this._prendas, this._session);

  final PrendaRepository _prendas;
  final SessionViewModel _session;

  FichaStatus _status = FichaStatus.loading;
  PrendaFicha? _ficha;
  String? _errorMessage;
  String? _refreshError;
  Future<PrendaFicha> Function()? _source;
  int _requestId = 0;
  bool _disposed = false;

  FichaStatus get status => _status;
  PrendaFicha? get ficha => _ficha;

  /// Mensaje del error que impidió mostrar la ficha.
  String? get errorMessage => _errorMessage;

  /// Mensaje de un fallo al actualizar cuando ya había datos en pantalla.
  String? get refreshError => _refreshError;

  /// Sucursal del usuario autenticado. Sale de la sesión, nunca de un campo
  /// editable.
  String? get ownBranchId => _session.session?.user.branch?.id;

  /// Existencias de la sucursal del usuario: las únicas que se pueden vender.
  List<StockItem> get ownStock =>
      _ficha?.stockOfBranch(ownBranchId) ?? const [];

  /// `true` si el usuario tiene sucursal y hay existencias propias.
  bool get canSell => ownBranchId != null && ownStock.isNotEmpty;

  /// Indica si la existencia es de la sucursal del usuario.
  bool isOwn(StockItem item) => item.belongsTo(ownBranchId);

  /// Estado de una existencia según el umbral de alerta de la prenda.
  StockLevel levelOf(StockItem item) =>
      item.levelFor(_ficha?.prenda.alertThreshold ?? 2);

  /// Carga la ficha por identificador.
  Future<void> load(int id) => _fetch(() => _prendas.getById(id));

  /// Carga la ficha por código de barras.
  Future<void> loadByBarcode(String barcode) =>
      _fetch(() => _prendas.getByBarcode(barcode));

  /// Vuelve a pedir la ficha (jalar para actualizar o "Reintentar"). Si ya
  /// había datos y falla, los conserva y guarda el aviso en [refreshError].
  Future<void> refresh() async {
    final source = _source;
    if (source == null) return;
    await _fetch(source);
  }

  Future<void> _fetch(Future<PrendaFicha> Function() source) async {
    _source = source;
    final id = ++_requestId;
    final hadData = _ficha != null;
    if (!hadData) {
      _status = FichaStatus.loading;
      _errorMessage = null;
      _notify();
    }
    _refreshError = null;
    try {
      final ficha = await source();
      if (id != _requestId) return;
      _ficha = ficha;
      _errorMessage = null;
      _status = FichaStatus.data;
    } on CatalogFailure catch (failure) {
      if (id != _requestId) return;
      _onError(failure.message, hadData);
    } catch (_) {
      if (id != _requestId) return;
      _onError(
        const CatalogFailure(CatalogFailureType.server).message,
        hadData,
      );
    }
    _notify();
  }

  void _onError(String message, bool hadData) {
    if (hadData) {
      _refreshError = message;
      _status = FichaStatus.data;
    } else {
      _errorMessage = message;
      _status = FichaStatus.error;
    }
  }

  /// Reemplaza una existencia con el dato que devolvió la API tras una venta.
  void applySale(StockItem updated) {
    final current = _ficha;
    if (current == null) return;
    _ficha = current.withStockItem(updated);
    _notify();
  }

  /// Quita el aviso de fallo al actualizar una vez mostrado.
  void clearRefreshError() {
    if (_refreshError == null) return;
    _refreshError = null;
    _notify();
  }

  /// Limpia todo el estado (por ejemplo, al cerrar sesión).
  void reset() {
    _requestId++;
    _ficha = null;
    _source = null;
    _errorMessage = null;
    _refreshError = null;
    _status = FichaStatus.loading;
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
