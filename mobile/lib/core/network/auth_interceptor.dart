import 'package:dio/dio.dart';

/// Puente entre la capa de red y el estado de sesión.
///
/// Evita una dependencia circular: el interceptor avisa aquí y el
/// `SessionViewModel` se suscribe después.
class SessionEvents {
  /// Se invoca cuando la API rechaza la sesión (401) en una petición autenticada.
  void Function()? onUnauthorized;

  /// Se invoca cuando la API niega el permiso (403). No cierra la sesión.
  void Function()? onForbidden;
}

/// Decorator: agrega `Authorization: Bearer <token>` a cada petición y
/// notifica los 401 y 403 de las peticiones autenticadas.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._readToken, required this._events});

  final Future<String?> Function() _readToken;
  final SessionEvents _events;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Si la petición ya trae su propio encabezado (por ejemplo, justo después
    // de iniciar sesión, antes de guardar la sesión), no se sobrescribe.
    if (!options.headers.containsKey('Authorization')) {
      final token = await _readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Un 401 del inicio de sesión (sin token) significa credenciales
    // incorrectas, no sesión vencida; por eso solo se notifica si la
    // petición llevaba token.
    final hadToken = err.requestOptions.headers.containsKey('Authorization');
    final status = err.response?.statusCode;
    if (hadToken && status == 401) {
      _events.onUnauthorized?.call();
    } else if (hadToken && status == 403) {
      _events.onForbidden?.call();
    }
    handler.next(err);
  }
}
