// Pruebas de integracion del cambio de estado de traspasos contra PostgreSQL real.
// Requisitos: `docker compose up -d` corriendo y la tabla `notificaciones` creada
// (infra/postgres/init/03_notificaciones.sql). Si no hay base, las pruebas se omiten.
// Ejecutar desde api/:  npm test
const { test, before, after, describe } = require('node:test');
const assert = require('node:assert/strict');
const { pool } = require('../src/db/pool');
const traspasos = require('../src/services/traspasosService');

let dbLista = false;
const datos = {};        // filas de prueba creadas en before()
const creados = [];      // ids de traspasos creados, para limpiar al final

// Usuarios de la semilla (infra/postgres/init/02_seed.sql)
const admin = { id: 1, rol: 'administrador', sucursalId: null };
const gerenteDestino = { id: 2, rol: 'gerente', sucursalId: 1 };   // Huauchinango
const empleadoHua = { id: 3, rol: 'empleado', sucursalId: 1 };

const conDb = (nombre, fn) =>
  test(nombre, async (t) => {
    if (!dbLista) return t.skip('Sin base de datos: levanta docker compose y aplica 03_notificaciones.sql');
    await fn(t);
  });

async function nuevoUsuario(nombre, rol, sucursal) {
  const { rows } = await pool.query(
    `INSERT INTO usuarios (nombre, email, id_keycloak, rol, id_sucursal_asignada)
     VALUES ($1, $2, gen_random_uuid(), $3, $4) RETURNING id`,
    [nombre, `${nombre.toLowerCase().replace(/\s+/g, '.')}@prueba.local`, rol, sucursal]
  );
  return { id: rows[0].id, rol, sucursalId: sucursal };
}

const stock = async (sucursal) => {
  const { rows } = await pool.query(
    'SELECT cantidad FROM inventario_sucursal WHERE id_prenda = $1 AND id_sucursal = $2', [datos.prendaId, sucursal]
  );
  return rows.length ? rows[0].cantidad : null;   // null = no existe la fila
};

async function solicitar(cantidad) {
  const t = await traspasos.crear(empleadoHua, {
    idSucursalOrigen: 2, detalle: [{ idPrenda: datos.prendaId, talla: 'M', color: 'rojo', cantidad }],
  });
  creados.push(t.id);
  return t.id;
}

const avisos = async (idUsuario, idTraspaso) =>
  (await pool.query('SELECT tipo, leida FROM notificaciones WHERE id_usuario = $1 AND id_traspaso = $2 ORDER BY id',
    [idUsuario, idTraspaso])).rows;

before(async () => {
  try {
    await pool.query('SELECT 1 FROM notificaciones LIMIT 1');
    const { rows } = await pool.query('SELECT id, rol, id_sucursal_asignada FROM usuarios WHERE id IN (1,2,3) ORDER BY id');
    dbLista = rows.length === 3 && rows[1].id_sucursal_asignada === 1 && rows[2].id_sucursal_asignada === 1;
  } catch {
    dbLista = false;
  }
  if (!dbLista) return;

  // Una prenda de prueba con 5 piezas en Zacatlan (2) y ninguna en Huauchinango (1)
  const prenda = await pool.query(
    `INSERT INTO prendas (codigo_barras, descripcion) VALUES ($1, 'PRENDA DE PRUEBA ESTADO') RETURNING id`,
    [`TEST-EST-${Date.now()}`]
  );
  datos.prendaId = prenda.rows[0].id;
  await pool.query(
    `INSERT INTO inventario_sucursal (id_prenda, id_sucursal, talla, color, cantidad) VALUES ($1, 2, 'M', 'Rojo', 5)`,
    [datos.prendaId]
  );

  datos.gerenteOrigen = await nuevoUsuario('Gerente Estado Zacatlan', 'gerente', 2);
  datos.gerenteAjeno = await nuevoUsuario('Gerente Estado Chignahuapan', 'gerente', 3);
});

after(async () => {
  if (dbLista) {
    // La auditoria apunta al inventario, asi que se borra primero
    await pool.query(
      `DELETE FROM historial_auditoria_inventario
       WHERE id_inventario IN (SELECT id FROM inventario_sucursal WHERE id_prenda = $1)`, [datos.prendaId]
    );
    if (creados.length) await pool.query('DELETE FROM traspasos WHERE id = ANY($1)', [creados]);
    await pool.query('DELETE FROM inventario_sucursal WHERE id_prenda = $1', [datos.prendaId]);
    await pool.query('DELETE FROM prendas WHERE id = $1', [datos.prendaId]);
    await pool.query('DELETE FROM usuarios WHERE id = ANY($1)', [[datos.gerenteOrigen.id, datos.gerenteAjeno.id]]);
  }
  await pool.end();
});

