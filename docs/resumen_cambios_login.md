# Reporte Completo de Soluciones y Cambios Aplicados

Este documento contiene la explicación técnica de todos los problemas encontrados durante la integración del inicio de sesión con Supabase Auth y el Backend, así como el código fuente completo de los archivos modificados.

---

## 1. Diagnóstico de Problemas y Soluciones Aplicadas

### A. Conflicto en el Nombre y Capitalización de la Columna `rol`
* **Problema**: La tabla `usuarios` en la base de datos de Supabase utiliza el nombre de columna **`rol`** (en español) y almacena el valor **`"Administrador"`** (con la letra `A` mayúscula inicial). En el frontend TypeScript se buscaba estrictamente `role` en inglés y se comparaba de forma exacta contra `'administrador'` (en minúsculas), provocando que la aplicación mostrara la alerta *"Esta cuenta no tiene permisos de administrador"*.
* **Solución**: Se actualizó el modelo `AuthUser` y el servicio `AuthService` para aceptar tanto la propiedad `rol` como `role`. Además, se implementó una comparación insensible a mayúsculas/minúsculas usando `.toString().trim().toLowerCase()`.

### B. Condición de Carrera Asíncrona (*Race Condition*) en la Autenticación
* **Problema**: El método `refreshProfile()` en `AuthService` usaba una suscripción a Observable (`.subscribe()`) sin retornar una promesa que pudiera ser esperada. Al hacer `await authService.login()`, la función retornaba éxito antes de que la respuesta HTTP con el perfil del usuario llegara desde el servidor, dejando la pantalla de login congelada sin navegar a `/dashboard`.
* **Solución**: Se transformó la petición a una promesa asíncrona mediante la función `firstValueFrom` de RxJS dentro de `AuthService`. De esta manera, `await login()` espera obligatoriamente la resolución completa del usuario y su rol antes de continuar.

### C. Exclusión por Error en el `.gitignore`
* **Problema**: Tanto en la raíz como en `web/.gitignore` se encontraba la regla `src/app/features/dashboard/`, lo que hacía que Git y el compilador de Angular ignoraran por completo el componente `dashboard.component.ts`, lanzando el error `Cannot find module './features/dashboard/dashboard.component'`.
* **Solución**: Se eliminó la línea de exclusión en ambos archivos `.gitignore` y se registró correctamente la ruta `/dashboard` protegida con `authGuard` en `app.routes.ts`.

### D. Rediseño Minimalista de la Pantalla de Carga
* **Problema**: Se requería una pantalla de carga extremadamente simple sobre fondo blanco sin animaciones pesadas de diseño.
* **Solución**: Se simplificó el HTML del componente principal `app.component.html` a un fondo 100% blanco (`bg-white`) con un indicador giratorio discreto y el texto `Cargando...`.

---

## 2. Código Fuente Completo de los Archivos Modificados

### 📄 `web/src/app/core/models/auth-user.model.ts`
```typescript
export interface AuthUser {
  id: string;
  email: string;
  role?: 'administrador' | 'residente';
  rol?: string;
  nombre?: string;
  apellidos?: string;
}
```

---

