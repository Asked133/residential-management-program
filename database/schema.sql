
CREATE TABLE IF NOT EXISTS public.usuarios (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre VARCHAR(50),
    apellidos VARCHAR(50),
    telefono VARCHAR(20),
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('Administrador', 'Residente')),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);


ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;


DROP POLICY IF EXISTS "Usuarios pueden leer su propio perfil" ON public.usuarios;
CREATE POLICY "Usuarios pueden leer su propio perfil"
ON public.usuarios
FOR SELECT
USING (auth.uid() = id);

--------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.version (
    numero_version INTEGER NOT NULL
);


INSERT INTO public.version (numero_version) VALUES (1);


--------------------------------------------------------------------------------------------