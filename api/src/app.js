const express = require('express');
const cors = require('cors');
const config = require('./config/env');
const { pool } = require('./db/pool');
const routes = require('./routes');
const { errorHandler } = require('./middlewares/errorHandler');

const app = express();
// Content-Disposition se expone para que la web lea el nombre del archivo al descargar un reporte
app.use(cors({ exposedHeaders: ['Content-Disposition'] }));
app.use(express.json());

// Publico: sirve para comprobar que la API y la base de datos estan vivas
app.get('/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'ok', time: new Date().toISOString() });
  } catch {
    res.status(503).json({ status: 'error', db: 'caida' });
  }
});

// Fotos de prendas: publicas (sin token) para que la app y la web las muestren con una imagen normal.
// nosniff evita que el navegador trate un archivo subido como si fuera otra cosa (HTML, script...).
app.use('/uploads', express.static(config.uploadsDir, {
  index: false,
  maxAge: '1d',
  setHeaders: (res) => res.set('X-Content-Type-Options', 'nosniff'),
}));

app.use('/api/v1', routes);
app.use((_req, res) => res.status(404).json({ error: 'RUTA_NO_ENCONTRADA' }));
app.use(errorHandler);

module.exports = app;
