<!--
Documento de entrada para /speckit.specify.
No guardar este archivo dentro de la carpeta specs/ generada por Spec Kit.
-->

# Insumo de especificación - Sprint 3: Traspasos y notificaciones

> **Referencias obligatorias para el agente:**
>
> - Contexto maestro: `docs/project-context.md`
> - Constitución técnica: `docs/reglas.md`
> - Este documento describe únicamente el alcance del Sprint 3 de la app móvil (30 de noviembre al 5 de diciembre de 2026).
> - Se construye sobre los Sprints 1 y 2. No se deben reimplementar la sesión, la búsqueda, la ficha, el escáner ni el descuento.

## 1. Contexto

Hoy los traspasos entre sucursales se acuerdan de palabra, sin registro. El Sprint 3 incorpora a la app el flujo de traspasos desde el lado del empleado: solicitar piezas de otra sucursal y seguir el estado de cada solicitud. La aprobación y el cambio de estados los hacen el administrador y los gerentes desde la página web; la app muestra el resultado y avisa al empleado.

## 2. Objetivo

Entregar una app con la que un empleado solicite un traspaso desde la ficha de una prenda, consulte el estado de sus solicitudes y reciba aviso cuando el estado cambie.

## 3. Historias de usuario

### US-S3-01 — Solicitud de traspaso

Como empleado, quiero solicitar a otra sucursal una o más piezas de una prenda para atender a un cliente que no encuentra su talla en mi tienda.

### US-S3-02 — Mis solicitudes

Como empleado, quiero ver la lista de mis solicitudes de traspaso y su estado para saber cuándo llegará la mercancía.

### US-S3-03 — Detalle de un traspaso

Como empleado, quiero ver el detalle de una solicitud (prenda, talla, color, cantidad, sucursal de origen y destino, estado e historial de cambios) para dar seguimiento.

### US-S3-04 — Notificaciones de estado

Como empleado, quiero recibir un aviso cuando mi solicitud sea aprobada, rechazada, enviada o recibida para enterarme sin tener que preguntar.

### US-S3-05 — Traspasos pendientes de mi sucursal

Como gerente, quiero ver los traspasos donde mi sucursal es origen o destino para estar al tanto de la mercancía que sale y llega. *(Sujeto a la decisión pendiente sobre el gerente en móvil; ver sección 10.)*

## 4. Alcance funcional

### 4.1 Solicitud de traspaso

- Se inicia desde la ficha de una prenda, con acción "Solicitar traspaso".
- El empleado elige la sucursal de origen entre las que tienen existencia de esa talla y color.
- Indica la cantidad (entero positivo).
- La app impide enviar cantidades menores o iguales a cero y avisa si supera la existencia visible del origen, pero la API es quien valida.
- No se puede pedir un traspaso a la propia sucursal.
- Se pide confirmación antes de enviar.
- Al enviar, el traspaso queda en estado `SOLICITADO`.
- Se evita el doble envío mientras la operación está en curso.
- Una solicitud puede incluir una o más piezas de la misma prenda; la combinación de varias prendas en una solicitud queda sujeta al contrato de la API.

### 4.2 Lista de mis solicitudes

- Muestra solo las solicitudes del usuario autenticado.
- Cada elemento indica prenda, cantidad, sucursal de origen, estado y fecha.
- Filtro por estado.
- Orden por fecha, de las más recientes a las más antiguas.
- Estados visibles: cargando, con datos, vacío y error con reintento.
- Actualización con el gesto de "jalar para actualizar".

### 4.3 Detalle del traspaso

- Datos completos de la solicitud y su estado actual.
- Historial de cambios de estado con fecha, si la API lo entrega.
- Estados: `SOLICITADO`, `APROBADO`, `RECHAZADO`, `EN_CAMINO` y `RECIBIDO`, cada uno con texto e ícono propios.
- Si fue rechazado y la API entrega un motivo, se muestra.
- La app solo muestra los estados; el cambio de estado lo hace la API a partir de acciones de la web.

### 4.4 Notificaciones

- Aviso al empleado cuando el estado de su solicitud cambia a `APROBADO`, `RECHAZADO`, `EN_CAMINO` o `RECIBIDO`.
- **Mecanismo por defecto:** avisos dentro de la app. Al abrir la app o al volver a primer plano se consulta si hay cambios, y se muestra un indicador con el número de avisos sin leer en el acceso a notificaciones.
- Centro de notificaciones con la lista de avisos, marcados como leídos o no leídos.
- Tocar un aviso abre el detalle del traspaso.
- Si se decide usar notificaciones push (por ejemplo, con un servicio externo), debe justificarse y documentarse durante la planeación, según `docs/reglas.md`.
- Un cambio de estado no debe generar avisos duplicados.

### 4.5 Traspasos de la sucursal (gerente)

- Para el rol de gerente, una lista de traspasos donde su sucursal sea origen o destino, con el estado de cada uno.
- Si se confirma que el gerente puede aprobar o rechazar desde la app, se agregan esas acciones; de lo contrario, la vista es de solo lectura y la aprobación se hace en la web.

