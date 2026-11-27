# Modelo de datos: Consulta de inventario, escáner y venta

Los modelos viven en `mobile/lib/data/models/` y se construyen desde los DTO (`mobile/lib/data/dto/`) mediante un Adapter. Los nombres de campo del contrato (`snake_case`) solo aparecen en los DTO.

## Prenda (resumen de la lista)

| Campo | Tipo | Origen en la API | Notas |
|-------|------|------------------|-------|
| `id` | entero | `id` | |
| `barcode` | texto | `codigo_barras` | |
| `description` | texto | `descripcion` | se muestra como nombre |
| `brand` | texto, opcional | `marca` | |
| `category` | texto, opcional | `categoria` | |
| `season` | texto, opcional | `temporada` | |
| `photoUrl` | texto, opcional | `foto_url` | sin foto se usa el marcador de posición |
| `alertThreshold` | entero | `umbral_alerta` | por defecto 2; define cuándo es "bajo" |
| `totalStock` | entero | `existencia_total` | solo en la lista |

## Ficha de prenda

Los mismos campos de la prenda más `stock`, una lista de **Existencia**. Se pide por identificador o por código de barras.

## Existencia (`StockItem`)

| Campo | Tipo | Origen | Notas |
|-------|------|--------|-------|
| `id` | entero | `id` | identificador de inventario; es el que se envía al vender |
| `branchId` | entero | `id_sucursal` | |
| `branchName` | texto | `sucursal` | |
| `size` | texto | `talla` | |
| `color` | texto | `color` | |
| `quantity` | entero | `cantidad` | nunca negativo |

**Estado derivado** (`StockLevel`), calculado en el modelo con la cantidad y el umbral de la prenda:

- `outOfStock`: `quantity == 0`
- `low`: `0 < quantity <= alertThreshold`
- `available`: en otro caso

**Reglas**:
- La existencia de la sucursal del usuario se identifica comparando `branchId` con `User.branchId` de la sesión.
- Solo las existencias de esa sucursal son vendibles. El resto se muestra sin acción de venta.
- Tras una venta aceptada, la fila se reemplaza por la existencia que devuelve la API.

## Sucursal

Se reutiliza `Branch` del Sprint 1 (`id`, `name`). La lista sale de `GET /sucursales` y alimenta el filtro.

## Filtros de búsqueda (`SearchFilters`)

| Campo | Tipo | Notas |
|-------|------|-------|
| `query` | texto | se recortan espacios; la API ignora mayúsculas (a confirmar) |
| `size` | texto, opcional | |
| `color` | texto, opcional | |
| `branchId` | entero, opcional | |

Un filtro vacío no se envía. `SearchFilters` es inmutable y comparable para evitar repetir la misma consulta.

## Solicitud de venta (`SaleRequest`)

| Campo | Tipo | Regla |
|-------|------|-------|
| `stockId` | entero | el `id` de la existencia elegida |
| `quantity` | entero | mayor que 0. Si supera la existencia mostrada solo se avisa, sin bloquear: la existencia mostrada puede estar desactualizada y la API decide (409) |

La sucursal no viaja: la API la toma del token del usuario.

## Sesión (cambio respecto del Sprint 1)

`Session` agrega dos campos para la renovación automática:

| Campo | Tipo | Origen |
|-------|------|--------|
| `refreshToken` | texto, opcional | `refresh_token` de Keycloak |
| `refreshExpiresAt` | fecha, opcional | `refresh_expires_in` más la hora actual |

Reglas:
- Se guardan solo en almacenamiento seguro y nunca se imprimen.
- Una sesión sin `refreshToken` se comporta como en el Sprint 1: al vencer pide iniciar sesión.
- Una sesión guardada por el Sprint 1 (sin estos campos) se lee sin error.

## Errores de catálogo (`CatalogFailure`)

| Tipo | Cuándo | Mensaje al usuario |
|------|--------|--------------------|
| `network` | sin conexión o tiempo agotado | "No hay conexión. Revisa tu internet e inténtalo de nuevo." |
| `server` | error 5xx | "No pudimos completar la operación. Inténtalo de nuevo." |
| `notFound` | 404 en ficha o código | "Prenda no encontrada." |
| `insufficientStock` | 409 `STOCK_INSUFICIENTE` | "Solo quedan N pieza(s) disponibles." |
| `forbidden` | 403 | "No tienes permiso para esta acción." |
| `invalid` | 400 `DATOS_INVALIDOS` | "Revisa los datos e inténtalo de nuevo." |

Un 401 no llega al ViewModel: lo atiende el interceptor (renueva o vuelve al inicio de sesión).
