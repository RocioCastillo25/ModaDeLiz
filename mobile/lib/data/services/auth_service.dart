import '../../core/network/api_client.dart';
import '../dto/login_response_dto.dart';

/// Llamadas HTTP de acceso (ver `contracts/auth-api.md`).
class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  /// `POST /auth/login`. Lanza `ApiException` si la API responde con error.
  Future<LoginResponseDto> login(String username, String password) async {
    final json = await _client.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return LoginResponseDto.fromJson(json);
  }
}
