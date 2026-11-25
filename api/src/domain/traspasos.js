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

// Transiciones validas: SOLICITADO -> APROBADO | RECHAZADO; APROBADO -> EN_CAMINO; EN_CAMINO -> RECIBIDO.
// RECHAZADO y RECIBIDO son estados finales.
const TRANSICIONES = {
  SOLICITADO: ['APROBADO', 'RECHAZADO'],
  APROBADO: ['EN_CAMINO'],
  RECHAZADO: [],
  EN_CAMINO: ['RECIBIDO'],
  RECIBIDO: [],
};

function transicionValida(de, a) {
  return (TRANSICIONES[de] || []).includes(a);
}

/**
 * Quien puede llevar el traspaso al estado `nuevo`:
 *  - APROBADO / RECHAZADO: gerente de la sucursal de origen o de destino, o administrador;
 *    nunca el propio solicitante.
 *  - EN_CAMINO: gerente de la sucursal de origen (la que envia) o administrador.
 *  - RECIBIDO: gerente de la sucursal de destino (la que recibe) o administrador.
 *  - El empleado no cambia estados.
 */
function puedeCambiarEstado(user, traspaso, nuevo) {
  if (user.rol !== 'administrador' && user.rol !== 'gerente') return false;
  const decide = nuevo === 'APROBADO' || nuevo === 'RECHAZADO';
  if (decide && user.id === traspaso.usuario_solicita) return false;
  if (user.rol === 'administrador') return ESTADOS.includes(nuevo);

  switch (nuevo) {
    case 'APROBADO':
    case 'RECHAZADO':
      return user.sucursalId === traspaso.id_sucursal_origen || user.sucursalId === traspaso.id_sucursal_destino;
    case 'EN_CAMINO':
      return user.sucursalId === traspaso.id_sucursal_origen;
    case 'RECIBIDO':
      return user.sucursalId === traspaso.id_sucursal_destino;
    default:
      return false;
  }
}

// Tipo de aviso que recibe el solicitante en cada cambio de estado
const TIPO_AVISO = {
  APROBADO: 'TRASPASO_APROBADO',
  RECHAZADO: 'TRASPASO_RECHAZADO',
  EN_CAMINO: 'TRASPASO_EN_CAMINO',
  RECIBIDO: 'TRASPASO_RECIBIDO',
};

function mensajeAviso(idTraspaso, estado) {
  switch (estado) {
    case 'APROBADO': return `Tu solicitud de traspaso #${idTraspaso} fue aprobada`;
    case 'RECHAZADO': return `Tu solicitud de traspaso #${idTraspaso} fue rechazada`;
    case 'EN_CAMINO': return `Tu traspaso #${idTraspaso} va en camino`;
    case 'RECIBIDO': return `Tu traspaso #${idTraspaso} fue recibido y el inventario ya se actualizo`;
    default: return `El traspaso #${idTraspaso} cambio a ${estado}`;
  }
}

module.exports = {
  ESTADOS, TRANSICIONES, TIPO_AVISO,
  detalleDuplicado, puedeVer, transicionValida, puedeCambiarEstado, mensajeAviso,
};
