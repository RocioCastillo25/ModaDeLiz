import 'dart:async';

import 'package:checklizz/data/models/prenda.dart';
import 'package:checklizz/data/models/prenda_ficha.dart';
import 'package:checklizz/data/models/search_filters.dart';
import 'package:checklizz/data/repositories/catalog_failure.dart';
import 'package:checklizz/data/repositories/mock_catalog_repositories.dart';
import 'package:checklizz/data/repositories/prenda_repository.dart';
import 'package:checklizz/data/services/barcode_scanner_service.dart';
import 'package:checklizz/features/escaner/escaner_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_barcode_scanner_service.dart';

/// Repositorio que cuenta las consultas por código y puede fallar o esperar.
class _CountingRepository implements PrendaRepository {
  _CountingRepository(this._inner);

  final PrendaRepository _inner;
  final List<String> lookups = [];
  CatalogFailureType? failure;
  Completer<void>? gate;

  @override
  Future<PrendaFicha> getByBarcode(String barcode) async {
    lookups.add(barcode);
    if (gate != null) await gate!.future;
    if (failure != null) throw CatalogFailure(failure!);
    return _inner.getByBarcode(barcode);
  }

  @override
  Future<List<Prenda>> search(SearchFilters filters) => _inner.search(filters);

  @override
  Future<PrendaFicha> getById(int id) => _inner.getById(id);
}

const _blusa = '7501000000012';
const _vestido = '7501000000029';

