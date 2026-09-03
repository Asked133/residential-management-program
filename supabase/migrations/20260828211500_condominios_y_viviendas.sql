-- ==============================================================================
-- Archivo: supabase/migrations/20260828211500_condominios_y_viviendas.sql
-- Proyecto: HAVEN
-- Descripción: Encapsulamiento de la entidad viviendas, tabla de auditoría,
-- vista de consulta, funciones RPC de mutación y control de permisos.
-- (Nota: Entidad condominios desacoplada para sprints posteriores)
-- ==============================================================================

-- ==============================================================================
-- 1. MODIFICACIÓN DE VIVIENDAS Y RESTRICCIONES
-- ==============================================================================
-- Limpieza preventiva si existían columnas o restricciones de condominios
ALTER TABLE public.viviendas DROP CONSTRAINT IF EXISTS viviendas_condominio_id_fkey CASCADE;
ALTER TABLE public.viviendas DROP CONSTRAINT IF EXISTS uq_viviendas_condominio_numero_casa CASCADE;
ALTER TABLE public.viviendas DROP CONSTRAINT IF EXISTS viviendas_condominio_id_numero_casa_key CASCADE;
ALTER TABLE public.viviendas DROP COLUMN IF EXISTS condominio_id CASCADE;

-- Control de estado y unicidad global de número de casa
ALTER TABLE public.viviendas ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE public.viviendas DROP CONSTRAINT IF EXISTS uq_viviendas_numero_casa;
ALTER TABLE public.viviendas DROP CONSTRAINT IF EXISTS viviendas_numero_casa_key;
ALTER TABLE public.viviendas ADD CONSTRAINT uq_viviendas_numero_casa UNIQUE (numero_casa);

-- Limpieza de políticas RLS heredadas
DROP POLICY IF EXISTS "Permitir lectura de viviendas a usuarios autenticados" ON public.viviendas;
DROP POLICY IF EXISTS "Administradores pueden gestionar viviendas" ON public.viviendas;

-- ==============================================================================
-- 2. TABLA DE BITÁCORA (AUDITORÍA)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.viviendas_bitacora (
    id BIGSERIAL PRIMARY KEY,
    registro_id TEXT NOT NULL,
    operacion VARCHAR(10) NOT NULL CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    modificado_por TEXT,
    modificado_en TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_viviendas_bitacora_registro ON public.viviendas_bitacora(registro_id);
CREATE INDEX IF NOT EXISTS idx_viviendas_bitacora_fecha ON public.viviendas_bitacora(modificado_en);
REVOKE ALL ON public.viviendas_bitacora FROM authenticated, anon, service_role;

-- ==============================================================================
-- 3. TRIGGERS DE AUDITORÍA
-- ==============================================================================
DROP TRIGGER IF EXISTS trg_viviendas_auditoria_insert ON public.viviendas;
CREATE TRIGGER trg_viviendas_auditoria_insert
    AFTER INSERT ON public.viviendas
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();

DROP TRIGGER IF EXISTS trg_viviendas_auditoria_update ON public.viviendas;
CREATE TRIGGER trg_viviendas_auditoria_update
    BEFORE UPDATE ON public.viviendas
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();

DROP TRIGGER IF EXISTS trg_viviendas_auditoria_delete ON public.viviendas;
CREATE TRIGGER trg_viviendas_auditoria_delete
    BEFORE DELETE ON public.viviendas
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();