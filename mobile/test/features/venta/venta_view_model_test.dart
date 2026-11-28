import 'dart:async';

import 'package:checklizz/data/models/stock_item.dart';
import 'package:checklizz/data/repositories/catalog_failure.dart';
import 'package:checklizz/data/repositories/inventario_repository.dart';
import 'package:checklizz/data/repositories/mock_catalog_repositories.dart';
import 'package:checklizz/data/services/connectivity_service.dart';
import 'package:checklizz/features/venta/venta_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Connectivity implements ConnectivityService {
  bool online = true;

  @override
  Future<bool> isOnline() async => online;
}

/// Repositorio de ventas que cuenta los envíos y puede fallar o esperar.
class _RecordingInventario implements InventarioRepository {
  _RecordingInventario(this._inner);

  final InventarioRepository _inner;
  final List<(int, int)> sales = [];
  CatalogFailureType? failure;
  Completer<void>? gate;

  @override
  Future<StockItem> sell(int stockId, int quantity) async {
    sales.add((stockId, quantity));
    if (gate != null) await gate!.future;
    if (failure != null) throw CatalogFailure(failure!);
    return _inner.sell(stockId, quantity);
  }
}

void main() {
  late MockCatalogStore store;
  late _RecordingInventario inventario;
  late _Connectivity connectivity;
  late VentaViewModel vm;
  late List<StockItem> options;

  setUp(() async {
    store = MockCatalogStore(delay: Duration.zero);
    inventario = _RecordingInventario(MockInventarioRepository(store));
    connectivity = _Connectivity();
    // Blusa floral en Zacatlán: M Rosa (5) y CH Blanco (1).
    options = store.stockOf(1).where((item) => item.branchId == 'branch-zacatlan').toList();
    vm = VentaViewModel(
      inventario,
      MockPrendaRepository(store),
      connectivity,
      prendaId: 1,
      options: options,
    );
  });

  tearDown(() => vm.dispose());

  group('Elección y validación de la cantidad', () {
    test('empieza con la primera existencia que tiene piezas', () {
      expect(vm.selected, options.first);
      expect(vm.status, VentaStatus.editing);
    });

    test('una existencia agotada no se puede elegir', () {
      final soldOut = options.first.copyWith(quantity: 0);
      final other = VentaViewModel(
        inventario,
        MockPrendaRepository(store),
        connectivity,
        prendaId: 1,
        options: [soldOut, options.last],
      );
      addTearDown(other.dispose);
      expect(other.selected, options.last, reason: 'se salta la agotada');
    });

    test('sin ninguna existencia con piezas no hay nada que vender', () {
      final empty = VentaViewModel(
        inventario,
        MockPrendaRepository(store),
        connectivity,
        prendaId: 1,
        options: [options.first.copyWith(quantity: 0)],
      );
      addTearDown(empty.dispose);
      expect(empty.selected, isNull);
      expect(empty.canContinue, isFalse);
    });

    for (final entry in {
      '': 'Escribe la cantidad.',
      '   ': 'Escribe la cantidad.',
      '0': 'La cantidad debe ser mayor que cero.',
      '-3': 'La cantidad debe ser mayor que cero.',
      '1.5': 'Escribe un número entero.',
      '2,5': 'Escribe un número entero.',
      'abc': 'Escribe un número entero.',
    }.entries) {
      test('la cantidad "${entry.key}" no se puede enviar', () {
        vm.setQuantity(entry.key);
        expect(vm.quantity, isNull);
        expect(vm.quantityError, entry.value);
        expect(vm.canContinue, isFalse);
        vm.confirm();
        expect(vm.status, VentaStatus.editing, reason: 'no pasa a confirmar');
      });
    }

    test('un entero positivo es válido', () {
      vm.setQuantity(' 2 ');
      expect(vm.quantity, 2);
      expect(vm.quantityError, isNull);
      expect(vm.canContinue, isTrue);
    });

    test('pedir más de lo que se ve avisa, pero la decisión es de la API', () {
      vm.setQuantity('99');
      expect(vm.quantity, 99);
      expect(vm.quantityWarning, 'Solo hay 5 piezas.');
      expect(vm.canContinue, isTrue, reason: 'la API valida la existencia');
    });

    test('cambiar de existencia revalida la cantidad', () {
      vm.setQuantity('3');
      expect(vm.quantityWarning, isNull);
      vm.select(options.last); // CH Blanco: 1 pieza
      expect(vm.quantityWarning, 'Solo hay 1 pieza.');
    });

    test('solo se pueden elegir las existencias que se ofrecieron', () {
      final foreign = store.stockOf(1).firstWhere((item) => item.branchId != 'branch-zacatlan');
      vm.select(foreign);
      expect(vm.selected, options.first, reason: 'no se acepta una existencia ajena');
    });
  });

  group('Confirmación y envío', () {
    test('pide confirmar mostrando prenda, talla, color y cantidad', () {
      vm.setQuantity('2');
      vm.confirm();
      expect(vm.status, VentaStatus.confirming);
      expect(vm.summary, 'Talla M · Rosa · 2 piezas');
    });

    test('se puede volver a editar desde la confirmación', () {
      vm.setQuantity('2');
      vm.confirm();
      vm.backToEditing();
      expect(vm.status, VentaStatus.editing);
      expect(inventario.sales, isEmpty);
    });

    test('una venta aceptada muestra la existencia que devolvió la API', () async {
      vm.setQuantity('2');
      vm.confirm();
      await vm.submit();

      expect(vm.status, VentaStatus.done);
      expect(vm.result?.quantity, 3);
      expect(vm.result?.id, options.first.id);
      expect(inventario.sales, [(options.first.id, 2)]);
      expect(store.stockOf(1).firstWhere((i) => i.id == options.first.id).quantity, 3);
    });

    test('envía solo el inventario y la cantidad, nunca la sucursal', () async {
      vm.setQuantity('1');
      vm.confirm();
      await vm.submit();
      expect(inventario.sales.single, (options.first.id, 1));
    });

    test('un doble toque genera una sola venta', () async {
      inventario.gate = Completer<void>();
      vm.setQuantity('1');
      vm.confirm();
      final first = vm.submit();
      expect(vm.status, VentaStatus.submitting);
      expect(vm.canSubmit, isFalse);
      final second = vm.submit();
      inventario.gate!.complete();
      await Future.wait([first, second]);

      expect(inventario.sales, hasLength(1));
      expect(vm.status, VentaStatus.done);
    });

    test('sin conexión avisa y no intenta la venta', () async {
      connectivity.online = false;
      vm.setQuantity('1');
      vm.confirm();
      await vm.submit();

      expect(vm.status, VentaStatus.error);
      expect(vm.errorMessage, contains('conexión'));
      expect(inventario.sales, isEmpty);

      connectivity.online = true;
      await vm.submit();
      expect(vm.status, VentaStatus.done, reason: 'se puede reintentar');
    });

    test('un error del servicio no muestra detalles técnicos y permite reintentar', () async {
      inventario.failure = CatalogFailureType.server;
      vm.setQuantity('1');
      vm.confirm();
      await vm.submit();
      expect(vm.status, VentaStatus.error);
      expect(vm.errorMessage, isNot(contains('Exception')));
      expect(vm.errorMessage, isNot(contains('500')));
      expect(vm.canSubmit, isTrue);
    });

    test('un 403 avisa que no tiene permiso', () async {
      inventario.failure = CatalogFailureType.forbidden;
      vm.setQuantity('1');
      vm.confirm();
      await vm.submit();
      expect(vm.status, VentaStatus.error);
      expect(vm.errorMessage, 'No tienes permiso para vender de esta sucursal.');
    });
  });

  group('Existencia insuficiente (409)', () {
    test('muestra la existencia actual y no modifica nada', () async {
      vm.setQuantity('99');
      vm.confirm();
      await vm.submit();

      expect(vm.status, VentaStatus.insufficient);
      expect(vm.errorMessage, 'Solo quedan 5 piezas.');
      expect(vm.latestFicha, isNotNull);
      expect(store.stockOf(1).firstWhere((i) => i.id == options.first.id).quantity, 5);
    });

    test('si otra persona vendió mientras tanto, informa la existencia vigente', () async {
      store.sell(options.first.id, 4); // quedan 1
      vm.setQuantity('3');
      vm.confirm();
      await vm.submit();

      expect(vm.errorMessage, 'Solo queda 1 pieza.');
      expect(vm.selected?.quantity, 1, reason: 'la opción se actualiza con lo vigente');
    });

    test('si ya no quedan piezas lo dice con claridad', () async {
      store.sell(options.first.id, 5);
      vm.setQuantity('1');
      vm.confirm();
      await vm.submit();
      expect(vm.errorMessage, 'Ya no quedan piezas de esta talla y color.');
    });

    test('tras el aviso se puede corregir la cantidad y vender', () async {
      vm.setQuantity('99');
      vm.confirm();
      await vm.submit();
      vm.backToEditing();
      vm.setQuantity('5');
      vm.confirm();
      await vm.submit();
      expect(vm.status, VentaStatus.done);
      expect(vm.result?.quantity, 0);
    });
  });

  test('al cerrar sesión se limpia el estado', () {
    vm.setQuantity('2');
    vm.reset();
    expect(vm.quantity, isNull);
    expect(vm.status, VentaStatus.editing);
    expect(vm.result, isNull);
  });
}
