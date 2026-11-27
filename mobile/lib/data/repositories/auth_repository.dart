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

  /// Renueva la sesión guardada con el token de renovación y devuelve el
  /// token de acceso nuevo, o `null` si no se puede renovar (no hay sesión, no
  /// hay token de renovación o Keycloak lo rechaza).
  ///
  /// Lanza `AuthFailure` de tipo `network` o `server` si el fallo es de
  /// conexión: en ese caso la sesión no se descarta.
  Future<String?> refresh();
}

/// Lee la sesión guardada. Si el token de acceso venció pero se puede renovar,
/// la conserva (la primera petición la renovará); si no, la descarta.
Future<Session?> restoreStoredSession(TokenStorage storage, DateTime now) async {
  final session = await storage.read();
  if (session == null) return null;
  if (!session.isValid(now: now) && !session.canRefresh(now: now)) {
    await storage.clear();
    return null;
  }
  return session;
}
