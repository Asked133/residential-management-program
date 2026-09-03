import { Injectable, signal, computed, inject, OnDestroy } from '@angular/core';
import { createClient, SupabaseClient, Session, Subscription } from '@supabase/supabase-js';
import { Router } from '@angular/router';
import { ApiService } from './api.service';
import { AuthUser } from '../models/auth-user.model';
import { environment } from '../../../environments/environment';
import { firstValueFrom, timeout } from 'rxjs';
import Swal from 'sweetalert2';

@Injectable({
  providedIn: 'root'
})
export class AuthService implements OnDestroy {
  private readonly apiService = inject(ApiService);
  private readonly router = inject(Router);

  private readonly supabase: SupabaseClient = createClient(
    environment.supabaseUrl,
    environment.supabaseKey,
    { auth: { flowType: 'pkce', detectSessionInUrl: true } }
  );

  private authSubscription: Subscription | null = null;
  private refreshProfilePromise: Promise<void> | null = null;

  readonly currentUser = signal<AuthUser | null>(null);
  readonly currentSession = signal<Session | null>(null);
  readonly isLoading = signal<boolean>(true);
  readonly authStatus = signal<'loading' | 'authenticated' | 'unauthenticated'>('loading');

  readonly userRole = computed<'administrador' | 'residente' | 'vigilante' | null>(() => {
    const user = this.currentUser();
    if (!user) return null;
    return this.normalizeRole(user.role || user.rol);
  });

  readonly isAdmin = computed(() => this.userRole() === 'administrador');
  readonly isResidente = computed(() => this.userRole() === 'residente');
  readonly isVigilante = computed(() => this.userRole() === 'vigilante');

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

  normalizeRole(role?: string | number | null): 'administrador' | 'residente' | 'vigilante' {
    const raw = (role ?? '').toString().trim().toLowerCase();
    if (raw === 'administrador' || raw === 'admin' || raw === 'administrator' || raw === '1') return 'administrador';
    if (raw === 'vigilante' || raw === 'guardia' || raw === 'guard' || raw === 'vigilancia' || raw === '3') return 'vigilante';
    if (raw === 'residente' || raw === 'resident' || raw === 'propietario' || raw === '2') return 'residente';
    return 'residente';
  }

  getDashboardRoute(role?: string | null): string {
    const normalized = this.normalizeRole(role ?? this.currentUser()?.role ?? this.currentUser()?.rol);
    switch (normalized) {
      case 'administrador':
        return '/dashboard/admin';
      case 'residente':
        return '/dashboard/residente';
      case 'vigilante':
        return '/dashboard/vigilante';
      default:
        return '/dashboard';
    }
  }

  navigateToDashboard(): Promise<boolean> {
    return this.router.navigate([this.getDashboardRoute()]);
  }

  async refreshProfile(): Promise<void> {
    if (this.refreshProfilePromise) {
      return this.refreshProfilePromise;
    }

    const session = this.currentSession();
    if (!session) {
      this.clearState();
      return;
    }

    this.refreshProfilePromise = this.doRefreshProfile(session);
    try {
      await this.refreshProfilePromise;
    } finally {
      this.refreshProfilePromise = null;
    }
  }

