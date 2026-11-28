import 'dart:convert';
import 'dart:typed_data';

import 'package:checklizz/core/network/api_client.dart';
import 'package:checklizz/core/network/auth_interceptor.dart';
import 'package:checklizz/data/models/search_filters.dart';
import 'package:checklizz/data/models/stock_item.dart';
import 'package:checklizz/data/repositories/api_catalog_repositories.dart';
import 'package:checklizz/data/repositories/catalog_failure.dart';
import 'package:checklizz/data/services/catalog_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adaptador falso: responde con un código y un cuerpo fijos (o simula la
/// falta de conexión) y guarda la última petición.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body, {this.offline = false});

  final int status;
  final Object body;
  final bool offline;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _ficha = {
  'id': 1,
  'codigo_barras': '7501',
  'descripcion': 'Blusa floral',
  'umbral_alerta': 2,
  'existencias': [
    {
      'id': 10,
      'id_sucursal': 2,
      'sucursal': 'Zacatlán',
      'talla': 'M',
      'color': 'Rosa',
      'cantidad': 5,
    },
  ],
};

const _existencia = {
  'id': 10,
  'id_prenda': 1,
  'id_sucursal': 2,
  'sucursal': 'Zacatlán',
  'talla': 'M',
  'color': 'Rosa',
  'cantidad': 3,
  'umbral_alerta': 2,
};

CatalogService _service(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.prueba/api/v1'))
    ..httpClientAdapter = adapter;
  final client = ApiClient(
    baseUrl: 'https://api.prueba/api/v1',
    dio: dio,
    interceptor: AuthInterceptor(
      readToken: () async => 'token',
      events: SessionEvents(),
    ),
  );
  return CatalogService(client);
}

Future<CatalogFailureType> _failureOf(Future<Object?> Function() action) async {
  try {
    await action();
  } on CatalogFailure catch (failure) {
    return failure.type;
  }
  fail('Se esperaba un CatalogFailure');
}

