# Contrato de acceso (Keycloak y API REST)

**Estado**: alineado con `docs/openapi.yaml` (Integrante 1), publicado en `develop` el 2026-11-20.
Sustituye al contrato provisional (`POST /auth/login`), que ya no existe en la API.

El acceso tiene tres pasos. Los dos últimos usan el token que emite el primero.

## 1. Pedir el token a Keycloak

`POST {KEYCLOAK_BASE_URL}/realms/checklizz/protocol/openid-connect/token`

Cuerpo `application/x-www-form-urlencoded`:

| Campo | Valor |
|---|---|
| `grant_type` | `password` |
| `client_id` | `checklizz-app` |
| `username` | usuario escrito en el formulario |
| `password` | contraseña escrita en el formulario (viaja por HTTPS y nunca se guarda) |

**Respuesta 200** (campos que usa la app): `access_token` y `expires_in` (segundos).

| Respuesta | Significado | Qué muestra la app |
|---|---|---|
| 401 `invalid_grant` | Credenciales incorrectas | Mensaje genérico, sin revelar si el usuario existe |
| 400 `invalid_grant` con "Account disabled" | Cuenta desactivada | Mensaje claro de cuenta desactivada |
| Otro 400 | Solicitud rechazada | Mensaje genérico de credenciales incorrectas |
| 5xx / sin respuesta | Servicio no disponible | Mensaje de servicio caído o de sin conexión, con reintento |

## 2. Leer el perfil

`GET {API_BASE_URL}/me` con `Authorization: Bearer <access_token>`.

**Respuesta 200** (`Perfil`): `id`, `nombre`, `rol`, `sucursalId` (puede ser `null` para el administrador) y `keycloakId`.

El rol llega como `administrador`, `gerente` o `empleado`.

| Respuesta | Qué hace la app |
|---|---|
| 401 | Fallo del servicio (el token acaba de emitirse) |
| 403, o un código de usuario inactivo | Cuenta que no puede usar la app (mensaje de cuenta desactivada) |

## 3. Leer el nombre de la sucursal

`GET {API_BASE_URL}/sucursales` con el mismo encabezado. Solo se pide para gerentes y empleados.

**Respuesta 200**: lista de `{ id, nombre, ubicacion }`. La app busca la sucursal cuyo `id` es `sucursalId` del perfil; si no aparece, el acceso se rechaza como datos incompletos.

## Direcciones

| Entorno | `API_BASE_URL` | `KEYCLOAK_BASE_URL` |
|---|---|---|
| Emulador Android (desarrollo) | `http://10.0.2.2:3000/api/v1` | `http://10.0.2.2:8080` |
| Teléfono físico en la misma red | `http://<IP de la computadora>:3000/api/v1` | `http://<IP de la computadora>:8080` |
| Producción (Cloudflare Tunnel) | `https://<dominio>/api/v1` | `https://<dominio-de-identidad>` |

Solo las versiones de **depuración** aceptan HTTP. La versión release exige HTTPS.

## Encabezado en peticiones autenticadas

`Authorization: Bearer <access_token>`, agregado por el interceptor. Un 401 posterior se trata como sesión vencida; un 403 muestra aviso de falta de permisos sin cerrar sesión.

## Formato de error de la API

`{ "error": "CODIGO", "mensaje": "...", "detalles": [{ "campo", "mensaje" }] }`. La app lo lee para decidir qué hacer y nunca lo muestra tal cual al usuario.

## Puntos abiertos

1. **Vigencia del token.** Keycloak emite tokens cortos por defecto (5 minutos). Sin renovación de sesión, el empleado tendría que iniciar sesión de nuevo cada vez que venza. Conviene acordar con el Integrante 2 una vigencia razonable para la app o incorporar la renovación con `refresh_token` (decisión diferida del Sprint 1).
2. **Usuarios inactivos.** El contrato no define el código de error de la API para un usuario desactivado en la base de datos. La app trata un 403 o un código con "INACTIV" como cuenta desactivada.
3. **HTTPS de desarrollo.** Para probar en un teléfono físico hace falta que la API y Keycloak sean alcanzables desde él.
