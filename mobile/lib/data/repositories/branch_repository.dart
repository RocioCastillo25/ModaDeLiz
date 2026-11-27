import '../models/branch.dart';

/// Lista de sucursales para el filtro de búsqueda. Lanza `CatalogFailure`.
abstract class BranchRepository {
  Future<List<Branch>> list();
}
