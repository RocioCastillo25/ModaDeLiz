// CAPA DE NEGOCIO: solicitud y consulta de traspasos entre sucursales (RF-06).
const { withTransaction } = require('../db/pool');
const repo = require('../repositories/traspasosRepository');
const notificaciones = require('../repositories/notificacionesRepository');
const prendasRepo = require('../repositories/prendasRepository');
const sucursalesRepo = require('../repositories/sucursalesRepository');
const { detalleDuplicado, puedeVer } = require('../domain/traspasos');
const { AppError, notFound, forbidden, conflict } = require('../errors');

const invalido = (msg) => new AppError(400, 'DATOS_INVALIDOS', msg);

module.exports = {
  /**
   * Solicita piezas a otra sucursal. La sucursal destino es la del solicitante;
   * el administrador (que no tiene sucursal) debe indicarla en idSucursalDestino.
   * Nace en estado SOLICITADO. El stock NO se mueve hasta que se reciba.
   */
  async crear(user, { idSucursalOrigen, idSucursalDestino, detalle }) {
    let destino;
    if (user.rol === 'administrador') {
      if (!idSucursalDestino) throw invalido('El administrador debe indicar idSucursalDestino');
      destino = idSucursalDestino;
    } else {
      if (idSucursalDestino && idSucursalDestino !== user.sucursalId) {
        throw forbidden('Solo puedes solicitar piezas para tu propia sucursal');
      }
      destino = user.sucursalId;
    }
    if (idSucursalOrigen === destino) throw invalido('La sucursal de origen debe ser distinta a la de destino');

    const repetido = detalleDuplicado(detalle);
    if (repetido) throw invalido(`El detalle repite ${repetido}`);

    const origen = await sucursalesRepo.findById(idSucursalOrigen);
    if (!origen) throw notFound('Sucursal de origen');
    const sucursalDestino = await sucursalesRepo.findById(destino);
    if (!sucursalDestino) throw notFound('Sucursal de destino');

    return withTransaction(async (db) => {
      // Se valida la disponibilidad en el origen y se guarda talla/color tal como estan en el inventario
      const items = [];
      for (const it of detalle) {
        const prenda = await prendasRepo.findById(it.idPrenda);
        if (!prenda || !prenda.activa) throw notFound(`Prenda ${it.idPrenda}`);

        const stock = await repo.existencia({ idSucursal: idSucursalOrigen, ...it }, db);
        const disponibles = stock ? stock.cantidad : 0;
        if (disponibles < it.cantidad) {
          throw conflict(
            'STOCK_INSUFICIENTE',
            `${origen.nombre} solo tiene ${disponibles} pieza(s) de "${prenda.descripcion}" talla ${it.talla} color ${it.color}`
          );
        }
        items.push({ idPrenda: it.idPrenda, talla: stock.talla, color: stock.color, cantidad: it.cantidad });
      }

      const { id } = await repo.insertar({ idOrigen: idSucursalOrigen, idDestino: destino, idSolicita: user.id }, db);
      await repo.insertarDetalle(id, items, db);

      // Aviso a los gerentes de la sucursal que debe surtir las piezas
      const piezas = items.reduce((suma, it) => suma + it.cantidad, 0);
      const mensaje = `Nueva solicitud de traspaso #${id} de ${sucursalDestino.nombre}: ${piezas} pieza(s)`;
      for (const g of await notificaciones.gerentesActivos(idSucursalOrigen, db)) {
        if (g.id !== user.id) {
          await notificaciones.crear({ idUsuario: g.id, idTraspaso: id, tipo: 'TRASPASO_SOLICITADO', mensaje }, db);
        }
      }

      return repo.findById(id, db);
    });
  },

  /** Traspasos visibles para el usuario segun su rol. */
  listar(user, filtros) {
    return repo.list({ user, ...filtros });
  },

  async obtener(user, id) {
    const traspaso = await repo.findById(id);
    if (!traspaso) throw notFound('Traspaso');
    if (!puedeVer(user, traspaso)) throw forbidden('No puedes ver este traspaso');
    return traspaso;
  },
};
