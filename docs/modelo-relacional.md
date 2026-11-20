# CheckLizz · Modelo relacional

Diagrama Entidad-Relación de la base de datos PostgreSQL (7 tablas). Se genera a partir de `infra/postgres/init/01_schema.sql`. GitHub lo muestra como dibujo; si no, se puede pegar el bloque en https://mermaid.live

```mermaid
erDiagram
    SUCURSALES ||--o{ USUARIOS : "tiene asignados"
    SUCURSALES ||--o{ INVENTARIO_SUCURSAL : "guarda existencias"
    PRENDAS ||--o{ INVENTARIO_SUCURSAL : "se almacena como"
    SUCURSALES ||--o{ TRASPASOS : "es origen de"
    SUCURSALES ||--o{ TRASPASOS : "es destino de"
    USUARIOS ||--o{ TRASPASOS : "solicita"
    USUARIOS |o--o{ TRASPASOS : "aprueba"
    TRASPASOS ||--|{ DETALLE_TRASPASO : "contiene"
    PRENDAS ||--o{ DETALLE_TRASPASO : "se traspasa en"
    INVENTARIO_SUCURSAL ||--o{ HISTORIAL_AUDITORIA_INVENTARIO : "registra cambios"
    USUARIOS |o--o{ HISTORIAL_AUDITORIA_INVENTARIO : "realiza"

    SUCURSALES {
        int id PK
        varchar nombre UK
        varchar ubicacion
    }

    USUARIOS {
        int id PK
        varchar nombre
        varchar email
        uuid id_keycloak UK
        varchar rol "administrador, gerente o empleado"
        int id_sucursal_asignada FK
        boolean activo
        timestamptz creado_en
    }

    PRENDAS {
        int id PK
        varchar codigo_barras UK
        varchar descripcion
        varchar marca
        varchar categoria
        varchar temporada
        text foto_url
        int umbral_alerta "minimo para alerta de stock bajo"
        boolean activa
        timestamptz creado_en
    }

    INVENTARIO_SUCURSAL {
        int id PK
        int id_prenda FK
        int id_sucursal FK
        varchar talla
        varchar color
        int cantidad "CHECK cantidad >= 0"
    }

    TRASPASOS {
        int id PK
        int id_sucursal_origen FK
        int id_sucursal_destino FK
        int usuario_solicita FK
        int usuario_aprueba FK
        varchar estado "SOLICITADO, APROBADO, RECHAZADO, EN_CAMINO, RECIBIDO"
        timestamptz fecha_solicitud
        timestamptz fecha_actualizacion
    }

    DETALLE_TRASPASO {
        int id_traspaso PK, FK
        int id_prenda PK, FK
        varchar talla PK
        varchar color PK
        int cantidad "CHECK cantidad > 0"
    }

    HISTORIAL_AUDITORIA_INVENTARIO {
        bigint id PK
        int id_inventario FK
        varchar tipo_movimiento "alta, venta, traspaso o ajuste"
        int cantidad_anterior
        int cantidad_nueva
        int id_usuario FK
        timestamptz timestamp
    }
```

## Reglas que garantiza la base de datos
- `inventario_sucursal.cantidad >= 0`: el stock nunca queda negativo.
- `UNIQUE (id_prenda, id_sucursal, talla, color)`: una sola fila por prenda, talla y color en cada sucursal.
- `traspasos`: origen y destino deben ser distintos; el estado solo admite los 5 valores definidos.
- `usuarios`: gerente y empleado siempre tienen sucursal; solo el administrador puede no tenerla.
- `historial_auditoria_inventario`: cada venta, alta, traspaso o ajuste deja el valor anterior y el nuevo, quién lo hizo y cuándo.
