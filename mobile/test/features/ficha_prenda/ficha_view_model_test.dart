import 'package:checklizz/core/security/in_memory_token_storage.dart';
import 'package:checklizz/data/models/prenda.dart';
import 'package:checklizz/data/models/prenda_ficha.dart';
import 'package:checklizz/data/models/search_filters.dart';
import 'package:checklizz/data/models/stock_item.dart';
import 'package:checklizz/data/repositories/catalog_failure.dart';
import 'package:checklizz/data/repositories/mock_auth_repository.dart';
import 'package:checklizz/data/repositories/mock_catalog_repositories.dart';
import 'package:checklizz/data/repositories/prenda_repository.dart';
import 'package:checklizz/features/auth/session_view_model.dart';
import 'package:checklizz/features/ficha_prenda/ficha_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FlakyRepository implements PrendaRepository {
  _FlakyRepository(this._inner);

  final PrendaRepository _inner;
  CatalogFailureType? failure;
  int fichaCalls = 0;

  @override
  Future<List<Prenda>> search(SearchFilters filters) => _inner.search(filters);

  @override
  Future<PrendaFicha> getById(int id) async {
    fichaCalls++;
    if (failure != null) throw CatalogFailure(failure!);
    return _inner.getById(id);
  }

  @override
  Future<PrendaFicha> getByBarcode(String barcode) async {
    fichaCalls++;
    if (failure != null) throw CatalogFailure(failure!);
    return _inner.getByBarcode(barcode);
  }
}

Future<SessionViewModel> _loggedIn(String username) async {
  final repository = MockAuthRepository(
    InMemoryTokenStorage(),
    delay: Duration.zero,
  );
  final session = SessionViewModel(repository);
  session.onLoggedIn(await repository.login(username, MockAuthRepository.demoPassword));
  return session;
}

void main() {
  late MockCatalogStore store;
  late _FlakyRepository prendas;

  setUp(() {
    store = MockCatalogStore(delay: Duration.zero);
    prendas = _FlakyRepository(MockPrendaRepository(store));
  });

  test('carga la ficha por identificador', () async {
    final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
    final future = vm.load(1);
    expect(vm.status, FichaStatus.loading);
    await future;
    expect(vm.status, FichaStatus.data);
    expect(vm.ficha?.prenda.description, 'Blusa floral manga corta');
    expect(vm.ficha?.stock, isNotEmpty);
  });

  test('carga la ficha por código de barras', () async {
    final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
    await vm.loadByBarcode('7501000000029');
    expect(vm.status, FichaStatus.data);
    expect(vm.ficha?.prenda.id, 2);
  });

  test('un código desconocido deja el estado de error "no encontrada"', () async {
    final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
    await vm.loadByBarcode('0000');
    expect(vm.status, FichaStatus.error);
    expect(vm.errorMessage, 'Prenda no encontrada.');
  });

  test('un fallo de red muestra un mensaje claro y reintentar vuelve a cargar', () async {
    final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
    prendas.failure = CatalogFailureType.network;
    await vm.load(1);
    expect(vm.status, FichaStatus.error);
    expect(vm.errorMessage, contains('conexión'));

    prendas.failure = null;
    await vm.refresh();
    expect(vm.status, FichaStatus.data);
  });

  test('actualizar vuelve a pedir los datos de la misma prenda', () async {
    final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
    await vm.load(3);
    final before = prendas.fichaCalls;
    // Otra persona vende una pieza mientras la ficha está abierta.
    final line = vm.ficha!.stock.firstWhere((item) => item.quantity > 3);
    store.sell(line.id, 2);

    await vm.refresh();
    expect(prendas.fichaCalls, before + 1);
    expect(
      vm.ficha!.stock.firstWhere((item) => item.id == line.id).quantity,
      line.quantity - 2,
    );
  });

  test('si falla al actualizar, conserva los datos que ya tenía y avisa', () async {
    final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
    await vm.load(1);
    prendas.failure = CatalogFailureType.network;
    await vm.refresh();
    expect(vm.ficha, isNotNull, reason: 'no se pierde lo que ya se veía');
    expect(vm.refreshError, contains('conexión'));
    expect(vm.status, FichaStatus.data);
  });

  group('Sucursal del usuario', () {
    test('identifica las existencias de la sucursal del empleado', () async {
      final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
      await vm.load(1);
      expect(vm.ownBranchId, 'branch-zacatlan');
      expect(vm.ownStock, isNotEmpty);
      expect(vm.ownStock.every((item) => item.branchId == 'branch-zacatlan'), isTrue);
      expect(vm.isOwn(vm.ficha!.stock.first), vm.ficha!.stock.first.branchId == 'branch-zacatlan');
    });

    test('un gerente ve las de su propia sucursal', () async {
      final vm = FichaViewModel(prendas, await _loggedIn('demo.encargado'));
      await vm.load(1);
      expect(vm.ownBranchId, 'branch-huauchinango');
      expect(vm.ownStock.every((item) => item.branchId == 'branch-huauchinango'), isTrue);
    });

    test('las existencias de otras sucursales no son vendibles', () async {
      final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
      await vm.load(1);
      final other = vm.ficha!.stock.firstWhere((item) => item.branchId != 'branch-zacatlan');
      expect(vm.isOwn(other), isFalse);
    });
  });

  group('Estado de la existencia', () {
    test('distingue agotado, bajo y disponible con el umbral de la prenda', () async {
      final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
      await vm.load(1);
      StockItem find(int qty) => vm.ficha!.stock.firstWhere((item) => item.quantity == qty);
      expect(vm.levelOf(find(0)), StockLevel.outOfStock);
      expect(vm.levelOf(find(1)), StockLevel.low);
      expect(vm.levelOf(find(8)), StockLevel.available);
    });
  });

  group('Tras una venta', () {
    test('reemplaza la existencia con el dato que devuelve la API', () async {
      final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
      await vm.load(1);
      final line = vm.ownStock.firstWhere((item) => item.quantity >= 3);
      vm.applySale(line.copyWith(quantity: 1));
      expect(vm.ficha!.stock.firstWhere((item) => item.id == line.id).quantity, 1);
      expect(vm.ficha!.totalStock, isNot(0));
    });
  });

  test('al cerrar sesión se limpia el estado', () async {
    final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
    await vm.load(1);
    vm.reset();
    expect(vm.ficha, isNull);
    expect(vm.status, FichaStatus.loading);
  });

  test('una respuesta lenta de otra ficha no pisa la actual', () async {
    final vm = FichaViewModel(prendas, await _loggedIn('demo.vendedor'));
    final first = vm.load(1);
    await vm.load(2);
    await first;
    expect(vm.ficha?.prenda.id, 2);
  });

  test('sin sucursal asignada no hay existencias propias', () async {
    final repository = MockAuthRepository(InMemoryTokenStorage(), delay: Duration.zero);
    final session = SessionViewModel(repository);
    // El administrador no tiene sucursal; aquí solo se comprueba el caso.
    session.onLoggedIn(await repository.login('demo.admin', MockAuthRepository.demoPassword));
    final vm = FichaViewModel(prendas, session);
    await vm.load(1);
    expect(vm.ownBranchId, isNull);
    expect(vm.ownStock, isEmpty);
    expect(vm.canSell, isFalse);
  });
}
