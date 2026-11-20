import '../../data/models/session.dart';

/// Almacenamiento de la sesión en el dispositivo.
///
/// Solo guarda token, expiración y datos del usuario. Nunca la contraseña.
abstract class TokenStorage {
  Future<void> save(Session session);

  /// Devuelve la sesión guardada o `null` si no hay o está dañada.
  Future<Session?> read();

  Future<void> clear();
}
