// DOMINIO DE TRASPASOS: reglas puras (sin base de datos), faciles de probar.

const ESTADOS = ['SOLICITADO', 'APROBADO', 'RECHAZADO', 'EN_CAMINO', 'RECIBIDO'];

const normaliza = (v) => String(v).trim().toLowerCase();

/**
 * Devuelve la descripcion del primer renglon repetido (misma prenda, talla y color)
 * o null si no hay repetidos. Un traspaso no puede pedir dos veces lo mismo.
 */
function detalleDuplicado(detalle) {
  const vistos = new Set();
  for (const item of detalle) {
    const clave = `${item.idPrenda}|${normaliza(item.talla)}|${normaliza(item.color)}`;
    if (vistos.has(clave)) return `prenda ${item.idPrenda}, talla ${item.talla}, color ${item.color}`;
    vistos.add(clave);
  }
  return null;
}

/**
 * Visibilidad de un traspaso segun el rol:
 *  - administrador: todos
 *  - gerente: los de su sucursal (como origen o como destino)
 *  - empleado: solo las solicitudes que el creo
 */
function puedeVer(user, traspaso) {
  if (user.rol === 'administrador') return true;
  if (user.rol === 'gerente') {
    return traspaso.id_sucursal_origen === user.sucursalId || traspaso.id_sucursal_destino === user.sucursalId;
  }
  return traspaso.usuario_solicita === user.id;
}

module.exports = { ESTADOS, detalleDuplicado, puedeVer };
