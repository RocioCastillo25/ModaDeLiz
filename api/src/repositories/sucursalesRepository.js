const { pool } = require('../db/pool');

module.exports = {
  async list() {
    const { rows } = await pool.query('SELECT id, nombre, ubicacion FROM sucursales ORDER BY id');
    return rows;
  },
  async findById(id) {
    const { rows } = await pool.query('SELECT id, nombre, ubicacion FROM sucursales WHERE id = $1', [id]);
    return rows[0];
  },
};
