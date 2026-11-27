import '../../core/network/api_exception.dart';
import '../../core/security/token_storage.dart';
import '../models/app_role.dart';
import '../models/branch.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import 'auth_failure.dart';
import 'auth_repository.dart';

/// Paso del acceso en el que ocurrió un error; cambia cómo se interpreta.
enum _Step { token, profile, branches }

/// Repositorio de autenticación contra Keycloak y la API real.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(
    this._service,
    this._storage, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthService _service;
  final TokenStorage _storage;
  final DateTime Function() _clock;

  @override
  Future<Session> login(String username, String password) async {
    var step = _Step.token;
    final Session session;
    try {
      final token = await _service.requestToken(username, password);

      step = _Step.profile;
      final profile = await _service.fetchProfile(token.accessToken);
      final role = profile.appRole;
      if (role == null) {
        throw const AuthFailure(AuthFailureType.incompleteData);
      }

      Branch? branch;
      if (role.requiresBranch) {
        step = _Step.branches;
        final branches = await _service.fetchBranches(token.accessToken);
        for (final candidate in branches) {
          if (candidate.id == profile.branchId) {
            branch = candidate.toBranch();
            break;
          }
        }
      }

      final now = _clock();
      session = Session(
        accessToken: token.accessToken,
        expiresAt: now.add(Duration(seconds: token.expiresIn)),
        user: profile.toUser(branch),
        refreshToken: token.refreshToken,
        refreshExpiresAt: token.refreshExpiresIn == null
            ? null
            : now.add(Duration(seconds: token.refreshExpiresIn!)),
      );
    } on ApiException catch (error) {
      throw AuthFailure(_mapError(error, step));
    }
    // Un administrador no conserva sesión en el dispositivo.
    if (session.user.role != AppRole.admin) {
      await _storage.save(session);
    }
    return session;
  }

  @override
  Future<Session?> restoreSession() => restoreStoredSession(_storage, _clock());

  @override
  Future<void> logout() => _storage.clear();

  @override
  Future<String?> refresh() async {
    final current = await _storage.read();
    final now = _clock();
    if (current == null || !current.canRefresh(now: now)) return null;
    try {
      final token = await _service.refreshToken(current.refreshToken!);
      final renewed = current.withTokens(
        accessToken: token.accessToken,
        expiresAt: now.add(Duration(seconds: token.expiresIn)),
        refreshToken: token.refreshToken,
        refreshExpiresAt: token.refreshExpiresIn == null
            ? null
            : now.add(Duration(seconds: token.refreshExpiresIn!)),
      );
      await _storage.save(renewed);
      return renewed.accessToken;
    } on ApiException catch (error) {
      // Un fallo de conexión o del servicio no invalida la sesión: se avisa
      // para que el usuario reintente. Cualquier otro rechazo (invalid_grant,
      // cuenta desactivada, token vencido) significa que no se puede renovar.
      if (error.kind == ApiErrorKind.network) {
        throw const AuthFailure(AuthFailureType.network);
      }
      if (error.kind == ApiErrorKind.server) {
        throw const AuthFailure(AuthFailureType.server);
      }
      return null;
    }
  }

  AuthFailureType _mapError(ApiException error, _Step step) {
    if (error.kind == ApiErrorKind.network) return AuthFailureType.network;
    if (error.kind == ApiErrorKind.server) return AuthFailureType.server;

    final texto = '${error.code ?? ''} ${error.description ?? ''}'.toLowerCase();
    final desactivada = texto.contains('disabled') || texto.contains('inactiv');

    if (step == _Step.token) {
      // Keycloak responde 401 ante credenciales incorrectas y 400 con
      // "Account disabled" ante una cuenta desactivada. Cualquier otro rechazo
      // se muestra como credenciales incorrectas, sin revelar si existe el usuario.
      if (desactivada) return AuthFailureType.accountDisabled;
      return AuthFailureType.invalidCredentials;
    }

    // Con el token recién emitido, la API no debería rechazarlo: un 401 o un
    // 400 aquí es un fallo del servicio. Un 403 o un usuario inactivo significa
    // que la cuenta no puede usar la app.
    if (error.kind == ApiErrorKind.forbidden || desactivada) {
      return AuthFailureType.accountDisabled;
    }
    return AuthFailureType.server;
  }
}
