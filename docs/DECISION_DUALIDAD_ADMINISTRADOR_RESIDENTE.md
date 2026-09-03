# Decisión de Arquitectura y UX: Dualidad Administrador - Residente

> **Propósito:** Definir el estándar técnico y la experiencia de usuario (UX) para el caso de uso común donde la persona que administra el condominio también reside o es propietaria de una vivienda dentro del complejo.

---

## 🎯 El Problema de Negocio y UX

En desarrollos residenciales (condominios, privadas y cotos), es muy habitual que el Administrador o un miembro de la Mesa Directiva / Comité de Colonos **viva dentro del mismo residencial**.

Esto genera una disyuntiva:
* ¿Debe tener dos cuentas con dos correos distintos (`admin@haven.com` y `juan@gmail.com`)?
* ¿O debe tener una sola cuenta con acceso a ambas capacidades?

---

## ⚖️ Evaluación de Opciones Técnicas

### ❌ Opción 1: Dos Cuentas Separadas (2 Correos Distintos)
* **Mecanismo:** El usuario tiene una cuenta administrativa y otra cuenta personal como residente.
* **Por qué NO se recomienda:**
  * **Pésima Experiencia de Usuario (Alta Fricción):** El administrador tendría que cerrar sesión de su panel de trabajo cada vez que quiera consultar si le llegó un paquete a caseta, reservar la terraza para el fin de semana o pagar su cuota de mantenimiento, y luego volver a cerrar sesión para volver a trabajar.
  * **Riesgo de abandono y quejas:** En auditorías de UX (Nielsen Norman), forzar múltiples credenciales para una misma persona física es una de las mayores causas de frustración.

---

### ❌ Opción 3: Tabla Intermedia de Múltiples Roles (`usuario_roles` N a M)
* **Mecanismo:** Modificar la base de datos para que un usuario pueda tener un array o tabla relacional de roles asignados simultáneamente.
* **Por qué NO se recomienda en esta fase (Principio Ponytail - Anti-Sobreingeniería):**
  * La base de datos actual (`public.usuarios`), las vistas (`vw_usuarios`) y los microservicios (`Usuarios.Api`) están fuertemente tipados con un único `rol_id`.
  * Reestructurar la base de datos a un esquema multi-rol en este momento retrasaría la migración de microservicios y rompería los contratos vigentes de endpoints y procedimientos almacenados (`alta_usuario`, `cambio_usuario`).

---

### ✅ Opción 2: Cuenta Única con "Selector de Contexto" (RECOMENDADA)
* **Mecanismo (Patrón SaaS / PropTech - BuildingLink, Yardi, CondoControl):**
  * La persona física tiene **una sola cuenta** en el sistema con rol de **Administrador** (`rol_id = 1`), pero tiene **su propia vivienda asignada** en la base de datos (`vivienda_id`).
  * En la interfaz web, el Administrador tiene acceso por defecto al panel general.
  * En la cabecera (Navbar / Perfil), cuenta con un botón de conmutación: **`"Ver como Residente"`** o un acceso directo a **`"Mi Vivienda"`**.

#### 🌟 Beneficios:
1. **Jerarquía Natural de Privilegios:** El Administrador ya tiene un superconjunto de permisos (puede ver y gestionar todo). Darle acceso a las vistas de su propia casa no viola el principio de menor privilegio.
2. **Fricción Cero:** Una sola contraseña, un solo inicio de sesión, sin salir del sistema.
3. **Auditoría Transparente:** Todas las operaciones de bitácora (`x-actor-id`) corresponden al UUID real de la persona, evitando duplicidad de identidades.

---

## 🔒 Regla Inquebrantable de Seguridad

> [!CAUTION]
> **Prohibición de Google OAuth para Cuentas Administrativas**  
> Aunque el Administrador viva en la colonia, **su cuenta NUNCA debe autenticarse vía Google OAuth**.  
> Dado que su usuario tiene acceso a finanzas, residentes, accesos y bitácoras del condominio, **siempre debe iniciar sesión con correo y contraseña directa**.  
> El filtro de seguridad en `AuthCallbackComponent` debe mantenerse activo para revocar automáticamente la sesión si una cuenta con privilegios intenta ingresar por OAuth.

---

## 📅 Hoja de Ruta de Implementación

### Fase 1 (Inmediata / MVP Actual):
* Asignar la vivienda correspondiente al usuario administrador en la base de datos.
* Mantener el rol único de `Administrador`.
* El administrador prueba las funciones residenciales desde su panel administrativo o mediante consulta de su propia vivienda.

### Fase 2 (Siguiente Sprint):
* Diseñar en el Navbar del Administrador un switch o tarjeta de acceso rápido: **`"Mi Vivienda"`**.
* Cargar los componentes del residente (`Mis Visitas`, `Mis Pagos`, `Mis Reservas`) filtrando automáticamente por la vivienda asignada al Administrador.
