import '../models/branch.dart';
import '../models/prenda.dart';
import '../models/prenda_ficha.dart';
import '../models/search_filters.dart';
import '../models/stock_item.dart';
import 'branch_repository.dart';
import 'catalog_failure.dart';
import 'inventario_repository.dart';
import 'prenda_repository.dart';

/// Datos de ejemplo compartidos por los repositorios simulados, para que una
/// venta se vea después en la ficha. Todo es de PRUEBA.
class MockCatalogStore {
  MockCatalogStore({this.delay = const Duration(milliseconds: 300)})
    : _stock = _initialStock();

  /// Espera simulada de la red.
  final Duration delay;

  /// Sucursales de ejemplo. Los identificadores coinciden con los de los
  /// usuarios de `MockAuthRepository`.
  static const List<Branch> branches = [
    Branch(id: 'branch-huauchinango', name: 'Huauchinango'),
    Branch(id: 'branch-zacatlan', name: 'Zacatlán'),
    Branch(id: 'branch-chignahuapan', name: 'Chignahuapan'),
    Branch(id: 'branch-ahuazotepec', name: 'Ahuazotepec'),
    Branch(id: 'branch-xicotepec', name: 'Xicotepec'),
  ];

  static const List<Prenda> prendas = [
    Prenda(
      id: 1,
      barcode: '7501000000012',
      description: 'Blusa floral manga corta',
      brand: 'Lizz',
      category: 'Blusas',
      season: 'Primavera',
    ),
    Prenda(
      id: 2,
      barcode: '7501000000029',
      description: 'Vestido midi negro',
      brand: 'Lizz',
      category: 'Vestidos',
      season: 'Otoño',
    ),
    Prenda(
      id: 3,
      barcode: '7501000000036',
      description: 'Jeans skinny azul',
      brand: 'Denim Co',
      category: 'Pantalones',
      season: 'Todo el año',
      alertThreshold: 3,
    ),
    Prenda(
      id: 4,
      barcode: '7501000000043',
      description: 'Chamarra de mezclilla',
      brand: 'Denim Co',
      category: 'Chamarras',
      season: 'Invierno',
    ),
    Prenda(
      id: 5,
      barcode: '7501000000050',
      description: 'Falda plisada rosa',
      brand: 'Lizz',
      category: 'Faldas',
      season: 'Primavera',
    ),
    // Agotada en todas las sucursales.
    Prenda(
      id: 6,
      barcode: '7501000000067',
      description: 'Playera básica blanca',
      brand: 'Basics',
      category: 'Playeras',
      season: 'Todo el año',
    ),
  ];

  final List<StockItem> _stock;

  static List<StockItem> _initialStock() {
    var nextId = 100;
    StockItem line(int prenda, Branch branch, String size, String color, int qty) =>
        StockItem(
          id: nextId++ + prenda * 1000,
          branchId: branch.id,
          branchName: branch.name,
          size: size,
          color: color,
          quantity: qty,
        );
    final [huau, zac, chig, ahua, xico] = branches;
    return [
      // 1 Blusa floral.
      line(1, huau, 'M', 'Rosa', 8),
      line(1, huau, 'G', 'Rosa', 4),
      line(1, zac, 'M', 'Rosa', 5),
      line(1, zac, 'CH', 'Blanco', 1), // baja
      line(1, chig, 'M', 'Rosa', 3),
      line(1, ahua, 'M', 'Blanco', 0), // agotada
      line(1, xico, 'G', 'Blanco', 6),
      // 2 Vestido midi.
      line(2, huau, 'CH', 'Negro', 2), // baja
      line(2, zac, 'M', 'Negro', 7),
      line(2, chig, 'M', 'Negro', 0), // agotada
      line(2, xico, 'G', 'Negro', 9),
      // 3 Jeans.
      line(3, huau, '28', 'Azul', 10),
      line(3, zac, '30', 'Azul', 3), // baja (umbral 3)
      line(3, zac, '32', 'Azul', 6),
      line(3, ahua, '30', 'Azul', 5),
      line(3, xico, '28', 'Azul', 4),
      // 4 Chamarra.
      line(4, huau, 'M', 'Azul', 2), // baja
      line(4, chig, 'G', 'Azul', 5),
      // 5 Falda.
      line(5, zac, 'U', 'Rosa', 4),
      line(5, ahua, 'U', 'Rosa', 1), // baja
      line(5, xico, 'U', 'Rosa', 8),
      // 6 Playera: agotada en todas.
      line(6, huau, 'M', 'Blanco', 0),
      line(6, zac, 'M', 'Blanco', 0),
    ];
  }

  /// Existencias de una prenda. El identificador de inventario lleva la prenda
  /// en los miles (`prenda * 1000 + n`).
  List<StockItem> stockOf(int prendaId) =>
      _stock.where((item) => item.id ~/ 1000 == prendaId).toList();

