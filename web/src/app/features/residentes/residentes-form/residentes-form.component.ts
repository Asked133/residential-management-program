import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ResidentesService } from '../../../core/services/residentes.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-residentes-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  template: `
    <div class="min-h-screen bg-[#f1f3f7] flex items-center justify-center p-6 font-sans antialiased text-[#0f172a] selection:bg-[#0f172a] selection:text-white">
      <div class="w-full max-w-[480px] bg-white border border-[#e2e8f0] rounded-xl p-10 shadow-sm">

        <!-- Title & Subtitle -->
        <h2 class="text-3xl leading-tight font-bold text-[#0f172a] tracking-tight">
          Registrar residente
        </h2>
        <p class="text-base font-normal text-[#64748b] mt-2 mb-8">
          Alta de cuenta — Haven
        </p>

        <!-- Form -->
        <form [formGroup]="residenteForm" (ngSubmit)="onSubmit()" class="space-y-6">

          <!-- Error Banner -->
          <div *ngIf="errorMessage()" class="p-3.5 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm font-medium flex items-center gap-2.5">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5 shrink-0 text-red-600">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
            </svg>
            <span>{{ errorMessage() }}</span>
          </div>

          <!-- Nombre -->
          <div>
            <label for="nombre" class="block text-sm font-semibold text-[#1e293b] mb-2">
              Nombre
            </label>
            <input
              id="nombre"
              type="text"
              formControlName="nombre"
              placeholder="Juan"
              class="w-full px-4 py-3 bg-white border border-[#e2e8f0] rounded-lg text-[#0f172a] text-base placeholder-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#0f172a] focus:border-transparent transition-all"
            />
            <div *ngIf="residenteForm.get('nombre')?.touched && residenteForm.get('nombre')?.invalid" class="mt-1.5 text-xs text-red-500 font-medium">
              <span *ngIf="residenteForm.get('nombre')?.errors?.['required']">El nombre es requerido.</span>
            </div>
          </div>

          <!-- Apellidos -->
          <div>
            <label for="apellidos" class="block text-sm font-semibold text-[#1e293b] mb-2">
              Apellidos
            </label>
            <input
              id="apellidos"
              type="text"
              formControlName="apellidos"
              placeholder="Pérez García"
              class="w-full px-4 py-3 bg-white border border-[#e2e8f0] rounded-lg text-[#0f172a] text-base placeholder-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#0f172a] focus:border-transparent transition-all"
            />
            <div *ngIf="residenteForm.get('apellidos')?.touched && residenteForm.get('apellidos')?.invalid" class="mt-1.5 text-xs text-red-500 font-medium">
              <span *ngIf="residenteForm.get('apellidos')?.errors?.['required']">Los apellidos son requeridos.</span>
            </div>
          </div>

          <!-- Teléfono -->
          <div>
            <label for="telefono" class="block text-sm font-semibold text-[#1e293b] mb-2">
              Teléfono
            </label>
            <input
              id="telefono"
              type="tel"
              formControlName="telefono"
              placeholder="4421234567"
              class="w-full px-4 py-3 bg-white border border-[#e2e8f0] rounded-lg text-[#0f172a] text-base placeholder-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#0f172a] focus:border-transparent transition-all"
            />
            <div *ngIf="residenteForm.get('telefono')?.touched && residenteForm.get('telefono')?.invalid" class="mt-1.5 text-xs text-red-500 font-medium">
              <span *ngIf="residenteForm.get('telefono')?.errors?.['required']">El teléfono es requerido.</span>
            </div>
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
              placeholder="residente@haven.com"
              class="w-full px-4 py-3 bg-white border border-[#e2e8f0] rounded-lg text-[#0f172a] text-base placeholder-[#94a3b8] focus:outline-none focus:ring-2 focus:ring-[#0f172a] focus:border-transparent transition-all"
            />
            <div *ngIf="residenteForm.get('email')?.touched && residenteForm.get('email')?.invalid" class="mt-1.5 text-xs text-red-500 font-medium">
              <span *ngIf="residenteForm.get('email')?.errors?.['required']">El correo es requerido.</span>
              <span *ngIf="residenteForm.get('email')?.errors?.['email']">Ingrese un correo válido.</span>
            </div>
          </div>

          <!-- Actions -->
          <div class="pt-2 flex items-center gap-3">
            <!-- Submit -->
            <button
              type="submit"
              [disabled]="isSubmitting()"
              class="flex-1 py-3.5 px-4 bg-[#0f172a] hover:bg-[#1e293b] active:bg-[#020617] text-white font-semibold text-base rounded-lg disabled:opacity-75 disabled:cursor-not-allowed transition-all flex items-center justify-center gap-2 shadow-xs cursor-pointer"
            >
              <svg *ngIf="isSubmitting()" class="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span>{{ isSubmitting() ? 'Registrando...' : 'Registrar residente' }}</span>
            </button>

            <!-- Cancel -->
            <a
              [routerLink]="['/dashboard/admin/residentes']"
              class="py-3.5 px-4 bg-slate-100 hover:bg-slate-200 text-slate-700 text-base font-semibold rounded-lg transition-colors border border-slate-300 shadow-xs cursor-pointer flex items-center justify-center"
            >
              Cancelar
            </a>
          </div>

        </form>
      </div>
    </div>
  `
})
export class ResidentesFormComponent {
  private readonly fb = inject(FormBuilder);
  private readonly residentesService = inject(ResidentesService);
  private readonly router = inject(Router);

  readonly isSubmitting = signal<boolean>(false);
  readonly errorMessage = signal<string | null>(null);

  residenteForm: FormGroup = this.fb.group({
    nombre: ['', [Validators.required]],
    apellidos: ['', [Validators.required]],
    telefono: ['', [Validators.required]],
    email: ['', [Validators.required, Validators.email]]
  });

  async onSubmit(): Promise<void> {
    if (this.residenteForm.invalid) {
      this.residenteForm.markAllAsTouched();
      return;
    }

    this.isSubmitting.set(true);
    this.errorMessage.set(null);

    const payload = { ...this.residenteForm.value, rol: 'residente' };

    try {
      await this.residentesService.crear(payload);
      const Toast = Swal.mixin({
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 3000,
        timerProgressBar: true
      });
      Toast.fire({
        icon: 'success',
        title: 'Residente registrado correctamente.'
      });
      this.router.navigate(['/dashboard/admin/residentes']);
    } catch {
      this.isSubmitting.set(false);
      this.errorMessage.set('No fue posible registrar al residente. Intenta de nuevo.');
    }
  }
}
