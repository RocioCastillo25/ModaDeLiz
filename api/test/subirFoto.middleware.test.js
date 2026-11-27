// Pruebas del middleware que recibe la foto, montado en una mini aplicacion Express (sin base de datos ni token).
const { test, before, after, describe } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { subirFoto } = require('../src/middlewares/subirFoto');
const { errorHandler } = require('../src/middlewares/errorHandler');
const { TAMANO_MAXIMO } = require('../src/domain/fotos');

let servidor;
let base;

before(async () => {
  const app = express();
  app.post('/foto', subirFoto, (req, res) => res.json({ bytes: req.file.size, campo: req.file.fieldname }));
  app.use(errorHandler);
  await new Promise((listo) => { servidor = app.listen(0, '127.0.0.1', listo); });
  base = `http://127.0.0.1:${servidor.address().port}`;
});

after(() => new Promise((listo) => servidor.close(listo)));

const enviar = (formulario) => fetch(`${base}/foto`, { method: 'POST', body: formulario });
const archivo = (bytes, campo = 'foto') => {
  const f = new FormData();
  f.append(campo, new Blob([Buffer.alloc(bytes, 7)], { type: 'image/jpeg' }), 'vestido.jpg');
  return f;
};

describe('subirFoto', () => {
  test('acepta una foto en el campo "foto" y la deja en memoria', async () => {
    const res = await enviar(archivo(2048));
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { bytes: 2048, campo: 'foto' });
  });

  test('acepta una foto de exactamente 5 MB', async () => {
    const res = await enviar(archivo(TAMANO_MAXIMO));
    assert.equal(res.status, 200);
  });

  test('rechaza mas de 5 MB con 400', async () => {
    const res = await enviar(archivo(TAMANO_MAXIMO + 1));
    assert.equal(res.status, 400);
    const cuerpo = await res.json();
    assert.equal(cuerpo.error, 'DATOS_INVALIDOS');
    assert.match(cuerpo.mensaje, /5 MB/);
  });

  test('rechaza si falta el archivo', async () => {
    const res = await enviar(new FormData());
    assert.equal(res.status, 400);
    assert.match((await res.json()).mensaje, /Falta el archivo/);
  });

  test('rechaza un archivo en un campo con otro nombre', async () => {
    const res = await enviar(archivo(100, 'imagen'));
    assert.equal(res.status, 400);
    assert.equal((await res.json()).error, 'DATOS_INVALIDOS');
  });

  test('rechaza campos de texto extra', async () => {
    const f = archivo(100);
    f.append('nota', 'hola');
    assert.equal((await enviar(f)).status, 400);
  });

  test('rechaza una peticion que no es multipart', async () => {
    const res = await fetch(`${base}/foto`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ foto: 'x' }),
    });
    assert.equal(res.status, 400);
    assert.equal((await res.json()).error, 'DATOS_INVALIDOS');
  });
});
