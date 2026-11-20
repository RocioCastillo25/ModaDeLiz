import '../../data/models/session.dart';
import 'token_storage.dart';

/// Almacenamiento en memoria. Se usa solo en pruebas; no persiste nada.
class InMemoryTokenStorage implements TokenStorage {
  Session? _session;

  @override
  Future<void> save(Session session) async => _session = session;

  @override
  Future<Session?> read() async => _session;

  @override
  Future<void> clear() async => _session = null;
}
