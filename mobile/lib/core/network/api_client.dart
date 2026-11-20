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
    _dio.interceptors.add(interceptor);
  }

  final Dio _dio;

  /// Envía un POST y devuelve el cuerpo JSON. Lanza [ApiException] si falla.
  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Envía un GET y devuelve el cuerpo JSON. Lanza [ApiException] si falla.
  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
