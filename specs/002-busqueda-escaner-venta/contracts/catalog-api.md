# Contrato con la API: catálogo, inventario y ventas

Fuente de verdad: `docs/openapi.yaml` en `develop` (consultado el 2026-11-26). Este archivo resume lo que la app usa. Si el contrato cambia, el contrato manda.

Base de la API: `API_BASE_URL` (por ejemplo `http://10.0.2.2:3000/api/v1` en el emulador). Todas las peticiones llevan `Authorization: Bearer <token>`, agregado por el interceptor.

Errores de la API: `{ "error": "CODIGO", "mensaje": "...", "detalles": [...] }`. La app usa `error` solo para decidir qué hacer y nunca lo muestra.

## GET /prendas — búsqueda universal

Parámetros de consulta (todos opcionales): `q` (texto en descripción o marca), `codigo`, `categoria`, `talla`, `color`, `sucursalId`.

Respuesta `200`: lista de `PrendaResumen` con `id`, `codigo_barras`, `descripcion`, `marca`, `categoria`, `temporada`, `foto_url`, `umbral_alerta` y `existencia_total`.

Uso en la app: `q`, `talla`, `color` y `sucursalId` desde la hoja de filtros. No se manda ningún parámetro vacío.

## GET /prendas/{id} — ficha

Respuesta `200`: `PrendaFicha` con los datos de la prenda y `existencias`: lista de `{ id, id_sucursal, sucursal, talla, color, cantidad }`. El `id` es el identificador de inventario que se usa para vender.

Errores: `404 NO_ENCONTRADO`.

## GET /prendas/codigo/{codigo} — ficha por código de barras

Mismo cuerpo que la ficha. Es el resultado del escáner y de la búsqueda manual por código.

Errores: `404 NO_ENCONTRADO` (código desconocido). El código se codifica para la ruta (espacios y símbolos).

## POST /ventas — descuento por venta

Cuerpo: `{ "idInventario": <entero>, "cantidad": <entero >= 1> }`.

Respuesta `201`: `Existencia` actualizada `{ id, id_prenda, id_sucursal, sucursal, talla, color, cantidad, umbral_alerta }`.

Errores:
- `403 PROHIBIDO`: la existencia no es de la sucursal del usuario.
- `409 STOCK_INSUFICIENTE`: no hay suficientes piezas. El cuerpo no documenta la existencia actual; la app recarga la ficha para saberla.
- `400 DATOS_INVALIDOS`: cantidad inválida.

La sucursal la decide la API según el usuario; la app no envía sucursal.

## GET /sucursales — lista para el filtro

Respuesta `200`: lista de `{ id, nombre, ubicacion }`. Ya la usa el inicio de sesión.

## Renovación de la sesión (Keycloak)

`POST {KEYCLOAK_BASE_URL}/realms/checklizz/protocol/openid-connect/token`, formulario:

| Campo | Valor |
|-------|-------|
| `grant_type` | `refresh_token` |
| `client_id` | `checklizz-app` |
| `refresh_token` | el guardado en la sesión |

Respuesta `200`: `access_token`, `expires_in`, `refresh_token` (nuevo) y `refresh_expires_in`. Respuesta `400` o `401` (`invalid_grant`): la sesión no se puede renovar y se vuelve al inicio de sesión.

## Puntos abiertos

| Punto | Con quién | Efecto si no se resuelve |
|-------|-----------|--------------------------|
| ¿El realm entrega `refresh_token` al cliente `checklizz-app` y con qué vigencia? | Integrante 2 | Al vencer el token se vuelve al inicio de sesión |
| ¿`q`, `talla` y `color` ignoran mayúsculas y acentos? | Integrante 1 | El filtro puede fallar con distinta escritura |
| ¿`existencia_total` respeta `sucursalId`? | Integrante 1 | La lista muestra la existencia total, sin la etiqueta de sucursal |
| ¿Las fotos (`foto_url`) son accesibles desde el teléfono? | Integrante 1 | Se muestra el marcador de posición |
