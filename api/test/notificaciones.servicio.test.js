// Pruebas de integracion del servicio de notificaciones contra PostgreSQL real.
// Requisitos: `docker compose up -d` corriendo y la tabla `notificaciones` creada
// (infra/postgres/init/03_notificaciones.sql). Si no hay base, las pruebas se omiten.
// Ejecutar desde api/:  npm test
const { test, before, after, describe } = require('node:test');
const assert = require('node:assert/strict');
const { pool } = require('../src/db/pool');
const repo = require('../src/repositories/notificacionesRepository');
const servicio = require('../src/services/notificacionesService');

let dbLista = false;
const usuarios = {};     // usuarios temporales; sus avisos se borran en cascada

const conDb = (nombre, fn) =>
  test(nombre, async (t) => {
    if (!dbLista) return t.skip('Sin base de datos: levanta docker compose y aplica 03_notificaciones.sql');
    await fn(t);
  });

async function nuevoUsuario(nombre) {
  const { rows } = await pool.query(
    `INSERT INTO usuarios (nombre, email, id_keycloak, rol, id_sucursal_asignada)
     VALUES ($1, $2, gen_random_uuid(), 'empleado', 1) RETURNING id`,
    [nombre, `${nombre.toLowerCase().replace(/\s+/g, '.')}@prueba.local`]
  );
  return { id: rows[0].id, rol: 'empleado', sucursalId: 1 };
}

const aviso = (usuario, mensaje) =>
  repo.crear({ idUsuario: usuario.id, idTraspaso: null, tipo: 'TRASPASO_APROBADO', mensaje });

before(async () => {
  try {
    await pool.query('SELECT 1 FROM notificaciones LIMIT 1');
    dbLista = true;
  } catch {
    dbLista = false;
  }
  if (!dbLista) return;
  usuarios.ana = await nuevoUsuario('Aviso Ana');
  usuarios.beto = await nuevoUsuario('Aviso Beto');
});

after(async () => {
  if (dbLista) await pool.query('DELETE FROM usuarios WHERE id = ANY($1)', [[usuarios.ana.id, usuarios.beto.id]]);
  await pool.end();
});

describe('notificaciones del usuario', () => {
  let primero;

  conDb('sin avisos: lista vacia y cero no leidas', async () => {
    assert.deepEqual(await servicio.listar(usuarios.ana), []);
    assert.deepEqual(await servicio.resumen(usuarios.ana), { no_leidas: 0 });
  });

  conDb('lista solo los avisos propios, los mas recientes primero', async () => {
    primero = await aviso(usuarios.ana, 'uno');
    await aviso(usuarios.ana, 'dos');
    await aviso(usuarios.ana, 'tres');
    await aviso(usuarios.beto, 'de beto');

    const lista = await servicio.listar(usuarios.ana);
    assert.deepEqual(lista.map((a) => a.mensaje), ['tres', 'dos', 'uno']);
    assert.deepEqual(Object.keys(lista[0]).sort(), ['creada_en', 'id', 'id_traspaso', 'leida', 'mensaje', 'tipo']);
  });

  conDb('respeta el limite', async () => {
    assert.equal((await servicio.listar(usuarios.ana, { limite: 2 })).length, 2);
  });

  conDb('el resumen cuenta las no leidas', async () => {
    assert.deepEqual(await servicio.resumen(usuarios.ana), { no_leidas: 3 });
  });

  conDb('marcar leida un aviso propio', async () => {
    const marcado = await servicio.marcarLeida(usuarios.ana, primero.id);
    assert.equal(marcado.leida, true);
    assert.deepEqual(await servicio.resumen(usuarios.ana), { no_leidas: 2 });
    assert.deepEqual((await servicio.listar(usuarios.ana, { soloNoLeidas: true })).map((a) => a.mensaje), ['tres', 'dos']);
  });

  conDb('un aviso ajeno o inexistente da 404 y no se toca', async () => {
    await assert.rejects(servicio.marcarLeida(usuarios.beto, primero.id), { status: 404 });
    await assert.rejects(servicio.marcarLeida(usuarios.ana, 999999999), { status: 404 });
  });

  conDb('marcar todas solo afecta al usuario y devuelve cuantas marco', async () => {
    assert.deepEqual(await servicio.marcarTodasLeidas(usuarios.ana), { marcadas: 2 });
    assert.deepEqual(await servicio.resumen(usuarios.ana), { no_leidas: 0 });
    assert.deepEqual(await servicio.resumen(usuarios.beto), { no_leidas: 1 }, 'los de beto siguen sin leer');
    assert.deepEqual(await servicio.marcarTodasLeidas(usuarios.ana), { marcadas: 0 });
  });
});
