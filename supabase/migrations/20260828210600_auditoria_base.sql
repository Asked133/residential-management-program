-- ==============================================================================
-- Archivo: supabase/migrations/20260828210600_auditoria_base.sql
-- Proyecto: HAVEN[cite: 3]
-- Descripción: Función genérica de auditoría para registro de operaciones.
-- Cumple con el requerimiento de registrar: ¿Quién lo hizo?, ¿Qué hizo? y ¿Cuándo lo hizo?[cite: 1].
-- ==============================================================================

DROP FUNCTION IF EXISTS public.fn_auditoria() CASCADE;

-- ==============================================================================
-- CREACIÓN DE FUNCIÓN BASE DE AUDITORÍA
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.fn_auditoria()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_actor TEXT;
    v_registro_id TEXT;
    v_datos_anteriores JSONB := NULL;
    v_datos_nuevos JSONB := NULL;
    v_tabla_bitacora TEXT := TG_TABLE_NAME || '_bitacora';
BEGIN
    -- 1. Intentar capturar el actor desde los headers (PostgREST)
    BEGIN
        v_actor := current_setting('request.headers', true)::json->>'x-actor-id';
    EXCEPTION WHEN OTHERS THEN
        v_actor := NULL;
    END;
    
    -- Fallback: Si no hay contexto de PostgREST, usar el usuario de la sesión
    IF v_actor IS NULL THEN
        v_actor := session_user;
    END IF;

    -- 2. Lógica por tipo de operación
    IF TG_OP = 'INSERT' THEN
        v_registro_id := COALESCE(to_jsonb(NEW)->>'id', to_jsonb(NEW)->>'numero_version', 'n/a');
        v_datos_nuevos := to_jsonb(NEW);
        
        EXECUTE format(
            'INSERT INTO %I (registro_id, operacion, datos_anteriores, datos_nuevos, modificado_por, modificado_en) VALUES ($1, $2, $3, $4, $5, NOW())', 
            v_tabla_bitacora
        ) USING v_registro_id, TG_OP, v_datos_anteriores, v_datos_nuevos, v_actor;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        v_registro_id := COALESCE(to_jsonb(NEW)->>'id', to_jsonb(NEW)->>'numero_version', 'n/a');
        v_datos_anteriores := to_jsonb(OLD);
        v_datos_nuevos := to_jsonb(NEW);
        
        EXECUTE format(
            'INSERT INTO %I (registro_id, operacion, datos_anteriores, datos_nuevos, modificado_por, modificado_en) VALUES ($1, $2, $3, $4, $5, NOW())', 
            v_tabla_bitacora
        ) USING v_registro_id, TG_OP, v_datos_anteriores, v_datos_nuevos, v_actor;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        v_registro_id := COALESCE(to_jsonb(OLD)->>'id', to_jsonb(OLD)->>'numero_version', 'n/a');
        v_datos_anteriores := to_jsonb(OLD);
        
        EXECUTE format(
            'INSERT INTO %I (registro_id, operacion, datos_anteriores, datos_nuevos, modificado_por, modificado_en) VALUES ($1, $2, $3, $4, $5, NOW())', 
            v_tabla_bitacora
        ) USING v_registro_id, TG_OP, v_datos_anteriores, v_datos_nuevos, v_actor;
        
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;