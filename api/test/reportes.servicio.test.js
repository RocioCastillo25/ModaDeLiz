// Pruebas de integracion del servicio de reportes contra PostgreSQL real.
// Requisitos: `docker compose up -d` corriendo. Si no hay base, las pruebas se omiten.
// Los datos de venta de prueba llevan fechas de 2020 para no mezclarse con ventas reales.
// Ejecutar desde api/:  npm test
const { test, before, after, describe } = require('node:test');
const assert = require('node:assert/strict');
const { pool } = require('../src/db/pool');
const reportes = require('../src/services/reportesService');

let dbLista = false;
const datos = {};
const AHORA = new Date('2026-11-23T15:00:00.000Z');

const admin = { id: 1, rol: 'administrador', sucursalId: null };
const gerente1 = { id: 2, rol: 'gerente', sucursalId: 1 };
const gerente2 = { id: 90, rol: 'gerente', sucursalId: 2 };
const empleado = { id: 3, rol: 'empleado', sucursalId: 1 };

const conDb = (nombre, fn) =>
  test(nombre, async (t) => {
    if (!dbLista) return t.skip('Sin base de datos: levanta docker compose');
    await fn(t);
  });

async function prenda(descripcion, { activa = true, umbral = 5 } = {}) {
  const { rows } = await pool.query(
    `INSERT INTO prendas (codigo_barras, descripcion, umbral_alerta, activa) VALUES ($1, $2, $3, $4) RETURNING id`,
    [`TEST-REP-${descripcion}-${Date.now()}`, descripcion, umbral, activa]
  );
  return rows[0].id;
}

async function inventario(idPrenda, idSucursal, talla, color, cantidad) {
  const { rows } = await pool.query(
    `INSERT INTO inventario_sucursal (id_prenda, id_sucursal, talla, color, cantidad) VALUES ($1,$2,$3,$4,$5) RETURNING id`,
    [idPrenda, idSucursal, talla, color, cantidad]
  );
  return rows[0].id;
}

// Registra una venta en la auditoria con la fecha indicada (hora de Puebla, UTC-6 en 2020)
const venta = (idInventario, piezas, cuando) =>
  pool.query(
    `INSERT INTO historial_auditoria_inventario (id_inventario, tipo_movimiento, cantidad_anterior, cantidad_nueva, "timestamp")
     VALUES ($1, 'venta', $2, $3, $4)`,
    [idInventario, 100, 100 - piezas, cuando]
  );

before(async () => {
  try {
    await pool.query('SELECT 1 FROM historial_auditoria_inventario LIMIT 1');
    dbLista = true;
  } catch {
    dbLista = false;
  }
  if (!dbLista) return;

  datos.a = await prenda('REPORTE PRUEBA A');                       // umbral 5
  datos.b = await prenda('REPORTE PRUEBA B');
  datos.inactiva = await prenda('REPORTE PRUEBA INACTIVA', { activa: false });

  datos.aSuc1 = await inventario(datos.a, 1, 'M', 'Rojo', 4);       // bajo el umbral
  datos.aSuc2 = await inventario(datos.a, 2, 'M', 'Rojo', 10);
  await inventario(datos.a, 1, 'CH', 'Negro', 0);                   // sin piezas: no cuenta como existencia
  datos.bSuc1 = await inventario(datos.b, 1, 'G', 'Azul', 20);
  datos.bSuc2 = await inventario(datos.b, 2, 'G', 'Azul', 20);
  await inventario(datos.inactiva, 1, 'M', 'Verde', 3);

  // A en sucursal 1: 3 + 1 + 2 = 6 piezas. La de las 23:30 del dia 10 (hora local) ya es dia 11 en UTC.
  await venta(datos.aSuc1, 3, '2020-03-10 12:00:00-06');
  await venta(datos.aSuc1, 1, '2020-03-10 23:30:00-06');
  await venta(datos.aSuc1, 2, '2020-03-20 12:00:00-06');
  // B: 8 en sucursal 1 y 1 en sucursal 2 = 9
  await venta(datos.bSuc1, 8, '2020-03-12 12:00:00-06');
  await venta(datos.bSuc2, 1, '2020-03-12 12:00:00-06');
});

after(async () => {
  if (dbLista) {
    const ids = [datos.a, datos.b, datos.inactiva];
    await pool.query(
      `DELETE FROM historial_auditoria_inventario
       WHERE id_inventario IN (SELECT id FROM inventario_sucursal WHERE id_prenda = ANY($1))`, [ids]
    );
    await pool.query('DELETE FROM inventario_sucursal WHERE id_prenda = ANY($1)', [ids]);
    await pool.query('DELETE FROM prendas WHERE id = ANY($1)', [ids]);
  }
  await pool.end();
});

const periodo2020 = { desde: '2020-01-01', hasta: '2020-12-31' };
const resumen = (items) => items.map((i) => [i.descripcion, i.piezas_vendidas]);

