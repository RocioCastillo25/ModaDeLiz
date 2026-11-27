# Pruebas de aceptación por requerimiento · CheckLizz

| | |
|---|---|
| Versión del sistema | `v0.1.0` |
| Fecha de ejecución | 27 de noviembre de 2026 |
| Responsable | Integrante 4 (RocioCastillo25) · proceso y documentación |
| Evidencia | `docs/evidencia/entrega/` (salidas de pruebas) y `docs/evidencia/sprint-1/`, `sprint-2/` (capturas y pruebas de la app) |

## Cómo leer este documento

Cada requerimiento tiene un **criterio de aceptación** (qué debe pasar para darlo por bueno), el **tipo de prueba** con que se verificó y el **resultado**:

| Resultado | Significado |
|---|---|
| ✅ Aceptada | Se probó y cumple el criterio |
| 🟡 Parcial | Cumple en la API o en un cliente, falta otra parte, o falta la prueba en el sistema completo |
| ⏳ Pendiente | Está planeado en un sprint posterior; todavía no se puede probar |

Los identificadores (`MOV-xx`, `WEB-xx`, `RF-xx`, `RNF-xx`) son los que usa el contrato `docs/openapi.yaml` y el código. Los requerimientos de la base (inicio de sesión, roles) se identifican con su historia de usuario (`US-S1-xx`). **Pendiente del equipo:** confirmar los identificadores que faltan (RF-01 a RF-05, RF-08 a RF-12 y RNF-01 a RNF-07) con la lista oficial de requerimientos y agregarlos a la tabla.

## Resumen de pruebas automáticas

| Componente | Comando | Pruebas | Resultado | Evidencia |
|---|---|---|---|---|
| Página web | `cd web && npm test` | 19 | **19 pasan**, 0 fallan | `evidencia/entrega/pruebas-web.txt` |
| Página web (compilación) | `cd web && npm run build` | — | Compila sin errores | `evidencia/entrega/build-web.txt` |
| API | `cd api && npm test` | 115 | **53 pasan**, 0 fallan, **62 omitidas** | `evidencia/entrega/pruebas-api.txt` |
| App móvil | `cd mobile && flutter test` | 191 | **191 pasan** (cobertura 85,2 %) | `evidencia/sprint-2/pruebas-flutter.txt` |

> Las 62 pruebas omitidas de la API son las de servicios (traspasos, notificaciones, reportes, fotos) que necesitan PostgreSQL. Se omiten solas cuando no hay base de datos. **Para aceptarlas hay que correrlas con `docker compose up -d` y registrar el resultado aquí** (sección *Pruebas pendientes con el sistema completo*).

---

## 1. Base del sistema: acceso, sesión y roles

| ID | Requerimiento | Criterio de aceptación | Tipo de prueba | Resultado | Evidencia |
|---|---|---|---|---|---|
| US-S1-02 | Inicio de sesión | Con usuario y contraseña válidos entra a la pantalla principal; con campos vacíos o datos incorrectos muestra un mensaje claro y no entra | Automática (Flutter) + manual en teléfono | ✅ Aceptada | `sprint-1/01`, `02`, `03-*.png` |
| US-S1-02 | Cuenta desactivada | Una cuenta desactivada no puede entrar aunque la contraseña sea correcta | Automática + manual | ✅ Aceptada | `sprint-1/06-cuenta-desactivada.png` |
| US-S1-02 | Sin conexión | Sin red, la app avisa en lugar de quedarse cargando | Manual en teléfono | ✅ Aceptada | `sprint-1/07-sin-conexion.png` |
| US-S1-03 | Cierre de sesión | Al cerrar sesión se borra el token y vuelve al inicio | Automática (Flutter) | ✅ Aceptada | `sprint-1/pruebas-flutter.txt` |
| US-S1-04 | Sesión persistente y expiración | Al reabrir la app sigue la sesión; al vencer el token se renueva sola o pide entrar de nuevo | Automática (Flutter) | 🟡 Parcial | Falta el escenario de sesión vencida en el teléfono (T056, T066 de la bitácora del Sprint 1) |
| US-S1-05 | Pantalla principal por rol | Empleado y gerente ven su nombre, rol y sucursal; la administradora recibe el aviso de usar la web | Automática + manual | ✅ Aceptada | `sprint-1/04-*.png`, `05-aviso-administrador.png` |
| — | Permisos verificados en la API | Una petición sin token responde 401; con un rol sin permiso, 403, aunque el botón esté oculto en la interfaz | Revisión de código (`middlewares/auth.js`, `requireRole`) | 🟡 Parcial | Falta la prueba con el sistema completo (P-01) |

