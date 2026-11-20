// CAPA DE DATOS: unico lugar con SQL de usuarios.
const { pool } = require('../db/pool');

const COLS = 'id, nombre, email, id_keycloak, rol, id_sucursal_asignada, activo, creado_en';

module.exports = {
  async findByKeycloakId(kcId) {
    const { rows } = await pool.query(`SELECT ${COLS} FROM usuarios WHERE id_keycloak = $1`, [kcId]);
    return rows[0];
  },
  async findById(id) {
    const { rows } = await pool.query(`SELECT ${COLS} FROM usuarios WHERE id = $1`, [id]);
    return rows[0];
  },
  async list({ sucursalId, activo } = {}) {
    const where = [];
    const params = [];
    if (sucursalId) { params.push(sucursalId); where.push(`id_sucursal_asignada = $${params.length}`); }
    if (activo !== undefined) { params.push(activo); where.push(`activo = $${params.length}`); }
    const sql = `SELECT ${COLS} FROM usuarios ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY id`;
    const { rows } = await pool.query(sql, params);
    return rows;
  },
  async create({ nombre, email, idKeycloak, rol, sucursalId }) {
    const { rows } = await pool.query(
      `INSERT INTO usuarios (nombre, email, id_keycloak, rol, id_sucursal_asignada)
       VALUES ($1,$2,$3,$4,$5) RETURNING ${COLS}`,
      [nombre, email, idKeycloak, rol, sucursalId ?? null]
    );
    return rows[0];
  },
  async update(id, { nombre, email, rol, sucursalId }) {
    const { rows } = await pool.query(
      `UPDATE usuarios SET nombre = COALESCE($2, nombre), email = COALESCE($3, email),
              rol = COALESCE($4, rol), id_sucursal_asignada = COALESCE($5, id_sucursal_asignada)
       WHERE id = $1 RETURNING ${COLS}`,
      [id, nombre ?? null, email ?? null, rol ?? null, sucursalId ?? null]
    );
    return rows[0];
  },
  async setActivo(id, activo) {
    const { rows } = await pool.query(`UPDATE usuarios SET activo = $2 WHERE id = $1 RETURNING ${COLS}`, [id, activo]);
    return rows[0];
  },
};
