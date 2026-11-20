<!--
Informe de impacto de sincronización
- Cambio de versión: (plantilla sin completar) → 1.0.0
- Principios modificados: ninguno (constitución inicial)
- Principios agregados: I–XI (derivados de docs/reglas.md, secciones I–XI y XIV)
- Secciones agregadas: "Restricciones técnicas y alcance excluido", "Flujo de desarrollo y pruebas", "Gobernanza"
- Secciones eliminadas: ninguna
- Pendientes: ninguno
-->
# Constitución de CheckLizz (app móvil)

Fuente de verdad: `docs/reglas.md`. Esta constitución lo adopta sin cambiar su contenido; ante cualquier
diferencia, se corrige esta constitución para que coincida con ese documento o se enmienda según la
sección de Gobernanza.

## Principios fundamentales

### I. Arquitectura y límites del repositorio
- La app vive en `mobile/` y se desarrolla con Flutter y Dart, con código base único para Android e iPhone.
- La app MUST consumir únicamente la API REST; nunca se conecta directamente a PostgreSQL ni a Keycloak
  para operaciones de negocio.
- Las reglas de negocio viven en la API. La app valida solo lo mínimo para la experiencia (campos vacíos,
  cantidades positivas) y MUST NOT duplicar reglas como el límite de existencia.
- `api/`, `infra/` y `web/` pertenecen a otros integrantes y MUST NOT modificarse aquí.
- No se introducen paquetes ni servicios externos nuevos sin justificar su necesidad y documentar el cambio.

### II. Patrón MVVM con ChangeNotifier
- **View:** widgets y pantallas; solo muestran estado y envían acciones del usuario.
- **ViewModel:** estado de la pantalla (cargando, datos, error) y lógica de presentación.
- **Model:** clases de datos (prenda, inventario, traspaso, usuario).
- **Repository:** oculta al ViewModel el origen de los datos.
- **Service:** comunicación de bajo nivel (cliente HTTP, almacenamiento seguro del token, escáner).
- Una View MUST NOT llamar a la API ni a un Service directamente.
- Un ViewModel MUST NOT importar `package:flutter/material.dart` ni conocer widgets.
- Cada pantalla tiene su propio ViewModel dentro de `features/<nombre>/`.

### III. Estructura de carpetas, patrones de diseño e inyección de dependencias
- Estructura obligatoria de `mobile/lib/`: `main.dart`, `core/` (`di`, `network`, `security`, `theme`),
  `data/` (`models`, `dto`, `repositories`, `services`), `features/` (`auth`, `busqueda`, `ficha_prenda`,
  `venta`, `traspasos`, `notificaciones`) y `shared/` (widgets reutilizables).
- Los patrones se aplican solo donde resuelven un problema concreto: Singleton (`ApiClient` como singleton
  perezoso en `get_it`, no variable global), Factory (`fromJson` en cada modelo), Adapter (DTO a modelo y
  envoltura del escáner tras `BarcodeScannerService`), Decorator (interceptor que agrega
  `Authorization: Bearer <token>`), Observer (`ChangeNotifier` y widgets reactivos) y Repository (único
  punto de acceso a datos para los ViewModels).
- Se usa `get_it` como contenedor; las dependencias llegan por constructor (`ApiClient` → Repositories →
  ViewModels) y ninguna clase crea por sí misma sus dependencias.
- Toda interfaz de repositorio MUST tener una implementación real (contra la API) y una simulada (datos de
  ejemplo), intercambiables desde el registro de dependencias.

### IV. Autenticación y sesión
- El usuario inicia sesión con usuario y contraseña; el token JWT lo emite Keycloak.
- El token se guarda únicamente en almacenamiento seguro del dispositivo (`flutter_secure_storage` o
  equivalente). La contraseña MUST NOT guardarse en el dispositivo.
- Las credenciales incorrectas muestran un mensaje genérico que no revela si el usuario existe.
- Ante 401 se intenta renovar la sesión; si no es posible, se vuelve al inicio de sesión.
- Ante 403 se muestra un aviso de falta de permisos sin cerrar la sesión.
- Cerrar sesión borra el token y limpia el estado de los ViewModels.
- Una cuenta desactivada no puede iniciar sesión.

### V. Roles y permisos
- Los roles son `ROLE_ADMIN`, `ROLE_ENCARGADO` y `ROLE_VENDEDOR`, y se leen del token.
- La app muestra u oculta opciones según el rol solo para mejorar la experiencia; la API decide si una
  operación procede.
- Un empleado solo descuenta stock de su propia sucursal, tomada del usuario autenticado y nunca de un
  campo editable.

### VI. Inventario, ventas y escáner
- La consulta de inventario muestra las 5 sucursales.
- La app solo descuenta **cantidades de piezas**; MUST NOT mostrar ni capturar precios, cobros ni
  descuentos comerciales.
- La cantidad a descontar es un entero positivo; la app impide enviar valores inválidos y la API valida que
  la existencia no quede negativa.
- Si la API rechaza una venta por existencia insuficiente, la app muestra un mensaje claro con la
  existencia actual.
