import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP de la app. Se registra como singleton perezoso en `get_it`.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required AuthInterceptor interceptor,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
               headers: {'Content-Type': 'application/json'},
             ),
           ) {
    interceptor.attach(_dio);
    _dio.interceptors.add(interceptor);
  }

  final Dio _dio;

  /// Envía un POST con JSON y devuelve el cuerpo. Lanza [ApiException] si falla.
  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    final body = await _send(
      () => _dio.post<Map<String, dynamic>>(path, data: data),
    );
    return body ?? <String, dynamic>{};
  }

  /// Envía un POST con formulario (`application/x-www-form-urlencoded`) a una
  /// dirección completa. Se usa con el endpoint de token de Keycloak.
  Future<Map<String, dynamic>> postForm(
    String url,
    Map<String, String> fields,
  ) async {
    final body = await _send(
      () => _dio.post<Map<String, dynamic>>(
        url,
        data: fields,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      ),
    );
    return body ?? <String, dynamic>{};
  }

  /// Envía un GET y devuelve el cuerpo JSON (un objeto). Lanza [ApiException]
  /// si falla. Con [headers] se puede indicar un encabezado propio, por
  /// ejemplo `Authorization`, antes de que exista una sesión guardada.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final body = await _send(
      () => _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
        options: Options(headers: headers),
      ),
    );
    return body ?? <String, dynamic>{};
  }

  /// Envía un GET y devuelve el cuerpo JSON (una lista). Con [query] se
  /// agregan parámetros de consulta.
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final body = await _send(
      () => _dio.get<List<dynamic>>(
        path,
        queryParameters: query,
        options: Options(headers: headers),
      ),
    );
    return body ?? <dynamic>[];
  }

  Future<T?> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
