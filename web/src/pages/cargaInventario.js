// Lógica de la carga inicial de inventario, sin interfaz. La usan la captura por filas y la carga por CSV.
// Cada fila suma (o reemplaza, según el modo) la existencia de una prenda + talla + color en una sucursal.
//
// La API solo ofrece PUT /inventario, que FIJA la cantidad. Para sumar se lee la existencia actual
// (GET /inventario) y se envía actual + nueva. Esto no es atómico: una venta registrada entre la lectura
// y la escritura se perdería. Lo correcto es que la API ofrezca una operación de suma con bloqueo de fila.

export const MODOS = { sumar: 'sumar', reemplazar: 'reemplazar' };

let siguienteId = 1;
export const filaVacia = (idSucursal = '') => ({
  id: siguienteId++, codigo: '', idSucursal: String(idSucursal), talla: '', color: '', cantidad: '', estado: null,
});

/** Normaliza lo capturado: talla en mayúsculas (M, CH, G) y color con mayúscula inicial (Blanco). */
export function normalizar(f) {
  const color = f.color.trim().toLowerCase();
  return {
    ...f,
    codigo: f.codigo.trim(),
    talla: f.talla.trim().toUpperCase(),
    color: color ? color[0].toUpperCase() + color.slice(1) : '',
    cantidad: String(f.cantidad).trim(),
  };
}

export const estaVacia = (f) => !f.codigo.trim() && !f.talla.trim() && !f.color.trim() && !String(f.cantidad).trim();

const clave = (f) => [f.codigo, f.idSucursal, f.talla, f.color.toLowerCase()].join('|');

/**
 * Valida una lista de filas ya normalizadas. Devuelve { [idFila]: 'mensaje' } con el primer problema de cada una.
 * `sucursalFija` es la sucursal del gerente (las demás se rechazan); null para la administradora.
 * Al sumar, la cantidad debe ser al menos 1 y las filas repetidas se permiten (se suman una tras otra).
 * Al reemplazar, se admite 0 y una fila repetida es un error (la segunda pisaría a la primera).
 */
export function validarFilas(filas, sucursalFija = null, modo = MODOS.sumar) {
  const sumar = modo === MODOS.sumar;
  const errores = {};
  const vistas = new Map();
  filas.forEach((f) => {
    let e;
    if (!f.codigo) e = 'Falta el código de barras.';
    else if (!f.idSucursal) e = 'Elige la sucursal.';
    else if (sucursalFija && Number(f.idSucursal) !== sucursalFija) e = 'Solo puedes cargar a tu sucursal.';
    else if (!f.talla) e = 'Falta la talla.';
    else if (f.talla.length > 20) e = 'La talla admite máximo 20 caracteres.';
    else if (!f.color) e = 'Falta el color.';
    else if (f.color.length > 40) e = 'El color admite máximo 40 caracteres.';
    else if (!/^\d+$/.test(f.cantidad)) e = `La cantidad debe ser un número entero de ${sumar ? 1 : 0} en adelante.`;
    else if (sumar && Number(f.cantidad) === 0) e = 'Para sumar, la cantidad debe ser al menos 1.';
    else if (!sumar && vistas.has(clave(f))) e = `Repetida: es la misma prenda, sucursal, talla y color que la fila ${vistas.get(clave(f))}.`;
    if (e) errores[f.id] = e;
    else vistas.set(clave(f), filas.indexOf(f) + 1);
  });
  return errores;
}

/**
 * Guarda las filas una por una para reportar el resultado de cada una sin detener la carga.
 * `alAvanzar(idFila, { tipo: 'ok' | 'error', mensaje })` se llama después de cada fila.
 */
export async function guardarFilas(repo, filas, alAvanzar, modo = MODOS.sumar) {
  const prendas = new Map(); // código → prenda | null (cache para no pedir la misma prenda varias veces)
  let ok = 0;
  for (const f of filas) {
    try {
      if (!prendas.has(f.codigo)) {
        prendas.set(f.codigo, await repo.getPrendaPorCodigo(f.codigo).catch((e) => {
          if (e.status === 404) return null;
          throw e;
        }));
      }
      const prenda = prendas.get(f.codigo);
      if (!prenda) {
        alAvanzar(f.id, { tipo: 'error', mensaje: 'No existe una prenda con este código. Dala de alta primero.' });
        continue;
      }
      const idSucursal = Number(f.idSucursal);
      let color = f.color;
      let anterior = 0;
      if (modo === MODOS.sumar) {
        // Se lee justo antes de escribir para que las filas repetidas también se acumulen.
        const actuales = await repo.listInventario({ prendaId: prenda.id, sucursalId: idSucursal });
        const actual = actuales.find((i) => i.talla === f.talla && i.color.toLowerCase() === f.color.toLowerCase());
        if (actual) { anterior = actual.cantidad; color = actual.color; } // respeta cómo ya estaba escrito el color
      }
      const cantidad = modo === MODOS.sumar ? anterior + Number(f.cantidad) : Number(f.cantidad);
      await repo.fijarExistencia({ idPrenda: prenda.id, idSucursal, talla: f.talla, color, cantidad });
      ok += 1;
      alAvanzar(f.id, {
        tipo: 'ok',
        mensaje: modo === MODOS.sumar ? `${prenda.descripcion}: ${anterior} → ${cantidad}` : `${prenda.descripcion}: ${cantidad}`,
      });
    } catch (e) {
      alAvanzar(f.id, { tipo: 'error', mensaje: e.message });
    }
  }
  return { ok, errores: filas.length - ok };
}