void main() {
  group('CatalogService', () {
    test('la búsqueda envía solo los filtros con valor', () async {
      final adapter = _Adapter(200, []);
      await _service(adapter).searchPrendas(
        SearchFilters(query: ' blusa ', size: 'M', color: '', branchId: '2'),
      );
      expect(adapter.last?.uri.path, '/api/v1/prendas');
      expect(adapter.last?.uri.queryParameters, {
        'q': 'blusa',
        'talla': 'M',
        'sucursalId': '2',
      });
    });

    test('una búsqueda sin filtros no envía parámetros', () async {
      final adapter = _Adapter(200, []);
      await _service(adapter).searchPrendas(SearchFilters());
      expect(adapter.last?.uri.queryParameters, isEmpty);
    });

    test('la búsqueda ignora elementos que no son prendas', () async {
      final adapter = _Adapter(200, [
        {'id': 1, 'codigo_barras': '7501', 'descripcion': 'Blusa'},
        'basura',
      ]);
      final list = await _service(adapter).searchPrendas(SearchFilters());
      expect(list, hasLength(1));
    });

    test('la ficha por identificador usa GET /prendas/{id}', () async {
      final adapter = _Adapter(200, _ficha);
      final ficha = await _service(adapter).fetchFicha(1);
      expect(adapter.last?.method, 'GET');
      expect(adapter.last?.uri.path, '/api/v1/prendas/1');
      expect(ficha.stock, hasLength(1));
    });

    test('el código de barras se codifica en la ruta', () async {
      final adapter = _Adapter(200, _ficha);
      await _service(adapter).fetchFichaByBarcode('AB 12/3');
      expect(adapter.last?.uri.toString(), contains('/prendas/codigo/AB%2012%2F3'));
    });

    test('la venta envía solo el inventario y la cantidad, nunca la sucursal', () async {
      final adapter = _Adapter(201, _existencia);
      final updated = await _service(adapter).sell(10, 2);
      expect(adapter.last?.method, 'POST');
      expect(adapter.last?.uri.path, '/api/v1/ventas');
      expect(adapter.last?.data, {'idInventario': 10, 'cantidad': 2});
      expect(updated.quantity, 3);
    });

    test('las peticiones llevan el token del usuario', () async {
      final adapter = _Adapter(200, _ficha);
      await _service(adapter).fetchFicha(1);
      expect(adapter.last?.headers['Authorization'], 'Bearer token');
    });
  });

  group('ApiPrendaRepository: errores', () {
    test('404 es "prenda no encontrada"', () async {
      final repo = ApiPrendaRepository(
        _service(_Adapter(404, {'error': 'NO_ENCONTRADO', 'mensaje': 'x'})),
      );
      expect(await _failureOf(() => repo.getByBarcode('0000')), CatalogFailureType.notFound);
    });

    test('sin conexión es error de red', () async {
      final repo = ApiPrendaRepository(_service(_Adapter(0, {}, offline: true)));
      expect(await _failureOf(() => repo.search(SearchFilters())), CatalogFailureType.network);
    });

    test('un 500 es error del servicio y no revela detalles', () async {
      final repo = ApiPrendaRepository(_service(_Adapter(500, {'error': 'X'})));
      final type = await _failureOf(() => repo.getById(1));
      expect(type, CatalogFailureType.server);
      expect(const CatalogFailure(CatalogFailureType.server).message, isNot(contains('500')));
    });

    test('una ficha mal formada es error del servicio', () async {
      final repo = ApiPrendaRepository(_service(_Adapter(200, {'id': 1})));
      expect(await _failureOf(() => repo.getById(1)), CatalogFailureType.server);
    });

    test('la búsqueda devuelve modelos con el umbral por defecto', () async {
      final repo = ApiPrendaRepository(
        _service(_Adapter(200, [
          {'id': 1, 'codigo_barras': '7501', 'descripcion': 'Blusa', 'existencia_total': 4},
        ])),
      );
      final list = await repo.search(SearchFilters());
      expect(list.single.alertThreshold, 2);
      expect(list.single.totalStock, 4);
    });
  });

  group('ApiInventarioRepository: ventas', () {
    test('201 devuelve la existencia que informa la API', () async {
      final repo = ApiInventarioRepository(_service(_Adapter(201, _existencia)));
      final StockItem item = await repo.sell(10, 2);
      expect(item.quantity, 3);
      expect(item.branchId, '2');
    });

    test('409 STOCK_INSUFICIENTE es existencia insuficiente', () async {
      final repo = ApiInventarioRepository(
        _service(_Adapter(409, {'error': 'STOCK_INSUFICIENTE', 'mensaje': 'No hay'})),
      );
      expect(await _failureOf(() => repo.sell(10, 99)), CatalogFailureType.insufficientStock);
    });

    test('403 PROHIBIDO es falta de permiso', () async {
      final repo = ApiInventarioRepository(
        _service(_Adapter(403, {'error': 'PROHIBIDO', 'mensaje': 'x'})),
      );
      expect(await _failureOf(() => repo.sell(10, 1)), CatalogFailureType.forbidden);
    });

    test('400 DATOS_INVALIDOS es dato inválido', () async {
      final repo = ApiInventarioRepository(
        _service(_Adapter(400, {'error': 'DATOS_INVALIDOS', 'mensaje': 'x'})),
      );
      expect(await _failureOf(() => repo.sell(10, 0)), CatalogFailureType.invalid);
    });

    test('sin conexión la venta falla como error de red', () async {
      final repo = ApiInventarioRepository(_service(_Adapter(0, {}, offline: true)));
      expect(await _failureOf(() => repo.sell(10, 1)), CatalogFailureType.network);
    });
  });

  group('ApiBranchRepository', () {
    test('convierte las sucursales del contrato', () async {
      final repo = ApiBranchRepository(
        _service(_Adapter(200, [
          {'id': 1, 'nombre': 'Huauchinango', 'ubicacion': 'Centro'},
          {'id': 2, 'nombre': 'Zacatlán'},
        ])),
      );
      final branches = await repo.list();
      expect(branches.map((b) => b.name), ['Huauchinango', 'Zacatlán']);
      expect(branches.first.id, '1');
    });
  });
}
