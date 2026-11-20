// Cliente de la API de administracion de Keycloak (crear/desactivar usuarios).
const { keycloak } = require('../config/env');
const { AppError } = require('../errors');

const base = keycloak.internalUrl;
const realmUrl = `${base}/admin/realms/${keycloak.realm}`;

async function adminToken() {
  const res = await fetch(`${base}/realms/master/protocol/openid-connect/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'password',
      client_id: 'admin-cli',
      username: keycloak.adminUser,
      password: keycloak.adminPassword,
    }),
  });
  if (!res.ok) throw new AppError(502, 'KEYCLOAK_NO_DISPONIBLE', 'No se pudo autenticar con Keycloak');
  return (await res.json()).access_token;
}

async function call(token, path, options = {}) {
  const res = await fetch(`${realmUrl}${path}`, {
    ...options,
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', ...(options.headers || {}) },
  });
  return res;
}

module.exports = {
  /** Crea el usuario en Keycloak con contrasena y rol. Devuelve su id (UUID). */
  async crearUsuario({ username, email, nombre, password, rol }) {
    const token = await adminToken();
    const [firstName, ...resto] = nombre.trim().split(' ');
    const res = await call(token, '/users', {
      method: 'POST',
      body: JSON.stringify({
        username, email, firstName, lastName: resto.join(' ') || '-',
        enabled: true, emailVerified: true,
        credentials: [{ type: 'password', value: password, temporary: false }],
      }),
    });
    if (res.status === 409) throw new AppError(409, 'USUARIO_DUPLICADO', 'Ya existe ese usuario o correo en Keycloak');
    if (!res.ok) throw new AppError(502, 'KEYCLOAK_ERROR', `Keycloak respondio ${res.status}`);

    const id = res.headers.get('location').split('/').pop();
    const rolRes = await call(token, `/roles/${rol}`);
    const rolRep = await rolRes.json();
    await call(token, `/users/${id}/role-mappings/realm`, { method: 'POST', body: JSON.stringify([rolRep]) });
    return id;
  },

  async cambiarRol(idKeycloak, rolNuevo, rolAnterior) {
    const token = await adminToken();
    const nuevo = await (await call(token, `/roles/${rolNuevo}`)).json();
    const viejo = await (await call(token, `/roles/${rolAnterior}`)).json();
    await call(token, `/users/${idKeycloak}/role-mappings/realm`, { method: 'DELETE', body: JSON.stringify([viejo]) });
    await call(token, `/users/${idKeycloak}/role-mappings/realm`, { method: 'POST', body: JSON.stringify([nuevo]) });
  },

  async setHabilitado(idKeycloak, enabled) {
    const token = await adminToken();
    await call(token, `/users/${idKeycloak}`, { method: 'PUT', body: JSON.stringify({ enabled }) });
  },
};
