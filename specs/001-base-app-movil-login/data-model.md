# Modelo de datos: Base de la app móvil e inicio de sesión

Los campos exactos dependen del contrato `docs/openapi.yaml` (aún inexistente). Este modelo es el que usa la app; el DTO absorbe cualquier diferencia con la API.

## Entidades

### Branch (Sucursal)

| Campo | Tipo | Reglas |
|-------|------|--------|
| `id` | texto | Obligatorio, no vacío |
| `name` | texto | Obligatorio. Uno de: Huauchinango, Zacatlán, Chignahuapan, Ahuazotepec, Xicotepec (la app no valida la lista; la API la define) |

### AppRole (Rol)

Enumeración cerrada: `admin` (`ROLE_ADMIN` en Keycloak, `administrador` en la API), `manager` (`ROLE_ENCARGADO`, `gerente`), `seller` (`ROLE_VENDEDOR`, `empleado`). `AppRole.tryParse` acepta ambos nombres.

- Un valor de rol desconocido no se acepta: el acceso se rechaza con mensaje claro.
- Etiquetas para pantalla: Administrador, Gerente de tienda, Empleado.

### User (Usuario)

| Campo | Tipo | Reglas |
|-------|------|--------|
| `id` | texto | Obligatorio |
| `name` | texto | Obligatorio; se muestra en la pantalla principal |
| `role` | `AppRole` | Obligatorio; exactamente uno |
| `branch` | `Branch` | Obligatorio para `manager` y `seller`; viene siempre de la respuesta de acceso, nunca de un campo editable |

### Session (Sesión)

| Campo | Tipo | Reglas |
|-------|------|--------|
| `accessToken` | texto | Solo en almacenamiento seguro; nunca se imprime ni se registra |
| `expiresAt` | fecha y hora | Obligatoria; la sesión es vigente si `expiresAt` es posterior a la hora actual |
| `user` | `User` | Obligatorio |

Propiedad derivada: `isValid` (vigente según `expiresAt`).

### DTOs del acceso (según `docs/openapi.yaml`)

- **TokenResponseDto** (Keycloak): `access_token` y `expires_in`.
- **ProfileDto** (`GET /me`): `id`, `nombre`, `rol` (`administrador`, `gerente` o `empleado`) y `sucursalId` (puede faltar para el administrador). `toUser` es el Adapter a `User`.
- **BranchDto** (`GET /sucursales`): `id` y `nombre`. `toBranch` es el Adapter a `Branch`.

Si falta un dato obligatorio, el rol es desconocido o un rol que requiere sucursal no la trae, la conversión falla con "datos incompletos" y el acceso se rechaza. La `Session` se arma con el token, la vigencia (`expires_in`) y el `User`.

## Estados de la sesión (máquina de estados)

```text
Desconocida --(arranque)--> Restaurando
Restaurando --(token vigente guardado)--> Autenticada
Restaurando --(sin token o vencido)--> NoAutenticada
NoAutenticada --(credenciales válidas, rol seller/manager)--> Autenticada
NoAutenticada --(credenciales válidas, rol admin)--> AvisoAdministrador (sin sesión guardada)
Autenticada --(cerrar sesión)--> NoAutenticada
Autenticada --(401 de la API)--> NoAutenticada (con aviso)
AvisoAdministrador --(aceptar aviso)--> NoAutenticada
```

## Estado de la pantalla de inicio de sesión

`inicial` → `cargando` → (`exito` | `error`). Tipos de error: `camposVacios`, `credencialesIncorrectas`, `cuentaDesactivada`, `sinConexion`, `servicioNoDisponible`, `datosIncompletos`.

## Validaciones de la app (mínimas)

- Usuario y contraseña: no vacíos tras quitar espacios en los extremos de usuario (la contraseña no se recorta).
- Las reglas de negocio (cuenta activa, credenciales, rol) las decide la API.
