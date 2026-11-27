# Especificación de la funcionalidad: Consulta de inventario, escáner y venta

**Rama de la funcionalidad**: `002-busqueda-escaner-venta`

**Creado**: 2026-11-26

**Estado**: Borrador

**Entrada**: Descripción del usuario: "Sprint 2 de la app móvil: búsqueda de prendas, ficha con existencias en las 5 sucursales, escáner de códigos y descuento de piezas por venta", con apoyo en `docs/sprint-2.md` y en el contrato real de `docs/openapi.yaml` de `develop`.

## Aclaraciones

### Sesión 2026-11-26

- Q: ¿La solicitud de traspaso desde la ficha entra en el Sprint 2 o solo se deja el botón deshabilitado hasta el Sprint 3? → A: Solo el botón "Solicitar traspaso" deshabilitado, con la leyenda "Próximamente"; la solicitud completa se hace en el Sprint 3.
- Q: ¿Qué debe pasar cuando la sesión vence (el token dura 5 minutos por defecto)? → A: La app renueva la sesión sola con el `refresh_token` de Keycloak; si no se puede renovar, vuelve al inicio de sesión con un aviso. Esto sustituye lo decidido en el Sprint 1 (volver directo al inicio de sesión).

## Escenarios de usuario y pruebas *(obligatorio)*

### Historia de usuario 1 - Buscar prendas con filtros (Prioridad: P1)

Como empleado, quiero buscar prendas por nombre, talla, color o sucursal para saber en segundos si hay existencia, sin preguntar por WhatsApp con el cliente enfrente.

**Por qué esta prioridad**: Es la consulta más frecuente del piso de venta y la puerta de entrada a la ficha y a la venta. Sin ella la app no resuelve el problema central del proyecto.

**Prueba independiente**: Iniciar sesión, abrir "Buscar", escribir parte de un nombre, aplicar filtros de talla, color y sucursal, y comprobar que la lista muestra solo las prendas coincidentes con su existencia.

**Escenarios de aceptación**:

1. **Dado** que el empleado está en la pantalla principal, **Cuando** abre "Buscar" y escribe parte del nombre de una prenda, **Entonces** ve la lista de prendas coincidentes, cada una con foto pequeña, nombre y existencia.
2. **Dado** que hay resultados, **Cuando** combina filtros de talla, color y sucursal, **Entonces** la lista muestra solo lo que cumple todos los filtros y la existencia corresponde a la sucursal filtrada.
3. **Dado** que el texto lleva mayúsculas o espacios sobrantes al inicio o al final, **Cuando** busca, **Entonces** obtiene los mismos resultados que sin ellos.
4. **Dado** que ninguna prenda coincide, **Cuando** termina la búsqueda, **Entonces** ve un mensaje claro de que no hay resultados.
5. **Dado** que la consulta falla por red o por el servicio, **Cuando** termina el intento, **Entonces** ve un aviso sin detalles técnicos y un botón para reintentar.
6. **Dado** que la búsqueda está en curso, **Cuando** espera, **Entonces** ve un indicador de carga.
7. **Dado** que el resultado es largo, **Cuando** el empleado recorre la lista, **Entonces** las prendas se muestran por bloques sin congelar la pantalla.

---

### Historia de usuario 2 - Ver la ficha de una prenda con su existencia por sucursal (Prioridad: P1)

Como empleado, quiero ver la foto, las características y la existencia de una prenda en las 5 sucursales, con desglose por talla y color, para decirle al cliente dónde puede encontrarla.

**Por qué esta prioridad**: Es la respuesta que el cliente espera. Además es la pantalla desde la que se descuenta stock.

**Prueba independiente**: Desde un resultado de búsqueda, abrir la ficha y comprobar foto, datos de la prenda y la matriz de existencias, con la sucursal del usuario destacada y la existencia cero marcada como agotada.

**Escenarios de aceptación**:

1. **Dado** que el empleado toca una prenda de los resultados, **Cuando** se abre la ficha, **Entonces** ve foto, nombre, descripción, marca, categoría y temporada, y la existencia en cada una de las 5 sucursales por talla y color.
2. **Dado** que la ficha está abierta, **Cuando** el empleado mira la matriz, **Entonces** la fila de su sucursal aparece destacada.
3. **Dado** que una combinación tiene existencia cero o baja, **Cuando** se muestra, **Entonces** se distingue con texto o ícono además del color ("Agotado", "Pocas piezas").
4. **Dado** que la ficha está abierta, **Cuando** el empleado jala hacia abajo para actualizar, **Entonces** la app vuelve a pedir los datos y muestra las existencias vigentes.
5. **Dado** que la prenda no tiene foto, **Cuando** se abre la ficha, **Entonces** se muestra una imagen de marcador de posición.
6. **Dado** que la ficha no se puede cargar, **Cuando** falla la consulta, **Entonces** ve un aviso claro con botón para reintentar.
7. **Dado** que la ficha está abierta, **Cuando** el empleado mira las acciones, **Entonces** ve el botón "Solicitar traspaso" deshabilitado con la leyenda "Próximamente" y no ocurre nada al tocarlo.

