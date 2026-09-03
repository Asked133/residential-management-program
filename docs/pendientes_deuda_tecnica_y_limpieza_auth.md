# Pendientes de Deuda Técnica y Limpieza — Módulo de Autenticación y OAuth

> **Documento generado a partir de las auditorías técnicas (Junior-to-Senior y Ponytail).**  
> **Propósito:** Registrar formalmente las áreas de mejora, optimizaciones y limpieza que quedaron fuera del alcance inmediato del PR de OAuth 2.0 / Login Combinado para ser abordadas en el siguiente sprint de estabilización.

---

## 📋 Resumen Ejecutivo

Durante las auditorías de código se corrigieron los bloqueos críticos (*blockers*) inmediatos:
- ✅ Activación del evento `SIGNED_IN` en `onAuthStateChange` (para evitar spinner infinito en OAuth PKCE).
- ✅ Reordenamiento del toast informativo previo a la navegación en `signOutAndRedirect()`.
- ✅ Inclusión de timeout de seguridad de 10s en `loginGoogle()` contra redirecciones huérfanas.
- ✅ Limpieza de inyecciones e imports no utilizados (`ActivatedRoute`, `Router` directo en vistas).
- ✅ Centralización del mapeo de roles esperados (`MODO_ROLES`).

A continuación se detallan los elementos de **deuda técnica, tipado y arquitectura** que deben atenderse de manera controlada sin romper contratos existentes.

---

## 🔍 Detalle de Pendientes

