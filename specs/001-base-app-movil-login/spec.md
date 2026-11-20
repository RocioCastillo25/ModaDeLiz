# Especificación de la funcionalidad: Base de la app móvil e inicio de sesión

**Rama de la funcionalidad**: `001-base-app-movil-login`

**Creado**: 2026-11-20

**Estado**: Borrador

**Entrada**: Descripción del usuario: "Construir la base de la aplicación móvil de CheckLizz e implementar su inicio de sesión (Sprint 1)" (`spec-input.md`, con apoyo en `docs/sprint-1.md`).

## Aclaraciones

### Sesión 2026-11-20

- Q: Cuando un administrador inicia sesión con credenciales válidas en la app, ¿qué debe pasar? → A: Ve un aviso que lo dirige a la página web, no entra a la pantalla principal y su sesión no se conserva.
- Q: ¿Cómo debe escribir su usuario y contraseña la persona que inicia sesión: en un formulario dentro de la app o en una página de acceso que se abre en el navegador? → A: En un formulario propio dentro de la app, con usuario y contraseña.
- Q: Cuando el servicio rechaza la sesión (venció o ya no es válida), ¿la app vuelve directo al inicio de sesión o intenta renovarla primero? → A: Vuelve directo al inicio de sesión con un aviso claro; la renovación de sesión se difiere a un sprint posterior, cuando el contrato de la API la defina.

## Escenarios de usuario y pruebas *(obligatorio)*

### Historia de usuario 1 - Iniciar sesión y ver la pantalla principal (Prioridad: P1)

Como empleado o gerente de tienda, quiero iniciar sesión con mi usuario y contraseña para acceder a las funciones que me corresponden y confirmar, en la pantalla principal, que entré con mi cuenta, mi rol y mi sucursal.

**Por qué esta prioridad**: Sin acceso seguro no existe ninguna otra función de la app. Es la base mínima que entrega valor y sobre la que se construyen los siguientes sprints.

**Prueba independiente**: Con un usuario de ejemplo, escribir usuario y contraseña, entrar y comprobar que la pantalla principal muestra nombre, rol y sucursal correctos.

**Escenarios de aceptación**:

1. **Dado** que el usuario tiene una cuenta activa, **Cuando** escribe su usuario y contraseña correctos y pulsa "Iniciar sesión", **Entonces** llega a la pantalla principal, donde ve su nombre, su rol y su sucursal asignada.
2. **Dado** que el usuario escribe credenciales incorrectas, **Cuando** pulsa "Iniciar sesión", **Entonces** ve un mensaje genérico que no revela si el usuario existe y permanece en el inicio de sesión.
3. **Dado** que la cuenta está desactivada, **Cuando** intenta iniciar sesión, **Entonces** ve un mensaje claro de que no puede entrar y no accede a la app.
4. **Dado** que algún campo del formulario está vacío, **Cuando** intenta enviarlo, **Entonces** no se envía nada y se indica qué campo falta.
5. **Dado** que el inicio de sesión se está procesando, **Cuando** el usuario vuelve a pulsar el botón, **Entonces** no se envía una segunda petición y se ve que está cargando.
6. **Dado** que no hay conexión a internet, **Cuando** el usuario intenta iniciar sesión, **Entonces** recibe un aviso claro y no se intenta la operación.
7. **Dado** que el servicio de acceso falla, **Cuando** el usuario intenta iniciar sesión, **Entonces** ve un mensaje claro, sin detalles técnicos, y puede reintentar.

---

### Historia de usuario 2 - Cerrar sesión (Prioridad: P2)

Como usuario autenticado, quiero cerrar mi sesión para que otra persona no use mi cuenta desde el mismo teléfono.

**Por qué esta prioridad**: Protege la cuenta en teléfonos compartidos o perdidos; depende de que ya exista el inicio de sesión.

