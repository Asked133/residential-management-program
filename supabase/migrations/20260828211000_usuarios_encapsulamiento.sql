-- ==============================================================================
-- Archivo: supabase/migrations/20260828211000_usuarios_encapsulamiento.sql
-- Proyecto: HAVEN
-- Descripción: Encapsulamiento de la entidad usuarios, bitácora de auditoría, 
-- triggers de registro/sincronización y cron job de limpieza de inactivos.
-- ==============================================================================

-- ==============================================================================
-- 1. ALTER TABLE: AÑADIR COLUMNAS DE CONTROL
-- ==============================================================================
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS debe_cambiar_password BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE public.usuarios ALTER COLUMN apellidos DROP NOT NULL;

-- ==============================================================================
-- 2. TABLA DE BITÁCORA PARA USUARIOS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.usuarios_bitacora (
    id BIGSERIAL PRIMARY KEY,
    registro_id TEXT NOT NULL,
    operacion VARCHAR(10) NOT NULL CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    modificado_por TEXT,
    modificado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_usuarios_bitacora_registro ON public.usuarios_bitacora(registro_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_bitacora_fecha ON public.usuarios_bitacora(modificado_en);

REVOKE ALL ON public.usuarios_bitacora FROM authenticated, anon, service_role;

-- ==============================================================================
-- 3. TRIGGERS DE AUDITORÍA
-- ==============================================================================
DROP TRIGGER IF EXISTS trg_usuarios_auditoria_insert ON public.usuarios;
CREATE TRIGGER trg_usuarios_auditoria_insert
    AFTER INSERT ON public.usuarios
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();

DROP TRIGGER IF EXISTS trg_usuarios_auditoria_update ON public.usuarios;
CREATE TRIGGER trg_usuarios_auditoria_update
    BEFORE UPDATE ON public.usuarios
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();

DROP TRIGGER IF EXISTS trg_usuarios_auditoria_delete ON public.usuarios;
CREATE TRIGGER trg_usuarios_auditoria_delete
    BEFORE DELETE ON public.usuarios
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();

-- ==============================================================================
-- 4. VISTA DE CONSULTA 
-- ==============================================================================
DROP VIEW IF EXISTS public.vw_usuarios CASCADE;
CREATE VIEW public.vw_usuarios AS
SELECT 
    u.id, 
    u.rol_id, 
    r.nombre AS rol_nombre,
    u.email, 
    u.nombre, 
    u.apellidos, 
    u.telefono, 
    u.activo, 
    u.debe_cambiar_password, 
    u.creado_en
FROM public.usuarios u
JOIN public.roles r ON u.rol_id = r.id;

-- ==============================================================================
-- 5. FUNCIONES CRUD Y ADMINISTRATIVAS (ENCAPSULAMIENTO)
-- ==============================================================================

-- a) alta_usuario
DROP FUNCTION IF EXISTS public.alta_usuario(UUID, INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR);
CREATE OR REPLACE FUNCTION public.alta_usuario(
    p_id UUID, 
    p_rol_id INTEGER, 
    p_email VARCHAR(255),
    p_nombre VARCHAR(50), 
    p_apellidos VARCHAR(50), 
    p_telefono VARCHAR(20) DEFAULT NULL
) 
RETURNS public.vw_usuarios
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_usuario public.vw_usuarios;
BEGIN
    INSERT INTO public.usuarios (id, rol_id, email, nombre, apellidos, telefono)
    VALUES (p_id, p_rol_id, p_email, p_nombre, p_apellidos, p_telefono);
    
    SELECT * INTO v_usuario FROM public.vw_usuarios WHERE id = p_id;
    RETURN v_usuario;
END;
$$;

-- b) baja_usuario
DROP FUNCTION IF EXISTS public.baja_usuario(UUID);
CREATE OR REPLACE FUNCTION public.baja_usuario(p_id UUID) 
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_filas_afectadas INTEGER;
BEGIN
    UPDATE public.usuarios 
    SET activo = false 
    WHERE id = p_id AND activo = true;
    
    GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;
    RETURN v_filas_afectadas > 0;
END;
$$;

-- c) cambio_usuario
DROP FUNCTION IF EXISTS public.cambio_usuario(UUID, INTEGER, VARCHAR, VARCHAR, VARCHAR, BOOLEAN);
CREATE OR REPLACE FUNCTION public.cambio_usuario(
    p_id UUID, 
    p_rol_id INTEGER DEFAULT NULL, 
    p_nombre VARCHAR(50) DEFAULT NULL, 
    p_apellidos VARCHAR(50) DEFAULT NULL, 
    p_telefono VARCHAR(20) DEFAULT NULL, 
    p_debe_cambiar_password BOOLEAN DEFAULT NULL
) 
RETURNS public.vw_usuarios
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_usuario public.vw_usuarios;
BEGIN
    UPDATE public.usuarios
    SET 
        rol_id = COALESCE(p_rol_id, rol_id),
        nombre = COALESCE(p_nombre, nombre),
        apellidos = COALESCE(p_apellidos, apellidos),
        telefono = COALESCE(p_telefono, telefono),
        debe_cambiar_password = COALESCE(p_debe_cambiar_password, debe_cambiar_password)
    WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario con ID % no encontrado', p_id;
    END IF;
    
    SELECT * INTO v_usuario FROM public.vw_usuarios WHERE id = p_id;
    RETURN v_usuario;
END;
$$;

-- d) eliminar_usuario_definitivo
DROP FUNCTION IF EXISTS public.eliminar_usuario_definitivo(UUID);
CREATE OR REPLACE FUNCTION public.eliminar_usuario_definitivo(p_id UUID) 
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_filas_afectadas INTEGER;
BEGIN
    DELETE FROM auth.users WHERE id = p_id;
    
    GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;
    RETURN v_filas_afectadas > 0;
