<!--
Documento de entrada para /speckit.specify.
No guardar este archivo dentro de la carpeta specs/ generada por Spec Kit.
-->

# Insumo de especificación - Sprint 2: Consulta de inventario, escáner y venta

> **Referencias obligatorias para el agente:**
>
> - Contexto maestro: `docs/project-context.md`
> - Constitución técnica: `docs/reglas.md`
> - Este documento describe únicamente el alcance del Sprint 2 de la app móvil (23 al 28 de noviembre de 2026).
> - Se construye sobre el Sprint 1 (`docs/sprint-1.md`). No se debe reimplementar el inicio de sesión, la estructura ni el tema.

## 1. Contexto

El Sprint 2 es el corazón de la app: permite que cualquier empleado responda en segundos si una prenda existe en alguna de las 5 sucursales, sin preguntar por WhatsApp, y que descuente piezas al vender. Aquí se integra la cámara para escanear las etiquetas.

Se parte de la base del Sprint 1. La app pasa del repositorio simulado a la API real para autenticación y consulta, conservando la posibilidad de volver a los datos simulados.

## 2. Objetivo

Entregar una app con la que un empleado busque prendas por varios criterios, escanee una etiqueta para abrir su ficha, vea la existencia en las 5 sucursales y descuente piezas vendidas de su propia sucursal.

## 3. Historias de usuario

### US-S2-01 — Búsqueda universal

Como empleado, quiero buscar prendas por nombre, talla, color o sucursal para saber rápidamente si hay existencia sin preguntar por WhatsApp.

### US-S2-02 — Ficha de prenda

Como empleado, quiero ver la fotografía, las características y la existencia de una prenda en las 5 sucursales para decirle al cliente dónde puede encontrarla.

### US-S2-03 — Escaneo de código de barras

Como empleado, quiero escanear con la cámara la etiqueta de una prenda para abrir su ficha al instante.

### US-S2-04 — Descuento de stock por venta

Como empleado, quiero descontar piezas de una prenda de mi sucursal cuando la vendo para mantener el inventario actualizado al momento.

### US-S2-05 — Consulta de existencia por sucursal

Como empleado, quiero filtrar la consulta por sucursal para revisar qué hay en una tienda específica.

## 4. Alcance funcional

### 4.1 Búsqueda universal

- Campo de búsqueda por nombre o descripción.
- Filtros por talla, color y sucursal.
- Resultados en lista con foto pequeña, nombre y existencia total o de la sucursal filtrada.
- Estados visibles: cargando, con resultados, sin resultados y error con botón de reintentar.
- Búsqueda tolerante a mayúsculas y a espacios sobrantes.
- Si el resultado es largo, se carga por páginas o en bloques.

### 4.2 Ficha de prenda

- Foto, nombre, descripción, marca, categoría y temporada.
- Matriz de existencias: por sucursal, con desglose por talla y color.
- La sucursal del usuario aparece destacada.
- Las existencias bajas o agotadas se distinguen visualmente, con ícono o texto además del color.
- Actualización al abrir la ficha y con gesto de "jalar para actualizar".
- Acciones desde la ficha: descontar piezas y, a partir del Sprint 3, solicitar traspaso (puede aparecer deshabilitada).

### 4.3 Escáner de códigos

- Pantalla de escáner con la cámara para códigos de barras y QR.
- Se usa a través de la interfaz propia `BarcodeScannerService` (patrón Adapter).
- El permiso de cámara se solicita al abrir el escáner, con una explicación breve.
- Si el permiso se niega, se ofrece la búsqueda manual por código.
- Al leer un código válido se abre la ficha de la prenda.
- Un código desconocido muestra "prenda no encontrada" y permite escanear otra vez.
- Evita lecturas duplicadas del mismo código en cada fotograma.
- Linterna opcional para tiendas con poca luz, si la librería lo permite.

### 4.4 Descuento de stock

- Desde la ficha, el empleado elige talla y color, indica la cantidad y confirma.
- La cantidad debe ser un entero positivo; la app no deja enviar valores inválidos.
- Solo se puede descontar de la sucursal del usuario.
- Se pide confirmación antes de enviar, mostrando prenda, talla, color y cantidad.
- Si la API acepta la operación, se muestra la nueva existencia.
- Si la existencia es insuficiente, se muestra un mensaje claro con la existencia actual y no se modifica nada.
- El botón se deshabilita mientras la operación está en curso para evitar el doble envío.
- Solo se descuentan piezas; no se capturan precios.

### 4.5 Navegación

- La pantalla principal ofrece accesos a "Buscar" y "Escanear".
- Desde el escáner o la búsqueda se llega a la ficha y de ahí al descuento.

### 4.6 Repositorios

