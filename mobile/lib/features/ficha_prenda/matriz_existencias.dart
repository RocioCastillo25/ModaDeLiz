import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/stock_item.dart';
import '../../shared/stock_badge.dart';

/// Matriz de existencias: una tarjeta por sucursal con su desglose por talla y
/// color. La sucursal del usuario aparece destacada y primero.
class MatrizExistencias extends StatelessWidget {
  const MatrizExistencias({
    super.key,
    required this.stock,
    required this.ownBranchId,
    required this.levelOf,
  });

  final List<StockItem> stock;
  final String? ownBranchId;
  final StockLevel Function(StockItem item) levelOf;

  @override
  Widget build(BuildContext context) {
    final byBranch = <String, List<StockItem>>{};
    for (final item in stock) {
      byBranch.putIfAbsent(item.branchId, () => []).add(item);
    }
    final ids = byBranch.keys.toList()
      ..sort((a, b) {
        if (a == ownBranchId) return -1;
        if (b == ownBranchId) return 1;
        return byBranch[a]!.first.branchName.compareTo(
          byBranch[b]!.first.branchName,
        );
      });
    if (ids.isEmpty) {
      return const Text(
        'Esta prenda aún no tiene existencias registradas.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: [
        for (final id in ids) ...[
          _BranchBlock(
            items: byBranch[id]!,
            isOwn: id == ownBranchId,
            levelOf: levelOf,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BranchBlock extends StatelessWidget {
  const _BranchBlock({
    required this.items,
    required this.isOwn,
    required this.levelOf,
  });

  final List<StockItem> items;
  final bool isOwn;
  final StockLevel Function(StockItem item) levelOf;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final name = items.first.branchName;
    return Semantics(
      container: true,
      label: isOwn ? 'Tu sucursal, $name, $total piezas' : '$name, $total piezas',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isOwn
              ? AppColors.pinkSoft.withValues(alpha: 0.28)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOwn ? AppColors.pink : AppColors.glassBorder,
            width: isOwn ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOwn ? Icons.storefront : Icons.store_mall_directory_outlined,
                  color: AppColors.pink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isOwn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tu sucursal',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Talla ${item.size} · ${item.color}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: StockBadge(
                          quantity: item.quantity,
                          level: levelOf(item),
                          compact: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
