// Sesión y composición de dependencias (inyección por contexto):
// decide qué repositorio usa toda la app (real o simulado) y quién es el usuario.
import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import Keycloak from 'keycloak-js';
import { config } from '../config';
import { createHttpClient } from '../api/httpClient';
import { createApiRepository } from '../repositories/apiRepository';
import { createMockRepository } from '../repositories/mockRepository';

const AuthContext = createContext(null);

export const useAuth = () => useContext(AuthContext);
export const useRepo = () => useContext(AuthContext).repo;

const USUARIOS_DEMO = {
  administrador: { id: 1, nombre: 'Dueña Moda de Liz', rol: 'administrador', sucursalId: null },
  gerente: { id: 2, nombre: 'Gerente Huauchinango', rol: 'gerente', sucursalId: 1 },
};

let keycloak; // una sola instancia por pestaña (keycloak-js no admite inicializarse dos veces)

export function AuthProvider({ children }) {
  const [estado, setEstado] = useState({ cargando: true });

  useEffect(() => {
    if (config.useMock) {
      setEstado({ cargando: false, demo: true });
      return;
    }
    keycloak ??= new Keycloak(config.keycloak);
    keycloak
      .init({ onLoad: 'login-required', pkceMethod: 'S256', checkLoginIframe: false })
      .then(async () => {
        const http = createHttpClient({
          baseUrl: config.apiUrl,
          getToken: async () => {
            await keycloak.updateToken(30).catch(() => keycloak.login());
            return keycloak.token;
          },
        });
        const repo = createApiRepository(http);
        const usuario = await repo.getMe();
        setEstado({ cargando: false, usuario, repo });
      })
      .catch((e) => setEstado({ cargando: false, error: e?.message || 'No se pudo iniciar sesión.' }));
  }, []);

  const valor = useMemo(() => ({
    ...estado,
    entrarDemo: (rol) => {
      const usuario = USUARIOS_DEMO[rol];
      setEstado({ cargando: false, demo: true, usuario, repo: createMockRepository(usuario) });
    },
    logout: () => {
      if (config.useMock) setEstado({ cargando: false, demo: true });
      else keycloak.logout({ redirectUri: window.location.origin });
    },
  }), [estado]);

  return <AuthContext.Provider value={valor}>{children}</AuthContext.Provider>;
}
