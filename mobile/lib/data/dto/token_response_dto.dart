import '../repositories/auth_failure.dart';

/// Respuesta del endpoint de token de Keycloak (`grant_type=password`).
class TokenResponseDto {
  const TokenResponseDto({required this.accessToken, required this.expiresIn});

  final String accessToken;

  /// Segundos de vigencia del token.
  final int expiresIn;

  /// Crea el DTO desde el JSON. Si falta un dato, falla con
  /// [AuthFailureType.incompleteData].
  factory TokenResponseDto.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    final expiresIn = json['expires_in'];
    if (token is! String ||
        token.isEmpty ||
        expiresIn is! num ||
        expiresIn <= 0) {
      throw const AuthFailure(AuthFailureType.incompleteData);
    }
    return TokenResponseDto(
      accessToken: token,
      expiresIn: expiresIn.toInt(),
    );
  }
}
