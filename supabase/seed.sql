-- ============================================================================
-- 1. VERSIÓN DEL SISTEMA
-- ============================================================================
INSERT INTO public.version (numero_version) 
VALUES ('1.0.0');

-- ============================================================================
-- 2. CATÁLOGO BASE DE ROLES
-- ============================================================================
INSERT INTO public.roles (id, nombre, descripcion) VALUES
  (1, 'Administrador', 'Control total del sistema residencial'),
  (2, 'Residente', 'Acceso a pagos, reservaciones y avisos'),
  (3, 'Vigilancia', 'Control de accesos y registro de visitas'),
  (4, 'Mantenimiento', 'Atención y resolución de reportes e incidencias')
ON CONFLICT (id) DO UPDATE 
SET nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion;

SELECT setval('public.roles_id_seq', (SELECT MAX(id) FROM public.roles));

-- ============================================================================
-- 3. PERFIL DE USUARIO ADMINISTRADOR (Temporal)
-- ============================================================================
INSERT INTO public.usuarios (id, rol_id, email, nombre, apellidos, telefono)
VALUES (
  '6754a566-e529-40fb-8610-bd136ec77fd5',
  1,
  'admin@haven.com',
  'Admin',
  'Principal',
  '4420000000'
)
ON CONFLICT (id) DO UPDATE 
SET rol_id = EXCLUDED.rol_id,
    email = EXCLUDED.email,
    nombre = EXCLUDED.nombre,
    apellidos = EXCLUDED.apellidos,
    telefono = EXCLUDED.telefono;

-- ===========================================================================
-- 4. INSERTAR CASAS
-- ===========================================================================
INSERT INTO public.viviendas (numero_casa, tipo) VALUES
  ('Casa 101', 'Grande'),
  ('Casa 102', 'Mediana'),
  ('Depto 201', 'Chico')
ON CONFLICT (numero_casa) DO NOTHING;

-- ============================================================================
-- 5. ASIGNAR VIVIENDA AL ADMINISTRADOR
-- ============================================================================
INSERT INTO public.vivienda_residente (vivienda_id, usuario_id) VALUES
  (1, '6754a566-e529-40fb-8610-bd136ec77fd5')
ON CONFLICT (vivienda_id, usuario_id) DO NOTHING;