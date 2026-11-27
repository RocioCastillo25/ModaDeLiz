import '../models/prenda.dart';
import '../models/prenda_ficha.dart';
import '../models/search_filters.dart';

/// Único punto de acceso al catálogo de prendas para los ViewModels.
///
/// Tiene una implementación real (contra la API) y otra simulada, que se
/// intercambian desde el registro de dependencias. Lanza `CatalogFailure`.
abstract class PrendaRepository {
  /// Busca prendas con los filtros dados.
  Future<List<Prenda>> search(SearchFilters filters);

  /// Ficha con las existencias de las 5 sucursales (`notFound` si no existe).
  Future<PrendaFicha> getById(int id);

  /// Ficha a partir del código de barras (`notFound` si no corresponde a
  /// ninguna prenda).
  Future<PrendaFicha> getByBarcode(String barcode);
}
