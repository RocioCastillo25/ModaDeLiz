// CAPA DE PRESENTACION: rutas, validacion de entrada (Zod) y codigos HTTP.
const express = require('express');
const { z } = require('zod');
const { authenticate, requireRole } = require('../middlewares/auth');
const { wrap } = require('../middlewares/errorHandler');
const sucursalesRepo = require('../repositories/sucursalesRepository');
const usuarios = require('../services/usuariosService');
const prendas = require('../services/prendasService');
const inventario = require('../services/inventarioService');
const traspasos = require('../services/traspasosService');
const notificaciones = require('../services/notificacionesService');
const { ESTADOS } = require('../domain/traspasos');
const { forbidden } = require('../errors');

const router = express.Router();
const ROLES = ['administrador', 'gerente', 'empleado'];
const id = z.coerce.number().int().positive();
const bool = z.enum(['true', 'false']).transform((v) => v === 'true');

// Todo lo de abajo requiere un token valido
router.use(authenticate);

// ---------- Perfil ----------
router.get('/me', (req, res) => res.json(req.user));

// ---------- Sucursales ----------
router.get('/sucursales', wrap(async (_req, res) => res.json(await sucursalesRepo.list())));

// ---------- Usuarios (solo administrador) ----------
const usuarioNuevo = z.object({
  nombre: z.string().min(2).max(120),
  email: z.string().email(),
  username: z.string().min(3).max(60),
  password: z.string().min(8),
  rol: z.enum(ROLES),
  sucursalId: id.optional(),
});
const usuarioEdicion = z.object({
  nombre: z.string().min(2).max(120).optional(),
  email: z.string().email().optional(),
  rol: z.enum(ROLES).optional(),
  sucursalId: id.optional(),
});

router.get('/usuarios', requireRole('administrador'), wrap(async (req, res) => {
  const q = z.object({ sucursalId: id.optional(), activo: bool.optional() }).parse(req.query);
  res.json(await usuarios.list(q));
}));
router.get('/usuarios/:id', requireRole('administrador'), wrap(async (req, res) =>
  res.json(await usuarios.get(id.parse(req.params.id)))));
router.post('/usuarios', requireRole('administrador'), wrap(async (req, res) =>
  res.status(201).json(await usuarios.crear(usuarioNuevo.parse(req.body)))));
router.put('/usuarios/:id', requireRole('administrador'), wrap(async (req, res) =>
  res.json(await usuarios.actualizar(id.parse(req.params.id), usuarioEdicion.parse(req.body)))));
router.patch('/usuarios/:id/activo', requireRole('administrador'), wrap(async (req, res) => {
  const { activo } = z.object({ activo: z.boolean() }).parse(req.body);
  res.json(await usuarios.setActivo(id.parse(req.params.id), activo, req.user));
}));

// ---------- Prendas (catalogo) ----------
const prendaNueva = z.object({
  codigo_barras: z.string().min(3).max(64),
  descripcion: z.string().min(2).max(200),
  marca: z.string().max(80).optional(),
  categoria: z.string().max(80).optional(),
  temporada: z.string().max(40).optional(),
  foto_url: z.string().url().optional(),
  umbral_alerta: z.number().int().min(0).optional(),
});

router.get('/prendas', wrap(async (req, res) => {
  const q = z.object({
    q: z.string().optional(), codigo: z.string().optional(), categoria: z.string().optional(),
    talla: z.string().optional(), color: z.string().optional(), sucursalId: id.optional(),
  }).parse(req.query);
  res.json(await prendas.buscar(q));
}));
router.get('/prendas/codigo/:codigo', wrap(async (req, res) => res.json(await prendas.fichaPorCodigo(req.params.codigo))));
router.get('/prendas/:id', wrap(async (req, res) => res.json(await prendas.ficha(id.parse(req.params.id)))));
router.post('/prendas', requireRole('administrador', 'gerente'), wrap(async (req, res) =>
  res.status(201).json(await prendas.crear(prendaNueva.parse(req.body)))));
