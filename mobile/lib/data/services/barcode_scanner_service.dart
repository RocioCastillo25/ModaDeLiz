import 'package:flutter/widgets.dart';

/// Problemas que el escáner puede informar.
enum ScannerError {
  /// El usuario negó el permiso de cámara.
  permissionDenied,

  /// La cámara no está disponible (no existe, está en uso o falló).
  unavailable,
}

/// Interfaz propia del escáner de códigos (patrón Adapter). Las pantallas y
/// los ViewModels solo conocen esta interfaz, nunca la librería de cámara.
abstract class BarcodeScannerService {
  /// Códigos leídos, sin repeticiones consecutivas del mismo valor.
  Stream<String> get codes;

  /// Problemas de cámara (permiso negado o cámara no disponible).
  Stream<ScannerError> get errors;

  /// Prepara la cámara. La solicitud de permiso del sistema aparece cuando la
  /// vista previa ([buildPreview]) se muestra; si se niega, se informa por
  /// [errors].
  Future<void> start();

  Future<void> stop();

  /// Enciende o apaga la linterna. No hace nada si el dispositivo no la tiene.
  Future<void> toggleTorch();

  /// Vista previa de la cámara. Es la única forma en que las pantallas la ven.
  Widget buildPreview(BuildContext context);

  Future<void> dispose();
}
