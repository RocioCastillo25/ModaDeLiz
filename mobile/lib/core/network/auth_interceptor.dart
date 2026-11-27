import 'package:dio/dio.dart';

/// Puente entre la capa de red y el estado de sesión.
///
/// Evita una dependencia circular: el interceptor avisa aquí y el
/// `SessionViewModel` se suscribe después.
class SessionEvents {
  /// Se invoca cuando la API rechaza la sesión (401) y no se pudo renovar.
  void Function()? onUnauthorized;

  /// Se invoca cuando la API niega el permiso (403). No cierra la sesión.
  void Function()? onForbidden;
}

/// Decorator: agrega `Authorization: Bearer <token>` a cada petición, renueva
/// la sesión ante un 401 y notifica los 401 y 403 de las peticiones
/// autenticadas.
///
/// Renovación: ante un 401 de una petición que usó el token guardado, pide un
/// token nuevo con [refreshSession] y repite la petición UNA sola vez. Si
/// varias peticiones fallan a la vez, comparten una única renovación. Un 401
/// significa que la API no procesó la petición, así que repetirla no duplica
/// ninguna operación (por ejemplo, un descuento de venta).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._readToken,
    required this._events,
    this._refreshSession,
  });

  static const String _usedStoredToken = 'usedStoredToken';
  static const String _retried = 'sessionRetried';

  final Future<String?> Function() _readToken;
  final SessionEvents _events;
  final Future<String?> Function()? _refreshSession;

  Dio? _dio;
  Future<String?>? _refreshing;

  /// Conecta el interceptor con el cliente para poder repetir peticiones.
  void attach(Dio dio) => _dio = dio;

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
        options.extra[_usedStoredToken] = true;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Un 401 del inicio de sesión (sin token) significa credenciales
    // incorrectas, no sesión vencida; por eso solo se atiende si la
    // petición llevaba token.
    final request = err.requestOptions;
    final hadToken = request.headers.containsKey('Authorization');
    final status = err.response?.statusCode;

    if (hadToken && status == 403) {
      _events.onForbidden?.call();
      handler.next(err);
      return;
    }
    if (!hadToken || status != 401) {
      handler.next(err);
      return;
    }

    final canRenew =
        _refreshSession != null &&
        _dio != null &&
        request.extra[_usedStoredToken] == true &&
        request.extra[_retried] != true;
    if (!canRenew) {
      _events.onUnauthorized?.call();
      handler.next(err);
      return;
    }

    final String? newToken;
    try {
      newToken = await _renewedToken(request.headers['Authorization']);
    } catch (_) {
      // Sin conexión o error del servicio al renovar: la sesión no se cierra;
      // se informa como un fallo de conexión para que se pueda reintentar.
      handler.reject(
        DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
        ),
      );
      return;
    }

    if (newToken == null) {
      _events.onUnauthorized?.call();
      handler.next(err);
      return;
    }

    request.headers['Authorization'] = 'Bearer $newToken';
    request.extra[_retried] = true;
    try {
      handler.resolve(await _dio!.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Devuelve un token nuevo. Si otra petición ya lo renovó mientras esta
  /// fallaba, usa ese; si no, comparte una única renovación en curso.
  Future<String?> _renewedToken(Object? usedHeader) async {
    final current = await _readToken();
    if (current != null && current.isNotEmpty && 'Bearer $current' != usedHeader) {
      return current;
    }
    return _refreshing ??= _refreshSession!().whenComplete(
      () => _refreshing = null,
    );
  }
}
