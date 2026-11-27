// Pruebas de las reglas puras de fotos de prendas. No necesitan base de datos.
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { TAMANO_MAXIMO, tipoImagen, nombreDeFotoPropia, esFotoUrl } = require('../src/domain/fotos');

const relleno = (n) => Buffer.alloc(n, 1);
const jpg = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), relleno(20)]);
const png = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), relleno(20)]);
const webp = Buffer.concat([Buffer.from('RIFF'), relleno(4), Buffer.from('WEBP'), relleno(10)]);

describe('tipoImagen (por contenido, no por nombre)', () => {
  test('reconoce JPG, PNG y WebP', () => {
    assert.deepEqual(tipoImagen(jpg), { ext: 'jpg', mime: 'image/jpeg' });
    assert.deepEqual(tipoImagen(png), { ext: 'png', mime: 'image/png' });
    assert.deepEqual(tipoImagen(webp), { ext: 'webp', mime: 'image/webp' });
  });
  test('rechaza otros formatos aunque el cliente diga que es una imagen', () => {
    assert.equal(tipoImagen(Buffer.from('GIF89a' + 'x'.repeat(20))), null, 'GIF');
    assert.equal(tipoImagen(Buffer.from('<html><script>alert(1)</script></html>')), null, 'HTML');
    assert.equal(tipoImagen(Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>')), null, 'SVG (puede llevar scripts)');
    assert.equal(tipoImagen(Buffer.from('%PDF-1.7 ' + 'x'.repeat(20))), null, 'PDF');
  });
  test('RIFF que no es WebP (por ejemplo un WAV) se rechaza', () => {
    assert.equal(tipoImagen(Buffer.concat([Buffer.from('RIFF'), relleno(4), Buffer.from('WAVE'), relleno(10)])), null);
  });
  test('archivos vacios, cortos o que no son Buffer', () => {
    assert.equal(tipoImagen(Buffer.alloc(0)), null);
    assert.equal(tipoImagen(Buffer.from([0xff, 0xd8, 0xff])), null);
    assert.equal(tipoImagen('texto'), null);
    assert.equal(tipoImagen(undefined), null);
  });
  test('el limite es de 5 MB', () => {
    assert.equal(TAMANO_MAXIMO, 5 * 1024 * 1024);
  });
});

describe('nombreDeFotoPropia', () => {
  test('devuelve el nombre del archivo de una foto subida', () => {
    assert.equal(nombreDeFotoPropia('/uploads/prendas/prenda-3-ab12cd.jpg'), 'prenda-3-ab12cd.jpg');
  });
  test('ignora enlaces externos y rutas que no son nuestras', () => {
    assert.equal(nombreDeFotoPropia('https://ejemplo.com/uploads/prendas/x.jpg'), null);
    assert.equal(nombreDeFotoPropia('/otra/carpeta/x.jpg'), null);
    assert.equal(nombreDeFotoPropia(null), null);
    assert.equal(nombreDeFotoPropia(undefined), null);
  });
  test('no permite salirse de la carpeta (path traversal)', () => {
    assert.equal(nombreDeFotoPropia('/uploads/prendas/../../etc/passwd'), null);
    assert.equal(nombreDeFotoPropia('/uploads/prendas/..'), null);
    assert.equal(nombreDeFotoPropia('/uploads/prendas/a/b.jpg'), null);
    assert.equal(nombreDeFotoPropia('/uploads/prendas/a\\b.jpg'), null);
    assert.equal(nombreDeFotoPropia('/uploads/prendas/'), null);
  });
});

describe('esFotoUrl', () => {
  test('acepta URL http/https completas y la ruta de una foto subida', () => {
    assert.equal(esFotoUrl('https://cdn.ejemplo.com/vestido.jpg'), true);
    assert.equal(esFotoUrl('http://localhost:3000/uploads/prendas/x.png'), true);
    assert.equal(esFotoUrl('/uploads/prendas/prenda-3-ab12cd.webp'), true);
  });
  test('rechaza lo demas, incluidos esquemas peligrosos', () => {
    assert.equal(esFotoUrl('vestido.jpg'), false);
    assert.equal(esFotoUrl(''), false);
    assert.equal(esFotoUrl('/uploads/prendas/../x.jpg'), false);
    assert.equal(esFotoUrl('javascript:alert(1)'), false);
    assert.equal(esFotoUrl('file:///etc/passwd'), false);
    assert.equal(esFotoUrl('data:image/png;base64,AAAA'), false);
  });
});