describe('flujo completo de un traspaso', () => {
  let id;

  conDb('el empleado no puede cambiar estados', async () => {
    id = await solicitar(2);
    await assert.rejects(traspasos.cambiarEstado(empleadoHua, id, 'APROBADO'), { status: 403, code: 'PROHIBIDO' });
  });

  conDb('un gerente de otra sucursal ni siquiera lo ve', async () => {
    await assert.rejects(traspasos.cambiarEstado(datos.gerenteAjeno, id, 'APROBADO'), { status: 403 });
  });

  conDb('un traspaso que no existe da 404', async () => {
    await assert.rejects(traspasos.cambiarEstado(admin, 999999, 'APROBADO'), { status: 404 });
  });

  conDb('el gerente de origen aprueba, queda registrado quien aprobo y se avisa al solicitante', async () => {
    const t = await traspasos.cambiarEstado(datos.gerenteOrigen, id, 'APROBADO');
    assert.equal(t.estado, 'APROBADO');
    assert.equal(t.usuario_aprueba, datos.gerenteOrigen.id);
    const lista = await avisos(empleadoHua.id, id);
    assert.deepEqual(lista.map((a) => a.tipo), ['TRASPASO_APROBADO']);
    assert.equal(lista[0].leida, false);
  });

  conDb('no se puede saltar a RECIBIDO desde APROBADO', async () => {
    await assert.rejects(traspasos.cambiarEstado(admin, id, 'RECIBIDO'), { status: 409, code: 'TRANSICION_NO_PERMITIDA' });
    assert.equal(await stock(2), 5, 'el stock no se mueve');
  });

  conDb('solo el origen marca EN_CAMINO (el destino no)', async () => {
    await assert.rejects(traspasos.cambiarEstado(gerenteDestino, id, 'EN_CAMINO'), { status: 403 });
    const t = await traspasos.cambiarEstado(datos.gerenteOrigen, id, 'EN_CAMINO');
    assert.equal(t.estado, 'EN_CAMINO');
    assert.equal(t.usuario_aprueba, datos.gerenteOrigen.id, 'conserva al que aprobo');
    assert.equal(await stock(2), 5, 'en camino todavia no mueve stock');
  });

  conDb('solo el destino marca RECIBIDO (el origen no)', async () => {
    await assert.rejects(traspasos.cambiarEstado(datos.gerenteOrigen, id, 'RECIBIDO'), { status: 403 });
  });

  conDb('al recibir resta en el origen, suma en el destino (creando la fila) y audita', async () => {
    const t = await traspasos.cambiarEstado(gerenteDestino, id, 'RECIBIDO');
    assert.equal(t.estado, 'RECIBIDO');
    assert.equal(await stock(2), 3);
    assert.equal(await stock(1), 2, 'el destino no tenia fila: se crea con lo recibido');

    const { rows } = await pool.query(
      `SELECT h.tipo_movimiento, h.cantidad_anterior, h.cantidad_nueva, i.id_sucursal
       FROM historial_auditoria_inventario h JOIN inventario_sucursal i ON i.id = h.id_inventario
       WHERE i.id_prenda = $1 ORDER BY i.id_sucursal`, [datos.prendaId]
    );
    assert.equal(rows.length, 2);
    assert.ok(rows.every((r) => r.tipo_movimiento === 'traspaso'));
    assert.deepEqual(rows.map((r) => [r.id_sucursal, r.cantidad_anterior, r.cantidad_nueva]), [[1, 0, 2], [2, 5, 3]]);
  });

  conDb('avisa al solicitante en cada paso', async () => {
    const lista = await avisos(empleadoHua.id, id);
    assert.deepEqual(lista.map((a) => a.tipo), ['TRASPASO_APROBADO', 'TRASPASO_EN_CAMINO', 'TRASPASO_RECIBIDO']);
  });

  conDb('un traspaso recibido ya no cambia', async () => {
    await assert.rejects(traspasos.cambiarEstado(admin, id, 'RECHAZADO'), { status: 409, code: 'TRANSICION_NO_PERMITIDA' });
    await assert.rejects(traspasos.cambiarEstado(gerenteDestino, id, 'RECIBIDO'), { status: 409 });
    assert.equal(await stock(2), 3, 'recibir dos veces no vuelve a mover el stock');
  });

  conDb('una segunda recepcion suma a la fila existente del destino', async () => {
    const otro = await solicitar(1);
    await traspasos.cambiarEstado(admin, otro, 'APROBADO');
    await traspasos.cambiarEstado(admin, otro, 'EN_CAMINO');
    await traspasos.cambiarEstado(admin, otro, 'RECIBIDO');
    assert.equal(await stock(2), 2);
    assert.equal(await stock(1), 3);
  });
});

