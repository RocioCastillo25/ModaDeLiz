# Bitácora — Sprint 2 (app móvil CheckLizz)

**Integrante:** 3 — Frontend móvil y escaneo (Flutter)
**Sprint:** 2, "Consulta de inventario, escáner y venta" (23 al 28 de noviembre de 2026)
**Fecha de esta entrada:** 26 de noviembre de 2026 (avance parcial, a mitad del sprint)
**Rama:** `feature/mobile-busqueda-escaner-venta` (documentación subida; el código sigue en la copia local, sin commit)
**Evidencia en el repositorio:** `docs/evidencia/sprint-2/` (esta bitácora y los resultados de pruebas)

## Resumen

A mitad del sprint están terminados el proceso de Spec Kit completo (especificación, aclaraciones, plan y 58 tareas) y la base técnica, la **búsqueda con filtros** y la **ficha de prenda** con la existencia de las 5 sucursales. Son **34 de 58 tareas (59 %)**, con **191 pruebas automáticas en verde**, análisis sin avisos y **85,2 % de cobertura de líneas**. Falta el descuento por venta, el escáner con cámara y la navegación final, además de la prueba en el teléfono y la prueba contra los servicios reales. El código es el primer tramo (MVP) del primer Pull Request del sprint.

## 1. Objetivo del sprint

Que un empleado busque prendas por varios criterios, escanee una etiqueta para abrir su ficha, vea la existencia en las 5 sucursales y descuente piezas vendidas de su propia sucursal.

## 2. Actividades de la semana

| Fecha | Actividad | Resultado |
|---|---|---|
| Hasta el 25 de nov | Seguimiento del repositorio: el Pull Request #1 (Sprint 1) y el #5 (acceso con Keycloak) quedaron fusionados en `develop`; el Integrante 2 fusionó la infraestructura de Keycloak (#6) | Contrato real y Keycloak disponibles para la app |
| 26 de nov | Revisión del estado del proyecto frente al plan del equipo (qué toca a cada integrante esta semana) | Hallazgo: la API ya tiene todos los endpoints del Sprint 2; faltaba hacer la app |
| 26 de nov | Actualización de la copia local con `develop` (45 commits nuevos) y creación de la rama `feature/mobile-busqueda-escaner-venta` | Rama lista, sin seguimiento a `develop` para no subir ahí por error |
| 26 de nov | **Especificación** (`/speckit.specify`) | 5 historias de usuario, 32 requisitos funcionales, 8 criterios de éxito y casos límite |
| 26 de nov | **Aclaraciones** (`/speckit.clarify`) | 2 decisiones: botón de traspaso deshabilitado hasta el Sprint 3; renovación automática de la sesión |
| 26 de nov | **Plan** (`/speckit.plan`) | Investigación (12 decisiones), modelo de datos, contratos, guía de validación; revisión de la constitución sin violaciones |
| 26 de nov | **Tareas** (`/speckit.tasks`) | 58 tareas por historia de usuario |
| 26 de nov | Subida de la documentación a GitHub | 3 commits en la rama de la funcionalidad |
| 26 de nov | **Implementación**: preparación y fundamentos | Paquete `mobile_scanner`, permisos de cámara, modelos, repositorios reales y simulados, servicio de catálogo |
| 26 de nov | **Renovación de sesión** con el token de renovación de Keycloak | Una sola renovación compartida entre peticiones simultáneas y repetición única de la petición |
| 26 de nov | **Búsqueda con filtros** (historia 1) | Texto, talla, color y sucursal; listas por bloques; estados de carga, vacío y error |
| 26 de nov | **Ficha de prenda** (historia 2) | Foto, datos, matriz de existencias, sucursal propia destacada, agotado y bajo con ícono y texto, jalar para actualizar |
| 26 de nov | Pantalla principal con acceso a la búsqueda y cierre automático de pantallas al terminar la sesión | Navegación base |
| 26 de nov | **Pruebas** y evidencia | 191 pruebas, cobertura 85,2 % (ver sección 4) |

## 3. Avance

**34 de 58 tareas completadas (59 %).**

| Fase | Hechas | Total |
|---|---|---|
| Preparación | 3 | 3 |
| Fundamentos | 21 | 21 |
| US1 — Buscar prendas con filtros | 5 | 5 |
| US2 — Ficha de prenda | 5 | 5 |
| US4 — Descontar piezas vendidas | 0 | 5 |
| US3 — Escáner de códigos | 0 | 6 |
| US5 — Navegación | 0 | 4 |
| Pulido y entrega | 0 | 9 |

