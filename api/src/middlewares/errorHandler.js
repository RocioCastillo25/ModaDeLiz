const { ZodError } = require('zod');

/** Envuelve controladores async para que sus errores lleguen al errorHandler. */
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

// eslint-disable-next-line no-unused-vars
function errorHandler(err, _req, res, _next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: 'DATOS_INVALIDOS',
      mensaje: 'La peticion tiene datos invalidos',
      detalles: err.issues.map((i) => ({ campo: i.path.join('.'), mensaje: i.message })),
    });
  }
  if (err.status) {
    return res.status(err.status).json({ error: err.code, mensaje: err.message });
  }
  // Errores de PostgreSQL con significado de negocio
  if (err.code === '23505') return res.status(409).json({ error: 'DUPLICADO', mensaje: 'Ya existe un registro con esos datos' });
  if (err.code === '23503') return res.status(409).json({ error: 'REFERENCIA_INVALIDA', mensaje: 'Referencia a un registro que no existe' });
  if (err.code === '23514') return res.status(409).json({ error: 'REGLA_VIOLADA', mensaje: 'La operacion viola una regla de la base de datos' });

  console.error(err);
  res.status(500).json({ error: 'ERROR_INTERNO', mensaje: 'Error interno del servidor' });
}

module.exports = { wrap, errorHandler };
