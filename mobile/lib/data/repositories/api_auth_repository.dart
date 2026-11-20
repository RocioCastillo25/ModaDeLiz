import '../../core/network/api_exception.dart';
import '../../core/security/token_storage.dart';
import '../models/app_role.dart';
import '../models/session.dart';
import '../services/auth_service.dart';
import 'auth_failure.dart';
import 'auth_repository.dart';

/// Repositorio de autenticación contra la API real.
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
    final Session session;
    try {
      final dto = await _service.login(username, password);
      session = dto.toSession(now: _clock());
    } on ApiException catch (error) {
      throw AuthFailure(_mapError(error));
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

  AuthFailureType _mapError(ApiException error) {
    switch (error.kind) {
      case ApiErrorKind.unauthorized:
        return AuthFailureType.invalidCredentials;
      case ApiErrorKind.forbidden:
        return AuthFailureType.accountDisabled;
      case ApiErrorKind.network:
        return AuthFailureType.network;
      case ApiErrorKind.badRequest:
      case ApiErrorKind.server:
        return AuthFailureType.server;
    }
  }
}
