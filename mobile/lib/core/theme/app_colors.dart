import 'package:flutter/painting.dart';

/// Paleta de CheckLizz (sección 12 de `docs/project-context.md`).
/// Es la única fuente de colores: las pantallas no definen colores sueltos.
class AppColors {
  const AppColors._();

  // Fondo con degradado.
  static const Color backgroundStart = Color(0xFF1B1035);
  static const Color backgroundEnd = Color(0xFF3A1561);

  // Acentos.
  static const Color pink = Color(0xFFFF5FA2);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF38D6E8);
  static const Color amber = Color(0xFFFFB86B);

  // Superficies de vidrio: blanco con transparencia, borde sutil.
  static const Color glass = Color(0x1AFFFFFF); // 10 %
  static const Color glassBorder = Color(0x33FFFFFF); // 20 %

  // Texto.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB8FFFFFF); // 72 %

  // Estados.
  static const Color danger = Color(0xFFFF7A8A);
  static const Color disabled = Color(0x33FFFFFF);

  /// Degradado del botón principal: rosa a violeta.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pink, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Degradado del fondo de las pantallas.
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundStart, backgroundEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
