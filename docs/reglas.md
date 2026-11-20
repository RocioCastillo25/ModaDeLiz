# Reglas y constitución técnica del proyecto

Estas reglas son obligatorias para todo el desarrollo de la app móvil. Si una historia de usuario parece contradecirlas, se debe señalar la contradicción y solicitar una decisión antes de implementarla.

## I. Arquitectura

1. La app móvil vive en `mobile/` y se desarrolla con Flutter y Dart.
2. La app consume únicamente la API REST; nunca se conecta directamente a PostgreSQL ni a Keycloak para operaciones de negocio.
3. Las reglas de negocio viven en la API. La app valida lo mínimo para dar buena experiencia (campos vacíos, cantidades positivas), pero no duplica reglas como el límite de existencia.
4. No modificar `api/`, `infra/` ni `web/`: pertenecen a otros integrantes.
5. No introducir paquetes ni servicios externos nuevos sin justificar su necesidad y documentar el cambio.
6. La app debe funcionar en Android y en iPhone (código base único).

## II. Patrón MVVM

1. Usar MVVM con `ChangeNotifier`:
   - **View:** widgets y pantallas. Solo muestran estado y envían acciones del usuario.
   - **ViewModel:** guarda el estado de la pantalla (cargando, datos, error) y ejecuta la lógica de presentación.
   - **Model:** clases de datos (prenda, inventario, traspaso, usuario).
   - **Repository:** oculta al ViewModel de dónde vienen los datos.
   - **Service:** comunicación de bajo nivel (cliente HTTP, almacenamiento seguro del token, escáner).
2. Una View nunca llama a la API ni a un Service directamente.
3. Un ViewModel nunca importa `package:flutter/material.dart` ni conoce widgets.
4. Cada pantalla tiene su propio ViewModel dentro de `features/<nombre>/`.

## III. Estructura de carpetas

```
mobile/lib/
├── main.dart
├── core/
│   ├── di/          # registro de dependencias (get_it)
│   ├── network/     # ApiClient e interceptores
│   ├── security/    # token JWT y almacenamiento seguro
│   └── theme/       # colores, tipografía, tema
├── data/
│   ├── models/      # Prenda, Inventario, Traspaso
│   ├── dto/         # respuestas crudas de la API
│   ├── repositories/
│   └── services/    # BarcodeScannerService, AuthService
├── features/        # auth, busqueda, ficha_prenda, venta, traspasos, notificaciones
└── shared/          # widgets reutilizables
```

## IV. Patrones de diseño

Aplicar solo donde resuelven un problema concreto:

1. **Singleton:** `ApiClient`, registrado en `get_it` como singleton perezoso (no como variable global).
2. **Factory:** constructor `fromJson` en cada modelo.
3. **Adapter:** conversión de DTO a modelo y envoltura de la librería de escáner detrás de la interfaz propia `BarcodeScannerService`.
4. **Decorator:** interceptor del cliente HTTP que agrega `Authorization: Bearer <token>` a cada petición.
5. **Observer:** ViewModels con `ChangeNotifier` y widgets que reaccionan al cambio de estado.
6. **Repository:** único punto de acceso a datos para los ViewModels.

## V. Inyección de dependencias

1. Usar `get_it` como contenedor. Las dependencias llegan por constructor: `ApiClient` → Repositories → ViewModels.
2. Ninguna clase crea por sí misma sus dependencias.
3. Toda interfaz de repositorio tiene una implementación real (contra la API) y una simulada (datos de ejemplo), intercambiables desde el registro de dependencias. Esto permite avanzar mientras la API no esté lista.

## VI. Autenticación y sesión

1. El usuario inicia sesión con usuario y contraseña; el token JWT lo emite Keycloak.
2. Guardar el token únicamente en almacenamiento seguro del dispositivo (`flutter_secure_storage` o equivalente).
3. No guardar la contraseña del usuario en el dispositivo.
4. Mostrar un mensaje genérico ante credenciales incorrectas, sin revelar si el usuario existe.
5. Cuando la API responda 401, intentar renovar la sesión; si no es posible, volver al inicio de sesión.
6. Cuando la API responda 403, mostrar un aviso de falta de permisos sin cerrar la sesión.
7. Cerrar sesión borra el token y limpia el estado de los ViewModels.
8. Una cuenta desactivada no puede iniciar sesión.

## VII. Roles y permisos

1. Los roles son `ROLE_ADMIN`, `ROLE_ENCARGADO` y `ROLE_VENDEDOR`; se leen del token.
2. La app muestra u oculta opciones según el rol para mejorar la experiencia, pero la API es quien decide si una operación procede.
3. Un empleado solo puede descontar stock de su propia sucursal; la sucursal se toma del usuario autenticado, nunca de un campo editable.

