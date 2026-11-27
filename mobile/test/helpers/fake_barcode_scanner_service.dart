import 'dart:async';

import 'package:checklizz/data/services/barcode_scanner_service.dart';
import 'package:flutter/widgets.dart';

/// Escáner falso para pruebas: no usa la cámara; los códigos y los errores se
/// emiten a mano.
class FakeBarcodeScannerService implements BarcodeScannerService {
  final StreamController<String> _codes = StreamController<String>.broadcast();
  final StreamController<ScannerError> _errors =
      StreamController<ScannerError>.broadcast();

  int startCalls = 0;
  int stopCalls = 0;
  int torchToggles = 0;
  bool disposed = false;

  @override
  Stream<String> get codes => _codes.stream;

  @override
  Stream<ScannerError> get errors => _errors.stream;

  /// Simula que la cámara leyó un código.
  void emit(String code) => _codes.add(code);

  /// Simula un problema de cámara.
  void emitError(ScannerError error) => _errors.add(error);

  @override
  Future<void> start() async => startCalls++;

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> toggleTorch() async => torchToggles++;

  @override
  Widget buildPreview(BuildContext context) =>
      const SizedBox.expand(key: ValueKey('vista-previa-falsa'));

  @override
  Future<void> dispose() async {
    disposed = true;
    await _codes.close();
    await _errors.close();
  }
}
