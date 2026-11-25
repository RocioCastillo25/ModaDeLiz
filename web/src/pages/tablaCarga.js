// Convierte texto tabular (CSV o pegado desde Excel) en filas de carga de inventario. Sin interfaz.
import { filaVacia, normalizar } from './cargaInventario.js';

export const COLUMNAS = ['codigo', 'sucursal', 'talla', 'color', 'cantidad'];

const sinAcentos = (s) => String(s ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').trim().toLowerCase();

/** Detecta el separador por la primera línea: tabulador (Excel), punto y coma (Excel en algunos idiomas) o coma. */
function detectarSeparador(texto) {
  const linea = texto.split('\n', 1)[0];
  const cuenta = (c) => linea.split(c).length - 1;
  if (cuenta('\t') > 0) return '\t';
  return cuenta(';') > cuenta(',') ? ';' : ',';
}

/** Lector CSV (RFC 4180): respeta comillas, comillas dobles escapadas y saltos de línea dentro de comillas. */
export function leerCsv(texto) {
  const limpio = texto.replace(/^﻿/, '').replace(/\r\n?/g, '\n');
  const sep = detectarSeparador(limpio);
  const filas = [];
  let fila = [];
  let celda = '';
  let entreComillas = false;
  for (let i = 0; i < limpio.length; i++) {
    const c = limpio[i];
    if (entreComillas) {
      if (c === '"' && limpio[i + 1] === '"') { celda += '"'; i++; }
      else if (c === '"') entreComillas = false;
      else celda += c;
    } else if (c === '"' && celda === '') entreComillas = true;
    else if (c === sep) { fila.push(celda); celda = ''; }
    else if (c === '\n') { fila.push(celda); filas.push(fila); fila = []; celda = ''; }
    else celda += c;
  }
  if (celda !== '' || fila.length) { fila.push(celda); filas.push(fila); }
  return filas.filter((f) => f.some((c) => c.trim() !== ''));
}

const ALIAS = {
  codigo: ['codigo', 'codigo de barras', 'codigo_barras', 'cod', 'sku'],
  sucursal: ['sucursal', 'tienda', 'id_sucursal'],
  talla: ['talla', 'size'],
  color: ['color'],
  cantidad: ['cantidad', 'piezas', 'existencia', 'cant'],
};

/** Si la primera fila es un encabezado, devuelve el índice de cada columna; si no, null. */
function leerEncabezado(primera) {
  const nombres = primera.map(sinAcentos);
  const indices = {};
  for (const [col, alias] of Object.entries(ALIAS)) {
    const i = nombres.findIndex((n) => alias.includes(n));
    if (i >= 0) indices[col] = i;
  }
  return indices.codigo !== undefined && indices.cantidad !== undefined ? indices : null;
}

/**
 * Convierte filas de celdas en filas de carga. Acepta archivos con o sin encabezado.
 * Sin encabezado: 5 columnas (código, sucursal, talla, color, cantidad) o 4 (sin sucursal).
 * La sucursal puede venir por nombre (con o sin acentos) o por número. Si no viene, se usa `sucursalPorDefecto`.
 */
export function aFilasDeCarga(celdas, sucursales, sucursalPorDefecto = '') {
  if (celdas.length === 0) return [];
  const encabezado = leerEncabezado(celdas[0]);
  const datos = encabezado ? celdas.slice(1) : celdas;
  const nombres = new Map(sucursales.map((s) => [sinAcentos(s.nombre), s.id]));

  const idDeSucursal = (valor) => {
    const v = String(valor ?? '').trim();
    if (!v) return sucursalPorDefecto;
    if (/^\d+$/.test(v)) return sucursales.some((s) => s.id === Number(v)) ? Number(v) : '';
    return nombres.get(sinAcentos(v)) ?? '';
  };

  return datos.map((c) => {
    let v;
    if (encabezado) v = Object.fromEntries(COLUMNAS.map((col) => [col, encabezado[col] !== undefined ? c[encabezado[col]] : '']));
    else if (c.length >= 5) v = { codigo: c[0], sucursal: c[1], talla: c[2], color: c[3], cantidad: c[4] };
    else v = { codigo: c[0], sucursal: '', talla: c[1], color: c[2], cantidad: c[3] };
    return normalizar({
      ...filaVacia(),
      codigo: v.codigo ?? '',
      idSucursal: String(idDeSucursal(v.sucursal)),
      talla: v.talla ?? '',
      color: v.color ?? '',
      cantidad: v.cantidad ?? '',
    });
  });
}

/** Plantilla CSV con encabezado y ejemplos. El BOM hace que Excel muestre bien los acentos. */
export function plantillaCsv(sucursales) {
  const s = (i) => sucursales[i]?.nombre ?? '';
  const lineas = [
    COLUMNAS.join(','),
    `7501000000011,${s(0)},M,Blanco,6`,
    `7501000000011,${s(1)},G,Blanco,3`,
    `7501000000028,${s(0)},28,Azul,4`,
  ];
  return '﻿' + lineas.join('\r\n') + '\r\n';
}
