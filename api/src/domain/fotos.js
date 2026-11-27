// DOMINIO DE FOTOS DE PRENDAS: reglas puras (sin disco ni base de datos).

const TAMANO_MAXIMO = 5 * 1024 * 1024;           // 5 MB
const PREFIJO_URL = '/uploads/prendas/';
const NOMBRE_VALIDO = /^[\w.-]+$/;               // sin barras ni ".." posibles: solo el nombre del archivo

/**
 * Reconoce JPG, PNG y WebP por su CONTENIDO (los primeros bytes), no por el nombre ni por el
 * tipo que declare el cliente, que puede ser falso. Devuelve { ext, mime } o null.
 */
function tipoImagen(buffer) {
  if (!Buffer.isBuffer(buffer) || buffer.length < 12) return null;
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return { ext: 'jpg', mime: 'image/jpeg' };
  if (buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
    return { ext: 'png', mime: 'image/png' };
  }
  if (buffer.toString('latin1', 0, 4) === 'RIFF' && buffer.toString('latin1', 8, 12) === 'WEBP') {
    return { ext: 'webp', mime: 'image/webp' };
  }
  return null;
}

/** Nombre del archivo si la URL apunta a una foto subida por nosotros; si no, null. */
function nombreDeFotoPropia(fotoUrl) {
  if (typeof fotoUrl !== 'string' || !fotoUrl.startsWith(PREFIJO_URL)) return null;
  const nombre = fotoUrl.slice(PREFIJO_URL.length);
  return NOMBRE_VALIDO.test(nombre) && !nombre.includes('..') ? nombre : null;
}

/**
 * `foto_url` valido: una URL http(s) completa (foto externa) o la ruta de una foto subida
 * (/uploads/prendas/archivo.jpg). La segunda es lo que devuelve POST /prendas/{id}/foto, y la
 * web la reenvia al editar la prenda, asi que tambien debe aceptarse.
 */
function esFotoUrl(valor) {
  if (nombreDeFotoPropia(valor)) return true;
  try {
    const url = new URL(valor);
    return url.protocol === 'http:' || url.protocol === 'https:';
  } catch {
    return false;
  }
}

module.exports = { TAMANO_MAXIMO, PREFIJO_URL, tipoImagen, nombreDeFotoPropia, esFotoUrl };
