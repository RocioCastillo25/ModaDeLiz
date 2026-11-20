import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/motion.dart';

/// Botón principal: degradado rosa a violeta, grande y con foco visible.
///
/// Se deshabilita si [onPressed] es `null` y muestra un indicador cuando
/// [isLoading] es `true` (evita el doble envío).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final radius = BorderRadius.circular(16);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.isLoading ? '${widget.label}, cargando' : widget.label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: Motion.of(context),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : AppColors.disabled,
          borderRadius: radius,
          border: Border.all(
            color: _focused ? AppColors.violet : Colors.transparent,
            width: 3,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? widget.onPressed : null,
            onFocusChange: (value) => setState(() => _focused = value),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? AppColors.onPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
