// CAPA DE DATOS: unico lugar con el SQL de los reportes (solo lecturas).
const { pool } = require('../db/pool');

// Las sucursales estan en Puebla: un dia de venta se cuenta en hora local, no en UTC.
const ZONA_HORARIA = 'America/Mexico_City';

module.exports = {
  ZONA_HORARIA,

  /** Piezas con existencia (cantidad > 0) de prendas activas, con o sin filtro de sucursal. */
  async existencias({ sucursalId }, db = pool) {
    const params = [];
    let filtro = '';
    if (sucursalId) { params.push(sucursalId); filtro = 'AND i.id_sucursal = $1'; }
    const { rows } = await db.query(
      `SELECT i.id_sucursal, p.id AS id_prenda, p.descripcion, i.talla, i.color, i.cantidad
       FROM inventario_sucursal i
       JOIN prendas p ON p.id = i.id_prenda
       WHERE i.cantidad > 0 AND p.activa = TRUE ${filtro}
       ORDER BY i.id_sucursal, p.descripcion, i.talla, i.color`,
      params
    );
    return rows;
  },

  /**
   * Piezas vendidas por prenda, a partir de los movimientos `venta` de la auditoria
   * (cada venta resta cantidad_anterior - cantidad_nueva). Con `sucursalId` se reporta esa
   * sucursal; sin el, se suma toda la cadena. `desde` y `hasta` (YYYY-MM-DD) incluyen ambos dias.
   */
  async masVendidos({ sucursalId, desde, hasta, limite }, db = pool) {
    const params = [];
    const where = [`h.tipo_movimiento = 'venta'`];
    if (sucursalId) { params.push(sucursalId); where.push(`i.id_sucursal = $${params.length}`); }
    if (desde || hasta) {
      // La zona horaria solo se manda cuando hay periodo: un parametro sin usar hace fallar a PostgreSQL
      params.push(ZONA_HORARIA);
      const dia = `(h."timestamp" AT TIME ZONE $${params.length}::text)::date`;
      if (desde) { params.push(desde); where.push(`${dia} >= $${params.length}::date`); }
      if (hasta) { params.push(hasta); where.push(`${dia} <= $${params.length}::date`); }
    }
    params.push(limite);

    const porSucursal = Boolean(sucursalId);
    const { rows } = await db.query(
      `SELECT p.id AS id_prenda, p.descripcion,
              ${porSucursal ? 's.id' : 'NULL::int'} AS id_sucursal,
              ${porSucursal ? 's.nombre' : 'NULL::text'} AS sucursal,
              SUM(h.cantidad_anterior - h.cantidad_nueva)::int AS piezas_vendidas
       FROM historial_auditoria_inventario h
       JOIN inventario_sucursal i ON i.id = h.id_inventario
       JOIN prendas p ON p.id = i.id_prenda
       JOIN sucursales s ON s.id = i.id_sucursal
       WHERE ${where.join(' AND ')}
       GROUP BY p.id, p.descripcion${porSucursal ? ', s.id, s.nombre' : ''}
       ORDER BY piezas_vendidas DESC, p.descripcion, p.id
       LIMIT $${params.length}`,
      params
    );
    return rows;
  },
};
