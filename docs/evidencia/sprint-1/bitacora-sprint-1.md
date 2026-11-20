# Bitácora — Sprint 1 (app móvil CheckLizz)

**Integrante:** 3 — Frontend móvil y escaneo (Flutter)
**Sprint:** 1, "Base de la app móvil e inicio de sesión" (16 al 21 de noviembre de 2026)
**Fecha de esta entrada:** 20 de noviembre de 2026 (cierre de la semana)
**Rama:** `feature/mobile-base-login`
**Pull Request:** https://github.com/RocioCastillo25/ModaDeLiz/pull/1 (en borrador, con 8 commits)
**Evidencia en el repositorio:** `docs/evidencia/sprint-1/` (capturas, resultados de pruebas y esta bitácora)

## Resumen de cierre

El Sprint 1 de la app móvil queda **entregado a falta de la revisión del Pull Request**: 65 de 68 tareas completadas (96 %), código con 80 pruebas automáticas en verde, APK de prueba instalado y probado en un teléfono Android, y evidencia reunida. Las 3 tareas restantes no dependen de código: el escenario de sesión vencida en el teléfono (T056 y T066) y la aprobación del Pull Request con la etiqueta `v0.1.0` (T068).

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
- [ ] Pull Request revisado y aprobado por otra persona, y etiqueta `v0.1.0`, coordinados con el Integrante 4 (T068).
- [ ] Pasar el Pull Request de borrador a "listo para revisión".

## 8. Dependencias con otros integrantes

| Necesito | De | Estado |
|---|---|---|
| Contrato `docs/openapi.yaml` de autenticación | Integrante 1 | No existe aún. Se usa un contrato provisional (`specs/001-base-app-movil-login/contracts/auth-api.md`) con 3 preguntas abiertas |
| Realm, roles y usuarios de prueba en Keycloak | Integrante 2 | Pendiente. Mientras tanto, usuarios de ejemplo |
| Rama `develop` y reglas de Pull Request | Integrante 4 | Disponible. El PR necesita al menos 1 aprobación |

## 9. Riesgos

- El contrato real de la API puede diferir del provisional. El cambio queda aislado en `login_response_dto.dart`.
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
