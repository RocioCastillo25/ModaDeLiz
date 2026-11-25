// Pruebas de las reglas puras de reportes y de los exportadores PDF/Excel. No necesitan base de datos.
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const ExcelJS = require('exceljs');
const dominio = require('../src/domain/reportes');
const { aPdf } = require('../src/exportadores/pdf');
const { aXlsx, nombreHoja } = require('../src/exportadores/xlsx');

const AHORA = '2026-11-23T15:00:00.000Z';
const sucursales = [{ id: 1, nombre: 'Huauchinango' }, { id: 2, nombre: 'Zacatlan' }, { id: 3, nombre: 'Chignahuapan' }];
const fila = (id_sucursal, id_prenda, descripcion, talla, color, cantidad) =>
  ({ id_sucursal, id_prenda, descripcion, talla, color, cantidad });

describe('fechas y nombres', () => {
  test('esFechaIso acepta solo dias reales con formato AAAA-MM-DD', () => {
    assert.equal(dominio.esFechaIso('2026-11-23'), true);
    assert.equal(dominio.esFechaIso('2028-02-29'), true, 'bisiesto');
    assert.equal(dominio.esFechaIso('2026-02-30'), false);
    assert.equal(dominio.esFechaIso('2026-13-01'), false);
    assert.equal(dominio.esFechaIso('23/11/2026'), false);
    assert.equal(dominio.esFechaIso('2026-1-5'), false);
    assert.equal(dominio.esFechaIso('hoy'), false);
  });
  test('rangoValido: desde no puede ser posterior a hasta; cada extremo es opcional', () => {
    assert.equal(dominio.rangoValido('2026-01-01', '2026-01-31'), true);
    assert.equal(dominio.rangoValido('2026-01-31', '2026-01-31'), true);
    assert.equal(dominio.rangoValido('2026-02-01', '2026-01-31'), false);
    assert.equal(dominio.rangoValido(undefined, '2026-01-31'), true);
    assert.equal(dominio.rangoValido('2026-01-31', undefined), true);
    assert.equal(dominio.rangoValido(undefined, undefined), true);
  });
  test('nombreArchivo usa la fecha de generacion', () => {
    assert.equal(dominio.nombreArchivo('existencias', 'pdf', AHORA), 'existencias-2026-11-23.pdf');
    assert.equal(dominio.nombreArchivo('mas-vendidos', 'xlsx', AHORA), 'mas-vendidos-2026-11-23.xlsx');
  });
  test('hay un tipo de contenido por cada formato', () => {
    for (const f of dominio.FORMATOS) assert.ok(dominio.TIPOS_CONTENIDO[f]);
    assert.match(dominio.TIPOS_CONTENIDO.xlsx, /spreadsheetml/);
  });
});

describe('agruparExistencias', () => {
  const filas = [
    fila(1, 10, 'Vestido', 'CH', 'Rosa', 3),
    fila(1, 10, 'Vestido', 'M', 'Rosa', 2),
    fila(1, 11, 'Blusa', 'M', 'Azul', 4),
    fila(2, 10, 'Vestido', 'CH', 'Rosa', 7),
  ];

  test('cuenta productos distintos (no renglones) y piezas por sucursal', () => {
    const [hua, zac] = dominio.agruparExistencias(sucursales, filas);
    assert.equal(hua.sucursal, 'Huauchinango');
    assert.equal(hua.productos_distintos, 2, 'el vestido en dos tallas cuenta una vez');
    assert.equal(hua.piezas, 9);
    assert.equal(hua.detalle.length, 3);
    assert.equal(zac.productos_distintos, 1);
    assert.equal(zac.piezas, 7);
  });

  test('una sucursal sin piezas aparece en cero', () => {
    const chig = dominio.agruparExistencias(sucursales, filas)[2];
    assert.deepEqual([chig.id_sucursal, chig.productos_distintos, chig.piezas, chig.detalle], [3, 0, 0, []]);
  });

  test('el detalle solo lleva los campos del contrato', () => {
    const [hua] = dominio.agruparExistencias(sucursales, filas);
    assert.deepEqual(Object.keys(hua.detalle[0]), ['id_prenda', 'descripcion', 'talla', 'color', 'cantidad']);
  });
});

