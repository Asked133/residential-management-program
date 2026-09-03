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