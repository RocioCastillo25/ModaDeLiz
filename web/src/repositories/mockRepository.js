// Repositorio simulado: misma interfaz que apiRepository, con datos en memoria.
// Permite usar y presentar la web sin Docker. Replica las reglas básicas de la API
// (código de barras único, cantidades no negativas, gerente limitado a su sucursal).
import { ApiError } from '../api/httpClient.js';

const sucursales = [
  { id: 1, nombre: 'Huauchinango', ubicacion: 'Matriz - Huauchinango, Puebla' },
  { id: 2, nombre: 'Zacatlan', ubicacion: 'Zacatlan, Puebla' },
  { id: 3, nombre: 'Chignahuapan', ubicacion: 'Chignahuapan, Puebla' },
  { id: 4, nombre: 'Ahuazotepec', ubicacion: 'Ahuazotepec, Puebla' },
  { id: 5, nombre: 'Xicotepec', ubicacion: 'Xicotepec, Puebla' },
];

const prendas = [
  { id: 1, codigo_barras: '7501000000011', descripcion: 'Blusa manga corta lisa', marca: 'Lizz', categoria: 'Blusas', temporada: 'Primavera-Verano', foto_url: null, umbral_alerta: 2, activa: true },
  { id: 2, codigo_barras: '7501000000028', descripcion: 'Jeans tiro alto', marca: 'Lizz', categoria: 'Pantalones', temporada: 'Todo el anio', foto_url: null, umbral_alerta: 2, activa: true },
  { id: 3, codigo_barras: '7501000000035', descripcion: 'Vestido floral midi', marca: 'Lizz', categoria: 'Vestidos', temporada: 'Primavera-Verano', foto_url: null, umbral_alerta: 2, activa: true },
  { id: 4, codigo_barras: '7501000000042', descripcion: 'Sueter tejido cuello alto', marca: 'Lizz', categoria: 'Sueteres', temporada: 'Otono-Invierno', foto_url: null, umbral_alerta: 3, activa: true },
];

let inventario = [
  [1, 1, 'M', 'Blanco', 6], [1, 2, 'M', 'Blanco', 3], [1, 3, 'M', 'Blanco', 0], [1, 1, 'G', 'Blanco', 2],
  [2, 1, '28', 'Azul', 4], [2, 4, '28', 'Azul', 5], [2, 5, '30', 'Negro', 1],
  [3, 2, 'CH', 'Rosa', 2], [3, 5, 'M', 'Rosa', 7],
  [4, 3, 'M', 'Gris', 5], [4, 1, 'G', 'Gris', 1],
].map(([id_prenda, id_sucursal, talla, color, cantidad], i) => ({ id: i + 1, id_prenda, id_sucursal, talla, color, cantidad }));

const delay = (v) => new Promise((r) => setTimeout(() => r(structuredClone(v)), 250));
const incluye = (txt, q) => (txt || '').toLowerCase().includes(q.trim().toLowerCase());
const nombreSucursal = (id) => sucursales.find((s) => s.id === id)?.nombre;

