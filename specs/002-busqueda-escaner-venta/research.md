# Investigación (Fase 0): Consulta de inventario, escáner y venta

No quedan marcadores `NEEDS CLARIFICATION`. Las decisiones de alcance se resolvieron en `/speckit.clarify` (traspaso deshabilitado y renovación de sesión). Aquí se documentan las decisiones técnicas del plan. Las decisiones del Sprint 1 (D1 a D13 de `specs/001-base-app-movil-login/research.md`) siguen vigentes salvo donde se indique.

## D1. Lector de códigos: `mobile_scanner`

- **Decisión**: usar `mobile_scanner` para códigos de barras y QR, envuelto por `BarcodeScannerService` (Adapter). Es el único paquete nuevo del sprint. La versión exacta se fija con `flutter pub add mobile_scanner` al implementar y se verifica que su Android mínimo sea compatible con el proyecto.
- **Justificación**: es el paquete de cámara más usado y mantenido para esta tarea; soporta barras y QR, linterna y control de la cámara; en Android usa ML Kit (sin servicios propios). Pide el permiso de cámara por sí mismo al iniciar.
- **Alternativas**: `flutter_barcode_scanner` (sin mantenimiento); `camera` más lectura propia (mucho código y riesgo).

## D2. Permiso de cámara sin paquete adicional

- **Decisión**: la pantalla del escáner muestra primero una explicación breve y un botón "Activar cámara"; al tocarlo se inicia el escáner, que dispara la solicitud del sistema. Si el sistema devuelve "permiso denegado", se muestra la búsqueda manual por código.
- **Justificación**: cumple "pedir el permiso solo al abrir el escáner, explicando su uso" sin sumar `permission_handler`. El servicio traduce el error de la librería a un tipo propio (`ScannerError.permissionDenied`).
- **Alternativas**: `permission_handler` (otra dependencia solo para preguntar un permiso).

## D3. Navegación: se mantiene `Navigator`

- **Decisión**: seguir con `Navigator` y `MaterialPageRoute`, con la compuerta de sesión del Sprint 1.
- **Justificación**: el Sprint 1 dejó "reevaluar `go_router` en el Sprint 2". Hay 4 destinos y ningún enlace profundo; un paquete de rutas no aporta. Se reevalúa de nuevo si el Sprint 3 suma muchas rutas.
- **Alternativas**: `go_router`.

## D4. Contrato de catálogo

- **Decisión**: usar los endpoints marcados `implementado` en `docs/openapi.yaml` de `develop`: `GET /prendas` (parámetros `q`, `talla`, `color`, `sucursalId`), `GET /prendas/{id}`, `GET /prendas/codigo/{codigo}`, `POST /ventas` y `GET /sucursales`. Detalle en [contracts/catalog-api.md](contracts/catalog-api.md).
- **Justificación**: es el contrato real; la ficha ya trae `existencias` con el `id` de inventario que se usa para vender.
- **Hallazgo**: `PrendaResumen` trae `existencia_total` pero no el desglose por sucursal. Con filtro de sucursal, la lista mostrará la cantidad vigente de esa sucursal solo si el servicio ya la filtra en ese total. No está documentado; se confirma en la prueba real y, si no es así, la lista muestra la existencia total sin la etiqueta "de la sucursal".
- **Alternativas**: pedir `GET /inventario` por cada prenda de la lista (una petición por fila, demasiado lento).

## D5. Paginación en bloques

- **Decisión**: la API devuelve la lista completa sin paginación. La app la recibe entera y la muestra por bloques de 20 con carga al llegar al final (lista perezosa).
- **Justificación**: cumple "se carga por bloques" sin pedir cambios a la API; evita construir cientos de filas a la vez.
- **Alternativas**: pedir paginación a la API (Integrante 1); queda como mejora si el catálogo crece mucho.

## D6. Filtros de talla y color

- **Decisión**: la hoja de filtros usa campos de texto cortos para talla y color (se recortan los espacios y se envían tal cual), y una lista de sucursales obtenida de `GET /sucursales`. Se agrega un botón "Limpiar filtros".
- **Justificación**: la API no ofrece un catálogo de tallas ni colores y `PrendaResumen` no trae esos datos, así que no se pueden construir listas fijas sin inventarlas.
- **Riesgo**: la sensibilidad a mayúsculas y acentos depende de la API. Se prueba en la prueba real; el app solo recorta espacios y manda el texto escrito.
- **Alternativas**: listas fijas de tallas (S, M, L…) que no coincidirían con los datos reales; construir las listas con los valores de las fichas visitadas (incompleto).

