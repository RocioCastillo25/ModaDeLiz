/// Configuración de la app tomada del entorno de compilación.
///
/// Se define al compilar o ejecutar con `--dart-define`, por ejemplo:
/// `flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://api.ejemplo.com`.
/// No se usan archivos `.env` ni se guardan direcciones en el repositorio.
class AppConfig {
  const AppConfig._();

  /// Dirección base de la API REST (HTTPS).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.invalid',
  );

  /// Si es `true`, la app usa repositorios simulados (datos de ejemplo).
  /// Mientras la API no esté disponible, el valor por defecto es `true`.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );
}
