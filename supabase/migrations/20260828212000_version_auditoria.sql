-- ==============================================================================
-- Archivo: supabase/migrations/20260828212000_version_auditoria.sql
-- Proyecto: HAVEN[cite: 3]
-- Descripción: Creación de tabla de bitácora y triggers de auditoría para 
-- la tabla version, respetando las convenciones de base de datos.
-- ==============================================================================

-- ==============================================================================
-- 1. TABLA DE BITÁCORA PARA VERSION
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.version_bitacora (
    id BIGSERIAL PRIMARY KEY,
    registro_id TEXT NOT NULL,
    operacion VARCHAR(10) NOT NULL CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    modificado_por TEXT,
    modificado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices recomendados para optimizar consultas en la bitácora
CREATE INDEX IF NOT EXISTS idx_version_bitacora_registro ON public.version_bitacora(registro_id);
CREATE INDEX IF NOT EXISTS idx_version_bitacora_fecha ON public.version_bitacora(modificado_en);

-- Revocar accesos directos por seguridad
REVOKE ALL ON public.version_bitacora FROM authenticated, anon, service_role;

