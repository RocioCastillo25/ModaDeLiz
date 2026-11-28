import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'barcode_scanner_service.dart';

/// Adapter de `mobile_scanner` detrás de [BarcodeScannerService]. Es el único
/// archivo de la app que importa la librería de la cámara.
///
/// La cámara y la solicitud de permiso empiezan cuando la vista previa
/// ([buildPreview]) aparece en pantalla, es decir, al abrir el escáner.
class MobileScannerService implements BarcodeScannerService {
  MobileScannerService({MobileScannerController? controller})
    : _controller =
          controller ??
          MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates) {
    _controller.addListener(_onStateChanged);
  }

  final MobileScannerController _controller;
  final StreamController<String> _codes = StreamController<String>.broadcast();
  final StreamController<ScannerError> _errors =
      StreamController<ScannerError>.broadcast();

  MobileScannerException? _lastError;
  String? _lastCode;
  DateTime? _lastCodeAt;
  bool _disposed = false;

  @override
  Stream<String> get codes => _codes.stream;

  @override
  Stream<ScannerError> get errors => _errors.stream;

  @override
  Future<void> start() async {
    // La cámara se inicia sola cuando la vista previa entra en pantalla.
  }

  @override
  Future<void> stop() async {
    try {
      await _controller.stop();
    } catch (_) {
      // Si la cámara ya estaba detenida no hay nada que hacer.
    }
  }

  @override
  Future<void> toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } catch (_) {
      // Un dispositivo sin linterna no hace nada.
    }
  }

  @override
  Widget buildPreview(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      fit: BoxFit.cover,
      onDetect: _onDetect,
      errorBuilder: (context, error) => const SizedBox.shrink(),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.trim().isEmpty) continue;
      final now = DateTime.now();
      // Evita repetir el mismo código en cada fotograma.
      if (value == _lastCode &&
          _lastCodeAt != null &&
          now.difference(_lastCodeAt!) < const Duration(seconds: 2)) {
        return;
      }
      _lastCode = value;
      _lastCodeAt = now;
      if (!_codes.isClosed) _codes.add(value);
      return;
    }
  }

  void _onStateChanged() {
    final error = _controller.value.error;
    if (error == null || identical(error, _lastError) || _errors.isClosed) {
      return;
    }
    _lastError = error;
    _errors.add(
      error.errorCode == MobileScannerErrorCode.permissionDenied
          ? ScannerError.permissionDenied
          : ScannerError.unavailable,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_onStateChanged);
    await _codes.close();
    await _errors.close();
    try {
      await _controller.dispose();
    } catch (_) {
      // Ya estaba liberada.
    }
  }
}
