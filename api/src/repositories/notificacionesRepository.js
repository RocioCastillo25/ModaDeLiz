// CAPA DE DATOS: unico lugar con SQL de notificaciones.
const { pool } = require('../db/pool');

// Todas las funciones aceptan un `db` opcional (pool o client de una transaccion).
module.exports = {
  /** Gerentes activos de una sucursal: son quienes deben enterarse de una solicitud nueva. */
  async gerentesActivos(idSucursal, db = pool) {
    const { rows } = await db.query(
      `SELECT id FROM usuarios WHERE rol = 'gerente' AND activo = TRUE AND id_sucursal_asignada = $1`,
      [idSucursal]
    );
    return rows;
  },

  async crear({ idUsuario, idTraspaso, tipo, mensaje }, db = pool) {
    const { rows } = await db.query(
      `INSERT INTO notificaciones (id_usuario, id_traspaso, tipo, mensaje)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [idUsuario, idTraspaso ?? null, tipo, mensaje]
    );
    return rows[0];
  },
};
