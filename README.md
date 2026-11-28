# Moda de Liz · CheckLizz

Sistema de **inventario conectado y traspasos entre sucursales** para **Moda de Liz**, tienda de ropa con 5 sucursales (Huauchinango, Zacatlán, Chignahuapan, Ahuazotepec y Xicotepec).

## Componentes

| Carpeta | Qué es | Tecnología |
|---|---|---|
| `api/` | API REST con las reglas de negocio | Node.js + Express + PostgreSQL |
| `mobile/` | App para empleados y gerentes | Flutter |
| `web/` | Página para gerentes y administradora (catálogo e inventario) | React + Vite |
| `infra/` | Esquema de base de datos y configuración de Keycloak | PostgreSQL, Keycloak |
| `docs/` | Contrato `openapi.yaml`, bitácora y documentación técnica | Markdown |

## Cómo levantarlo

```bash
cp .env.example .env
docker compose up -d --build
```

- API: http://localhost:3000
- Keycloak: http://localhost:8080
- pgAdmin (opcional): `docker compose --profile tools up -d` → http://localhost:5050

## Flujo de trabajo (GitFlow)

1. Parte siempre de `develop` actualizada (`git checkout develop && git pull origin develop`).
2. Crea una rama descriptiva (`feature/...`, `fix/...`, `chore/...`, `docs/...`).
3. Abre un Pull Request hacia `develop` usando la plantilla y pide al menos una revisión.
4. Las versiones se publican fusionando `develop` en `main` y etiquetando (`v0.1.0`, `v0.2.0`, …).

Commits en formato [Conventional Commits](https://www.conventionalcommits.org/es/) con la descripción en español.
