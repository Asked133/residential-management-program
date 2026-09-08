-- ============================================================================
-- 1. VERSIÓN DEL SISTEMA
-- ============================================================================
INSERT INTO public.version (numero_version, updated_at)
SELECT '1.0.0', now()
WHERE NOT EXISTS (SELECT 1 FROM public.version);

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
-- 3. CONDOMINIO MAESTRO (Requerido antes de usuarios y viviendas)
-- ============================================================================
INSERT INTO public.condominios (id, nombre, activo) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Condominio Residencial Principal', true)
ON CONFLICT (id) DO UPDATE 
SET nombre = EXCLUDED.nombre,
    activo = EXCLUDED.activo;

-- ============================================================================
-- 4. PERFIL DE USUARIO ADMINISTRADOR (Temporal)
-- ============================================================================
INSERT INTO public.usuarios (id, rol_id, email, nombre, apellidos, telefono, condominio_id)
VALUES (
  '6754a566-e529-40fb-8610-bd136ec77fd5',
  1,
  'admin@haven.com',
  'Admin',
  'Principal',
  '4420000000',
  'a0000000-0000-0000-0000-000000000001'
)
ON CONFLICT (id) DO UPDATE 
SET rol_id = EXCLUDED.rol_id,
    email = EXCLUDED.email,
    nombre = EXCLUDED.nombre,
    apellidos = EXCLUDED.apellidos,
    telefono = EXCLUDED.telefono,
    condominio_id = EXCLUDED.condominio_id;

-- ===========================================================================
-- 5. INSERTAR VIVIENDAS CON VÍNCULO A CONDOMINIO
-- ===========================================================================
INSERT INTO public.viviendas (condominio_id, numero_casa, tipo) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Casa 101', 'Grande'),
  ('a0000000-0000-0000-0000-000000000001', 'Casa 102', 'Mediana'),
  ('a0000000-0000-0000-0000-000000000001', 'Depto 201', 'Chico')
ON CONFLICT (condominio_id, numero_casa) DO NOTHING;

-- ============================================================================
-- 6. ASIGNAR VIVIENDA AL ADMINISTRADOR
-- ============================================================================
INSERT INTO public.vivienda_residente (vivienda_id, usuario_id) VALUES
  (1, '6754a566-e529-40fb-8610-bd136ec77fd5')
ON CONFLICT (vivienda_id, usuario_id) DO NOTHING;