# Cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y [versionado semántico](https://semver.org/lang/es/).

## [0.1.0] · 27 de noviembre de 2026

Primera versión entregable: fundamentos, inventario base, página web de catálogo e inventario y búsqueda en la app móvil.

### Infraestructura
- `docker-compose.yml` con PostgreSQL 16, Keycloak 26 y la API; pgAdmin opcional con `--profile tools` (#6).
- Realm de Keycloak con los roles `administrador`, `gerente` y `empleado`, el cliente `checklizz-app` y usuarios de prueba (#6).
- Esquema relacional, datos semilla de las 5 sucursales y modelo relacional documentado (#2).
- Respaldo diario de la base con `pg_dump` a las 10:00 p. m. (RNF-08) (#45).

### API
- API REST con Express, validación de tokens JWT de Keycloak y permisos por rol y sucursal (#3).
- Prendas, inventario por prenda + sucursal + talla + color, ventas con bloqueo de fila y auditoría de cada cambio (#3).
- Traspasos entre sucursales: solicitud, consulta, cambio de estado con movimiento de stock y notificaciones (RF-06, RF-07) (#29, #30).
- Reportes de existencias, más vendidos y stock bajo, descargables en PDF y Excel (RF-13, RF-14, RF-15) (#32).
- Foto de prenda (JPG, PNG o WebP hasta 5 MB) (#45).
- Contrato `docs/openapi.yaml`.

### Página web
- Catálogo de prendas con búsqueda y ficha con existencias por sucursal; existencias con filtro de stock bajo (#38).
- Alta y edición de prendas (#39, #40).
- Carga inicial de inventario por filas y por CSV, en modos *Sumar* y *Reemplazar* (#41, #42).
- Inicio de sesión con Keycloak (PKCE) o modo demostración con datos simulados.

### App móvil
- Estructura MVVM, inyección de dependencias, tema visual e inicio de sesión con Keycloak y la API (#1, #5).
- Búsqueda de prendas con filtros, ficha con existencias en las 5 sucursales y renovación automática de la sesión (#46).

### Documentación y proceso
- Repositorio reestructurado con plantillas de Pull Request e issues; `main` y `develop` protegidas (#4).
- README sin el módulo de asistencia, que quedó fuera de alcance (#31).
- Documento técnico final: arquitectura, SOLID, patrones, GitFlow y Docker (#43).

### Limitaciones conocidas
- Escáner de códigos y descuento por venta en la app: pendientes (Sprint 2).
- Pantallas de traspasos y reportes en la web: pendientes (Sprints 3 y 4); la API ya los ofrece.
- La suma en la carga inicial no es atómica (ver documento técnico, sección 10).

[0.1.0]: https://github.com/RocioCastillo25/ModaDeLiz/releases/tag/v0.1.0
