import 'dart:convert';
import 'dart:typed_data';

import 'package:checklizz/core/network/api_client.dart';
import 'package:checklizz/core/network/api_exception.dart';
import 'package:checklizz/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adaptador falso: responde con un código fijo y guarda la última petición.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, {this.body = const {'ok': true}});

  final int status;
  final Object body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
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

void main() {
  late SessionEvents events;
  late int unauthorizedCount;
  late int forbiddenCount;

  setUp(() {
    events = SessionEvents();
    unauthorizedCount = 0;
    forbiddenCount = 0;
    events.onUnauthorized = () => unauthorizedCount++;
    events.onForbidden = () => forbiddenCount++;
  });

  ApiClient buildClient(_FakeAdapter adapter, {String? token}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.prueba'))
      ..httpClientAdapter = adapter;
    return ApiClient(
      baseUrl: 'https://api.prueba',
      dio: dio,
      interceptor: AuthInterceptor(
        readToken: () async => token,
        events: events,
      ),
    );
  }

  test('agrega el encabezado Authorization cuando hay token', () async {
    final adapter = _FakeAdapter(200);
    await buildClient(adapter, token: 'abc').get('/algo');
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer abc');
  });

  test('no agrega encabezado cuando no hay token', () async {
    final adapter = _FakeAdapter(200);
    await buildClient(adapter).get('/algo');
    expect(adapter.lastRequest?.headers.containsKey('Authorization'), isFalse);
  });

  test('notifica el 401 de una petición autenticada', () async {
    final client = buildClient(_FakeAdapter(401), token: 'abc');
    await expectLater(
      client.get('/algo'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'tipo', ApiErrorKind.unauthorized),
      ),
    );
    expect(unauthorizedCount, 1);
  });

  test('no trata como sesión vencida el 401 del inicio de sesión sin token', () async {
    final client = buildClient(_FakeAdapter(401));
    await expectLater(client.post('/auth/login'), throwsA(isA<ApiException>()));
    expect(unauthorizedCount, 0,
        reason: 'sin token, un 401 son credenciales incorrectas');
  });

  test('notifica el 403 sin tratarlo como sesión vencida', () async {
    final client = buildClient(_FakeAdapter(403), token: 'abc');
    await expectLater(
      client.get('/algo'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'tipo', ApiErrorKind.forbidden),
      ),
    );
    expect(forbiddenCount, 1);
    expect(unauthorizedCount, 0);
  });

  test('no sobrescribe un encabezado Authorization que la petición ya trae', () async {
    final adapter = _FakeAdapter(200);
    await buildClient(adapter, token: 'guardado').get(
      '/me',
      headers: {'Authorization': 'Bearer recien-emitido'},
    );
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer recien-emitido',
        reason: 'justo después de iniciar sesión se usa el token recién emitido');
  });

  test('postForm envía los datos como formulario', () async {
    final adapter = _FakeAdapter(200, body: {'access_token': 'a', 'expires_in': 300});
    final json = await buildClient(adapter).postForm(
      'https://id.prueba/realms/checklizz/protocol/openid-connect/token',
      {'grant_type': 'password', 'username': 'ana'},
    );
    expect(adapter.lastRequest?.contentType, contains('application/x-www-form-urlencoded'));
    expect(adapter.lastRequest?.uri.host, 'id.prueba',
        reason: 'usa la dirección completa, no la base de la API');
    expect(json['access_token'], 'a');
  });

  test('getList devuelve una lista', () async {
    final adapter = _FakeAdapter(200, body: [
      {'id': 1, 'nombre': 'Huauchinango'},
    ]);
    final list = await buildClient(adapter).getList('/sucursales');
    expect(list, hasLength(1));
  });

  test('conserva el código y la descripción del error del cuerpo', () async {
    final client = buildClient(
      _FakeAdapter(400, body: {'error': 'invalid_grant', 'error_description': 'Account disabled'}),
    );
    await expectLater(
      client.postForm('https://id.prueba/token', {'a': 'b'}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'código', 'invalid_grant')
            .having((e) => e.description, 'descripción', 'Account disabled')
            .having((e) => e.kind, 'tipo', ApiErrorKind.badRequest),
      ),
    );
  });

  test('traduce un 500 a error de servidor', () async {
    final client = buildClient(_FakeAdapter(500), token: 'abc');
    await expectLater(
      client.get('/algo'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'tipo', ApiErrorKind.server),
      ),
    );
  });

  group('Renovación de la sesión ante un 401', () {
    late _ScriptedAdapter adapter;
    late String? stored;
    late int refreshCalls;

    /// Cliente cuyo token guardado cambia al renovar.
    ApiClient renewing({
      required Future<String?> Function() refresh,
      String? initial = 'viejo',
    }) {
      stored = initial;
      refreshCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.prueba'))
        ..httpClientAdapter = adapter;
      return ApiClient(
        baseUrl: 'https://api.prueba',
        dio: dio,
        interceptor: AuthInterceptor(
          readToken: () async => stored,
          events: events,
          refreshSession: () async {
            refreshCalls++;
            return refresh();
          },
        ),
      );
    }

    setUp(() => adapter = _ScriptedAdapter({'Bearer nuevo': 200}));

    test('renueva y repite la petición una sola vez', () async {
      final client = renewing(refresh: () async => stored = 'nuevo');
      final json = await client.get('/prendas');

      expect(json['ok'], true);
      expect(refreshCalls, 1);
      expect(adapter.requests, 2, reason: 'la original y una repetición');
      expect(adapter.lastAuthorization, 'Bearer nuevo');
      expect(unauthorizedCount, 0, reason: 'la sesión se renovó, no se cierra');
    });

    test('varias peticiones a la vez comparten una sola renovación', () async {
      final client = renewing(
        refresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return stored = 'nuevo';
        },
      );
      final results = await Future.wait([
        client.get('/prendas'),
        client.get('/prendas/1'),
        client.get('/sucursales'),
      ]);

      expect(results, hasLength(3));
      expect(refreshCalls, 1, reason: 'una renovación para las tres peticiones');
      expect(unauthorizedCount, 0);
    });

    test('un descuento de venta interrumpido se envía una sola vez con éxito', () async {
      final client = renewing(refresh: () async => stored = 'nuevo');
      await client.post('/ventas', data: {'idInventario': 1, 'cantidad': 1});

      expect(adapter.successfulRequests, 1,
          reason: 'el 401 no procesó nada: solo una venta aceptada');
      expect(adapter.requests, 2);
    });

    test('si no se puede renovar, avisa que la sesión no es válida', () async {
      final client = renewing(refresh: () async => null);
      await expectLater(
        client.get('/prendas'),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'tipo', ApiErrorKind.unauthorized),
        ),
      );
      expect(refreshCalls, 1);
      expect(unauthorizedCount, 1);
    });

    test('si la repetición vuelve a recibir 401, no renueva otra vez', () async {
      adapter = _ScriptedAdapter({});
      final client = renewing(refresh: () async => stored = 'nuevo');
      await expectLater(client.get('/prendas'), throwsA(isA<ApiException>()));
      expect(refreshCalls, 1, reason: 'solo se intenta una vez');
      expect(adapter.requests, 2);
      expect(unauthorizedCount, 1);
    });

    test('un fallo de conexión al renovar no cierra la sesión', () async {
      final client = renewing(refresh: () async => throw StateError('sin red'));
      await expectLater(
        client.get('/prendas'),
        throwsA(
          isA<ApiException>().having((e) => e.kind, 'tipo', ApiErrorKind.network),
        ),
      );
      expect(unauthorizedCount, 0, reason: 'la sesión sigue guardada');
    });

    test('tras renovar, las peticiones siguientes salen con el token nuevo sin renovar', () async {
      final client = renewing(refresh: () async => stored = 'nuevo');
      await client.get('/prendas');
      await client.get('/prendas/1');
      expect(refreshCalls, 1);
      expect(adapter.lastAuthorization, 'Bearer nuevo');
    });

    test('no renueva cuando la petición lleva su propio token (inicio de sesión)', () async {
      final client = renewing(refresh: () async => stored = 'nuevo');
      await expectLater(
        client.get('/me', headers: {'Authorization': 'Bearer recien-emitido'}),
        throwsA(isA<ApiException>()),
      );
      expect(refreshCalls, 0);
    });

    test('el 403 no renueva ni cierra la sesión', () async {
      adapter = _ScriptedAdapter({}, defaultStatus: 403);
      final client = renewing(refresh: () async => stored = 'nuevo');
      await expectLater(client.get('/prendas'), throwsA(isA<ApiException>()));
      expect(refreshCalls, 0);
      expect(forbiddenCount, 1);
      expect(unauthorizedCount, 0);
    });
  });
}

/// Adaptador que responde 200 solo a los encabezados `Authorization` indicados
/// y [defaultStatus] (401) al resto; cuenta las peticiones.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._okByAuth, {this.defaultStatus = 401});

  final Map<String, int> _okByAuth;
  final int defaultStatus;
  int requests = 0;
  int successfulRequests = 0;
  String? lastAuthorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    final auth = options.headers['Authorization'] as String?;
    lastAuthorization = auth;
    final status = _okByAuth[auth] ?? defaultStatus;
    if (status == 200) successfulRequests++;
    return ResponseBody.fromString(
      jsonEncode({'ok': status == 200}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
