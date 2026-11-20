// CAPA DE NEGOCIO: catalogo de prendas.
const repo = require('../repositories/prendasRepository');
const inventarioRepo = require('../repositories/inventarioRepository');
const { notFound, conflict } = require('../errors');

module.exports = {
  buscar: (filtros) => repo.search(filtros),

  /** Ficha de prenda (MOV-02): datos + existencias en las 5 sucursales. */
  async ficha(id) {
    const prenda = await repo.findById(id);
    if (!prenda) throw notFound('Prenda');
    return { ...prenda, existencias: await inventarioRepo.matrizPorPrenda(id) };
  },

  /** Busqueda por codigo de barras (MOV-03: resultado del escaner). */
  async fichaPorCodigo(codigo) {
    const prenda = await repo.findByCodigo(codigo);
    if (!prenda) throw notFound('Prenda');
    return { ...prenda, existencias: await inventarioRepo.matrizPorPrenda(prenda.id) };
  },

  async crear(datos) {
    if (await repo.findByCodigo(datos.codigo_barras)) {
      throw conflict('CODIGO_DUPLICADO', 'Ya existe una prenda con ese codigo de barras');
    }
    return repo.create(datos);
  },

  async actualizar(id, datos) {
    const p = await repo.update(id, datos);
    if (!p) throw notFound('Prenda');
    return p;
  },

  async desactivar(id) {
    const p = await repo.setActiva(id, false);
    if (!p) throw notFound('Prenda');
    return p;
  },
};
