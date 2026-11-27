// Pruebas de aceptación de la página web (WEB-01 y WEB-02) sobre el repositorio simulado,
// que replica las reglas de la API: código de barras único, cantidades no negativas y
// gerente limitado a su sucursal. Se ejecutan con `npm test` (node --test), sin navegador.
import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import { createMockRepository } from '../src/repositories/mockRepository.js';
import { leerCsv, aFilasDeCarga, plantillaCsv } from '../src/pages/tablaCarga.js';
import { validarFilas, guardarFilas, normalizar, filaVacia, MODOS } from '../src/pages/cargaInventario.js';
import { validarPrenda, aCuerpo, PRENDA_VACIA } from '../src/pages/prendaValidacion.js';

const admin = { id: 1, nombre: 'Liz', rol: 'administrador', sucursalId: 1 };
const gerenteZacatlan = { id: 2, nombre: 'Gerente', rol: 'gerente', sucursalId: 2 };
const sucursales = [
  { id: 1, nombre: 'Huauchinango' }, { id: 2, nombre: 'Zacatlan' }, { id: 3, nombre: 'Chignahuapan' },
  { id: 4, nombre: 'Ahuazotepec' }, { id: 5, nombre: 'Xicotepec' },
];
const fila = (datos) => normalizar({ ...filaVacia(), ...datos });
const existencia = async (repo, prendaId, sucursalId, talla, color) =>
  (await repo.listInventario({ prendaId, sucursalId })).find((i) => i.talla === talla && i.color === color)?.cantidad;

describe('WEB-01 · Lista de prendas y existencias por sucursal', () => {
  test('el catálogo muestra solo prendas activas con su existencia total', async () => {
    const repo = createMockRepository(admin);
    const prendas = await repo.buscarPrendas();
    assert.ok(prendas.length >= 4);
    assert.ok(prendas.every((p) => p.activa));
    const blusa = prendas.find((p) => p.codigo_barras === '7501000000011');
    assert.equal(blusa.existencia_total, 6 + 3 + 0 + 2);
  });

  test('la búsqueda filtra por texto, talla y sucursal', async () => {
    const repo = createMockRepository(admin);
    assert.deepEqual((await repo.buscarPrendas({ q: 'jeans' })).map((p) => p.codigo_barras), ['7501000000028']);
    const enXicotepec = await repo.buscarPrendas({ sucursalId: 5 });
    assert.ok(enXicotepec.every((p) => ['Jeans tiro alto', 'Vestido floral midi'].includes(p.descripcion)));
  });

  test('la ficha de una prenda trae la existencia de cada sucursal', async () => {
    const repo = createMockRepository(admin);
    const ficha = await repo.getPrenda(1);
    assert.ok(ficha.existencias.length > 0);
    assert.ok(ficha.existencias.every((e) => e.sucursal && Number.isInteger(e.cantidad)));
  });

  test('la administradora ve las 5 sucursales; el gerente solo la suya', async () => {
    const todas = new Set((await createMockRepository(admin).listInventario()).map((i) => i.id_sucursal));
    assert.ok(todas.size > 1);
    const gerente = createMockRepository(gerenteZacatlan);
    const suyas = await gerente.listInventario();
    assert.ok(suyas.length > 0 && suyas.every((i) => i.id_sucursal === 2));
    await assert.rejects(gerente.listInventario({ sucursalId: 1 }), { status: 403 });
  });

  test('el filtro de stock bajo devuelve solo existencias en o por debajo del umbral', async () => {
    const bajos = await createMockRepository(admin).listInventario({ bajoUmbral: true });
    assert.ok(bajos.length > 0 && bajos.every((i) => i.cantidad <= i.umbral_alerta));
  });
});

describe('Alta y edición de prendas (formulario web)', () => {
  test('rechaza datos incompletos antes de llamar a la API', () => {
    const errores = validarPrenda({ ...PRENDA_VACIA, codigo_barras: '12', umbral_alerta: '-1' }, true);
    assert.ok(errores.codigo_barras && errores.descripcion && errores.umbral_alerta);
  });

  test('una prenda válida se da de alta y no se permite repetir el código de barras', async () => {
    const repo = createMockRepository(admin);
    const form = { ...PRENDA_VACIA, codigo_barras: '7509990000017', descripcion: 'Falda plisada', categoria: 'Faldas' };
    assert.deepEqual(validarPrenda(form, true), {});
    const nueva = await repo.crearPrenda(aCuerpo(form, true));
    assert.equal(nueva.descripcion, 'Falda plisada');
    await assert.rejects(repo.crearPrenda(aCuerpo(form, true)), { status: 409, code: 'CODIGO_DUPLICADO' });
  });

  test('editar cambia los datos sin tocar el código de barras', async () => {
    const repo = createMockRepository(admin);
    const editada = await repo.actualizarPrenda(3, aCuerpo({ ...PRENDA_VACIA, descripcion: 'Vestido floral largo', umbral_alerta: '4' }, false));
    assert.equal(editada.descripcion, 'Vestido floral largo');
    assert.equal(editada.umbral_alerta, 4);
    assert.equal(editada.codigo_barras, '7501000000035');
  });
});

