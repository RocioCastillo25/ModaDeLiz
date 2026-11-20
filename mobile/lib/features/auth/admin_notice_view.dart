import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/glass_card.dart';
import '../../shared/gradient_background.dart';
import '../../shared/primary_button.dart';

/// Aviso para el administrador: su herramienta de trabajo es la página web.
class AdminNoticeView extends StatelessWidget {
  const AdminNoticeView({super.key, required this.onBack});

  /// Vuelve al formulario de inicio de sesión.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.laptop_chromebook,
                        size: 48,
                        color: AppColors.cyan,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Usa la página web',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tu cuenta de administradora trabaja desde la página '
                        'web de CheckLizz. Esta aplicación es para empleados '
                        'y gerentes de tienda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Volver al inicio de sesión',
                        onPressed: onBack,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