---

### Historia de usuario 3 - Escanear una etiqueta para abrir la ficha (Prioridad: P2)

Como empleado, quiero escanear con la cámara la etiqueta de una prenda para abrir su ficha al instante, sin escribir nada.

**Por qué esta prioridad**: Acelera la consulta y la venta, pero la búsqueda manual ya cubre la necesidad básica. Requiere además el permiso de cámara y pruebas en teléfono físico.

**Prueba independiente**: Abrir "Escanear", conceder el permiso, apuntar a una etiqueta con código de barras o QR de una prenda registrada y comprobar que se abre su ficha.

**Escenarios de aceptación**:

1. **Dado** que el empleado abre "Escanear" por primera vez, **Cuando** se muestra la pantalla, **Entonces** recibe una explicación breve del uso de la cámara antes de la solicitud del permiso.
2. **Dado** que la cámara está activa, **Cuando** lee un código de una prenda registrada, **Entonces** se abre su ficha.
3. **Dado** que el empleado mantiene el mismo código frente a la cámara, **Cuando** se leen varios fotogramas, **Entonces** se abre una sola ficha.
4. **Dado** que el código no corresponde a ninguna prenda, **Cuando** se lee, **Entonces** ve "prenda no encontrada" y puede escanear de nuevo sin salir del escáner.
5. **Dado** que el empleado negó el permiso de cámara, **Cuando** abre el escáner, **Entonces** se le ofrece buscar la prenda manualmente por código.
6. **Dado** que hay poca luz y el teléfono lo permite, **Cuando** el empleado activa la linterna, **Entonces** se enciende y puede apagarla.

---

### Historia de usuario 4 - Descontar piezas vendidas de mi sucursal (Prioridad: P1)

Como empleado, quiero descontar piezas de una prenda de mi sucursal cuando la vendo para mantener el inventario actualizado al momento.

**Por qué esta prioridad**: Es lo que mantiene el inventario confiable y el valor de negocio central del sprint. Debe ser a prueba de errores y de dobles envíos.

**Prueba independiente**: Desde la ficha, elegir talla y color de la sucursal propia, indicar una cantidad, confirmar y comprobar que la existencia mostrada baja con el valor que devuelve el servicio. Probar también una cantidad mayor a la existente.

**Escenarios de aceptación**:

1. **Dado** que el empleado está en la ficha, **Cuando** elige talla y color de su sucursal e indica una cantidad entera positiva, **Entonces** la app le pide confirmar mostrando prenda, talla, color y cantidad.
2. **Dado** que confirma, **Cuando** el servicio acepta la venta, **Entonces** se muestra la nueva existencia que devolvió el servicio.
3. **Dado** que la cantidad pedida es mayor que la existencia, **Cuando** el servicio la rechaza, **Entonces** ve un mensaje claro con la existencia actual y no cambia nada.
4. **Dado** que la cantidad está vacía, es cero, negativa o no es un entero, **Cuando** intenta confirmar, **Entonces** no se envía nada y se indica el problema.
5. **Dado** que la operación está en curso, **Cuando** el empleado toca de nuevo el botón, **Entonces** no se envía una segunda venta.
6. **Dado** que una existencia pertenece a otra sucursal, **Cuando** el empleado mira la ficha, **Entonces** no puede descontarla desde su cuenta.
7. **Dado** que no hay conexión, **Cuando** intenta vender, **Entonces** recibe un aviso y la operación no se intenta.

---

### Historia de usuario 5 - Navegar entre pantallas principales (Prioridad: P2)

Como empleado, quiero llegar a "Buscar" y "Escanear" desde la pantalla principal, y de ahí a la ficha y a la venta, para consultar el stock en pocos pasos.

**Por qué esta prioridad**: Une las funciones anteriores; sin ella las pantallas no son accesibles, pero cada una se puede probar por separado.

**Prueba independiente**: Desde la pantalla principal, entrar a "Buscar" y a "Escanear", abrir una ficha desde cada una y volver con el botón de regreso.

**Escenarios de aceptación**:

