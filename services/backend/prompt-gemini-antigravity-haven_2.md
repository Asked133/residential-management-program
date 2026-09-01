# PROMPT PARA GEMINI (ANTIGRAVITY) — MIGRACIÓN HAVEN A MICROSERVICIOS

## CONTEXTO DEL PROYECTO

Estoy desarrollando **Haven**, un sistema de gestión de condominios, como proyecto universitario (Tópico 1: Microservicios). El backend actual es un monolito en **C#/.NET (ASP.NET Core + EF Core)** desplegado en **Render**, que se conecta a **Supabase** (Postgres + Auth) usando `HttpClient` contra el REST API de Supabase (`/rest/v1/...`).

El profesor pidió tres cambios estructurales que debes implementar juntos:

### 1. Separación en microservicios reales por entidad
No basta con organizar el código en carpetas: cada servicio debe ser un **proceso desplegado de forma independiente** (contenedor propio, Dockerfile propio, URL propia en Render), de modo que si uno se cae, los demás sigan funcionando. Las 3 entidades/servicios son:
- **Usuarios.Api** (ya existe parcialmente en el monolito actual)
- **Viviendas.Api** (ya existe la tabla, falta separar el servicio)
- **Condominios.Api** (aún no existe ni la tabla ni el servicio — se creará próximamente)

Importante: **los tres servicios comparten la MISMA base de datos** (un solo proyecto Supabase/Postgres). El aislamiento que pide el profesor es de **despliegue/runtime**, no de datos — esto es intencional, lo confirmó explícitamente porque de la separación de datos "se encarga el DBA, no el backend". Cada servicio abre su propia conexión hacia la misma BD, pero:
- Cada servicio solo opera sobre las tablas/vistas/funciones de SU propia entidad.
- Ningún servicio hace JOIN directo a tablas de otro dominio. Si Viviendas necesita datos de Condominios, lo pide vía HTTP al servicio de Condominios, nunca por SQL directo.

### 2. Todo acceso a datos debe pasar por objetos de base de datos, nunca SQL/REST directo a tablas
El profesor exige que el backend jamás toque tablas directamente. Por cada entidad debe existir en Postgres:
- Una **vista** para lecturas: ej. `vw_usuarios`, `vw_viviendas`, `vw_condominios`
- Tres **funciones/stored procedures**: `alta_X`, `baja_X`, `cambio_X` (X = usuario, vivienda, condominio)

**Estos objetos los entrega el DBA del equipo** (yo te pasaré los nombres exactos de columnas/parámetros de cada vista y función cuando estén listos — probablemente en un mensaje posterior a este). El backend solo los INVOCA:
- Lecturas → `GET {supabase_url}/rest/v1/vw_X?...filtros...`
- Alta/Baja/Cambio → `POST {supabase_url}/rest/v1/rpc/alta_X` (body con los parámetros de la función), y análogo para `baja_X`/`cambio_X`.

Actualmente el código en `SupabaseService.cs` hace llamadas directas a tablas, por ejemplo:
```csharp
var requestUrl = $"{_supabaseUrl}/rest/v1/usuarios?id=eq.{userId}&select=*";
```
Esto debe reemplazarse por el patrón de vista/RPC en cuanto tenga los nombres definitivos del DBA.

### 3. Nuevo modelo de registro de usuarios (autoregistro + OAuth)
Cambiamos el flujo de alta de cuentas:
- **Administradores**: los seguimos dando de alta nosotros manualmente (flujo backend privilegiado, usando `service_role_key`). Esto NO cambia.
- **Residentes**: ahora se registran ellos mismos, de dos formas posibles:
  - Email + contraseña (`supabase.auth.signUp` desde el frontend, directo a Supabase, SIN pasar por nuestro backend)
  - Google OAuth 2.0 (`supabase.auth.signInWithOAuth`, también directo desde el frontend)
