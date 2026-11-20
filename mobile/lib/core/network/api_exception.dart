import 'package:dio/dio.dart';

/// Clases de error de red, sin detalles técnicos para el usuario.
enum ApiErrorKind { network, badRequest, unauthorized, forbidden, server }

/// Error que expone el [ApiClient] a las capas superiores.
class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode});

  final ApiErrorKind kind;
  final int? statusCode;

  /// Traduce un error de `dio` a un [ApiException].
  factory ApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    if (status == null) {
      return const ApiException(ApiErrorKind.network);
    }
    if (status == 401) {
      return ApiException(ApiErrorKind.unauthorized, statusCode: status);
    }
    if (status == 403) {
      return ApiException(ApiErrorKind.forbidden, statusCode: status);
    }
    if (status >= 400 && status < 500) {
      return ApiException(ApiErrorKind.badRequest, statusCode: status);
    }
    return ApiException(ApiErrorKind.server, statusCode: status);
  }

  @override
  String toString() => 'ApiException(${kind.name}, $statusCode)';
}
