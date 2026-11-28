// Pruebas de integracion del servicio de traspasos contra PostgreSQL real.
// Requisitos: `docker compose up -d` corriendo y la tabla `notificaciones` creada
// (infra/postgres/init/03_notificaciones.sql). Si no hay base, las pruebas se omiten.
// Ejecutar desde api/:  npm test
const { test, before, after, describe } = require('node:test');
const assert = require('node:assert/strict');
const { pool } = require('../src/db/pool');
const traspasos = require('../src/services/traspasosService');

let dbLista = false;
const datos = {};            // filas de prueba creadas en before()
const creados = [];          // ids de traspasos creados, para limpiar al final
let solicitudId;             // traspaso de la primera prueba, reutilizado por las demas

// Usuarios de la semilla (infra/postgres/init/02_seed.sql)
const admin = { id: 1, rol: 'administrador', sucursalId: null };
const gerenteHua = { id: 2, rol: 'gerente', sucursalId: 1 };
const empleadoHua = { id: 3, rol: 'empleado', sucursalId: 1 };

const conDb = (nombre, fn) =>
  test(nombre, async (t) => {
    if (!dbLista) return t.skip('Sin base de datos: levanta docker compose y aplica 03_notificaciones.sql');
    await fn(t);
  });

const detalle = (cantidad, extra = {}) => [{ idPrenda: datos.prendaId, talla: 'M', color: 'rojo', cantidad, ...extra }];

async function nuevoUsuario(nombre, rol, sucursal) {
  const { rows } = await pool.query(
    `INSERT INTO usuarios (nombre, email, id_keycloak, rol, id_sucursal_asignada)
     VALUES ($1, $2, gen_random_uuid(), $3, $4) RETURNING id`,
    [nombre, `${nombre.toLowerCase().replace(/\s+/g, '.')}@prueba.local`, rol, sucursal]
  );
  return { id: rows[0].id, rol, sucursalId: sucursal };
}

before(async () => {
  try {
    await pool.query('SELECT 1 FROM notificaciones LIMIT 1');
    const { rows } = await pool.query('SELECT id, rol, id_sucursal_asignada FROM usuarios WHERE id IN (1,2,3) ORDER BY id');
    dbLista = rows.length === 3 && rows[1].id_sucursal_asignada === 1 && rows[2].id_sucursal_asignada === 1;
  } catch {
    dbLista = false;
  }
  if (!dbLista) return;

  // Una prenda de prueba con 5 piezas en la sucursal 2 (Zacatlan)
  const prenda = await pool.query(
    `INSERT INTO prendas (codigo_barras, descripcion) VALUES ($1, 'PRENDA DE PRUEBA TRASPASOS') RETURNING id`,
    [`TEST-${Date.now()}`]
  );
  datos.prendaId = prenda.rows[0].id;
  await pool.query(
    `INSERT INTO inventario_sucursal (id_prenda, id_sucursal, talla, color, cantidad) VALUES ($1, 2, 'M', 'Rojo', 5)`,
    [datos.prendaId]
  );

  datos.gerenteOrigen = await nuevoUsuario('Gerente Prueba Zacatlan', 'gerente', 2);
  datos.gerenteAjeno = await nuevoUsuario('Gerente Prueba Chignahuapan', 'gerente', 3);
  datos.empleadoAjeno = await nuevoUsuario('Empleado Prueba Huauchinango', 'empleado', 1);
});

after(async () => {
  if (dbLista) {
    // Los traspasos arrastran su detalle y sus notificaciones (ON DELETE CASCADE)
    if (creados.length) await pool.query('DELETE FROM traspasos WHERE id = ANY($1)', [creados]);
    await pool.query('DELETE FROM inventario_sucursal WHERE id_prenda = $1', [datos.prendaId]);
    await pool.query('DELETE FROM prendas WHERE id = $1', [datos.prendaId]);
    const usuarios = [datos.gerenteOrigen, datos.gerenteAjeno, datos.empleadoAjeno].map((u) => u.id);
    await pool.query('DELETE FROM usuarios WHERE id = ANY($1)', [usuarios]);
  }
  await pool.end();
});

