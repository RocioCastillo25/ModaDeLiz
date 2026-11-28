import 'package:flutter/painting.dart';

/// Paleta de CheckLizz: glassmorphism en rosa pastel y blanco, tomada del
/// logo de Moda D' Liz (sección 12 de `docs/project-context.md`).
/// Es la única fuente de colores: las pantallas no definen colores sueltos.
class AppColors {
  const AppColors._();

  // Fondo con degradado: rosa pastel arriba, blanco abajo.
  static const Color backgroundStart = Color(0xFFFFD9EA);
  static const Color backgroundEnd = Color(0xFFFFFFFF);

  // Acentos.
  static const Color pink = Color(0xFFD6338A); // rosa fuerte del logo
  static const Color pinkSoft = Color(0xFFF9A8D4); // rosa pastel
  static const Color violet = Color(0xFF7C5CE0); // foco y detalles
  static const Color cyan = Color(0xFF0E8FA3); // información
  static const Color amber = Color(0xFFA86400); // avisos

  // Superficies de vidrio: blanco translúcido, borde claro y sombra rosada.
  static const Color glass = Color(0x99FFFFFF); // 60 %
  static const Color glassBorder = Color(0xE6FFFFFF); // 90 %
  static const Color glassShadow = Color(0x26D6338A);
  static const Color fieldFill = Color(0xB3FFFFFF);
  static const Color fieldBorder = Color(0xFFE9B3D0);

  // Texto: ciruela oscuro sobre fondos claros (buen contraste).
  static const Color textPrimary = Color(0xFF3A1030);
  static const Color textSecondary = Color(0xFF6E4C62);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Estados.
  static const Color danger = Color(0xFFC0264F);
  static const Color disabled = Color(0xFFEAD7E2);

  /// Degradado del botón principal: rosa a rosa fuerte.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFEC5FA8), Color(0xFFC72A7F)],
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
