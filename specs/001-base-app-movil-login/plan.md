# Plan de implementación: Base de la app móvil e inicio de sesión

**Rama**: `001-base-app-movil-login` | **Fecha**: 2026-11-20 | **Especificación**: [spec.md](spec.md)

**Entrada**: Especificación de la funcionalidad en `specs/001-base-app-movil-login/spec.md`

## Resumen

Se construye el proyecto Flutter en `mobile/` con la arquitectura MVVM y `ChangeNotifier`, inyección de dependencias con `get_it`, el tema visual de CheckLizz y un inicio de sesión con formulario propio (usuario y contraseña). El acceso funciona con un repositorio simulado (usuarios de ejemplo por rol) y con uno real contra la API, intercambiables desde el registro de dependencias sin tocar pantallas ni ViewModels. La sesión se guarda en almacenamiento seguro, se restaura al abrir la app y se descarta al cerrar sesión o al expirar. Un administrador recibe un aviso que lo dirige a la web y su sesión no se conserva.

## Contexto técnico

**Lenguaje/Versión**: Dart 3 con Flutter 3.47.2 (canal estable)

**Dependencias principales**: `get_it` (inyección de dependencias), `dio` (cliente HTTP con interceptores), `flutter_secure_storage` (almacenamiento seguro del token), `connectivity_plus` (aviso sin conexión). Justificación en [research.md](research.md).

**Almacenamiento**: Almacenamiento seguro del dispositivo, solo para la sesión (token y fecha de expiración). No se guarda la contraseña.

**Pruebas**: `flutter_test` con repositorios simulados escritos a mano (sin paquetes de simulación)

**Plataforma objetivo**: Android (primera entrega, con APK de prueba); iPhone se prevé cuando haya equipo para compilar. Código base único.

**Tipo de proyecto**: Aplicación móvil

**Metas de rendimiento**: Llegar a la pantalla principal en menos de 10 segundos desde que se abre la app e inicia sesión (SC-001); entrar a la pantalla principal de inmediato con sesión vigente; animaciones breves que no retrasan ninguna acción.

**Restricciones**: Sin modo sin conexión (se avisa y se bloquea el inicio de sesión); sin guardar contraseña; textos en español; sin precios ni funciones de sprints posteriores; dirección de la API configurable por entorno y sin archivos `.env` en el repositorio.

**Escala/Alcance**: 2 pantallas funcionales (inicio de sesión y principal) más un aviso para administrador; unos 25 empleados y 5 gerentes en 5 sucursales.

## Verificación de la constitución

*PUERTA: debe pasar antes de la investigación de la Fase 0. Se vuelve a verificar tras el diseño de la Fase 1.*

| Principio | Evaluación | Estado |
|-----------|------------|--------|
| I. Arquitectura y límites | Todo en `mobile/`; solo consume la API REST; las reglas de negocio (cuenta desactivada, credenciales) las decide la API; no se toca `api/`, `infra/` ni `web/`. Paquetes nuevos justificados en `research.md`. | Cumple |
| II. MVVM con ChangeNotifier | Un ViewModel por pantalla en `features/<nombre>/`; las Views no llaman a Services; los ViewModels no importan `material.dart`. | Cumple |
| III. Estructura, patrones y DI | Estructura de `lib/` según la constitución; `ApiClient` singleton perezoso en `get_it`; interceptor Decorator; `fromJson` en modelos; `AuthRepository` con implementación real y simulada intercambiables. | Cumple |
| IV. Autenticación y sesión | Token solo en almacenamiento seguro; sin contraseña guardada; mensaje genérico; 401 vuelve al inicio de sesión; 403 muestra aviso sin cerrar sesión; cerrar sesión limpia token y ViewModels. | Cumple con matiz (ver abajo) |
| V. Roles y permisos | Roles `ROLE_*` leídos de la respuesta de acceso o del token; la sucursal viene del usuario autenticado, nunca de un campo editable. | Cumple |
| VI y VII. Inventario, traspasos | No aplican en este sprint. | N/A |
| VIII. Errores y estados | Cargando, éxito y error visibles; reintento; sin detalles técnicos; sin internet se bloquea el inicio de sesión; botón deshabilitado en curso. | Cumple |
| IX y X. Interfaz y diseño | Colores solo desde `core/theme`; reducir movimiento respetado; paleta y glassmorphism de la sección 12. | Cumple |
| XI. Pruebas | ViewModels de autenticación sin interfaz y con repositorio simulado; casos 401 y 403 cubiertos. | Cumple |

