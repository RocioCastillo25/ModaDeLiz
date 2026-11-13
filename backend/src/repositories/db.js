const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'db-checklizz',
  user: process.env.DB_USER || 'admin_checklizz',
  password: process.env.DB_PASSWORD || 'password_seguro',
  database: process.env.DB_NAME || 'checklizz_db',
  port: process.env.DB_PORT || 5432,
});

pool.on('error', (err, client) => {
  console.error('Error inesperado en el cliente de PostgreSQL', err);
  process.exit(-1);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  getClient: () => pool.connect(), // Esencial para las transacciones ACID
};