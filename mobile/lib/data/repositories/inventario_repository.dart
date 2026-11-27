import '../models/stock_item.dart';

/// Único punto de acceso a las ventas (descuento de piezas).
///
/// Tiene una implementación real y otra simulada. Lanza `CatalogFailure`.
abstract class InventarioRepository {
  /// Descuenta [quantity] piezas de la existencia [stockId] y devuelve la
  /// existencia que informa la API.
  ///
  /// Fallos: `insufficientStock`, `forbidden`, `invalid`, `network`, `server`.
  Future<StockItem> sell(int stockId, int quantity);
}
