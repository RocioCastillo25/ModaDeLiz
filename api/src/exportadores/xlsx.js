// EXPORTADOR EXCEL: convierte el `documento` de domain/reportes.js en un .xlsx (Buffer).
// Una hoja por seccion; los numeros se guardan como numeros para poder sumarlos y ordenarlos.
const ExcelJS = require('exceljs');

const COLOR_ENCABEZADO = 'FFF8D7E3';
const COLOR_MARCA = 'FFC2185B';

/** Nombre de hoja valido en Excel: maximo 31 caracteres, sin \ / ? * [ ] : y sin repetirse. */
function nombreHoja(titulo, usados) {
  const base = String(titulo).replace(/[\\/?*[\]:]/g, ' ').trim().slice(0, 31) || 'Hoja';
  let nombre = base;
  for (let n = 2; usados.has(nombre.toLowerCase()); n += 1) {
    const sufijo = ` (${n})`;
    nombre = base.slice(0, 31 - sufijo.length) + sufijo;
  }
  usados.add(nombre.toLowerCase());
  return nombre;
}

const fechaLegible = (iso) =>
  new Date(iso).toLocaleString('es-MX', { timeZone: 'America/Mexico_City', dateStyle: 'medium', timeStyle: 'short' });

/** documento -> Promise<Buffer> con el libro de Excel. */
async function aXlsx(documento) {
  const libro = new ExcelJS.Workbook();
  libro.creator = 'CheckLizz · Moda de Lizz';
  libro.title = documento.titulo;
  libro.created = new Date(documento.generadoEn);

  const usados = new Set();
  for (const seccion of documento.secciones) {
    const hoja = libro.addWorksheet(nombreHoja(seccion.titulo, usados));
    const total = seccion.columnas.length;
    const combina = (fila) => { if (total > 1) hoja.mergeCells(fila, 1, fila, total); };

    hoja.getCell('A1').value = documento.titulo;
    hoja.getCell('A1').font = { bold: true, size: 14, color: { argb: COLOR_MARCA } };
    combina(1);
    hoja.getCell('A2').value = documento.subtitulo;
    combina(2);
    hoja.getCell('A3').value = `Generado el ${fechaLegible(documento.generadoEn)}`;
    hoja.getCell('A3').font = { italic: true, color: { argb: 'FF777777' } };
    combina(3);

    let fila = 4;
    if (seccion.resumen) {
      hoja.getCell(`A${fila}`).value = `${seccion.titulo}: ${seccion.resumen}`;
      hoja.getCell(`A${fila}`).font = { bold: true };
      combina(fila);
      fila += 1;
    }
    fila += 1;                                   // renglon en blanco antes de la tabla

    const encabezado = hoja.getRow(fila);
    seccion.columnas.forEach((c, i) => {
      const celda = encabezado.getCell(i + 1);
      celda.value = c.titulo;
      celda.font = { bold: true };
      celda.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLOR_ENCABEZADO } };
      celda.alignment = { horizontal: c.tipo === 'numero' ? 'right' : 'left' };
      hoja.getColumn(i + 1).width = Math.max(12, Math.round(c.ancho * 9));
    });
    hoja.views = [{ state: 'frozen', ySplit: fila }];

    seccion.filas.forEach((datos) => {
      fila += 1;
      const renglon = hoja.getRow(fila);
      seccion.columnas.forEach((c, i) => {
        const celda = renglon.getCell(i + 1);
        celda.value = datos[c.clave] ?? null;
        if (c.tipo === 'numero') { celda.numFmt = '#,##0'; celda.alignment = { horizontal: 'right' }; }
      });
    });

    if (seccion.filas.length) {
      hoja.autoFilter = { from: { row: fila - seccion.filas.length, column: 1 }, to: { row: fila, column: total } };
    }
  }

  return Buffer.from(await libro.xlsx.writeBuffer());
}

module.exports = { aXlsx, nombreHoja };