/// Deja correr los eventos pendientes (emisiones de flujos y consultas).
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late FakeBarcodeScannerService scanner;
  late _CountingRepository prendas;
  late DateTime now;
  late EscanerViewModel vm;

  setUp(() {
    scanner = FakeBarcodeScannerService();
    prendas = _CountingRepository(
      MockPrendaRepository(MockCatalogStore(delay: Duration.zero)),
    );
    now = DateTime(2026, 11, 27, 12);
    vm = EscanerViewModel(scanner, prendas, clock: () => now);
  });

  tearDown(() => vm.dispose());

  group('Permiso de cámara', () {
    test('al abrir solo explica; no pide la cámara todavía', () {
      expect(vm.status, EscanerStatus.explaining);
      expect(scanner.startCalls, 0);
    });

    test('al aceptar la explicación inicia la cámara', () async {
      await vm.start();
      expect(vm.status, EscanerStatus.scanning);
      expect(scanner.startCalls, 1);
    });

    test('si se niega el permiso ofrece la búsqueda manual', () async {
      await vm.start();
      scanner.emitError(ScannerError.permissionDenied);
      await _settle();
      expect(vm.status, EscanerStatus.permissionDenied);
      expect(vm.canLookUpManually, isTrue);
    });

    test('si la cámara no está disponible también ofrece la búsqueda manual', () async {
      await vm.start();
      scanner.emitError(ScannerError.unavailable);
      await _settle();
      expect(vm.status, EscanerStatus.unavailable);
      expect(vm.canLookUpManually, isTrue);
    });

    test('tras negar el permiso se puede intentar de nuevo', () async {
      await vm.start();
      scanner.emitError(ScannerError.permissionDenied);
      await _settle();
      await vm.start();
      expect(vm.status, EscanerStatus.scanning);
      expect(scanner.startCalls, 2);
    });
  });

  group('Lectura de códigos', () {
    test('un código registrado abre la ficha de esa prenda', () async {
      await vm.start();
      scanner.emit(_blusa);
      await _settle();
      expect(vm.status, EscanerStatus.found);
      expect(vm.foundFicha?.prenda.description, 'Blusa floral manga corta');
    });

    test('muestra "resolviendo" mientras consulta', () async {
      prendas.gate = Completer<void>();
      await vm.start();
      scanner.emit(_blusa);
      await _settle();
      expect(vm.status, EscanerStatus.resolving);
      prendas.gate!.complete();
      await _settle();
      expect(vm.status, EscanerStatus.found);
    });

    test('el mismo código mantenido frente a la cámara abre una sola ficha', () async {
      await vm.start();
      scanner
        ..emit(_blusa)
        ..emit(_blusa)
        ..emit(_blusa);
      await _settle();
      expect(prendas.lookups, [_blusa]);
      expect(vm.status, EscanerStatus.found);
    });

    test('espacios alrededor del código no cambian el resultado', () async {
      await vm.start();
      scanner.emit('  $_blusa \n');
      await _settle();
      expect(prendas.lookups, [_blusa]);
      expect(vm.status, EscanerStatus.found);
    });

    test('un código vacío se ignora', () async {
      await vm.start();
      scanner.emit('   ');
      await _settle();
      expect(prendas.lookups, isEmpty);
      expect(vm.status, EscanerStatus.scanning);
    });

    test('después de ver la ficha se puede escanear otra prenda', () async {
      await vm.start();
      scanner.emit(_blusa);
      await _settle();
      vm.resume();
      expect(vm.status, EscanerStatus.scanning);
      scanner.emit(_vestido);
      await _settle();
      expect(vm.foundFicha?.prenda.description, 'Vestido midi negro');
    });

    test('el mismo código recién abierto no reabre la ficha al volver', () async {
      await vm.start();
      scanner.emit(_blusa);
      await _settle();
      vm.resume();
      now = now.add(const Duration(milliseconds: 800));
      scanner.emit(_blusa);
      await _settle();
      expect(prendas.lookups, [_blusa], reason: 'sigue frente a la cámara');
      expect(vm.status, EscanerStatus.scanning);

      now = now.add(const Duration(seconds: 3));
      scanner.emit(_blusa);
      await _settle();
      expect(prendas.lookups, [_blusa, _blusa], reason: 'pasó el tiempo de espera');
      expect(vm.status, EscanerStatus.found);
    });
  });

  group('Código desconocido y errores', () {
    test('un código desconocido avisa "prenda no encontrada"', () async {
      await vm.start();
      scanner.emit('0000');
      await _settle();
      expect(vm.status, EscanerStatus.notFound);
      expect(vm.message, 'Prenda no encontrada.');
    });

    test('tras el aviso se puede escanear otra vez sin salir del escáner', () async {
      await vm.start();
      scanner.emit('0000');
      await _settle();
      vm.rescan();
      expect(vm.status, EscanerStatus.scanning);
      scanner.emit(_blusa);
      await _settle();
      expect(vm.status, EscanerStatus.found);
    });

    test('mientras muestra el aviso ignora nuevas lecturas', () async {
      await vm.start();
      scanner.emit('0000');
      await _settle();
      scanner.emit(_blusa);
      await _settle();
      expect(vm.status, EscanerStatus.notFound);
      expect(prendas.lookups, ['0000']);
    });

    test('un fallo de red muestra un mensaje claro y permite reintentar', () async {
      prendas.failure = CatalogFailureType.network;
      await vm.start();
      scanner.emit(_blusa);
      await _settle();
      expect(vm.status, EscanerStatus.error);
      expect(vm.message, contains('conexión'));

      prendas.failure = null;
      vm.rescan();
      now = now.add(const Duration(seconds: 3));
      scanner.emit(_blusa);
      await _settle();
      expect(vm.status, EscanerStatus.found);
    });

    test('un error del servicio no muestra detalles técnicos', () async {
      prendas.failure = CatalogFailureType.server;
      await vm.start();
      scanner.emit(_blusa);
      await _settle();
      expect(vm.status, EscanerStatus.error);
      expect(vm.message, isNot(contains('500')));
    });
  });

  group('Búsqueda manual por código', () {
    test('encuentra una prenda aunque no haya cámara', () async {
      await vm.start();
      scanner.emitError(ScannerError.permissionDenied);
      await _settle();
      await vm.lookUp(_vestido);
      expect(vm.status, EscanerStatus.found);
      expect(vm.foundFicha?.prenda.id, 2);
    });

    test('un código vacío pide escribirlo y no consulta', () async {
      await vm.lookUp('   ');
      expect(vm.manualError, 'Escribe el código de la etiqueta.');
      expect(prendas.lookups, isEmpty);
    });

    test('un código desconocido avisa "prenda no encontrada"', () async {
      await vm.lookUp('9999');
      expect(vm.status, EscanerStatus.notFound);
    });
  });

  group('Linterna y cierre', () {
    test('enciende y apaga la linterna', () async {
      await vm.start();
      expect(vm.torchOn, isFalse);
      await vm.toggleTorch();
      expect(vm.torchOn, isTrue);
      expect(scanner.torchToggles, 1);
      await vm.toggleTorch();
      expect(vm.torchOn, isFalse);
    });

    test('al cerrar libera la cámara y deja de escuchar', () async {
      await vm.start();
      vm.dispose();
      expect(scanner.disposed, isTrue);
    });
  });
}