## D7. Renovación automática de la sesión

- **Decisión**:
  - El token de Keycloak se renueva con `POST {KEYCLOAK}/realms/checklizz/protocol/openid-connect/token`, `grant_type=refresh_token`, `client_id=checklizz-app`, `refresh_token=...`.
  - La sesión guarda además el `refresh_token` y su vigencia (`refresh_expires_in`) en el almacenamiento seguro.
  - El interceptor, ante un 401 de una petición con token y no reintentada, pide una renovación **compartida** (si ya hay una en curso, espera la misma), actualiza la sesión guardada y repite la petición una sola vez.
  - Si la renovación falla (rechazo, token de renovación vencido, cuenta desactivada), notifica `onUnauthorized` y se vuelve al inicio de sesión con aviso.
  - Un fallo de red al renovar no cierra la sesión: se informa el error de conexión y se permite reintentar.
- **Justificación**: cumple la aclaración del 2026-11-26 y el principio IV. Repetir tras un 401 es seguro para la venta: el 401 significa que la API no procesó nada, así que no hay doble descuento (SC-008).
- **Riesgo**: depende de que el realm entregue `refresh_token` y de su vigencia. Se confirma con el Integrante 2 en la prueba real. Si Keycloak no lo entrega, se vuelve al inicio de sesión, como en el Sprint 1.
- **Alternativas**: renovar por temporizador antes de vencer (más estado y puede fallar con la app en segundo plano); alargar el token en Keycloak (decisión de otro integrante, no basta por sí sola).

## D8. Descuento y manejo del 409

- **Decisión**: `POST /ventas` con `{idInventario, cantidad}`. La respuesta `201` trae la existencia actualizada, que reemplaza esa fila de la ficha. Ante un `409 STOCK_INSUFICIENTE` la app vuelve a pedir la ficha para conocer la existencia vigente y muestra "Solo quedan N pieza(s)" sin cambiar nada hasta que la ficha se recargue.
- **Justificación**: el contrato no indica que el 409 traiga la existencia actual en el cuerpo; recargar la ficha da el valor real sin suponer campos.
- **Alternativas**: leer una cantidad del texto del mensaje (frágil).

## D9. Estado bajo y agotado

- **Decisión**: agotado si la cantidad es 0; bajo si es mayor que 0 y menor o igual que el umbral de la prenda (`umbral_alerta`, 2 por defecto). Se muestra con ícono y texto ("Agotado", "Pocas piezas") además del color mediante un widget compartido `StockBadge`.
- **Justificación**: la prenda trae su propio umbral; cumple la regla XI.6 de no depender solo del color.
- **Alternativas**: umbral fijo en la app (duplicaría una regla que define la API).

## D10. Fotos de las prendas

- **Decisión**: `Image.network` con imagen de marcador de posición mientras carga y si falla o no hay `foto_url`. Sin paquete de caché.
- **Justificación**: cumple la especificación sin dependencia extra; la caché de imágenes del propio Flutter basta para este uso.
- **Alternativas**: `cached_network_image` (otra dependencia).

## D11. Pruebas

- **Decisión**: repositorios simulados de prendas, inventario y sucursales con casos de existencia baja, agotada, código desconocido y 409; dobles manuales del servicio de escáner. Se prueban los ViewModels de búsqueda, ficha, venta y escáner, la validación de cantidades y el interceptor con renovación (renovación única con varias peticiones, reintento único, renovación fallida y fallo de red).
- **Justificación**: la constitución exige ViewModels sin interfaz y casos 401, 403 y 409.
- **Alternativas**: `mocktail` (innecesario con pocos dobles).

## D12. Configuración por entorno

- **Decisión**: se conservan `API_BASE_URL`, `KEYCLOAK_BASE_URL` y `USE_MOCK` del Sprint 1; no se agregan variables nuevas.
- **Justificación**: nada del sprint requiere otra dirección.
