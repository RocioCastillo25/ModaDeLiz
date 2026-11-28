import '../repositories/auth_failure.dart';

/// Respuesta del endpoint de token de Keycloak (`grant_type=password`).
class TokenResponseDto {
  const TokenResponseDto({
    required this.accessToken,
    required this.expiresIn,
    this.refreshToken,
    this.refreshExpiresIn,
  });

  final String accessToken;

  /// Segundos de vigencia del token.
  final int expiresIn;

  /// Token para renovar la sesión. Puede faltar si Keycloak no lo entrega.
  final String? refreshToken;

  /// Segundos de vigencia del token de renovación (0 o ausente: sin dato).
  final int? refreshExpiresIn;

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
    final refresh = json['refresh_token'];
    final refreshExpires = json['refresh_expires_in'];
    return TokenResponseDto(
      accessToken: token,
      expiresIn: expiresIn.toInt(),
      refreshToken: (refresh is String && refresh.isNotEmpty) ? refresh : null,
      refreshExpiresIn: (refreshExpires is num && refreshExpires > 0)
          ? refreshExpires.toInt()
          : null,
    );
  }
}
