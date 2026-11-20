# Contrato provisional de acceso (API REST)

**Estado**: provisional. `docs/openapi.yaml` aún no existe; este contrato lo propone la app y debe confirmarse con el Integrante 1. Mientras tanto la app usa el repositorio simulado.

Base: `API_BASE_URL` (configurable por entorno, HTTPS).

## POST /auth/login

Inicia sesión con usuario y contraseña.

**Solicitud** (`application/json`)

```json
{ "username": "string", "password": "string" }
```

**Respuesta 200**

```json
{
  "accessToken": "string",
  "expiresIn": 3600,
  "user": {
    "id": "string",
    "name": "string",
    "role": "ROLE_VENDEDOR | ROLE_ENCARGADO | ROLE_ADMIN",
    "branch": { "id": "string", "name": "string" }
  }
}
```

`branch` puede faltar solo para `ROLE_ADMIN`.

**Errores**

| Código | Significado | Comportamiento de la app |
|--------|-------------|--------------------------|
| 400 | Solicitud inválida | Mensaje genérico de error |
| 401 | Credenciales incorrectas | Mensaje genérico, sin revelar si el usuario existe |
| 403 | Cuenta desactivada | Mensaje claro de cuenta desactivada |
| 5xx / sin respuesta | Servicio no disponible | Mensaje claro con opción de reintentar |

## Encabezado en peticiones autenticadas

`Authorization: Bearer <accessToken>`, agregado por el interceptor. Un 401 posterior se trata como sesión vencida; un 403 muestra aviso de falta de permisos sin cerrar sesión.

## Preguntas abiertas para el Integrante 1

1. ¿Distinguirá la API "cuenta desactivada" con un código propio (por ejemplo, 403 con motivo)?
2. ¿Habrá endpoint de renovación de sesión? (Sprint 1 no lo usa.)
3. ¿Los nombres de campo coinciden con los propuestos?
