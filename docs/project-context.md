# Contexto general del proyecto

## 1. Identificación

- **Nombre:** CheckLizz, sistema de inventario conectado y traspasos entre sucursales.
- **Cliente:** Moda de Lizz, tienda de ropa con 5 sucursales: Huauchinango (matriz), Zacatlán, Chignahuapan, Ahuazotepec y Xicotepec.
- **Product Owner:** la dueña de Moda de Lizz.
- **Fecha límite de entrega:** 11 de diciembre de 2026.
- **Metodología:** Scrum, con 4 sprints de una semana.
- **Equipo:** 4 integrantes.
- **Integrante responsable de este repositorio de trabajo:** Integrante 3, Frontend móvil y escaneo (Flutter).
- **Tipo de proyecto:** proyecto académico con cliente real.

## 2. Propósito

CheckLizz centraliza el inventario de las 5 sucursales para que cualquier empleado consulte, desde su celular, qué prendas hay en todas las tiendas, descuente piezas al vender y solicite traspasos, en lugar de preguntar por WhatsApp con el cliente enfrente.

Hoy no existe una lista digital de prendas: el inventario está en papel o en la memoria del personal, y los traspasos se acuerdan de palabra, sin registro. El resultado son ventas perdidas, tiempo desperdiciado y decisiones sin información.

El producto completo se compone de tres piezas: una **app móvil** (empleados y gerentes), una **página web** (gerentes y administradora) y una **API REST** sobre una base de datos PostgreSQL central.

## 3. Alcance general del producto

El producto completo se organiza en cuatro sprints:

1. **Sprint 1, Fundamentos e inventario base (16 al 21 de nov):** Docker Compose, esquema relacional, usuarios y roles, carga inicial del inventario.
2. **Sprint 2, Movilidad y ventas (23 al 28 de nov):** app Flutter con login, búsqueda y consulta de stock, escáner de códigos y descuento por venta.
3. **Sprint 3, Logística de traspasos (30 de nov al 5 de dic):** solicitud, aprobación, cambio de estados y notificaciones.
4. **Sprint 4, Reportes, auditoría y entrega (7 al 10 de dic):** alertas de stock bajo, reportes, Cloudflare Tunnel, respaldos, pruebas de extremo a extremo y entrega a la dueña.

### Alcance de este repositorio de trabajo

Este repositorio cubre **únicamente la aplicación móvil** (`mobile/`), que es la parte del Integrante 3. Los sprints de `docs/sprint-1.md` a `docs/sprint-4.md` describen lo que la app móvil debe lograr en cada semana y qué necesita de los demás integrantes.

| Sprint | Meta de la app móvil |
|---|---|
| 1 | Base del proyecto Flutter (MVVM, DI, red, seguridad, tema) e inicio de sesión |
| 2 | Búsqueda, ficha de prenda, escáner de códigos y descuento por venta |
| 3 | Solicitud de traspasos y notificaciones de su estado |
| 4 | Pulido, pruebas, rendimiento, instalable (APK) y entrega |

Cada sprint construye sobre el anterior. No se vuelve a implementar una funcionalidad terminada sin una razón documentada.

## 4. Usuarios y roles

El sistema usa únicamente tres roles, administrados en Keycloak:

- **Administrador (`ROLE_ADMIN`):** la dueña. Su plataforma principal es la web: acceso global, gestión de usuarios, reportes y aprobación de cualquier traspaso.
- **Gerente de tienda (`ROLE_ENCARGADO`):** uno por sucursal. Usa web y móvil, restringido a su sucursal. Gestiona el inventario de su tienda y aprueba los traspasos de su sucursal.
- **Empleado (`ROLE_VENDEDOR`):** más de 25 personas en las 5 tiendas. Usa exclusivamente la app móvil.

### Quién usa la app móvil

- **Empleado:** consulta el stock de las 5 sucursales, escanea códigos, descuenta piezas de su sucursal, solicita traspasos y recibe avisos.
- **Gerente:** puede hacer todo lo anterior dentro de la app. Las funciones adicionales del gerente en móvil están pendientes de confirmación (ver sección 10).
- **Administrador:** su uso de la app móvil está pendiente de confirmación (ver sección 10).

