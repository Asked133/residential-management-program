# Contrato de Base de Datos: Vistas y Stored Procedures (HAVEN)

## 📌 Reglas de Consumo
1. **Acceso directo a tablas bloqueado:** Toda lectura se hace mediante vistas (`vw_*`) y toda escritura mediante Stored Procedures (`supabase.rpc(...)`).
2. **Auditoría:** En peticiones donde se conozca al usuario autenticado, enviar el header `x-actor-id: <UUID>` en la llamada de Supabase para alimentar la bitácora.
3. **Autoregistro de residentes:** No requiere `alta_usuario`. Al registrarse en Supabase Auth (`auth.users`), un trigger crea automáticamente el registro en `usuarios` con `rol_id = 2` (Residente).

---

## 1. Entidad: Usuarios

### Vista de Consulta
* **`vw_usuarios`**
  * `id`: UUID
  * `rol_id`: INTEGER
  * `rol_nombre`: VARCHAR(50)
  * `email`: VARCHAR(255)
  * `nombre`: VARCHAR(50)
  * `apellidos`: VARCHAR(50)
  * `telefono`: VARCHAR(20)
  * `activo`: BOOLEAN
  * `debe_cambiar_password`: BOOLEAN
  * `creado_en`: TIMESTAMPTZ

### Stored Procedures (RPC)
* **`alta_usuario`** (Uso administrativo / Alta manual)
  * Parámetros:
    * `p_id`: UUID (Obligatorio, debe existir previamente en `auth.users`)
    * `p_rol_id`: INTEGER
    * `p_email`: VARCHAR(255)
    * `p_nombre`: VARCHAR(50)
    * `p_apellidos`: VARCHAR(50)
    * `p_telefono`: VARCHAR(20) *(Opcional, default NULL)*
  * Retorna: Registro de `vw_usuarios`

* **`baja_usuario`** (Baja lógica: `activo = false`)
  * Parámetros:
    * `p_id`: UUID
  * Retorna: `BOOLEAN` (`true` si afectó al registro)

* **`cambio_usuario`** (Actualización dinámica de campos)
  * Parámetros:
    * `p_id`: UUID (Obligatorio)
    * `p_rol_id`: INTEGER *(Opcional)*
    * `p_nombre`: VARCHAR(50) *(Opcional)*
    * `p_apellidos`: VARCHAR(50) *(Opcional)*
    * `p_telefono`: VARCHAR(20) *(Opcional)*
    * `p_debe_cambiar_password`: BOOLEAN *(Opcional)*
  * Retorna: Registro actualizado de `vw_usuarios`

---

## 2. Entidad: Condominios

### Vista de Consulta
* **`vw_condominios`**
  * `id`: UUID
  * `nombre`: VARCHAR(150)
  * `activo`: BOOLEAN
  * `creado_en`: TIMESTAMPTZ

### Stored Procedures (RPC)
* **`alta_condominio`**
  * Parámetros:
    * `p_nombre`: VARCHAR(150)
  * Retorna: Registro de `vw_condominios`

* **`baja_condominio`** (Baja lógica: `activo = false`)
  * Parámetros:
    * `p_id`: UUID
  * Retorna: `BOOLEAN`

* **`cambio_condominio`**
  * Parámetros:
    * `p_id`: UUID
    * `p_nombre`: VARCHAR(150) *(Opcional)*
  * Retorna: Registro de `vw_condominios`

---

## 3. Entidad: Viviendas

### Vista de Consulta
* **`vw_viviendas`**
  * `id`: INTEGER
  * `numero_casa`: VARCHAR(50)
  * `tipo`: VARCHAR(20)
  * `activo`: BOOLEAN
  * `condominio_id`: UUID
  * `condominio_nombre`: VARCHAR(150)
  * `creado_en`: TIMESTAMPTZ

### Stored Procedures (RPC)
* **`alta_vivienda`**
  * Parámetros:
    * `p_numero_casa`: VARCHAR(50)
    * `p_condominio_id`: UUID
    * `p_tipo`: VARCHAR(20) *(Opcional)*
  * Retorna: Registro de `vw_viviendas`

* **`baja_vivienda`** (Baja lógica: `activo = false`)
  * Parámetros:
    * `p_id`: INTEGER
  * Retorna: `BOOLEAN`

* **`cambio_vivienda`**
  * Parámetros:
    * `p_id`: INTEGER
    * `p_numero_casa`: VARCHAR(50) *(Opcional)*
    * `p_tipo`: VARCHAR(20) *(Opcional)*
    * `p_condominio_id`: UUID *(Opcional)*
  * Retorna: Registro de `vw_viviendas`