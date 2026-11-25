// Lógica de la carga inicial de inventario, sin interfaz. La usan la captura por filas y la carga por CSV.
// Cada fila fija (reemplaza) la existencia de una prenda + talla + color en una sucursal: PUT /inventario.

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
 */
export function validarFilas(filas, sucursalFija = null) {
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
    else if (!/^\d+$/.test(f.cantidad)) e = 'La cantidad debe ser un número entero de 0 en adelante.';
    else if (vistas.has(clave(f))) e = `Repetida: es la misma prenda, sucursal, talla y color que la fila ${vistas.get(clave(f))}.`;
    if (e) errores[f.id] = e;
    else vistas.set(clave(f), filas.indexOf(f) + 1);
  });
  return errores;
}

/**
 * Guarda las filas una por una para reportar el resultado de cada una sin detener la carga.
 * `alAvanzar(idFila, { tipo: 'ok' | 'error', mensaje })` se llama después de cada fila.
 */
export async function guardarFilas(repo, filas, alAvanzar) {
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
      await repo.fijarExistencia({
        idPrenda: prenda.id, idSucursal: Number(f.idSucursal), talla: f.talla, color: f.color, cantidad: Number(f.cantidad),
      });
      ok += 1;
      alAvanzar(f.id, { tipo: 'ok', mensaje: `Guardado: ${prenda.descripcion}` });
    } catch (e) {
      alAvanzar(f.id, { tipo: 'error', mensaje: e.message });
    }
  }
  return { ok, errores: filas.length - ok };
}
