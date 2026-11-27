# Bitácora — Sprint 2 (app móvil CheckLizz)

**Integrante:** 3 — Frontend móvil y escaneo (Flutter)
**Sprint:** 2, "Consulta de inventario, escáner y venta" (23 al 28 de noviembre de 2026)
**Fecha de esta entrada:** 27 de noviembre de 2026 (avance casi completo)
**Ramas:** `feature/mobile-busqueda-escaner-venta` (fusionada en `develop`, [PR #46](https://github.com/RocioCastillo25/ModaDeLiz/pull/46)) y `feature/mobile-venta-escaner` (venta, escáner y navegación, subida a GitHub; pendiente su Pull Request)
**Evidencia en el repositorio:** `docs/evidencia/sprint-2/` (esta bitácora, resultados de pruebas y capturas)

## Resumen

El Sprint 2 de la app móvil está **casi completo: 53 de 58 tareas (91 %)**. Un empleado ya puede **buscar prendas con filtros, abrir su ficha con la existencia de las 5 sucursales, escanear una etiqueta y descontar piezas vendidas de su sucursal**. Todo está probado en un teléfono Android con datos de ejemplo. Hay **249 pruebas automáticas en verde**, análisis sin avisos y **86,4 % de cobertura de líneas**.

El primer tramo (búsqueda, ficha y renovación de sesión) se fusionó en `develop` con la aprobación de otra persona (PR #46). El segundo tramo (venta, escáner y navegación) está subido a la rama `feature/mobile-venta-escaner`. Falta la prueba contra los servicios reales (Keycloak y API), la lectura de un código físico con la cámara, la entrega del APK a la dueña y la etiqueta `v0.2.0`.

## 1. Objetivo del sprint

Que un empleado busque prendas por varios criterios, escanee una etiqueta para abrir su ficha, vea la existencia en las 5 sucursales y descuente piezas vendidas de su propia sucursal.

## 2. Actividades de la semana

| Fecha | Actividad | Resultado |
|---|---|---|
| Hasta el 25 de nov | Seguimiento del repositorio: el Pull Request #1 (Sprint 1) y el #5 (acceso con Keycloak) quedaron fusionados en `develop`; el Integrante 2 fusionó la infraestructura de Keycloak (#6) | Contrato real y Keycloak disponibles para la app |
| 26 de nov | Revisión del estado del proyecto frente al plan del equipo (qué toca a cada integrante esta semana) | Hallazgo: la API ya tiene todos los endpoints del Sprint 2; faltaba hacer la app |
| 26 de nov | Actualización de la copia local con `develop` (45 commits nuevos) y creación de la rama del Sprint 2 | Rama lista, sin seguimiento a `develop` para no subir ahí por error |
| 26 de nov | **Especificación** (`/speckit.specify`) | 5 historias de usuario, 32 requisitos funcionales, 8 criterios de éxito y casos límite |
| 26 de nov | **Aclaraciones** (`/speckit.clarify`) | 2 decisiones: botón de traspaso deshabilitado hasta el Sprint 3; renovación automática de la sesión |
| 26 de nov | **Plan** (`/speckit.plan`) | Investigación (12 decisiones), modelo de datos, contratos, guía de validación; constitución sin violaciones |
| 26 de nov | **Tareas** (`/speckit.tasks`) | 58 tareas por historia de usuario |
| 26 de nov | Subida de la documentación a GitHub | 3 commits en la rama de la funcionalidad |
| 26 de nov | **Preparación y fundamentos** | Paquete `mobile_scanner`, permisos de cámara, modelos, repositorios reales y simulados, servicio de catálogo |
| 26 de nov | **Renovación de sesión** con el token de renovación de Keycloak | Una sola renovación compartida entre peticiones simultáneas y repetición única de la petición |
| 26 de nov | **Búsqueda con filtros** (historia 1) y **ficha de prenda** (historia 2) | Texto, talla, color y sucursal; matriz de existencias con la sucursal propia destacada |
| 26 de nov | Pruebas y primera evidencia | 191 pruebas, cobertura 85,2 % |
| 26 de nov | Pull Request #46 (búsqueda, ficha y renovación de sesión) | Aprobado y fusionado en `develop` |
| 27 de nov | Instalación del APK en el teléfono, pruebas y capturas de búsqueda y ficha | 8 capturas |
| 27 de nov | **Descuento de piezas por venta** (historia 4) | Confirmación, validación, doble envío bloqueado, manejo del 409 y existencia actualizada |
| 27 de nov | **Escáner de códigos** (historia 3) | Explicación antes del permiso, lectura con cámara, código desconocido, permiso negado y búsqueda manual |
| 27 de nov | **Navegación** (historia 5) | Accesos desde la pantalla principal, ficha precargada desde el escáner y aviso de permisos (403) |
| 27 de nov | Códigos de barras de ejemplo en EAN-13 válido y página `codigos-de-prueba.html` | La cámara lee códigos válidos |
| 27 de nov | Pruebas en el teléfono de la venta y del escáner | 14 capturas nuevas |
| 27 de nov | Subida de los commits a la rama `feature/mobile-venta-escaner` | 3 commits |

## 3. Avance

**53 de 58 tareas completadas (91 %).**

| Fase | Hechas | Total |
|---|---|---|
| Preparación | 3 | 3 |
| Fundamentos | 21 | 21 |
| US1 — Buscar prendas con filtros | 5 | 5 |
| US2 — Ficha de prenda | 5 | 5 |
| US4 — Descontar piezas vendidas | 5 | 5 |
| US3 — Escáner de códigos | 6 | 6 |
| US5 — Navegación | 4 | 4 |
| Pulido y entrega | 4 | 9 |

Todas las historias tienen código, pruebas automáticas y validación en el teléfono con datos de ejemplo.

### Código nuevo (`mobile/`)
- **Datos:** modelos `Prenda`, `PrendaFicha`, `StockItem` y `SearchFilters`; DTO que convierten el contrato de la API; `CatalogService`; tres repositorios (prendas, ventas y sucursales) con versión real y simulada.
- **Sesión:** renovación automática de la sesión en el interceptor de red; la sesión guardada incluye el token de renovación.
- **Búsqueda y ficha:** `BusquedaView` con su hoja de filtros, `FichaView` con `MatrizExistencias`, y los widgets compartidos `StockBadge` y `PrendaImage`.
- **Venta:** `VentaViewModel` y `VentaSheet`. Solo ofrece las existencias de la sucursal del usuario; no envía la sucursal; valida un entero positivo; avisa (sin bloquear) si se pide más de lo que se ve; ante un 409 consulta la existencia vigente y la informa.
- **Escáner:** `BarcodeScannerService` (interfaz propia) con `MobileScannerService` como único archivo que usa la librería de la cámara; `EscanerViewModel` y `EscanerView`.
- **Navegación:** la pantalla principal abre la búsqueda y el escáner; si la sesión termina, se cierran las pantallas abiertas.
- **Datos de ejemplo:** 6 prendas, 5 sucursales, casos de existencia baja y agotada, códigos EAN-13 válidos.

## 4. Pruebas

| Verificación | Resultado |
|---|---|
| `flutter analyze` | Sin avisos |
| `flutter test` | **249 pruebas aprobadas, 0 fallidas** (el Sprint 1 cerró con 96: 153 nuevas) |
| Cobertura de líneas | **86,4 %** (1862 de 2154) |
| Cobertura de los ViewModels | Búsqueda 97,4 %, ficha 90,3 %, venta 98,2 %, escáner 97,2 %, sesión 97,8 %, pantalla principal 100 % |
| Compilación del APK | Correcta (versión de depuración con datos de ejemplo y el escáner) |
| Dispositivo | Teléfono Android RMX3890 (Android 15): inicio de sesión, búsqueda, filtros, ficha, venta y escáner validados (ver capturas) |

### Escenarios validados en el teléfono

| # | Escenario | Resultado | Captura |
|---|---|---|---|
| 1 | Pantalla principal con acceso a "Buscar prendas" y "Escanear código" | Aprobado | `00b-pantalla-principal-escaner.png` |
| 2 | Búsqueda con resultados y existencia (incluye una prenda agotada) | Aprobado | `01-busqueda.png` |
| 3 | Filtros de talla, color y sucursal combinados | Aprobado | `02`, `03` y `04` |
| 4 | Búsqueda sin resultados | Aprobado | `05-sin-resultados.png` |
| 5 | Ficha con matriz de existencias, "Tu sucursal" destacada, existencia baja y agotada, y traspaso deshabilitado | Aprobado | `06` y `07` |
| 6 | Hoja de venta solo con las existencias de la sucursal propia | Aprobado | `09-venta-hoja.png` |
| 7 | Pedir más piezas de las que hay: aviso "Solo hay 5 piezas." y, al confirmar, "Solo quedan 5 piezas. No se descontó nada." | Aprobado | `10`, `11` y `12` |
| 8 | Venta válida de 2 piezas: confirmación, "Venta registrada", y la ficha muestra 3 piezas en Zacatlán | Aprobado | `13`, `14` y `15` |
| 9 | Escáner: explicación antes de pedir la cámara | Aprobado | `16-escaner-explicacion.png` |
| 10 | Escáner con la cámara activa (vista previa y guía de lectura) | Aprobado | `17-escaner-camara-activa.jpg` |
| 11 | Código inexistente: "Prenda no encontrada" y se puede escanear otra vez | Aprobado | `18-escaner-prenda-no-encontrada.png` |
| 12 | Búsqueda manual por código abre la ficha correcta | Aprobado | `19-escaner-ficha-por-codigo.png` |
| 13 | Solicitud de permiso de cámara del sistema | Aprobado | `20-escaner-permiso-camara-sistema.png` |
| 14 | Permiso negado: aviso y búsqueda manual por código | Aprobado | `21` y `22` |
| 15 | Lectura de un código de barras físico o en pantalla con la cámara | Pendiente (hay que apuntar la cámara a `codigos-de-prueba.html`) | — |

### APK de prueba

| Dato | Valor |
|---|---|
| Archivo | `app-debug.apk` (222,9 MB, depuración, datos de ejemplo) |
| SHA-256 | `FE843B5045B8DFB600A3941468818895CB9C65C95CCB150920A6DCB33B1AD325` |
| Compilación | Correcta (la primera compilación con el paquete del escáner tarda unos 20 minutos) |
| Instalación | Correcta en el teléfono Android RMX3890 (Android 15) |
| Entrega | Se entrega por separado; no se sube al repositorio por su tamaño |

Las pruebas automáticas cubren: búsqueda y filtros, carga por bloques, ficha y existencia propia, validación de la cantidad (vacía, cero, negativa, decimal y texto), venta aceptada, doble toque, sin conexión, 403, 409 con existencia vigente, escáner (explicación, código registrado, código repetido, desconocido, permiso negado y búsqueda manual), renovación de sesión (una sola renovación para varias peticiones, repetición única y venta sin doble descuento) y recorridos completos de pantalla. Detalle en `pruebas-flutter.txt`, `analisis-flutter.txt` y `cobertura-resumen.txt`.

## 5. Problemas encontrados y cómo se resolvieron

| Problema | Solución |
|---|---|
| La fila "Total en las sucursales" de la ficha y el botón de traspaso se desbordaban (los detectaron las pruebas) | Se cambiaron a diseños que bajan de línea o recortan el texto |
| La capa de servicios del catálogo tenía solo 3,9 % de cobertura | Se escribieron 18 pruebas del servicio y de los repositorios reales |
| Los códigos de barras de ejemplo no eran EAN-13 válidos, así que la cámara no los habría leído | Se recalcularon con su dígito verificador y se creó `codigos-de-prueba.html` para probarlos |
| La regla "no duplicar la regla de la existencia" chocaba con bloquear cantidades mayores a las que se ven (la existencia mostrada puede estar desactualizada) | La app avisa sin bloquear; la API decide y, ante el 409, se informa la existencia vigente |
| La compilación del APK con el paquete del escáner tarda más de 20 minutos | Se ejecuta en segundo plano |
| El teléfono aparecía solo como dispositivo de archivos | Se activó la depuración USB |
| Un color suelto (`Color(0x66000000)`) en la pantalla del escáner contradecía la regla de usar solo el tema | Se movió a `AppColors.scrim` |
| Una captura del teléfono salió con el panel de notificaciones desplegado (mostraba datos personales) | Se descartó, se repitió con la app al frente y se revisaron una por una todas las capturas antes de subirlas |
| Un error de comillas en un commit hizo que los archivos del escáner quedaran dentro del commit de la navegación | Sin pérdida: están subidos; el mensaje del commit solo menciona la conexión |

## 6. Decisiones tomadas

1. El botón "Solicitar traspaso" aparece deshabilitado con la leyenda "Próximamente"; la solicitud completa es del Sprint 3.
2. La sesión se renueva sola con el token de renovación de Keycloak; si no se puede renovar, se vuelve al inicio de sesión. Esto sustituye lo decidido en el Sprint 1.
3. Un único paquete nuevo: `mobile_scanner`, detrás de la interfaz propia `BarcodeScannerService`.
4. Los filtros de talla y color son campos de texto, porque la API no tiene un catálogo de tallas ni de colores.
5. La API entrega la lista completa; la app la muestra por bloques de 20.
6. Ante un 409 por existencia insuficiente, la app recarga la ficha para mostrar la existencia vigente.
7. Pedir más piezas de las que se ven solo avisa; la API decide.
8. La navegación sigue con `Navigator`.
9. El escáner usa la cámara real también en modo de ejemplo; los códigos de ejemplo son EAN-13 válidos.

## 7. Pendientes para cerrar el sprint

- [ ] Leer con la cámara un código de `codigos-de-prueba.html` (escenario 15).
- [ ] Probar contra Keycloak y la API reales, con los Integrantes 1 y 2 (tarea T054): búsqueda, ficha, escáner, venta, renovación de sesión y 403.
- [ ] Actualizar el contrato y la investigación con lo que resulte de esa prueba (T055).
- [ ] Entregar el APK a la dueña y que lo pruebe (T057).
- [ ] Abrir el Pull Request de `feature/mobile-venta-escaner` a `develop` y conseguir la aprobación de otra persona (T058).
- [ ] Etiqueta `v0.2.0`, coordinada con el Integrante 4.
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

- **Prueba real pendiente:** nada se ha probado aún contra Keycloak y la API reales; es la mayor incertidumbre (formato de los errores, `refresh_token`, filtros).
- **Vigencia del token:** 5 minutos por defecto. La renovación automática lo cubre solo si Keycloak entrega el token de renovación.
- **Tiempo:** quedan la prueba real, la entrega del APK y la revisión del segundo Pull Request, que depende de otra persona.

## 10. Evidencia adjunta

| Archivo | Qué muestra |
|---|---|
| `pruebas-flutter.txt`, `analisis-flutter.txt`, `cobertura-resumen.txt` | Resultado de `flutter test` (249 pruebas), `flutter analyze` (sin avisos) y cobertura (86,4 %) |
| `00-pantalla-principal.png`, `00b-pantalla-principal-escaner.png` | Pantalla principal sin y con el acceso al escáner |
| `01-busqueda.png` a `05-sin-resultados.png` | Búsqueda, filtros y estado vacío |
| `06-ficha.png`, `07-ficha-matriz.png` | Ficha y matriz de existencias |
| `09-venta-hoja.png` a `15-ficha-existencia-actualizada.png` | Hoja de venta, aviso de cantidad, existencia insuficiente, confirmación, venta registrada y ficha actualizada |
| `16-escaner-explicacion.png` a `22-escaner-permiso-negado-busqueda-manual.png` | Explicación, cámara activa, prenda no encontrada, búsqueda manual y permiso de cámara |
| `codigos-de-prueba.html` | Página con códigos EAN-13 de las prendas de ejemplo para probar el escáner |
| `codigos-de-barras-prueba.docx` | Documento para imprimir con los 7 códigos EAN-13 de prueba (6 prendas de ejemplo y un código inexistente), con instrucciones de uso |
| Documentos de Spec Kit | `specs/002-busqueda-escaner-venta/` (especificación, plan, investigación, modelo de datos, contratos, guía y tareas) |
