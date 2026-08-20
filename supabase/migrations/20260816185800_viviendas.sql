-- ============================================================================
-- 1. TABLA: VIVIENDAS (ID numérico autoincrementable)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.viviendas (
    id SERIAL PRIMARY KEY,
    numero_casa VARCHAR(50) NOT NULL,
    tipo VARCHAR(20) DEFAULT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    
    CONSTRAINT uq_viviendas_numero_casa UNIQUE (numero_casa)
);

-- RLS: Lectura para usuarios autenticados
DROP POLICY IF EXISTS "Permitir lectura de viviendas a usuarios autenticados" ON public.viviendas;
CREATE POLICY "Permitir lectura de viviendas a usuarios autenticados"
ON public.viviendas FOR SELECT
TO authenticated
USING (true);

-- RLS: Gestión exclusiva para Administradores
DROP POLICY IF EXISTS "Administradores pueden gestionar viviendas" ON public.viviendas;
CREATE POLICY "Administradores pueden gestionar viviendas"
ON public.viviendas FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid() AND u.rol_id = 1
  )
);

-- ============================================================================
-- 2. TABLA RELACIONAL: VIVIENDA_RESIDENTE (N:M)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.vivienda_residente (
    vivienda_id INTEGER NOT NULL REFERENCES public.viviendas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),

    -- Llave primaria compuesta para evitar duplicar asignaciones
    PRIMARY KEY (vivienda_id, usuario_id)
);

CREATE INDEX IF NOT EXISTS idx_vivienda_residente_vivienda ON public.vivienda_residente(vivienda_id);
CREATE INDEX IF NOT EXISTS idx_vivienda_residente_usuario ON public.vivienda_residente(usuario_id);

-- RLS: Residentes pueden consultar su propia casa asignada
DROP POLICY IF EXISTS "Usuarios pueden ver su propia asignacion de vivienda" ON public.vivienda_residente;
CREATE POLICY "Usuarios pueden ver su propia asignacion de vivienda"
ON public.vivienda_residente FOR SELECT
TO authenticated
USING (usuario_id = auth.uid());

-- RLS: Administradores pueden gestionar todas las asignaciones
DROP POLICY IF EXISTS "Administradores pueden gestionar asignaciones de vivienda" ON public.vivienda_residente;
CREATE POLICY "Administradores pueden gestionar asignaciones de vivienda"
ON public.vivienda_residente FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.id = auth.uid() AND u.rol_id = 1
  )
);

-- ============================================================================
-- 3. ACTUALIZAR VERSIÓN DEL SISTEMA
-- ============================================================================
UPDATE public.version 
SET numero_version = '1.1.0',
    updated_at = now();