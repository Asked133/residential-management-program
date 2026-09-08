import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive, Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { UserMenuComponent } from '../../../core/components/user-menu/user-menu.component';

@Component({
  selector: 'app-admin-layout',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive, UserMenuComponent],
  template: `
    <div class="min-h-screen bg-[#F8FAFC] text-slate-900 font-sans antialiased flex flex-col lg:flex-row">
      
      <!-- Mobile Top Bar -->
      <header class="lg:hidden bg-white border-b border-slate-200 sticky top-0 z-40 px-4 h-16 flex items-center justify-between shadow-2xs">
        <div class="flex items-center gap-3">
          <button
            type="button"
            (click)="toggleMobileMenu()"
            class="p-2 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-colors cursor-pointer"
            aria-label="Abrir menú de navegación"
          >
            <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          
          <div class="flex items-center gap-2.5">
            <img src="/haven-logo.png" alt="Haven" class="w-7 h-7 rounded-lg object-contain" />
            <span class="font-bold text-base tracking-tight text-slate-900">Haven</span>
            <span class="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-700 border border-indigo-200">
              Admin
            </span>
          </div>
        </div>

        <app-user-menu [user]="currentUser()" (logout)="onLogout()" />
      </header>

      <!-- Mobile Backdrop Overlay -->
      <div
        *ngIf="mobileMenuOpen()"
        (click)="mobileMenuOpen.set(false)"
        class="lg:hidden fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-xs transition-opacity"
        aria-hidden="true"
      ></div>

      <!-- Persistent Sidebar (Desktop & Mobile Drawer) -->
      <aside
        class="fixed inset-y-0 left-0 z-50 w-64 bg-white border-r border-slate-200 flex flex-col justify-between transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:h-screen lg:shrink-0"
        [class.translate-x-0]="mobileMenuOpen()"
        [class.-translate-x-full]="!mobileMenuOpen()"
      >
        <div>
          <!-- Sidebar Brand Header -->
          <div class="p-5 border-b border-slate-100 flex items-center justify-between">
            <div class="flex items-center gap-3">
              <img src="/haven-logo.png" alt="Haven" class="w-9 h-9 rounded-xl object-contain shadow-2xs" />
              <div>
                <span class="font-bold text-base tracking-tight text-slate-900 block leading-none">Haven</span>
                <span class="text-[11px] text-slate-400 font-medium mt-1 block">Condominio Residencial</span>
              </div>
            </div>

            <button
              type="button"
              (click)="mobileMenuOpen.set(false)"
              class="lg:hidden p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded-lg transition-colors cursor-pointer"
              aria-label="Cerrar menú"
            >
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Condominium Badge Indicator -->
          <div class="px-5 py-3 bg-slate-50/60 border-b border-slate-100 flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <span class="text-xs font-semibold text-slate-700">Haven Principal</span>
            </div>
            <span class="text-[10px] font-semibold px-2 py-0.5 rounded bg-indigo-50 text-indigo-700 border border-indigo-200">
              Administrador
            </span>
          </div>

          <!-- Navigation Links -->
          <nav class="p-3 space-y-1">
            <p class="px-3 pt-2 pb-1.5 text-[11px] font-bold text-slate-400 uppercase tracking-wider">
              Gestión General
            </p>

            <!-- Panel Principal -->
            <a
              routerLink="/dashboard/admin"
              [routerLinkActiveOptions]="{ exact: true }"
              routerLinkActive="bg-[#111C99] text-white font-semibold shadow-2xs shadow-[#111C99]/20"
              class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer group"
              (click)="mobileMenuOpen.set(false)"
            >
              <svg class="w-4 h-4 shrink-0 transition-transform group-hover:scale-105" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
              </svg>
              <span class="flex-1">Panel Principal</span>
            </a>

            <!-- Residentes -->
            <a
              routerLink="/dashboard/admin/residentes"
              [routerLinkActiveOptions]="{ exact: false }"
              routerLinkActive="bg-[#111C99] text-white font-semibold shadow-2xs shadow-[#111C99]/20"
              class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer group"
              (click)="mobileMenuOpen.set(false)"
            >
              <svg class="w-4 h-4 shrink-0 transition-transform group-hover:scale-105" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span class="flex-1">Directorio de Residentes</span>
            </a>

            <!-- Viviendas -->
            <a
              routerLink="/dashboard/admin/viviendas"
              [routerLinkActiveOptions]="{ exact: false }"
              routerLinkActive="bg-[#111C99] text-white font-semibold shadow-2xs shadow-[#111C99]/20"
              class="flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer group"
              (click)="mobileMenuOpen.set(false)"
            >
              <svg class="w-4 h-4 shrink-0 transition-transform group-hover:scale-105" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span class="flex-1">Directorio de Viviendas</span>
            </a>
          </nav>
        </div>

        <!-- Sidebar User Footer (Botón de Admin / Mi Perfil) -->
        <div class="p-3 border-t border-slate-100 bg-slate-50/40">
          <div class="flex items-center justify-between gap-2">
            <a
              routerLink="/perfil"
              (click)="mobileMenuOpen.set(false)"
              routerLinkActive="bg-indigo-50/80 border-indigo-200 text-[#111C99]"
              class="flex items-center gap-2.5 overflow-hidden flex-1 p-2 rounded-xl hover:bg-slate-100 transition-colors group cursor-pointer border border-transparent"
              title="Ver mi perfil de administrador"
            >
              <div class="w-8 h-8 rounded-full bg-[#111C99] text-white font-bold text-xs flex items-center justify-center shrink-0 shadow-2xs group-hover:scale-105 transition-transform">
                {{ userInitials }}
              </div>
              <div class="truncate">
                <p class="text-xs font-bold text-slate-900 group-hover:text-[#111C99] transition-colors truncate">
                  {{ currentUser()?.nombre || 'Administrador' }}
                </p>
                <p class="text-[11px] text-slate-500 font-mono truncate">
                  {{ currentUser()?.email }}
                </p>
              </div>
            </a>

            <button
              type="button"
              (click)="onLogout()"
              title="Cerrar sesión"
              class="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer shrink-0"
            >
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
              </svg>
            </button>
          </div>
        </div>
      </aside>

      <!-- Main Scrollable Content Area -->
      <main class="flex-1 min-w-0 lg:h-screen lg:overflow-y-auto">
        <router-outlet />
      </main>

    </div>
  `
})
export class AdminLayoutComponent {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);

  readonly currentUser = this.authService.currentUser;
  readonly mobileMenuOpen = signal<boolean>(false);

  get userInitials(): string {
    const user = this.currentUser();
    const n = user?.nombre?.trim()?.charAt(0) ?? '';
    const a = user?.apellidos?.trim()?.charAt(0) ?? '';
    return (n + a).toUpperCase() || 'AD';
  }

  toggleMobileMenu(): void {
    this.mobileMenuOpen.update(o => !o);
  }

  onLogout(): void {
    this.authService.logout();
  }
}
