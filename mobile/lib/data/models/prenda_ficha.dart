import 'prenda.dart';
import 'stock_item.dart';

/// Ficha de una prenda: sus datos y la existencia en las 5 sucursales.
class PrendaFicha {
  const PrendaFicha({required this.prenda, required this.stock});

  final Prenda prenda;

  /// Existencias por sucursal, talla y color.
  final List<StockItem> stock;

  /// Total de piezas de todas las sucursales.
  int get totalStock => stock.fold(0, (sum, item) => sum + item.quantity);

  /// Existencias de la sucursal [branchId].
  List<StockItem> stockOfBranch(String? branchId) =>
      stock.where((item) => item.belongsTo(branchId)).toList();

  /// Ficha con una existencia reemplazada (por ejemplo, tras una venta).
  PrendaFicha withStockItem(StockItem updated) => PrendaFicha(
    prenda: prenda,
    stock: [for (final item in stock) item.id == updated.id ? updated : item],
  );
}
