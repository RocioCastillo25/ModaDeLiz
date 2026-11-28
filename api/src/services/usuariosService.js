// CAPA DE NEGOCIO: reglas de usuarios y roles.
const repo = require('../repositories/usuariosRepository');
const sucursalesRepo = require('../repositories/sucursalesRepository');
const kc = require('./keycloakAdmin');
const { notFound, AppError } = require('../errors');

async function validarSucursal(rol, sucursalId) {
  if (rol !== 'administrador' && !sucursalId) {
    throw new AppError(400, 'SUCURSAL_REQUERIDA', 'Gerente y empleado necesitan una sucursal');
  }
  if (sucursalId && !(await sucursalesRepo.findById(sucursalId))) throw notFound('Sucursal');
}

module.exports = {
  list: (filtros) => repo.list(filtros),

  async get(id) {
    const u = await repo.findById(id);
    if (!u) throw notFound('Usuario');
    return u;
  },

  async crear({ nombre, email, username, password, rol, sucursalId }) {
    await validarSucursal(rol, sucursalId);
    const idKeycloak = await kc.crearUsuario({ username, email, nombre, password, rol });
    return repo.create({ nombre, email, idKeycloak, rol, sucursalId });
  },

  async actualizar(id, datos) {
    const actual = await this.get(id);
    const rol = datos.rol ?? actual.rol;
    const sucursalId = datos.sucursalId ?? actual.id_sucursal_asignada;
    await validarSucursal(rol, sucursalId);
    if (datos.rol && datos.rol !== actual.rol) await kc.cambiarRol(actual.id_keycloak, datos.rol, actual.rol);
    return repo.update(id, datos);
  },

  async setActivo(id, activo, solicitante) {
    const actual = await this.get(id);
    if (!activo && actual.id === solicitante.id) {
      throw new AppError(400, 'AUTODESACTIVACION', 'No puedes desactivar tu propia cuenta');
    }
    await kc.setHabilitado(actual.id_keycloak, activo);
    return repo.setActivo(id, activo);
  },
};