describe('reporte de existencias', () => {
  conDb('el administrador ve todas las sucursales con productos distintos y piezas', async () => {
    const { datos: r } = await reportes.existencias(admin, {}, AHORA);
    const total = (await pool.query('SELECT count(*)::int AS n FROM sucursales')).rows[0].n;
    assert.equal(r.generado_en, AHORA.toISOString());
    assert.equal(r.sucursales.length, total);

    const hua = r.sucursales.find((s) => s.id_sucursal === 1);
    const piezasA = hua.detalle.filter((d) => d.id_prenda === datos.a);
    assert.deepEqual(piezasA.map((d) => [d.talla, d.color, d.cantidad]), [['M', 'Rojo', 4]],
      'la fila con 0 piezas no sale');
    const piezasB = hua.detalle.filter((d) => d.id_prenda === datos.b);
    assert.deepEqual(piezasB.map((d) => d.cantidad), [20]);
  });

  conDb('no incluye prendas inactivas', async () => {
    const { datos: r } = await reportes.existencias(admin, { sucursalId: 1 }, AHORA);
    assert.ok(!r.sucursales[0].detalle.some((d) => d.id_prenda === datos.inactiva));
  });

  conDb('el administrador puede filtrar una sucursal', async () => {
    const { datos: r } = await reportes.existencias(admin, { sucursalId: 2 }, AHORA);
    assert.equal(r.sucursales.length, 1);
    assert.equal(r.sucursales[0].id_sucursal, 2);
  });

  conDb('los totales coinciden con el detalle', async () => {
    const { datos: r } = await reportes.existencias(admin, { sucursalId: 1 }, AHORA);
    const [s] = r.sucursales;
    assert.equal(s.piezas, s.detalle.reduce((t, d) => t + d.cantidad, 0));
    assert.equal(s.productos_distintos, new Set(s.detalle.map((d) => d.id_prenda)).size);
  });

  conDb('el gerente solo ve su sucursal, aunque no mande filtro', async () => {
    const { datos: r } = await reportes.existencias(gerente2, {}, AHORA);
    assert.equal(r.sucursales.length, 1);
    assert.equal(r.sucursales[0].id_sucursal, 2);
  });

  conDb('el gerente no puede pedir otra sucursal y el empleado no puede pedir nada', async () => {
    await assert.rejects(reportes.existencias(gerente1, { sucursalId: 2 }, AHORA), { status: 403, code: 'PROHIBIDO' });
    await assert.rejects(reportes.existencias(empleado, {}, AHORA), { status: 403 });
  });

  conDb('una sucursal que no existe da 404', async () => {
    await assert.rejects(reportes.existencias(admin, { sucursalId: 999999 }, AHORA), { status: 404 });
  });
});

describe('reporte de lo mas vendido', () => {
  conDb('solo el administrador', async () => {
    await assert.rejects(reportes.masVendidos(gerente1, periodo2020, AHORA), { status: 403 });
    await assert.rejects(reportes.masVendidos(empleado, periodo2020, AHORA), { status: 403 });
  });

  conDb('suma toda la cadena y ordena de mayor a menor; sin sucursal los campos van en null', async () => {
    const { datos: r } = await reportes.masVendidos(admin, periodo2020, AHORA);
    assert.deepEqual(resumen(r.items), [['REPORTE PRUEBA B', 9], ['REPORTE PRUEBA A', 6]]);
    assert.equal(r.items[0].id_sucursal, null);
    assert.equal(r.items[0].sucursal, null);
    assert.deepEqual([r.desde, r.hasta], ['2020-01-01', '2020-12-31']);
  });

  conDb('con sucursal reporta solo esa y trae su nombre', async () => {
    const uno = (await reportes.masVendidos(admin, { ...periodo2020, sucursalId: 1 }, AHORA)).datos;
    assert.deepEqual(resumen(uno.items), [['REPORTE PRUEBA B', 8], ['REPORTE PRUEBA A', 6]]);
    assert.equal(uno.items[0].id_sucursal, 1);
    assert.equal(uno.items[0].sucursal, 'Huauchinango');

    const dos = (await reportes.masVendidos(admin, { ...periodo2020, sucursalId: 2 }, AHORA)).datos;
    assert.deepEqual(resumen(dos.items), [['REPORTE PRUEBA B', 1]]);
  });

  conDb('"hasta" incluye ese dia completo en hora local (la venta de las 23:30 cuenta)', async () => {
    const { datos: r } = await reportes.masVendidos(admin, { desde: '2020-01-01', hasta: '2020-03-10' }, AHORA);
    assert.deepEqual(resumen(r.items), [['REPORTE PRUEBA A', 4]]);
  });

  conDb('"desde" excluye lo anterior: la venta del dia 10 a las 23:30 no entra al dia 11', async () => {
    const { datos: r } = await reportes.masVendidos(admin, { desde: '2020-03-11', hasta: '2020-03-19' }, AHORA);
    assert.deepEqual(resumen(r.items), [['REPORTE PRUEBA B', 9]]);
    const tarde = await reportes.masVendidos(admin, { desde: '2020-03-20', hasta: '2020-12-31' }, AHORA);
    assert.deepEqual(resumen(tarde.datos.items), [['REPORTE PRUEBA A', 2]]);
  });

  conDb('sin periodo ni sucursal tambien funciona (todo el historial)', async () => {
    const { datos: r } = await reportes.masVendidos(admin, { limite: 100 }, AHORA);
    assert.deepEqual([r.desde, r.hasta], [null, null]);
    const nombres = r.items.map((i) => i.descripcion);
    assert.ok(nombres.indexOf('REPORTE PRUEBA B') < nombres.indexOf('REPORTE PRUEBA A'), 'B (9) antes que A (6)');
    // solo con "desde" o solo con "hasta"
    assert.ok((await reportes.masVendidos(admin, { desde: '2020-03-20', limite: 100 }, AHORA)).datos.items.length > 0);
    assert.ok((await reportes.masVendidos(admin, { hasta: '2020-03-10', limite: 100 }, AHORA)).datos.items.length > 0);
  });

  conDb('respeta el limite', async () => {
    const { datos: r } = await reportes.masVendidos(admin, { ...periodo2020, limite: 1 }, AHORA);
    assert.deepEqual(resumen(r.items), [['REPORTE PRUEBA B', 9]]);
  });

  conDb('un periodo al reves da 400 y una sucursal inexistente 404', async () => {
    await assert.rejects(
      reportes.masVendidos(admin, { desde: '2020-12-31', hasta: '2020-01-01' }, AHORA), { status: 400, code: 'DATOS_INVALIDOS' }
    );
    await assert.rejects(reportes.masVendidos(admin, { sucursalId: 999999 }, AHORA), { status: 404 });
  });

  conDb('un periodo sin ventas devuelve lista vacia', async () => {
    const { datos: r } = await reportes.masVendidos(admin, { desde: '1999-01-01', hasta: '1999-12-31' }, AHORA);
    assert.deepEqual(r.items, []);
  });
});