END;
$$;

-- ==============================================================================
-- 6. PERMISOS Y SEGURIDAD
-- ==============================================================================
REVOKE SELECT, INSERT, UPDATE, DELETE ON public.usuarios FROM authenticated, anon, service_role;
GRANT SELECT ON public.vw_usuarios TO service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.alta_usuario(UUID, INTEGER, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO service_role;
GRANT EXECUTE ON FUNCTION public.baja_usuario(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.cambio_usuario(UUID, INTEGER, VARCHAR, VARCHAR, VARCHAR, BOOLEAN) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.eliminar_usuario_definitivo(UUID) TO service_role;

-- ==============================================================================
-- 7. TRIGGER DE AUTOREGISTRO (AUTH.USERS)
-- ==============================================================================
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql 
AS $$
DECLARE
    v_es_google BOOLEAN;
    v_nombre VARCHAR(50);
    v_apellidos VARCHAR(50);
BEGIN
    v_es_google := (
        COALESCE(NEW.raw_app_meta_data->>'provider', '') = 'google' OR 
        COALESCE(NEW.app_metadata->>'provider', '') = 'google'
    );

    v_nombre := COALESCE(
        NEW.raw_user_meta_data->>'nombre',
        NEW.raw_user_meta_data->>'given_name',
        split_part(NEW.raw_user_meta_data->>'full_name', ' ', 1),
        NEW.raw_user_meta_data->>'name', 
        'Usuario'
    );

    v_apellidos := COALESCE(
        NEW.raw_user_meta_data->>'apellidos',
        NEW.raw_user_meta_data->>'family_name',
        NULLIF(trim(substr(COALESCE(NEW.raw_user_meta_data->>'full_name', ''), length(v_nombre) + 1)), ''),
        ''
    );

    INSERT INTO public.usuarios (
        id, 
        rol_id, 
        email, 
        nombre, 
        apellidos, 
        telefono, 
        activo,
        debe_cambiar_password
    )
    VALUES (
        NEW.id,
        2, -- Residente
        NEW.email,
        v_nombre,
        v_apellidos,
        NEW.raw_user_meta_data->>'telefono',
        true,
        CASE WHEN v_es_google THEN false ELSE true END
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        nombre = EXCLUDED.nombre,
        apellidos = COALESCE(NULLIF(EXCLUDED.apellidos, ''), public.usuarios.apellidos);

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 8. TRIGGER DE RESINCRONIZACIÓN POR GOOGLE OAUTH
-- ==============================================================================
DROP FUNCTION IF EXISTS public.handle_user_metadata_sync() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_user_metadata_sync() 
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql 
AS $$
BEGIN
    IF NEW.raw_user_meta_data IS DISTINCT FROM OLD.raw_user_meta_data THEN
        UPDATE public.usuarios
        SET 
            nombre = COALESCE(
                NEW.raw_user_meta_data->>'nombre',
                NEW.raw_user_meta_data->>'given_name',
                NEW.raw_user_meta_data->>'name', 
                nombre
            ),
            apellidos = COALESCE(
                NEW.raw_user_meta_data->>'apellidos',
                NEW.raw_user_meta_data->>'family_name', 
                apellidos
            )
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_metadata_updated ON auth.users;
CREATE TRIGGER on_auth_user_metadata_updated
    AFTER UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_user_metadata_sync();

-- ==============================================================================
-- 9. JOB DE LIMPIEZA POR INACTIVIDAD
-- ==============================================================================
CREATE EXTENSION IF NOT EXISTS pg_cron;

DROP FUNCTION IF EXISTS public.borrar_residentes_inactivos();
CREATE OR REPLACE FUNCTION public.borrar_residentes_inactivos() 
RETURNS VOID
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql 
AS $$
DECLARE
    v_usuario RECORD;
BEGIN
    FOR v_usuario IN 
        SELECT u.id 
        FROM public.usuarios u
        WHERE u.rol_id = 2 
          AND (
              (SELECT last_sign_in_at FROM auth.users WHERE id = u.id) < now() - interval '3 months'
              OR (
                  (SELECT last_sign_in_at FROM auth.users WHERE id = u.id) IS NULL 
                  AND (SELECT created_at FROM auth.users WHERE id = u.id) < now() - interval '3 months'
              )
          )
    LOOP
        PERFORM public.eliminar_usuario_definitivo(v_usuario.id);
    END LOOP;
END;
$$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'borrar_residentes_inactivos_diario') THEN
        PERFORM cron.unschedule('borrar_residentes_inactivos_diario');
    END IF;
END;
$$;

SELECT cron.schedule('borrar_residentes_inactivos_diario', '0 3 * * *', 'SELECT public.borrar_residentes_inactivos();');

NOTIFY pgrst, 'reload schema';

-- ==============================================================================
-- 10. INCREMENTO DE VERSIÓN
-- ==============================================================================
UPDATE public.version 
SET 
    numero_version = CASE 
        WHEN numero_version ~ '^[0-9]+\.[0-9]+(\.[0-9]+)?$' THEN
            split_part(numero_version, '.', 1) || '.' || 
            ((split_part(numero_version, '.', 2)::integer) + 1)::text || 
            CASE 
                WHEN split_part(numero_version, '.', 3) <> '' THEN '.' || split_part(numero_version, '.', 3) 
                ELSE '' 
            END
        WHEN numero_version ~ '^[0-9]+$' THEN
            ((numero_version::integer) + 1)::text
        ELSE numero_version || '.1'
    END,
    updated_at = now();