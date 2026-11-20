import 'dart:convert';
import 'dart:typed_data';

import 'package:checklizz/core/network/api_client.dart';
import 'package:checklizz/core/network/api_exception.dart';
import 'package:checklizz/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adaptador falso: responde con un código fijo y guarda la última petición.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status);

  final int status;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
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

  test('traduce un 500 a error de servidor', () async {
    final client = buildClient(_FakeAdapter(500), token: 'abc');
    await expectLater(
      client.get('/algo'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'tipo', ApiErrorKind.server),
      ),
    );
  });
}