  /// Descuenta piezas en memoria. Lanza `insufficientStock` si no alcanza.
  StockItem sell(int stockId, int quantity) {
    final index = _stock.indexWhere((item) => item.id == stockId);
    if (index < 0) throw const CatalogFailure(CatalogFailureType.notFound);
    if (quantity <= 0) throw const CatalogFailure(CatalogFailureType.invalid);
    final current = _stock[index];
    if (quantity > current.quantity) {
      throw const CatalogFailure(CatalogFailureType.insufficientStock);
    }
    final updated = current.copyWith(quantity: current.quantity - quantity);
    _stock[index] = updated;
    return updated;
  }

  /// Existencia que cuenta una prenda con esos filtros.
  int _countFor(Prenda prenda, SearchFilters filters) {
    return stockOf(prenda.id)
        .where(
          (item) =>
              (filters.branchId == null || item.branchId == filters.branchId) &&
              (filters.size == null || _same(item.size, filters.size!)) &&
              (filters.color == null || _same(item.color, filters.color!)),
        )
        .fold(0, (sum, item) => sum + item.quantity);
  }

  bool _hasStockMatching(Prenda prenda, SearchFilters filters) {
    return stockOf(prenda.id).any(
      (item) =>
          (filters.branchId == null || item.branchId == filters.branchId) &&
          (filters.size == null || _same(item.size, filters.size!)) &&
          (filters.color == null || _same(item.color, filters.color!)),
    );
  }

  static String _fold(String text) => text
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .trim();

  static bool _same(String a, String b) => _fold(a) == _fold(b);

  List<Prenda> search(SearchFilters filters) {
    final text = _fold(filters.query);
    final results = <Prenda>[];
    for (final prenda in prendas) {
      final haystack = _fold('${prenda.description} ${prenda.brand ?? ''}');
      if (text.isNotEmpty && !haystack.contains(text)) continue;
      final hasFilters =
          filters.size != null ||
          filters.color != null ||
          filters.branchId != null;
      if (hasFilters && !_hasStockMatching(prenda, filters)) continue;
      results.add(
        Prenda(
          id: prenda.id,
          barcode: prenda.barcode,
          description: prenda.description,
          brand: prenda.brand,
          category: prenda.category,
          season: prenda.season,
          photoUrl: prenda.photoUrl,
          alertThreshold: prenda.alertThreshold,
          totalStock: _countFor(prenda, filters),
        ),
      );
    }
    return results;
  }

  PrendaFicha? ficha(Prenda? prenda) {
    if (prenda == null) return null;
    final items = stockOf(prenda.id);
    return PrendaFicha(
      prenda: Prenda(
        id: prenda.id,
        barcode: prenda.barcode,
        description: prenda.description,
        brand: prenda.brand,
        category: prenda.category,
        season: prenda.season,
        photoUrl: prenda.photoUrl,
        alertThreshold: prenda.alertThreshold,
        totalStock: items.fold(0, (sum, item) => sum + item.quantity),
      ),
      stock: items,
    );
  }
}

/// Catálogo de prendas simulado, con DATOS DE PRUEBA.
class MockPrendaRepository implements PrendaRepository {
  MockPrendaRepository(this._store);

  final MockCatalogStore _store;

  @override
  Future<List<Prenda>> search(SearchFilters filters) async {
    await Future<void>.delayed(_store.delay);
    return _store.search(filters);
  }

  @override
  Future<PrendaFicha> getById(int id) async {
    await Future<void>.delayed(_store.delay);
    final prenda = MockCatalogStore.prendas.where((p) => p.id == id);
    final ficha = _store.ficha(prenda.isEmpty ? null : prenda.first);
    if (ficha == null) throw const CatalogFailure(CatalogFailureType.notFound);
    return ficha;
  }

  @override
  Future<PrendaFicha> getByBarcode(String barcode) async {
    await Future<void>.delayed(_store.delay);
    final prenda = MockCatalogStore.prendas.where(
      (p) => p.barcode == barcode.trim(),
    );
    final ficha = _store.ficha(prenda.isEmpty ? null : prenda.first);
    if (ficha == null) throw const CatalogFailure(CatalogFailureType.notFound);
    return ficha;
  }
}

/// Ventas simuladas: descuentan en memoria y rechazan si no alcanza.
class MockInventarioRepository implements InventarioRepository {
  MockInventarioRepository(this._store);

  final MockCatalogStore _store;

  @override
  Future<StockItem> sell(int stockId, int quantity) async {
    await Future<void>.delayed(_store.delay);
    return _store.sell(stockId, quantity);
  }
}

/// Sucursales simuladas.
class MockBranchRepository implements BranchRepository {
  MockBranchRepository(this._store);

  final MockCatalogStore _store;

  @override
  Future<List<Branch>> list() async {
    await Future<void>.delayed(_store.delay);
    return MockCatalogStore.branches;
  }
}
