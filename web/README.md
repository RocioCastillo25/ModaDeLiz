# CheckLizz · Web

Página para la **administradora** y los **gerentes**: catálogo de prendas, existencias por sucursal, alta y edición de productos y carga inicial de inventario.

## Cómo correrla

```bash
cd web
npm install
cp .env.example .env   # opcional
npm run dev            # http://localhost:5173
```

- `VITE_USE_MOCK=true` (por defecto): datos simulados, sin Docker. Entras eligiendo un rol.
- `VITE_USE_MOCK=false`: inicia sesión con Keycloak y usa la API (`docker compose up -d` en la raíz).

## Estructura

```
src/
├── config.js            # variables de entorno
├── api/httpClient.js    # fetch + token Bearer + traducción de errores
├── auth/AuthProvider.jsx# sesión (Keycloak o demo) e inyección del repositorio
├── repositories/        # apiRepository (real) y mockRepository (simulado), misma interfaz
├── components/          # Layout, estados (cargando/vacío/error), indicadores
└── pages/               # una pantalla por archivo
```

Las páginas nunca llaman a `fetch`: piden los datos al repositorio que reciben por contexto.
