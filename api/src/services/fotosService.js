// CAPA DE NEGOCIO: foto de prenda. Guarda el archivo en la carpeta de subidas (un volumen en Docker)
// y deja su ruta publica en `foto_url`. Se sirve sin token desde /uploads/prendas/<archivo>.
const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');
const config = require('../config/env');
const prendasRepo = require('../repositories/prendasRepository');
const prendas = require('./prendasService');
const { tipoImagen, nombreDeFotoPropia, PREFIJO_URL } = require('../domain/fotos');
const { AppError, notFound } = require('../errors');

const carpeta = () => path.join(config.uploadsDir, 'prendas');

module.exports = {
  /**
   * @param {number} idPrenda
   * @param {{ buffer: Buffer }} archivo  el archivo recibido por multer (en memoria)
   * @returns la ficha de la prenda con su nueva foto_url
   */
  async guardar(idPrenda, archivo) {
    const prenda = await prendasRepo.findById(idPrenda);
    if (!prenda) throw notFound('Prenda');

    const tipo = tipoImagen(archivo.buffer);
    if (!tipo) throw new AppError(400, 'DATOS_INVALIDOS', 'El archivo no es una imagen JPG, PNG o WebP');

    // Nombre generado por nosotros: nunca se usa el que manda el cliente
    const nombre = `prenda-${idPrenda}-${crypto.randomBytes(8).toString('hex')}.${tipo.ext}`;
    await fs.mkdir(carpeta(), { recursive: true });
    await fs.writeFile(path.join(carpeta(), nombre), archivo.buffer);

    try {
      await prendasRepo.update(idPrenda, { foto_url: `${PREFIJO_URL}${nombre}` });
    } catch (err) {
      await fs.unlink(path.join(carpeta(), nombre)).catch(() => {});   // no dejar archivos huerfanos
      throw err;
    }

    // La foto anterior ya no se usa: se borra solo si la habiamos subido nosotros (no si era un enlace externo)
    const anterior = nombreDeFotoPropia(prenda.foto_url);
    if (anterior && anterior !== nombre) await fs.unlink(path.join(carpeta(), anterior)).catch(() => {});

    return prendas.ficha(idPrenda);
  },
};
