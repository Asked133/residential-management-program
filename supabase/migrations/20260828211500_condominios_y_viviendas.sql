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
