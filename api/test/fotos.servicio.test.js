// Pruebas de integracion del servicio de fotos: base de datos real y una carpeta temporal en disco.
// Requisitos: `docker compose up -d` corriendo. Si no hay base, las pruebas se omiten.
// Ejecutar desde api/:  npm test
const { test, before, after, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const config = require('../src/config/env');
const { pool } = require('../src/db/pool');
const fotos = require('../src/services/fotosService');
const prendasRepo = require('../src/repositories/prendasRepository');

let dbLista = false;
let carpetaTemporal;
let idPrenda;

const jpg = (relleno = 1) => Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(64, relleno)]);
const png = () => Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(64, 2)]);

const conDb = (nombre, fn) =>
  test(nombre, async (t) => {
    if (!dbLista) return t.skip('Sin base de datos: levanta docker compose');
    await fn(t);
  });

const archivosGuardados = async () => {
  try { return await fs.readdir(path.join(carpetaTemporal, 'prendas')); } catch { return []; }
};

before(async () => {
  try {
    await pool.query('SELECT 1 FROM prendas LIMIT 1');
    dbLista = true;
  } catch {
    dbLista = false;
  }
  if (!dbLista) return;
  carpetaTemporal = await fs.mkdtemp(path.join(os.tmpdir(), 'checklizz-fotos-'));
  config.uploadsDir = carpetaTemporal;           // el servicio lee la carpeta en cada llamada
  const { rows } = await pool.query(
    `INSERT INTO prendas (codigo_barras, descripcion) VALUES ($1, 'PRENDA DE PRUEBA FOTO') RETURNING id`,
    [`TEST-FOTO-${Date.now()}`]
  );
  idPrenda = rows[0].id;
});

after(async () => {
  if (dbLista) {
    await pool.query('DELETE FROM prendas WHERE id = $1', [idPrenda]);
    await fs.rm(carpetaTemporal, { recursive: true, force: true });
  }
  await pool.end();
});

describe('guardar foto de una prenda', () => {
  let primera;

  conDb('guarda el archivo y deja la ruta publica en foto_url', async () => {
    const ficha = await fotos.guardar(idPrenda, { buffer: jpg() });
    assert.match(ficha.foto_url, new RegExp(`^/uploads/prendas/prenda-${idPrenda}-[0-9a-f]{16}\\.jpg$`));
    assert.ok(Array.isArray(ficha.existencias), 'devuelve la ficha completa de la prenda');

    primera = path.basename(ficha.foto_url);
    assert.deepEqual(await archivosGuardados(), [primera]);
    assert.deepEqual(await fs.readFile(path.join(carpetaTemporal, 'prendas', primera)), jpg());
    assert.equal((await prendasRepo.findById(idPrenda)).foto_url, ficha.foto_url);
  });

  conDb('al subir otra, reemplaza la anterior y borra el archivo viejo', async () => {
    const ficha = await fotos.guardar(idPrenda, { buffer: png() });
    const segunda = path.basename(ficha.foto_url);
    assert.match(segunda, /\.png$/, 'la extension sale del contenido real');
    assert.notEqual(segunda, primera);
    assert.deepEqual(await archivosGuardados(), [segunda], 'el archivo anterior ya no esta');
  });

  conDb('un archivo que no es imagen se rechaza y no cambia nada', async () => {
    const antes = await archivosGuardados();
    const fotoAntes = (await prendasRepo.findById(idPrenda)).foto_url;
    await assert.rejects(
      fotos.guardar(idPrenda, { buffer: Buffer.from('<html><script>alert(1)</script></html>') }),
      { status: 400, code: 'DATOS_INVALIDOS' }
    );
    assert.deepEqual(await archivosGuardados(), antes);
    assert.equal((await prendasRepo.findById(idPrenda)).foto_url, fotoAntes);
  });

  conDb('una prenda que no existe da 404 y no escribe nada', async () => {
    const antes = await archivosGuardados();
    await assert.rejects(fotos.guardar(999999, { buffer: jpg() }), { status: 404 });
    assert.deepEqual(await archivosGuardados(), antes);
  });

  conDb('si la foto anterior era un enlace externo, no intenta borrar nada y la reemplaza', async () => {
    await prendasRepo.update(idPrenda, { foto_url: 'https://cdn.ejemplo.com/vestido.jpg' });
    const ficha = await fotos.guardar(idPrenda, { buffer: jpg(9) });
    assert.match(ficha.foto_url, /^\/uploads\/prendas\//);
    assert.equal((await archivosGuardados()).length, 2, 'el archivo de la prueba anterior sigue ahi: no era el reemplazado');
  });

  conDb('una ruta manipulada en foto_url no borra archivos fuera de la carpeta', async () => {
    const intruso = path.join(carpetaTemporal, 'intruso.txt');
    await fs.writeFile(intruso, 'no me borres');
    await prendasRepo.update(idPrenda, { foto_url: '/uploads/prendas/../intruso.txt' });
    await fotos.guardar(idPrenda, { buffer: jpg(5) });
    assert.equal(await fs.readFile(intruso, 'utf8'), 'no me borres');
  });
});