- El endpoint `POST /api/auth/register` de nuestro backend **ya no crea residentes**. Solo debe quedar para el alta de administradores (o eliminarse/renombrarse a algo como `/api/auth/register-admin` protegido).
- La creación automática de la fila en la tabla `usuarios` cuando alguien se autoregistra (por cualquiera de los dos métodos) la hace un **trigger en `auth.users`** que el DBA va a crear — el backend no participa en ese insert. El trigger fija `rol_id = 2` (Residente) siempre, nunca lo decide el cliente.
- Como Google no siempre entrega teléfono o apellidos completos, el backend debe exponer un endpoint autenticado `PATCH /api/auth/completar-perfil` para que el frontend complete esos datos tras el primer login.
- La cuenta de un residente no es funcional hasta que un administrador le asigne una vivienda (tabla `vivienda_residente`). Esto NO es un bloqueo de login — el login siempre funciona; es un gate a nivel de aplicación (el frontend revisa si existe asignación y muestra "cuenta pendiente" si no la hay).

## ARCHIVOS RELEVANTES DEL PROYECTO ACTUAL
- `Backend/Program.cs` — configuración JWT Bearer contra Supabase (Authority = OIDC discovery), CORS, DbContext InMemory (temporal).
- `Backend/Controllers/AuthController.cs` — endpoints `ping`, `register`, `me`, `residentes`.
- `Backend/Services/SupabaseService.cs` / `ISupabaseService.cs` — llamadas HTTP directas al REST API de Supabase.
- `Backend/DTOs/UsuarioDto.cs`, `RegisterRequestDto.cs`.
- `supabase/migrations/` — schema de `usuarios`, `viviendas`, `vivienda_residente`, `roles`, `version`, con RLS ya definido.
- Estructura del repo (según README): `web/`, `mobile/`, `backend/` en la raíz del monorepo.

## FLUJO DE TRABAJO A SEGUIR (POR PUNTOS)

Sigue estos pasos EN ORDEN. Si un paso depende de información del DBA que aún no tienes (marcado explícitamente como "ESPERAR DBA"), detente en ese punto, avísame qué necesitas exactamente, y continúa con los pasos que sí puedas hacer mientras tanto (reordenando si es necesario, pero sin saltarte validaciones).

### FASE 0 — Librería compartida
1. Crea un proyecto `HavenApi.Shared` (class library) con:
   - La configuración de autenticación JWT Bearer contra Supabase (extraída de `Program.cs` actual) como un método de extensión reutilizable, ej. `AddHavenJwtAuth(this IServiceCollection services, IConfiguration config)`.
   - DTOs comunes que puedan compartir los 3 servicios (ej. estructura base de usuario autenticado, claims).
   - Un `HttpClient` tipado base para llamadas entre servicios (para cuando Viviendas necesite consultar Condominios o Usuarios).

### FASE 1 — Extraer Usuarios.Api
2. Crea un nuevo proyecto `Usuarios.Api` (Web API, mismo target framework net10.0), con su propio Dockerfile basado en el `Backend/Dockerfile` actual.
3. Mueve a este proyecto: `AuthController`, `SupabaseService`/`ISupabaseService`, `UsuarioDto`, `RegisterRequestDto`. Referencia `HavenApi.Shared` para la config JWT.
4. Elimina de `SupabaseService` el uso de `service_role_key` para crear residentes vía `/auth/v1/admin/users` — ese flujo queda SOLO para alta de administradores (mantenlo, pero renómbralo/protégelo claramente, ej. `RegisterAdminAsync`).
5. Agrega el endpoint `PATCH /api/auth/completar-perfil` (autenticado con `[Authorize]`), que reciba nombre/apellidos/teléfono y actualice el registro del usuario autenticado (usa el `sub`/`NameIdentifier` del JWT, igual que hace `Me()` actualmente).
6. **ESPERAR DBA (vistas/funciones de usuarios)**: cuando tengas los nombres exactos de `vw_usuarios`, `alta_usuario`, `baja_usuario`, `cambio_usuario` y sus parámetros, reemplaza las llamadas directas a `/rest/v1/usuarios` por:
   - Lecturas → `GET /rest/v1/vw_usuarios?...`
   - Altas/bajas/cambios → `POST /rest/v1/rpc/alta_usuario`, `rpc/baja_usuario`, `rpc/cambio_usuario`
   - Actualiza también `completar-perfil` para usar `rpc/cambio_usuario`.