### 4.6 Repositorios

- Interfaz `TraspasoRepository` con implementación real y simulada.
- Los datos simulados incluyen traspasos en cada uno de los 5 estados y cambios de estado que permiten probar las notificaciones.

## 5. Roles y permisos del Sprint 3

| Acción | Empleado | Gerente |
|---|---|---|
| Solicitar un traspaso | Sí | Sí |
| Ver sus propias solicitudes | Sí | Sí |
| Recibir avisos de sus solicitudes | Sí | Sí |
| Ver traspasos de su sucursal | No | Sí (pendiente de confirmar) |
| Aprobar o rechazar desde la app | No | Pendiente de confirmar |

## 6. Reglas de negocio

- Un traspaso no puede pedir más piezas de las que existen en la sucursal de origen; la API valida la regla.
- Un empleado solo ve sus propias solicitudes.
- Un traspaso a la propia sucursal no es válido.
- Los estados válidos son `SOLICITADO`, `APROBADO`, `RECHAZADO`, `EN_CAMINO` y `RECIBIDO`.
- El cambio de estado lo realiza la API; la app no lo modifica.
- El aviso de cambio de estado se genera una sola vez por cambio.
- El stock se mueve entre sucursales según la regla de la API; la app solo refleja el resultado.

## 7. Criterios de aceptación

### Solicitud

- Desde la ficha se puede solicitar un traspaso con sucursal de origen y cantidad válidas.
- Cantidad cero, negativa o vacía no se puede enviar.
- Pedir más de lo disponible muestra el mensaje de la API sin crear la solicitud.
- No se puede elegir la propia sucursal como origen.
- Un doble toque no crea dos solicitudes.
- Al enviar, la solicitud aparece en "Mis solicitudes" como `SOLICITADO`.

### Lista y detalle

- La lista muestra solo las solicitudes del usuario.
- El filtro por estado funciona.
- El detalle muestra todos los datos y el estado con texto e ícono.
- Un estado `RECHAZADO` muestra el motivo si existe.

### Notificaciones

- Cuando una solicitud cambia de estado, el empleado ve el aviso al abrir la app o volver a ella.
- El indicador muestra la cantidad de avisos sin leer.
- Tocar un aviso abre el detalle y lo marca como leído.
- Un mismo cambio no genera dos avisos.

### Roles y sesión

- Un empleado no ve solicitudes de otros empleados.
- Una respuesta 401 devuelve al inicio de sesión; una 403 muestra un aviso de falta de permisos.

### Pruebas

- Los ViewModels de traspasos y notificaciones se prueban con repositorios simulados.
- Se prueba la validación de cantidades, el filtro por estado y la no duplicación de avisos.
- Se prueba la app en al menos un dispositivo Android físico.

## 8. Entidades principales

- **Traspaso:** identificador, sucursal de origen, sucursal de destino, usuario que solicita, estado y fecha de solicitud.
- **Detalle de traspaso:** prenda, talla, color y cantidad.
- **Cambio de estado:** estado anterior, estado nuevo y fecha.
- **Notificación:** traspaso relacionado, mensaje, fecha y si fue leída.

## 9. Entregables

- Solicitud de traspaso desde la ficha de prenda.
- Lista y detalle de mis solicitudes con filtro por estado.
- Centro de notificaciones con indicador de avisos sin leer.
- Repositorio real y simulado de traspasos.
- Pruebas de los ViewModels.
- APK instalable para la dueña.
- Evidencia para la bitácora: capturas de la solicitud, la lista, el detalle y los avisos.
- Etiqueta de versión `v0.3.0` al cerrar el sprint, coordinada con el Integrante 4.

## 10. Dependencias y decisiones pendientes

| Necesita | De quién | Mientras tanto |
|---|---|---|
| Endpoints para crear y consultar traspasos, y para consultar cambios de estado, en `docs/openapi.yaml` | Integrante 1 | Repositorio simulado |
| Mesa de control de traspasos en la web (aprobar, rechazar, enviar y recibir) | Web, por asignar | Cambios de estado simulados |
| Regla de movimiento de stock al recibir | Integrante 1 | No aplica en la app |

### Decisiones pendientes (resolver con `/speckit.clarify`)

1. ¿El gerente aprueba o rechaza desde la app o solo desde la web?
2. ¿Notificaciones solo dentro de la app o también push?
3. ¿Una solicitud puede contener varias prendas o solo una?
4. ¿La API entrega el motivo del rechazo y el historial de estados?

## 11. Fuera de alcance

- Aprobar, enviar o marcar como recibido desde el empleado.
- Mesa de control de traspasos (es de la web).
- Notificaciones por correo o mensajes de texto.
- Precios y descuentos comerciales.
- Reportes y alertas de stock bajo.
- Modo sin conexión.

## 12. Cierre del sprint

El Sprint 3 se considera cerrado cuando un empleado puede solicitar un traspaso, ver el estado de sus solicitudes y recibir avisos de los cambios, con la API o con datos simulados si aún no está lista, las pruebas pasan, el APK fue probado en un dispositivo físico y la evidencia está en la bitácora.
