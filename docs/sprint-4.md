<!--
Documento de entrada para /speckit.specify.
No guardar este archivo dentro de la carpeta specs/ generada por Spec Kit.
-->

# Insumo de especificación - Sprint 4: Pulido, pruebas y entrega de la app móvil

> **Referencias obligatorias para el agente:**
>
> - Contexto maestro: `docs/project-context.md`
> - Constitución técnica: `docs/reglas.md`
> - Este documento describe únicamente el alcance del Sprint 4 de la app móvil (7 al 10 de diciembre de 2026).
> - Se construye sobre los Sprints 1, 2 y 3. No se deben reimplementar funcionalidades ya terminadas.

## 1. Contexto

El Sprint 4 del proyecto cubre reportes, auditoría, respaldos, acceso remoto y la entrega a la dueña. Los reportes y las alertas de stock bajo son de la página web, así que para la app móvil este sprint no agrega grandes funciones: se dedica a cerrar pendientes, endurecer lo construido, probarlo de extremo a extremo con el sistema real y entregar un instalable estable el 11 de diciembre.

## 2. Objetivo

Entregar una app móvil estable, probada contra el sistema desplegado y lista para que la dueña y los empleados la usen en las 5 sucursales.

## 3. Historias de usuario

### US-S4-01 — Conexión con el sistema desplegado

Como empleado, quiero que la app funcione con el servidor real de Moda de Lizz para usarla en mi tienda sin depender de datos de ejemplo.

### US-S4-02 — Robustez ante fallos de red

Como empleado, quiero que la app me explique con claridad qué pasó cuando falla la conexión, para saber si debo reintentar o avisar.

### US-S4-03 — Rendimiento y fluidez

Como empleado, quiero que la búsqueda, el escáner y el descuento respondan rápido para no hacer esperar al cliente.

### US-S4-04 — Aviso de stock bajo en la ficha

Como empleado, quiero ver una señal clara cuando una prenda tiene poca existencia para avisar al gerente a tiempo. *(Sujeto a la decisión pendiente de la sección 10.)*

### US-S4-05 — Instalable y entrega

Como dueña, quiero instalar la app en los celulares del personal para empezar a usarla en las tiendas.

### US-S4-06 — Manual de uso breve

Como empleado, quiero una guía corta de uso dentro de la app para aprender sin capacitación larga.

## 4. Alcance funcional

### 4.1 Conexión con el sistema real

- Cambiar todos los repositorios a la implementación real.
- Dirección de la API de producción configurada por entorno, con HTTPS, mediante el dominio publicado por el equipo de infraestructura.
- Conservar la implementación simulada solo para pruebas.
- Verificar el inicio de sesión con los usuarios reales de Keycloak y con cada rol.

### 4.2 Manejo de errores y fallos de red

- Revisión de todas las pantallas para que tengan los tres estados: cargando, con datos y error.
- Mensajes claros y diferenciados para: sin internet, servidor no disponible, sesión vencida, falta de permisos y existencia insuficiente.
- Botón de reintento en los errores recuperables.
- Con la sesión vencida, volver al inicio de sesión sin perder lo que el usuario hacía, cuando sea posible.
- Como no hay modo sin conexión, sin internet se muestra un aviso y se bloquean las acciones que modifican datos.
- Tiempos de espera definidos en las peticiones para no dejar al usuario esperando indefinidamente.

### 4.3 Rendimiento

- Tiempo de respuesta percibido corto en búsqueda, ficha, escáner y descuento.
- Carga de imágenes con vista previa mientras llegan y sin bloquear la pantalla.
- Evitar peticiones repetidas innecesarias.
- Fluidez al desplazarse por listas largas.
- Revisión de consumo de memoria y batería durante el uso del escáner.

### 4.4 Aviso de stock bajo en la ficha

- Señal visible en la ficha cuando la existencia de una prenda en una sucursal está por debajo del umbral que entregue la API.
- La señal usa ícono y texto, no solo color.
- No hay panel de alertas en la app: ese panel es de la web.
- Si se decide que la app no muestra esta señal, la historia se retira.

### 4.5 Accesibilidad y usabilidad

- Tamaños de texto legibles y respeto del tamaño de fuente del sistema.
- Zonas táctiles suficientemente grandes.
- Contraste adecuado en el tema rosa pastel y blanco.
- Revisión del flujo completo con personal de la tienda, con el cliente enfrente.

### 4.6 Guía de uso

- Pantalla de ayuda dentro de la app con los pasos de buscar, escanear, descontar y solicitar un traspaso.
- Textos cortos y con capturas o íconos.

### 4.7 Instalable y despliegue

- Generar el APK de la versión final firmado para su instalación.
- Instrucciones de instalación en los celulares del personal, incluida la autorización de orígenes desconocidos si se instala fuera de la tienda de aplicaciones.
- Versión de la app visible en la pantalla de ayuda.
- Compilación para iPhone solo si se cuenta con un equipo Mac disponible; de lo contrario, queda documentado como pendiente.

### 4.8 Pruebas de extremo a extremo