  async handleCallback(): Promise<{ success: boolean; error?: string }> {
    this.isLoading.set(true);
    try {
      // 1. Primero verificamos si Supabase (detectSessionInUrl) ya intercambió el código y creó la sesión
      let { data: { session } } = await this.supabase.auth.getSession();

      // 2. Si no hay sesión activa aún pero hay un ?code= en la URL, lo intercambiamos manualmente
      if (!session) {
        const params = new URLSearchParams(window.location.search);
        const code = params.get('code');

        if (code) {
          console.log('[AuthService] Intercambiando PKCE code por sesión manualmente...');
          const { data, error } = await this.supabase.auth.exchangeCodeForSession(code);
          if (!error && data?.session) {
            session = data.session;
          } else {
            console.warn('[AuthService] Aviso en exchangeCodeForSession (posible auto-intercambio previo):', error?.message);
            // Reintentar lectura de sesión por si el cliente interno de Supabase lo resolvió en paralelo
            const retry = await this.supabase.auth.getSession();
            session = retry.data.session;
          }
        }
      }

      if (!session) {
        this.isLoading.set(false);
        return { success: false, error: 'No se encontró sesión activa.' };
      }

      this.currentSession.set(session);

      // Limpiar parámetros de la URL (?code=...) para mantener la barra limpia
      if (window.location.search.includes('code=')) {
        window.history.replaceState(null, '', window.location.pathname);
      }

      await this.refreshProfile();

      if (this.authStatus() === 'authenticated') {
        this.isLoading.set(false);
        return { success: true };
      }

      this.isLoading.set(false);
      return { success: false, error: 'No se pudo verificar el perfil.' };
    } catch (err: any) {
      this.isLoading.set(false);
      return { success: false, error: err?.message || 'Error inesperado durante la verificación.' };
    }
  }

  private async doRefreshProfile(session: Session): Promise<void> {
    try {
      // Timeout defensivo de 2.5s: si Render demora, activamos el fallback a Supabase de inmediato
      const profile = await firstValueFrom(this.apiService.get<AuthUser>('/api/auth/me').pipe(timeout(2500)));
      console.log('[AuthService] Respuesta exitosa de /api/auth/me:', profile);
      this.setAuthenticatedUser(session.user, profile);
    } catch (err) {
      console.warn('[AuthService] Fallback activado (error o demora en /api/auth/me):', err);
      // Respaldo resiliente: Si el backend en Render falla (401/404/demora),
      // consultamos la vista vw_usuarios directamente en Supabase para obtener el rol real
      try {
        const { data: dbUser, error: dbErr } = await this.supabase
          .from('vw_usuarios')
          .select('*')
          .eq('id', session.user.id)
          .maybeSingle();

        if (dbUser && !dbErr) {
          console.log('[AuthService] Perfil obtenido directamente de Supabase (vw_usuarios):', dbUser);
          this.setAuthenticatedUser(session.user, dbUser);
          return;
        }
      } catch (dbError) {
        console.error('[AuthService] Error al consultar vw_usuarios en Supabase:', dbError);
      }
      this.setAuthenticatedUser(session.user);
    } finally {
      this.isLoading.set(false);
    }
  }

  async login(email: string, pass: string): Promise<{ success: boolean; error?: string; role?: string }> {
    this.isLoading.set(true);
    try {
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

      if (this.authStatus() === 'authenticated') {
        const targetRoute = this.getDashboardRoute();
        await this.router.navigate([targetRoute]);
        this.isLoading.set(false);
        return { success: true, role: this.userRole() || undefined };
      }

      this.isLoading.set(false);
      return { success: false, error: 'Acceso denegado.' };
    } catch (err: any) {
      this.isLoading.set(false);
      return { success: false, error: err?.message || 'Error inesperado de conexión.' };
    }
  }

  async logout(): Promise<void> {
    await this.supabase.auth.signOut();
    this.clearState();
    this.router.navigate(['/login']);
  }

