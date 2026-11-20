<!--
Documento de entrada para /speckit.specify.
No guardar este archivo dentro de la carpeta specs/ generada por Spec Kit.
-->

# Insumo de especificación - Sprint 1: Base de la app móvil e inicio de sesión

> **Referencias obligatorias para el agente:**
>
> - Contexto maestro: `docs/project-context.md`
> - Constitución técnica: `docs/reglas.md`
> - Este documento describe únicamente el alcance del Sprint 1 de la app móvil (16 al 21 de noviembre de 2026).

## 1. Contexto

El Sprint 1 del proyecto construye los fundamentos del sistema: Docker, base de datos, usuarios y roles, y carga inicial del inventario. Esa parte la desarrollan otros integrantes. Para la app móvil, este sprint consiste en dejar listo el proyecto Flutter con la arquitectura definida y con el inicio de sesión funcionando, de modo que los siguientes sprints solo agreguen funcionalidades.

Como la API y Keycloak se construyen en paralelo, la app debe poder avanzar contra **repositorios simulados** y cambiar a la API real sin tocar las pantallas ni los ViewModels.

## 2. Objetivo

Entregar una app Flutter que se ejecute en Android, con la estructura MVVM completa, el tema visual de CheckLizz, la comunicación con la API preparada y un inicio de sesión que lleve a una pantalla principal según el rol del usuario.

## 3. Historias de usuario

### US-S1-01 — Estructura base del proyecto

Como integrante del equipo, quiero un proyecto Flutter con la arquitectura MVVM, la inyección de dependencias y el tema visual ya configurados para que las siguientes funcionalidades se construyan sobre una base ordenada.

### US-S1-02 — Inicio de sesión

Como empleado o gerente, quiero iniciar sesión con mi usuario y contraseña para acceder a las funciones que me corresponden.

### US-S1-03 — Cierre de sesión

Como usuario autenticado, quiero cerrar mi sesión para que otra persona no use mi cuenta desde el mismo teléfono.

### US-S1-04 — Sesión persistente y expiración

Como usuario autenticado, quiero que la app recuerde mi sesión mientras el token sea válido y me pida iniciar sesión de nuevo cuando expire, para no escribir mis datos cada vez que abro la app.

### US-S1-05 — Pantalla principal por rol

Como empleado o gerente, quiero ver una pantalla principal con mi nombre, mi rol y mi sucursal para confirmar que entré con la cuenta correcta.

## 4. Alcance funcional

### 4.1 Estructura del proyecto

- Proyecto Flutter en `mobile/` para Android e iPhone.
- Carpetas `core/` (`di`, `network`, `security`, `theme`), `data/` (`models`, `dto`, `repositories`, `services`), `features/` y `shared/`, según `docs/reglas.md`.
- Registro de dependencias con `get_it`.
- `ApiClient` como Singleton con la dirección de la API configurable por entorno.
- Interceptor (Decorator) que agrega el token a cada petición.
- Tema central con los colores, la tipografía y los componentes base del diseño visual.
- Navegación entre el inicio de sesión y la pantalla principal.

### 4.2 Inicio de sesión

- Formulario con usuario y contraseña, y botón "Iniciar sesión".
- Validación mínima en la app: campos no vacíos.
- Estados visibles: cargando, error y éxito.
- Mensaje genérico ante credenciales incorrectas.
- Rechazo de cuentas desactivadas con un mensaje claro.
- Lectura del rol y la sucursal del usuario a partir de la respuesta de autenticación.
- Un administrador (`ROLE_ADMIN`) ve un aviso que lo dirige a la página web, según la decisión pendiente del contexto.

### 4.3 Sesión

- Token guardado en almacenamiento seguro.
- Al abrir la app, si hay un token vigente, se entra directamente a la pantalla principal.
- Si el token expiró o la API responde 401, se vuelve al inicio de sesión.
- Cerrar sesión borra el token y limpia el estado.

### 4.4 Pantalla principal

- Muestra nombre del usuario, rol y sucursal asignada.
- Contiene el acceso a las secciones que se construirán en los siguientes sprints (búsqueda, escáner, traspasos). En este sprint pueden mostrarse deshabilitadas o marcadas como "próximamente".
- Botón para cerrar sesión.

### 4.5 Repositorios simulados

- Una implementación simulada de autenticación con usuarios de ejemplo de cada rol y una sucursal asignada.
- Se puede alternar entre la implementación simulada y la real desde el registro de dependencias.
- Los datos de ejemplo están identificados como de prueba.

### 4.6 Diseño visual

