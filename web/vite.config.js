import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// El puerto 5173 está registrado como redirect URI del cliente checklizz-app en Keycloak.
export default defineConfig({
  plugins: [react()],
  server: { port: 5173, strictPort: true },
});
