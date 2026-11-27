import '../../core/network/api_exception.dart';
import '../models/branch.dart';
import '../models/prenda.dart';
import '../models/prenda_ficha.dart';
import '../models/search_filters.dart';
import '../models/stock_item.dart';
import '../services/catalog_service.dart';
import 'branch_repository.dart';
import 'catalog_failure.dart';
import 'inventario_repository.dart';
import 'prenda_repository.dart';

/// Ejecuta [action] y traduce los errores de red a [CatalogFailure].
Future<T> _guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on ApiException catch (error) {
    throw CatalogFailure.fromApi(error);
  }
}

/// Catálogo de prendas contra la API real.
class ApiPrendaRepository implements PrendaRepository {
  ApiPrendaRepository(this._service);

  final CatalogService _service;

  @override
  Future<List<Prenda>> search(SearchFilters filters) => _guard(() async {
    final dtos = await _service.searchPrendas(filters);
    return [for (final dto in dtos) dto.toModel()];
  });

  @override
  Future<PrendaFicha> getById(int id) =>
      _guard(() async => (await _service.fetchFicha(id)).toModel());

  @override
  Future<PrendaFicha> getByBarcode(String barcode) => _guard(
    () async => (await _service.fetchFichaByBarcode(barcode)).toModel(),
  );
}

/// Ventas contra la API real.
class ApiInventarioRepository implements InventarioRepository {
  ApiInventarioRepository(this._service);

  final CatalogService _service;

  @override
  Future<StockItem> sell(int stockId, int quantity) =>
      _guard(() async => (await _service.sell(stockId, quantity)).toModel());
}

/// Sucursales contra la API real.
class ApiBranchRepository implements BranchRepository {
  ApiBranchRepository(this._service);

  final CatalogService _service;

  @override
  Future<List<Branch>> list() => _guard(() async {
    final dtos = await _service.fetchBranches();
    return [for (final dto in dtos) dto.toBranch()];
  });
}