- Fondo rosa pastel y blanco con degradado y tarjetas de vidrio discreto, y el logo de la tienda, según la sección 12 de `docs/project-context.md`.
- La pantalla de inicio de sesión muestra el nombre "CheckLizz" y un formulario claro y de lectura rápida.
- Botones grandes y estados de foco visibles.
- Animaciones suaves y breves, con respeto a la preferencia de reducir movimiento.

## 5. Roles y permisos del Sprint 1

| Rol | Inicio de sesión en la app | Pantalla principal |
|---|---|---|
| Empleado (`ROLE_VENDEDOR`) | Sí | Sí |
| Gerente (`ROLE_ENCARGADO`) | Sí | Sí |
| Administrador (`ROLE_ADMIN`) | Aviso que lo dirige a la web (pendiente de confirmar) | No |

## 6. Reglas de negocio

- Solo usuarios con cuenta activa pueden iniciar sesión.
- El mensaje ante credenciales incorrectas no revela si el usuario existe.
- La contraseña nunca se guarda en el dispositivo.
- El token se guarda solo en almacenamiento seguro.
- Cada usuario pertenece a una sucursal; la app la toma de la respuesta de autenticación.
- Un token expirado obliga a iniciar sesión de nuevo.

## 7. Criterios de aceptación

### Estructura

- El proyecto compila y se ejecuta en un emulador o dispositivo Android.
- Las carpetas y capas siguen `docs/reglas.md`.
- Las pantallas no llaman a la API ni a los Services directamente.
- Cambiar de repositorio simulado a real no requiere modificar ViewModels ni pantallas.

### Inicio y cierre de sesión

- Con credenciales válidas se llega a la pantalla principal.
- Con credenciales incorrectas se muestra el mensaje genérico y no se entra.
- Con campos vacíos no se envía la petición.
- Con una cuenta desactivada se muestra un mensaje claro.
- Mientras se procesa el inicio de sesión, el botón está deshabilitado.
- Cerrar sesión regresa al inicio de sesión y borra el token.

### Sesión

- Al reabrir la app con un token vigente se entra sin pedir credenciales.
- Con un token expirado o una respuesta 401 se vuelve al inicio de sesión.

### Pantalla principal

- Se muestran correctamente nombre, rol y sucursal.
- Un administrador no accede a la pantalla principal y recibe el aviso.

### Pruebas

- Los ViewModels de autenticación se prueban con el repositorio simulado: éxito, credenciales incorrectas, cuenta desactivada y token expirado.

## 8. Entidades principales

- **Usuario:** identificador, nombre, rol y sucursal asignada.
- **Sesión:** token de acceso, expiración y usuario autenticado.
- **Sucursal:** identificador y nombre.

La definición de los campos exactos depende del contrato `docs/openapi.yaml` y de los datos que emita Keycloak.

## 9. Entregables

- Proyecto Flutter en `mobile/` con la arquitectura MVVM y `get_it`.
- Tema visual central.
- Inicio y cierre de sesión con repositorio simulado y preparado para el real.
- Sesión persistente con almacenamiento seguro.
- Pantalla principal por rol.
- Pruebas de los ViewModels de autenticación.
- APK instalable de prueba.
- Evidencia para la bitácora (capturas del inicio de sesión y la pantalla principal).
- Etiqueta de versión `v0.1.0` al cerrar el sprint, coordinada con el Integrante 4.

## 10. Dependencias con otros integrantes

| Necesita | De quién | Mientras tanto |
|---|---|---|
| Contrato `docs/openapi.yaml` de autenticación y usuario | Integrante 1 | Repositorio simulado |
| Realm, roles y usuarios de prueba en Keycloak | Integrante 2 | Usuarios de ejemplo en el repositorio simulado |
| Rama `develop` y reglas de Pull Request | Integrante 4 | Trabajar en `feature/mobile-*` local |

## 11. Fuera de alcance

- Búsqueda, ficha de prenda, escáner y descuento de stock (Sprint 2).
- Traspasos y notificaciones (Sprint 3 y 4).
- Registro de cuentas y recuperación de contraseña desde la app: las cuentas las administra la dueña en la web.
- Precios y descuentos comerciales.
- Modo sin conexión.
- Funciones de la web, la API y la infraestructura.

## 12. Cierre del sprint

El Sprint 1 se considera cerrado cuando la app inicia sesión, mantiene y cierra la sesión según los criterios anteriores, las pruebas de autenticación pasan, el APK de prueba fue instalado en un dispositivo Android y la evidencia está en la bitácora.
