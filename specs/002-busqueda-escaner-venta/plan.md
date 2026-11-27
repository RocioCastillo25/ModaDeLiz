# Plan de implementación: Consulta de inventario, escáner y venta

**Rama**: `feature/mobile-busqueda-escaner-venta` (carpeta de especificación `002-busqueda-escaner-venta`) | **Fecha**: 2026-11-26 | **Especificación**: [spec.md](spec.md)

**Entrada**: Especificación de la funcionalidad en `specs/002-busqueda-escaner-venta/spec.md`

## Resumen

Se agregan a la app del Sprint 1 cuatro funciones: búsqueda de prendas con filtros, ficha con la matriz de existencias de las 5 sucursales, escáner de códigos que abre la ficha y descuento de piezas de la sucursal del usuario. Se mantiene la arquitectura MVVM con `ChangeNotifier` y `get_it`. Los datos entran por repositorios nuevos (`PrendaRepository`, `InventarioRepository`, `BranchRepository`) con implementación real y simulada, igual que en el Sprint 1. La cámara se envuelve tras `BarcodeScannerService`. Además, la sesión se renueva sola con el `refresh_token` de Keycloak (aclaración del 2026-11-26): el interceptor atiende el 401, renueva una sola vez aunque fallen varias peticiones a la vez y repite la petición original.

## Contexto técnico

**Lenguaje/Versión**: Dart 3 con Flutter 3.47.2 (canal estable), igual que el Sprint 1.

**Dependencias principales**: las del Sprint 1 (`get_it`, `dio`, `flutter_secure_storage`, `connectivity_plus`) más **una nueva**: `mobile_scanner` (lectura de códigos con la cámara). Justificación en [research.md](research.md), D1.

**Almacenamiento**: almacenamiento seguro del dispositivo para la sesión; ahora guarda también el token de renovación y su vigencia. No se guarda la contraseña. No hay caché de inventario.

**Pruebas**: `flutter_test` con repositorios simulados escritos a mano. Prueba física en el teléfono Android, incluida la cámara.

**Plataforma objetivo**: Android (APK de prueba); iPhone previsto, código base único.

**Tipo de proyecto**: aplicación móvil.

**Metas de rendimiento**: resultados de búsqueda visibles en menos de 15 s desde la pantalla principal (SC-001); ficha abierta en menos de 3 s tras leer una etiqueta (SC-002); venta completa en menos de 20 s (SC-003); listas que no congelan la pantalla.

**Restricciones**: sin precios; sin modo sin conexión ni caché; textos en español; solo se descuenta de la sucursal del usuario; la API aplica las reglas de negocio; sin archivos `.env`.

**Escala/Alcance**: 3 pantallas nuevas (búsqueda, ficha, escáner), una hoja de filtros y una hoja de venta; unas 25 personas empleadas y 5 gerentes en 5 sucursales.

## Verificación de la constitución

*PUERTA: debe pasar antes de la investigación de la Fase 0. Se vuelve a verificar tras el diseño de la Fase 1.*

| Principio | Evaluación | Estado |
|-----------|------------|--------|
| I. Arquitectura y límites | Todo en `mobile/`; solo consume la API REST (y el endpoint de token de Keycloak para renovar, igual que el inicio de sesión). Las reglas de existencia las decide la API. Un paquete nuevo (`mobile_scanner`) justificado en `research.md`. | Cumple |
| II. MVVM con ChangeNotifier | Un ViewModel por pantalla en `features/<nombre>/`; las Views no llaman a Services; los ViewModels no importan `material.dart`. | Cumple |
| III. Estructura, patrones y DI | Repositorios nuevos con versión real y simulada; DTO a modelo (Adapter); `fromJson` en modelos; escáner tras `BarcodeScannerService` (Adapter); `get_it` por constructor. Se agrega `features/escaner/` (la constitución lista las secciones de negocio y no incluye el escáner; se justifica igual que `home` en el Sprint 1). | Cumple con matiz |
| IV. Autenticación y sesión | Ahora se cumple por completo el "ante 401 se intenta renovar": renovación automática con una sola petición de renovación a la vez; si no es posible, vuelve al inicio de sesión. El token de renovación se guarda solo en almacenamiento seguro. | Cumple |
| V. Roles y permisos | La sucursal de la venta sale del usuario autenticado, no de un campo editable. Solo se ofrece descontar sobre las existencias de esa sucursal; la API decide. | Cumple |
| VI. Inventario, ventas y escáner | 5 sucursales visibles; solo piezas; cantidad entera positiva; mensaje con existencia actual ante el 409; existencia mostrada desde la respuesta de la API; permiso de cámara solo al abrir el escáner con explicación previa; búsqueda manual si se niega; "prenda no encontrada" que permite reintentar. | Cumple |
| VII. Traspasos y notificaciones | No aplican; solo el botón "Solicitar traspaso" deshabilitado. | N/A |
| VIII. Errores y estados | Cargando, con datos y error con reintento en búsqueda y ficha; sin conexión se bloquea la venta; botón deshabilitado en curso. | Cumple |
| IX y X. Interfaz y diseño | Colores solo desde `core/theme`; agotado y bajo con texto e ícono además del color; se respeta reducir movimiento. | Cumple |
| XI. Pruebas | ViewModels de búsqueda, ficha, escáner y venta sin interfaz; casos 401 (con renovación), 403 y 409 con pruebas. | Cumple |

