import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/prenda_ficha.dart';
import '../../data/repositories/catalog_failure.dart';
import '../../data/repositories/prenda_repository.dart';
import '../../data/services/barcode_scanner_service.dart';

/// Estados visibles del escáner.
enum EscanerStatus {
  /// Se explica el uso de la cámara antes de pedir el permiso.
  explaining,

  /// La cámara está activa y espera un código.
  scanning,

  /// Se consulta la prenda del código leído.
  resolving,

  /// Se encontró la prenda: la pantalla abre su ficha.
  found,

  /// El código no corresponde a ninguna prenda.
  notFound,

  /// Falló la consulta (sin conexión o servicio caído).
  error,

  /// El usuario negó el permiso de cámara.
  permissionDenied,

  /// La cámara no está disponible.
  unavailable,
}

/// ViewModel del escáner de códigos. No conoce widgets ni la cámara: usa
/// `BarcodeScannerService`.
class EscanerViewModel extends ChangeNotifier {
  EscanerViewModel(
    this._scanner,
    this._prendas, {
    DateTime Function()? clock,
    this.repeatWindow = const Duration(seconds: 2),
  }) : _clock = clock ?? DateTime.now;

  final BarcodeScannerService _scanner;
  final PrendaRepository _prendas;
  final DateTime Function() _clock;

  /// Tiempo en que se ignora el mismo código tras abrir su ficha, para que un
  /// código que sigue frente a la cámara no abra la ficha otra vez.
  final Duration repeatWindow;

  EscanerStatus _status = EscanerStatus.explaining;
  String? _message;
  String? _manualError;
  PrendaFicha? _foundFicha;
  bool _torchOn = false;
  String? _lastCode;
  DateTime? _lastAt;
  StreamSubscription<String>? _codeSub;
  StreamSubscription<ScannerError>? _errorSub;
  bool _disposed = false;

  EscanerStatus get status => _status;

  /// Mensaje en español del aviso o error actual, sin detalles técnicos.
  String? get message => _message;

  /// Aviso de la búsqueda manual (por ejemplo, código vacío).
  String? get manualError => _manualError;

  /// Ficha encontrada, para abrirla.
  PrendaFicha? get foundFicha => _foundFicha;
  bool get torchOn => _torchOn;

  /// `true` si se ofrece escribir el código a mano.
  bool get canLookUpManually =>
      _status == EscanerStatus.permissionDenied ||
      _status == EscanerStatus.unavailable;

  /// Inicia la cámara (el sistema pide el permiso en ese momento).
  Future<void> start() async {
    _listen();
    _status = EscanerStatus.scanning;
    _message = null;
    _notify();
    await _scanner.start();
  }

  void _listen() {
    _codeSub ??= _scanner.codes.listen(_onCode);
    _errorSub ??= _scanner.errors.listen((error) {
      if (_status == EscanerStatus.found || _status == EscanerStatus.resolving) {
        return;
      }
      _status = error == ScannerError.permissionDenied
          ? EscanerStatus.permissionDenied
          : EscanerStatus.unavailable;
      _message = null;
      _notify();
    });
  }

  Future<void> _onCode(String raw) async {
    final code = raw.trim();
    if (code.isEmpty || _status != EscanerStatus.scanning) return;
    if (_isRepeat(code)) return;
    await _resolve(code);
  }

  bool _isRepeat(String code) {
    final at = _lastAt;
    return code == _lastCode &&
        at != null &&
        _clock().difference(at) < repeatWindow;
  }

  /// Busca la prenda escribiendo el código a mano.
  Future<void> lookUp(String raw) async {
    final code = raw.trim();
    if (code.isEmpty) {
      _manualError = 'Escribe el código de la etiqueta.';
      _notify();
      return;
    }
    _manualError = null;
    await _resolve(code);
  }

  Future<void> _resolve(String code) async {
    _lastCode = code;
    _lastAt = _clock();
    _status = EscanerStatus.resolving;
    _message = null;
    _notify();
    try {
      _foundFicha = await _prendas.getByBarcode(code);
      _status = EscanerStatus.found;
    } on CatalogFailure catch (failure) {
      _message = failure.message;
      _status = failure.type == CatalogFailureType.notFound
          ? EscanerStatus.notFound
          : EscanerStatus.error;
    } catch (_) {
      _message = const CatalogFailure(CatalogFailureType.server).message;
      _status = EscanerStatus.error;
    }
    _notify();
  }

  /// Vuelve a escanear tras un aviso o un error.
  void rescan() {
    _status = EscanerStatus.scanning;
    _message = null;
    _foundFicha = null;
    _lastAt = _clock();
    _notify();
  }

  /// Vuelve a escanear tras ver la ficha encontrada.
  void resume() => rescan();

  /// Enciende o apaga la linterna.
  Future<void> toggleTorch() async {
    await _scanner.toggleTorch();
    _torchOn = !_torchOn;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _codeSub?.cancel();
    _errorSub?.cancel();
    _scanner.dispose();
    super.dispose();
  }
}
