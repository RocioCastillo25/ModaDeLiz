# Guía de validación rápida: Base de la app móvil e inicio de sesión

Valida de punta a punta que el Sprint 1 funciona. Los detalles de datos y contratos están en [data-model.md](data-model.md) y [contracts/](contracts/).

## Requisitos previos

- Flutter 3.47.2 (o compatible) y Android SDK, con un emulador o un teléfono Android.
- Estar en la carpeta `mobile/`.

## Preparación

```text
flutter pub get
flutter analyze
flutter test
```

Resultado esperado: sin errores de análisis y todas las pruebas en verde.

## Ejecución con datos de ejemplo

```text
flutter run --dart-define=USE_MOCK=true
```

## Ejecución contra la API real (cuando exista)

```text
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://<dirección-de-la-api>/api/v1 --dart-define=KEYCLOAK_BASE_URL=https://<dirección-de-keycloak>
```

## Escenarios de validación

| # | Pasos | Resultado esperado |
|---|-------|--------------------|
| 1 | Entrar como `demo.vendedor` | Llega a la pantalla principal con nombre, "Empleado" y "Zacatlán" |
| 2 | Entrar como `demo.encargado` | Pantalla principal con "Gerente de tienda" y "Huauchinango" |
| 3 | Escribir una contraseña incorrecta | Mensaje genérico; permanece en el inicio de sesión |
| 4 | Dejar campos vacíos y pulsar el botón | No se envía nada; se indica qué falta |
| 5 | Entrar como `demo.desactivado` | Mensaje claro de cuenta desactivada |
| 6 | Entrar como `demo.admin` | Aviso que dirige a la web; no hay pantalla principal; al reabrir la app se pide iniciar sesión |
| 7 | Pulsar varias veces "Iniciar sesión" | Botón deshabilitado; una sola petición |
| 8 | Activar modo avión y pulsar el botón | Aviso de sin conexión; no se intenta el acceso |
| 9 | Entrar y cerrar la app sin cerrar sesión; reabrir | Entra directo a la pantalla principal |
| 10 | Pulsar "Cerrar sesión" y reabrir la app | Vuelve al inicio de sesión; se pide iniciar sesión |
| 11 | Simular sesión vencida y reabrir | Se pide iniciar sesión de nuevo |
| 12 | Activar "reducir animaciones" en el sistema | Las animaciones se reducen o desaparecen |
| 13 | Revisar la pantalla principal | Accesos a buscar, escanear y traspasos marcados "próximamente" |

## Instalable de prueba

```text
flutter build apk --release --dart-define=USE_MOCK=true
```

El APK queda en `mobile/build/app/outputs/flutter-apk/app-release.apk`. Instalarlo en un teléfono Android y repetir los escenarios 1, 3, 9 y 10. Guardar capturas del inicio de sesión y de la pantalla principal como evidencia para la bitácora.
