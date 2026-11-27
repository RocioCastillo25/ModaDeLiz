import '../models/prenda.dart';
import '../repositories/catalog_failure.dart';

/// Prenda tal como la entrega la API (`codigo_barras`, `descripcion`...).
class PrendaDto {
  const PrendaDto({
    required this.id,
    required this.barcode,
    required this.description,
    this.brand,
    this.category,
    this.season,
    this.photoUrl,
    this.alertThreshold,
    this.totalStock,
  });

  final int id;
  final String barcode;
  final String description;
  final String? brand;
  final String? category;
  final String? season;
  final String? photoUrl;
  final int? alertThreshold;
  final int? totalStock;

  /// Crea el DTO desde el JSON de la lista o de la ficha. Si falta un dato
  /// obligatorio, falla con [CatalogFailureType.server].
  factory PrendaDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final barcode = json['codigo_barras'];
    final description = json['descripcion'];
    if (id is! num ||
        barcode is! String ||
        description is! String ||
        description.trim().isEmpty) {
      throw const CatalogFailure(CatalogFailureType.server);
    }
    return PrendaDto(
      id: id.toInt(),
      barcode: barcode,
      description: description,
      brand: _text(json['marca']),
      category: _text(json['categoria']),
      season: _text(json['temporada']),
      photoUrl: _text(json['foto_url']),
      alertThreshold: (json['umbral_alerta'] as num?)?.toInt(),
      totalStock: (json['existencia_total'] as num?)?.toInt(),
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Adapter: convierte el DTO en el modelo [Prenda].
  Prenda toModel({int? totalStockOverride}) => Prenda(
    id: id,
    barcode: barcode,
    description: description,
    brand: brand,
    category: category,
    season: season,
    photoUrl: photoUrl,
    alertThreshold: alertThreshold ?? 2,
    totalStock: totalStockOverride ?? totalStock ?? 0,
  );
}