router.put('/prendas/:id', requireRole('administrador', 'gerente'), wrap(async (req, res) =>
  res.json(await prendas.actualizar(id.parse(req.params.id), prendaNueva.partial().omit({ codigo_barras: true }).parse(req.body)))));
router.delete('/prendas/:id', requireRole('administrador', 'gerente'), wrap(async (req, res) =>
  res.json(await prendas.desactivar(id.parse(req.params.id)))));

// ---------- Inventario ----------
router.get('/inventario', wrap(async (req, res) => {
  const q = z.object({ sucursalId: id.optional(), prendaId: id.optional(), bajoUmbral: bool.optional() }).parse(req.query);
  // Un gerente solo ve el inventario detallado de su sucursal; empleados consultan por /prendas
  if (req.user.rol === 'gerente') {
    if (q.sucursalId && q.sucursalId !== req.user.sucursalId) throw forbidden();
    q.sucursalId = req.user.sucursalId;
  }
  res.json(await inventario.list(q));
}));
router.get('/inventario/:id/historial', requireRole('administrador', 'gerente'), wrap(async (req, res) =>
  res.json(await inventario.historial(id.parse(req.params.id)))));

const existencia = z.object({
  idPrenda: id, idSucursal: id,
  talla: z.string().min(1).max(20), color: z.string().min(1).max(40),
  cantidad: z.number().int().min(0),
});
router.put('/inventario', requireRole('administrador', 'gerente'), wrap(async (req, res) =>
  res.json(await inventario.fijarExistencia(req.user, existencia.parse(req.body)))));

// ---------- Ventas (descuento de stock) ----------
router.post('/ventas', requireRole('administrador', 'gerente', 'empleado'), wrap(async (req, res) => {
  const body = z.object({ idInventario: id, cantidad: z.number().int().positive() }).parse(req.body);
  res.status(201).json(await inventario.vender(req.user, body));
}));

// ---------- Traspasos (solicitud y consulta) ----------
const traspasoNuevo = z.object({
  idSucursalOrigen: id,
  idSucursalDestino: id.optional(), // solo lo usa el administrador
  detalle: z.array(z.object({
    idPrenda: id,
    talla: z.string().min(1).max(20),
    color: z.string().min(1).max(40),
    cantidad: z.number().int().positive(),
  })).min(1).max(50),
});

router.get('/traspasos', wrap(async (req, res) => {
  const q = z.object({ estado: z.enum(ESTADOS).optional(), sucursalId: id.optional() }).parse(req.query);
  res.json(await traspasos.listar(req.user, q));
}));
router.get('/traspasos/:id', wrap(async (req, res) =>
  res.json(await traspasos.obtener(req.user, id.parse(req.params.id)))));
router.post('/traspasos', wrap(async (req, res) =>
  res.status(201).json(await traspasos.crear(req.user, traspasoNuevo.parse(req.body)))));
router.patch('/traspasos/:id/estado', wrap(async (req, res) => {
  const { estado } = z.object({ estado: z.enum(ESTADOS) }).parse(req.body);
  res.json(await traspasos.cambiarEstado(req.user, id.parse(req.params.id), estado));
}));

// ---------- Notificaciones (avisos del usuario autenticado) ----------
router.get('/notificaciones', wrap(async (req, res) => {
  const q = z.object({
    soloNoLeidas: bool.optional(),
    limite: z.coerce.number().int().min(1).max(100).optional(),
  }).parse(req.query);
  res.json(await notificaciones.listar(req.user, q));
}));
router.get('/notificaciones/resumen', wrap(async (req, res) => res.json(await notificaciones.resumen(req.user))));
router.post('/notificaciones/marcar-leidas', wrap(async (req, res) =>
  res.json(await notificaciones.marcarTodasLeidas(req.user))));
router.patch('/notificaciones/:id/leida', wrap(async (req, res) =>
  res.json(await notificaciones.marcarLeida(req.user, id.parse(req.params.id)))));

module.exports = router;
