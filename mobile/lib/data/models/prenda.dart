import 'stock_item.dart';

/// Prenda del catálogo (resumen que se muestra en la lista de resultados).
class Prenda {
  const Prenda({
    required this.id,
    required this.barcode,
    required this.description,
    this.brand,
    this.category,
    this.season,
    this.photoUrl,
    this.alertThreshold = 2,
    this.totalStock = 0,
  });

  final int id;
  final String barcode;

  /// Nombre o descripción de la prenda.
  final String description;
  final String? brand;
  final String? category;
  final String? season;
  final String? photoUrl;

  /// Piezas a partir de las cuales la existencia se considera baja.
  final int alertThreshold;

  /// Existencia total informada por la API.
  final int totalStock;

  /// Estado de la existencia total: agotada, baja o disponible.
  StockLevel get stockLevel {
    if (totalStock <= 0) return StockLevel.outOfStock;
    if (totalStock <= alertThreshold) return StockLevel.low;
    return StockLevel.available;
  }
}
