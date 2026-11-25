const express = require('express');
const cors = require('cors');
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

app.use('/api/v1', routes);
app.use((_req, res) => res.status(404).json({ error: 'RUTA_NO_ENCONTRADA' }));
app.use(errorHandler);

module.exports = app;
