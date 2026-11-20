# Tareas: Base de la app móvil e inicio de sesión

**Entrada**: Documentos de diseño en `specs/001-base-app-movil-login/`

**Requisitos previos**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Pruebas**: SÍ se incluyen. La constitución (principio XI) exige probar los ViewModels sin interfaz y con repositorios simulados, y cubrir los errores 401 y 403. Las pruebas de cada historia se escriben primero y deben fallar antes de implementar.

**Organización**: Las tareas se agrupan por historia de usuario para implementar y probar cada una de forma independiente.

## Formato: `[ID] [P?] [Historia] Descripción`

- **[P]**: se puede ejecutar en paralelo (archivos distintos, sin dependencias pendientes)
- **[US#]**: historia de usuario a la que pertenece (US1 a US5, según `spec.md`)
- Todas las rutas son relativas a la raíz del repositorio; el código vive en `mobile/`
- Cada campo con restricciones cita `data-model.md` con su `Entidad.campo`

## Convenciones de rutas

- Código: `mobile/lib/` (capas `core/`, `data/`, `features/`, `shared/`)
- Pruebas: `mobile/test/`
- Identificadores y archivos de código en inglés; comentarios, textos de interfaz y nombres de pruebas en español

---

## Fase 1: Preparación (infraestructura compartida)

**Propósito**: crear el proyecto Flutter y dejar lista su configuración base

- [X] T001 Crear el proyecto Flutter en `mobile/` con `flutter create --org com.modadelizz --project-name checklizz --platforms android,ios mobile`
- [X] T002 Agregar en `mobile/pubspec.yaml` las dependencias `get_it`, `dio`, `flutter_secure_storage` y `connectivity_plus` (justificadas en `research.md` D1 a D5) y ejecutar `flutter pub get`
- [X] T003 [P] Configurar reglas de análisis estático en `mobile/analysis_options.yaml`
- [X] T004 [P] Configurar en `mobile/android/app/src/main/AndroidManifest.xml` el permiso de internet, el nombre visible "CheckLizz" y la orientación vertical
- [X] T005 [P] Agregar a `mobile/.gitignore` las exclusiones de `.env`, `*.jks` y `key.properties` para no subir secretos

---

## Fase 2: Fundamentos (prerrequisitos bloqueantes)

**Propósito**: modelos, interfaces, red y DI que necesitan todas las historias

**⚠️ CRÍTICO**: ninguna historia puede empezar hasta terminar esta fase

- [X] T006 [P] Crear `mobile/lib/core/config/app_config.dart` con `API_BASE_URL` y `USE_MOCK` leídos de `--dart-define` (valor por defecto de `USE_MOCK`: `true`), según `research.md` D11
- [X] T007 [P] Crear la enumeración `AppRole` en `mobile/lib/data/models/app_role.dart` según `data-model.md` AppRole (valores `admin`, `manager`, `seller`; rechaza roles desconocidos; etiquetas Administrador, Gerente de tienda y Empleado)
- [X] T008 [P] Crear `Branch` en `mobile/lib/data/models/branch.dart` con `fromJson`, según `data-model.md` Branch.id y Branch.name
- [X] T009 [P] Crear `User` en `mobile/lib/data/models/user.dart` con `fromJson`, según `data-model.md` User.role y User.branch (la sucursal es obligatoria para `manager` y `seller`)
- [X] T010 Crear `Session` en `mobile/lib/data/models/session.dart` con la propiedad derivada `isValid`, según `data-model.md` Session.expiresAt (depende de T007, T008, T009)
- [X] T011 [P] Crear los errores tipados `AuthFailure` (`invalidCredentials`, `accountDisabled`, `incompleteData`, `network`, `server`) en `mobile/lib/data/repositories/auth_failure.dart` y `ApiException` sin detalles técnicos en `mobile/lib/core/network/api_exception.dart`
- [X] T012 [P] Crear la interfaz `TokenStorage` en `mobile/lib/core/security/token_storage.dart` (`save`, `read`, `clear`), según `contracts/internal-interfaces.md`
- [X] T013 [P] Crear la interfaz `ConnectivityService` en `mobile/lib/data/services/connectivity_service.dart` (`isOnline`)
- [X] T014 Crear la interfaz `AuthRepository` en `mobile/lib/data/repositories/auth_repository.dart` (`login`, `restoreSession`, `logout`), según `contracts/internal-interfaces.md` (depende de T010, T011)
- [X] T015 Crear `LoginResponseDto` con el Adapter a `Session` en `mobile/lib/data/dto/login_response_dto.dart`, según `contracts/auth-api.md` y `data-model.md` LoginResponseDto; falla con `incompleteData` si falta rol o sucursal requerida (depende de T010)
- [X] T016 Crear `MockAuthRepository` en `mobile/lib/data/repositories/mock_auth_repository.dart` con los 4 usuarios de ejemplo de `contracts/internal-interfaces.md`, identificados como de prueba, persistiendo la sesión a través de `TokenStorage` (depende de T012, T014, T015)
- [X] T017 [P] Prueba de `Session`, `AppRole` y `User` (vigencia, rol desconocido, sucursal obligatoria) en `mobile/test/data/session_test.dart`
- [X] T018 Prueba de `MockAuthRepository` (los 4 usuarios, contraseña incorrecta, cuenta desactivada) en `mobile/test/data/mock_auth_repository_test.dart` (depende de T016)
- [X] T019 Crear `ApiClient` como singleton perezoso sobre `dio`, con dirección tomada de `AppConfig`, en `mobile/lib/core/network/api_client.dart` (depende de T006, T011)
- [X] T020 Crear el interceptor Decorator que agrega `Authorization: Bearer <token>` y notifica los 401 en `mobile/lib/core/network/auth_interceptor.dart` (depende de T012, T019)
- [X] T021 Prueba del interceptor (agrega el encabezado, notifica 401, no cierra sesión en 403) en `mobile/test/core/auth_interceptor_test.dart` (depende de T020)
- [X] T022 Crear `SessionViewModel` (estados `restoring`, `authenticated`, `unauthenticated`) en `mobile/lib/features/auth/session_view_model.dart`, sin importar `material.dart` (depende de T014)
- [X] T023 Crear el registro de dependencias inicial en `mobile/lib/core/di/service_locator.dart` con `ApiClient` singleton perezoso, `MockAuthRepository` y `SessionViewModel`; las dependencias llegan por constructor (depende de T016, T019, T020, T022)

**Punto de control**: fundamentos listos; pueden empezar las historias.

---

## Fase 3: Historia de usuario 5 - Base de la app con datos de ejemplo e imagen de CheckLizz (Prioridad: P1) 🎯

**Objetivo**: tema visual central, componentes compartidos, implementaciones reales de los servicios y alternancia entre datos de ejemplo y reales sin tocar pantallas.

**Prueba independiente**: las pruebas de esta fase pasan y los componentes compartidos se ven con la paleta del tema; el escenario visual completo se valida con la pantalla de la Fase 4.

### Pruebas de la Historia 5

- [X] T024 [P] [US5] Prueba de `ApiAuthRepository` con un `AuthService` simulado (éxito, 401 a credenciales incorrectas, 403 a cuenta desactivada, sin conexión, 5xx) en `mobile/test/data/api_auth_repository_test.dart`
- [X] T025 [P] [US5] Prueba de que `USE_MOCK` selecciona `MockAuthRepository` o `ApiAuthRepository` sin cambiar ViewModels en `mobile/test/core/service_locator_test.dart`

### Implementación de la Historia 5

- [X] T026 [P] [US5] Crear la paleta en `mobile/lib/core/theme/app_colors.dart` (rosa pastel y blanco, según la sección 12 de `docs/project-context.md`: fondo `#ffd9ea` a `#ffffff`; rosa `#d6338a`, rosa pastel `#f9a8d4`, violeta `#7c5ce0`, ámbar `#a86400`; vidrio blanco al 60 %)
- [X] T027 [P] [US5] Crear `mobile/lib/core/theme/motion.dart` que reduce o elimina animaciones según `MediaQuery.disableAnimations`
- [X] T028 [US5] Crear `mobile/lib/core/theme/app_theme.dart` con tipografía sans-serif del sistema, botones grandes y foco visible (depende de T026)
- [X] T029 [P] [US5] Crear `mobile/lib/shared/gradient_background.dart`
- [X] T030 [P] [US5] Crear `mobile/lib/shared/glass_card.dart` (vidrio discreto, borde sutil, esquinas redondeadas)
- [X] T031 [P] [US5] Crear `mobile/lib/shared/primary_button.dart` (degradado de rosa a rosa fuerte, grande, deshabilitado mientras carga)
- [X] T032 [P] [US5] Crear `mobile/lib/shared/error_message.dart` (mensaje claro con botón de reintentar, sin detalles técnicos)
- [X] T033 [P] [US5] Crear `SecureTokenStorage` sobre `flutter_secure_storage` en `mobile/lib/core/security/secure_token_storage.dart`
- [X] T034 [P] [US5] Crear `ConnectivityPlusService` en `mobile/lib/data/services/connectivity_plus_service.dart`
- [X] T035 [P] [US5] Crear `AuthService` (llamada `POST /auth/login` con `ApiClient`) en `mobile/lib/data/services/auth_service.dart`, según `contracts/auth-api.md`
- [X] T036 [US5] Crear `ApiAuthRepository` en `mobile/lib/data/repositories/api_auth_repository.dart` (mapea códigos HTTP a `AuthFailure`; usa `LoginResponseDto`) (depende de T033, T035)
- [X] T037 [US5] Actualizar `mobile/lib/core/di/service_locator.dart` para registrar `SecureTokenStorage` y `ConnectivityPlusService` y alternar `MockAuthRepository` y `ApiAuthRepository` con `AppConfig.useMock` (depende de T034, T036)

**Punto de control**: la base visual y la alternancia de datos están listas.

---

## Fase 4: Historia de usuario 1 - Iniciar sesión y ver la pantalla principal (Prioridad: P1) 🎯 MVP

**Objetivo**: un empleado o gerente entra con usuario y contraseña y ve su nombre, rol y sucursal.

**Prueba independiente**: con `demo.vendedor` se llega a la pantalla principal con nombre, "Empleado" y "Zacatlán"; los escenarios 3, 4, 5, 7 y 8 del `quickstart.md` se comportan como se describe.

### Pruebas de la Historia 1 (escribir primero; deben fallar)

- [X] T038 [P] [US1] Pruebas de `LoginViewModel` con repositorio simulado: éxito, credenciales incorrectas, cuenta desactivada, campos vacíos o solo espacios sin llamar al repositorio, doble envío ignorado, sin conexión, servicio caído y datos incompletos, en `mobile/test/features/auth/login_view_model_test.dart`
- [X] T039 [P] [US1] Pruebas de `HomeViewModel` (nombre, etiqueta de rol, sucursal y secciones futuras deshabilitadas con "próximamente") en `mobile/test/features/home/home_view_model_test.dart`

### Implementación de la Historia 1

- [X] T040 [US1] Crear `LoginViewModel` (estados `idle`, `loading`, `error`; validación mínima de campos; bloqueo de doble envío; consulta de `ConnectivityService` antes de enviar) en `mobile/lib/features/auth/login_view_model.dart`, según `data-model.md` (Estado de la pantalla y Validaciones)
- [X] T041 [US1] Crear `HomeViewModel` en `mobile/lib/features/home/home_view_model.dart` con los datos del usuario y las secciones buscar, escanear y traspasos "próximamente"
- [X] T042 [P] [US1] Crear `LoginView` en `mobile/lib/features/auth/login_view.dart` con el nombre "CheckLizz", formulario de usuario y contraseña, botón "Iniciar sesión" deshabilitado mientras carga y textos en español
- [X] T043 [P] [US1] Crear `HomeView` en `mobile/lib/features/home/home_view.dart` con tarjeta de vidrio de nombre, rol y sucursal, y los accesos "próximamente"
- [X] T044 [US1] Crear `mobile/lib/app.dart` con `MaterialApp`, el tema central y la compuerta de sesión (muestra `LoginView` o `HomeView` según `SessionViewModel`) (depende de T040, T041, T042, T043)
- [X] T045 [US1] Crear `mobile/lib/main.dart` que inicializa el registro de dependencias y ejecuta la app (depende de T044)
- [X] T046 [US1] Validar los escenarios 1, 2, 3, 4, 5, 7 y 8 de `specs/001-base-app-movil-login/quickstart.md` en emulador Android

**Punto de control**: la Historia 1 funciona de forma independiente (MVP).

---

## Fase 5: Historia de usuario 2 - Cerrar sesión (Prioridad: P2)

**Objetivo**: cerrar sesión borra el token, limpia el estado y regresa al inicio de sesión.

**Prueba independiente**: iniciar sesión, pulsar "Cerrar sesión" y comprobar que al reabrir la app se pide iniciar sesión.

- [X] T047 [P] [US2] Pruebas de cierre de sesión (borra el token, pasa a `unauthenticated`, limpia el estado de `LoginViewModel` y `HomeViewModel`) en `mobile/test/features/auth/session_view_model_test.dart`
- [X] T048 [US2] Implementar `logout()` en `mobile/lib/features/auth/session_view_model.dart` y en ambos repositorios (`mobile/lib/data/repositories/mock_auth_repository.dart` y `api_auth_repository.dart`), con limpieza del estado de los demás ViewModels registrados (depende de T047)
- [X] T049 [US2] Conectar el botón "Cerrar sesión" en `mobile/lib/features/home/home_view.dart` y `mobile/lib/features/home/home_view_model.dart` (depende de T048)
- [X] T050 [US2] Validar el escenario 10 de `quickstart.md`

**Punto de control**: las Historias 1 y 2 funcionan de forma independiente.

---

## Fase 6: Historia de usuario 3 - Sesión persistente y expiración (Prioridad: P2)

**Objetivo**: con sesión vigente se entra directo; con sesión vencida o rechazada (401) se vuelve al inicio de sesión con aviso, sin renovación.

**Prueba independiente**: iniciar sesión, cerrar la app y reabrirla; luego simular vencimiento y reabrir.

- [X] T051 [P] [US3] Pruebas de restauración: sesión vigente entra directo, sesión vencida se borra y pide iniciar sesión, 401 vuelve al inicio con aviso, 403 muestra aviso sin cerrar sesión, en `mobile/test/features/auth/session_restore_test.dart`
- [X] T052 [US3] Implementar `restoreSession()` en `mobile/lib/data/repositories/mock_auth_repository.dart` y `mobile/lib/data/repositories/api_auth_repository.dart`, comparando Session.expiresAt de `data-model.md` con la hora actual y borrando la sesión vencida
- [X] T053 [US3] Implementar `restore()` en `mobile/lib/features/auth/session_view_model.dart` y una pantalla de espera mientras restaura en `mobile/lib/app.dart` (depende de T052)
- [X] T054 [US3] Implementar `onSessionRejected()` y conectar el aviso de 401 del interceptor (`mobile/lib/core/network/auth_interceptor.dart`) con `SessionViewModel`; mostrar un aviso de falta de permisos en 403 sin cerrar sesión (depende de T053)
- [X] T055 [US3] Mostrar el aviso "tu sesión venció" en `mobile/lib/features/auth/login_view.dart` cuando se vuelve por vencimiento o rechazo
- [ ] T056 [US3] Validar los escenarios 9 y 11 de `quickstart.md`

**Punto de control**: las Historias 1 a 3 funcionan de forma independiente.

---

## Fase 7: Historia de usuario 4 - Comportamiento por rol (Prioridad: P3)

**Objetivo**: el administrador ve un aviso que lo dirige a la web; no accede a la pantalla principal y su sesión no se conserva.

**Prueba independiente**: iniciar sesión con `demo.admin` y comprobar el aviso; reabrir la app y comprobar que se pide iniciar sesión.

- [X] T057 [P] [US4] Pruebas: el administrador no persiste token, `LoginViewModel` expone el aviso y empleado y gerente no lo ven, en `mobile/test/features/auth/admin_notice_test.dart`
- [X] T058 [P] [US4] Crear `AdminNoticeView` en `mobile/lib/features/auth/admin_notice_view.dart` con el mensaje que dirige a la página web y un botón para volver al inicio de sesión
- [X] T059 [US4] Garantizar en `mobile/lib/data/repositories/mock_auth_repository.dart` y `api_auth_repository.dart` que no se guarda el token cuando el rol es `admin` (`research.md` D9) (depende de T057)
- [X] T060 [US4] Exponer el aviso de administrador en `mobile/lib/features/auth/login_view_model.dart` y mostrarlo desde la compuerta de `mobile/lib/app.dart` (depende de T058, T059)
- [X] T061 [US4] Validar el escenario 6 de `quickstart.md`

**Punto de control**: todas las historias funcionan de forma independiente.

---

## Fase 8: Pulido y asuntos transversales

**Propósito**: calidad, documentación y entrega del sprint

- [X] T062 [P] Revisar que todos los textos de interfaz estén en español con tildes y signos de apertura correctos en `mobile/lib/`
- [X] T063 [P] Verificar que no existan colores sueltos fuera de `mobile/lib/core/theme/` y que ninguna View importe un Service o `dio` (`mobile/lib/features/`, `mobile/lib/shared/`)
- [X] T064 Ejecutar `flutter analyze` y `flutter test` en `mobile/` y corregir los hallazgos
- [X] T065 [P] Escribir `mobile/README.md` en español (cómo ejecutar con `USE_MOCK`, usuarios de ejemplo, cómo cambiar a la API real y cómo generar el APK)
- [ ] T066 Ejecutar el `quickstart.md` completo, incluidos los escenarios 12 (reducir animaciones) y 13 (accesos "próximamente"), en un emulador o dispositivo Android
- [X] T067 Generar el APK de prueba con `flutter build apk --release --dart-define=USE_MOCK=true` y probarlo en un dispositivo Android
- [ ] T068 Reunir la evidencia para la bitácora (capturas del inicio de sesión y de la pantalla principal) y coordinar con el Integrante 4 la etiqueta `v0.1.0` y el Pull Request desde una rama `feature/mobile-*` (sin commit ni etiqueta hasta que el usuario lo pida)

---

## Dependencias y orden de ejecución

### Dependencias entre fases

- **Preparación (Fase 1)**: sin dependencias.
- **Fundamentos (Fase 2)**: depende de la Fase 1 y bloquea todas las historias.
- **Historias (Fases 3 a 7)**: dependen de la Fase 2.
  - US5 (Fase 3) conviene primero: aporta tema, componentes y servicios reales que usa US1.
  - US1 (Fase 4) depende de US5 para tema y componentes.
  - US2, US3 y US4 dependen de US1, porque extienden `SessionViewModel`, `LoginViewModel` y `app.dart`.
- **Pulido (Fase 8)**: depende de las historias deseadas.

### Dependencias entre historias

- **US5 (P1)**: tras la Fase 2; sin dependencia de otras historias.
- **US1 (P1)**: tras US5; es el MVP.
- **US2 (P2)**: tras US1.
- **US3 (P2)**: tras US1; puede ir en paralelo con US2 si se coordinan los cambios en `session_view_model.dart` y `app.dart`.
- **US4 (P3)**: tras US1.

### Dentro de cada historia

- Las pruebas se escriben primero y deben fallar.
- Modelos, luego repositorios, luego ViewModels, luego Views.
- Se completa la historia antes de pasar a la siguiente prioridad.

### Oportunidades de paralelismo

- Fase 1: T003, T004 y T005.
- Fase 2: T006 a T009; T011 a T013; T017.
- Fase 3: T024 y T025; T026, T027 y T029 a T035.
- Fase 4: T038 y T039; T042 y T043.
- Historias US2, US3 y US4 en paralelo si hay varias personas, cuidando los archivos compartidos.

---

## Ejemplo de paralelismo: Historia 1

```text
# Pruebas de la Historia 1 en paralelo:
Tarea: "Pruebas de LoginViewModel en mobile/test/features/auth/login_view_model_test.dart"
Tarea: "Pruebas de HomeViewModel en mobile/test/features/home/home_view_model_test.dart"

# Pantallas de la Historia 1 en paralelo:
Tarea: "Crear LoginView en mobile/lib/features/auth/login_view.dart"
Tarea: "Crear HomeView en mobile/lib/features/home/home_view.dart"
```

---

## Estrategia de implementación

### Primero el MVP (Historia 1)

1. Fase 1: Preparación.
2. Fase 2: Fundamentos (bloquea todo).
3. Fase 3: US5 (tema, servicios reales y alternancia).
4. Fase 4: US1 (inicio de sesión y pantalla principal).
5. **DETENER Y VALIDAR**: probar el inicio de sesión de forma independiente con el repositorio simulado.

### Entrega incremental

1. Preparación y Fundamentos listos.
2. US5 y US1: MVP demostrable.
3. US2: cierre de sesión.
4. US3: sesión persistente y expiración.
5. US4: aviso para administrador.
6. Pulido, APK y evidencia para la bitácora.

---

## Notas

- Las tareas [P] usan archivos distintos y no tienen dependencias pendientes.
- La etiqueta [US#] enlaza cada tarea con su historia para dar trazabilidad.
- No se modifican `api/`, `infra/` ni `web/`.
- Confirmar que las pruebas fallan antes de implementar.
- Hacer commit solo cuando el usuario lo pida, en formato Conventional Commits con la descripción en español.
