import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="min-h-screen bg-[#f8fafc] text-[#0f172a] font-sans antialiased">
      <!-- Navbar -->
      <header class="bg-white border-b border-slate-200 sticky top-0 z-30">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-9 h-9 rounded-lg bg-slate-900 text-white flex items-center justify-center font-bold text-lg">
              H
            </div>
            <div>
              <span class="font-bold text-lg tracking-tight text-slate-900">Haven</span>
              <span class="ml-2 text-xs font-semibold px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-700 border border-indigo-200">
                Administración
              </span>
            </div>
          </div>

          <div class="flex items-center gap-4">
            <div class="hidden sm:flex flex-col text-right">
              <span class="text-sm font-semibold text-slate-800">
                {{ currentUser()?.nombre || 'Administrador' }} {{ currentUser()?.apellidos || '' }}
              </span>
              <span class="text-xs text-slate-500">{{ currentUser()?.email }}</span>
            </div>
            <button
              (click)="onLogout()"
              class="py-2 px-3.5 bg-slate-100 hover:bg-slate-200 text-slate-700 text-sm font-semibold rounded-lg transition-colors border border-slate-300 shadow-xs cursor-pointer flex items-center gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
              </svg>
              <span>Cerrar sesión</span>
            </button>
          </div>
        </div>
      </header>

      <!-- Main Content -->
      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Welcome Hero -->
        <div class="bg-white border border-slate-200 rounded-xl p-6 sm:p-8 mb-8 shadow-xs">
          <h1 class="text-2xl sm:text-3xl font-bold text-slate-900">
            Panel de Administración
          </h1>
          <p class="text-slate-600 mt-2">
            Bienvenido al centro de control del condominio.
          </p>
        </div>

        <!-- Actions -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          <div class="bg-white p-6 rounded-xl border border-slate-200 shadow-xs flex items-center gap-4 hover:border-slate-300 transition-all cursor-pointer">
            <div class="w-12 h-12 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center font-bold text-xl">
              👥
            </div>
            <div>
              <p class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Gestión</p>
              <p class="text-lg font-bold text-slate-900">Registrar Residentes</p>
            </div>
          </div>
        </div>
      </main>
    </div>
  `
})
export class AdminDashboardComponent {
  private readonly authService = inject(AuthService);
  readonly currentUser = this.authService.currentUser;

  onLogout(): void {
    this.authService.logout();
  }
}