**Matiz (principio IV, renovación de sesión)**: la constitución pide intentar renovar la sesión ante un 401, pero `docs/sprint-1.md` y la especificación (FR-013) piden volver al inicio de sesión. Decisión confirmada en `/speckit.clarify` (2026-11-20): en este sprint se vuelve directo al inicio de sesión; la renovación queda fuera hasta que el contrato de la API defina un endpoint de renovación. No es una violación: es una renovación "no posible" con el contrato actual. Se registra en `research.md`.

**Evaluación tras el diseño de la Fase 1**: sin cambios; el diseño no introduce violaciones.

## Estructura del proyecto

### Documentación (esta funcionalidad)

```text
specs/001-base-app-movil-login/
├── plan.md              # Este archivo
├── research.md          # Fase 0
├── data-model.md        # Fase 1
├── quickstart.md        # Fase 1
├── contracts/           # Fase 1
│   ├── auth-api.md
│   └── internal-interfaces.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Fase 2 (lo crea /speckit.tasks)
```

### Código fuente (raíz del repositorio)

```text
mobile/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart                         # MaterialApp, tema y compuerta de sesión
│   ├── core/
│   │   ├── di/service_locator.dart      # registro get_it; alterna simulado/real
│   │   ├── config/app_config.dart       # URL de la API por entorno y modo simulado
│   │   ├── network/
│   │   │   ├── api_client.dart          # Singleton perezoso
│   │   │   ├── auth_interceptor.dart    # Decorator: agrega Authorization
│   │   │   └── api_exception.dart       # errores sin detalles técnicos
│   │   ├── security/
│   │   │   ├── token_storage.dart       # interfaz de almacenamiento seguro
│   │   │   └── secure_token_storage.dart
│   │   └── theme/
│   │       ├── app_colors.dart
│   │       ├── app_theme.dart
│   │       └── motion.dart              # reducir movimiento
│   ├── data/
│   │   ├── models/                      # user.dart, session.dart, branch.dart, app_role.dart
│   │   ├── dto/                         # login_response_dto.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart     # interfaz
│   │   │   ├── api_auth_repository.dart
│   │   │   └── mock_auth_repository.dart
│   │   └── services/
│   │       ├── auth_service.dart        # llamadas HTTP de acceso
│   │       └── connectivity_service.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_view.dart
│   │   │   ├── login_view_model.dart
│   │   │   └── admin_notice_view.dart
│   │   └── home/
│   │       ├── home_view.dart
│   │       └── home_view_model.dart
│   └── shared/
│       ├── glass_card.dart
│       ├── primary_button.dart
│       ├── gradient_background.dart
│       └── error_message.dart
└── test/
    ├── features/
    │   ├── auth/login_view_model_test.dart
    │   └── home/home_view_model_test.dart
    ├── data/
    │   ├── mock_auth_repository_test.dart
    │   └── session_test.dart
    └── core/auth_interceptor_test.dart
```

**Decisión de estructura**: aplicación móvil de un solo proyecto en `mobile/`, con las capas de `docs/reglas.md`. La carpeta `features/home/` se agrega para la pantalla principal; la constitución lista `features/` con las secciones de negocio y esta pantalla es la base de navegación de todas ellas. `app.dart` concentra la compuerta de sesión (decide entre inicio de sesión y pantalla principal observando un `SessionViewModel`). No se crean `api/`, `infra/` ni `web/`.

## Seguimiento de complejidad

Sin violaciones de la constitución; no se requiere justificación adicional.