describe('rechazo y casos limite', () => {
  conDb('rechazar no mueve stock, guarda quien rechazo y avisa', async () => {
    const antesOrigen = await stock(2);
    const antesDestino = await stock(1);
    const id = await solicitar(1);

    const t = await traspasos.cambiarEstado(gerenteDestino, id, 'RECHAZADO');
    assert.equal(t.estado, 'RECHAZADO');
    assert.equal(t.usuario_aprueba, gerenteDestino.id);
    assert.equal(await stock(2), antesOrigen);
    assert.equal(await stock(1), antesDestino);
    assert.deepEqual((await avisos(empleadoHua.id, id)).map((a) => a.tipo), ['TRASPASO_RECHAZADO']);

    await assert.rejects(traspasos.cambiarEstado(admin, id, 'APROBADO'), { status: 409, code: 'TRANSICION_NO_PERMITIDA' });
  });

  conDb('el solicitante gerente no aprueba su propia solicitud', async () => {
    const t = await traspasos.crear(gerenteDestino, {
      idSucursalOrigen: 2, detalle: [{ idPrenda: datos.prendaId, talla: 'M', color: 'Rojo', cantidad: 1 }],
    });
    creados.push(t.id);
    await assert.rejects(traspasos.cambiarEstado(gerenteDestino, t.id, 'APROBADO'), { status: 403 });
    // Otro gerente o el administrador si pueden
    assert.equal((await traspasos.cambiarEstado(admin, t.id, 'APROBADO')).estado, 'APROBADO');
  });

  conDb('si el origen se quedo sin piezas, recibir falla completo y no cambia nada', async () => {
    const id = await solicitar(2);                       // el origen tiene 2 al solicitar
    await traspasos.cambiarEstado(admin, id, 'APROBADO');
    await traspasos.cambiarEstado(admin, id, 'EN_CAMINO');
    await pool.query(                                    // ...pero antes de recibir se vende una
      'UPDATE inventario_sucursal SET cantidad = 1 WHERE id_prenda = $1 AND id_sucursal = 2', [datos.prendaId]
    );

    await assert.rejects(traspasos.cambiarEstado(admin, id, 'RECIBIDO'), { status: 409, code: 'STOCK_INSUFICIENTE' });
    assert.equal((await traspasos.obtener(admin, id)).estado, 'EN_CAMINO', 'el estado se queda donde estaba');
    assert.equal(await stock(2), 1);
    assert.equal(await stock(1), 3);
    assert.deepEqual((await avisos(empleadoHua.id, id)).map((a) => a.tipo), ['TRASPASO_APROBADO', 'TRASPASO_EN_CAMINO'],
      'no hay aviso de recibido');
  });

  conDb('dos recepciones simultaneas solo mueven el stock una vez', async () => {
    await pool.query(
      'UPDATE inventario_sucursal SET cantidad = 5 WHERE id_prenda = $1 AND id_sucursal = 2', [datos.prendaId]
    );
    const antesDestino = await stock(1);
    const id = await solicitar(2);
    await traspasos.cambiarEstado(admin, id, 'APROBADO');
    await traspasos.cambiarEstado(admin, id, 'EN_CAMINO');

    const resultados = await Promise.allSettled([
      traspasos.cambiarEstado(admin, id, 'RECIBIDO'),
      traspasos.cambiarEstado(gerenteDestino, id, 'RECIBIDO'),
    ]);
    assert.equal(resultados.filter((r) => r.status === 'fulfilled').length, 1);
    assert.equal(resultados.filter((r) => r.status === 'rejected')[0].reason.code, 'TRANSICION_NO_PERMITIDA');
    assert.equal(await stock(2), 3);
    assert.equal(await stock(1), antesDestino + 2);
  });
});