Los permisos se verifican siempre en la API. Ocultar un botón en la app no protege una operación.

## 5. Reglas generales del negocio

- Todo usuario debe iniciar sesión para usar la app.
- Una cuenta desactivada no puede iniciar sesión.
- Cada usuario pertenece a una sucursal asignada.
- Un empleado consulta las 5 sucursales, pero solo descuenta stock de la suya.
- La existencia nunca puede quedar en negativo.
- Un cambio en el inventario debe verse de inmediato en las demás sucursales.
- Solo se descuentan cantidades de piezas; no se manejan precios.
- Un traspaso no puede pedir más piezas de las que tiene la sucursal de origen.
- Los estados de un traspaso son `SOLICITADO`, `APROBADO` o `RECHAZADO`, `EN_CAMINO` y `RECIBIDO`.
- El empleado que solicita un traspaso recibe aviso cuando cambia de estado.

## 6. Arquitectura y tecnologías

| Componente | Tecnología | Responsable |
|---|---|---|
| App móvil | Flutter (Android e iPhone), MVVM | Integrante 3 (este repositorio) |
| API | Node.js con Express, arquitectura en capas | Integrante 1 |
| Base de datos | PostgreSQL 15 o superior | Integrante 1 |
| Identidad y roles | Keycloak, tokens JWT | Integrante 2 |
| Infraestructura | Docker Compose, Cloudflare Tunnel | Integrante 2 |
| Página web | React con Vite | Por asignar |
| Repositorio y documentación | GitHub, Gitflow, bitácora | Integrante 4 |

```
App móvil (Flutter) ──> API REST (Node.js + Express) ──> PostgreSQL
Web (React + Vite)  ──┘        └─ valida tokens JWT de Keycloak
```

La app móvil nunca se conecta a la base de datos: toda la comunicación pasa por la API REST.

### Arquitectura de la app móvil

MVVM con `ChangeNotifier`: `View` (widgets), `ViewModel` (estado y lógica de presentación), `Model` (datos), `Repository` (oculta el origen de los datos) y `Service` (cliente HTTP, token, escáner). Inyección de dependencias con `get_it`.

## 7. Estructura de carpetas esperada

```
checklizz/
├── mobile/              # App Flutter (este repositorio de trabajo)
│   └── lib/
│       ├── main.dart
│       ├── core/        # di, network, security, theme
│       ├── data/        # models, dto, repositories, services
│       ├── features/    # auth, busqueda, ficha_prenda, venta, traspasos, notificaciones
│       └── shared/      # widgets reutilizables
├── api/                 # Backend (Integrante 1, no se modifica aquí)
├── infra/               # Docker, Keycloak (Integrante 2, no se modifica aquí)
├── web/                 # Página web (por asignar, no se modifica aquí)
├── docs/                # Insumos de Spec Kit y contrato openapi.yaml
├── specs/               # Generado por Spec Kit, una carpeta por sprint
├── .specify/            # Generado por Spec Kit
├── CLAUDE.md
└── README.md
```

## 8. Seguridad

- Inicio de sesión con usuario y contraseña; la API recibe tokens JWT emitidos por Keycloak.
- El token se guarda en almacenamiento seguro del dispositivo, nunca en texto plano ni en preferencias comunes.
- Cada petición a la API lleva el token mediante un interceptor.
- Cuando el token expira, la app renueva la sesión o pide iniciar sesión de nuevo.
- La comunicación con la API es cifrada (HTTPS).
- No se guardan contraseñas en el dispositivo.
- No se suben contraseñas ni archivos `.env` al repositorio; la dirección de la API se configura por entorno.
- Los mensajes de error no revelan información interna del sistema.

## 9. Alcance excluido

- Control de asistencia de empleados y geolocalización.
- Registro de precios, cobros, facturación y totales de venta. La app solo descuenta piezas; **no muestra precios ni descuentos comerciales**.
- Integración con punto de venta, impresoras fiscales y cajones de dinero.
- Funcionamiento sin conexión a internet (modo offline).
- Alta, edición y baja de prendas desde la app móvil, salvo que se confirme lo contrario (ver sección 10).
- Gestión de usuarios y reportes: son funciones de la web.
- Tienda en línea o app para clientes finales.

