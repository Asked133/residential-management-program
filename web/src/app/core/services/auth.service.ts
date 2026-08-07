import { Injectable, signal, computed, inject, OnDestroy } from '@angular/core';
import { createClient, SupabaseClient, Session, Subscription } from '@supabase/supabase-js';
import { Router } from '@angular/router';
import { ApiService } from './api.service';
import { AuthUser } from '../models/auth-user.model';
import { environment } from '../../../environments/environment';
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

  readonly isAdmin = computed(() => this.currentUser()?.role === 'administrador');

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
        this.currentUser.set(null);
        this.authStatus.set('unauthenticated');
        this.isLoading.set(false);
      }
    });

    this.authSubscription = data.subscription;
  }

  async refreshProfile(): Promise<void> {
    if (this.isRefreshingProfile) {
      return;
    }

    const session = this.currentSession();
    if (!session) {
      this.authStatus.set('unauthenticated');
      this.isLoading.set(false);
      return;
    }

    this.isRefreshingProfile = true;

    try {
      this.apiService.get<AuthUser>('/api/auth/me').subscribe({
        next: (profile) => {
          this.isRefreshingProfile = false;

          if (profile && profile.role === 'administrador') {
            this.currentUser.set(profile);
            this.authStatus.set('authenticated');
          } else {
            // Non-admin user -> Auto logout & error toast
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
            this.logout();
          }
          this.isLoading.set(false);
        },
        error: (err) => {
          this.isRefreshingProfile = false;
          console.error('Error fetching user profile from /api/auth/me:', err);
          this.authStatus.set('unauthenticated');
          this.isLoading.set(false);
        }
      });
    } catch (err) {
      this.isRefreshingProfile = false;
      this.authStatus.set('unauthenticated');
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
    this.currentUser.set(null);
    this.currentSession.set(null);
    this.authStatus.set('unauthenticated');
    this.isLoading.set(false);
    this.router.navigate(['/login']);
  }

  ngOnDestroy(): void {
    if (this.authSubscription) {
      this.authSubscription.unsubscribe();
    }
  }
}
