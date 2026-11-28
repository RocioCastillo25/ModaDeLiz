// DOMINIO DE REPORTES: arma, sin tocar la base de datos, los tres reportes del contrato.
// Cada constructor devuelve:
//   datos     -> el JSON que describe docs/openapi.yaml
//   documento -> una forma neutra (titulo + secciones con tabla) que los exportadores
//                convierten a PDF y a Excel, asi los tres formatos muestran lo mismo.

const FORMATOS = ['json', 'pdf', 'xlsx'];

const TIPOS_CONTENIDO = {
  json: 'application/json; charset=utf-8',
  pdf: 'application/pdf',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
};

/** `YYYY-MM-DD` que ademas es un dia real del calendario (rechaza 2026-02-30). */
function esFechaIso(texto) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(texto)) return false;
  const fecha = new Date(`${texto}T00:00:00Z`);
  return !Number.isNaN(fecha.getTime()) && fecha.toISOString().slice(0, 10) === texto;
}

/** Las fechas ISO se comparan bien como texto. */
function rangoValido(desde, hasta) {
  return !desde || !hasta || desde <= hasta;
}

/** Nombre de descarga: existencias-2026-11-23.pdf */
function nombreArchivo(base, formato, generadoEn) {
  return `${base}-${generadoEn.slice(0, 10)}.${formato}`;
}

const sum = (filas, campo) => filas.reduce((total, f) => total + f[campo], 0);

/**
 * Agrupa las existencias por sucursal. Recibe TODAS las sucursales a reportar (incluso las
 * que no tienen piezas, que salen en cero) y las filas de inventario con cantidad.
 */
function agruparExistencias(sucursales, filas) {
  return sucursales.map((s) => {
    const detalle = filas
      .filter((f) => f.id_sucursal === s.id)
      .map(({ id_prenda, descripcion, talla, color, cantidad }) => ({ id_prenda, descripcion, talla, color, cantidad }));
    return {
      id_sucursal: s.id,
      sucursal: s.nombre,
      productos_distintos: new Set(detalle.map((d) => d.id_prenda)).size,
      piezas: sum(detalle, 'cantidad'),
      detalle,
    };
  });
}

const COLUMNAS_DETALLE = [
  { clave: 'descripcion', titulo: 'Prenda', ancho: 4 },
  { clave: 'talla', titulo: 'Talla', ancho: 1 },
  { clave: 'color', titulo: 'Color', ancho: 1.6 },
  { clave: 'cantidad', titulo: 'Piezas', ancho: 1, tipo: 'numero' },
];

function reporteExistencias({ sucursales, filas, generadoEn }) {
  const agrupadas = agruparExistencias(sucursales, filas);
  const datos = { generado_en: generadoEn, sucursales: agrupadas };

  const documento = {
    titulo: 'Reporte de existencias',
    subtitulo: `${agrupadas.length === 1 ? agrupadas[0].sucursal : 'Todas las sucursales'} · piezas con existencia`,
    generadoEn,
    secciones: [
      {
        titulo: 'Resumen por sucursal',
        columnas: [
          { clave: 'sucursal', titulo: 'Sucursal', ancho: 3 },
          { clave: 'productos_distintos', titulo: 'Productos distintos', ancho: 2, tipo: 'numero' },
          { clave: 'piezas', titulo: 'Piezas', ancho: 1.4, tipo: 'numero' },
        ],
        filas: agrupadas.map(({ sucursal, productos_distintos, piezas }) => ({ sucursal, productos_distintos, piezas })),
      },
      ...agrupadas.map((s) => ({
        titulo: s.sucursal,
        resumen: `${s.productos_distintos} producto(s) distinto(s) · ${s.piezas} pieza(s)`,
        columnas: COLUMNAS_DETALLE,
        filas: s.detalle,
      })),
    ],
  };
  return { datos, documento };
}

function reporteMasVendidos({ items, desde, hasta, sucursal, generadoEn }) {
  const datos = { desde: desde || null, hasta: hasta || null, items };

  let periodo = 'Todo el historial';
  if (desde && hasta) periodo = `Del ${desde} al ${hasta}`;
  else if (desde) periodo = `Desde el ${desde}`;
  else if (hasta) periodo = `Hasta el ${hasta}`;

  const columnas = [
    { clave: 'posicion', titulo: '#', ancho: 0.6, tipo: 'numero' },
    { clave: 'descripcion', titulo: 'Prenda', ancho: 4 },
    ...(sucursal ? [] : [{ clave: 'sucursal', titulo: 'Sucursal', ancho: 2 }]),
    { clave: 'piezas_vendidas', titulo: 'Piezas vendidas', ancho: 1.6, tipo: 'numero' },
  ];
  const documento = {
    titulo: 'Prendas más vendidas',
    subtitulo: `${sucursal || 'Todas las sucursales'} · ${periodo}`,
    generadoEn,
    secciones: [{
      titulo: 'Ranking',
      columnas,
      filas: items.map((it, i) => ({ posicion: i + 1, ...it, sucursal: it.sucursal || 'Todas' })),
    }],
  };
  return { datos, documento };
}

function reporteStockBajo({ items, generadoEn }) {
  const datos = { generado_en: generadoEn, items };
  const documento = {
    titulo: 'Prendas con stock bajo',
    subtitulo: `${items.length} registro(s) en o por debajo del umbral de alerta`,
    generadoEn,
    secciones: [{
      titulo: 'Stock bajo',
      columnas: [
        { clave: 'descripcion', titulo: 'Prenda', ancho: 4 },
        { clave: 'sucursal', titulo: 'Sucursal', ancho: 2 },
        { clave: 'talla', titulo: 'Talla', ancho: 1 },
        { clave: 'color', titulo: 'Color', ancho: 1.5 },
        { clave: 'cantidad', titulo: 'Piezas', ancho: 1, tipo: 'numero' },
        { clave: 'umbral_alerta', titulo: 'Umbral', ancho: 1, tipo: 'numero' },
      ],
      filas: items,
    }],
  };
  return { datos, documento };
}

module.exports = {
  FORMATOS, TIPOS_CONTENIDO,
  esFechaIso, rangoValido, nombreArchivo,
  agruparExistencias, reporteExistencias, reporteMasVendidos, reporteStockBajo,
};
