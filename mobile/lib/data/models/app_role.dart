/// Rol de un usuario. Los roles se administran en el sistema de identidad.
enum AppRole {
  admin('ROLE_ADMIN', 'administrador', 'Administrador'),
  manager('ROLE_ENCARGADO', 'gerente', 'Gerente de tienda'),
  seller('ROLE_VENDEDOR', 'empleado', 'Empleado');

  const AppRole(this.code, this.apiName, this.label);

  /// Código de rol de Keycloak (por ejemplo `ROLE_VENDEDOR`). Es el que se
  /// guarda en el dispositivo.
  final String code;

  /// Nombre del rol en la API (`docs/openapi.yaml`): `administrador`,
  /// `gerente` o `empleado`.
  final String apiName;

  /// Etiqueta que se muestra en pantalla.
  final String label;

  /// El administrador no necesita sucursal; los demás roles sí.
  bool get requiresBranch => this != AppRole.admin;

  /// Convierte el código de Keycloak o el nombre de la API en un rol.
  /// Devuelve `null` si es desconocido.
  static AppRole? tryParse(String? value) {
    for (final role in AppRole.values) {
      if (role.code == value || role.apiName == value) return role;
    }
    return null;
  }
}
