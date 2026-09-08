-- ==============================================================================
-- Archivo: supabase/migrations/20260907100000_incorporacion_condominios.sql
-- Proyecto: HAVEN
-- Descripción: Incorporación de condominios, bitácora forense, actualización de
--              relaciones foráneas, vistas y stored procedures.
-- ==============================================================================

-- ==============================================================================
-- 1. TABLA BASE: CONDOMINIOS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.condominios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(150) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Inserción de condominio predeterminado para migración de datos
INSERT INTO public.condominios (id, nombre, activo)
VALUES ('a0000000-0000-0000-0000-000000000001', 'Condominio Residencial Principal', true)
ON CONFLICT (id) DO UPDATE 
SET nombre = EXCLUDED.nombre,
    activo = EXCLUDED.activo;

-- ==============================================================================
-- 2. RELACIONES UNO A MUCHOS (1:N)
-- ==============================================================================

-- A) Relación con viviendas
ALTER TABLE public.viviendas 
ADD COLUMN IF NOT EXISTS condominio_id UUID REFERENCES public.condominios(id) ON DELETE RESTRICT;

UPDATE public.viviendas 
SET condominio_id = 'a0000000-0000-0000-0000-000000000001'
WHERE condominio_id IS NULL;

ALTER TABLE public.viviendas ALTER COLUMN condominio_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_viviendas_condominio ON public.viviendas(condominio_id);

-- Restricción de unicidad compuesta por condominio
ALTER TABLE public.viviendas DROP CONSTRAINT IF EXISTS viviendas_numero_casa_key;
ALTER TABLE public.viviendas DROP CONSTRAINT IF EXISTS uq_viviendas_numero_casa;
ALTER TABLE public.viviendas DROP CONSTRAINT IF EXISTS uq_viviendas_condominio_numero_casa;
ALTER TABLE public.viviendas ADD CONSTRAINT uq_viviendas_condominio_numero_casa UNIQUE (condominio_id, numero_casa);

-- B) Relación con usuarios
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS condominio_id UUID REFERENCES public.condominios(id) ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS idx_usuarios_condominio ON public.usuarios(condominio_id);

UPDATE public.usuarios 
SET condominio_id = 'a0000000-0000-0000-0000-000000000001'
WHERE condominio_id IS NULL;

-- ==============================================================================
-- 3. TABLA BITÁCORA DE AUDITORÍA (CONDOMINIOS)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.condominios_bitacora (
    id BIGSERIAL PRIMARY KEY,
    registro_id TEXT NOT NULL,
    operacion VARCHAR(10) NOT NULL CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    modificado_por TEXT,
    modificado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_condominios_bitacora_registro ON public.condominios_bitacora(registro_id);
CREATE INDEX IF NOT EXISTS idx_condominios_bitacora_fecha ON public.condominios_bitacora(modificado_en);

REVOKE ALL ON public.condominios_bitacora FROM authenticated, anon, service_role;

-- ==============================================================================
-- 4. TRIGGERS DE AUDITORÍA CONECTADOS A fn_auditoria()
-- ==============================================================================
DROP TRIGGER IF EXISTS trg_condominios_auditoria_insert ON public.condominios;
CREATE TRIGGER trg_condominios_auditoria_insert
    AFTER INSERT ON public.condominios
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();

DROP TRIGGER IF EXISTS trg_condominios_auditoria_update ON public.condominios;
CREATE TRIGGER trg_condominios_auditoria_update
    BEFORE UPDATE ON public.condominios
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();

DROP TRIGGER IF EXISTS trg_condominios_auditoria_delete ON public.condominios;
CREATE TRIGGER trg_condominios_auditoria_delete
    BEFORE DELETE ON public.condominios
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();
    -- ==============================================================================
-- 5. VISTA DE CONSULTA (vw_condominios)
-- ==============================================================================
DROP VIEW IF EXISTS public.vw_condominios CASCADE;
CREATE VIEW public.vw_condominios AS
SELECT 
    c.id,
    c.nombre,
    c.activo,
    c.creado_en
FROM public.condominios c
WHERE c.activo = true;

-- ==============================================================================
-- 6. STORED PROCEDURES: CONDOMINIOS (RPC)
-- ==============================================================================

-- A) alta_condominio
DROP FUNCTION IF EXISTS public.alta_condominio(VARCHAR);
CREATE OR REPLACE FUNCTION public.alta_condominio(p_nombre VARCHAR(150))
RETURNS public.vw_condominios
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_id UUID;
    v_resultado public.vw_condominios;
BEGIN
    INSERT INTO public.condominios (nombre)
    VALUES (p_nombre)
    RETURNING id INTO v_id;

    SELECT * INTO v_resultado FROM public.vw_condominios WHERE id = v_id;
    RETURN v_resultado;
END;
$$;

