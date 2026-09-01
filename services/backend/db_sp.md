vw_usuarios (columnas):
  id            UUID
  rol_id        INTEGER
  rol_nombre    VARCHAR(50)   -- join contra roles
  email         VARCHAR(255)
  nombre        VARCHAR(50)
  apellidos     VARCHAR(50)
  telefono      VARCHAR(20)
  activo        BOOLEAN
  creado_en     TIMESTAMPTZ

alta_usuario(
  p_id          UUID,             -- ya debe existir en auth.users
  p_rol_id      INTEGER,
  p_email       VARCHAR(255),
  p_nombre      VARCHAR(50),
  p_apellidos   VARCHAR(50),
  p_telefono    VARCHAR(20) DEFAULT NULL
) RETURNS public.vw_usuarios

baja_usuario(
  p_id          UUID
) RETURNS BOOLEAN                 -- desactiva (activo=false), no borra fila

cambio_usuario(
  p_id          UUID,
  p_rol_id      INTEGER     DEFAULT NULL,
  p_nombre      VARCHAR(50) DEFAULT NULL,
  p_apellidos   VARCHAR(50) DEFAULT NULL,
  p_telefono    VARCHAR(20) DEFAULT NULL
) RETURNS public.vw_usuarios      -- solo actualiza los campos no-NULL