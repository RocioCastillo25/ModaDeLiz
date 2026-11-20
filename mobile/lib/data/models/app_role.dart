/// Rol de un usuario. Los roles se administran en el sistema de identidad.
enum AppRole {
  admin('ROLE_ADMIN', 'Administrador'),
  manager('ROLE_ENCARGADO', 'Gerente de tienda'),
  seller('ROLE_VENDEDOR', 'Empleado');

  const AppRole(this.code, this.label);

  /// Código que usa la API (por ejemplo `ROLE_VENDEDOR`).
  final String code;

  /// Etiqueta que se muestra en pantalla.
  final String label;

  /// El administrador no necesita sucursal; los demás roles sí.
  bool get requiresBranch => this != AppRole.admin;

  /// Convierte el código de la API en un rol. Devuelve `null` si es desconocido.
  static AppRole? tryParse(String? code) {
    for (final role in AppRole.values) {
      if (role.code == code) return role;
    }
    return null;
  }
}