-- B) baja_condominio (baja lógica)
DROP FUNCTION IF EXISTS public.baja_condominio(UUID);
CREATE OR REPLACE FUNCTION public.baja_condominio(p_id UUID)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_filas_afectadas INTEGER;
BEGIN
    UPDATE public.condominios
    SET activo = false
    WHERE id = p_id AND activo = true;

    GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;
    RETURN v_filas_afectadas > 0;
END;
$$;

-- C) cambio_condominio
DROP FUNCTION IF EXISTS public.cambio_condominio(UUID, VARCHAR);
CREATE OR REPLACE FUNCTION public.cambio_condominio(
    p_id UUID,
    p_nombre VARCHAR(150) DEFAULT NULL
)
RETURNS public.vw_condominios
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_resultado public.vw_condominios;
BEGIN
    UPDATE public.condominios
    SET nombre = COALESCE(NULLIF(trim(p_nombre), ''), nombre)
    WHERE id = p_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Condominio con ID % no encontrado', p_id;
    END IF;

    SELECT * INTO v_resultado FROM public.vw_condominios WHERE id = p_id;
    RETURN v_resultado;
END;
$$;

-- ==============================================================================
-- 7. PERMISOS Y SEGURIDAD: CONDOMINIOS
-- ==============================================================================
REVOKE SELECT, INSERT, UPDATE, DELETE ON public.condominios FROM authenticated, anon, service_role;

GRANT SELECT ON public.vw_condominios TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.alta_condominio(VARCHAR) TO service_role;
GRANT EXECUTE ON FUNCTION public.baja_condominio(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.cambio_condominio(UUID, VARCHAR) TO service_role;

NOTIFY pgrst, 'reload schema';

-- ==============================================================================
-- 8. ACTUALIZACIÓN DE ENTIDAD: VIVIENDAS (VISTA Y STORED PROCEDURES)
-- ==============================================================================

-- A) Actualización de la vista vw_viviendas
DROP VIEW IF EXISTS public.vw_viviendas CASCADE;
CREATE VIEW public.vw_viviendas AS
SELECT 
    v.id, 
    v.numero_casa, 
    v.tipo, 
    v.activo, 
    v.condominio_id,
    c.nombre AS condominio_nombre,
    v.creado_en
FROM public.viviendas v
JOIN public.condominios c ON c.id = v.condominio_id
WHERE v.activo = true;

-- B) Actualización de alta_vivienda
DROP FUNCTION IF EXISTS public.alta_vivienda(VARCHAR, UUID, VARCHAR);
DROP FUNCTION IF EXISTS public.alta_vivienda(VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION public.alta_vivienda(
    p_numero_casa VARCHAR(50), 
    p_condominio_id UUID,
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
    INSERT INTO public.viviendas (numero_casa, condominio_id, tipo) 
    VALUES (p_numero_casa, p_condominio_id, p_tipo) 
    RETURNING id INTO v_id;
    
    SELECT * INTO v_resultado FROM public.vw_viviendas WHERE id = v_id;
    RETURN v_resultado;
END;
$$;

-- Sobrecarga para mantener compatibilidad con llamadas legacy del frontend
CREATE OR REPLACE FUNCTION public.alta_vivienda(
    p_numero_casa VARCHAR(50), 
    p_tipo VARCHAR(20) DEFAULT NULL
) 
RETURNS public.vw_viviendas
SECURITY DEFINER 
SET search_path = public 
LANGUAGE plpgsql AS $$
BEGIN
    RETURN public.alta_vivienda(
        p_numero_casa := p_numero_casa,
        p_condominio_id := 'a0000000-0000-0000-0000-000000000001'::UUID,
        p_tipo := p_tipo
    );
END;
$$;

-- C) Actualización de cambio_vivienda
DROP FUNCTION IF EXISTS public.cambio_vivienda(INTEGER, VARCHAR, VARCHAR, UUID);
DROP FUNCTION IF EXISTS public.cambio_vivienda(INTEGER, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION public.cambio_vivienda(
    p_id INTEGER, 
    p_numero_casa VARCHAR(50) DEFAULT NULL, 
    p_tipo VARCHAR(20) DEFAULT NULL,
    p_condominio_id UUID DEFAULT NULL
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
        numero_casa = COALESCE(NULLIF(trim(p_numero_casa), ''), numero_casa),
        tipo = COALESCE(NULLIF(trim(p_tipo), ''), tipo),
        condominio_id = COALESCE(p_condominio_id, condominio_id)
    WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vivienda con ID % no encontrada', p_id;
    END IF;

    SELECT * INTO v_resultado FROM public.vw_viviendas WHERE id = p_id;
    RETURN v_resultado;
END;
$$;

-- D) Permisos y recarga PostgREST
GRANT SELECT ON public.vw_viviendas TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.alta_vivienda(VARCHAR, UUID, VARCHAR) TO service_role;
GRANT EXECUTE ON FUNCTION public.alta_vivienda(VARCHAR, VARCHAR) TO service_role;
GRANT EXECUTE ON FUNCTION public.cambio_vivienda(INTEGER, VARCHAR, VARCHAR, UUID) TO service_role;

NOTIFY pgrst, 'reload schema';