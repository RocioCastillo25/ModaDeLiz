/// Configuración de la app tomada del entorno de compilación.
///
/// Se define al compilar o ejecutar con `--dart-define`, por ejemplo:
/// `flutter run --dart-define=USE_MOCK=false
///   --dart-define=API_BASE_URL=https://api.ejemplo.com/api/v1
///   --dart-define=KEYCLOAK_BASE_URL=https://id.ejemplo.com`.
/// No se usan archivos `.env` ni se guardan direcciones en el repositorio.
class AppConfig {
  const AppConfig._();

  /// Dirección base de la API REST (por ejemplo `https://.../api/v1`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.invalid',
  );

  /// Dirección base de Keycloak, sin la ruta del realm.
  static const String keycloakBaseUrl = String.fromEnvironment(
    'KEYCLOAK_BASE_URL',
    defaultValue: 'https://keycloak.invalid',
  );

  /// Realm y cliente definidos en `docs/openapi.yaml`.
  static const String keycloakRealm = 'checklizz';
  static const String keycloakClientId = 'checklizz-app';

  /// Dirección del endpoint de token de Keycloak.
  static String keycloakTokenUrl([String base = keycloakBaseUrl]) =>
      '$base/realms/$keycloakRealm/protocol/openid-connect/token';

  /// Si es `true`, la app usa repositorios simulados (datos de ejemplo).
  /// Mientras la API no esté disponible, el valor por defecto es `true`.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );
}