- Tras una venta, la existencia mostrada se actualiza con el dato que devuelve la API.
- El escáner se usa a través de `BarcodeScannerService`; las pantallas MUST NOT importar la librería de
  cámara directamente.
- El permiso de cámara se pide solo al abrir el escáner, explicando su uso; si se niega, se ofrece la
  búsqueda manual.
- Un código no reconocido muestra el aviso "prenda no encontrada" y permite volver a escanear.

### VII. Traspasos y notificaciones
- Un traspaso se solicita indicando prenda, talla, color, cantidad y sucursal de origen.
- La app impide cantidades menores o iguales a cero; la API valida la existencia del origen.
- Los estados son `SOLICITADO`, `APROBADO`, `RECHAZADO`, `EN_CAMINO` y `RECIBIDO`; la app solo los
  muestra, el cambio de estado lo hace la API.
- El empleado ve únicamente sus propias solicitudes y recibe aviso cuando el estado cambia.
- El mecanismo de aviso (dentro de la app o push) se define en la fase de planeación; si requiere un
  servicio externo, MUST justificarse y documentarse.

### VIII. Manejo de errores y estados
- Toda pantalla que consulta datos maneja tres estados visibles: cargando, con datos y error.
- Los errores de red muestran un mensaje claro y un botón para reintentar.
- Nunca se muestran stack traces, códigos internos ni detalles técnicos al usuario.
- Sin modo sin conexión: si no hay internet se muestra un aviso y se bloquean las acciones que modifican
  datos.
- Se evita el doble envío deshabilitando el botón mientras una operación está en curso.

### IX. Interfaz y experiencia de usuario
- La interfaz es sencilla y rápida en piso de venta; una consulta de stock se hace en pocos pasos (buscar
  o escanear, ver la ficha).
- Botones grandes y textos legibles, pensados para uso con una mano.
- Todos los textos están en español, con tildes y signos de apertura correctos.
- Colores y componentes salen del tema central (`core/theme`); MUST NOT escribirse colores sueltos en las
  pantallas.
- La existencia baja o agotada se distingue visualmente sin depender solo del color.
- La app respeta la preferencia del sistema de reducir animaciones.

### X. Diseño visual y animaciones
- Estética oscura con glassmorphism discreto (sección 12 de `docs/project-context.md`).
- Paleta: fondo degradado `#1b1035` a `#3a1561`; acentos rosa `#ff5fa2`, violeta `#8b5cf6`, cian
  `#38d6e8` y ámbar `#ffb86b`.
- Las animaciones son suaves y breves; no retrasan la búsqueda, el escaneo ni el descuento de stock.
- El diseño se ve bien en pantallas pequeñas y grandes, en vertical.
- La estética MUST NOT alterar la lógica, las llamadas a la API ni el manejo de sesión.

### XI. Pruebas (NO NEGOCIABLE)
- Los ViewModels se prueban sin interfaz y con repositorios simulados.
- Las reglas mínimas de la app (validación de cantidades, manejo de errores 401, 403 y 409) MUST tener
  pruebas.
- Cada sprint se prueba en al menos un dispositivo físico o emulador Android.

## Restricciones técnicas y alcance excluido

Quedan fuera de alcance y MUST NOT implementarse en la app móvil:

1. Control de asistencia y geolocalización.
2. Precios, cobros, facturación y totales de venta.
3. Integración con punto de venta.
4. Modo sin conexión.
5. Gestión de usuarios, reportes y alta de prendas (funciones de la web).
6. Funcionalidades para clientes finales.

No se suben contraseñas, llaves ni archivos `.env`; la dirección de la API se configura por entorno.

## Flujo de desarrollo y pruebas

- Gitflow: ramas `feature/mobile-*` desde `develop`; Pull Request con al menos 1 aprobación; sin push
  directo a `main` ni `develop`.
- Commits en formato Conventional Commits con la descripción en español.
- Al cerrar cada sprint se genera un APK instalable para la dueña.
- Una historia está "hecha" cuando: está integrada en `develop` mediante Pull Request revisado por otra
  persona, funciona con la API (o con el repositorio simulado si aún no está disponible), tiene evidencia
  para la bitácora y cumple la regla de negocio asociada.

## Gobernanza

Esta constitución prevalece sobre otras prácticas del proyecto. Si una historia de usuario parece
contradecirla, se MUST señalar la contradicción y solicitar una decisión antes de implementarla.

- **Enmiendas:** cualquier cambio se documenta, se refleja primero en `docs/reglas.md` y se aprueba
  mediante Pull Request revisado por otra persona.
- **Versionado (semántico):** MAYOR por eliminar o redefinir principios de forma incompatible; MENOR por
  agregar principios o ampliar guía de forma material; PARCHE por aclaraciones y correcciones de
  redacción.
- **Cumplimiento:** toda revisión de Pull Request y todo `/speckit.plan` verifican el cumplimiento de
  estos principios; la complejidad adicional se justifica por escrito.
- **Guía de trabajo:** `CLAUDE.md`, `docs/project-context.md` y `docs/reglas.md`.

**Versión**: 1.0.0 | **Ratificada**: 2026-11-20 | **Última enmienda**: 2026-11-20
