# Modelo de datos: Base de la app móvil e inicio de sesión

Los campos exactos dependen del contrato `docs/openapi.yaml` (aún inexistente). Este modelo es el que usa la app; el DTO absorbe cualquier diferencia con la API.

## Entidades

### Branch (Sucursal)

| Campo | Tipo | Reglas |
|-------|------|--------|
| `id` | texto | Obligatorio, no vacío |
| `name` | texto | Obligatorio. Uno de: Huauchinango, Zacatlán, Chignahuapan, Ahuazotepec, Xicotepec (la app no valida la lista; la API la define) |

### AppRole (Rol)

Enumeración cerrada: `admin` (`ROLE_ADMIN`), `manager` (`ROLE_ENCARGADO`), `seller` (`ROLE_VENDEDOR`).

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

### LoginResponseDto (DTO)

Respuesta cruda del acceso: token, segundos de vigencia, `user` con `id`, `name`, `role` y `branch`. Se convierte a `Session` con el Adapter; si falta rol o sucursal en un rol que la requiere, la conversión falla y el acceso se rechaza.

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
