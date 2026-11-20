# Investigación (Fase 0): Base de la app móvil e inicio de sesión

No quedan marcadores `NEEDS CLARIFICATION`. Las decisiones del contexto ya se resolvieron en `/speckit.clarify`; aquí se documentan las decisiones técnicas del plan.

## D1. Cliente HTTP: `dio`

- **Decisión**: usar `dio` como cliente HTTP.
- **Justificación**: la constitución exige un interceptor (Decorator) que agregue `Authorization: Bearer <token>`; `dio` trae interceptores, tiempos de espera y errores tipificados listos.
- **Alternativas**: `http` (oficial, sin interceptores, habría que escribir un envoltorio propio para agregar el token y mapear errores); `chopper` (genera código, es más peso del necesario).

## D2. Inyección de dependencias: `get_it`

- **Decisión**: `get_it`, como indica la constitución.
- **Justificación**: contenedor ligero; permite registrar `ApiClient` como singleton perezoso y alternar repositorios simulado y real desde un solo lugar.
- **Alternativas**: `provider` o `riverpod` (reemplazan el patrón MVVM con `ChangeNotifier` definido en `docs/reglas.md`).

## D3. Almacenamiento seguro: `flutter_secure_storage`

- **Decisión**: guardar el token y su expiración con `flutter_secure_storage`, detrás de la interfaz `TokenStorage`.
- **Justificación**: la constitución exige almacenamiento seguro del dispositivo; usa el llavero del sistema.
- **Alternativas**: `shared_preferences` (texto plano, prohibido por la constitución).

## D4. Estado y navegación sin paquetes adicionales

- **Decisión**: `ChangeNotifier` con `ListenableBuilder`, y `Navigator` de Flutter con una compuerta de sesión en `app.dart` (un `SessionViewModel` decide la pantalla visible).
- **Justificación**: con dos pantallas no se justifica un paquete de enrutamiento; menos dependencias que mantener.
- **Alternativas**: `go_router` (útil cuando haya muchas rutas con enlaces profundos; se reevalúa en el Sprint 2).

## D5. Aviso sin conexión: `connectivity_plus`

- **Decisión**: `ConnectivityService` (interfaz propia) respaldado por `connectivity_plus`; se consulta antes de enviar el inicio de sesión.
- **Justificación**: FR-018 pide avisar y no intentar el inicio de sesión sin internet. Además, los fallos de conexión durante la petición se mapean al mismo aviso.
- **Alternativas**: detectar solo por fallo de la petición (no cumple "no intentar"); `internet_connection_checker` (paquete extra con sondeos periódicos).

## D6. Contrato de acceso provisional

- **Decisión**: la app asume un endpoint `POST /auth/login` en la API que recibe usuario y contraseña y devuelve token, expiración y datos del usuario (ver [contracts/auth-api.md](contracts/auth-api.md)).
- **Justificación**: `docs/openapi.yaml` aún no existe y la regla I.2 prohíbe depender de Keycloak para operaciones de negocio. La API entregará la "respuesta de autenticación" con nombre, rol y sucursal, como describe `docs/sprint-1.md`.
- **Riesgo y mitigación**: los nombres de campo pueden cambiar. La conversión DTO a modelo (Adapter) aísla el cambio en `login_response_dto.dart`. Debe confirmarse con el Integrante 1.
- **Alternativas**: llamar al endpoint de token de Keycloak desde la app (contradice la regla I.2 y expone detalles del sistema de identidad).

## D7. Lectura de rol y sucursal

- **Decisión**: tomar rol y sucursal de la respuesta de acceso; si no vienen, intentar leer el rol de los datos del token (decodificación del payload sin verificar firma, solo para presentación). Si falta el rol o la sucursal, no se permite entrar (caso límite de la especificación).
- **Justificación**: la API es quien decide permisos; la app solo adapta lo que muestra.
- **Alternativas**: paquete de decodificación JWT (dependencia extra para algo que es base64 de una sola línea).

## D8. Expiración y 401

- **Decisión**: al abrir la app se compara la expiración guardada con la hora actual; si venció, se borra la sesión. Ante un 401 en cualquier petición, el interceptor notifica y se vuelve al inicio de sesión. Ante un 403 se muestra aviso sin cerrar sesión.
- **Justificación**: cumple FR-012 y FR-013. La constitución pide intentar renovar ante 401, pero el contrato aún no define renovación; se difiere (ver Verificación de la constitución en el plan).
- **Alternativas**: renovar con token de refresco (requiere endpoint y almacenamiento adicional que el contrato no ofrece todavía).

## D9. Administrador

- **Decisión**: el repositorio devuelve la sesión y la capa de presentación decide: si el rol es `ROLE_ADMIN`, se muestra `AdminNoticeView` y la sesión no se guarda (el repositorio no persiste el token de un administrador).
- **Justificación**: aclaración 1 de la especificación. La decisión de no guardar vive en el repositorio para que ninguna pantalla pueda omitirla por error.
- **Alternativas**: guardar y luego borrar (deja una ventana donde el token existe en el teléfono).

## D10. Tema, tipografía y movimiento

- **Decisión**: tema central en `core/theme` con la paleta de la sección 12; tipografía sans-serif del sistema (sin paquete de fuentes). Fondo con degradado `#1b1035` a `#3a1561`; superficies de vidrio con blanco al 10 % y borde sutil, sin desenfoque costoso en gama baja. El movimiento se reduce consultando `MediaQuery.disableAnimations`.
- **Justificación**: evita descargar fuentes y asegura arranque rápido; cumple la constitución IX y X.
- **Alternativas**: `google_fonts` (descarga en ejecución, dependencia extra).

## D11. Configuración por entorno

- **Decisión**: `--dart-define=API_BASE_URL=...` y `--dart-define=USE_MOCK=true|false`, leídos en `AppConfig`.
- **Justificación**: la regla de no subir `.env` y de configurar la dirección por entorno. El valor por defecto de `USE_MOCK` es `true` mientras no exista la API.
- **Alternativas**: archivo `.env` con paquete (prohibido subirlo y agrega dependencia).

## D12. Pruebas

- **Decisión**: pruebas de ViewModels con `flutter_test` y `MockAuthRepository` más dobles manuales de `TokenStorage` y `ConnectivityService`. Casos: éxito, credenciales incorrectas, cuenta desactivada, token expirado, administrador, sin conexión, 401 y 403, doble envío.
- **Justificación**: la constitución pide ViewModels sin interfaz y con repositorios simulados; los dobles manuales evitan otro paquete.
- **Alternativas**: `mocktail` (cómodo, pero innecesario con pocos dobles).

## D13. Instalable

- **Decisión**: APK de depuración o de lanzamiento firmado con la llave de depuración para la prueba de la dueña; firma de producción fuera de este sprint.
- **Justificación**: el objetivo es instalar y probar, no publicar en una tienda.
