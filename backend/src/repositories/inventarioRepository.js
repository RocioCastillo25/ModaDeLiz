const db = require('./db');

const registrarVentaConAuditoria = async (idPrenda, idSucursal, talla, color, cantidadVendida, idUsuario) => {
  const client = await db.getClient();
  try {
    // 1. Iniciar la transacción ACID
    await client.query('BEGIN');

    // 2. Consultar el stock actual
    const stockQuery = `
      SELECT id, cantidad FROM inventario_sucursal 
      WHERE id_prenda = $1 AND id_sucursal = $2 AND talla = $3 AND color = $4
      FOR UPDATE;
    `;
    const stockResult = await client.query(stockQuery, [idPrenda, idSucursal, talla, color]);

    if (stockResult.rows.length === 0) {
      throw new Error('La prenda no existe en el inventario de esta sucursal.');
    }

    const inventario = stockResult.rows[0];
    const cantidadAnterior = inventario.cantidad;
    const cantidadNueva = cantidadAnterior - cantidadVendida;

    if (cantidadNueva < 0) {
      throw new Error('Stock insuficiente para completar la venta.');
    }

    // 3. Actualizar el inventario (La restricción CHECK en SQL también protegerá esto)
    const updateStockQuery = `
      UPDATE inventario_sucursal 
      SET cantidad = $1 
      WHERE id = $2;
    `;
    await client.query(updateStockQuery, [cantidadNueva, inventario.id]);

    // 4. Registrar en la bitácora de auditoría
    const auditQuery = `
      INSERT INTO historial_auditoria_inventario 
      (id_inventario, tipo_movimiento, cantidad_anterior, cantidad_nueva, id_usuario) 
      VALUES ($1, 'VENTA', $2, $3, $4);
    `;
    await client.query(auditQuery, [inventario.id, cantidadAnterior, cantidadNueva, idUsuario]);

    // 5. Confirmar transacción si todo salió bien
    await client.query('COMMIT');
    return { success: true, message: 'Venta registrada y stock actualizado correctamente.' };

  } catch (error) {
    // Si hay un error, revertimos todos los cambios
    await client.query('ROLLBACK');
    throw error;
  } finally {
    // Liberar el cliente
    client.release();
  }
};

module.exports = {
  registrarVentaConAuditoria,
};