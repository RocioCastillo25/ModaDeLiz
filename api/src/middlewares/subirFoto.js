// MIDDLEWARE: recibe la foto (multipart/form-data, campo `foto`) en memoria, con limite de 5 MB.
// Traduce los errores de multer a errores de negocio (400) para que respondan igual que el resto de la API.
// Que el archivo sea realmente una imagen se valida despues, por contenido, en el servicio de fotos.
const multer = require('multer');
const { AppError } = require('../errors');
const { TAMANO_MAXIMO } = require('../domain/fotos');

const recibir = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: TAMANO_MAXIMO, files: 1, fields: 0 },
}).single('foto');

const invalido = (mensaje) => new AppError(400, 'DATOS_INVALIDOS', mensaje);

function subirFoto(req, res, next) {
  recibir(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') return next(invalido('La foto pesa mas de 5 MB'));
      if (err.code === 'LIMIT_UNEXPECTED_FILE') return next(invalido('Envia un solo archivo en el campo "foto"'));
      if (err.code === 'LIMIT_FIELD_COUNT') return next(invalido('Solo se acepta el archivo en el campo "foto"'));
      return next(invalido(`No se pudo leer el archivo: ${err.message}`));
    }
    if (err) {
      // Cuerpo que no es multipart, o que llega cortado
      return next(invalido('La peticion debe ser multipart/form-data con el archivo en el campo "foto"'));
    }
    if (!req.file) return next(invalido('Falta el archivo en el campo "foto"'));
    return next();
  });
}

module.exports = { subirFoto };
