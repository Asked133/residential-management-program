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