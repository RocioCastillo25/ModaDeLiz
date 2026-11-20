import '../../core/security/token_storage.dart';
import '../models/session.dart';

/// Único punto de acceso a la autenticación para los ViewModels.
///
/// Tiene una implementación real (contra la API) y otra simulada, que se
/// intercambian desde el registro de dependencias.
abstract class AuthRepository {
  /// Inicia sesión. Lanza `AuthFailure` si no es posible.
  ///
  /// Si el usuario es administrador, devuelve la sesión pero NO la guarda en
  /// el dispositivo.
  Future<Session> login(String username, String password);

  /// Devuelve la sesión guardada si sigue vigente; si no, `null`.
  Future<Session?> restoreSession();

  /// Cierra la sesión y borra el token guardado.
  Future<void> logout();
}

/// Lee la sesión guardada y la descarta si ya venció.
Future<Session?> restoreStoredSession(TokenStorage storage, DateTime now) async {
  final session = await storage.read();
  if (session == null) return null;
  if (!session.isValid(now: now)) {
    await storage.clear();
    return null;
  }
  return session;
}