## 2. App móvil

| ID | Requerimiento | Criterio de aceptación | Tipo de prueba | Resultado | Evidencia |
|---|---|---|---|---|---|
| MOV-01 | Búsqueda universal | Busca por texto, talla, color y sucursal; muestra estados de cargando, sin resultados y error | Automática (Flutter) | ✅ Aceptada | `sprint-2/pruebas-flutter.txt`, PR #46 |
| MOV-02 | Ficha de prenda con existencias | Muestra la existencia en las 5 sucursales, destaca la propia y marca agotado o bajo con ícono y texto | Automática (Flutter) | ✅ Aceptada | `sprint-2/pruebas-flutter.txt`, PR #46 |
| MOV-03 | Escaneo de código de barras | Al escanear una etiqueta abre la ficha; un código desconocido muestra un aviso | API lista (`GET /prendas/codigo/{codigo}`) | ⏳ Pendiente | App: paquete del escáner preparado; pantalla en el Sprint 2 |
| MOV-04 | Descuento de stock por venta | El empleado descuenta piezas solo de su sucursal; la existencia nunca queda negativa | API lista (`POST /ventas` con `FOR UPDATE` y `CHECK cantidad >= 0`) | 🟡 Parcial | App pendiente en el Sprint 2; prueba de API en P-02 |
| MOV-05 | Solicitud de traspasos desde la app | El empleado pide piezas a otra sucursal y ve el estado de su solicitud | API lista (`POST/GET /traspasos`) | ⏳ Pendiente | App en el Sprint 3 |

## 3. Página web

| ID | Requerimiento | Criterio de aceptación | Tipo de prueba | Resultado | Evidencia |
|---|---|---|---|---|---|
| WEB-01 | Catálogo y existencias | La lista muestra solo prendas activas con su existencia total; busca por texto, talla y sucursal; la ficha trae la existencia de cada sucursal | Automática (5 pruebas) | ✅ Aceptada | `pruebas-web.txt` · PR #38 |
| WEB-01 | Permisos por sucursal | La administradora ve las 5 sucursales; el gerente solo la suya y recibe 403 si pide otra | Automática | ✅ Aceptada | `pruebas-web.txt` |
| WEB-01 | Alta y edición de prendas | El formulario rechaza datos incompletos antes de enviar; un código de barras repetido responde 409; editar no cambia el código | Automática (3 pruebas) | ✅ Aceptada | `pruebas-web.txt` · PR #39, #40 |
| WEB-02 | Carga inicial por filas | En modo *Sumar* la cantidad se suma a la existencia; en *Reemplazar* queda fija (admite 0); cada fila inválida explica su problema; un código inexistente no detiene las demás filas | Automática (5 pruebas) | ✅ Aceptada | `pruebas-web.txt` · PR #41, #42 |
| WEB-02 | Carga inicial por CSV | Lee CSV con o sin encabezado, con coma, punto y coma o tabuladores (pegado de Excel), comillas y acentos; la sucursal puede venir por nombre o número; la plantilla descargable se vuelve a leer sin errores | Automática (6 pruebas) | ✅ Aceptada | `pruebas-web.txt` · PR #42 |
| WEB-02 | Gerente limitado a su sucursal | Un gerente no puede cargar a otra sucursal: la página lo avisa y la API responde 403 | Automática | ✅ Aceptada | `pruebas-web.txt` |
| WEB-03 | Traspasos en la web | Gerente y administradora ven y aprueban los traspasos de su alcance | API lista (`GET /traspasos`, `PATCH /traspasos/{id}/estado`) | ⏳ Pendiente | Pantalla web en el Sprint 3 |
| WEB-04 | Stock bajo | El filtro *Solo stock bajo o agotado* deja solo existencias en o por debajo del umbral de la prenda | Automática | ✅ Aceptada | `pruebas-web.txt` |
| WEB-05 | Reporte de existencias | La administradora descarga el reporte en PDF y Excel | API lista (`GET /reportes/existencias`) | ⏳ Pendiente | Pantalla web en el Sprint 4 |

## 4. API: traspasos, notificaciones y reportes

