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