  async loginWithGoogle(): Promise<{ success: boolean; error?: string }> {
    const { error } = await this.supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: `${window.location.origin}/auth/callback` }
    });
    if (error) return { success: false, error: error.message };
    return { success: true };
  }

  async register(datos: {
    email: string;
    password: string;
    nombre: string;
    apellidos: string;
    telefono: string;
  }): Promise<{ success: boolean; error?: string; requiresEmailConfirmation?: boolean }> {
    this.isLoading.set(true);
    try {
      const { data, error } = await this.supabase.auth.signUp({
        email: datos.email.trim(),
        password: datos.password,
        options: {
          data: {
            nombre: datos.nombre.trim(),
            apellidos: datos.apellidos.trim(),
            telefono: datos.telefono.trim()
          }
        }
      });

      if (error) {
        this.isLoading.set(false);
        return { success: false, error: error.message };
      }

      if (data.session) {
        this.currentSession.set(data.session);
        await this.refreshProfile();
        this.isLoading.set(false);
        return { success: true, requiresEmailConfirmation: false };
      }

      this.isLoading.set(false);
      return { success: true, requiresEmailConfirmation: true };
    } catch (err: any) {
      this.isLoading.set(false);
      return { success: false, error: err?.message || 'Error inesperado al registrar el usuario.' };
    }
  }

  async signOutAndRedirect(mensaje: string): Promise<void> {
    await this.supabase.auth.signOut();
    this.clearState();
    Swal.fire({
      icon: 'warning',
      title: 'Acceso no permitido',
      text: mensaje,
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 3500,
      timerProgressBar: true
    });
    this.router.navigate(['/login']);
  }

  async actualizarPerfil(datos: {
    nombre: string;
    apellidos: string;
    telefono?: string;
  }): Promise<{ success: boolean; error?: string }> {
    try {
      const actualizado = await firstValueFrom(
        this.apiService.patch<{ id: string; nombre: string; apellidos: string; telefono: string }>(
          '/api/auth/completar-perfil',
          datos
        )
      );

      this.currentUser.update(u =>
        u
          ? {
              ...u,
              nombre: actualizado.nombre,
              apellidos: actualizado.apellidos,
              telefono: actualizado.telefono
            }
          : u
      );

      return { success: true };
    } catch (err: any) {
      const message = err?.error?.error || err?.message || 'No se pudo actualizar el perfil.';
      return { success: false, error: message };
    }
  }

  isProfileIncomplete(): boolean {
    const user = this.currentUser();
    if (!user) return false;
    const rol = (user.role || user.rol || '').toLowerCase();
    // Aplica exclusivamente al rol residente
    if (!rol.includes('residente')) return false;

    const nombre = (user.nombre || '').trim();
    const apellidos = (user.apellidos || '').trim();
    const telefono = (user.telefono || '').trim();

    const nombreValido = nombre.length > 0 && nombre.toLowerCase() !== 'sin nombre';
    const apellidosValidos = apellidos.length > 0;
    const telefonoValido = telefono.length >= 10;

    return !nombreValido || !apellidosValidos || !telefonoValido;
  }

  private setAuthenticatedUser(
    sessionUser: { id: string; email?: string; user_metadata?: Record<string, any>; app_metadata?: Record<string, any> },
    profile?: any | null
  ): void {
    // El rol SIEMPRE debe venir del backend (/api/auth/me).
    // Soportamos 'rol', 'role', 'role_id' o 'rol_id' (1=admin, 2=residente, 3=vigilante),
    // y app_metadata del servidor de Supabase. user_metadata de cliente NO se usa para autorizar.
    const rawRole = (
      profile?.rol ??
      profile?.role ??
      profile?.rol_nombre ??
      profile?.rolNombre ??
      profile?.rol_id ??
      profile?.role_id ??
      profile?.rolId ??
      profile?.roleId ??
      sessionUser.app_metadata?.['rol'] ??
      sessionUser.app_metadata?.['role'] ??
      'Residente'
    ).toString();

    const normalized = this.normalizeRole(rawRole);
    const formattedRole = normalized.charAt(0).toUpperCase() + normalized.slice(1);

    console.log('[AuthService] Perfil resuelto:', {
      profile,
      rawRole,
      normalized,
      formattedRole
    });

    this.currentUser.set({
      id: profile?.id || sessionUser.id,
      email: profile?.email || sessionUser.email || '',
      role: formattedRole,
      rol: formattedRole,
      nombre: profile?.nombre || sessionUser.user_metadata?.['nombre'],
      apellidos: profile?.apellidos || sessionUser.user_metadata?.['apellidos'],
      telefono: profile?.telefono || sessionUser.user_metadata?.['telefono'],
      creadoEn: profile?.creadoEn ?? profile?.creado_en ?? undefined
    });
    this.authStatus.set('authenticated');
  }

  private clearState(): void {
    this.currentUser.set(null);
    this.authStatus.set('unauthenticated');
    this.isLoading.set(false);
  }

  ngOnDestroy(): void {
    this.authSubscription?.unsubscribe();
  }
}
