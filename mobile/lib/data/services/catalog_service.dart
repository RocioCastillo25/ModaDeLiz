import '../../core/network/api_client.dart';
import '../dto/branch_dto.dart';
import '../dto/prenda_dto.dart';
import '../dto/prenda_ficha_dto.dart';
import '../dto/stock_item_dto.dart';
import '../models/search_filters.dart';

/// Llamadas HTTP del catálogo, el inventario y las ventas, según
/// `docs/openapi.yaml`. El token lo agrega el interceptor.
class CatalogService {
  CatalogService(this._client);

  final ApiClient _client;

  /// `GET /prendas` con los filtros indicados; no envía los que están vacíos.
  Future<List<PrendaDto>> searchPrendas(SearchFilters filters) async {
    final query = <String, dynamic>{
      if (filters.query.isNotEmpty) 'q': filters.query,
      if (filters.size != null) 'talla': filters.size,
      if (filters.color != null) 'color': filters.color,
      if (filters.branchId != null) 'sucursalId': filters.branchId,
    };
    final list = await _client.getList('/prendas', query: query);
    return list
        .whereType<Map<String, dynamic>>()
        .map(PrendaDto.fromJson)
        .toList();
  }

  /// `GET /prendas/{id}`.
  Future<PrendaFichaDto> fetchFicha(int id) async {
    final json = await _client.get('/prendas/$id');
    return PrendaFichaDto.fromJson(json);
  }

  /// `GET /prendas/codigo/{codigo}`. El código se codifica para la ruta.
  Future<PrendaFichaDto> fetchFichaByBarcode(String barcode) async {
    final json = await _client.get(
      '/prendas/codigo/${Uri.encodeComponent(barcode)}',
    );
    return PrendaFichaDto.fromJson(json);
  }

  /// `POST /ventas`. La sucursal no se envía: la API la toma del usuario.
  Future<StockItemDto> sell(int stockId, int quantity) async {
    final json = await _client.post(
      '/ventas',
      data: {'idInventario': stockId, 'cantidad': quantity},
    );
    return StockItemDto.fromJson(json);
  }

  /// `GET /sucursales`.
  Future<List<BranchDto>> fetchBranches() async {
    final list = await _client.getList('/sucursales');
    return list
        .whereType<Map<String, dynamic>>()
        .map(BranchDto.fromJson)
        .toList();
  }
}
