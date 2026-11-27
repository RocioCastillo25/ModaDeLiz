import '../models/prenda_ficha.dart';
import '../models/stock_item.dart';
import '../repositories/catalog_failure.dart';
import 'prenda_dto.dart';
import 'stock_item_dto.dart';

/// Ficha tal como la entrega la API: datos de la prenda y `existencias`.
class PrendaFichaDto {
  const PrendaFichaDto({required this.prenda, required this.stock});

  final PrendaDto prenda;
  final List<StockItemDto> stock;

  factory PrendaFichaDto.fromJson(Map<String, dynamic> json) {
    final rawStock = json['existencias'];
    if (rawStock != null && rawStock is! List) {
      throw const CatalogFailure(CatalogFailureType.server);
    }
    final items = <StockItemDto>[
      for (final entry in (rawStock as List<dynamic>? ?? const []))
        if (entry is Map<String, dynamic>)
          StockItemDto.fromJson(entry)
        else
          throw const CatalogFailure(CatalogFailureType.server),
    ];
    return PrendaFichaDto(prenda: PrendaDto.fromJson(json), stock: items);
  }

  /// Adapter: convierte el DTO en el modelo [PrendaFicha].
  PrendaFicha toModel() {
    final items = <StockItem>[for (final item in stock) item.toModel()];
    final total = items.fold<int>(0, (sum, item) => sum + item.quantity);
    return PrendaFicha(
      prenda: prenda.toModel(totalStockOverride: total),
      stock: items,
    );
  }
}