## VIII. Inventario, ventas y escáner

1. La consulta de inventario muestra las 5 sucursales.
2. La app solo descuenta **cantidades de piezas**. No muestra ni captura precios, cobros ni descuentos comerciales.
3. La cantidad a descontar debe ser un entero positivo; la app impide enviar valores inválidos, y la API valida que la existencia no quede negativa.
4. Si la API rechaza una venta por existencia insuficiente, la app muestra un mensaje claro con la existencia actual.
5. Después de una venta, la existencia mostrada se actualiza con el dato que devuelve la API.
6. El escáner se usa a través de `BarcodeScannerService`; las pantallas nunca importan la librería de cámara directamente.
7. Pedir el permiso de cámara solo cuando se abre el escáner, explicando su uso; si se niega, ofrecer la búsqueda manual.
8. Un código no reconocido muestra el aviso "prenda no encontrada" y permite volver a escanear.

## IX. Traspasos y notificaciones

1. Un traspaso se solicita indicando prenda, talla, color, cantidad y sucursal de origen.
2. La app impide enviar cantidades menores o iguales a cero; la API valida la existencia del origen.
3. Los estados de un traspaso son `SOLICITADO`, `APROBADO`, `RECHAZADO`, `EN_CAMINO` y `RECIBIDO`; la app solo los muestra, el cambio de estado lo hace la API.
4. El empleado ve únicamente sus propias solicitudes.
5. El empleado recibe aviso cuando el estado de su traspaso cambia. El mecanismo (dentro de la app o push) se define en la fase de planeación; si se requiere un servicio externo, debe justificarse y documentarse.

## X. Manejo de errores y estados

1. Toda pantalla que consulta datos maneja tres estados visibles: cargando, con datos y error.
2. Los errores de red muestran un mensaje claro y un botón para reintentar.
3. Nunca mostrar stack traces, códigos internos ni detalles técnicos al usuario.
4. Como no hay modo sin conexión, si no hay internet se muestra un aviso y se bloquean las acciones que modifican datos.
5. Evitar el doble envío: deshabilitar el botón mientras una operación está en curso.

## XI. Interfaz y experiencia de usuario

1. La interfaz debe ser sencilla y rápida de usar en piso de venta, con el cliente enfrente.
2. Una consulta de stock debe poder hacerse en pocos pasos: buscar o escanear, ver la ficha.
3. Botones grandes y textos legibles, pensados para uso con una mano.
4. Todos los textos de la interfaz están en español, con tildes y signos de apertura correctos.
5. Los colores y componentes salen del tema central (`core/theme`); no escribir colores sueltos en las pantallas.
6. La existencia baja o agotada se distingue visualmente, sin depender solo del color.
7. La app respeta la preferencia del sistema de reducir animaciones.

## XII. Pruebas y proceso de desarrollo

1. Los ViewModels se prueban sin interfaz y con repositorios simulados.
2. Las reglas mínimas de la app (validación de cantidades, manejo de errores 401, 403 y 409) tienen pruebas.
3. Cada sprint se prueba en al menos un dispositivo físico o emulador Android.
4. Al cerrar cada sprint se genera un APK instalable para la dueña.
5. Una historia está "hecha" cuando: está integrada en `develop` mediante Pull Request revisado por otra persona, funciona con la API (o con el repositorio simulado si aún no está disponible), tiene evidencia para la bitácora y cumple la regla de negocio asociada.
6. Seguir Gitflow: ramas `feature/mobile-*` desde `develop`, Pull Request con al menos 1 aprobación, sin push directo a `main` ni `develop`.
7. Commits en formato Conventional Commits con la descripción en español.
8. No subir contraseñas, llaves ni archivos `.env`; la dirección de la API se configura por entorno.

## XIII. Alcance excluido

1. Control de asistencia y geolocalización.
2. Precios, cobros, facturación y totales de venta.
3. Integración con punto de venta.
4. Modo sin conexión.
5. Gestión de usuarios, reportes y alta de prendas: son funciones de la web.
6. Funcionalidades para clientes finales.

## XIV. Diseño visual y animaciones

1. Estética clara con glassmorphism discreto en rosa pastel y blanco, con el logo de Moda D' Liz, según la sección 12 de `docs/project-context.md`.
2. Paleta: fondo degradado de `#ffd9ea` a `#ffffff`; acentos rosa fuerte `#d6338a`, rosa pastel `#f9a8d4`, violeta `#7c5ce0` y ámbar oscuro `#a86400`; texto `#3a1030`.
3. Las animaciones son suaves y breves; no retrasan la búsqueda, el escaneo ni el descuento de stock.
4. El diseño debe verse bien en pantallas pequeñas y grandes, en vertical.
5. La estética no debe alterar la lógica, las llamadas a la API ni el manejo de sesión.
