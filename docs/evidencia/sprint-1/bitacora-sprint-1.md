# Bitácora — Sprint 1 (app móvil CheckLizz)

**Integrante:** 3 — Frontend móvil y escaneo (Flutter)
**Sprint:** 1, "Base de la app móvil e inicio de sesión" (16 al 21 de noviembre de 2026)
**Fecha de esta entrada:** 20 de noviembre de 2026 (cierre de la semana, actualizada la misma noche)
**Ramas:** `feature/mobile-base-login` (fusionada) y `feature/mobile-acceso-keycloak` (seguimiento, ver sección 11)
**Pull Requests:** [#1](https://github.com/RocioCastillo25/ModaDeLiz/pull/1) (Sprint 1, **fusionado en `develop`**) y [#5](https://github.com/RocioCastillo25/ModaDeLiz/pull/5) (acceso con Keycloak, en borrador)
**Evidencia en el repositorio:** `docs/evidencia/sprint-1/` (capturas, resultados de pruebas y esta bitácora)

## Resumen de cierre

El Sprint 1 de la app móvil queda **entregado y fusionado en `develop`**: 65 de 68 tareas completadas (96 %), código con 80 pruebas automáticas en verde (96 con el trabajo de seguimiento), APK de prueba instalado y probado en un teléfono Android, y evidencia reunida. El Pull Request #1 lo aprobó y fusionó Karol Salvador el 20 de noviembre de 2026. Las 3 tareas restantes no dependen de código: el escenario de sesión vencida en el teléfono (T056 y T066) y la etiqueta `v0.1.0` con el Integrante 4 (T068).

Ese mismo día apareció el contrato real de la API (`docs/openapi.yaml`), distinto del provisional. El acceso de la app ya se adaptó en una rama nueva (sección 11).

## 1. Objetivo del sprint

Entregar una app Flutter para Android con la estructura MVVM, el tema visual de CheckLizz, la comunicación con la API preparada y un inicio de sesión que lleve a una pantalla principal según el rol del usuario. Mientras la API y el sistema de identidad no estén listos, la app funciona con datos de ejemplo.

## 2. Trabajo realizado

### Proceso (Spec Kit)
- Constitución del proyecto (v1.1.0) a partir de `docs/reglas.md`.
- Especificación del Sprint 1, con 5 historias de usuario, 25 requisitos funcionales y 9 criterios de éxito.
- Sesión de aclaraciones: se resolvieron 3 decisiones (administrador en móvil, mecanismo de inicio de sesión y renovación de sesión).
- Plan de implementación, investigación técnica, modelo de datos, contratos y guía de validación.
- Lista de 68 tareas organizadas por historia de usuario.

### Código (`mobile/`)
- Proyecto Flutter con MVVM (`ChangeNotifier`) e inyección de dependencias con `get_it`.
- Inicio de sesión con usuario y contraseña, y mensajes claros ante errores (credenciales incorrectas, cuenta desactivada, sin conexión, servicio caído).
- Cierre de sesión que borra el token y limpia el estado.
- Sesión persistente en almacenamiento seguro; si vence, o la API responde 401, se vuelve al inicio de sesión; un 403 avisa sin cerrar la sesión.
- Pantalla principal con nombre, rol y sucursal, y accesos a búsqueda, escáner y traspasos marcados como "próximamente".
- Aviso para el administrador, que lo dirige a la página web; su sesión no se conserva.
- Repositorio simulado con 4 usuarios de ejemplo, intercambiable por la API real con `--dart-define=USE_MOCK=false`.
- Diseño en glassmorphism rosa pastel y blanco, con el logo de Moda D' Liz, y respeto a la preferencia de reducir animaciones.
- Icono de la app con el logo.

### Trabajo adicional (no planeado al inicio)
- Rediseño de la interfaz a petición del equipo, de estilo oscuro a rosa pastel y blanco. Se actualizaron `docs/project-context.md`, `docs/reglas.md`, la constitución y la especificación para que coincidan.
- Diseño editable en Figma: paleta de 16 colores, 6 componentes y 4 pantallas.
- Reducción de la memoria máxima de Gradle de 8 GB a 2 GB, porque la compilación se detenía por falta de memoria.

## 3. Avance

**65 de 68 tareas completadas (96 %).**

| Fase | Hechas | Total |
|---|---|---|
| Preparación | 5 | 5 |
| Fundamentos | 18 | 18 |
| US5 — Base, datos de ejemplo e imagen | 14 | 14 |
| US1 — Iniciar sesión y pantalla principal | 9 | 9 |
| US2 — Cerrar sesión | 4 | 4 |
| US3 — Sesión persistente y expiración | 5 | 6 |
| US4 — Comportamiento por rol (administrador) | 5 | 5 |
| Pulido y entrega | 5 | 7 |

Las historias US1 a US4 tienen el código y las pruebas automáticas terminados. US1, US2 y US4 ya están validadas también en el teléfono. A US3 (sesión persistente y expiración) solo le falta validar en el teléfono el escenario de sesión vencida, que está cubierto por pruebas automáticas (ver sección 4).

## 4. Pruebas

| Verificación | Resultado |
|---|---|
| `flutter analyze` | Sin avisos |
| `flutter test` | 80 pruebas aprobadas, 0 fallidas |
| Dispositivo | Teléfono Android (RMX3890, Android 15), versión de depuración con datos de ejemplo |

### Escenarios validados en el teléfono (guía `quickstart.md`)

| # | Escenario | Resultado | Captura |
|---|---|---|---|
| 1 | Empleado (`demo.vendedor`) entra: nombre, rol "Empleado" y sucursal "Zacatlán" | Aprobado | `04-pantalla-principal.png` |
| 2 | Gerente (`demo.encargado`): "Gerente de tienda" y "Huauchinango" | Aprobado | `04b-pantalla-principal-gerente.png` |
| 3 | Contraseña incorrecta: mensaje genérico, no entra | Aprobado | `03-credenciales-incorrectas.png` |
| 4 | Campos vacíos: indica qué falta y no envía | Aprobado | `02-campos-vacios.png` |
| 5 | Cuenta desactivada: mensaje claro, no entra | Aprobado | `06-cuenta-desactivada.png` |
| 6 | Administrador: aviso hacia la web, sin pantalla principal y sin sesión guardada al reabrir | Aprobado | `05-aviso-administrador.png` |
| 8 | Sin conexión (modo avión): avisa y no intenta el acceso | Aprobado | `07-sin-conexion.png` |
| 9 | Reabrir con sesión vigente: entra directo | Aprobado | — |
| 10 | Cerrar sesión: vuelve al inicio y, al reabrir, pide iniciar sesión | Aprobado | — |
| 13 | Tres accesos "Próximamente" en la pantalla principal | Aprobado | `04-pantalla-principal.png` |
| 7 | Tres pulsaciones seguidas en "Iniciar sesión": entra una sola vez y sin errores | Aprobado | — |
| 12 | Con las animaciones del sistema en cero, iniciar y cerrar sesión funcionan | Aprobado (funcional; el efecto visual se cubre con el código que consulta la preferencia del sistema) | — |
| 11 | Sesión vencida pide iniciar sesión | Solo en pruebas automáticas (no se puede adelantar el reloj del teléfono sin acceso root) | — |

### APK de prueba

| Dato | Valor |
|---|---|
| Archivo | `checklizz-sprint1-prueba.apk` (47.2 MB, versión release, datos de ejemplo) |
| SHA-256 | `06DA45A9A2B1113F659F9181264FA929016E7A28309679D52B1F21ED8BA0B2B9` |
| Instalación | Correcta en el teléfono Android RMX3890 (Android 15) |
| Prueba en el teléfono | Abre, inicia sesión como empleado (Zacatlán), conserva la sesión al reabrir y cierra sesión. Sin aviso de guardar contraseña |
| Firma | Con la llave de depuración: sirve para instalar y probar. La firma de producción queda fuera del Sprint 1 |

Las pruebas automáticas cubren: éxito, credenciales incorrectas, cuenta desactivada, campos vacíos, doble envío, sin conexión, servicio caído, datos incompletos, sesión vigente y vencida, errores 401 y 403, y administrador sin sesión guardada.

Detalle completo en `pruebas-flutter.txt`.

## 5. Problemas encontrados y cómo se resolvieron

| Problema | Solución |
|---|---|
| El botón "Cerrar sesión" quedaba fuera de pantalla en teléfonos pequeños (lo detectó una prueba) | Se fijó al pie de la pantalla |
| El encabezado de la pantalla principal se desbordaba 45 píxeles con el logo nuevo (lo detectó una prueba) | Se redujo el logo y el nombre se ajusta si no cabe |
| La compilación se detenía por falta de memoria | Se bajó la memoria máxima de Gradle a 2 GB |
| El emulador Android no arrancó (x86 de 32 bits no compatible) | Se probó en un teléfono físico |
| Tras la prueba del modo avión, el teléfono quedó sin red y la app avisó "Sin conexión" (comportamiento correcto) | Se reconectaron Wi-Fi y datos y se repitió la prueba del APK |
| Al iniciar sesión, Android ofrecía guardar la contraseña en el Administrador de contraseñas de Google (contradice la regla de no guardar la contraseña) | Se desactivó el autocompletado de los campos de usuario y contraseña y se canceló el contexto de autocompletado |
| Una captura mostraba datos personales del teléfono (correo y notificaciones) | Se repitió la captura y se recortó la barra de estado en todas |

## 6. Decisiones tomadas

1. El administrador ve un aviso que lo dirige a la web, no entra a la app y su sesión no se conserva.
2. El inicio de sesión usa un formulario propio dentro de la app.
3. Ante un 401 se vuelve directo al inicio de sesión; la renovación de sesión se difiere a un sprint posterior.
4. La estética pasa a rosa pastel y blanco con el logo de la tienda (cambio de la sección 12 de `project-context.md`).

## 7. Pendientes para cerrar el sprint

- [ ] Escenario 11 (sesión vencida) en el teléfono: hoy solo en pruebas automáticas (T056 y T066).
- [ ] Entregar el APK a la dueña para que lo pruebe.
- [x] Pull Request #1 revisado, aprobado y fusionado en `develop` (20 de noviembre de 2026).
- [ ] Etiqueta `v0.1.0`, coordinada con el Integrante 4 (T068).
- [ ] Revisión del Pull Request #5 (acceso con Keycloak) y prueba contra Keycloak y la API reales.

## 8. Dependencias con otros integrantes

| Necesito | De | Estado |
|---|---|---|
| Contrato `docs/openapi.yaml` | Integrante 1 | Publicado el 20 de noviembre. Difiere del contrato provisional; la app se adaptó (PR #5). Falta definir el error de la API para un usuario inactivo |
| Realm, roles y usuarios de prueba en Keycloak | Integrante 2 | Pendiente. Mientras tanto, usuarios de ejemplo. Hay que confirmar que el cliente `checklizz-app` permite `grant_type=password` y acordar la vigencia del token |
| Rama `develop` y reglas de Pull Request | Integrante 4 | Disponible. El PR #1 se fusionó con la aprobación de otra persona |

## 9. Riesgos

- El contrato real de la API podía diferir del provisional, y así fue. El cambio quedó aislado en la capa de datos (servicio, DTOs y repositorio), sin tocar pantallas ni ViewModels (sección 11).
- Los tokens de Keycloak duran 5 minutos por defecto. Sin renovación de sesión, el empleado tendría que iniciar sesión de nuevo con esa frecuencia. Hay que acordar la vigencia con el Integrante 2 o incorporar `refresh_token` en el Sprint 2.
- La fecha límite del sprint es el 21 de noviembre. Las validaciones en dispositivo y el APK dependen de tener el teléfono conectado y memoria libre para compilar.

## 10. Evidencia adjunta

| Archivo | Qué muestra | Estado |
|---|---|---|
| `pruebas-flutter.txt` | Resultado de `flutter analyze` y `flutter test` | Listo |
| `01-inicio-sesion.png` | Pantalla de inicio de sesión | Listo |
| `02-campos-vacios.png` | Aviso de campos vacíos | Listo |
| `03-credenciales-incorrectas.png` | Mensaje genérico | Listo |
| `04-pantalla-principal.png` | Nombre, rol y sucursal del empleado | Listo |
| `04b-pantalla-principal-gerente.png` | Pantalla principal del gerente | Listo |
| `05-aviso-administrador.png` | Aviso hacia la página web | Listo |
| `06-cuenta-desactivada.png` | Mensaje de cuenta desactivada | Listo |
| `07-sin-conexion.png` | Aviso de sin conexión | Listo |
| `checklizz-sprint1-prueba.apk` | APK de prueba (release, datos de ejemplo) | Listo. Se entrega por separado: no se sube al repositorio por su tamaño (47 MB) |
| Diseño en Figma | https://www.figma.com/design/wTgySHkdZDt93fM4dYnTPx | Listo |


## 11. Seguimiento posterior al cierre (20 de noviembre de 2026, noche)

### Novedades del repositorio
- **Pull Request #1 fusionado.** Karol Salvador lo aprobó (colaboradora del repositorio) y lo fusionó en `develop` a las 20:43 UTC. Con esto se cumple la definición de "hecha" de `docs/reglas.md`: integrado por un Pull Request revisado por otra persona.
- **Contrato de la API publicado.** El Integrante 1 subió `docs/openapi.yaml`, junto con `docs/modelo-relacional.md`. Otros Pull Requests (#2, #3 y #4) agregaron la base de datos, la API y una reestructuración del repositorio (`api/` e `infra/`). Las carpetas de la app móvil no cambiaron de lugar.
- **Copia de trabajo conectada a GitHub.** La carpeta de trabajo ya es un repositorio git limitado a `mobile`, `docs`, `specs` y `.specify`, con un script para subir avances con el formato de commits del proyecto.

### Diferencias entre el contrato real y el provisional

| Tema | Contrato real | Lo que asumía la app |
|---|---|---|
| Inicio de sesión | Contra Keycloak: `POST .../realms/checklizz/protocol/openid-connect/token` con `grant_type=password` y `client_id=checklizz-app` | `POST /auth/login` en la API |
| Datos del usuario | `GET /me`: id, nombre, rol y `sucursalId` | Todo venía en la respuesta de acceso |
| Roles | `administrador`, `gerente`, `empleado` | `ROLE_ADMIN`, `ROLE_ENCARGADO`, `ROLE_VENDEDOR` |
| Nombre de la sucursal | `GET /sucursales` | Venía en la respuesta de acceso |
| Errores | `{error, mensaje, detalles}` | Códigos HTTP simples |

### Trabajo realizado
- Rama `feature/mobile-acceso-keycloak`, creada desde `develop`.
- Acceso adaptado al contrato real: token de Keycloak, perfil en `/me` y sucursal en `/sucursales`. Se agregaron los DTOs de token, perfil y sucursal; el servicio y el repositorio real se reescribieron; los roles de la API se reconocen junto con los de Keycloak.
- Pantallas y ViewModels sin cambios. El modo de ejemplo sigue igual y el APK de prueba no se ve afectado.
- Direcciones por entorno: `API_BASE_URL` y `KEYCLOAK_BASE_URL`. HTTP permitido solo en las versiones de depuración.
- Documentación alineada: `contracts/auth-api.md` reescrito, y modelo de datos, investigación, plan, quickstart y README actualizados.

### Resultado
- `flutter analyze` sin avisos y **96 pruebas automáticas en verde** (80 del Sprint 1 y 16 nuevas del flujo real).
- Pull Request #5 abierto en borrador hacia `develop`.
- **Sin probar contra Keycloak ni la API reales:** los servicios no están disponibles desde el equipo de desarrollo. Las pruebas usan respuestas simuladas escritas según `docs/openapi.yaml`.

### Puntos abiertos para el equipo
1. **Integrante 2 (Keycloak):** confirmar que el cliente `checklizz-app` permite el flujo de contraseña directa y acordar una vigencia del token razonable para la app (el valor por defecto es de 5 minutos).
2. **Integrante 1 (API):** definir el error de la API para un usuario inactivo. Hoy la app lo trata como cuenta desactivada si recibe un 403 o un código que contenga la palabra inactivo.
3. **Renovación de sesión:** recomendada para el Sprint 2, con `refresh_token`, para no pedir inicio de sesión cada pocos minutos.

### Próximos pasos
- Revisión del Pull Request #5 y prueba real contra Keycloak y la API cuando estén disponibles.
- Etiqueta `v0.1.0` con el Integrante 4.
- Entregar el APK de prueba a la dueña.
- Iniciar el Sprint 2 (búsqueda, ficha de prenda, escáner y descuento por venta) en una rama nueva desde `develop`, con `/speckit.specify` a partir de `docs/sprint-2.md`.