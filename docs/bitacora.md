# Bitácora del proyecto · CheckLizz

Registro del avance por sprint: qué se hizo, quién lo hizo, en qué Pull Request quedó y qué falta. Las bitácoras detalladas de la app móvil están en `docs/evidencia/sprint-1/bitacora-sprint-1.md` y `docs/evidencia/sprint-2/bitacora-sprint-2.md`.

| | |
|---|---|
| Última actualización | 27 de noviembre de 2026 |
| Responsable de la bitácora | Integrante 4 (RocioCastillo25) |
| Tablero | GitHub Projects: *CheckModaLiz* y *CheckLizz · Sprint 1* |
| Entrega final | 11 de diciembre de 2026 |

## Equipo

| Integrante | Usuario | Responsabilidad |
|---|---|---|
| 1 | kar5788-S | API REST y base de datos |
| 2 | Less-Riv | Keycloak, Docker e infraestructura |
| 3 | MonicaItzel25 | App móvil (Flutter) |
| 4 | RocioCastillo25 | Página web, repositorio, proceso y documentación |

## Resumen

| Sprint | Fechas | Meta | Estado |
|---|---|---|---|
| 0 | 6 al 15 de nov | Levantamiento de requerimientos y decisiones de arquitectura | ✅ Terminado |
| 1 | 16 al 21 de nov | Fundamentos e inventario base | ✅ Terminado (pendiente la etiqueta `v0.1.0`) |
| 2 | 23 al 28 de nov | Movilidad y ventas | 🟡 En curso |
| 3 | 30 de nov al 5 de dic | Logística de traspasos | 🟡 API adelantada |
| 4 | 7 al 10 de dic | Reportes, auditoría y entrega | 🟡 API adelantada |

---

## Sprint 0 · Análisis y diseño (6 al 15 de noviembre)

| Fecha | Actividad | Resultado |
|---|---|---|
| 6 nov | Entrevista de levantamiento con personal de las tiendas (formulario de 19 preguntas, 5 respuestas) | Problemas principales: descuadre del inventario (3 de 5) y tiempo perdido coordinándose por chat (2 de 5) |
| 13 nov | Documentos *Arquitectura y patrones de diseño* y *Control de versiones con Gitflow* | Arquitectura cliente-servidor en capas, MVVM en móvil, GitFlow |
| 13 nov | Estructura inicial del repositorio y reglas de protección (*rulesets*) de `main` y `develop` | PR obligatorio con 1 aprobación, sin *force push* |

## Sprint 1 · Fundamentos e inventario base (16 al 21 de noviembre)

| Fecha | Actividad | Quién | PR |
|---|---|---|---|
| 20 nov | Esquema de base de datos, datos semilla de las 5 sucursales y modelo relacional | kar5788-S | #2 |
| 20 nov | API Express con JWT de Keycloak, roles, inventario y ventas; contrato `openapi.yaml` | kar5788-S | #3 |
| 20 nov | Reestructuración del repositorio, plantillas de PR e issues | RocioCastillo25 | #4 |
| 20 nov | App móvil: estructura MVVM e inicio de sesión | MonicaItzel25 | #1 |
| 20 nov | App móvil: inicio de sesión con Keycloak y la API real | MonicaItzel25 | #5 |
| 21 nov | `docker-compose.yml`, realm de Keycloak y `.env.example` | Less-Riv | #6 |
| 21 nov | Prueba del flujo de Pull Request | RocioCastillo25 | #7 |
| 21 nov | Tablero *CheckLizz · Sprint 1* con 18 tareas y reporte de avance | RocioCastillo25 | — |

**Cierre:** la base quedó integrada en `develop`. La app móvil terminó 65 de 68 tareas, con 96 pruebas automáticas y el APK probado en un teléfono Android.

**Problemas y cómo se resolvieron:**

- El contrato de la API llegó distinto del provisional: la app se adaptó en una rama nueva (PR #5).
- Nombres de roles distintos entre Keycloak, API y app: se unificaron en `administrador`, `gerente` y `empleado` (decisión D1, issue #11).

## Sprint 2 · Movilidad y ventas (23 al 28 de noviembre)

| Fecha | Actividad | Quién | PR |
|---|---|---|---|
| 23–25 nov | Contrato de traspasos, notificaciones, reportes y foto de prendas | kar5788-S | #29 |
| 25 nov | API: solicitud y consulta de traspasos | kar5788-S | #30 |
| 25 nov | API: reportes de existencias, más vendido y stock bajo en PDF y Excel | kar5788-S | #32 |
| 25 nov | README: se quitó «asistencia de empleados» (fuera de alcance) y se describieron los componentes | RocioCastillo25 | #31 |
| 25 nov | Tablero: una issue por tarea de la web y la documentación (#33 a #37) | RocioCastillo25 | — |
| 25 nov | **Web:** lista de prendas y existencias por sucursal, con filtro de stock bajo | RocioCastillo25 | #38 |
| 25 nov | **Web:** formulario de alta y edición de prendas | RocioCastillo25 | #39, #40 |
| 25 nov | **Web:** carga inicial de inventario por filas y por CSV, en modos *Sumar* y *Reemplazar* | RocioCastillo25 | #41, #42 |
| 25 nov | Documento técnico final: arquitectura, SOLID, patrones, GitFlow y Docker | RocioCastillo25 | #43 |
| 27 nov | API: foto de prendas y respaldo diario de la base (RNF-08) | kar5788-S | #45 |
| 27 nov | App: búsqueda con filtros, ficha con existencias y renovación de sesión | MonicaItzel25 | #46 |
| 27 nov | Pruebas de aceptación por requerimiento, 19 pruebas automáticas de la web, esta bitácora y presentación | RocioCastillo25 | este PR |

**Pruebas al 27 de noviembre:** web 19 de 19; API 53 pasan y 62 esperan la base de datos; app 191 de 191 (cobertura 85,2 %). Detalle en `docs/pruebas-aceptacion.md`.

**Problemas y cómo se resolvieron:**

- La API solo permite *fijar* la existencia (`PUT /inventario`). Para sumar en la carga inicial, la web lee la existencia y envía el total. Quedó documentado que no es atómico y se propuso `POST /inventario/entradas` (documento técnico, sección 10).
- Se abrieron PRs duplicados de la misma rama (#39/#40, #41/#42, #44 cerrado). Acuerdo: revisar `gh pr list` antes de abrir uno nuevo.
- La documentación decía que la lógica de la web estaba «probada aparte» sin pruebas reales: se agregaron en `web/test/`.

**Pendiente del sprint:** escáner y descuento por venta en la app (MOV-03, MOV-04) y publicar la versión `v0.1.0` en `main` (issue #21).

## Sprint 3 · Logística de traspasos (30 de noviembre al 5 de diciembre)

**Adelantado:** la API de traspasos, cambio de estado y notificaciones ya está en `develop` (PR #29, #30).

**Por hacer:** pantallas de traspasos en la app (MOV-05) y en la web (WEB-03); correr las pruebas de la API con la base levantada.

## Sprint 4 · Reportes, auditoría y entrega (7 al 10 de diciembre)

**Adelantado:** reportes en PDF y Excel (PR #32) y respaldo diario (PR #45).

**Por hacer:** pantalla de reportes en la web (WEB-05), contenedor de la web en Docker, Cloudflare Tunnel, pruebas de extremo a extremo (P-00 a P-07), APK final, versión `v0.2.0` y entrega a la dueña.