- Interfaces `PrendaRepository` e `InventarioRepository` con implementación real y simulada.
- Los datos simulados incluyen prendas de varias sucursales, tallas y colores, y casos de existencia baja y agotada.

## 5. Roles y permisos del Sprint 2

| Acción | Empleado | Gerente |
|---|---|---|
| Buscar y consultar las 5 sucursales | Sí | Sí |
| Escanear y ver la ficha | Sí | Sí |
| Descontar stock de su sucursal | Sí | Sí |
| Descontar stock de otra sucursal | No | No |
| Dar de alta o editar prendas | No | Pendiente de confirmar (ver contexto, sección 10) |

## 6. Reglas de negocio

- Todos los usuarios consultan las 5 sucursales.
- Solo se descuenta stock de la sucursal del usuario autenticado; la app la toma de la sesión, no de un campo editable.
- La existencia nunca puede quedar negativa; la regla la aplica la API.
- Un cambio de inventario debe verse de inmediato en las demás sucursales.
- La app muestra existencias en piezas; no maneja precios.
- La venta se confirma con la existencia que devuelve la API, no con un cálculo local.

## 7. Criterios de aceptación

### Búsqueda

- Buscar por nombre devuelve las prendas coincidentes.
- Los filtros de talla, color y sucursal se pueden combinar.
- Sin resultados se muestra un mensaje claro.
- Un error de red muestra un aviso y permite reintentar.

### Ficha

- Se ven foto, características y existencia en las 5 sucursales.
- La sucursal del usuario está destacada.
- Una existencia de cero se distingue como agotada.
- Jalar para actualizar vuelve a pedir los datos.

### Escáner

- Escanear un código existente abre la ficha correcta.
- Un código desconocido muestra el aviso y no se cierra el escáner.
- Si se niega el permiso, se ofrece la búsqueda manual.
- Un mismo código mantenido frente a la cámara abre una sola ficha.

### Descuento

- Descontar una cantidad válida actualiza la existencia mostrada.
- Pedir más piezas de las existentes muestra el mensaje de existencia insuficiente.
- Cantidad cero, negativa o vacía no se puede enviar.
- No se puede descontar de otra sucursal.
- Un doble toque no genera dos descuentos.

### Roles y sesión

- Una respuesta 401 devuelve al inicio de sesión.
- Una respuesta 403 muestra un aviso de falta de permisos.

### Pruebas

- Los ViewModels de búsqueda, ficha y venta se prueban con repositorios simulados.
- Se prueba la validación de cantidades y el manejo de existencia insuficiente.
- Se prueba la app en al menos un dispositivo Android físico, incluida la cámara.

## 8. Entidades principales

- **Prenda:** identificador, código de barras, nombre o descripción, marca, categoría, temporada y foto.
- **Inventario por sucursal:** prenda, sucursal, talla, color y cantidad.
- **Sucursal:** identificador y nombre.
- **Venta (descuento):** prenda, talla, color, cantidad y sucursal.

## 9. Entregables

- Búsqueda con filtros.
- Ficha de prenda con la matriz de existencias.
- Escáner de códigos con permiso de cámara y manejo de errores.
- Descuento de stock con confirmación y validaciones.
- Repositorios reales y simulados.
- Pruebas de los ViewModels.
- APK instalable para la dueña.
- Evidencia para la bitácora: capturas de búsqueda, ficha, escáner y venta.
- Etiqueta de versión `v0.2.0` al cerrar el sprint, coordinada con el Integrante 4.

## 10. Dependencias con otros integrantes

| Necesita | De quién | Mientras tanto |
|---|---|---|
| Endpoints de búsqueda de prendas, consulta de inventario por sucursal y descuento por venta, en `docs/openapi.yaml` | Integrante 1 | Repositorios simulados |
| Datos de inventario cargados (carga inicial) | Integrante 1 y gerentes | Datos de ejemplo |
| Token con rol y sucursal del usuario | Integrante 2 | Sesión simulada |
| Imágenes de las prendas accesibles por URL | Integrante 1 | Imagen de marcador de posición |

## 11. Fuera de alcance

- Traspasos y su solicitud (Sprint 3).
- Notificaciones (Sprint 3 y 4).
- Alta, edición y baja de prendas desde el móvil.
- Precios y descuentos comerciales.
- Alertas de stock bajo y reportes: son de la web.
- Modo sin conexión y caché de inventario.

## 12. Cierre del sprint

El Sprint 2 se considera cerrado cuando un empleado puede buscar, escanear, ver la ficha y descontar piezas con la API (o con los datos simulados si la API aún no está lista), las pruebas pasan, el APK fue probado en un dispositivo físico con cámara y la evidencia está en la bitácora.
