# Contratos internos de la app

Interfaces entre capas. Permiten cambiar la implementación (simulada o real) sin tocar pantallas ni ViewModels.

## AuthRepository (interfaz)

```text
login(username, password) -> Session
restoreSession()          -> Session?     # null si no hay token o venció
logout()                  -> void         # borra el token
```

- Lanza `AuthFailure` tipado: `invalidCredentials`, `accountDisabled`, `incompleteData`, `network`, `server`.
- `login` NO persiste la sesión de un usuario con rol `admin`.
- Implementaciones: `ApiAuthRepository` (usa `AuthService` y `TokenStorage`) y `MockAuthRepository`.

### Usuarios de ejemplo (`MockAuthRepository`)

Identificados como de prueba (contraseña de ejemplo solo en el simulador, nunca en datos reales).

| Usuario | Rol | Sucursal | Caso |
|---------|-----|----------|------|
| `demo.vendedor` | `ROLE_VENDEDOR` | Zacatlán | Acceso normal |
| `demo.encargado` | `ROLE_ENCARGADO` | Huauchinango | Acceso normal |
| `demo.admin` | `ROLE_ADMIN` | (sin sucursal) | Aviso a la web |
| `demo.desactivado` | `ROLE_VENDEDOR` | Xicotepec | Cuenta desactivada |

## TokenStorage (interfaz)

```text
save(session) / read() -> StoredSession? / clear()
```

Guarda solo token, expiración y datos del usuario. Nunca la contraseña.

## ConnectivityService (interfaz)

```text
isOnline() -> bool
```

## SessionViewModel

Estado global de sesión: `restoring`, `authenticated(user)`, `unauthenticated`. Acciones: `restore()`, `onLoggedIn(session)`, `logout()`, `onSessionRejected()` (401). Al cerrar sesión limpia el estado de los demás ViewModels.

## LoginViewModel

Estado: `idle`, `loading`, `error(tipo)`. Acción: `submit(username, password)`. Rechaza campos vacíos sin llamar al repositorio y ignora un segundo `submit` mientras está en `loading`. Expone `adminNotice` cuando el rol es administrador.

## HomeViewModel

Expone nombre, etiqueta de rol, sucursal y la lista de secciones futuras (buscar, escanear, traspasos) con `enabled = false` y la etiqueta "próximamente".

## Reglas de dependencia

- View → ViewModel → Repository → Service. Una View nunca importa un Service ni `dio`.
- Un ViewModel nunca importa `package:flutter/material.dart`.
- Las dependencias llegan por constructor; `service_locator.dart` es el único lugar que las ensambla.