describe('crear traspaso', () => {
  conDb('el empleado solicita y nace SOLICITADO hacia su propia sucursal', async () => {
    const t = await traspasos.crear(empleadoHua, { idSucursalOrigen: 2, detalle: detalle(2) });
    creados.push(t.id);
    solicitudId = t.id;

    assert.equal(t.estado, 'SOLICITADO');
    assert.equal(t.id_sucursal_origen, 2);
    assert.equal(t.id_sucursal_destino, 1);
    assert.equal(t.usuario_solicita, empleadoHua.id);
    assert.equal(t.detalle.length, 1);
    assert.equal(t.detalle[0].cantidad, 2);
    assert.equal(t.detalle[0].color, 'Rojo', 'guarda el color tal como esta en el inventario');
  });

  conDb('no mueve el stock al solicitar', async () => {
    const { rows } = await pool.query(
      `SELECT cantidad FROM inventario_sucursal WHERE id_prenda = $1 AND id_sucursal = 2`, [datos.prendaId]
    );
    assert.equal(rows[0].cantidad, 5);
  });

  conDb('avisa a los gerentes de la sucursal de origen', async () => {
    const { rows } = await pool.query(
      `SELECT tipo, leida FROM notificaciones WHERE id_usuario = $1 AND id_traspaso = $2`,
      [datos.gerenteOrigen.id, solicitudId]
    );
    assert.equal(rows.length, 1);
    assert.equal(rows[0].tipo, 'TRASPASO_SOLICITADO');
    assert.equal(rows[0].leida, false);
  });

  conDb('rechaza pedir a la misma sucursal', async () => {
    await assert.rejects(
      traspasos.crear(empleadoHua, { idSucursalOrigen: 1, detalle: detalle(1) }),
      { status: 400, code: 'DATOS_INVALIDOS' }
    );
  });

  conDb('rechaza si el origen no tiene piezas suficientes y no crea nada', async () => {
    const antes = (await pool.query('SELECT count(*)::int AS n FROM traspasos')).rows[0].n;
    await assert.rejects(
      traspasos.crear(empleadoHua, { idSucursalOrigen: 2, detalle: detalle(6) }),
      { status: 409, code: 'STOCK_INSUFICIENTE' }
    );
    const despues = (await pool.query('SELECT count(*)::int AS n FROM traspasos')).rows[0].n;
    assert.equal(despues, antes);
  });

  conDb('rechaza un detalle con renglones repetidos', async () => {
    const repetido = [...detalle(1), ...detalle(1, { color: 'ROJO' })];
    await assert.rejects(
      traspasos.crear(empleadoHua, { idSucursalOrigen: 2, detalle: repetido }),
      { status: 400, code: 'DATOS_INVALIDOS' }
    );
  });

  conDb('rechaza una prenda que no existe', async () => {
    await assert.rejects(
      traspasos.crear(empleadoHua, { idSucursalOrigen: 2, detalle: detalle(1, { idPrenda: 999999 }) }),
      { status: 404 }
    );
  });

  conDb('el empleado no puede pedir para otra sucursal', async () => {
    await assert.rejects(
      traspasos.crear(empleadoHua, { idSucursalOrigen: 2, idSucursalDestino: 4, detalle: detalle(1) }),
      { status: 403, code: 'PROHIBIDO' }
    );
  });

  conDb('el administrador debe indicar la sucursal destino', async () => {
    await assert.rejects(
      traspasos.crear(admin, { idSucursalOrigen: 2, detalle: detalle(1) }),
      { status: 400, code: 'DATOS_INVALIDOS' }
    );
    const t = await traspasos.crear(admin, { idSucursalOrigen: 2, idSucursalDestino: 4, detalle: detalle(1) });
    creados.push(t.id);
    assert.equal(t.id_sucursal_destino, 4);
  });
});

describe('listar y consultar traspasos', () => {
  const ids = (lista) => lista.map((t) => t.id);

  conDb('el empleado ve solo lo que solicito', async () => {
    assert.ok(ids(await traspasos.listar(empleadoHua, {})).includes(solicitudId));
    assert.ok(!ids(await traspasos.listar(datos.empleadoAjeno, {})).includes(solicitudId));
  });

  conDb('el gerente ve los de su sucursal (origen o destino) y no los ajenos', async () => {
    assert.ok(ids(await traspasos.listar(datos.gerenteOrigen, {})).includes(solicitudId), 'origen');
    assert.ok(ids(await traspasos.listar(gerenteHua, {})).includes(solicitudId), 'destino');
    assert.ok(!ids(await traspasos.listar(datos.gerenteAjeno, {})).includes(solicitudId), 'ajeno');
  });

  conDb('el administrador ve todos', async () => {
    assert.ok(ids(await traspasos.listar(admin, {})).includes(solicitudId));
  });

  conDb('filtra por estado', async () => {
    assert.ok(ids(await traspasos.listar(admin, { estado: 'SOLICITADO' })).includes(solicitudId));
    assert.ok(!ids(await traspasos.listar(admin, { estado: 'RECIBIDO' })).includes(solicitudId));
  });

  conDb('obtener respeta la visibilidad', async () => {
    const t = await traspasos.obtener(empleadoHua, solicitudId);
    assert.equal(t.id, solicitudId);
    await assert.rejects(traspasos.obtener(datos.gerenteAjeno, solicitudId), { status: 403 });
    await assert.rejects(traspasos.obtener(admin, 999999), { status: 404 });
  });
});
