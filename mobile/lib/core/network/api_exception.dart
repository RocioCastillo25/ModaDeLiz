import 'package:dio/dio.dart';

/// Clases de error de red, sin detalles técnicos para el usuario.
enum ApiErrorKind { network, badRequest, unauthorized, forbidden, server }

/// Error que expone el [ApiClient] a las capas superiores.
class ApiException implements Exception {
  const ApiException(
    this.kind, {
    this.statusCode,
    this.code,
    this.description,
  });

  final ApiErrorKind kind;
  final int? statusCode;

  /// Código de error del cuerpo de la respuesta (`error`), si lo hay. Es para
  /// decidir qué hacer; nunca se muestra al usuario.
  final String? code;

  /// Descripción del error del cuerpo (`error_description` de Keycloak o
  /// `mensaje` de la API). Es para decidir qué hacer; nunca se muestra al
  /// usuario.
  final String? description;

  /// Traduce un error de `dio` a un [ApiException].
  factory ApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    if (status == null) {
      return const ApiException(ApiErrorKind.network);
    }
    String? code;
    String? description;
    final body = error.response?.data;
    if (body is Map) {
      code = body['error']?.toString();
      description = (body['error_description'] ?? body['mensaje'])?.toString();
    }
    final ApiErrorKind kind;
    if (status == 401) {
      kind = ApiErrorKind.unauthorized;
    } else if (status == 403) {
      kind = ApiErrorKind.forbidden;
    } else if (status >= 400 && status < 500) {
      kind = ApiErrorKind.badRequest;
    } else {
      kind = ApiErrorKind.server;
    }
    return ApiException(
      kind,
      statusCode: status,
      code: code,
      description: description,
    );
  }

  @override
  String toString() => 'ApiException(${kind.name}, $statusCode)';
}
