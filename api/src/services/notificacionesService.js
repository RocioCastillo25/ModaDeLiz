// CAPA DE NEGOCIO: avisos del usuario autenticado (RF-07). Cada usuario solo ve y marca los suyos.
const repo = require('../repositories/notificacionesRepository');
const { notFound } = require('../errors');

module.exports = {
  listar(user, { soloNoLeidas = false, limite = 50 } = {}) {
    return repo.listar(user.id, { soloNoLeidas, limite });
  },

  async resumen(user) {
    return { no_leidas: await repo.contarNoLeidas(user.id) };
  },

  async marcarLeida(user, id) {
    // Un aviso ajeno responde igual que uno inexistente, para no revelar que existe
    const aviso = await repo.marcarLeida(id, user.id);
    if (!aviso) throw notFound('Notificacion');
    return aviso;
  },

  async marcarTodasLeidas(user) {
    return { marcadas: await repo.marcarTodasLeidas(user.id) };
  },
};
