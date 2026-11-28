import 'package:flutter/widgets.dart';

/// Utilidades de movimiento. Respetan la preferencia del sistema de reducir
/// animaciones.
class Motion {
  const Motion._();

  /// Duración breve por defecto de las animaciones.
  static const Duration short = Duration(milliseconds: 200);

  /// Devuelve [duration], o cero si el usuario pidió reducir animaciones.
  static Duration of(BuildContext context, [Duration duration = short]) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}
