import 'dart:async';

import 'package:checklizz/data/models/branch.dart';
import 'package:checklizz/data/models/prenda.dart';
import 'package:checklizz/data/models/prenda_ficha.dart';
import 'package:checklizz/data/models/search_filters.dart';
import 'package:checklizz/data/repositories/branch_repository.dart';
import 'package:checklizz/data/repositories/catalog_failure.dart';
import 'package:checklizz/data/repositories/mock_catalog_repositories.dart';
import 'package:checklizz/data/repositories/prenda_repository.dart';
import 'package:checklizz/features/busqueda/busqueda_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio que registra las búsquedas y puede fallar o esperar.
class _RecordingRepository implements PrendaRepository {
  _RecordingRepository(this._inner);

  final PrendaRepository _inner;
  final List<SearchFilters> searches = [];
  CatalogFailureType? failure;
  Completer<void>? gate;
  List<Prenda>? fixed;

  @override
  Future<List<Prenda>> search(SearchFilters filters) async {
    searches.add(filters);
    if (gate != null) await gate!.future;
    if (failure != null) throw CatalogFailure(failure!);
    return fixed ?? _inner.search(filters);
  }

  @override
  Future<PrendaFicha> getById(int id) => _inner.getById(id);

  @override
  Future<PrendaFicha> getByBarcode(String barcode) => _inner.getByBarcode(barcode);
}

class _FailingBranches implements BranchRepository {
  @override
  Future<List<Branch>> list() async =>
      throw const CatalogFailure(CatalogFailureType.network);
}

List<Prenda> _manyPrendas(int count) => [
  for (var i = 1; i <= count; i++)
    Prenda(id: i, barcode: 'c$i', description: 'Prenda $i', totalStock: 5),
];

void main() {
  late MockCatalogStore store;
  late _RecordingRepository prendas;
  late BusquedaViewModel vm;

  setUp(() {
    store = MockCatalogStore(delay: Duration.zero);
    prendas = _RecordingRepository(MockPrendaRepository(store));
    vm = BusquedaViewModel(
      prendas,
      MockBranchRepository(store),
      debounce: Duration.zero,
    );
  });

  tearDown(() => vm.dispose());

  group('Búsqueda', () {
    test('al abrir muestra las prendas y carga las sucursales', () async {
      await vm.init();
      expect(vm.status, BusquedaStatus.results);
      expect(vm.results, hasLength(MockCatalogStore.prendas.length));
      expect(vm.branches, hasLength(5));
    });

    test('muestra "cargando" mientras espera la respuesta', () async {
      prendas.gate = Completer<void>();
      final future = vm.search();
      expect(vm.status, BusquedaStatus.loading);
      prendas.gate!.complete();
      await future;
      expect(vm.status, BusquedaStatus.results);
    });

    test('busca por parte del nombre, sin importar mayúsculas ni espacios', () async {
      await vm.updateQuery('  BLUSA  ');
      expect(vm.results.map((p) => p.description), ['Blusa floral manga corta']);
      expect(prendas.searches.last.query, 'BLUSA', reason: 'sin espacios sobrantes');
    });

    test('combina los filtros de talla, color y sucursal', () async {
      await vm.applyFilters(
        SearchFilters(size: 'M', color: 'rosa', branchId: 'branch-zacatlan'),
      );
      expect(vm.results.map((p) => p.description), ['Blusa floral manga corta']);
      expect(vm.activeFilterCount, 3);
    });

    test('con filtro de sucursal muestra la existencia de esa sucursal', () async {
      await vm.applyFilters(SearchFilters(branchId: 'branch-zacatlan'));
      final blusa = vm.results.firstWhere((p) => p.id == 1);
      expect(blusa.totalStock, 6, reason: '5 de M rosa y 1 de CH blanco en Zacatlán');
    });

    test('sin coincidencias muestra el estado vacío', () async {
      await vm.updateQuery('abrigo de piel');
      expect(vm.status, BusquedaStatus.empty);
      expect(vm.results, isEmpty);
    });

    test('un fallo de red muestra un mensaje claro y permite reintentar', () async {
      prendas.failure = CatalogFailureType.network;
      await vm.search();
      expect(vm.status, BusquedaStatus.error);
      expect(vm.errorMessage, contains('conexión'));

      prendas.failure = null;
      await vm.retry();
      expect(vm.status, BusquedaStatus.results);
      expect(vm.errorMessage, isNull);
    });

    test('un error del servicio no muestra detalles técnicos', () async {
      prendas.failure = CatalogFailureType.server;
      await vm.search();
      expect(vm.status, BusquedaStatus.error);
      expect(vm.errorMessage, isNot(contains('500')));
      expect(vm.errorMessage, isNot(contains('Exception')));
    });

    test('limpiar los filtros conserva el texto y vuelve a buscar', () async {
      await vm.updateQuery('jeans');
      await vm.applyFilters(SearchFilters(query: 'jeans', size: '30'));
      await vm.clearFilters();
      expect(vm.filters.query, 'jeans');
      expect(vm.filters.size, isNull);
      expect(vm.activeFilterCount, 0);
    });

    test('una búsqueda lenta no pisa a una más reciente', () async {
      final firstGate = Completer<void>();
      prendas.gate = firstGate;
      final slow = vm.updateQuery('blusa');
      prendas.gate = null;
      await vm.updateQuery('jeans');
      expect(vm.results.map((p) => p.description), ['Jeans skinny azul']);
      // Libera la primera respuesta, que ya no debe aplicarse.
      firstGate.complete();
      await slow;
      expect(vm.results.map((p) => p.description), ['Jeans skinny azul']);
    });

    test('si falla la lista de sucursales, la búsqueda sigue funcionando', () async {
      final broken = BusquedaViewModel(
        prendas,
        _FailingBranches(),
        debounce: Duration.zero,
      );
      addTearDown(broken.dispose);
      await broken.init();
      expect(broken.status, BusquedaStatus.results);
      expect(broken.branches, isEmpty);
    });
  });

  group('Carga por bloques', () {
    test('muestra 20 resultados y carga más al llegar al final', () async {
      prendas.fixed = _manyPrendas(45);
      await vm.search();
      expect(vm.visibleResults, hasLength(20));
      expect(vm.hasMore, isTrue);

      vm.loadMore();
      expect(vm.visibleResults, hasLength(40));
      vm.loadMore();
      expect(vm.visibleResults, hasLength(45));
      expect(vm.hasMore, isFalse);
    });

    test('una búsqueda nueva vuelve al primer bloque', () async {
      prendas.fixed = _manyPrendas(45);
      await vm.search();
      vm.loadMore();
      await vm.search();
      expect(vm.visibleResults, hasLength(20));
    });
  });

  group('Escritura con espera', () {
    test('varias letras seguidas disparan una sola búsqueda', () async {
      final slow = BusquedaViewModel(
        prendas,
        MockBranchRepository(store),
        debounce: const Duration(milliseconds: 40),
      );
      addTearDown(slow.dispose);
      slow
        ..onQueryChanged('b')
        ..onQueryChanged('bl')
        ..onQueryChanged('blu');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(prendas.searches, hasLength(1));
      expect(prendas.searches.single.query, 'blu');
    });
  });

  test('al cerrar sesión se limpia el estado', () async {
    await vm.updateQuery('blusa');
    vm.reset();
    expect(vm.status, BusquedaStatus.idle);
    expect(vm.results, isEmpty);
    expect(vm.filters.isEmpty, isTrue);
  });
}
