// Configuracion centralizada. Todo viene de variables de entorno.
const env = process.env;

module.exports = {
  port: Number(env.PORT || 3000),
  // Carpeta de fotos subidas. En Docker es un volumen (UPLOADS_DIR=/app/uploads).
  uploadsDir: env.UPLOADS_DIR || require('node:path').join(__dirname, '..', '..', 'uploads'),
  db: {
    host: env.DB_HOST || 'localhost',
    port: Number(env.DB_PORT || 5432),
    user: env.DB_USER || 'checklizz',
    password: env.DB_PASSWORD || 'checklizz_dev',
    database: env.DB_NAME || 'checklizz',
  },
  keycloak: {
    internalUrl: env.KEYCLOAK_INTERNAL_URL || 'http://localhost:8080',
    realm: env.KEYCLOAK_REALM || 'checklizz',
    adminUser: env.KEYCLOAK_ADMIN || 'admin',
    adminPassword: env.KEYCLOAK_ADMIN_PASSWORD || 'admin',
    allowedIssuers: (env.ALLOWED_ISSUERS || 'http://localhost:8080/realms/checklizz')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean),
  },
};
