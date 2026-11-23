// CAPA DE NEGOCIO: solicitud y consulta de traspasos entre sucursales (RF-06).
const { withTransaction } = require('../db/pool');
const repo = require('../repositories/traspasosRepository');
const notificaciones = require('../repositories/notificacionesRepository');
const prendasRepo = require('../repositories/prendasRepository');
const sucursalesRepo = require('../repositories/sucursalesRepository');
const inventarioRepo = require('../repositories/inventarioRepository');
const {
  detalleDuplicado, puedeVer, transicionValida, puedeCambiarEstado, mensajeAviso, TIPO_AVISO,
} = require('../domain/traspasos');
const { AppError, notFound, forbidden, conflict } = require('../errors');

const invalido = (msg) => new AppError(400, 'DATOS_INVALIDOS', msg);

/**
 * Al recibir: por cada renglon resta del origen y suma al destino, con auditoria `traspaso`.
 * Corre dentro de la transaccion de cambiarEstado: si algo falla, no se mueve nada.
 */
async function moverStock(traspaso, user, db) {
  for (const it of await repo.detalle(traspaso.id, db)) {
    const origen = await repo.bloquearExistencia({ idSucursal: traspaso.id_sucursal_origen, ...it }, db);
    if (!origen || origen.cantidad < it.cantidad) {
      throw conflict(
        'STOCK_INSUFICIENTE',
        `El origen ya no tiene ${it.cantidad} pieza(s) de "${it.descripcion}" talla ${it.talla} color ${it.color} ` +
        `(tiene ${origen ? origen.cantidad : 0})`
      );
    }
    const restante = origen.cantidad - it.cantidad;
    await inventarioRepo.setCantidad(origen.id, restante, db);
    await inventarioRepo.registrarAuditoria(
      { idInventario: origen.id, tipo: 'traspaso', anterior: origen.cantidad, nueva: restante, idUsuario: user.id }, db
    );

    const destino = await repo.bloquearExistencia({ idSucursal: traspaso.id_sucursal_destino, ...it }, db);
    if (destino) {
      const total = destino.cantidad + it.cantidad;
      await inventarioRepo.setCantidad(destino.id, total, db);
      await inventarioRepo.registrarAuditoria(
        { idInventario: destino.id, tipo: 'traspaso', anterior: destino.cantidad, nueva: total, idUsuario: user.id }, db
      );
    } else {
      const fila = await inventarioRepo.insert({
        idPrenda: it.idPrenda, idSucursal: traspaso.id_sucursal_destino, talla: origen.talla, color: origen.color, cantidad: it.cantidad,
      }, db);
      await inventarioRepo.registrarAuditoria(
        { idInventario: fila.id, tipo: 'traspaso', anterior: 0, nueva: it.cantidad, idUsuario: user.id }, db
      );
    }
  }
}

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

  /**
   * Cambia el estado respetando las transiciones validas y los permisos por rol y sucursal.
   * Al pasar a RECIBIDO mueve el stock en la misma transaccion. Avisa al solicitante.
   */
  async cambiarEstado(user, idTraspaso, nuevoEstado) {
    return withTransaction(async (db) => {
      const traspaso = await repo.bloquear(idTraspaso, db);
      if (!traspaso) throw notFound('Traspaso');
      if (!puedeVer(user, traspaso)) throw forbidden('No puedes ver este traspaso');
      if (!puedeCambiarEstado(user, traspaso, nuevoEstado)) {
        throw forbidden(`Tu rol o sucursal no puede marcar este traspaso como ${nuevoEstado}`);
      }
      if (!transicionValida(traspaso.estado, nuevoEstado)) {
        throw conflict('TRANSICION_NO_PERMITIDA', `No se puede pasar de ${traspaso.estado} a ${nuevoEstado}`);
      }

      if (nuevoEstado === 'RECIBIDO') await moverStock(traspaso, user, db);

      const decide = nuevoEstado === 'APROBADO' || nuevoEstado === 'RECHAZADO';
      await repo.cambiarEstado({ id: idTraspaso, estado: nuevoEstado, idAprueba: decide ? user.id : null }, db);

      // Aviso al solicitante (si el mismo hizo el cambio, ya lo sabe)
      if (traspaso.usuario_solicita !== user.id) {
        await notificaciones.crear({
          idUsuario: traspaso.usuario_solicita,
          idTraspaso,
          tipo: TIPO_AVISO[nuevoEstado],
          mensaje: mensajeAviso(idTraspaso, nuevoEstado),
        }, db);
      }

      return repo.findById(idTraspaso, db);
    });
  },
};
