const { pool } = require('../db/pool');

// Todas las funciones aceptan un `db` opcional (pool o client de una transaccion).
module.exports = {
  /** Existencias por prenda en todas las sucursales (matriz de MOV-02). */
  async matrizPorPrenda(idPrenda, db = pool) {
    const { rows } = await db.query(
      `SELECT i.id, i.id_sucursal, s.nombre AS sucursal, i.talla, i.color, i.cantidad
       FROM inventario_sucursal i JOIN sucursales s ON s.id = i.id_sucursal
       WHERE i.id_prenda = $1 ORDER BY s.id, i.talla, i.color`,
      [idPrenda]
    );
    return rows;
  },
  async list({ sucursalId, prendaId, bajoUmbral }, db = pool) {
    const params = [];
    const where = [];
    if (sucursalId) { params.push(sucursalId); where.push(`i.id_sucursal = $${params.length}`); }
    if (prendaId) { params.push(prendaId); where.push(`i.id_prenda = $${params.length}`); }
    if (bajoUmbral) where.push('i.cantidad <= p.umbral_alerta');
    const { rows } = await db.query(
      `SELECT i.id, i.id_prenda, p.codigo_barras, p.descripcion, i.id_sucursal, s.nombre AS sucursal,
              i.talla, i.color, i.cantidad, p.umbral_alerta
       FROM inventario_sucursal i
       JOIN prendas p ON p.id = i.id_prenda
       JOIN sucursales s ON s.id = i.id_sucursal
       ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
       ORDER BY p.descripcion, s.id, i.talla`,
      params
    );
    return rows;
  },
  /** Bloquea la fila (FOR UPDATE) para que dos ventas simultaneas no se pisen. */
  async lockById(id, db) {
    const { rows } = await db.query('SELECT * FROM inventario_sucursal WHERE id = $1 FOR UPDATE', [id]);
    return rows[0];
  },
  async lockByClave({ idPrenda, idSucursal, talla, color }, db) {
    const { rows } = await db.query(
      'SELECT * FROM inventario_sucursal WHERE id_prenda=$1 AND id_sucursal=$2 AND talla=$3 AND color=$4 FOR UPDATE',
      [idPrenda, idSucursal, talla, color]
    );
    return rows[0];
  },
  async insert({ idPrenda, idSucursal, talla, color, cantidad }, db) {
    const { rows } = await db.query(
      `INSERT INTO inventario_sucursal (id_prenda, id_sucursal, talla, color, cantidad)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [idPrenda, idSucursal, talla, color, cantidad]
    );
    return rows[0];
  },
  async setCantidad(id, cantidad, db) {
    const { rows } = await db.query('UPDATE inventario_sucursal SET cantidad = $2 WHERE id = $1 RETURNING *', [id, cantidad]);
    return rows[0];
  },
  async registrarAuditoria({ idInventario, tipo, anterior, nueva, idUsuario }, db) {
    await db.query(
      `INSERT INTO historial_auditoria_inventario (id_inventario, tipo_movimiento, cantidad_anterior, cantidad_nueva, id_usuario)
       VALUES ($1,$2,$3,$4,$5)`,
      [idInventario, tipo, anterior, nueva, idUsuario]
    );
  },
  async historial(idInventario, db = pool) {
    const { rows } = await db.query(
      `SELECT h.id, h.tipo_movimiento, h.cantidad_anterior, h.cantidad_nueva, u.nombre AS usuario, h."timestamp"
       FROM historial_auditoria_inventario h LEFT JOIN usuarios u ON u.id = h.id_usuario
       WHERE h.id_inventario = $1 ORDER BY h."timestamp" DESC LIMIT 100`,
      [idInventario]
    );
    return rows;
  },
};
