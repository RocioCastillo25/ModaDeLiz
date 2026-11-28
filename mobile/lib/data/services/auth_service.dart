import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../dto/branch_dto.dart';
import '../dto/profile_dto.dart';
import '../dto/token_response_dto.dart';

/// Llamadas HTTP del acceso, según `docs/openapi.yaml`:
/// 1. el token se pide a Keycloak con usuario y contraseña;
/// 2. el perfil sale de `GET /me`;
/// 3. el nombre de la sucursal sale de `GET /sucursales`.
class AuthService {
  AuthService(this._client, {String? tokenUrl})
    : _tokenUrl = tokenUrl ?? AppConfig.keycloakTokenUrl();

  final ApiClient _client;
  final String _tokenUrl;

  /// Pide el token a Keycloak. Lanza `ApiException` si responde con error.
  /// La contraseña viaja cifrada (HTTPS) y no se guarda en ningún lado.
  Future<TokenResponseDto> requestToken(String username, String password) async {
    final json = await _client.postForm(_tokenUrl, {
      'grant_type': 'password',
      'client_id': AppConfig.keycloakClientId,
      'username': username,
      'password': password,
    });
    return TokenResponseDto.fromJson(json);
  }

  /// Renueva el token con el `refresh_token` de Keycloak. Lanza
  /// `ApiException` si responde con error.
  Future<TokenResponseDto> refreshToken(String refreshToken) async {
    final json = await _client.postForm(_tokenUrl, {
      'grant_type': 'refresh_token',
      'client_id': AppConfig.keycloakClientId,
      'refresh_token': refreshToken,
    });
    return TokenResponseDto.fromJson(json);
  }

  /// `GET /me` con el token recién emitido.
  Future<ProfileDto> fetchProfile(String accessToken) async {
    final json = await _client.get('/me', headers: _bearer(accessToken));
    return ProfileDto.fromJson(json);
  }

  /// `GET /sucursales` con el token recién emitido.
  Future<List<BranchDto>> fetchBranches(String accessToken) async {
    final list = await _client.getList(
      '/sucursales',
      headers: _bearer(accessToken),
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(BranchDto.fromJson)
        .toList();
  }

  Map<String, String> _bearer(String token) => {
    'Authorization': 'Bearer $token',
  };
}
