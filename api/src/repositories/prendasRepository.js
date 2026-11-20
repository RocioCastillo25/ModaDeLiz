const { pool } = require('../db/pool');

const COLS = 'id, codigo_barras, descripcion, marca, categoria, temporada, foto_url, umbral_alerta, activa';

module.exports = {
  /** Busqueda universal (MOV-01): texto, codigo de barras, categoria, talla, color y sucursal. */
  async search({ q, codigo, categoria, talla, color, sucursalId }) {
    const params = [];
    const where = ['p.activa = TRUE'];
    const add = (sql, v) => { params.push(v); where.push(sql.replace('?', `$${params.length}`)); };

    if (codigo) add('p.codigo_barras = ?', codigo);
    if (q) {
      params.push(q);
      const n = params.length;
      where.push(`(p.descripcion ILIKE '%' || $${n} || '%' OR p.marca ILIKE '%' || $${n} || '%')`);
    }
    if (categoria) add('p.categoria ILIKE ?', categoria);

    const inv = [];
    if (talla) { params.push(talla); inv.push(`i.talla = $${params.length}`); }
    if (color) { params.push(color); inv.push(`i.color ILIKE $${params.length}`); }
    if (sucursalId) { params.push(sucursalId); inv.push(`i.id_sucursal = $${params.length}`); }
    if (inv.length) where.push(`EXISTS (SELECT 1 FROM inventario_sucursal i WHERE i.id_prenda = p.id AND ${inv.join(' AND ')})`);

    const { rows } = await pool.query(
      `SELECT p.id, p.codigo_barras, p.descripcion, p.marca, p.categoria, p.temporada, p.foto_url, p.umbral_alerta,
              COALESCE((SELECT SUM(cantidad) FROM inventario_sucursal WHERE id_prenda = p.id), 0)::int AS existencia_total
       FROM prendas p WHERE ${where.join(' AND ')} ORDER BY p.descripcion LIMIT 100`,
      params
    );
    return rows;
  },
  async findById(id) {
    const { rows } = await pool.query(`SELECT ${COLS} FROM prendas WHERE id = $1`, [id]);
    return rows[0];
  },
  async findByCodigo(codigo) {
    const { rows } = await pool.query(`SELECT ${COLS} FROM prendas WHERE codigo_barras = $1`, [codigo]);
    return rows[0];
  },
  async create(p) {
    const { rows } = await pool.query(
      `INSERT INTO prendas (codigo_barras, descripcion, marca, categoria, temporada, foto_url, umbral_alerta)
       VALUES ($1,$2,$3,$4,$5,$6,COALESCE($7,2)) RETURNING ${COLS}`,
      [p.codigo_barras, p.descripcion, p.marca ?? null, p.categoria ?? null, p.temporada ?? null, p.foto_url ?? null, p.umbral_alerta ?? null]
    );
    return rows[0];
  },
  async update(id, p) {
    const { rows } = await pool.query(
      `UPDATE prendas SET descripcion = COALESCE($2, descripcion), marca = COALESCE($3, marca),
              categoria = COALESCE($4, categoria), temporada = COALESCE($5, temporada),
              foto_url = COALESCE($6, foto_url), umbral_alerta = COALESCE($7, umbral_alerta)
       WHERE id = $1 RETURNING ${COLS}`,
      [id, p.descripcion ?? null, p.marca ?? null, p.categoria ?? null, p.temporada ?? null, p.foto_url ?? null, p.umbral_alerta ?? null]
    );
    return rows[0];
  },
  async setActiva(id, activa) {
    const { rows } = await pool.query(`UPDATE prendas SET activa = $2 WHERE id = $1 RETURNING ${COLS}`, [id, activa]);
    return rows[0];
  },
};
