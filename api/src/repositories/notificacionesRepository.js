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

  /** Avisos de un usuario, mas recientes primero. */
  async listar(idUsuario, { soloNoLeidas, limite }, db = pool) {
    const { rows } = await db.query(
      `SELECT id, id_traspaso, tipo, mensaje, leida, creada_en
       FROM notificaciones
       WHERE id_usuario = $1 ${soloNoLeidas ? 'AND leida = FALSE' : ''}
       ORDER BY creada_en DESC, id DESC LIMIT $2`,
      [idUsuario, limite]
    );
    return rows;
  },

  async contarNoLeidas(idUsuario, db = pool) {
    const { rows } = await db.query(
      'SELECT count(*)::int AS no_leidas FROM notificaciones WHERE id_usuario = $1 AND leida = FALSE',
      [idUsuario]
    );
    return rows[0].no_leidas;
  },

  /** Marca un aviso como leido solo si es del usuario; devuelve undefined si no existe o es de otro. */
  async marcarLeida(id, idUsuario, db = pool) {
    const { rows } = await db.query(
      `UPDATE notificaciones SET leida = TRUE WHERE id = $1 AND id_usuario = $2
       RETURNING id, id_traspaso, tipo, mensaje, leida, creada_en`,
      [id, idUsuario]
    );
    return rows[0];
  },

  async marcarTodasLeidas(idUsuario, db = pool) {
    const { rowCount } = await db.query(
      'UPDATE notificaciones SET leida = TRUE WHERE id_usuario = $1 AND leida = FALSE',
      [idUsuario]
    );
    return rowCount;
  },
};
