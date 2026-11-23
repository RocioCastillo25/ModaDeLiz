// CAPA DE DATOS: unico lugar con SQL de traspasos.
const { pool } = require('../db/pool');

// Traspaso con nombres de sucursales y personas, y su detalle en un arreglo JSON.
const SELECT_TRASPASO = `
  SELECT t.id,
         t.id_sucursal_origen,  so.nombre AS sucursal_origen,
         t.id_sucursal_destino, sd.nombre AS sucursal_destino,
         t.usuario_solicita,    us.nombre AS solicitante,
         t.usuario_aprueba,     ua.nombre AS aprobador,
         t.estado, t.fecha_solicitud, t.fecha_actualizacion,
         COALESCE((
           SELECT json_agg(json_build_object(
                    'id_prenda', d.id_prenda, 'codigo_barras', p.codigo_barras, 'descripcion', p.descripcion,
                    'talla', d.talla, 'color', d.color, 'cantidad', d.cantidad)
                  ORDER BY p.descripcion, d.talla, d.color)
           FROM detalle_traspaso d JOIN prendas p ON p.id = d.id_prenda
           WHERE d.id_traspaso = t.id
         ), '[]'::json) AS detalle
  FROM traspasos t
  JOIN sucursales so ON so.id = t.id_sucursal_origen
  JOIN sucursales sd ON sd.id = t.id_sucursal_destino
  JOIN usuarios us   ON us.id = t.usuario_solicita
  LEFT JOIN usuarios ua ON ua.id = t.usuario_aprueba`;

module.exports = {
  /** Lista los traspasos que el usuario puede ver (ver domain/traspasos.puedeVer), mas recientes primero. */
  async list({ user, estado, sucursalId }, db = pool) {
    const params = [];
    const where = [];

    if (user.rol === 'gerente') {
      params.push(user.sucursalId);
      where.push(`(t.id_sucursal_origen = $${params.length} OR t.id_sucursal_destino = $${params.length})`);
    } else if (user.rol === 'empleado') {
      params.push(user.id);
      where.push(`t.usuario_solicita = $${params.length}`);
    }
    if (estado) { params.push(estado); where.push(`t.estado = $${params.length}`); }
    if (sucursalId) {
      params.push(sucursalId);
      where.push(`(t.id_sucursal_origen = $${params.length} OR t.id_sucursal_destino = $${params.length})`);
    }

    const { rows } = await db.query(
      `${SELECT_TRASPASO} ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
       ORDER BY t.fecha_solicitud DESC, t.id DESC LIMIT 200`,
      params
    );
    return rows;
  },

  async findById(id, db = pool) {
    const { rows } = await db.query(`${SELECT_TRASPASO} WHERE t.id = $1`, [id]);
    return rows[0];
  },

  /** Existencia de una prenda en una sucursal (talla exacta, color sin distinguir mayusculas). Sin bloqueo. */
  async existencia({ idSucursal, idPrenda, talla, color }, db = pool) {
    const { rows } = await db.query(
      `SELECT id, talla, color, cantidad FROM inventario_sucursal
       WHERE id_sucursal = $1 AND id_prenda = $2 AND talla = $3 AND lower(color) = lower($4)`,
      [idSucursal, idPrenda, talla, color]
    );
    return rows[0];
  },

  async insertar({ idOrigen, idDestino, idSolicita }, db) {
    const { rows } = await db.query(
      `INSERT INTO traspasos (id_sucursal_origen, id_sucursal_destino, usuario_solicita)
       VALUES ($1,$2,$3) RETURNING id`,
      [idOrigen, idDestino, idSolicita]
    );
    return rows[0];
  },

  async insertarDetalle(idTraspaso, items, db) {
    for (const it of items) {
      await db.query(
        `INSERT INTO detalle_traspaso (id_traspaso, id_prenda, talla, color, cantidad) VALUES ($1,$2,$3,$4,$5)`,
        [idTraspaso, it.idPrenda, it.talla, it.color, it.cantidad]
      );
    }
  },
};
