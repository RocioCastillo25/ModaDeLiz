# Tareas: Consulta de inventario, escáner y venta

**Entrada**: Documentos de diseño en `specs/002-busqueda-escaner-venta/`

**Requisitos previos**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Pruebas**: SÍ se incluyen. La constitución (principio XI) exige probar los ViewModels sin interfaz y con repositorios simulados, y cubrir los errores 401, 403 y 409. Las pruebas de cada historia se escriben primero y deben fallar antes de implementar.

**Organización**: Las tareas se agrupan por historia de usuario para implementar y probar cada una de forma independiente. Se construye sobre el Sprint 1; no se reimplementa el inicio de sesión, el tema ni la estructura.

## Formato: `[ID] [P?] [Historia] Descripción`

- **[P]**: se puede ejecutar en paralelo (archivos distintos, sin dependencias pendientes)
- **[US#]**: historia de usuario de `spec.md`: US1 búsqueda, US2 ficha, US3 escáner, US4 venta, US5 navegación
- Todas las rutas son relativas a la raíz del repositorio; el código vive en `mobile/`
- Cada campo con restricciones cita `data-model.md` con su `Entidad.campo`

## Convenciones de rutas

- Código: `mobile/lib/` (capas `core/`, `data/`, `features/`, `shared/`)
- Pruebas: `mobile/test/`
- Identificadores y archivos de código en inglés; comentarios, textos de interfaz y nombres de pruebas en español

---

## Fase 1: Preparación (infraestructura compartida)

**Propósito**: dejar lista la configuración nueva del sprint

- [X] T001 Agregar `mobile_scanner` a `mobile/pubspec.yaml` con `flutter pub add mobile_scanner`, verificar que su Android mínimo sea compatible con el proyecto (ajustar `minSdk` en `mobile/android/app/build.gradle*` si hace falta) y ejecutar `flutter pub get` (`research.md` D1)
- [X] T002 [P] Agregar el permiso de cámara en `mobile/android/app/src/main/AndroidManifest.xml` (sin permisos extra)
- [X] T003 [P] Agregar `NSCameraUsageDescription` con un texto en español en `mobile/ios/Runner/Info.plist`

---

## Fase 2: Fundamentos (prerrequisitos bloqueantes)

**Propósito**: modelos, DTO, errores, repositorios, renovación de sesión y DI que necesitan todas las historias

**⚠️ CRÍTICO**: ninguna historia puede empezar hasta terminar esta fase

### Pruebas de los fundamentos (escribir primero; deben fallar)

- [X] T004 [P] Prueba de `Session` con `refreshToken` y `refreshExpiresAt`: ida y vuelta a JSON, y lectura de una sesión del Sprint 1 sin esos campos, en `mobile/test/data/session_test.dart`
- [X] T005 [P] Prueba de `StockLevel` (agotado en 0, bajo si es mayor que 0 y no supera el umbral, disponible en otro caso) y de `SearchFilters` (recorta espacios y omite campos vacíos) en `mobile/test/data/stock_item_test.dart`
- [X] T006 [P] Prueba de `AuthInterceptor` con renovación en `mobile/test/core/auth_interceptor_test.dart`: un 401 renueva y repite una sola vez; varias peticiones simultáneas comparten una renovación; la renovación fallida notifica `onUnauthorized`; el fallo de red al renovar no cierra la sesión; no intercepta el endpoint de token; el 403 no cierra la sesión
- [X] T007 [P] Prueba de `ApiAuthRepository.refresh()` en `mobile/test/data/api_auth_repository_test.dart`: guarda la sesión nueva, rechaza si falta `refresh_token` o venció, y conserva el usuario

### Implementación de los fundamentos

- [X] T008 [P] Crear `Prenda` en `mobile/lib/data/models/prenda.dart` y `PrendaFicha` en `mobile/lib/data/models/prenda_ficha.dart` según `data-model.md` Prenda.* y Ficha de prenda, con `fromJson` solo en los DTO
- [X] T009 [P] Crear `StockItem` y `StockLevel` en `mobile/lib/data/models/stock_item.dart` según `data-model.md` Existencia (`StockItem.quantity` nunca negativo; el estado se calcula con `Prenda.alertThreshold`)
- [X] T010 [P] Crear `SearchFilters` en `mobile/lib/data/models/search_filters.dart` según `data-model.md` Filtros de búsqueda, inmutable y comparable
- [X] T011 [P] Crear `CatalogFailure` y `CatalogFailureType` en `mobile/lib/data/repositories/catalog_failure.dart` con los tipos de `data-model.md` Errores de catálogo y sus mensajes en español, sin detalles técnicos
- [X] T012 [P] Crear los DTO `PrendaDto`, `PrendaFichaDto` y `StockItemDto` en `mobile/lib/data/dto/` (Adapter de `snake_case` a modelo; datos incompletos fallan con `CatalogFailureType.server`)
- [X] T013 Extender `ApiException` en `mobile/lib/core/network/api_exception.dart` para conservar el código `error` y el `mensaje` de la API solo para decidir el tipo de falla (`NO_ENCONTRADO`, `STOCK_INSUFICIENTE`, `PROHIBIDO`, `DATOS_INVALIDOS`); nunca se muestran al usuario
- [X] T014 Agregar a `Session` en `mobile/lib/data/models/session.dart` los campos `refreshToken` y `refreshExpiresAt` según `data-model.md` Sesión (`Session.refreshToken`, `Session.refreshExpiresAt`); la lectura de sesiones sin ellos no falla; `SecureTokenStorage` los guarda sin imprimirlos
- [X] T015 Extender `TokenResponseDto` en `mobile/lib/data/dto/token_response_dto.dart` con `refresh_token` y `refresh_expires_in` opcionales
- [X] T016 Agregar `refreshToken(String)` (formulario `grant_type=refresh_token`) a `AuthService` en `mobile/lib/data/services/auth_service.dart`, según `contracts/catalog-api.md` Renovación de la sesión
- [X] T017 Agregar `refresh()` a `AuthRepository` (`mobile/lib/data/repositories/auth_repository.dart`) y a `ApiAuthRepository` y `MockAuthRepository`: pide el token nuevo, conserva el usuario, guarda la sesión y devuelve el token o `null` si no se puede renovar; `login` guarda también el token de renovación
- [X] T018 Hacer que `AuthInterceptor` renueve la sesión ante un 401 en `mobile/lib/core/network/auth_interceptor.dart`, con una sola renovación compartida, repetición única de la petición y sin interceptar el endpoint de token; agregar a `ApiClient` en `mobile/lib/core/network/api_client.dart` la repetición de una petición con el token nuevo y los métodos que falten para `POST` con JSON y `GET` con parámetros (`contracts/internal-interfaces.md`)
- [X] T019 [P] Crear las interfaces `PrendaRepository`, `InventarioRepository` y `BranchRepository` en `mobile/lib/data/repositories/` según `contracts/internal-interfaces.md`
- [X] T020 [P] Crear `CatalogService` en `mobile/lib/data/services/catalog_service.dart` con `GET /prendas`, `GET /prendas/{id}`, `GET /prendas/codigo/{codigo}` (código codificado para la ruta), `POST /ventas` y `GET /sucursales`, según `contracts/catalog-api.md`
- [X] T021 Crear `ApiPrendaRepository`, `ApiInventarioRepository` y `ApiBranchRepository` en `mobile/lib/data/repositories/` que traducen `ApiException` a `CatalogFailure` (404 a `notFound`, 409 a `insufficientStock`, 403 a `forbidden`, 400 a `invalid`, red a `network`, 5xx a `server`)
- [X] T022 [P] Crear `MockPrendaRepository`, `MockInventarioRepository` y `MockBranchRepository` en `mobile/lib/data/repositories/` con prendas de varias sucursales, tallas y colores, casos de existencia baja y agotada, un código desconocido y descuento en memoria que rechaza con `insufficientStock`
- [X] T023 [P] Crear los widgets compartidos `StockBadge` (ícono y texto "Agotado", "Pocas piezas" o "Disponible", más color) y `PrendaImage` (marcador de posición si no hay foto, mientras carga o si falla) en `mobile/lib/shared/stock_badge.dart` y `mobile/lib/shared/prenda_image.dart`, con colores solo desde `core/theme`
- [X] T024 Registrar en `mobile/lib/core/di/service_locator.dart` los servicios, los repositorios (real o simulado según `USE_MOCK`) y la función de renovación del interceptor; mantener las pruebas existentes en verde y actualizar `mobile/test/core/service_locator_test.dart`

**Punto de control**: fundamentos listos; las historias pueden empezar.

---

## Fase 3: Historia de usuario 1 - Buscar prendas con filtros (Prioridad: P1) 🎯 MVP

**Objetivo**: buscar por nombre y filtrar por talla, color y sucursal, con estados de carga, vacío y error.

**Prueba independiente**: con datos de ejemplo, buscar parte de un nombre, combinar filtros y ver la lista con foto, nombre y existencia.

### Pruebas de la historia 1 (escribir primero)

- [X] T025 [P] [US1] Prueba de `BusquedaViewModel` en `mobile/test/features/busqueda/busqueda_view_model_test.dart`: resultados, vacío, error y reintento, recorte de espacios y mayúsculas, filtros combinados, limpiar filtros, carga por bloques de 20 y que una búsqueda nueva descarte la anterior

### Implementación de la historia 1

- [X] T026 [US1] Crear `BusquedaViewModel` en `mobile/lib/features/busqueda/busqueda_view_model.dart` con estados `idle`, `loading`, `results`, `empty` y `error`, filtros (`SearchFilters`), lista de sucursales, carga por bloques de 20 (`research.md` D5) y retardo corto al escribir; sin importar `material.dart`
- [X] T027 [P] [US1] Crear la hoja de filtros en `mobile/lib/features/busqueda/filtros_sheet.dart`: talla y color como texto corto, sucursal desde la lista, botones "Aplicar" y "Limpiar filtros" (`research.md` D6)
- [X] T028 [US1] Crear `BusquedaView` en `mobile/lib/features/busqueda/busqueda_view.dart`: campo de búsqueda, filtros, lista perezosa con foto pequeña, nombre y existencia, estados de carga, sin resultados y error con "Reintentar", con el estilo glass y botones grandes
- [X] T029 [US1] Registrar `BusquedaViewModel` en `mobile/lib/core/di/service_locator.dart` y limpiarlo al cerrar sesión

**Punto de control**: se puede buscar con filtros con datos de ejemplo.

---

## Fase 4: Historia de usuario 2 - Ficha de prenda (Prioridad: P1)

**Objetivo**: ver foto, datos y existencia de las 5 sucursales por talla y color, con la sucursal propia destacada.

**Prueba independiente**: desde un resultado abrir la ficha y comprobar foto, datos, matriz, sucursal propia destacada, agotado y jalar para actualizar.

### Pruebas de la historia 2 (escribir primero)

- [X] T030 [P] [US2] Prueba de `FichaViewModel` en `mobile/test/features/ficha_prenda/ficha_view_model_test.dart`: carga por identificador y por código, error con reintento, `notFound`, actualización, identificación de la existencia de la sucursal del usuario y reemplazo de una existencia tras una venta

### Implementación de la historia 2

- [X] T031 [US2] Crear `FichaViewModel` en `mobile/lib/features/ficha_prenda/ficha_view_model.dart` con estados `loading`, `data` y `error`, `load(id)`, `loadByBarcode(code)`, `refresh()` y `applySale(StockItem)`; la sucursal propia se toma de la sesión, no de un campo editable
- [X] T032 [P] [US2] Crear la matriz de existencias en `mobile/lib/features/ficha_prenda/matriz_existencias.dart`: filas por sucursal con desglose por talla y color, la sucursal propia destacada y `StockBadge` en cada cantidad
- [X] T033 [US2] Crear `FichaView` en `mobile/lib/features/ficha_prenda/ficha_view.dart`: foto, nombre, descripción, marca, categoría y temporada, matriz, jalar para actualizar, estados de carga y error con "Reintentar", y el botón "Solicitar traspaso" deshabilitado con la leyenda "Próximamente" (FR-029)
- [X] T034 [US2] Registrar `FichaViewModel` en `mobile/lib/core/di/service_locator.dart` como fábrica (uno por ficha abierta) y abrir la ficha desde cada resultado de `BusquedaView`

**Punto de control**: búsqueda y ficha funcionan juntas con datos de ejemplo.

---

## Fase 5: Historia de usuario 4 - Descontar piezas vendidas (Prioridad: P1)

**Objetivo**: descontar piezas de la sucursal del usuario con confirmación, validación y manejo de la existencia insuficiente.

**Prueba independiente**: desde la ficha elegir talla y color propios, indicar cantidad, confirmar y ver la existencia devuelta; probar una cantidad mayor a la existente.

### Pruebas de la historia 4 (escribir primero)

- [X] T035 [P] [US4] Prueba de `VentaViewModel` en `mobile/test/features/venta/venta_view_model_test.dart`: cantidad vacía, cero, negativa, decimal o mayor a la mostrada no se envía (`SaleRequest.quantity`); confirmación con prenda, talla, color y cantidad; envío correcto con la existencia devuelta; 409 con la existencia vigente tras recargar; 403; sin conexión; doble envío bloqueado; y el 401 repetido una sola vez sin doble descuento
- [X] T036 [P] [US4] Prueba de `ApiInventarioRepository` en `mobile/test/data/api_inventario_repository_test.dart`: envía solo `idInventario` y `cantidad`, nunca la sucursal, y traduce 201, 403, 409 y 400

### Implementación de la historia 4

- [X] T037 [US4] Crear `VentaViewModel` en `mobile/lib/features/venta/venta_view_model.dart` con estados `editing`, `confirming`, `submitting`, `done` y `error`; valida entero positivo (`SaleRequest.quantity`), consulta `ConnectivityService` antes de enviar, bloquea el doble envío y, ante `insufficientStock`, pide la existencia vigente a `PrendaRepository` para el mensaje "Solo quedan N pieza(s)"
- [X] T038 [US4] Crear la hoja de venta en `mobile/lib/features/venta/venta_sheet.dart`: elección de talla y color solo entre existencias de la sucursal propia, campo de cantidad numérico, paso de confirmación, botón deshabilitado en curso y mensajes en español
- [X] T039 [US4] Mostrar en `FichaView` la acción "Descontar piezas" solo sobre las existencias de la sucursal del usuario y actualizar la fila con la existencia devuelta (`FichaViewModel.applySale`); registrar `VentaViewModel` en `mobile/lib/core/di/service_locator.dart`

**Punto de control**: el flujo búsqueda, ficha y venta funciona completo con datos de ejemplo.

---

## Fase 6: Historia de usuario 3 - Escanear una etiqueta (Prioridad: P2)

**Objetivo**: leer un código con la cámara y abrir la ficha, con permiso explicado y búsqueda manual como alternativa.

**Prueba independiente**: abrir el escáner, conceder el permiso, escanear una etiqueta registrada y ver su ficha; probar un código desconocido y el permiso negado.

### Pruebas de la historia 3 (escribir primero)

- [X] T040 [P] [US3] Prueba de `EscanerViewModel` en `mobile/test/features/escaner/escaner_view_model_test.dart` con `FakeBarcodeScannerService`: explicación antes del permiso, código registrado abre una sola ficha aunque se repita, código desconocido muestra "prenda no encontrada" y permite escanear de nuevo, permiso negado y cámara no disponible ofrecen la búsqueda manual, y la búsqueda manual por código

### Implementación de la historia 3

- [X] T041 [P] [US3] Crear la interfaz `BarcodeScannerService`, `ScannerError` y `ScannerException` en `mobile/lib/data/services/barcode_scanner_service.dart` según `contracts/internal-interfaces.md`, y `FakeBarcodeScannerService` para pruebas en `mobile/test/helpers/fake_barcode_scanner_service.dart`
- [X] T042 [US3] Crear `MobileScannerService` en `mobile/lib/data/services/mobile_scanner_service.dart` (Adapter; único archivo que importa `mobile_scanner`): códigos de barras y QR, sin repeticiones consecutivas del mismo valor, vista previa, linterna y traducción del error de permiso (`research.md` D1 y D2)
- [X] T043 [US3] Crear `EscanerViewModel` en `mobile/lib/features/escaner/escaner_view_model.dart` con estados `explaining`, `scanning`, `resolving`, `notFound`, `permissionDenied` y `unavailable`; resuelve el código con `PrendaRepository.getByBarcode` y evita abrir dos fichas
- [X] T044 [US3] Crear `EscanerView` en `mobile/lib/features/escaner/escaner_view.dart`: explicación breve con botón "Activar cámara", vista previa, botón de linterna, aviso "Prenda no encontrada" con "Escanear otra vez", y campo de búsqueda manual por código cuando se niega el permiso
- [X] T045 [US3] Registrar `BarcodeScannerService` y `EscanerViewModel` en `mobile/lib/core/di/service_locator.dart` (el servicio se libera al salir de la pantalla)

**Punto de control**: el escáner abre la ficha en el teléfono.

---

## Fase 7: Historia de usuario 5 - Navegar entre pantallas (Prioridad: P2)

**Objetivo**: llegar a búsqueda y escáner desde la pantalla principal, y de ahí a la ficha y la venta; manejar sesión y permisos de forma uniforme.

**Prueba independiente**: recorrer pantalla principal, búsqueda, ficha y regreso; forzar un 401 y un 403.

- [X] T046 [P] [US5] Prueba de `HomeViewModel` y de la navegación en `mobile/test/features/home/home_view_model_test.dart` y `mobile/test/app_test.dart`: accesos a "Buscar" y "Escanear", regreso a donde se vino, 401 sin renovar vuelve al inicio de sesión con aviso, 403 muestra aviso sin cerrar la sesión
- [X] T047 [US5] Agregar a `HomeView` en `mobile/lib/features/home/home_view.dart` los accesos "Buscar" y "Escanear" con botones grandes y el estilo glass, sin mover el botón "Cerrar sesión" fijo al pie
- [X] T048 [US5] Definir las rutas hacia búsqueda, ficha y escáner en `mobile/lib/app.dart` con `Navigator`, conservando la compuerta de sesión (`research.md` D3)
- [X] T049 [US5] Mostrar el aviso de falta de permisos (403) en las pantallas nuevas y limpiar los ViewModels del sprint al cerrar sesión (`SessionViewModel.addCleanup`)

**Punto de control**: la app completa se recorre con datos de ejemplo.

---

## Fase 8: Pulido y verificación transversal

**Propósito**: calidad, prueba real, evidencia y cierre del sprint

- [X] T050 [P] Ejecutar `flutter analyze` y `flutter test`; corregir avisos y fallas
- [X] T051 [P] Revisar que ninguna pantalla importe `mobile_scanner`, `dio` ni un Service, que no haya colores sueltos y que no aparezcan precios ni mensajes técnicos (SC-007)
- [X] T052 [P] Revisar con `MediaQuery.disableAnimations` las animaciones nuevas y la lectura en pantallas pequeñas y grandes
- [X] T053 Probar en el teléfono con datos de ejemplo los escenarios de `quickstart.md` secciones 2 y 3 (incluida la cámara) y anotar el resultado
- [ ] T054 Probar contra Keycloak y la API reales según `quickstart.md` sección 4: búsqueda, ficha, escáner, venta, renovación de sesión, sesión no renovable y 403; confirmar con los Integrantes 1 y 2 los puntos abiertos de `contracts/catalog-api.md`
- [ ] T055 [P] Actualizar `specs/002-busqueda-escaner-venta/contracts/catalog-api.md` y `research.md` con lo que resulte de la prueba real (mayúsculas, `existencia_total` por sucursal, fotos, `refresh_token`)
- [X] T056 [P] Tomar las capturas de búsqueda, ficha, escáner y venta (sin datos personales en la barra de estado) y actualizar la bitácora del Sprint 2 en `docs/evidencia/sprint-2/`
- [ ] T057 Generar el APK de prueba para la dueña y probarlo en un teléfono con cámara
- [ ] T058 Abrir el Pull Request a `develop` desde `feature/mobile-busqueda-escaner-venta` y coordinar la etiqueta `v0.2.0` con el Integrante 4

---

## Dependencias y orden de ejecución

- **Fase 1** primero; **Fase 2** bloquea todas las historias.
- **US1** (búsqueda) y **US2** (ficha) forman el MVP; la ficha se abre desde la búsqueda.
- **US4** (venta) depende de la ficha (**US2**).
- **US3** (escáner) depende de la ficha y del repositorio; puede avanzar en paralelo con US4 una vez lista la Fase 4.
- **US5** (navegación) cierra el recorrido y puede empezar sus pruebas desde que existan las pantallas.
- **Fase 8** al final; T053 y T054 requieren teléfono y, la segunda, los servicios del Integrante 2.

### Oportunidades de paralelismo

- Fase 2: T004 a T007 (pruebas) y T008 a T012, T019, T020, T022 y T023 son archivos distintos.
- Con la Fase 2 terminada: T025 (US1), T030 (US2), T035 y T036 (US4) y T040 y T041 (US3) se pueden escribir en paralelo.

## Estrategia de implementación

1. **MVP (US1 y US2)**: búsqueda y ficha con datos de ejemplo; subir como primer Pull Request.
2. **Venta (US4)**: segundo Pull Request.
3. **Escáner (US3) y navegación (US5)**: tercer Pull Request, con prueba en teléfono físico.
4. **Prueba real, evidencia, APK y cierre** (Fase 8).

Cada punto de control deja la app en un estado que se puede probar y subir por separado.
