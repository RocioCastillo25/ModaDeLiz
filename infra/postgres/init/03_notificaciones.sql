-- =====================================================================
-- CheckLizz - Notificaciones de traspasos (RF-07)
-- Cada cambio en un traspaso deja un aviso para quien debe enterarse.
-- La app y la web las consultan periodicamente (GET /notificaciones).
--
-- OJO: los scripts de /docker-entrypoint-initdb.d solo corren la PRIMERA vez
-- que se crea el volumen. Si ya tienes la base creada, aplica este archivo a mano:
--   docker exec -i checklizz-postgres psql -U checklizz -d checklizz < infra/postgres/init/03_notificaciones.sql
-- (o borra el volumen con `docker compose down -v` y vuelve a levantar).
-- =====================================================================

CREATE TABLE IF NOT EXISTS notificaciones (
    id           BIGSERIAL PRIMARY KEY,
    id_usuario   INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,   -- quien recibe el aviso
    id_traspaso  INT REFERENCES traspasos(id) ON DELETE CASCADE,
    tipo         VARCHAR(30) NOT NULL
                 CHECK (tipo IN ('TRASPASO_SOLICITADO','TRASPASO_APROBADO','TRASPASO_RECHAZADO',
                                 'TRASPASO_EN_CAMINO','TRASPASO_RECIBIDO')),
    mensaje      VARCHAR(255) NOT NULL,
    leida        BOOLEAN NOT NULL DEFAULT FALSE,
    creada_en    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Consulta tipica: "mis avisos no leidos, los mas recientes primero"
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario
    ON notificaciones (id_usuario, leida, creada_en DESC);
