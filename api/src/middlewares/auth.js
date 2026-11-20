// CAPA DE SEGURIDAD: valida el JWT emitido por Keycloak y carga al usuario.
const { createRemoteJWKSet, jwtVerify } = require('jose');
const { keycloak } = require('../config/env');
const usuariosRepo = require('../repositories/usuariosRepository');
const { AppError, forbidden } = require('../errors');

const ROLES = ['administrador', 'gerente', 'empleado'];

// Las llaves publicas se piden por la red interna de Docker y se cachean.
const jwks = createRemoteJWKSet(
  new URL(`${keycloak.internalUrl}/realms/${keycloak.realm}/protocol/openid-connect/certs`)
);

async function authenticate(req, _res, next) {
  try {
    const header = req.headers.authorization || '';
    if (!header.startsWith('Bearer ')) {
      throw new AppError(401, 'TOKEN_REQUERIDO', 'Falta el encabezado Authorization: Bearer <token>');
    }

    let payload;
    try {
      ({ payload } = await jwtVerify(header.slice(7), jwks, { issuer: keycloak.allowedIssuers }));
    } catch (e) {
      throw new AppError(401, 'TOKEN_INVALIDO', 'Token invalido o expirado');
    }

    const roles = payload.realm_access?.roles || [];
    const rol = ROLES.find((r) => roles.includes(r));
    if (!rol) throw forbidden('El token no tiene un rol de CheckLizz');

    const usuario = await usuariosRepo.findByKeycloakId(payload.sub);
    if (!usuario || !usuario.activo) {
      throw new AppError(403, 'USUARIO_NO_REGISTRADO', 'Usuario no registrado o desactivado');
    }

    req.user = {
      id: usuario.id,
      nombre: usuario.nombre,
      rol,
      sucursalId: usuario.id_sucursal_asignada,
      keycloakId: payload.sub,
    };
    next();
  } catch (err) {
    next(err);
  }
}

/** Permite el paso solo a los roles indicados. Uso: requireRole('administrador', 'gerente') */
const requireRole = (...permitidos) => (req, _res, next) =>
  permitidos.includes(req.user.rol) ? next() : next(forbidden());

module.exports = { authenticate, requireRole };