1. **Dado** que el usuario está en la pantalla principal, **Cuando** la ve, **Entonces** tiene accesos visibles a "Buscar" y a "Escanear".
2. **Dado** que está en la ficha, **Cuando** regresa, **Entonces** vuelve a los resultados o al escáner de donde vino.
3. **Dado** que la sesión venció, **Cuando** el empleado usa cualquier pantalla del sprint, **Entonces** la app la renueva sin que él lo note y la acción continúa.
3b. **Dado** que la sesión no se puede renovar (por ejemplo, ya expiró del todo o la cuenta se desactivó), **Cuando** el empleado usa cualquier pantalla del sprint, **Entonces** regresa al inicio de sesión con un aviso claro.
4. **Dado** que el servicio responde que falta permiso, **Cuando** el empleado intenta una operación, **Entonces** ve un aviso de falta de permisos sin cerrar su sesión.

---

### Casos límite

- Una prenda sin existencia en ninguna sucursal se muestra como agotada en la lista y en la ficha.
- Una prenda tiene muchas tallas y colores: la matriz sigue siendo legible y se puede recorrer.
- Dos personas venden la última pieza al mismo tiempo: gana la primera; la segunda recibe el aviso de existencia insuficiente con la existencia actual.
- La existencia cambió desde que se abrió la ficha: al vender se muestra el valor vigente que devuelve el servicio, no un cálculo local.
- La sesión vence con la ficha abierta: al vender o actualizar, la app la renueva y completa la acción; si no puede, regresa al inicio de sesión.
- Una venta se interrumpe por sesión vencida: tras renovar se reenvía una sola vez, nunca dos descuentos.
- La cámara no está disponible, está en uso o el dispositivo no tiene: se ofrece la búsqueda manual por código.
- Una etiqueta ilegible o con un código con espacios o formato distinto: se trata como código no reconocido.
- Un empleado sin sucursal asignada o con una sucursal no encontrada: puede consultar, pero no se le ofrece descontar.
- Un administrador ya no entra a la app (Sprint 1), por lo que no se contempla su venta.

## Requisitos *(obligatorio)*

### Requisitos funcionales

- **FR-001**: La app MUST permitir buscar prendas por texto libre (nombre, descripción o marca) y filtrar por talla, color y sucursal, de forma combinable.
- **FR-002**: La búsqueda MUST ignorar diferencias de mayúsculas y espacios sobrantes al inicio y al final.
- **FR-003**: La lista de resultados MUST mostrar foto pequeña, nombre y existencia total, o la de la sucursal filtrada cuando hay filtro de sucursal.
- **FR-004**: La búsqueda MUST mostrar los estados cargando, con resultados, sin resultados y error con botón de reintentar.
- **FR-005**: Los resultados largos MUST mostrarse por bloques sin congelar la pantalla.
- **FR-006**: La ficha MUST mostrar foto, nombre, descripción, marca, categoría y temporada de la prenda.
- **FR-007**: La ficha MUST mostrar la existencia en las 5 sucursales con desglose por talla y color, y destacar la sucursal del usuario.
- **FR-008**: La existencia baja o agotada MUST distinguirse con texto o ícono, además del color.
- **FR-009**: La ficha MUST actualizarse al abrirse y con el gesto de jalar para actualizar.
- **FR-010**: La app MUST ofrecer un escáner de códigos de barras y QR que abra la ficha de la prenda leída.
- **FR-011**: El escáner MUST pedir el permiso de cámara solo al abrirse, con una explicación breve previa.
- **FR-012**: Si el permiso se niega o la cámara no está disponible, la app MUST ofrecer la búsqueda manual por código.
- **FR-013**: Un código desconocido MUST mostrar "prenda no encontrada" y permitir escanear otra vez sin salir del escáner.
- **FR-014**: Un mismo código mantenido frente a la cámara MUST abrir una sola ficha.
- **FR-015**: La app MUST permitir descontar piezas de la sucursal del usuario eligiendo talla y color y escribiendo una cantidad.
- **FR-016**: La cantidad MUST ser un entero positivo; cualquier otro valor impide el envío.
- **FR-017**: Antes de enviar, la app MUST pedir confirmación mostrando prenda, talla, color y cantidad.
- **FR-018**: La sucursal del descuento MUST salir de la sesión del usuario, nunca de un campo editable, y la app NO debe ofrecer descuento sobre otras sucursales.
- **FR-019**: Tras una venta aceptada, la app MUST mostrar la existencia que devuelve el servicio.
- **FR-020**: Si el servicio rechaza la venta por existencia insuficiente, la app MUST mostrar un mensaje claro con la existencia actual y no modificar lo mostrado.
- **FR-021**: El botón de confirmar MUST deshabilitarse mientras la operación está en curso para evitar el doble envío.
- **FR-022**: Sin conexión, la app MUST avisar y bloquear la venta.
- **FR-023**: La pantalla principal MUST ofrecer accesos a "Buscar" y a "Escanear".
- **FR-024**: Ante una respuesta de falta de permisos, la app MUST mostrar un aviso sin cerrar la sesión.
- **FR-030**: Cuando la sesión venza, la app MUST renovarla automáticamente y repetir la acción interrumpida una sola vez, sin pedir credenciales.
- **FR-031**: Si la sesión no se puede renovar, la app MUST regresar al inicio de sesión con un aviso claro y descartar los datos de la sesión.
- **FR-032**: Varias peticiones que fallen a la vez por sesión vencida MUST provocar una sola renovación, no una por petición.
- **FR-025**: Los datos de prendas e inventario MUST obtenerse mediante repositorios con implementación real y simulada, intercambiables sin tocar pantallas.
- **FR-026**: Los datos simulados MUST incluir prendas de varias sucursales, tallas y colores, y casos de existencia baja y agotada.
- **FR-027**: La app NO debe mostrar ni capturar precios; solo piezas.
- **FR-029**: La ficha MUST mostrar el botón "Solicitar traspaso" deshabilitado con la leyenda "Próximamente"; la solicitud de traspaso no se implementa en este sprint.
- **FR-028**: Todos los textos MUST estar en español y ningún error MUST mostrar detalles técnicos.

