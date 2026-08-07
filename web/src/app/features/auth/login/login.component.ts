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
