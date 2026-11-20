import '../models/app_role.dart';
import '../models/branch.dart';
import '../models/user.dart';
import '../repositories/auth_failure.dart';

/// Perfil tal como lo entrega `GET /me` (`docs/openapi.yaml`).
class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.name,
    required this.role,
    this.branchId,
  });

  final int id;
  final String name;

  /// Nombre del rol en la API: `administrador`, `gerente` o `empleado`.
  final String role;

  /// Identificador de la sucursal asignada. Puede faltar para el administrador.
  final int? branchId;

  /// Crea el DTO desde el JSON. Si falta un dato, falla con
  /// [AuthFailureType.incompleteData].
  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['nombre'];
    final role = json['rol'];
    final branchId = json['sucursalId'];
    if (id is! num ||
        name is! String ||
        name.trim().isEmpty ||
        role is! String ||
        (branchId != null && branchId is! num)) {
      throw const AuthFailure(AuthFailureType.incompleteData);
    }
    return ProfileDto(
      id: id.toInt(),
      name: name,
      role: role,
      branchId: (branchId as num?)?.toInt(),
    );
  }

  /// Rol de la app, o `null` si la API envió uno desconocido.
  AppRole? get appRole => AppRole.tryParse(role);

  /// Adapter: convierte el DTO en el modelo [User]. Falla con
  /// [AuthFailureType.incompleteData] si el rol es desconocido o si un rol que
  /// requiere sucursal no la trae.
  User toUser(Branch? branch) {
    final appRole = this.appRole;
    if (appRole == null || (appRole.requiresBranch && branch == null)) {
      throw const AuthFailure(AuthFailureType.incompleteData);
    }
    return User(
      id: id.toString(),
      name: name,
      role: appRole,
      branch: branch,
    );
  }
}