describe('reporte de stock bajo', () => {
  const de = (items, idPrenda) => items.filter((i) => i.id_prenda === idPrenda);

  conDb('el administrador ve lo que esta en o bajo el umbral, con los campos del contrato', async () => {
    const { datos: r } = await reportes.stockBajo(admin, {}, AHORA);
    assert.equal(r.generado_en, AHORA.toISOString());
    const bajos = de(r.items, datos.a);
    assert.ok(bajos.some((i) => i.id === datos.aSuc1 && i.cantidad === 4 && i.umbral_alerta === 5), 'A en sucursal 1 (4 <= 5)');
    assert.ok(!bajos.some((i) => i.id === datos.aSuc2), 'A en sucursal 2 tiene 10: no es bajo');
    assert.ok(de(r.items, datos.b).length === 0, 'B tiene 20: no es bajo');
    assert.deepEqual(Object.keys(bajos[0]).sort(),
      ['cantidad', 'color', 'descripcion', 'id', 'id_prenda', 'id_sucursal', 'sucursal', 'talla', 'umbral_alerta']);
  });

  conDb('el gerente solo ve su sucursal', async () => {
    const uno = (await reportes.stockBajo(gerente1, {}, AHORA)).datos.items;
    assert.ok(uno.length > 0 && uno.every((i) => i.id_sucursal === 1));
    assert.ok(de(uno, datos.a).length > 0);

    const dos = (await reportes.stockBajo(gerente2, {}, AHORA)).datos.items;
    assert.ok(dos.every((i) => i.id_sucursal === 2));
    assert.equal(de(dos, datos.a).length, 0);

    await assert.rejects(reportes.stockBajo(gerente1, { sucursalId: 2 }, AHORA), { status: 403 });
    await assert.rejects(reportes.stockBajo(empleado, {}, AHORA), { status: 403 });
  });

  conDb('el administrador puede filtrar una sucursal y una inexistente da 404', async () => {
    const uno = (await reportes.stockBajo(admin, { sucursalId: 1 }, AHORA)).datos.items;
    assert.ok(uno.every((i) => i.id_sucursal === 1));
    await assert.rejects(reportes.stockBajo(admin, { sucursalId: 999999 }, AHORA), { status: 404 });
  });
});

describe('exportar', () => {
  conDb('PDF y Excel salen con tipo, nombre con fecha y contenido valido', async () => {
    const reporte = await reportes.existencias(admin, {}, AHORA);

    const pdf = await reportes.exportar(reporte, 'pdf', 'existencias');
    assert.equal(pdf.tipo, 'application/pdf');
    assert.equal(pdf.nombre, 'existencias-2026-11-23.pdf');
    assert.equal(pdf.cuerpo.subarray(0, 5).toString('latin1'), '%PDF-');

    const xlsx = await reportes.exportar(reporte, 'xlsx', 'existencias');
    assert.match(xlsx.tipo, /spreadsheetml\.sheet$/);
    assert.equal(xlsx.nombre, 'existencias-2026-11-23.xlsx');
    assert.equal(xlsx.cuerpo.subarray(0, 2).toString('latin1'), 'PK', 'un .xlsx es un zip');
  });
});
