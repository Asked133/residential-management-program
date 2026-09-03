-- ==============================================================================
-- Archivo: supabase/migrations/20260902220000_asignacion_residentes.sql
-- Proyecto: HAVEN
-- Descripción: Auditoría, encapsulamiento y RPCs para la asignación de 
--              residentes a viviendas (tabla vivienda_residente).
-- ==============================================================================

-- ==============================================================================
-- 1. TABLA BASE Y BITÁCORA DE AUDITORÍA
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.vivienda_residente (
    vivienda_id INTEGER REFERENCES public.viviendas(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    PRIMARY KEY (vivienda_id, usuario_id)
);

CREATE TABLE IF NOT EXISTS public.vivienda_residente_bitacora (
    id BIGSERIAL PRIMARY KEY,
    registro_id TEXT NOT NULL,
    operacion VARCHAR(10) NOT NULL CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    modificado_por TEXT,
    modificado_en TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vivienda_residente_bitacora_registro ON public.vivienda_residente_bitacora(registro_id);
REVOKE ALL ON public.vivienda_residente_bitacora FROM authenticated, anon, service_role;

-- ==============================================================================
-- 2. TRIGGERS DE AUDITORÍA
-- ==============================================================================
DROP TRIGGER IF EXISTS trg_vivienda_res_auditoria_insert ON public.vivienda_residente;
CREATE TRIGGER trg_vivienda_res_auditoria_insert
    AFTER INSERT ON public.vivienda_residente
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();

DROP TRIGGER IF EXISTS trg_vivienda_res_auditoria_delete ON public.vivienda_residente;
CREATE TRIGGER trg_vivienda_res_auditoria_delete
    BEFORE DELETE ON public.vivienda_residente
    FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria();

-- ==============================================================================
-- 3. STORED PROCEDURE: ASIGNAR RESIDENTE A VIVIENDA
-- ==============================================================================
DROP FUNCTION IF EXISTS public.asignar_residente_vivienda(INTEGER, UUID);
CREATE OR REPLACE FUNCTION public.asignar_residente_vivienda(
    p_vivienda_id INTEGER, 
    p_usuario_id UUID
) 
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_rol_id INTEGER;
    v_existe_vivienda BOOLEAN;
    v_resultado jsonb;
BEGIN
    -- 1. Validar que la vivienda exista y esté activa
    SELECT EXISTS(SELECT 1 FROM public.viviendas WHERE id = p_vivienda_id AND activo = true) INTO v_existe_vivienda;
    IF NOT v_existe_vivienda THEN
        RAISE EXCEPTION 'Vivienda con ID % no existe o está inactiva', p_vivienda_id;
    END IF;

    -- 2. Validar que el usuario exista y obtener su rol
    SELECT rol_id INTO v_rol_id FROM public.usuarios WHERE id = p_usuario_id AND activo = true;
    IF v_rol_id IS NULL THEN
        RAISE EXCEPTION 'Usuario con ID % no existe o está inactivo', p_usuario_id;
    END IF;

    -- 3. Validar que el rol sea exactamente 2 (Residente)
    IF v_rol_id != 2 THEN
        RAISE EXCEPTION 'El usuario debe tener rol de Residente (rol_id=2). Rol actual: %', v_rol_id;
    END IF;

    -- 4. Insertar en la tabla pivote (Control de duplicidad 23505)
    BEGIN
        INSERT INTO public.vivienda_residente (vivienda_id, usuario_id)
        VALUES (p_vivienda_id, p_usuario_id);
    EXCEPTION
        WHEN unique_violation THEN
            RAISE EXCEPTION USING 
                ERRCODE = '23505',
                MESSAGE = 'El residente ya se encuentra asignado a esta vivienda.';
    END;

    -- 5. Armar objeto JSON compuesto mediante las vistas de lectura
    SELECT jsonb_build_object(
        'vivienda', row_to_json(vw_v),
        'residente', row_to_json(vw_u)
    ) INTO v_resultado
    FROM public.vw_viviendas vw_v, public.vw_usuarios vw_u
    WHERE vw_v.id = p_vivienda_id AND vw_u.id = p_usuario_id;

    RETURN v_resultado;
END;
$$;

-- ==============================================================================
-- 4. STORED PROCEDURE: QUITAR RESIDENTE DE VIVIENDA
-- ==============================================================================
DROP FUNCTION IF EXISTS public.quitar_residente_vivienda(INTEGER, UUID);
CREATE OR REPLACE FUNCTION public.quitar_residente_vivienda(
    p_vivienda_id INTEGER, 
    p_usuario_id UUID
) 
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_filas_afectadas INTEGER;
BEGIN
    DELETE FROM public.vivienda_residente 
    WHERE vivienda_id = p_vivienda_id AND usuario_id = p_usuario_id;

    GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;
    RETURN v_filas_afectadas > 0;
END;
$$;

-- ==============================================================================
-- 5. PERMISOS Y SEGURIDAD (ENCAPSULAMIENTO)
-- ==============================================================================
REVOKE SELECT, INSERT, UPDATE, DELETE ON public.vivienda_residente FROM authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.asignar_residente_vivienda(INTEGER, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.quitar_residente_vivienda(INTEGER, UUID) TO service_role;

NOTIFY pgrst, 'reload schema';

-- ==============================================================================
-- 6. INCREMENTO DE VERSIÓN
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