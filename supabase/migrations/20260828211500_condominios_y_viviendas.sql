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

    -- ==============================================================================
-- 4. VISTA DE CONSULTA
-- ==============================================================================
DROP VIEW IF EXISTS public.vw_viviendas CASCADE;
CREATE VIEW public.vw_viviendas AS
SELECT 
    v.id, 
    v.numero_casa, 
    v.tipo, 
    v.activo, 
    v.creado_en
FROM public.viviendas v;

-- ==============================================================================
-- 5. FUNCIONES DE ENCAPSULAMIENTO (STORED PROCEDURES)
-- ==============================================================================

-- a) alta_vivienda
DROP FUNCTION IF EXISTS public.alta_vivienda(VARCHAR, UUID, VARCHAR);
DROP FUNCTION IF EXISTS public.alta_vivienda(VARCHAR, VARCHAR);
CREATE OR REPLACE FUNCTION public.alta_vivienda(
    p_numero_casa VARCHAR(50), 
    p_tipo VARCHAR(20) DEFAULT NULL
) 
RETURNS public.vw_viviendas
SECURITY DEFINER 
SET search_path = public 
LANGUAGE plpgsql AS $$
DECLARE
    v_resultado public.vw_viviendas;
    v_id INTEGER;
BEGIN
    INSERT INTO public.viviendas (numero_casa, tipo) 
    VALUES (p_numero_casa, p_tipo) 
    RETURNING id INTO v_id;
    
    SELECT * INTO v_resultado FROM public.vw_viviendas WHERE id = v_id;
    RETURN v_resultado;
END;
$$;

-- b) baja_vivienda
DROP FUNCTION IF EXISTS public.baja_vivienda(INTEGER);
CREATE OR REPLACE FUNCTION public.baja_vivienda(p_id INTEGER) 
RETURNS BOOLEAN
SECURITY DEFINER 
SET search_path = public 
LANGUAGE plpgsql AS $$
DECLARE
    v_filas_afectadas INTEGER;
BEGIN
    UPDATE public.viviendas 
    SET activo = false 
    WHERE id = p_id AND activo = true;

    GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;
    RETURN v_filas_afectadas > 0;
END;
$$;

-- c) cambio_vivienda
DROP FUNCTION IF EXISTS public.cambio_vivienda(INTEGER, VARCHAR, VARCHAR, UUID);
DROP FUNCTION IF EXISTS public.cambio_vivienda(INTEGER, VARCHAR, VARCHAR);
CREATE OR REPLACE FUNCTION public.cambio_vivienda(
    p_id INTEGER, 
    p_numero_casa VARCHAR(50) DEFAULT NULL, 
    p_tipo VARCHAR(20) DEFAULT NULL
) 
RETURNS public.vw_viviendas
SECURITY DEFINER 
SET search_path = public 
LANGUAGE plpgsql AS $$
DECLARE
    v_resultado public.vw_viviendas;
BEGIN
    UPDATE public.viviendas 
    SET 
        numero_casa = COALESCE(p_numero_casa, numero_casa),
        tipo = COALESCE(p_tipo, tipo)
    WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vivienda con ID % no encontrada', p_id;
    END IF;

    SELECT * INTO v_resultado FROM public.vw_viviendas WHERE id = p_id;
    RETURN v_resultado;
END;
$$;

-- ==============================================================================
-- 6. PERMISOS Y SEGURIDAD POSTGREST
-- ==============================================================================
REVOKE SELECT, INSERT, UPDATE, DELETE ON public.viviendas FROM authenticated, anon, service_role;

GRANT SELECT ON public.vw_viviendas TO anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.alta_vivienda(VARCHAR, VARCHAR) TO service_role;
GRANT EXECUTE ON FUNCTION public.baja_vivienda(INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.cambio_vivienda(INTEGER, VARCHAR, VARCHAR) TO service_role;

NOTIFY pgrst, 'reload schema';

-- ==============================================================================
-- 7. INCREMENTO DE VERSIÓN
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