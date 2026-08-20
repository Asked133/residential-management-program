-- ============================================================================
-- 1. EXTENSIONES
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 2. EVENT TRIGGER: HABILITAR RLS AUTOMÁTICAMENTE EN TABLAS NUEVAS
-- ============================================================================
CREATE OR REPLACE FUNCTION rls_auto_enable()
RETURNS EVENT_TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;

DROP EVENT TRIGGER IF EXISTS ensure_rls;
CREATE EVENT TRIGGER ensure_rls
ON ddl_command_end
WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
EXECUTE FUNCTION rls_auto_enable();

-- ============================================================================
-- 3. TABLA: ROLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

DROP POLICY IF EXISTS "Permitir lectura de roles a usuarios autenticados" ON public.roles;
CREATE POLICY "Permitir lectura de roles a usuarios autenticados"
ON public.roles FOR SELECT
TO authenticated
USING (true);

-- ============================================================================
-- 4. TABLA: USUARIOS / PERFILES
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.usuarios (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    rol_id INTEGER NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
    email VARCHAR(255) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellidos VARCHAR(50) NOT NULL,
    telefono VARCHAR(20),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    
    CONSTRAINT uq_usuarios_email UNIQUE (email)
);

-- Índice único insensible a mayúsculas/minúsculas
CREATE UNIQUE INDEX IF NOT EXISTS idx_usuarios_email_lower ON public.usuarios (LOWER(email));

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios pueden leer su propio perfil" ON public.usuarios;
CREATE POLICY "Usuarios pueden leer su propio perfil"
ON public.usuarios FOR SELECT
USING (auth.uid() = id);

-- ============================================================================
-- 5. TABLA: CONTROL DE VERSIÓN
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.version (
    numero_version TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

DROP POLICY IF EXISTS "Permitir lectura publica de la version" ON public.version;
CREATE POLICY "Permitir lectura publica de la version"
ON public.version FOR SELECT
TO anon, authenticated
USING (true);