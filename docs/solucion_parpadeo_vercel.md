# Análisis Técnico Completo: Solución al Parpadeo (*Flicker*) en Vercel

Este documento detalla exhaustivamente la investigación, los intentos realizados y la solución definitiva implementada para eliminar el parpadeo (*flash*) de la pantalla de login durante el proceso de autenticación y redirección en **Vercel**.

---

## 1. Descripción del Problema Visual

Al ejecutar la aplicación en el entorno de producción de **Vercel**, durante el proceso de inicio de sesión se producía la siguiente secuencia de pantallas:

1. **Usuario ingresa credenciales y presiona "Entrar"**.
2. **Aparece la pantalla global de carga** (*"Cargando..."*).
3. ⚠️ **Destello de ~100-300 ms donde volvía a mostrarse el formulario de inicio de sesión**.
4. **Finalmente cargaba la pantalla de bienvenida**.

Este comportamiento arruinaba la experiencia de usuario (UX) al dar la falsa impresión de que el inicio de sesión había fallado o se había reiniciado antes de redirigir.

---

## 2. Intentos Realizados e Investigación de Causas

### ❌ Intento 1: Navegación Asíncrona sin Espera de Promesa
* **Hipótesis inicial**: Se creyó que el método `router.navigate(['/dashboard'])` se ejecutaba después de desactivar el botón de envío (`isSubmitting.set(false)`).
* **Causa encontrada**: En Angular, la navegación de rutas es una operación asíncrona. Al apagar el spinner del botón (`isSubmitting = false`) antes de que el *Router* cambiara de componente, Angular volvía a renderizar la vista actual (`LoginComponent`) en su estado normal durante unos milisegundos mientras la navegación se completaba.
* **Resultado del intento**: Redujo ligeramente el destello en desarrollo local, pero **en Vercel el parpadeo persistía**.

---

### ❌ Intento 2: Conmutación Desincronizada del Signal `isLoading`
* **Hipótesis**: Había una alternancia no deseada del indicador de carga global.
* **Causa encontrada**: El método `refreshProfile()` en `AuthService` ejecutaba `this.isLoading.set(false)` en su bloque `finally`. Inmediatamente después, el componente `LoginComponent` volvía a activar `this.authService.isLoading.set(true)` para cubrir la navegación hacia el dashboard.
* **Secuencia de estados defectuosa**:
  1. Clic en Entrar ➔ `isLoading = true` (Pantalla de carga activada).
  2. Finaliza consulta de perfil ➔ `isLoading = false` (Pantalla de carga apagada ➔ **Formulario visible por 50 ms**).
  3. Inicio de navegación ➔ `isLoading = true` (Pantalla de carga reactivada).
* **Resultado del intento**: Este ciclo `true ➔ false ➔ true` provocaba el parpadeo blanco/formulario/blanco.

---

### ❌ Intento 3: Descarga Bajo Demanda (*Lazy Loading*) en la CDN de Vercel
* **Hipótesis**: La infraestructura distribuida de Vercel introducía latencia de red en las rutas.
* **Causa encontrada**: La ruta `/dashboard` estaba configurada con *Lazy Loading* dinámico en `app.routes.ts`:
  ```typescript
  loadComponent: () => import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent)
  ```
  Al compilar en Vercel, Angular generaba un archivo JavaScript independiente (`chunk-XFGB3E4V.js`). 
  Al hacer clic en entrar:
  1. El cliente autenticaba exitosamente en Supabase.
  2. La pantalla de carga se ocultaba.
  3. El *Router* iniciaba una **petición HTTP a la CDN de Vercel** para descargar el archivo JS del Dashboard.
  4. Mientras Vercel entregaba el archivo por la red (latencia de 200 a 500 ms dependiendo de la conexión), la pantalla activa se mantenía en la ruta anterior (`/login`).

---

## 3. Solución Definitiva Implementada

La solución definitiva requirió combinar dos estrategias fundamentales:

### A. Empaquetado Directo (*Eager Loading*) de Rutas Críticas
En [app.routes.ts](file:///c:/Users/dcgom/OneDrive/Documentos/Documentos/Universidad/7mo%20Semestre/Topico1/GithubRepo/residential-management-program/web/src/app/app.routes.ts), se eliminó la importación dinámica `loadComponent` para el módulo de dashboard y se importó directamente:

```typescript
import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { LoginComponent } from './features/auth/login/login.component';
import { DashboardComponent } from './features/dashboard/dashboard.component';

export const routes: Routes = [
  {
    path: 'login',
    component: LoginComponent
  },
  {
    path: 'dashboard',
    canActivate: [authGuard],
    component: DashboardComponent
  },
  {
    path: '',
    redirectTo: '/login',
    pathMatch: 'full'
  },
  {
    path: '**',
    redirectTo: '/login'
  }
];
```
* **Efecto**: `DashboardComponent` se empaqueta en el `main.js` inicial. La transición entre rutas ocurre en **0 milisegundos a nivel de memoria**, sin realizar ninguna petición de red adicional a la CDN de Vercel.

---

### B. Control Continuo del Estado `isLoading`
En [auth.service.ts](file:///c:/Users/dcgom/OneDrive/Documentos/Documentos/Universidad/7mo%20Semestre/Topico1/GithubRepo/residential-management-program/web/src/app/core/services/auth.service.ts), se modificó la lógica de autenticación para que el signal `isLoading` permanezca en `true` sin interrupción durante todo el proceso (autenticación + obtención de perfil + navegación):

```typescript
  async login(email: string, pass: string): Promise<{ success: boolean; error?: string }> {
    this.isLoading.set(true);
    const { data, error } = await this.supabase.auth.signInWithPassword({
      email,
      password: pass
    });

    if (error) {
      this.isLoading.set(false);
      return { success: false, error: error.message };
    }

    this.currentSession.set(data.session);
    await this.refreshProfile(true); // Parameter skipLoadingOff = true

    if (this.authStatus() === 'authenticated') {
      await this.router.navigate(['/dashboard']);
      this.isLoading.set(false);
      return { success: true };
    } else {
      this.isLoading.set(false);
      return { success: false, error: 'Acceso denegado.' };
    }
  }
```

---

## 4. Resultado Final Obtenido

Con estos cambios, la secuencia en Vercel es perfectamente fluida y libre de parpadeos:

$$\text{Formulario Login} \xrightarrow{\text{Clic Entrar}} \text{Pantalla Blanca "Cargando..."} \xrightarrow{\text{Navegación 0ms}} \text{Pantalla "Bienvenido"}$$

1. **Zero Parpadeos**: La pantalla de login no vuelve a mostrarse en ningún momento intermedio.
2. **Zero Latencia de Red**: No se descargan scripts secundarios al cambiar a la vista de bienvenida.
3. **Seguridad Preservada**: La ruta sigue totalmente protegida por `authGuard`.
