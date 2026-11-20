import 'app_role.dart';
import 'branch.dart';

/// Usuario autenticado.
class User {
  const User({
    required this.id,
    required this.name,
    required this.role,
    this.branch,
  });

  final String id;
  final String name;
  final AppRole role;

  /// Sucursal asignada. Siempre viene de la respuesta de acceso, nunca de un
  /// campo editable. Es obligatoria para gerentes y empleados.
  final Branch? branch;

  /// Crea un usuario a partir del JSON de la API.
  /// Lanza [FormatException] si falta un dato obligatorio, si el rol es
  /// desconocido o si un rol que requiere sucursal no la trae.
  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Usuario sin identificador');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Usuario sin nombre');
    }
    final role = AppRole.tryParse(json['role'] as String?);
    if (role == null) {
      throw const FormatException('Rol desconocido');
    }
    final rawBranch = json['branch'];
    final branch = rawBranch is Map<String, dynamic>
        ? Branch.fromJson(rawBranch)
        : null;
    if (role.requiresBranch && branch == null) {
      throw const FormatException('Usuario sin sucursal asignada');
    }
    return User(id: id, name: name, role: role, branch: branch);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.code,
    if (branch != null) 'branch': branch!.toJson(),
  };
}