describe('WEB-02 · Carga inicial de inventario por filas', () => {
  test('en modo sumar, la cantidad cargada se suma a la existencia actual', async () => {
    const repo = createMockRepository(admin);
    const antes = await existencia(repo, 1, 1, 'M', 'Blanco');
    const filas = [fila({ codigo: '7501000000011', idSucursal: '1', talla: 'm', color: 'blanco', cantidad: '4' })];
    assert.deepEqual(validarFilas(filas, null, MODOS.sumar), {});
    const r = await guardarFilas(repo, filas, () => {}, MODOS.sumar);
    assert.deepEqual(r, { ok: 1, errores: 0 });
    assert.equal(await existencia(repo, 1, 1, 'M', 'Blanco'), antes + 4);
  });

  test('en modo reemplazar, la cantidad queda fija (se admite 0)', async () => {
    const repo = createMockRepository(admin);
    const filas = [fila({ codigo: '7501000000028', idSucursal: '4', talla: '28', color: 'Azul', cantidad: '0' })];
    assert.deepEqual(validarFilas(filas, null, MODOS.reemplazar), {});
    await guardarFilas(repo, filas, () => {}, MODOS.reemplazar);
    assert.equal(await existencia(repo, 2, 4, '28', 'Azul'), 0);
  });

  test('valida cada fila y explica el problema', () => {
    const filas = [
      fila({ codigo: '', idSucursal: '1', talla: 'M', color: 'Rojo', cantidad: '1' }),
      fila({ codigo: '7501000000011', idSucursal: '1', talla: 'M', color: 'Rojo', cantidad: '-3' }),
      fila({ codigo: '7501000000011', idSucursal: '1', talla: 'M', color: 'Rojo', cantidad: '0' }),
    ];
    const errores = validarFilas(filas, null, MODOS.sumar);
    assert.match(errores[filas[0].id], /código de barras/);
    assert.match(errores[filas[1].id], /número entero/);
    assert.match(errores[filas[2].id], /al menos 1/);
  });

  test('el gerente solo puede cargar a su sucursal (en la página y en la API)', async () => {
    const filas = [fila({ codigo: '7501000000011', idSucursal: '1', talla: 'M', color: 'Blanco', cantidad: '1' })];
    assert.match(validarFilas(filas, 2)[filas[0].id], /tu sucursal/);
    await assert.rejects(
      createMockRepository(gerenteZacatlan).fijarExistencia({ idPrenda: 1, idSucursal: 1, talla: 'M', color: 'Blanco', cantidad: 1 }),
      { status: 403 },
    );
  });

  test('una fila con un código inexistente se reporta y no detiene las demás', async () => {
    const repo = createMockRepository(admin);
    const filas = [
      fila({ codigo: '0000000000000', idSucursal: '1', talla: 'M', color: 'Blanco', cantidad: '1' }),
      fila({ codigo: '7501000000042', idSucursal: '1', talla: 'G', color: 'Gris', cantidad: '2' }),
    ];
    const avisos = {};
    const r = await guardarFilas(repo, filas, (id, a) => { avisos[id] = a; });
    assert.deepEqual(r, { ok: 1, errores: 1 });
    assert.match(avisos[filas[0].id].mensaje, /No existe una prenda/);
    assert.equal(avisos[filas[1].id].tipo, 'ok');
  });
});

describe('WEB-02 · Carga inicial de inventario por CSV', () => {
  test('lee un CSV con encabezado, sucursal por nombre y acentos', () => {
    const csv = '﻿Código,Sucursal,Talla,Color,Cantidad\r\n7501000000011,Zacatlán,ch,ROSA,5\r\n';
    const [f] = aFilasDeCarga(leerCsv(csv), sucursales);
    assert.equal(f.codigo, '7501000000011');
    assert.equal(f.idSucursal, '2');
    assert.equal(f.talla, 'CH');
    assert.equal(f.color, 'Rosa');
    assert.equal(f.cantidad, '5');
  });

  test('acepta lo pegado desde Excel (tabuladores) y el punto y coma', () => {
    const tab = aFilasDeCarga(leerCsv('7501000000028\t5\t30\tNegro\t2'), sucursales);
    const pyc = aFilasDeCarga(leerCsv('7501000000028;Xicotepec;30;Negro;2'), sucursales);
    assert.equal(tab[0].idSucursal, '5');
    assert.equal(pyc[0].idSucursal, '5');
  });

  test('respeta comillas y usa la sucursal por defecto si el archivo no la trae', () => {
    const [f] = aFilasDeCarga(leerCsv('"7501000000035","M","Azul, marino","3"'), sucursales, 3);
    assert.equal(f.color, 'Azul, marino');
    assert.equal(f.idSucursal, '3');
  });

  test('una sucursal desconocida queda vacía y la validación la señala', () => {
    const filas = aFilasDeCarga(leerCsv('codigo,sucursal,talla,color,cantidad\n7501000000011,Puebla,M,Blanco,1'), sucursales);
    assert.match(validarFilas(filas)[filas[0].id], /sucursal/);
  });

  test('la plantilla descargable se puede volver a leer sin errores', () => {
    const filas = aFilasDeCarga(leerCsv(plantillaCsv(sucursales)), sucursales);
    assert.equal(filas.length, 3);
    assert.deepEqual(validarFilas(filas), {});
  });

  test('un CSV completo se guarda de principio a fin', async () => {
    const repo = createMockRepository(admin);
    const antes = await existencia(repo, 3, 5, 'M', 'Rosa');
    const filas = aFilasDeCarga(leerCsv('codigo,sucursal,talla,color,cantidad\n7501000000035,Xicotepec,M,Rosa,3\n'), sucursales);
    const r = await guardarFilas(repo, filas, () => {});
    assert.deepEqual(r, { ok: 1, errores: 0 });
    assert.equal(await existencia(repo, 3, 5, 'M', 'Rosa'), antes + 3);
  });
});