**Prueba independiente**: Iniciar sesión, pulsar "Cerrar sesión" y comprobar que se regresa al inicio de sesión y que, al reabrir la app, se pide iniciar sesión de nuevo.

**Escenarios de aceptación**:

1. **Dado** que el usuario está en la pantalla principal, **Cuando** pulsa "Cerrar sesión", **Entonces** la app olvida la sesión y vuelve al inicio de sesión.
2. **Dado** que el usuario cerró sesión, **Cuando** cierra y reabre la app, **Entonces** se le pide iniciar sesión y no queda información de su cuenta visible.

---

### Historia de usuario 3 - Sesión persistente y expiración (Prioridad: P2)

Como usuario autenticado, quiero que la app recuerde mi sesión mientras sea válida y me pida iniciar sesión de nuevo cuando expire, para no escribir mis datos cada vez que abro la app.

**Por qué esta prioridad**: Reduce fricción diaria en piso de venta y mantiene la seguridad cuando la sesión vence.

**Prueba independiente**: Iniciar sesión, cerrar la app sin cerrar sesión y reabrirla; luego simular una sesión vencida y reabrirla.

**Escenarios de aceptación**:

1. **Dado** que el usuario tiene una sesión vigente, **Cuando** reabre la app, **Entonces** entra directamente a la pantalla principal sin escribir sus datos.
2. **Dado** que la sesión venció, **Cuando** el usuario abre la app, **Entonces** se le pide iniciar sesión de nuevo.
3. **Dado** que el usuario usa la app, **Cuando** el servicio indica que su sesión ya no es válida, **Entonces** la app vuelve al inicio de sesión con un aviso claro.

---

### Historia de usuario 4 - Comportamiento por rol (Prioridad: P3)

Como administrador, quiero que la app me avise que mi herramienta de trabajo es la página web, para no intentar usar funciones que no me corresponden en el teléfono.

**Por qué esta prioridad**: Es un caso de borde del acceso; no bloquea a los usuarios principales (empleados y gerentes).

**Prueba independiente**: Iniciar sesión con el usuario de ejemplo administrador y comprobar que ve el aviso y no accede a la pantalla principal.

**Escenarios de aceptación**:

1. **Dado** que un administrador inicia sesión con credenciales válidas, **Cuando** el acceso se procesa, **Entonces** ve un aviso que lo dirige a la página web, no accede a la pantalla principal y su sesión no se conserva en el teléfono.
2. **Dado** que un empleado o gerente inicia sesión, **Cuando** el acceso se procesa, **Entonces** accede a la pantalla principal sin ver ese aviso.

---

### Historia de usuario 5 - Base de la app con datos de ejemplo e imagen de CheckLizz (Prioridad: P1)

Como integrante del equipo, quiero una base de app ordenada, con la imagen visual de CheckLizz y datos de ejemplo intercambiables por los reales, para que las siguientes funcionalidades se construyan sin rehacer lo anterior ni depender de los demás servicios.

**Por qué esta prioridad**: La API y la identidad se construyen en paralelo; sin datos de ejemplo no se puede probar nada. Es habilitadora de todo el proyecto.

**Prueba independiente**: Instalar la app, entrar con cada usuario de ejemplo y revisar que los datos de prueba están identificados como tales y que el diseño cumple lo descrito.

**Escenarios de aceptación**:

1. **Dado** que los servicios reales aún no están disponibles, **Cuando** se usa la app con los datos de ejemplo, **Entonces** existe un usuario de ejemplo por rol, cada uno con su sucursal, identificado claramente como de prueba.
2. **Dado** que los servicios reales ya están disponibles, **Cuando** el equipo cambia de datos de ejemplo a datos reales, **Entonces** las pantallas siguen funcionando igual, sin modificarse.
3. **Dado** que el usuario abre el inicio de sesión, **Cuando** ve la pantalla, **Entonces** aparece el nombre "CheckLizz" con estética oscura, botones grandes y lectura rápida.
4. **Dado** que el sistema tiene activada la preferencia de reducir movimiento, **Cuando** el usuario navega, **Entonces** las animaciones se reducen o desaparecen.