Las historias 1 y 2 tienen código y pruebas automáticas terminados. Todavía no están validadas en el teléfono ni contra el sistema real (ver sección 7).

### Código nuevo (`mobile/`)
- **Datos:** modelos `Prenda`, `PrendaFicha`, `StockItem` y `SearchFilters`; DTO que convierten el contrato de la API; `CatalogService`; tres repositorios (prendas, ventas y sucursales) con versión real y simulada.
- **Sesión:** renovación automática de la sesión en el interceptor de red; la sesión guardada incluye el token de renovación; una sesión guardada por el Sprint 1 se sigue leyendo sin error.
- **Pantallas:** `BusquedaView` con su hoja de filtros, `FichaView` con `MatrizExistencias`, y los widgets compartidos `StockBadge` y `PrendaImage`.
- **Navegación:** la pantalla principal abre la búsqueda; la búsqueda abre la ficha; si la sesión termina, se cierran las pantallas abiertas.
- **Datos de ejemplo:** 6 prendas, 5 sucursales, casos de existencia baja y agotada, y venta que descuenta en memoria.

## 4. Pruebas

| Verificación | Resultado |
|---|---|
| `flutter analyze` | Sin avisos |
| `flutter test` | **191 pruebas aprobadas, 0 fallidas** (el Sprint 1 cerró con 96) |
| Cobertura de líneas | **85,2 %** (1402 de 1645) |
| Cobertura de los ViewModels | Búsqueda 97,4 %, ficha 89,1 %, sesión 97,8 %, pantalla principal 100 % |
| Compilación del APK | Correcta (versión de depuración con datos de ejemplo, con el paquete del escáner) |
| Dispositivo | Pendiente (ver sección 7) |

### APK de prueba (avance del sprint)

| Dato | Valor |
|---|---|
| Archivo | `app-debug.apk` (222,8 MB, depuración, datos de ejemplo) |
| SHA-256 | `F3730318E9EED55419293F0073D0C7E69C89531FE4F5A81F0F1A2DE02510AF8D` |
| Compilación | 23 minutos la primera vez, por el paquete del escáner |
| Instalación | Pendiente: el teléfono todavía no está en modo de depuración USB |

Pruebas nuevas del sprint (95): ViewModels de búsqueda (15) y ficha (14), modelos y DTO (16), servicio y repositorios reales del catálogo (18), renovación de sesión en el repositorio (9) y en el interceptor (9), sesión con token de renovación (6), registro de dependencias (3), pantalla principal (2) y recorrido de pantallas (3).

Lo que cubren:
- **Búsqueda:** resultados, vacío, error con reintento, texto con mayúsculas y espacios, filtros combinados, existencia por sucursal, carga por bloques de 20, una respuesta lenta que no pisa a una más reciente y espera al escribir.
- **Ficha:** carga por identificador y por código, código desconocido, error y reintento, conservar datos si falla al actualizar, sucursal propia del empleado y del gerente, y estados agotado, bajo y disponible.
- **Red y contrato:** solo se envían los filtros con valor, el código de barras se codifica, la venta envía solo el inventario y la cantidad (nunca la sucursal), y los errores 404, 409, 403, 400, sin conexión y 5xx se traducen sin mostrar detalles técnicos.
- **Renovación de sesión:** repite la petición una sola vez, comparte una renovación entre varias peticiones, no renueva si ya falló una vez, un fallo de conexión no cierra la sesión, y una venta interrumpida por sesión vencida no se descuenta dos veces.
- **Pantallas:** buscar y abrir la ficha, búsqueda sin resultados y cierre de pantallas al terminar la sesión.

Detalle en `pruebas-flutter.txt`, `analisis-flutter.txt` y `cobertura-resumen.txt`.

## 5. Problemas encontrados y cómo se resolvieron

| Problema | Solución |
|---|---|
| La fila "Total en las sucursales" de la ficha se desbordaba (lo detectó una prueba) | Se cambió a un diseño que baja de línea cuando no cabe |
| El botón de traspaso deshabilitado se desbordaba en pantallas angostas (lo detectó una prueba) | La leyenda "Próximamente" pasó a una segunda línea y el texto se recorta con puntos suspensivos |
| La capa de servicios del catálogo tenía solo 3,9 % de cobertura | Se escribieron 18 pruebas del servicio y de los repositorios reales; subió a 54,9 % |
| La primera compilación del APK con el paquete del escáner tarda más de 10 minutos | Se ejecuta en segundo plano |
| El teléfono (realme C67) aparece como dispositivo de archivos pero no como dispositivo de depuración | Hay que activar la depuración USB y aceptar el aviso en el teléfono |
| El directorio generado `mobile/android/.kotlin/` aparece sin seguimiento | No se sube; conviene agregarlo a `.gitignore` |