## 10. Supuestos, restricciones y decisiones pendientes

### Supuestos y restricciones

- Todas las tiendas tienen internet estable.
- La API, Keycloak y la base de datos los entregan otros integrantes; la app avanza en paralelo con datos simulados contra el contrato `docs/openapi.yaml`.
- Los empleados usan celulares Android; el soporte para iPhone se prevé cuando haya un equipo para compilar y probar.
- Se genera una versión instalable (APK) al final de cada sprint para que la dueña la pruebe.
- La fecha límite del 11 de diciembre de 2026 no se mueve; lo nuevo entra en el siguiente sprint.

### Decisiones pendientes (resolver con `/speckit.clarify`)

1. **Gerente en móvil:** ¿puede aprobar o rechazar traspasos desde la app, o solo desde la web? ¿Puede dar de alta prendas escaneando?
2. **Administrador en móvil:** ¿puede iniciar sesión en la app? Por defecto se le muestra un aviso que lo dirige a la web.
3. **Notificaciones:** ¿basta con avisos dentro de la app o se requieren notificaciones push (con un servicio externo)? Por defecto, dentro de la app.
4. **Mecanismo de login con Keycloak:** formulario propio con usuario y contraseña, o flujo con navegador (PKCE).
5. **Umbral de stock bajo:** ¿se muestra algún aviso en la app o es solo de la web?

## 11. Criterios generales de éxito

La app móvil se considerará satisfactoria cuando las pruebas demuestren que:

- Un empleado inicia y cierra sesión con su usuario y contraseña.
- Se puede buscar una prenda por nombre, talla, color, sucursal o código de barras.
- Escanear una etiqueta abre la ficha de la prenda de inmediato.
- La ficha muestra foto, características y existencia en las 5 sucursales.
- Descontar piezas actualiza el inventario y nunca deja la existencia en negativo.
- Un empleado puede solicitar un traspaso y ver su estado.
- El empleado recibe aviso cuando su traspaso cambia de estado.
- Un usuario solo puede hacer lo que su rol permite.
- La interfaz es rápida y sencilla de usar con el cliente enfrente.
- Se entrega un APK instalable que la dueña puede probar.

## 12. Diseño visual de la aplicación

La interfaz retoma la estética del pitch del proyecto (`pitch-moda-de-lizz.html`): **moderna, oscura y con glassmorphism discreto**.

- Fondo principal: degradado de `#1b1035` a `#3a1561`.
- Acentos: rosa `#ff5fa2`, violeta `#8b5cf6`, cian `#38d6e8` y ámbar `#ffb86b`.
- Superficies tipo vidrio: blanco con transparencia (`rgba(255, 255, 255, 0.10)`), borde sutil y esquinas redondeadas.
- Texto blanco, con texto secundario al 72 % de opacidad.
- Botón principal con degradado rosa a violeta; estados de foco visibles y buen contraste.
- Tipografía sans-serif limpia.
- Diseñada para uso con una mano y en piso de venta: botones grandes, pocos pasos y lectura rápida.
- Las animaciones son suaves y breves, y no retrasan ninguna operación. Se respeta la preferencia del sistema de reducir movimiento.
- La estética no debe cambiar la lógica, las llamadas a la API ni el manejo de sesión.

## 13. Organización del equipo

| Integrante | Responsabilidad |
|---|---|
| 1 | Backend, base de datos y API REST |
| 2 | Seguridad, roles y Docker (Keycloak, Docker Compose) |
| **3** | **Frontend móvil y escaneo (Flutter), este repositorio** |
| 4 | DevOps, control de versiones, documentación y bitácora |

### Ajustes frente a la descripción original de tareas

- Las **asistencias** quedan fuera de alcance (no es parte de este producto).
- **Precios y descuentos** quedan fuera de alcance: la app muestra existencias, no precios.
- La **página web** todavía no tiene responsable asignado.