---

### Casos límite

- ¿Qué pasa si el usuario escribe solo espacios en usuario o contraseña? Se trata como campo vacío.
- ¿Qué pasa si la conexión se pierde mientras se procesa el inicio de sesión? Se muestra un error claro con opción de reintentar y el botón vuelve a habilitarse.
- ¿Qué pasa si la sesión vence mientras el usuario está en la pantalla principal? Al siguiente intento de usar el servicio, la app vuelve al inicio de sesión con un aviso.
- ¿Qué pasa si la respuesta de acceso no trae rol o sucursal? No se permite entrar y se muestra un mensaje claro, sin detalles técnicos.
- ¿Qué pasa si una cuenta se desactiva mientras tiene sesión abierta? Al renovar o validar la sesión, ya no puede continuar y se le pide iniciar sesión.
- ¿Qué pasa si el usuario pulsa varias veces "Iniciar sesión" muy rápido? Solo se procesa una petición.

## Requisitos *(obligatorio)*

### Requisitos funcionales

- **FR-001**: El sistema DEBE permitir iniciar sesión con usuario y contraseña, escritos en un formulario propio dentro de la app (sin redirigir a una página de acceso externa).
- **FR-002**: El sistema DEBE impedir el envío del formulario de inicio de sesión cuando algún campo esté vacío o contenga solo espacios, e indicar qué falta.
- **FR-003**: El sistema DEBE mostrar un mensaje genérico ante credenciales incorrectas, sin revelar si el usuario existe.
- **FR-004**: El sistema DEBE rechazar las cuentas desactivadas con un mensaje claro.
- **FR-005**: El sistema DEBE deshabilitar el botón de inicio de sesión mientras la operación está en curso, para evitar envíos duplicados.
- **FR-006**: El sistema DEBE mostrar estados visibles de cargando, éxito y error en el inicio de sesión.
- **FR-007**: El sistema DEBE obtener el nombre, el rol y la sucursal asignada del usuario a partir de la respuesta de acceso.
- **FR-008**: El sistema DEBE mostrar una pantalla principal con nombre, rol y sucursal del usuario.
- **FR-009**: La pantalla principal DEBE mostrar los accesos a búsqueda, escáner y traspasos marcados como "próximamente", sin función en este sprint.
- **FR-010**: El sistema DEBE ofrecer un botón de cierre de sesión en la pantalla principal.
- **FR-011**: Al cerrar sesión, el sistema DEBE borrar la sesión guardada, limpiar el estado de la app y volver al inicio de sesión.
- **FR-012**: Al abrir la app con una sesión vigente, el sistema DEBE entrar directamente a la pantalla principal sin pedir credenciales.
- **FR-013**: Cuando la sesión haya vencido o el servicio la rechace, el sistema DEBE volver directo al inicio de sesión con un aviso claro, sin intentar renovarla.
- **FR-014**: El sistema NO DEBE guardar la contraseña del usuario en el dispositivo.
- **FR-015**: El sistema DEBE guardar la sesión únicamente en almacenamiento seguro del dispositivo.
- **FR-016**: Los usuarios con rol Empleado o Gerente de tienda DEBEN poder iniciar sesión y ver la pantalla principal.
- **FR-017**: Cuando inicie sesión un administrador, el sistema DEBE mostrarle un aviso que lo dirige a la página web, NO DEBE darle acceso a la pantalla principal y NO DEBE conservar su sesión en el dispositivo.
- **FR-018**: Sin conexión a internet, el sistema DEBE avisar al usuario y no intentar el inicio de sesión.
- **FR-019**: El sistema DEBE mostrar mensajes de error claros, en español, sin detalles técnicos ni códigos internos, con opción de reintentar cuando aplique.
- **FR-020**: El sistema DEBE incluir usuarios de ejemplo (uno por rol, con su sucursal) claramente identificados como de prueba.
- **FR-021**: El sistema DEBE permitir cambiar entre los datos de ejemplo y los servicios reales sin modificar las pantallas.
- **FR-022**: La interfaz DEBE usar la estética oscura y la paleta definidas en la sección 12 de `docs/project-context.md`, con el nombre "CheckLizz" en el inicio de sesión.
- **FR-023**: La interfaz DEBE tener botones grandes, foco visible y buen contraste, y DEBE respetar la preferencia del sistema de reducir movimiento.
- **FR-024**: Todos los textos de la interfaz DEBEN estar en español, con tildes y signos de apertura correctos.
- **FR-025**: El sistema NO DEBE incluir en este sprint búsqueda, ficha de prenda, escáner, descuento de existencias, traspasos, notificaciones, registro de cuentas, recuperación de contraseña, precios ni modo sin conexión.

