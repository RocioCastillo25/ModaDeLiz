import '../../core/security/token_storage.dart';
import '../models/app_role.dart';
import '../models/branch.dart';
import '../models/session.dart';
import '../models/user.dart';
import 'auth_failure.dart';
import 'auth_repository.dart';

/// Repositorio simulado de autenticación con DATOS DE PRUEBA.
///
/// Sirve para avanzar mientras la API y el sistema de identidad no estén
/// disponibles. Los usuarios y la contraseña de ejemplo existen solo aquí.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(
    this._storage, {
    DateTime Function()? clock,
    this.delay = const Duration(milliseconds: 400),
    this.tokenLifetime = const Duration(hours: 8),
  }) : _clock = clock ?? DateTime.now;

  /// Contraseña de ejemplo, válida solo en el simulador.
  static const String demoPassword = 'demo1234';

  static const String sellerUsername = 'demo.vendedor';
  static const String managerUsername = 'demo.encargado';
  static const String adminUsername = 'demo.admin';
  static const String disabledUsername = 'demo.desactivado';

  final TokenStorage _storage;
  final DateTime Function() _clock;
  final Duration delay;
  final Duration tokenLifetime;

  static const _zacatlan = Branch(id: 'branch-zacatlan', name: 'Zacatlán');
  static const _huauchinango = Branch(
    id: 'branch-huauchinango',
    name: 'Huauchinango',
  );
  static const _xicotepec = Branch(id: 'branch-xicotepec', name: 'Xicotepec');

  static const Map<String, User> _users = {
    sellerUsername: User(
      id: 'demo-1',
      name: 'Ana Pérez (prueba)',
      role: AppRole.seller,
      branch: _zacatlan,
    ),
    managerUsername: User(
      id: 'demo-2',
      name: 'Luis Gómez (prueba)',
      role: AppRole.manager,
      branch: _huauchinango,
    ),
    adminUsername: User(
      id: 'demo-3',
      name: 'Dueña de Moda de Lizz (prueba)',
      role: AppRole.admin,
    ),
    disabledUsername: User(
      id: 'demo-4',
      name: 'Cuenta desactivada (prueba)',
      role: AppRole.seller,
      branch: _xicotepec,
    ),
  };

  @override
  Future<Session> login(String username, String password) async {
    await Future<void>.delayed(delay);
    final user = _users[username.trim()];
    if (user == null || password != demoPassword) {
      throw const AuthFailure(AuthFailureType.invalidCredentials);
    }
    if (username.trim() == disabledUsername) {
      throw const AuthFailure(AuthFailureType.accountDisabled);
    }
    final session = Session(
      accessToken: 'token-de-prueba-${user.id}',
      expiresAt: _clock().add(tokenLifetime),
      user: user,
    );
    // Un administrador no conserva sesión en el dispositivo.
    if (user.role != AppRole.admin) {
      await _storage.save(session);
    }
    return session;
  }

  @override
  Future<Session?> restoreSession() => restoreStoredSession(_storage, _clock());

  @override
  Future<void> logout() => _storage.clear();
}
