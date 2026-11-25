// EXPORTADOR PDF: convierte el `documento` de domain/reportes.js en un PDF (Buffer).
const PDFDocument = require('pdfkit');

const COLOR_MARCA = '#C2185B';
const COLOR_ENCABEZADO = '#F8D7E3';
const COLOR_ZEBRA = '#FBF1F5';
const COLOR_TEXTO = '#222222';
const COLOR_APAGADO = '#777777';

const MARGEN = 40;
const RELLENO = 4;
const ALTO_ENCABEZADO = 20;

const fechaLegible = (iso) =>
  new Date(iso).toLocaleString('es-MX', { timeZone: 'America/Mexico_City', dateStyle: 'medium', timeStyle: 'short' });

const texto = (valor, columna) => {
  if (valor === null || valor === undefined) return '';
  return columna.tipo === 'numero' && typeof valor === 'number' ? valor.toLocaleString('es-MX') : String(valor);
};

function dibujaEncabezado(doc, columnas, anchos, x, y) {
  doc.rect(x, y, anchos.reduce((a, b) => a + b, 0), ALTO_ENCABEZADO).fill(COLOR_ENCABEZADO);
  doc.fillColor(COLOR_TEXTO).font('Helvetica-Bold').fontSize(9);
  let cx = x;
  columnas.forEach((c, i) => {
    doc.text(c.titulo, cx + RELLENO, y + 6, {
      width: anchos[i] - 2 * RELLENO, align: c.tipo === 'numero' ? 'right' : 'left', lineBreak: false,
    });
    cx += anchos[i];
  });
  doc.y = y + ALTO_ENCABEZADO;
}

function dibujaTabla(doc, seccion, anchoUtil) {
  const { columnas, filas } = seccion;
  const peso = columnas.reduce((suma, c) => suma + c.ancho, 0);
  const anchos = columnas.map((c) => (c.ancho / peso) * anchoUtil);
  const limite = () => doc.page.height - doc.page.margins.bottom;

  if (!filas.length) {
    doc.font('Helvetica-Oblique').fontSize(9).fillColor(COLOR_APAGADO).text('Sin registros.', MARGEN, doc.y);
    doc.moveDown(1);
    return;
  }

  dibujaEncabezado(doc, columnas, anchos, MARGEN, doc.y);
  filas.forEach((fila, n) => {
    doc.font('Helvetica').fontSize(9);
    const celdas = columnas.map((c) => texto(fila[c.clave], c));
    const alto = Math.max(...celdas.map((t, i) => doc.heightOfString(t, { width: anchos[i] - 2 * RELLENO }))) + 2 * RELLENO;

    if (doc.y + alto > limite()) {
      doc.addPage();
      dibujaEncabezado(doc, columnas, anchos, MARGEN, doc.y);
    }
    const y = doc.y;
    if (n % 2 === 1) doc.rect(MARGEN, y, anchoUtil, alto).fill(COLOR_ZEBRA);
    doc.fillColor(COLOR_TEXTO).font('Helvetica').fontSize(9);
    let x = MARGEN;
    columnas.forEach((c, i) => {
      doc.text(celdas[i], x + RELLENO, y + RELLENO, {
        width: anchos[i] - 2 * RELLENO, align: c.tipo === 'numero' ? 'right' : 'left',
      });
      x += anchos[i];
    });
    doc.y = y + alto;
  });
  doc.moveDown(1);
}

/** documento -> Promise<Buffer> con el PDF. */
function aPdf(documento) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({
      size: 'A4',
      margin: MARGEN,
      bufferPages: true,
      info: { Title: documento.titulo, Author: 'CheckLizz · Moda de Lizz', Subject: documento.subtitulo },
    });
    const partes = [];
    doc.on('data', (p) => partes.push(p));
    doc.on('end', () => resolve(Buffer.concat(partes)));
    doc.on('error', reject);

    const anchoUtil = doc.page.width - 2 * MARGEN;

    doc.font('Helvetica-Bold').fontSize(9).fillColor(COLOR_MARCA).text('MODA DE LIZZ · CHECKLIZZ', MARGEN, MARGEN);
    doc.moveDown(0.4).font('Helvetica-Bold').fontSize(18).fillColor(COLOR_TEXTO).text(documento.titulo);
    doc.font('Helvetica').fontSize(10).fillColor(COLOR_APAGADO).text(documento.subtitulo);
    doc.text(`Generado el ${fechaLegible(documento.generadoEn)}`);
    doc.moveDown(0.8);

    documento.secciones.forEach((seccion) => {
      // Que el titulo de la seccion no quede solo al final de una pagina
      if (doc.y + 70 > doc.page.height - doc.page.margins.bottom) doc.addPage();
      doc.font('Helvetica-Bold').fontSize(12).fillColor(COLOR_MARCA).text(seccion.titulo, MARGEN, doc.y);
      if (seccion.resumen) doc.font('Helvetica').fontSize(9).fillColor(COLOR_APAGADO).text(seccion.resumen);
      doc.moveDown(0.4);
      dibujaTabla(doc, seccion, anchoUtil);
    });

    // Numeracion de paginas (se pone al final, cuando ya se sabe el total)
    const { start, count } = doc.bufferedPageRange();
    for (let i = start; i < start + count; i += 1) {
      doc.switchToPage(i);
      const margenInferior = doc.page.margins.bottom;
      doc.page.margins.bottom = 0;   // sin esto, escribir en el borde inferior crearia otra pagina
      doc.font('Helvetica').fontSize(8).fillColor(COLOR_APAGADO)
        .text(`Página ${i + 1} de ${count}`, MARGEN, doc.page.height - 28, { width: anchoUtil, align: 'center' });
      doc.page.margins.bottom = margenInferior;
    }
    doc.end();
  });
}

module.exports = { aPdf };