export function createMockRepository(usuario) {
  const verificarSucursal = (idSucursal) => {
    if (usuario.rol !== 'administrador' && usuario.sucursalId !== idSucursal) {
      throw new ApiError(403, 'PROHIBIDO', 'Solo puedes operar sobre tu propia sucursal');
    }
  };
  const existencias = (idPrenda) =>
    inventario
      .filter((i) => i.id_prenda === idPrenda)
      .map((i) => ({ id: i.id, id_sucursal: i.id_sucursal, sucursal: nombreSucursal(i.id_sucursal), talla: i.talla, color: i.color, cantidad: i.cantidad }));
  const buscarPrenda = (id) => {
    const p = prendas.find((x) => x.id === Number(id));
    if (!p) throw new ApiError(404, 'NO_ENCONTRADO', 'No se encontró lo que buscabas.');
    return p;
  };

  return {
    getMe: () => delay(usuario),
    listSucursales: () => delay(sucursales),

    async buscarPrendas({ q, codigo, categoria, talla, color, sucursalId } = {}) {
      const res = prendas
        .filter((p) => p.activa)
        .filter((p) => !codigo || p.codigo_barras === codigo)
        .filter((p) => !q || incluye(p.descripcion, q) || incluye(p.marca, q))
        .filter((p) => !categoria || incluye(p.categoria, categoria))
        .filter((p) => {
          if (!talla && !color && !sucursalId) return true;
          return inventario.some((i) => i.id_prenda === p.id
            && (!talla || i.talla === talla)
            && (!color || incluye(i.color, color))
            && (!sucursalId || i.id_sucursal === Number(sucursalId)));
        })
        .map((p) => ({ ...p, existencia_total: existencias(p.id).reduce((s, e) => s + e.cantidad, 0) }))
        .sort((a, b) => a.descripcion.localeCompare(b.descripcion));
      return delay(res);
    },

    getPrenda: async (id) => delay({ ...buscarPrenda(id), existencias: existencias(Number(id)) }),

    async getPrendaPorCodigo(codigo) {
      const p = prendas.find((x) => x.codigo_barras === codigo);
      if (!p) throw new ApiError(404, 'NO_ENCONTRADO', 'No se encontró lo que buscabas.');
      return delay({ ...p, existencias: existencias(p.id) });
    },

    async crearPrenda(datos) {
      if (prendas.some((p) => p.codigo_barras === datos.codigo_barras)) {
        throw new ApiError(409, 'CODIGO_DUPLICADO', 'Ya existe una prenda con ese codigo de barras');
      }
      const nueva = { id: Math.max(0, ...prendas.map((p) => p.id)) + 1, marca: null, categoria: null, temporada: null, foto_url: null, umbral_alerta: 2, activa: true, ...datos };
      prendas.push(nueva);
      return delay(nueva);
    },

    async actualizarPrenda(id, datos) {
      const p = buscarPrenda(id);
      Object.entries(datos).forEach(([k, v]) => { if (v !== undefined) p[k] = v; });
      return delay(p);
    },

    async desactivarPrenda(id) {
      const p = buscarPrenda(id);
      p.activa = false;
      return delay(p);
    },

    async listInventario({ sucursalId, prendaId, bajoUmbral } = {}) {
      let suc = sucursalId ? Number(sucursalId) : undefined;
      if (usuario.rol === 'gerente') {
        if (suc && suc !== usuario.sucursalId) throw new ApiError(403, 'PROHIBIDO', 'No tienes permiso para esta acción.');
        suc = usuario.sucursalId;
      }
      const res = inventario
        .map((i) => {
          const p = prendas.find((x) => x.id === i.id_prenda);
          return { ...i, codigo_barras: p.codigo_barras, descripcion: p.descripcion, sucursal: nombreSucursal(i.id_sucursal), umbral_alerta: p.umbral_alerta };
        })
        .filter((i) => !suc || i.id_sucursal === suc)
        .filter((i) => !prendaId || i.id_prenda === Number(prendaId))
        .filter((i) => !bajoUmbral || i.cantidad <= i.umbral_alerta)
        .sort((a, b) => a.descripcion.localeCompare(b.descripcion) || a.id_sucursal - b.id_sucursal);
      return delay(res);
    },

    async fijarExistencia({ idPrenda, idSucursal, talla, color, cantidad }) {
      verificarSucursal(idSucursal);
      buscarPrenda(idPrenda);
      if (!Number.isInteger(cantidad) || cantidad < 0) {
        throw new ApiError(400, 'DATOS_INVALIDOS', 'La cantidad debe ser un entero mayor o igual a 0');
      }
      let fila = inventario.find((i) => i.id_prenda === idPrenda && i.id_sucursal === idSucursal && i.talla === talla && i.color === color);
      if (fila) fila.cantidad = cantidad;
      else {
        fila = { id: Math.max(0, ...inventario.map((i) => i.id)) + 1, id_prenda: idPrenda, id_sucursal: idSucursal, talla, color, cantidad };
        inventario = [...inventario, fila];
      }
      return delay(fila);
    },
  };
}
