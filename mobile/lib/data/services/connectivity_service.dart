/// Informa si el dispositivo tiene conexión a internet.
abstract class ConnectivityService {
  Future<bool> isOnline();
}
