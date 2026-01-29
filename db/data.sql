INSERT INTO categorias (id, nombre) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Analgésicos'),
  ('22222222-2222-2222-2222-222222222222', 'Antibióticos');

INSERT INTO medicamentos (
  id,
  nombre,
  cantidad_disponible,
  precio_unidad,
  categoria
) VALUES
(
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'Paracetamol 500mg',
  100,
  1.50,
  '11111111-1111-1111-1111-111111111111'
),
(
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'Amoxicilina 500mg',
  50,
  3.75,
  '22222222-2222-2222-2222-222222222222'
);

INSERT INTO ventas (id, fecha)
VALUES (
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  now()
);

INSERT INTO detalles_venta (
  venta,
  medicamento,
  cantidad
) VALUES
(
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  2
),
(
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  1
);
