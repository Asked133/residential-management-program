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
    u.email, 
    u.nombre,
    u.apellidos, 
    u.telefono, 
    u.activo, 
    u.debe_cambiar_password, 
    u.creado_en
FROM public.usuarios u;

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