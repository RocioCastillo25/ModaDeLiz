// Error de negocio con codigo HTTP y un codigo legible por maquina.
class AppError extends Error {
  constructor(status, code, message) {
    super(message || code);
    this.status = status;
    this.code = code;
  }
}

const notFound = (what = 'Recurso') => new AppError(404, 'NO_ENCONTRADO', `${what} no encontrado`);
const forbidden = (msg = 'No tienes permiso para esta accion') => new AppError(403, 'PROHIBIDO', msg);
const conflict = (code, msg) => new AppError(409, code, msg);

module.exports = { AppError, notFound, forbidden, conflict };