### 1. Tipado Débil y Cadena de Fallbacks en `setAuthenticatedUser`
* **Archivo:** [`web/src/app/core/services/auth.service.ts`](file:///c:/Users/dcgom/OneDrive/Documentos/Documentos/Universidad/7mo%20Semestre/Topico1/GithubRepo/residential-management-program/web/src/app/core/services/auth.service.ts) (Líneas ~195 a 210)
* **Prioridad:** 🟡 Media / Arquitectura
* **Diagnóstico (Ponytail P2):**
  La firma del método recibe el perfil como `any | null`:
  ```typescript
  private setAuthenticatedUser(
    sessionUser: { id: string; email?: string; ... },
    profile?: any | null
  ): void
  ```
  Esto provoca una cadena defensiva de hasta 10 propiedades para inferir el rol:
  `profile?.rol ?? profile?.role ?? profile?.rol_nombre ?? profile?.rolNombre ?? profile?.rol_id ?? ...`
* **Por qué se pospuso:**
  El backend está en plena transición entre el monolito (`/api/auth/me`), la base de datos Supabase directa (`vw_usuarios`) y el microservicio `Usuarios.Api`. Tocar esto hoy podría romper sesiones activas si un endpoint devuelve `rol_id` en lugar de `role`.
* **Solución recomendada para el siguiente sprint:**
  1. Definir un DTO unificado `UserProfileResponse` en `web/src/app/core/models/user-profile.model.ts`.
  2. Estandarizar la salida del microservicio `Usuarios.Api` para que siempre devuelva campos uniformes (`id`, `email`, `role`, `nombre`, `apellidos`).
  3. Reducir la función de normalización a un contrato único estricto sin `any`.

---

### 2. Desacople del Doble Disparo de `refreshProfile()` en Login Tradicional
* **Archivo:** [`web/src/app/core/services/auth.service.ts`](file:///c:/Users/dcgom/OneDrive/Documentos/Documentos/Universidad/7mo%20Semestre/Topico1/GithubRepo/residential-management-program/web/src/app/core/services/auth.service.ts) (Líneas ~45-55 y 140-150)
* **Prioridad:** 🟢 Baja / Optimización interna
* **Diagnóstico (Ponytail P1):**
  Al iniciar sesión con contraseña (`signInWithPassword`), Supabase dispara internamente el evento `SIGNED_IN`.  
  Actualmente, tanto `login()` llama explícitamente a `await this.refreshProfile()` como el listener global `onAuthStateChange` al recibir `SIGNED_IN`.  
  *Nota:* Actualmente **no causa fallos** porque existe el candado deduplicador `refreshProfilePromise` que reutiliza la promesa en vuelo.
* **Por qué se pospuso:**
  Quitar la llamada de `login()` requiere cambiar el flujo síncrono a uno 100% guiado por eventos en el componente, lo cual aumentaba el radio de impacto antes de validar el despliegue de OAuth.
* **Solución recomendada para el siguiente sprint:**
  Hacer que el flujo de autenticación sea completamente reactivo: `login()` solo invoca `signInWithPassword`, y toda la carga de perfil, establecimiento de señales y redirección al dashboard ocurra dentro del listener de estado de sesión.

---

### 3. Warning de Optimización de SweetAlert2 en Build (`CommonJS / AMD`)
* **Archivo:** [`web/angular.json`](file:///c:/Users/dcgom/OneDrive/Documentos/Documentos/Universidad/7mo%20Semestre/Topico1/GithubRepo/residential-management-program/web/angular.json)
* **Prioridad:** 🟢 Baja / Build & Rendimiento
* **Diagnóstico:**
  Durante `ng build`, Angular emite la advertencia:
  ```text
  ▲ [WARNING] Module 'sweetalert2' used by 'src/app/features/...' is not ESM.
    CommonJS or AMD dependencies can cause optimization bailouts.
  ```
* **Por qué se pospuso:**
  Es una advertencia cosmética de empaquetado heredada del inicio del proyecto. No impide la ejecución ni la compilación.
* **Solución recomendada para el siguiente sprint:**
  * **Opción A (Rápida):** Añadir `"allowedCommonJsDependencies": ["sweetalert2"]` en las opciones de build de `angular.json` para silenciar la advertencia.
  * **Opción B (Ideal Ponytail):** Reemplazar SweetAlert2 por un servicio de notificaciones/toasts ligero propio en Angular (o usando Tailwind + Signals), reduciendo el bundle transferible en ~80 kB.

---

### 4. Unificación de Propiedades en `AuthUser`
* **Archivo:** [`web/src/app/core/models/auth-user.model.ts`](file:///c:/Users/dcgom/OneDrive/Documentos/Documentos/Universidad/7mo%20Semestre/Topico1/GithubRepo/residential-management-program/web/src/app/core/models/auth-user.model.ts)
* **Prioridad:** 🟢 Baja / Limpieza de Modelos
* **Diagnóstico:**
  La interfaz `AuthUser` contiene tanto `role` como `rol` como propiedades opcionales para mantener compatibilidad con plantillas viejas:
  ```typescript
  export interface AuthUser {
    id: string;
    email: string;
    role?: string;
    rol?: string;
    ...
  }
  ```
* **Por qué se pospuso:**
  Varios componentes del dashboard leen `currentUser()?.rol` mientras que otros leen `currentUser()?.role`.
* **Solución recomendada para el siguiente sprint:**
  Hacer un barrido en el proyecto para usar únicamente `role` (o `rol` en español) y retirar el alias duplicado del modelo.

---

### 5. Cobertura de Pruebas Unitarias para el Flujo OAuth
* **Archivos:**
  - `web/src/app/features/auth/login/login.component.spec.ts`
  - `web/src/app/features/auth/callback/auth-callback.component.spec.ts`
  - `web/src/app/core/services/auth.service.spec.ts`
* **Prioridad:** 🟡 Media / Calidad
* **Diagnóstico:**
  Los tests existentes no cubren los nuevos casos introducidos:
  - Toggle de pestañas (`Residente` vs `Administrador · Vigilancia`).
  - Llamada a `loginWithGoogle()`.
  - Comportamiento de `AuthCallbackComponent` con `error_description` en la URL.
  - Bloqueo de acceso y ejecución de `signOutAndRedirect()` si un Administrador/Vigilante intenta ingresar vía Google.
* **Solución recomendada para el siguiente sprint:**
  Crear suites de pruebas con mocks de `SupabaseClient` y `Router` simulando:
  1. Login exitoso con rol `residente` -> redirige a `/dashboard/residente`.
  2. Login exitoso con rol `administrador` -> dispara `signOutAndRedirect` con warning.
  3. Callback con cancelación del usuario (`error_description`).

---

## 🎯 Plan de Acción Sugerido para el Próximo Issue / Sprint

| Tarea | Esfuerzo Estimado | Impacto |
|---|---|---|
| **Silenciar / resolver warning de SweetAlert2 en `angular.json`** | 10 mins | Limpieza de consola en CI/CD |
| **Crear tests unitarios de `AuthCallbackComponent`** | 45 mins | Prevención de regresiones |
| **Unificar `role` vs `rol` en `AuthUser` y componentes** | 30 mins | Consistencia de código |
| **Definir DTO estricto de usuario y eliminar `any` en `AuthService`** | 1 hora | Robustez y tipado estricto |
