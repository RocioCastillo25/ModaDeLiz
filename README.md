# Moda de Liz

Sistema de gestión de inventario multi-sucursal y asistencia de empleados para **Moda de Liz**.

## Estructura del repositorio

- `.github/` — Plantillas de Pull Requests e Issues.
- `docker-compose.yml` — Orquestación de servicios (actualizado en coordinación con el equipo).
- `.env.example` — Plantilla de variables de entorno requeridas.

## Flujo de trabajo (GitFlow)

1. Parte siempre de `develop` actualizada (`git checkout develop && git pull origin develop`).
2. Crea una rama descriptiva (`feat/...`, `fix/...`, `chore/...`).
3. Abre un Pull Request hacia `develop` usando la plantilla correspondiente.
