// CAPA DE NEGOCIO: carga de inventario y ventas (descuento de stock).
const { withTransaction } = require('../db/pool');
const repo = require('../repositories/inventarioRepository');
const prendasRepo = require('../repositories/prendasRepository');
const sucursalesRepo = require('../repositories/sucursalesRepository');
const { notFound, forbidden, conflict, AppError } = require('../errors');

/** El administrador opera en cualquier sucursal; los demas solo en la suya. */
function verificarSucursal(user, idSucursal) {
  if (user.rol !== 'administrador' && user.sucursalId !== idSucursal) {
    throw forbidden('Solo puedes operar sobre tu propia sucursal');
  }
}

module.exports = {
  list: (filtros) => repo.list(filtros),

  async historial(id) {
    return repo.historial(id);
  },

  /**
   * Carga inicial / ajuste (WEB-02). Fija la cantidad de una prenda+talla+color en una sucursal.
   * Crea el registro si no existe ('alta') o lo corrige ('ajuste'). Todo en una transaccion.
   */
  async fijarExistencia(user, { idPrenda, idSucursal, talla, color, cantidad }) {
    verificarSucursal(user, idSucursal);
    if (!(await prendasRepo.findById(idPrenda))) throw notFound('Prenda');
    if (!(await sucursalesRepo.findById(idSucursal))) throw notFound('Sucursal');

    return withTransaction(async (db) => {
      const actual = await repo.lockByClave({ idPrenda, idSucursal, talla, color }, db);
      if (!actual) {
        const nuevo = await repo.insert({ idPrenda, idSucursal, talla, color, cantidad }, db);
        await repo.registrarAuditoria({ idInventario: nuevo.id, tipo: 'alta', anterior: 0, nueva: cantidad, idUsuario: user.id }, db);
        return nuevo;
      }
      const actualizado = await repo.setCantidad(actual.id, cantidad, db);
      await repo.registrarAuditoria({ idInventario: actual.id, tipo: 'ajuste', anterior: actual.cantidad, nueva: cantidad, idUsuario: user.id }, db);
      return actualizado;
    });
  },

  /**
   * Venta (MOV-04): resta piezas. La fila se bloquea con FOR UPDATE, asi dos empleados
   * vendiendo la ultima pieza a la vez no dejan el stock negativo.
   */
  async vender(user, { idInventario, cantidad }) {
    return withTransaction(async (db) => {
      const fila = await repo.lockById(idInventario, db);
      if (!fila) throw notFound('Registro de inventario');
      verificarSucursal(user, fila.id_sucursal);
      if (fila.cantidad < cantidad) {
        throw conflict('STOCK_INSUFICIENTE', `Solo hay ${fila.cantidad} pieza(s) disponibles`);
      }
      const nueva = fila.cantidad - cantidad;
      const actualizado = await repo.setCantidad(fila.id, nueva, db);
      await repo.registrarAuditoria({ idInventario: fila.id, tipo: 'venta', anterior: fila.cantidad, nueva, idUsuario: user.id }, db);
      return actualizado;
    });
  },
};