**Matiz (principio III)**: `features/escaner/` no figura en la lista de carpetas de la constitución. No contradice su intención (una carpeta por pantalla con su ViewModel). Se propone agregarlo a `docs/reglas.md` en el próximo cambio de la constitución.

**Evaluación tras el diseño de la Fase 1**: sin cambios; el diseño no introduce violaciones.

## Estructura del proyecto

### Documentación (esta funcionalidad)

```text
specs/002-busqueda-escaner-venta/
├── plan.md              # Este archivo
├── research.md          # Fase 0
├── data-model.md        # Fase 1
├── quickstart.md        # Fase 1
├── contracts/           # Fase 1
│   ├── catalog-api.md
│   └── internal-interfaces.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Fase 2 (lo crea /speckit.tasks)
```

### Código fuente (raíz del repositorio)

Lo nuevo va marcado con `+`; lo existente que cambia, con `~`.

```text
mobile/
├── pubspec.yaml                                   ~ agrega mobile_scanner
├── android/app/src/main/AndroidManifest.xml       ~ permiso de cámara
├── ios/Runner/Info.plist                          ~ texto de uso de la cámara
├── lib/
│   ├── app.dart                                   ~ rutas hacia búsqueda, ficha y escáner
│   ├── core/
│   │   ├── di/service_locator.dart                ~ registra repositorios, escáner y ViewModels nuevos
│   │   ├── network/
│   │   │   ├── api_client.dart                    ~ agrega la repetición de una petición con el token nuevo
│   │   │   ├── auth_interceptor.dart              ~ renueva la sesión ante 401 y repite la petición
│   │   │   └── api_exception.dart                 ~ conserva el código `error` y el `mensaje` de la API
│   │   └── security/                              ~ la sesión guardada incluye el token de renovación
│   ├── data/
│   │   ├── models/                                + prenda.dart, prenda_ficha.dart, stock_item.dart
│   │   ├── dto/                                   + prenda_dto.dart, prenda_ficha_dto.dart, stock_item_dto.dart
│   │   │                                          ~ token_response_dto.dart (refresh_token)
│   │   ├── repositories/                          + prenda_repository.dart (+ api y mock)
│   │   │                                          + inventario_repository.dart (+ api y mock)
│   │   │                                          + branch_repository.dart (+ api y mock)
│   │   │                                          + catalog_failure.dart
│   │   └── services/                              + catalog_service.dart, barcode_scanner_service.dart,
│   │                                                mobile_scanner_service.dart
│   │                                              ~ auth_service.dart (renovar con refresh_token)
│   ├── features/
│   │   ├── home/                                  ~ accesos a "Buscar" y "Escanear"
│   │   ├── busqueda/                              + busqueda_view.dart, busqueda_view_model.dart, filtros_sheet.dart
│   │   ├── ficha_prenda/                          + ficha_view.dart, ficha_view_model.dart, matriz_existencias.dart
│   │   ├── venta/                                 + venta_sheet.dart, venta_view_model.dart
│   │   └── escaner/                               + escaner_view.dart, escaner_view_model.dart
│   └── shared/                                    + stock_badge.dart, prenda_image.dart
└── test/
    ├── features/{busqueda,ficha_prenda,venta,escaner}/   + una prueba de ViewModel por pantalla
    ├── data/{api_prenda_repository,api_inventario_repository}_test.dart   +
    └── core/auth_interceptor_test.dart                    ~ casos de renovación
```

**Decisión de estructura**: se conserva la organización del Sprint 1 y se agregan las carpetas de la constitución (`busqueda`, `ficha_prenda`, `venta`) más `escaner`. La navegación sigue con `Navigator` de Flutter (D3 del `research.md`); se reevaluó el cambio a `go_router` y no se justifica con 4 rutas y sin enlaces profundos. No se crean `api/`, `infra/` ni `web/`.

## Seguimiento de complejidad

| Cambio | Por qué hace falta | Alternativa más simple descartada |
|--------|--------------------|-----------------------------------|
| Un paquete nuevo (`mobile_scanner`) | Leer códigos con la cámara no se puede hacer solo con Flutter | Escribir código nativo por plataforma: mucho más trabajo y más riesgo |
| Renovación con petición única compartida | Evitar varias renovaciones simultáneas, que Keycloak puede rechazar | Renovar en cada 401: falla cuando se hacen varias peticiones a la vez |
