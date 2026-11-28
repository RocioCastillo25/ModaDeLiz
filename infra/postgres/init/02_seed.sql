-- =====================================================================
-- CheckLizz - Datos iniciales y de demostracion (SOLO DESARROLLO)
-- Los id_keycloak coinciden con los usuarios de infra/keycloak/realm-checklizz.json
-- =====================================================================

INSERT INTO sucursales (nombre, ubicacion) VALUES
  ('Huauchinango',  'Matriz - Huauchinango, Puebla'),
  ('Zacatlan',      'Zacatlan, Puebla'),
  ('Chignahuapan',  'Chignahuapan, Puebla'),
  ('Ahuazotepec',   'Ahuazotepec, Puebla'),
  ('Xicotepec',     'Xicotepec, Puebla');

INSERT INTO usuarios (nombre, email, id_keycloak, rol, id_sucursal_asignada) VALUES
  ('Duena Moda de Lizz',    'admin@checklizz.local',    '11111111-1111-1111-1111-111111111111', 'administrador', NULL),
  ('Gerente Huauchinango',  'gerente@checklizz.local',  '22222222-2222-2222-2222-222222222222', 'gerente',       1),
  ('Empleado Huauchinango', 'empleado@checklizz.local', '33333333-3333-3333-3333-333333333333', 'empleado',      1);

INSERT INTO prendas (codigo_barras, descripcion, marca, categoria, temporada, umbral_alerta) VALUES
  ('7501000000011', 'Blusa manga corta lisa',  'Lizz', 'Blusas',    'Primavera-Verano', 2),
  ('7501000000028', 'Jeans tiro alto',         'Lizz', 'Pantalones','Todo el anio',     2),
  ('7501000000035', 'Vestido floral midi',     'Lizz', 'Vestidos',  'Primavera-Verano', 2),
  ('7501000000042', 'Sueter tejido cuello alto','Lizz','Sueteres',  'Otono-Invierno',   3);

INSERT INTO inventario_sucursal (id_prenda, id_sucursal, talla, color, cantidad) VALUES
  (1, 1, 'M', 'Blanco', 6), (1, 2, 'M', 'Blanco', 3), (1, 3, 'M', 'Blanco', 0), (1, 1, 'G', 'Blanco', 2),
  (2, 1, '28', 'Azul',  4), (2, 4, '28', 'Azul',  5), (2, 5, '30', 'Negro', 1),
  (3, 2, 'CH', 'Rosa',  2), (3, 5, 'M', 'Rosa',   7),
  (4, 3, 'M', 'Gris',   5), (4, 1, 'G', 'Gris',   1);
