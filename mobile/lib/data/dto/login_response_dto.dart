import '../models/session.dart';
import '../models/user.dart';
import '../repositories/auth_failure.dart';

/// Respuesta cruda de `POST /auth/login` (ver `contracts/auth-api.md`).
class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;

  /// Segundos de vigencia del token.
  final int expiresIn;

  /// Datos crudos del usuario.
  final Map<String, dynamic> user;

  /// Crea el DTO desde el JSON. Si falta un dato, falla con
  /// [AuthFailureType.incompleteData].
  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'];
    final expiresIn = json['expiresIn'];
    final user = json['user'];
    if (token is! String ||
        token.isEmpty ||
        expiresIn is! int ||
        expiresIn <= 0 ||
        user is! Map<String, dynamic>) {
      throw const AuthFailure(AuthFailureType.incompleteData);
    }
    return LoginResponseDto(
      accessToken: token,
      expiresIn: expiresIn,
      user: user,
    );
  }

  /// Adapter: convierte el DTO en una [Session] del modelo de la app.
  ///
  /// Falla con [AuthFailureType.incompleteData] si el rol es desconocido o si
  /// un rol que requiere sucursal no la trae.
  Session toSession({DateTime? now}) {
    try {
      return Session(
        accessToken: accessToken,
        expiresAt: (now ?? DateTime.now()).add(Duration(seconds: expiresIn)),
        user: User.fromJson(user),
      );
    } on FormatException {
      throw const AuthFailure(AuthFailureType.incompleteData);
    }
  }
}