### Entidades clave

- **Prenda**: artículo del catálogo con código de barras, nombre o descripción, marca, categoría, temporada y foto.
- **Existencia**: cantidad de piezas de una prenda, en una sucursal, para una talla y un color; tiene un identificador propio que se usa para vender y un umbral que indica cuándo es baja.
- **Sucursal**: tienda con identificador y nombre; son 5.
- **Venta (descuento)**: operación que resta una cantidad entera positiva a una existencia de la sucursal del usuario y devuelve la existencia resultante.
- **Sesión del usuario**: nombre, rol y sucursal asignada, ya disponibles del Sprint 1.

## Criterios de éxito *(obligatorio)*

### Resultados medibles

- **SC-001**: Un empleado encuentra una prenda y ve su existencia en las 5 sucursales en menos de 15 segundos desde la pantalla principal.
- **SC-002**: Escanear una etiqueta registrada abre la ficha en menos de 3 segundos en el teléfono de pruebas.
- **SC-003**: Un empleado completa un descuento de venta en menos de 20 segundos desde que abre la ficha.
- **SC-004**: El 100 % de los intentos de vender más piezas de las existentes se rechaza con un mensaje que incluye la existencia actual, y la existencia nunca queda negativa.
- **SC-005**: Un doble toque en el botón de confirmar genera una sola venta en el 100 % de los casos probados.
- **SC-006**: En las pruebas de aceptación con el teléfono físico, se cumplen todos los escenarios de búsqueda, ficha, escáner y venta.
- **SC-008**: Una sesión vencida se renueva sin intervención del empleado en el 100 % de los casos probados, y una venta interrumpida por esto nunca se descuenta dos veces.
- **SC-007**: Ninguna pantalla del sprint muestra precios ni mensajes técnicos al usuario.

## Supuestos

- Se construye sobre el Sprint 1: inicio de sesión, tema visual, red, seguridad y pantalla principal ya existen y no se reimplementan.
- Se usa el contrato real de `docs/openapi.yaml` de `develop`: búsqueda de prendas, ficha por identificador y por código de barras, consulta de inventario y registro de ventas, con respuesta de conflicto por existencia insuficiente.
- La ficha devuelve ya las existencias de las 5 sucursales con su identificador de inventario, que es el que se usa para vender.
- El servicio impone las reglas de negocio (existencia no negativa, solo la sucursal del usuario); la app solo valida lo mínimo.
- Las fotos llegan por dirección web o pueden faltar; se usa una imagen de marcador de posición.
- Los empleados usan celulares Android; iPhone queda previsto pero sin pruebas en este sprint.
- Hay internet estable en las tiendas; no hay modo sin conexión ni caché de inventario.
- El administrador no entra a la app (decisión del Sprint 1).
- El gerente puede buscar, escanear y vender de su sucursal igual que el empleado; sus funciones adicionales quedan fuera.
- Se mantiene la posibilidad de volver a los datos simulados con la misma configuración del Sprint 1.
- La renovación de sesión depende de que Keycloak entregue el token de renovación en el acceso; se confirma con el Integrante 2 en la prueba real. Si no lo entrega, se vuelve al inicio de sesión al vencer.

## Fuera de alcance

- Solicitud, seguimiento y aprobación de traspasos, y notificaciones (Sprint 3).
- Alta, edición y baja de prendas desde el móvil.
- Precios, cobros y descuentos comerciales.
- Alertas de stock bajo y reportes: son de la web.
- Modo sin conexión y caché de inventario.