describe('reporteExistencias', () => {
  const filas = [fila(1, 10, 'Vestido', 'CH', 'Rosa', 3)];

  test('datos siguen el contrato y el documento trae resumen + una seccion por sucursal', () => {
    const { datos, documento } = dominio.reporteExistencias({ sucursales, filas, generadoEn: AHORA });
    assert.equal(datos.generado_en, AHORA);
    assert.equal(datos.sucursales.length, 3);
    assert.equal(documento.secciones.length, 1 + 3);
    assert.equal(documento.secciones[0].titulo, 'Resumen por sucursal');
    assert.deepEqual(documento.secciones[0].filas[0], { sucursal: 'Huauchinango', productos_distintos: 1, piezas: 3 });
    assert.deepEqual(documento.secciones.slice(1).map((s) => s.titulo), ['Huauchinango', 'Zacatlan', 'Chignahuapan']);
  });

  test('con una sola sucursal el subtitulo la nombra', () => {
    const { documento } = dominio.reporteExistencias({ sucursales: [sucursales[1]], filas: [], generadoEn: AHORA });
    assert.match(documento.subtitulo, /Zacatlan/);
  });
});

describe('reporteMasVendidos', () => {
  const items = [
    { id_prenda: 2, descripcion: 'Blusa', id_sucursal: null, sucursal: null, piezas_vendidas: 9 },
    { id_prenda: 1, descripcion: 'Vestido', id_sucursal: null, sucursal: null, piezas_vendidas: 6 },
  ];

  test('datos: periodo y items tal cual; sin periodo van en null', () => {
    const { datos } = dominio.reporteMasVendidos({ items, generadoEn: AHORA });
    assert.deepEqual(datos, { desde: null, hasta: null, items });
  });

  test('el ranking se numera y, sin sucursal, muestra la columna Sucursal como "Todas"', () => {
    const { documento } = dominio.reporteMasVendidos({ items, generadoEn: AHORA });
    const [seccion] = documento.secciones;
    assert.deepEqual(seccion.columnas.map((c) => c.clave), ['posicion', 'descripcion', 'sucursal', 'piezas_vendidas']);
    assert.deepEqual(seccion.filas.map((f) => [f.posicion, f.sucursal]), [[1, 'Todas'], [2, 'Todas']]);
    assert.match(documento.subtitulo, /Todas las sucursales · Todo el historial/);
  });

  test('con sucursal se omite la columna y el subtitulo la nombra con el periodo', () => {
    const { documento } = dominio.reporteMasVendidos({
      items, desde: '2026-11-01', hasta: '2026-11-30', sucursal: 'Zacatlan', generadoEn: AHORA,
    });
    assert.ok(!documento.secciones[0].columnas.some((c) => c.clave === 'sucursal'));
    assert.equal(documento.subtitulo, 'Zacatlan · Del 2026-11-01 al 2026-11-30');
  });

  test('periodos abiertos se describen', () => {
    assert.match(dominio.reporteMasVendidos({ items, desde: '2026-11-01', generadoEn: AHORA }).documento.subtitulo, /Desde el 2026-11-01/);
    assert.match(dominio.reporteMasVendidos({ items, hasta: '2026-11-30', generadoEn: AHORA }).documento.subtitulo, /Hasta el 2026-11-30/);
  });
});

describe('reporteStockBajo', () => {
  test('datos con generado_en e items; el subtitulo cuenta los registros', () => {
    const items = [{ id: 1, id_prenda: 1, descripcion: 'Vestido', id_sucursal: 1, sucursal: 'Huauchinango', talla: 'M', color: 'Rosa', cantidad: 1, umbral_alerta: 5 }];
    const { datos, documento } = dominio.reporteStockBajo({ items, generadoEn: AHORA });
    assert.deepEqual(datos, { generado_en: AHORA, items });
    assert.match(documento.subtitulo, /^1 registro/);
    assert.deepEqual(documento.secciones[0].columnas.map((c) => c.clave),
      ['descripcion', 'sucursal', 'talla', 'color', 'cantidad', 'umbral_alerta']);
  });
});