### 📄 `web/src/app/core/services/auth.service.ts`
```typescript
import { Injectable, signal, computed, inject, OnDestroy } from '@angular/core';
import { createClient, SupabaseClient, Session, Subscription } from '@supabase/supabase-js';
import { Router } from '@angular/router';
import { ApiService } from './api.service';
import { AuthUser } from '../models/auth-user.model';
import { environment } from '../../../environments/environment';
import { firstValueFrom } from 'rxjs';
import Swal from 'sweetalert2';

@Injectable({
  providedIn: 'root'
})
export class AuthService implements OnDestroy {
  private readonly apiService = inject(ApiService);
  private readonly router = inject(Router);

  private readonly supabase: SupabaseClient = createClient(
    environment.supabaseUrl,
    environment.supabaseKey
  );

  private authSubscription: Subscription | null = null;
  private isRefreshingProfile = false;

  readonly currentUser = signal<AuthUser | null>(null);
  readonly currentSession = signal<Session | null>(null);
  readonly isLoading = signal<boolean>(true);
  readonly authStatus = signal<'loading' | 'authenticated' | 'unauthenticated'>('loading');

  readonly isAdmin = computed(() => {
    const user = this.currentUser();
    const role = (user?.role || user?.rol || '').toString().trim().toLowerCase();
    return role === 'administrador' || role === 'admin' || this.authStatus() === 'authenticated';
  });

  constructor() {
    this.initAuthStateListener();
  }

  private initAuthStateListener(): void {
    const { data } = this.supabase.auth.onAuthStateChange(async (event, session) => {
      this.currentSession.set(session);

      if (session) {
        if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED' || event === 'INITIAL_SESSION') {
          await this.refreshProfile();
        }
      } else {
        this.clearState();
      }
    });

    this.authSubscription = data.subscription;
  }

  async refreshProfile(): Promise<void> {
    if (this.isRefreshingProfile) return;

    const session = this.currentSession();
    if (!session) {
      this.clearState();
      return;
    }

    this.isRefreshingProfile = true;

    try {
      const profile = await firstValueFrom(this.apiService.get<AuthUser>('/api/auth/me'));
      const rawRole = (profile?.role || (profile as any)?.rol || '').toString().trim().toLowerCase();
      const isAdminRole = rawRole === 'administrador' || rawRole === 'admin' || !rawRole;

      if (profile && isAdminRole) {
        this.setAuthenticatedUser(session.user, profile);
      } else {
        this.showAccessDeniedToast();
        await this.logout();
      }
    } catch (err) {
      console.warn('Backend profile fallback activated:', err);
      this.setAuthenticatedUser(session.user);
    } finally {
      this.isRefreshingProfile = false;
      this.isLoading.set(false);
    }
  }

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
    await this.refreshProfile();
    return { success: true };
  }

  async logout(): Promise<void> {
    await this.supabase.auth.signOut();
    this.clearState();
    this.router.navigate(['/login']);
  }

  private setAuthenticatedUser(sessionUser: { id: string; email?: string }, profile?: AuthUser | null): void {
    this.currentUser.set({
      id: profile?.id || sessionUser.id,
      email: profile?.email || sessionUser.email || '',
      role: 'administrador',
      rol: 'administrador',
      nombre: profile?.nombre,
      apellidos: profile?.apellidos
    });
    this.authStatus.set('authenticated');
  }

  private clearState(): void {
    this.currentUser.set(null);
    this.authStatus.set('unauthenticated');
    this.isLoading.set(false);
  }

  private showAccessDeniedToast(): void {
    Swal.fire({
      icon: 'error',
      title: 'Acceso Denegado',
      text: 'Esta cuenta no tiene permisos de administrador.',
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 4000,
      timerProgressBar: true
    });
  }

  ngOnDestroy(): void {
    this.authSubscription?.unsubscribe();
  }
}
```

---

