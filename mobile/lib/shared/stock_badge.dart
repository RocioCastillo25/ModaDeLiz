import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/stock_item.dart';

/// Muestra una cantidad de piezas con su estado. El estado se comunica con
/// ícono y texto, no solo con color ("Agotado", "Pocas piezas").
class StockBadge extends StatelessWidget {
  const StockBadge({
    super.key,
    required this.quantity,
    required this.level,
    this.compact = false,
  });

  final int quantity;
  final StockLevel level;

  /// Versión pequeña para las filas de la lista.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label, Color color) = switch (level) {
      StockLevel.outOfStock => (
        Icons.remove_circle_outline,
        'Agotado',
        AppColors.danger,
      ),
      StockLevel.low => (Icons.warning_amber_rounded, 'Pocas piezas', AppColors.amber),
      StockLevel.available => (Icons.check_circle_outline, 'Disponible', AppColors.cyan),
    };
    final text = level == StockLevel.outOfStock ? label : '$quantity · $label';
    return Semantics(
      label: '$quantity piezas, $label',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 16 : 20, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
