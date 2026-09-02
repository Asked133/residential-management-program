import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-auth-callback',
  standalone: true,
  imports: [],
  template: `
    <div class="min-h-screen bg-[#f1f3f7] flex items-center justify-center font-sans antialiased">
      <div class="flex flex-col items-center gap-4 text-center">
        <svg class="animate-spin h-10 w-10 text-[#0f172a]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <p class="text-[#64748b] font-medium text-base">Verificando tu cuenta...</p>
      </div>
    </div>
  `
})
export class AuthCallbackComponent implements OnInit {
  private readonly authService = inject(AuthService);

  async ngOnInit(): Promise<void> {
    const params = new URLSearchParams(window.location.search);
    const errorDescription = params.get('error_description');
    if (errorDescription) {
      await this.showErrorToastAndRedirect(errorDescription);
      return;
    }

    try {
      const result = await this.authService.handleCallback();
      if (!result.success) {
        await this.showErrorToastAndRedirect(result.error || 'No se pudo completar el inicio de sesión.');
        return;
      }

      const role = this.authService.userRole();

      if (role === 'administrador' || role === 'vigilante') {
        // Staff no puede usar Google OAuth — cerrar sesión y redirigir con aviso.
        await this.authService.signOutAndRedirect(
          'El acceso con Google es exclusivo para residentes. Inicia sesión con tu correo y contraseña.'
        );
        return;
      }

      // Residente OK — redirigir a su dashboard correspondiente.
      await this.authService.navigateToDashboard();
    } catch (err: any) {
      await this.showErrorToastAndRedirect(err?.message || 'Error inesperado al verificar la cuenta.');
    }
  }

  private readonly router = inject(Router);

  private async showErrorToastAndRedirect(message: string): Promise<void> {
    const Swal = (await import('sweetalert2')).default;
    await Swal.fire({
      icon: 'error',
      title: 'Error de autenticación',
      text: message,
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 5000,
      timerProgressBar: true
    });
    await this.router.navigate(['/login']);
  }
}