## 6. Decisiones tomadas

1. El botón "Solicitar traspaso" aparece deshabilitado con la leyenda "Próximamente" en este sprint; la solicitud completa es del Sprint 3.
2. La sesión se renueva sola con el token de renovación de Keycloak; si no se puede renovar, se vuelve al inicio de sesión. Esto sustituye lo decidido en el Sprint 1.
3. Un único paquete nuevo: `mobile_scanner`, detrás de la interfaz propia `BarcodeScannerService`.
4. Los filtros de talla y color son campos de texto, porque la API no tiene un catálogo de tallas ni de colores.
5. La API entrega la lista completa; la app la muestra por bloques de 20.
6. Ante un 409 por existencia insuficiente, la app recarga la ficha para mostrar la existencia vigente.
7. La navegación sigue con `Navigator`; no hace falta un paquete de rutas con 4 destinos.

## 7. Pendientes para cerrar el sprint

- [ ] Descuento de piezas por venta con confirmación y manejo del 409 (historia 4, 5 tareas).
- [ ] Escáner con cámara y búsqueda manual por código (historia 3, 6 tareas).
- [ ] Accesos finales y manejo del 403 en las pantallas nuevas (historia 5, 4 tareas).
- [ ] Probar en el teléfono (necesita depuración USB activada) y tomar las capturas de búsqueda, ficha, escáner y venta.
- [ ] Probar contra Keycloak y la API reales, junto con los Integrantes 1 y 2.
- [ ] APK de prueba para la dueña, probado en un teléfono con cámara.
- [ ] Commit del código, Pull Request a `develop` con la aprobación de otra persona y etiqueta `v0.2.0` con el Integrante 4.
- [ ] Restos del Sprint 1: escenario de sesión vencida en el teléfono y etiqueta `v0.1.0`.

## 8. Dependencias con otros integrantes

| Necesito | De | Estado |
|---|---|---|
| Que el realm entregue `refresh_token` al cliente `checklizz-app` y su vigencia | Integrante 2 | Por confirmar en la prueba real. Si no lo entrega, al vencer el token se vuelve al inicio de sesión |
| Confirmar si `q`, `talla` y `color` ignoran mayúsculas y acentos | Integrante 1 | Por confirmar |
| Confirmar si `existencia_total` respeta el filtro `sucursalId` | Integrante 1 | Por confirmar; si no, la lista muestra la existencia total |
| Fotos (`foto_url`) accesibles desde el teléfono | Integrante 1 | Por confirmar; mientras tanto se muestra una imagen de marcador de posición |
| Servicios encendidos (Keycloak, API y base de datos) para la prueba real | Integrante 2 | Pendiente de coordinar |
| Etiqueta `v0.2.0` | Integrante 4 | Pendiente |

## 9. Riesgos

- **Tiempo:** el plan del equipo pide tener las funciones subidas el miércoles por la noche. Faltan la venta y el escáner (11 tareas) y las validaciones en el teléfono. Se priorizó la búsqueda y la ficha, que son la base de todo lo demás.
- **Vigencia del token:** 5 minutos por defecto. La renovación automática lo cubre solo si Keycloak entrega el token de renovación.
- **Cámara:** el escáner solo se prueba bien en un teléfono físico, y el teléfono todavía no está en modo depuración.
- **Compilación lenta** del APK con el paquete del escáner en esta computadora.

## 10. Evidencia adjunta

| Archivo | Qué muestra | Estado |
|---|---|---|
| `pruebas-flutter.txt` | Resultado de `flutter test` (191 pruebas) | Listo |
| `analisis-flutter.txt` | Resultado de `flutter analyze` (sin avisos) | Listo |
| `cobertura-resumen.txt` | Cobertura de líneas por carpeta (85,2 %) | Listo |
| `01-busqueda.png` | Búsqueda con resultados y existencia | Pendiente (teléfono) |
| `02-filtros.png` | Hoja de filtros de talla, color y sucursal | Pendiente (teléfono) |
| `03-ficha-matriz.png` | Ficha con la matriz de existencias y la sucursal propia destacada | Pendiente (teléfono) |
| `04-existencia-baja-agotada.png` | Existencia baja y agotada con ícono y texto | Pendiente (teléfono) |
| `05-sin-resultados.png` | Búsqueda sin resultados | Pendiente (teléfono) |
| Documentos de Spec Kit | `specs/002-busqueda-escaner-venta/` (especificación, plan, investigación, modelo de datos, contratos, guía y tareas) | Listo, subido a la rama |
