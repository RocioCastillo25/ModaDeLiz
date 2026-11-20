import 'user.dart';

/// Sesión de un usuario autenticado.
class Session {
  const Session({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  /// Token de acceso. Solo se guarda en almacenamiento seguro; nunca se imprime.
  final String accessToken;

  /// Momento en que la sesión deja de ser válida.
  final DateTime expiresAt;

  final User user;

  /// Indica si la sesión sigue vigente en [now] (por defecto, la hora actual).
  bool isValid({DateTime? now}) => expiresAt.isAfter(now ?? DateTime.now());

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
    return Session(
      accessToken: token,
      expiresAt: DateTime.parse(expires),
      user: User.fromJson(user),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'user': user.toJson(),
  };
}
