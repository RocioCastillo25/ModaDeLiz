-- =====================================================================
-- CheckLizz - Esquema relacional (PostgreSQL 15+)
-- Se ejecuta automaticamente la primera vez que se crea el volumen.
-- =====================================================================

CREATE TABLE sucursales (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(80)  NOT NULL UNIQUE,
    ubicacion   VARCHAR(160)
);

CREATE TABLE usuarios (
    id                    SERIAL PRIMARY KEY,
    nombre                VARCHAR(120) NOT NULL,
    email                 VARCHAR(160),
    id_keycloak           UUID NOT NULL UNIQUE,
    rol                   VARCHAR(20)  NOT NULL
                          CHECK (rol IN ('administrador', 'gerente', 'empleado')),
    id_sucursal_asignada  INT REFERENCES sucursales(id),
    activo                BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en             TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Gerente y empleado siempre pertenecen a una sucursal
    CONSTRAINT chk_sucursal_por_rol CHECK (rol = 'administrador' OR id_sucursal_asignada IS NOT NULL)
);

CREATE TABLE prendas (
    id             SERIAL PRIMARY KEY,
    codigo_barras  VARCHAR(64)  NOT NULL UNIQUE,
    descripcion    VARCHAR(200) NOT NULL,
    marca          VARCHAR(80),
    categoria      VARCHAR(80),
    temporada      VARCHAR(40),
    foto_url       TEXT,
    umbral_alerta  INT NOT NULL DEFAULT 2 CHECK (umbral_alerta >= 0),
    activa         BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE inventario_sucursal (
    id           SERIAL PRIMARY KEY,
    id_prenda    INT NOT NULL REFERENCES prendas(id),
    id_sucursal  INT NOT NULL REFERENCES sucursales(id),
    talla        VARCHAR(20) NOT NULL,
    color        VARCHAR(40) NOT NULL,
    cantidad     INT NOT NULL DEFAULT 0 CHECK (cantidad >= 0),   -- restriccion clave: nunca negativo
    UNIQUE (id_prenda, id_sucursal, talla, color)
);
CREATE INDEX idx_inventario_sucursal ON inventario_sucursal (id_sucursal);
CREATE INDEX idx_inventario_prenda   ON inventario_sucursal (id_prenda);

CREATE TABLE traspasos (
    id                   SERIAL PRIMARY KEY,
    id_sucursal_origen   INT NOT NULL REFERENCES sucursales(id),
    id_sucursal_destino  INT NOT NULL REFERENCES sucursales(id),
    usuario_solicita     INT NOT NULL REFERENCES usuarios(id),
    usuario_aprueba      INT REFERENCES usuarios(id),
    estado               VARCHAR(20) NOT NULL DEFAULT 'SOLICITADO'
                         CHECK (estado IN ('SOLICITADO','APROBADO','RECHAZADO','EN_CAMINO','RECIBIDO')),
    fecha_solicitud      TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_actualizacion  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (id_sucursal_origen <> id_sucursal_destino)
);

-- Se agregan talla y color: el inventario se lleva por prenda + talla + color
CREATE TABLE detalle_traspaso (
    id_traspaso  INT NOT NULL REFERENCES traspasos(id) ON DELETE CASCADE,
    id_prenda    INT NOT NULL REFERENCES prendas(id),
    talla        VARCHAR(20) NOT NULL,
    color        VARCHAR(40) NOT NULL,
    cantidad     INT NOT NULL CHECK (cantidad > 0),
    PRIMARY KEY (id_traspaso, id_prenda, talla, color)
);

CREATE TABLE historial_auditoria_inventario (
    id                 BIGSERIAL PRIMARY KEY,
    id_inventario      INT NOT NULL REFERENCES inventario_sucursal(id),
    tipo_movimiento    VARCHAR(20) NOT NULL
                       CHECK (tipo_movimiento IN ('alta','venta','traspaso','ajuste')),
    cantidad_anterior  INT NOT NULL,
    cantidad_nueva     INT NOT NULL,
    id_usuario         INT REFERENCES usuarios(id),
    "timestamp"        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_auditoria_inventario ON historial_auditoria_inventario (id_inventario);
CREATE INDEX idx_auditoria_fecha      ON historial_auditoria_inventario ("timestamp");