| ID | Requerimiento | Criterio de aceptación | Tipo de prueba | Resultado | Evidencia |
|---|---|---|---|---|---|
| RF-06 | Solicitud de traspasos | No se piden más piezas de las que tiene el origen; los estados siguen `SOLICITADO → APROBADO/RECHAZADO → EN_CAMINO → RECIBIDO`; al recibir se mueve el stock | Automática: reglas de dominio ✔; servicio con BD omitido | 🟡 Parcial | `pruebas-api.txt` (`traspasos.dominio`); P-03 |
| RF-07 | Notificaciones | Quien solicitó recibe aviso en cada cambio de estado; cada usuario solo ve y marca los suyos | Automática con BD (omitida) | 🟡 Parcial | P-04 |
| RF-13 | Stock bajo | El reporte lista las prendas en o por debajo del umbral | Automática: dominio ✔; servicio omitido | 🟡 Parcial | `pruebas-api.txt` (`reportes.dominio`); P-05 |
| RF-14 | Más vendidos | Solo la administradora consulta las prendas más vendidas por sucursal y periodo | Automática: dominio ✔; permisos con BD omitidos | 🟡 Parcial | P-05 |
| RF-15 | Reporte de existencias | Se descarga en PDF y Excel; el gerente solo obtiene su sucursal | Automática: exportadores ✔; servicio omitido | 🟡 Parcial | P-05 |
| — | Foto de prenda | Solo JPG, PNG o WebP de hasta 5 MB, reconocidos por su contenido; no se puede salir de la carpeta de fotos | Automática (dominio y middleware) | ✅ Aceptada | `pruebas-api.txt` (`fotos.dominio`, `subirFoto.middleware`) |

## 5. Requerimientos no funcionales y reglas de negocio

| ID | Requerimiento | Criterio de aceptación | Tipo de prueba | Resultado | Evidencia |
|---|---|---|---|---|---|
| RNF-08 | Respaldo diario | `pg_dump` comprimido todos los días a las 10:00 p. m. en `./backups` | Revisión de configuración | 🟡 Parcial | `infra/backup/`, `docker-compose.yml`; P-06 |
| — | Existencia nunca negativa | Dos ventas simultáneas de la última pieza: una se rechaza | Diseño (`FOR UPDATE` + `CHECK`) | 🟡 Parcial | P-02 |
| — | Despliegue con Docker | `docker compose up -d --build` levanta PostgreSQL, Keycloak y API; `/health` responde `ok` | Manual | 🟡 Parcial | P-00 |
| — | Secretos fuera del repositorio | Solo se versiona `.env.example`; `.env` está en `.gitignore` | Revisión | ✅ Aceptada | `.gitignore` |
| — | Proceso GitFlow | Todo cambio entra a `develop` por Pull Request revisado por otra persona | Revisión del historial | ✅ Aceptada | PR #1 a #46 |

---

## Pruebas pendientes con el sistema completo

Se ejecutan con Docker, idealmente en la demostración con la dueña. Quien las corra marca el resultado y la fecha.

| ID | Pasos | Resultado esperado | Resultado | Fecha / quién |
|---|---|---|---|---|
| P-00 | `cp .env.example .env`, `docker compose up -d --build`, `curl http://localhost:3000/health` | `{"status":"ok","db":"ok"}` | | |
| P-01 | Llamar `GET /api/v1/usuarios` sin token y luego con el token de un empleado | 401 y luego 403 | | |
| P-02 | Con dos sesiones de empleado de la misma sucursal, vender al mismo tiempo la última pieza | Una venta da 201 y la otra 409; la existencia queda en 0 | | |
| P-03 | `cd api && npm test` con la base levantada | Las 115 pruebas pasan, 0 omitidas | | |
| P-04 | Solicitar un traspaso como empleado, aprobarlo como gerente del origen | El empleado ve el aviso; otro usuario no lo ve | | |
| P-05 | Como administradora descargar existencias, más vendidos y stock bajo en PDF y Excel; repetir como gerente | Los archivos abren; el gerente no puede pedir *más vendidos* (403) | | |
| P-06 | `docker compose exec backup sh /scripts/backup.sh` (o esperar a las 10:00 p. m.) | Aparece un `.sql.gz` en `./backups` que se puede restaurar | | |
| P-07 | Web con `VITE_USE_MOCK=false`: entrar con Keycloak, dar de alta una prenda y cargar un CSV | La prenda y las existencias aparecen en la app móvil | | |

## Aceptación de la dueña (Product Owner)

| Entrega | Fecha | Comentarios | Firma |
|---|---|---|---|
| `v0.1.0` · catálogo, carga inicial, búsqueda y ficha | | | |
