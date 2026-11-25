// Pruebas de las reglas puras de traspasos. No necesitan base de datos.
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const {
  ESTADOS, detalleDuplicado, puedeVer, transicionValida, puedeCambiarEstado, mensajeAviso, TIPO_AVISO,
} = require('../src/domain/traspasos');

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

describe('transicionValida', () => {
  test('acepta solo el flujo SOLICITADO -> APROBADO/RECHAZADO -> EN_CAMINO -> RECIBIDO', () => {
    assert.equal(transicionValida('SOLICITADO', 'APROBADO'), true);
    assert.equal(transicionValida('SOLICITADO', 'RECHAZADO'), true);
    assert.equal(transicionValida('APROBADO', 'EN_CAMINO'), true);
    assert.equal(transicionValida('EN_CAMINO', 'RECIBIDO'), true);
  });
  test('rechaza saltos, retrocesos y repetir el mismo estado', () => {
    assert.equal(transicionValida('SOLICITADO', 'RECIBIDO'), false);
    assert.equal(transicionValida('SOLICITADO', 'EN_CAMINO'), false);
    assert.equal(transicionValida('APROBADO', 'RECHAZADO'), false);
    assert.equal(transicionValida('APROBADO', 'SOLICITADO'), false);
    assert.equal(transicionValida('SOLICITADO', 'SOLICITADO'), false);
  });
  test('RECHAZADO y RECIBIDO son finales', () => {
    for (const nuevo of ESTADOS) {
      assert.equal(transicionValida('RECHAZADO', nuevo), false);
      assert.equal(transicionValida('RECIBIDO', nuevo), false);
    }
  });
});

describe('puedeCambiarEstado', () => {
  // Zacatlan (2) surte a Huauchinango (1); lo pidio el empleado 3
  const traspaso = { id_sucursal_origen: 2, id_sucursal_destino: 1, usuario_solicita: 3 };
  const admin = { id: 1, rol: 'administrador', sucursalId: null };
  const gerenteOrigen = { id: 8, rol: 'gerente', sucursalId: 2 };
  const gerenteDestino = { id: 2, rol: 'gerente', sucursalId: 1 };
  const gerenteAjeno = { id: 9, rol: 'gerente', sucursalId: 5 };
  const empleado = { id: 3, rol: 'empleado', sucursalId: 1 };

  test('aprobar y rechazar: gerente de origen o destino y administrador', () => {
    for (const estado of ['APROBADO', 'RECHAZADO']) {
      assert.equal(puedeCambiarEstado(gerenteOrigen, traspaso, estado), true);
      assert.equal(puedeCambiarEstado(gerenteDestino, traspaso, estado), true);
      assert.equal(puedeCambiarEstado(admin, traspaso, estado), true);
      assert.equal(puedeCambiarEstado(gerenteAjeno, traspaso, estado), false);
    }
  });
  test('el solicitante nunca aprueba ni rechaza lo suyo, ni siquiera siendo gerente o administrador', () => {
    const gerenteSolicitante = { id: 2, rol: 'gerente', sucursalId: 1 };
    const adminSolicitante = { id: 1, rol: 'administrador', sucursalId: null };
    for (const estado of ['APROBADO', 'RECHAZADO']) {
      assert.equal(puedeCambiarEstado(gerenteSolicitante, { ...traspaso, usuario_solicita: 2 }, estado), false);
      assert.equal(puedeCambiarEstado(adminSolicitante, { ...traspaso, usuario_solicita: 1 }, estado), false);
    }
  });
  test('marcar en camino: solo el gerente de origen o el administrador', () => {
    assert.equal(puedeCambiarEstado(gerenteOrigen, traspaso, 'EN_CAMINO'), true);
    assert.equal(puedeCambiarEstado(admin, traspaso, 'EN_CAMINO'), true);
    assert.equal(puedeCambiarEstado(gerenteDestino, traspaso, 'EN_CAMINO'), false);
    assert.equal(puedeCambiarEstado(gerenteAjeno, traspaso, 'EN_CAMINO'), false);
  });
  test('marcar recibido: solo el gerente de destino o el administrador', () => {
    assert.equal(puedeCambiarEstado(gerenteDestino, traspaso, 'RECIBIDO'), true);
    assert.equal(puedeCambiarEstado(admin, traspaso, 'RECIBIDO'), true);
    assert.equal(puedeCambiarEstado(gerenteOrigen, traspaso, 'RECIBIDO'), false);
    assert.equal(puedeCambiarEstado(gerenteAjeno, traspaso, 'RECIBIDO'), false);
  });
  test('el empleado no cambia estados', () => {
    for (const estado of ESTADOS) assert.equal(puedeCambiarEstado(empleado, traspaso, estado), false);
  });
});

describe('avisos de cambio de estado', () => {
  test('hay un tipo de aviso por cada estado salvo SOLICITADO', () => {
    assert.deepEqual(Object.keys(TIPO_AVISO), ['APROBADO', 'RECHAZADO', 'EN_CAMINO', 'RECIBIDO']);
  });
  test('el mensaje menciona el numero del traspaso', () => {
    for (const estado of Object.keys(TIPO_AVISO)) assert.match(mensajeAviso(42, estado), /#42/);
  });
});
