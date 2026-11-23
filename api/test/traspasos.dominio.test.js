// Pruebas de las reglas puras de traspasos. No necesitan base de datos.
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { ESTADOS, detalleDuplicado, puedeVer } = require('../src/domain/traspasos');

describe('estados de traspaso', () => {
  test('son los 5 definidos con los clientes', () => {
    assert.deepEqual(ESTADOS, ['SOLICITADO', 'APROBADO', 'RECHAZADO', 'EN_CAMINO', 'RECIBIDO']);
  });
});

describe('detalleDuplicado', () => {
  test('detecta la misma prenda, talla y color aunque cambien mayusculas y espacios', () => {
    const detalle = [
      { idPrenda: 1, talla: 'M', color: 'Rojo', cantidad: 1 },
      { idPrenda: 1, talla: 'm', color: ' rojo ', cantidad: 2 },
    ];
    assert.match(detalleDuplicado(detalle), /prenda 1/);
  });

  test('misma prenda en otra talla o color no es duplicado', () => {
    const detalle = [
      { idPrenda: 1, talla: 'M', color: 'Rojo', cantidad: 1 },
      { idPrenda: 1, talla: 'G', color: 'Rojo', cantidad: 1 },
      { idPrenda: 1, talla: 'M', color: 'Azul', cantidad: 1 },
      { idPrenda: 2, talla: 'M', color: 'Rojo', cantidad: 1 },
    ];
    assert.equal(detalleDuplicado(detalle), null);
  });
});

describe('puedeVer', () => {
  const traspaso = { id_sucursal_origen: 2, id_sucursal_destino: 1, usuario_solicita: 3 };

  test('el administrador ve todos', () => {
    assert.equal(puedeVer({ id: 1, rol: 'administrador', sucursalId: null }, traspaso), true);
  });
  test('el gerente ve los de su sucursal como origen o como destino', () => {
    assert.equal(puedeVer({ id: 9, rol: 'gerente', sucursalId: 2 }, traspaso), true);
    assert.equal(puedeVer({ id: 9, rol: 'gerente', sucursalId: 1 }, traspaso), true);
  });
  test('el gerente no ve los de otras sucursales', () => {
    assert.equal(puedeVer({ id: 9, rol: 'gerente', sucursalId: 5 }, traspaso), false);
  });
  test('el empleado solo ve las solicitudes que creo', () => {
    assert.equal(puedeVer({ id: 3, rol: 'empleado', sucursalId: 1 }, traspaso), true);
    assert.equal(puedeVer({ id: 4, rol: 'empleado', sucursalId: 1 }, traspaso), false);
  });
});
