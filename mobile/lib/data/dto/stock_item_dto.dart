import '../models/stock_item.dart';
import '../repositories/catalog_failure.dart';

/// Existencia tal como la entrega la API (`id_sucursal`, `talla`, `cantidad`...).
class StockItemDto {
  const StockItemDto({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.size,
    required this.color,
    required this.quantity,
  });

  final int id;
  final int branchId;
  final String branchName;
  final String size;
  final String color;
  final int quantity;

  /// Crea el DTO desde el JSON. Si falta un dato, falla con
  /// [CatalogFailureType.server].
  factory StockItemDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final branchId = json['id_sucursal'];
    final branchName = json['sucursal'];
    final size = json['talla'];
    final color = json['color'];
    final quantity = json['cantidad'];
    if (id is! num ||
        branchId is! num ||
        branchName is! String ||
        size is! String ||
        color is! String ||
        quantity is! num) {
      throw const CatalogFailure(CatalogFailureType.server);
    }
    return StockItemDto(
      id: id.toInt(),
      branchId: branchId.toInt(),
      branchName: branchName,
      size: size,
      color: color,
      quantity: quantity.toInt() < 0 ? 0 : quantity.toInt(),
    );
  }

  /// Adapter: convierte el DTO en el modelo [StockItem].
  StockItem toModel() => StockItem(
    id: id,
    branchId: branchId.toString(),
    branchName: branchName,
    size: size,
    color: color,
    quantity: quantity,
  );
}