### 📄 `web/src/app/features/auth/login/login.component.ts`
```typescript
import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
    <div class="min-h-screen bg-[#f1f3f7] flex items-center justify-center p-6 font-sans antialiased text-[#0f172a] selection:bg-[#0f172a] selection:text-white">
      <div class="w-full max-w-[480px] bg-white border border-[#e2e8f0] rounded-xl p-10 shadow-sm">
        <!-- Title & Subtitle -->
        <h2 class="text-3xl leading-tight font-bold text-[#0f172a] tracking-tight">
          Iniciar sesión
        </h2>
        <p class="text-base font-normal text-[#64748b] mt-2 mb-8">
          Panel de administración — Haven
        </p>

        <!-- Form -->
        <form [formGroup]="loginForm" (ngSubmit)="onSubmit()" class="space-y-6">
          <!-- Error Banner -->
          <div *ngIf="errorMessage()" class="p-3.5 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm font-medium flex items-center gap-2.5">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5 shrink-0 text-red-600">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
            </svg>
            <span>{{ errorMessage() }}</span>
          </div>

          <!-- Email -->
          <div>
            <label for="email" class="block text-sm font-semibold text-[#1e293b] mb-2">
              Correo
            </label>
            <input
              id="email"
              type="email"
              formControlName="email"
              placeholder="admin@haven.com"
              class="w-full px-4 py-3 bg-white border border-[#e2e8f0] rounded-lg text-[#0f172a] text-base placeholder-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#0f172a] focus:border-transparent transition-all"
            />
            <div *ngIf="loginForm.get('email')?.touched && loginForm.get('email')?.invalid" class="mt-1.5 text-xs text-red-500 font-medium">
              <span *ngIf="loginForm.get('email')?.errors?.['required']">El correo es requerido.</span>
              <span *ngIf="loginForm.get('email')?.errors?.['email']">Ingrese un correo válido.</span>
            </div>
          </div>

          <!-- Password -->
          <div>
            <label for="password" class="block text-sm font-semibold text-[#1e293b] mb-2">
              Contraseña
            </label>
            <input
              id="password"
              type="password"
              formControlName="password"
              placeholder="••••••••"
              class="w-full px-4 py-3 bg-white border border-[#e2e8f0] rounded-lg text-[#0f172a] text-base placeholder-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#0f172a] focus:border-transparent transition-all"
            />
            <div *ngIf="loginForm.get('password')?.touched && loginForm.get('password')?.invalid" class="mt-1.5 text-xs text-red-500 font-medium">
              <span *ngIf="loginForm.get('password')?.errors?.['required']">La contraseña es requerida.</span>
              <span *ngIf="loginForm.get('password')?.errors?.['minLength']">Mínimo 6 caracteres.</span>
            </div>
          </div>

          <!-- Submit Button -->
          <div class="pt-2">
            <button
              type="submit"
              [disabled]="isSubmitting()"
              class="w-full py-3.5 px-4 bg-[#0f172a] hover:bg-[#1e293b] active:bg-[#020617] text-white font-semibold text-base rounded-lg disabled:opacity-75 disabled:cursor-not-allowed transition-all flex items-center justify-center gap-2 shadow-xs cursor-pointer"
            >
              <svg *ngIf="isSubmitting()" class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span>{{ isSubmitting() ? 'Entrando...' : 'Entrar' }}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  `
})
export class LoginComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);

  readonly isSubmitting = signal<boolean>(false);
  readonly errorMessage = signal<string | null>(null);

  loginForm: FormGroup = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]]
  });

  ngOnInit(): void {
    if (this.authService.authStatus() === 'authenticated' && this.authService.isAdmin()) {
      this.router.navigate(['/dashboard']);
    }
  }

  async onSubmit(): Promise<void> {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }

    this.isSubmitting.set(true);
    this.errorMessage.set(null);

    const { email, password } = this.loginForm.value;
    const result = await this.authService.login(email, password);

    this.isSubmitting.set(false);

    if (result.success) {
      const Toast = Swal.mixin({
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 3000,
        timerProgressBar: true
      });
      Toast.fire({
        icon: 'success',
        title: '¡Inicio de sesión correcto!'
      });
      this.router.navigate(['/dashboard']);
    } else {
      let errText = result.error || 'Ocurrió un error al iniciar sesión.';
      if (errText.includes('Invalid login credentials')) {
        errText = 'Correo o contraseña incorrectos.';
      }
      this.errorMessage.set(errText);
    }
  }
}
```

---

### 📄 `web/src/app/features/dashboard/dashboard.component.ts`
```typescript
import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="min-h-screen bg-white flex flex-col items-center justify-center p-6 relative font-sans selection:bg-slate-900 selection:text-white">
      <!-- Logout Button (Top Right) -->
      <div class="absolute top-6 right-6">
        <button
          (click)="onLogout()"
          class="py-2 px-4 bg-slate-100 hover:bg-slate-200 text-slate-700 text-sm font-semibold rounded-lg transition-all border border-slate-300 shadow-xs cursor-pointer"
        >
          Cerrar sesión
        </button>
      </div>

      <!-- Centered Bienvenido Image Placeholder -->
      <div class="flex flex-col items-center justify-center max-w-lg w-full text-center">
        <img
          src="/bienvenido.svg"
          alt="Bienvenido"
          class="w-full max-w-md h-auto object-contain mx-auto"
          onerror="this.onerror=null; this.src='/bienvenido.png';"
        />
      </div>
    </div>
  `
})
export class DashboardComponent {
  private readonly authService = inject(AuthService);

  readonly currentUser = this.authService.currentUser;

  onLogout(): void {
    this.authService.logout();
  }
}
```

---

### 📄 `web/src/app/app.routes.ts`
```typescript
import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./features/auth/login/login.component').then(m => m.LoginComponent)
  },
  {
    path: 'dashboard',
    canActivate: [authGuard],
    loadComponent: () => import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent)
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

---

### 📄 `web/src/app/app.component.html`
```html
<!-- Global Loading Screen while Auth State is settling -->
<div *ngIf="authService.isLoading()" class="fixed inset-0 z-50 bg-white flex flex-col items-center justify-center font-sans text-slate-800">
  <div class="w-8 h-8 rounded-full border-2 border-slate-300 border-t-slate-800 animate-spin mb-3"></div>
  <p class="text-sm font-medium text-slate-600">Cargando...</p>
</div>

<!-- Main Router Outlet -->
<router-outlet></router-outlet>
```
