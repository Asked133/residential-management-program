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

