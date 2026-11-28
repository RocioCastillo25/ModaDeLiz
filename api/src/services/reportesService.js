// CAPA DE NEGOCIO: reportes de existencias, mas vendido y stock bajo (RF-13, RF-14, RF-15).
const reportesRepo = require('../repositories/reportesRepository');
const inventarioRepo = require('../repositories/inventarioRepository');
const sucursalesRepo = require('../repositories/sucursalesRepository');
const dominio = require('../domain/reportes');
const { aPdf } = require('../exportadores/pdf');
const { aXlsx } = require('../exportadores/xlsx');
const { AppError, notFound, forbidden } = require('../errors');

/**
 * A que sucursal(es) puede acceder el usuario:
 *  - administrador: la que pida, o todas (undefined)
 *  - gerente: solo la suya; pedir otra es 403
 *  - empleado: ninguna
 */
function alcance(user, sucursalId) {
  if (user.rol === 'administrador') return sucursalId;
  if (user.rol === 'gerente') {
    if (sucursalId && sucursalId !== user.sucursalId) throw forbidden('Solo puedes consultar los reportes de tu sucursal');
    return user.sucursalId;
  }
  throw forbidden('Tu rol no puede consultar reportes');
}

async function sucursalesA(idSucursal) {
  if (!idSucursal) return sucursalesRepo.list();
  const sucursal = await sucursalesRepo.findById(idSucursal);
  if (!sucursal) throw notFound('Sucursal');
  return [sucursal];
}

module.exports = {
  async existencias(user, { sucursalId } = {}, ahora = new Date()) {
    const idSucursal = alcance(user, sucursalId);
    const sucursales = await sucursalesA(idSucursal);
    const filas = await reportesRepo.existencias({ sucursalId: idSucursal });
    return dominio.reporteExistencias({ sucursales, filas, generadoEn: ahora.toISOString() });
  },

  /** Solo el administrador: es informacion comercial de toda la cadena. */
  async masVendidos(user, { sucursalId, desde, hasta, limite = 10 } = {}, ahora = new Date()) {
    if (user.rol !== 'administrador') throw forbidden('Solo el administrador puede ver lo mas vendido');
    if (!dominio.rangoValido(desde, hasta)) {
      throw new AppError(400, 'DATOS_INVALIDOS', 'La fecha "desde" no puede ser posterior a "hasta"');
    }
    const sucursal = sucursalId ? (await sucursalesA(sucursalId))[0] : null;
    const items = await reportesRepo.masVendidos({ sucursalId, desde, hasta, limite });
    return dominio.reporteMasVendidos({
      items, desde, hasta, sucursal: sucursal && sucursal.nombre, generadoEn: ahora.toISOString(),
    });
  },

  async stockBajo(user, { sucursalId } = {}, ahora = new Date()) {
    const idSucursal = alcance(user, sucursalId);
    if (idSucursal) await sucursalesA(idSucursal);   // 404 si el administrador pide una que no existe
    const filas = await inventarioRepo.list({ sucursalId: idSucursal, bajoUmbral: true });
    const items = filas.map(({ id, id_prenda, descripcion, id_sucursal, sucursal, talla, color, cantidad, umbral_alerta }) => (
      { id, id_prenda, descripcion, id_sucursal, sucursal, talla, color, cantidad, umbral_alerta }
    ));
    return dominio.reporteStockBajo({ items, generadoEn: ahora.toISOString() });
  },

  /** Convierte un reporte ya armado a PDF o Excel: { tipo, nombre, cuerpo }. */
  async exportar(reporte, formato, base) {
    const cuerpo = formato === 'pdf' ? await aPdf(reporte.documento) : await aXlsx(reporte.documento);
    return {
      tipo: dominio.TIPOS_CONTENIDO[formato],
      nombre: dominio.nombreArchivo(base, formato, reporte.documento.generadoEn),
      cuerpo,
    };
  },
};