describe('exportadores', () => {
  const muchas = [];
  for (let i = 1; i <= 200; i += 1) muchas.push(fila(1, i, `Prenda número ${i} con acentos: ñandú, camisón`, 'CH', 'Rosa', i));
  const { documento } = dominio.reporteExistencias({ sucursales: sucursales.slice(0, 2), filas: muchas, generadoEn: AHORA });

  test('PDF: es un PDF valido y se reparte en varias paginas con muchas filas', async () => {
    const pdf = await aPdf(documento);
    assert.ok(Buffer.isBuffer(pdf));
    assert.equal(pdf.subarray(0, 5).toString('latin1'), '%PDF-');
    assert.match(pdf.subarray(-16).toString('latin1'), /%%EOF/);
    const paginas = (pdf.toString('latin1').match(/\/Type \/Page(?!s)/g) || []).length;
    assert.ok(paginas >= 4, `se esperaban varias paginas y hay ${paginas}`);
  });

  test('PDF: un reporte vacio tambien se genera', async () => {
    const vacio = dominio.reporteStockBajo({ items: [], generadoEn: AHORA }).documento;
    assert.equal((await aPdf(vacio)).subarray(0, 5).toString('latin1'), '%PDF-');
  });

  test('Excel: una hoja por seccion, numeros como numeros y encabezado antes de los datos', async () => {
    const libro = new ExcelJS.Workbook();
    await libro.xlsx.load(await aXlsx(documento));
    assert.deepEqual(libro.worksheets.map((h) => h.name), ['Resumen por sucursal', 'Huauchinango', 'Zacatlan']);

    const hoja = libro.getWorksheet('Huauchinango');
    assert.equal(hoja.getCell('A1').value, 'Reporte de existencias');
    // titulo, subtitulo, generado, resumen, renglon en blanco -> encabezado en la fila 6
    assert.deepEqual([1, 2, 3, 4].map((c) => hoja.getRow(6).getCell(c).value), ['Prenda', 'Talla', 'Color', 'Piezas']);
    const primera = hoja.getRow(7);
    assert.equal(primera.getCell(1).value, 'Prenda número 1 con acentos: ñandú, camisón');
    assert.equal(typeof primera.getCell(4).value, 'number');
    assert.equal(primera.getCell(4).value, 1);
    assert.equal(hoja.rowCount, 6 + 200);

    const resumen = libro.getWorksheet('Resumen por sucursal');
    // sin renglon de resumen el encabezado queda una fila antes: fila 5
    assert.equal(resumen.getRow(5).getCell(1).value, 'Sucursal');
    assert.equal(resumen.getRow(6).getCell(3).value, (200 * 201) / 2);
  });

  test('Excel: un reporte sin filas deja solo el encabezado', async () => {
    const vacio = dominio.reporteStockBajo({ items: [], generadoEn: AHORA }).documento;
    const libro = new ExcelJS.Workbook();
    await libro.xlsx.load(await aXlsx(vacio));
    assert.equal(libro.worksheets.length, 1);
  });

  test('nombreHoja: quita caracteres invalidos, corta a 31 y evita repetidos', () => {
    const usados = new Set();
    assert.equal(nombreHoja('Zacatlan', usados), 'Zacatlan');
    assert.equal(nombreHoja('zacatlan', usados), 'zacatlan (2)', 'Excel no distingue mayusculas');
    assert.equal(nombreHoja('A/B:C*D?E[F]G\\H', new Set()), 'A B C D E F G H');
    assert.equal(nombreHoja('x'.repeat(40), new Set()).length, 31);
    const largos = new Set();
    nombreHoja('y'.repeat(40), largos);
    assert.ok(nombreHoja('y'.repeat(40), largos).length <= 31);
  });
});
