// PATRON SINGLETON: un unico pool de conexiones para toda la API.
// Node cachea los modulos, asi que este objeto se crea una sola vez.
const { Pool } = require('pg');
const { db } = require('../config/env');

const pool = new Pool({ ...db, max: 10 });

/**
 * Ejecuta `fn(client)` dentro de una transaccion ACID.
 * BEGIN -> fn -> COMMIT, o ROLLBACK si algo falla.
 */
async function withTransaction(fn) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = { pool, withTransaction };
