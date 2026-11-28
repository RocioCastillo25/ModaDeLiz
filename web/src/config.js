// Configuración centralizada: todo viene de variables de entorno de Vite.
const env = import.meta.env;

export const config = {
  useMock: (env.VITE_USE_MOCK ?? 'true') === 'true',
  apiUrl: env.VITE_API_URL || 'http://localhost:3000/api/v1',
  keycloak: {
    url: env.VITE_KEYCLOAK_URL || 'http://localhost:8080',
    realm: env.VITE_KEYCLOAK_REALM || 'checklizz',
    clientId: env.VITE_KEYCLOAK_CLIENT_ID || 'checklizz-app',
  },
};
