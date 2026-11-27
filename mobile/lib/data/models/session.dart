import 'user.dart';

/// Sesión de un usuario autenticado.
class Session {
  const Session({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
    this.refreshToken,
    this.refreshExpiresAt,
  });

  /// Token de acceso. Solo se guarda en almacenamiento seguro; nunca se imprime.
  final String accessToken;

  /// Momento en que la sesión deja de ser válida.
  final DateTime expiresAt;

  final User user;

  /// Token para renovar la sesión sin pedir la contraseña. Solo se guarda en
  /// almacenamiento seguro; nunca se imprime. Puede faltar.
  final String? refreshToken;

  /// Momento en que el token de renovación deja de servir. Si falta, se asume
  /// vigente hasta que Keycloak lo rechace.
  final DateTime? refreshExpiresAt;

  /// Indica si la sesión sigue vigente en [now] (por defecto, la hora actual).
  bool isValid({DateTime? now}) => expiresAt.isAfter(now ?? DateTime.now());

  /// Indica si se puede renovar la sesión en [now].
  bool canRefresh({DateTime? now}) {
    if (refreshToken == null || refreshToken!.isEmpty) return false;
    final limit = refreshExpiresAt;
    return limit == null || limit.isAfter(now ?? DateTime.now());
  }

  /// Copia con un token nuevo tras renovar la sesión.
  Session withTokens({
    required String accessToken,
    required DateTime expiresAt,
    String? refreshToken,
    DateTime? refreshExpiresAt,
  }) => Session(
    accessToken: accessToken,
    expiresAt: expiresAt,
    user: user,
    refreshToken: refreshToken ?? this.refreshToken,
    refreshExpiresAt: refreshToken != null
        ? refreshExpiresAt
        : this.refreshExpiresAt,
  );

  factory Session.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'];
    final expires = json['expiresAt'];
    final user = json['user'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Sesión sin token');
    }
    if (expires is! String || DateTime.tryParse(expires) == null) {
      throw const FormatException('Sesión sin expiración válida');
    }
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Sesión sin usuario');
    }
    // Las sesiones guardadas por el Sprint 1 no traen estos campos.
    final refresh = json['refreshToken'];
    final refreshExpires = json['refreshExpiresAt'];
    return Session(
      accessToken: token,
      expiresAt: DateTime.parse(expires),
      user: User.fromJson(user),
      refreshToken: (refresh is String && refresh.isNotEmpty) ? refresh : null,
      refreshExpiresAt: refreshExpires is String
          ? DateTime.tryParse(refreshExpires)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'user': user.toJson(),
    if (refreshToken != null) 'refreshToken': refreshToken,
    if (refreshExpiresAt != null)
      'refreshExpiresAt': refreshExpiresAt!.toUtc().toIso8601String(),
  };
}
