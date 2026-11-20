# CheckLizz — app móvil

App móvil de **Moda de Lizz** para que empleados y gerentes consulten el inventario de las
5 sucursales, descuenten piezas y soliciten traspasos. Está hecha con Flutter y Dart.

**Estado actual (Sprint 1):** base del proyecto e inicio de sesión. Las secciones de búsqueda,
escáner y traspasos aparecen como "próximamente".

## Requisitos

- Flutter 3.47.2 o compatible y Android SDK.
- Un emulador o un teléfono Android.

## Ejecutar

Con datos de ejemplo (no necesita API):

```text
flutter pub get
flutter run --dart-define=USE_MOCK=true
```

Contra la API real, cuando esté disponible:

```text
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://<dirección-de-la-api>
```

La dirección de la API se configura por entorno. No se usan archivos `.env` ni se sube ninguna
contraseña al repositorio.

## Usuarios de ejemplo (solo en modo de prueba)

Contraseña de todos: `demo1234`.

| Usuario | Rol | Sucursal | Qué prueba |
|---|---|---|---|
| `demo.vendedor` | Empleado | Zacatlán | Acceso normal |
| `demo.encargado` | Gerente de tienda | Huauchinango | Acceso normal |
| `demo.admin` | Administrador | (ninguna) | Aviso que dirige a la página web |
| `demo.desactivado` | Empleado | Xicotepec | Mensaje de cuenta desactivada |

En modo de prueba, la pantalla de inicio de sesión muestra la leyenda "MODO DE PRUEBA".

## Pruebas

```text
flutter analyze
flutter test
```

Los ViewModels se prueban sin interfaz y con repositorios simulados.

## Generar el APK de prueba

```text
flutter build apk --release --dart-define=USE_MOCK=true
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`. La firma de producción
queda fuera del Sprint 1: el APK sirve para instalar y probar.

## Arquitectura

MVVM con `ChangeNotifier` y `get_it`. Una View nunca llama a la API ni a un Service; los
ViewModels no importan `material.dart`.

```text
lib/
├── main.dart, app.dart
├── core/        # config, di, network, security, theme
├── data/        # models, dto, repositories, services
├── features/    # auth, home (y las secciones de los siguientes sprints)
└── shared/      # widgets reutilizables
```

Para cambiar entre datos de ejemplo y API real basta la bandera `USE_MOCK`: el registro de
dependencias (`lib/core/di/service_locator.dart`) elige la implementación del repositorio sin
tocar pantallas ni ViewModels.

## Seguridad

- El token se guarda solo en almacenamiento seguro del dispositivo.
- La contraseña nunca se guarda.
- Un administrador no conserva sesión en el teléfono: se le dirige a la página web.
- Los mensajes de error no revelan información interna ni si un usuario existe.

## Documentación

La especificación, el plan y las tareas del sprint están en `specs/001-base-app-movil-login/`.
Las reglas del proyecto están en `docs/reglas.md`.