7. **ESPERAR DBA (trigger de autoregistro)**: una vez el DBA confirme que el trigger en `auth.users` está creado, verifica que NO exista ya lógica duplicada en el backend intentando insertar en `usuarios` para residentes (debe quedar solo el trigger haciéndolo).

### FASE 2 — Extraer Viviendas.Api
8. Crea `Viviendas.Api`, mismo patrón de Dockerfile y referencia a `HavenApi.Shared`.
9. Implementa CRUD de `viviendas` y `vivienda_residente` (asignar/consultar vivienda de un residente, listar residentes de una vivienda, etc. — infiere los endpoints necesarios a partir del flujo de negocio descrito arriba: un admin asigna vivienda a un residente).
10. **ESPERAR DBA (vistas/funciones de viviendas)**: reemplaza cualquier acceso directo por `vw_viviendas` + `rpc/alta_vivienda`, `rpc/baja_vivienda`, `rpc/cambio_vivienda` (y análogo para `vivienda_residente` si el DBA define objetos separados para esa tabla puente).
11. Cualquier validación que requiera datos de usuarios (ej. verificar que un `usuario_id` existe antes de asignar vivienda) debe hacerse con una llamada HTTP a `Usuarios.Api`, nunca consultando la tabla `usuarios` directamente desde este servicio.

### FASE 3 — Crear Condominios.Api desde cero
12. Cuando el DBA entregue la migración SQL de la tabla `condominios` (y su relación con `viviendas`, probablemente un `condominio_id` en la tabla `viviendas`), crea `Condominios.Api` con el mismo patrón: Dockerfile, referencia a `Shared`, CRUD contra `vw_condominios` + `rpc/alta_condominio`, `rpc/baja_condominio`, `rpc/cambio_condominio`.
13. Actualiza `Viviendas.Api` para validar `condominio_id` llamando por HTTP a `Condominios.Api` en vez de asumir que el valor es válido.

### FASE 4 — Despliegue independiente
14. Crea un `render.yaml` (Blueprint) en la raíz del repo con 3 Web Services, cada uno con su propio `rootDir` (`Usuarios.Api/`, `Viviendas.Api/`, `Condominios.Api/`) y su propio Dockerfile, todos con las mismas variables de entorno de conexión a Supabase (`Supabase:Url`, `Supabase:AnonKey`, `Supabase:ServiceRoleKey` solo donde aplique).
15. Verifica que cada servicio pueda levantarse y responder de forma completamente independiente (probar deteniendo uno y confirmando que los otros dos siguen respondiendo).

## REGLAS QUE NO DEBES ROMPER EN NINGÚN PASO
- Nunca hagas que un servicio consulte tablas de otra entidad directamente (ni por REST de Supabase ni por SQL). Siempre HTTP entre servicios.
- Nunca dejes que `rol_id` se reciba como parámetro libre desde el cliente en ningún endpoint de registro — siempre debe fijarse en el backend o en el trigger/función de BD, nunca confiar en el payload del usuario.
- No implementes tú mismo las vistas/funciones SQL — esas las entrega el DBA. Si necesitas asumir una estructura temporalmente para no bloquearte, dilo explícitamente en el código con un comentario `// TODO: reemplazar por rpc/alta_usuario cuando el DBA lo entregue` y avísame en tu respuesta.
- Todo el código debe seguir en C#/.NET, ASP.NET Core + EF Core, consistente con el stack ya elegido para el proyecto.

Empieza por la FASE 0 y FASE 1 (los puntos que no dependen del DBA), y detente a preguntarme específicamente qué información de vistas/funciones/trigger necesitas antes de continuar con los puntos marcados "ESPERAR DBA".