### Entidades clave

- **Usuario**: persona con cuenta; tiene identificador, nombre, rol (Administrador, Gerente de tienda o Empleado) y una sucursal asignada.
- **Sesión**: periodo de acceso de un usuario; incluye su credencial de acceso, su fecha de expiración y el usuario autenticado.
- **Sucursal**: tienda de Moda de Lizz (Huauchinango, Zacatlán, Chignahuapan, Ahuazotepec o Xicotepec), con identificador y nombre.

## Criterios de éxito *(obligatorio)*

### Resultados medibles

- **SC-001**: Un empleado o gerente con cuenta válida llega a la pantalla principal en menos de 10 segundos desde que abre la app e inicia sesión.
- **SC-002**: El 100 % de los intentos con campos vacíos, credenciales incorrectas o cuenta desactivada muestran el mensaje correspondiente y no permiten entrar.
- **SC-003**: El 100 % de las reaperturas con sesión vigente entran sin pedir credenciales.
- **SC-004**: El 100 % de las reaperturas con sesión vencida piden iniciar sesión de nuevo.
- **SC-005**: Tras cerrar sesión, no queda información de la persona accesible en el teléfono ni en la app.
- **SC-006**: La contraseña no se encuentra almacenada en el dispositivo en ningún momento.
- **SC-007**: Una persona sin capacitación completa el inicio de sesión al primer intento en el 90 % de los casos de prueba.
- **SC-008**: Pasar de datos de ejemplo a servicios reales no exige cambios en las pantallas.
- **SC-009**: La app se instala y funciona en un dispositivo o emulador Android, y se entrega un instalable de prueba con evidencia para la bitácora al cerrar el sprint.

## Suposiciones

- Las tiendas tienen internet estable; no hay modo sin conexión.
- Los empleados usan celulares Android; el soporte para iPhone se prevé cuando haya un equipo para compilar y probar.
- Las cuentas, los roles y las sucursales los administra la dueña desde la página web; la app no crea cuentas ni recupera contraseñas.
- La API y el sistema de identidad los entregan otros integrantes; mientras tanto se usan datos de ejemplo conforme al contrato `docs/openapi.yaml`.
- Cada usuario tiene exactamente un rol y una sucursal asignada.
- El administrador que inicia sesión ve el aviso que lo dirige a la web y no se conserva su sesión (decisión confirmada en la sesión de aclaraciones).
- El inicio de sesión se hace con un formulario propio dentro de la app (decisión confirmada en la sesión de aclaraciones); no se usa un flujo con navegador.
- La renovación automática de la sesión queda fuera de este sprint; se incorporará cuando el contrato de la API la defina.
- Los permisos reales se validan siempre en la API; la app solo adapta lo que muestra según el rol.
- El sprint corre del 16 al 21 de noviembre de 2026; la entrega final del proyecto es el 11 de diciembre de 2026.
- La Product Owner (la dueña de Moda de Lizz) valida cada entrega mediante un instalable de prueba.