- Recorrido completo con el sistema real, por rol: inicio de sesión, búsqueda, escáner, ficha, descuento, solicitud de traspaso, avisos y cierre de sesión.
- Verificar que un descuento hecho en una sucursal se vea en las demás.
- Probar con varios usuarios al mismo tiempo, considerando que la tienda tiene más de 25 empleados.
- Pruebas de regresión de los Sprints 1, 2 y 3.
- Revisión con la dueña como Product Owner.

## 5. Roles y permisos del Sprint 4

No cambian respecto a los sprints anteriores. Se verifica en el sistema real que cada rol solo realiza las acciones que le corresponden.

| Rol | Acceso a la app |
|---|---|
| Empleado (`ROLE_VENDEDOR`) | Búsqueda, escáner, ficha, descuento, traspasos propios y avisos |
| Gerente (`ROLE_ENCARGADO`) | Lo anterior, más lo confirmado en las decisiones pendientes |
| Administrador (`ROLE_ADMIN`) | Aviso que lo dirige a la web (pendiente de confirmar) |

## 6. Reglas de negocio

- Las reglas de los sprints anteriores siguen vigentes.
- La app no incluye datos de ejemplo en la versión de entrega.
- La existencia nunca queda negativa; la regla la aplica la API.
- La app no guarda contraseñas ni muestra información interna al usuario.
- Lo nuevo que pida la dueña después de este punto entra en una versión posterior.

## 7. Criterios de aceptación

### Sistema real

- La app inicia sesión con usuarios reales de cada rol.
- La búsqueda, la ficha, el descuento y los traspasos funcionan contra el servidor desplegado.
- Un descuento hecho en una sucursal se refleja en las demás.

### Errores

- Sin internet se muestra un aviso y se bloquean las acciones que modifican datos.
- Cada tipo de error tiene un mensaje claro y distinto.
- Una petición lenta termina con un aviso en lugar de quedar colgada.
- La sesión vencida lleva al inicio de sesión.

### Rendimiento

- La búsqueda y la apertura de una ficha responden de forma fluida en un celular Android de gama media.
- El escáner abre la ficha casi de inmediato tras reconocer el código.
- Las listas largas se desplazan sin trabarse.

### Stock bajo

- La señal aparece cuando la existencia está por debajo del umbral y se distingue sin depender del color.

### Entrega

- El APK final se instala y abre correctamente en celulares reales.
- La guía de uso está disponible dentro de la app.
- La dueña prueba la app y valida el resultado.

### Pruebas

- Pasan todas las pruebas de los ViewModels y la regresión de los Sprints 1, 2 y 3.
- Se completa el recorrido de extremo a extremo por rol, con evidencia.

## 8. Entidades principales

No se agregan entidades. Se reutilizan Usuario, Sesión, Sucursal, Prenda, Inventario por sucursal, Traspaso y Notificación definidas en los sprints anteriores.

## 9. Entregables

- App conectada al sistema real, sin datos de ejemplo.
- Manejo de errores y fallos de red revisado.
- Ajustes de rendimiento y usabilidad.
- Señal de stock bajo en la ficha, si se confirma.
- Guía de uso dentro de la app.
- APK final firmado e instrucciones de instalación.
- Informe de pruebas de extremo a extremo con evidencia.
- Contribución al documento técnico y a la presentación final, coordinada con el Integrante 4.
- Etiqueta de versión `v1.0.0` para la entrega final, coordinada con el Integrante 4.

## 10. Dependencias y decisiones pendientes

| Necesita | De quién | Mientras tanto |
|---|---|---|
| Servidor desplegado con dominio HTTPS (Cloudflare Tunnel) | Integrante 2 | Probar contra el entorno local con Docker Compose |
| Datos reales de inventario cargados | Integrante 1 y gerentes | Datos de prueba identificados |
| Usuarios reales y roles en Keycloak | Integrante 2 | Usuarios de prueba |
| Mesa de control de traspasos en la web | Web, por asignar | Cambios de estado simulados |
| Documento técnico y plantilla de bitácora | Integrante 4 | No aplica |

### Decisiones pendientes (resolver con `/speckit.clarify`)

1. ¿La app muestra una señal de stock bajo en la ficha, o eso queda solo en la web?
2. ¿Se compila para iPhone en esta entrega o se documenta como pendiente?
3. ¿Se distribuye el APK por enlace directo o por otro medio?

## 11. Fuera de alcance

- Reportes, panel de alertas y gestión de usuarios: son de la web.
- Modo sin conexión.
- Precios y descuentos comerciales.
- Publicación en Google Play o App Store.
- Notificaciones por correo o mensajes de texto.
- Funcionalidades nuevas que no estén en este documento.

## 12. Cierre del sprint y del proyecto

El Sprint 4 se considera cerrado cuando la app funciona con el sistema desplegado, las pruebas de extremo a extremo y de regresión pasan, el APK final fue instalado en celulares reales del personal, la dueña validó la entrega y la evidencia, el documento técnico y la bitácora final están completos antes del 11 de diciembre de 2026.
