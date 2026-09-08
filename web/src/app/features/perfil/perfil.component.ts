import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-perfil',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  template: `
    <div class="min-h-screen bg-[#F7F7F7] text-[#0f172a] font-sans antialiased p-4 sm:p-6 lg:p-10">
      <div class="max-w-2xl mx-auto">

        <!-- Botón volver al panel (Oculto en Onboarding para evitar saltos) -->
        <button
          *ngIf="!isOnboarding()"
          type="button"
          (click)="volverAlDashboard()"
          [disabled]="guardando()"
          class="inline-flex items-center gap-1.5 text-sm font-medium text-slate-500 hover:text-slate-800 disabled:opacity-50 disabled:cursor-not-allowed transition-colors mb-6 cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          Volver al panel
        </button>

        <!-- Banner Corporativo de Onboarding (Sin emojis) -->
        <div
          *ngIf="isOnboarding()"
          class="mb-6 p-5 rounded-2xl bg-[#0f172a] text-white shadow-md flex items-start gap-4 border border-slate-800 animate-in fade-in duration-200"
        >
          <div class="w-10 h-10 rounded-xl bg-blue-600/20 border border-blue-500/30 flex items-center justify-center shrink-0 mt-0.5 text-blue-400">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <div class="flex-1">
            <h2 class="text-base font-bold text-white tracking-tight">Registro de información de contacto</h2>
            <p class="text-xs sm:text-sm text-slate-300 mt-1 leading-relaxed">
              Para habilitar tu acceso al condominio y permitir que la administración vincule tu vivienda, es indispensable registrar tu nombre completo y número telefónico a 10 dígitos.
            </p>
          </div>
        </div>

        <!-- Tarjeta de Perfil -->
        <div class="bg-white border border-slate-200 rounded-2xl shadow-xs overflow-hidden">

          <!-- Cabecera con Avatar -->
          <div class="p-6 sm:p-8 border-b border-slate-100 flex items-center gap-4">
            <div
              class="w-16 h-16 rounded-full flex items-center justify-center font-bold text-xl shrink-0 border-2 border-white shadow-xs"
              [ngClass]="avatarClasses"
            >
              {{ iniciales }}
            </div>
            <div>
              <h1 class="text-xl sm:text-2xl font-bold text-slate-900">
                {{ user()?.nombre || 'Usuario' }} {{ user()?.apellidos || '' }}
              </h1>
              <span class="inline-block mt-1 text-xs font-semibold px-2 py-0.5 rounded-full bg-slate-100 text-slate-700 border border-slate-200">
                {{ user()?.role || user()?.rol || 'Residente' }}
              </span>
            </div>
          </div>

          <!-- Banner de Error si falla la actualización -->
          <div
            *ngIf="errorMessage()"
            role="alert"
            class="mx-6 sm:mx-8 mt-6 p-4 rounded-xl bg-red-50/90 border border-red-200 text-red-700 text-sm font-medium flex items-start gap-3 animate-in fade-in duration-150"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-red-500 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span class="flex-1">{{ errorMessage() }}</span>
          </div>

          <!-- Modo Lectura (Oculto en onboarding) -->
          <div *ngIf="!editMode() && !isOnboarding()" class="p-6 sm:p-8">
            <dl class="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div>
                <dt class="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">Correo</dt>
                <dd class="text-sm text-slate-800 break-all">{{ user()?.email }}</dd>
              </div>
              <div>
                <dt class="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">Teléfono</dt>
                <dd class="text-sm text-slate-800">{{ user()?.telefono || 'No registrado' }}</dd>
              </div>
              <div>
                <dt class="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">Rol</dt>
                <dd class="text-sm text-slate-800">{{ user()?.role || user()?.rol }}</dd>
              </div>
              <div>
                <dt class="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">Miembro desde</dt>
                <dd class="text-sm text-slate-800">{{ (user()?.creadoEn | date:'longDate') || 'No disponible' }}</dd>
              </div>
            </dl>

            <button
              type="button"
              (click)="entrarModoEdicion()"
              class="mt-8 py-2.5 px-5 bg-[#111C99] hover:bg-[#0d1577] text-white text-sm font-semibold rounded-lg transition-colors shadow-xs cursor-pointer focus-visible:ring-2 focus-visible:ring-[#111C99] focus-visible:ring-offset-2"
            >
              Editar perfil
            </button>
          </div>

          <!-- Modo Edición con Formulario -->
          <form *ngIf="editMode()" [formGroup]="perfilForm" (ngSubmit)="onSubmit()" class="p-6 sm:p-8">
            <fieldset [disabled]="guardando()" class="space-y-5">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label for="nombre" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                    Nombre <span class="text-red-500">*</span>
                  </label>
                  <input
                    id="nombre"
                    type="text"
                    formControlName="nombre"
                    placeholder="Tu nombre oficial"
                    class="w-full px-3.5 py-2.5 bg-slate-50/50 hover:bg-white focus:bg-white border border-slate-200 rounded-lg text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-[#111C99]/10 focus:border-[#111C99] transition-all disabled:opacity-60 disabled:bg-slate-100"
                  />
                  <div *ngIf="perfilForm.get('nombre')?.touched && perfilForm.get('nombre')?.invalid" class="mt-1 text-xs text-red-500 font-medium">
                    El nombre es requerido.
                  </div>
                </div>

                <div>
                  <label for="apellidos" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                    Apellidos <span class="text-red-500">*</span>
                  </label>
                  <input
                    id="apellidos"
                    type="text"
                    formControlName="apellidos"
                    placeholder="Tus apellidos oficiales"
                    class="w-full px-3.5 py-2.5 bg-slate-50/50 hover:bg-white focus:bg-white border border-slate-200 rounded-lg text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-[#111C99]/10 focus:border-[#111C99] transition-all disabled:opacity-60 disabled:bg-slate-100"
                  />
                  <div *ngIf="perfilForm.get('apellidos')?.touched && perfilForm.get('apellidos')?.invalid" class="mt-1 text-xs text-red-500 font-medium">
                    Los apellidos son requeridos.
                  </div>
                </div>
              </div>

              <div>
                <label for="telefono" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                  Teléfono (10 dígitos) <span *ngIf="isOnboarding()" class="text-red-500">*</span>
                </label>
                <input
                  id="telefono"
                  type="tel"
                  maxlength="10"
                  formControlName="telefono"
                  placeholder="Ej. 4421234567"
                  class="w-full px-3.5 py-2.5 bg-slate-50/50 hover:bg-white focus:bg-white border border-slate-200 rounded-lg text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-[#111C99]/10 focus:border-[#111C99] transition-all disabled:opacity-60 disabled:bg-slate-100"
                />
                <div *ngIf="perfilForm.get('telefono')?.touched && perfilForm.get('telefono')?.invalid" class="mt-1 text-xs text-red-500 font-medium">
                  El teléfono es requerido y debe contener 10 dígitos numéricos.
                </div>
              </div>

              <div class="flex items-center gap-3 pt-2">
                <button
                  type="submit"
                  [disabled]="guardando()"
                  class="inline-flex items-center justify-center gap-2 py-2.5 px-6 bg-[#111C99] hover:bg-[#0d1577] disabled:opacity-60 disabled:cursor-not-allowed text-white text-sm font-semibold rounded-lg transition-colors shadow-xs cursor-pointer focus-visible:ring-2 focus-visible:ring-[#111C99] focus-visible:ring-offset-2"
                >
                  <svg *ngIf="guardando()" class="animate-spin -ml-1 mr-1 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span>{{ guardando() ? 'Guardando...' : (isOnboarding() ? 'Completar registro' : 'Guardar cambios') }}</span>
                </button>

                <!-- Botón Cancelar (Solo en modo edición normal) -->
                <button
                  *ngIf="!isOnboarding()"
                  type="button"
                  (click)="cancelarEdicion()"
                  [disabled]="guardando()"
                  class="py-2.5 px-5 bg-slate-100 hover:bg-slate-200 disabled:opacity-60 disabled:cursor-not-allowed text-slate-700 text-sm font-semibold rounded-lg transition-colors border border-slate-300 cursor-pointer focus-visible:ring-2 focus-visible:ring-slate-400"
                >
                  Cancelar
                </button>
              </div>
            </fieldset>
          </form>

        </div>
      </div>
    </div>
  `
})
export class PerfilComponent implements OnInit {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder);

  readonly user = this.authService.currentUser;
  readonly editMode = signal(false);
  readonly guardando = signal(false);
  readonly errorMessage = signal<string | null>(null);
  readonly isOnboarding = signal(false);

  perfilForm: FormGroup = this.fb.group({
    nombre: ['', Validators.required],
    apellidos: ['', Validators.required],
    telefono: ['']
  });

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      const isParamOnboarding = params['onboarding'] === 'true' || params['onboarding'] === '1';
      const isIncomplete = this.authService.isProfileIncomplete();

      if (isParamOnboarding || isIncomplete) {
        this.isOnboarding.set(true);
        this.perfilForm.get('telefono')?.setValidators([
          Validators.required,
          Validators.pattern('^[0-9]{10}$')
        ]);
        this.entrarModoEdicion();
      } else {
        this.resetForm();
      }
    });
  }

  get iniciales(): string {
    const inicialNombre = this.user()?.nombre?.trim()?.charAt(0) ?? '';
    const inicialApellido = this.user()?.apellidos?.trim()?.charAt(0) ?? '';
    const combinadas = `${inicialNombre}${inicialApellido}`.toUpperCase();
    if (combinadas) return combinadas;
    return (this.user()?.email?.trim()?.charAt(0) ?? '?').toUpperCase();
  }

  get avatarClasses(): string {
    const rol = (this.user()?.role || this.user()?.rol || '').toLowerCase();
    if (rol.includes('admin')) return 'bg-indigo-100 text-indigo-700';
    if (rol.includes('vigilan')) return 'bg-amber-100 text-amber-800';
    return 'bg-emerald-100 text-emerald-700';
  }

  volverAlDashboard(): void {
    if (this.guardando() || this.isOnboarding()) return;
    this.router.navigate([this.authService.getDashboardRoute()]);
  }

  entrarModoEdicion(): void {
    this.resetForm();
    this.errorMessage.set(null);
    this.editMode.set(true);
  }

  cancelarEdicion(): void {
    if (this.guardando() || this.isOnboarding()) return;
    this.editMode.set(false);
    this.errorMessage.set(null);
  }

  private resetForm(): void {
    const u = this.user();
    const rawNombre = u?.nombre?.trim() ?? '';
    const cleanedNombre = rawNombre.toLowerCase() === 'sin nombre' ? '' : rawNombre;

    this.perfilForm.reset({
      nombre: cleanedNombre,
      apellidos: u?.apellidos ?? '',
      telefono: u?.telefono ?? ''
    });
  }

  async onSubmit(): Promise<void> {
    if (this.perfilForm.invalid) {
      this.perfilForm.markAllAsTouched();
      return;
    }

    this.guardando.set(true);
    this.errorMessage.set(null);

    try {
      const { nombre, apellidos, telefono } = this.perfilForm.value;
      const resultado = await this.authService.actualizarPerfil({
        nombre: (nombre || '').trim(),
        apellidos: (apellidos || '').trim(),
        telefono: (telefono || '').trim() || undefined
      });

      if (resultado.success) {
        if (this.isOnboarding()) {
          Swal.fire({
            icon: 'success',
            title: 'Registro completado',
            text: 'Tus datos fueron guardados correctamente.',
            toast: true,
            position: 'top-end',
            showConfirmButton: false,
            timer: 2000,
            timerProgressBar: true
          });
          this.router.navigate([this.authService.getDashboardRoute()]);
          return;
        }

        this.editMode.set(false);
        Swal.fire({
          icon: 'success',
          title: 'Perfil actualizado',
          toast: true,
          position: 'top-end',
          showConfirmButton: false,
          timer: 2500,
          timerProgressBar: true
        });
      } else {
        this.errorMessage.set(resultado.error || 'No se pudo actualizar el perfil.');
      }
    } catch (err: any) {
      this.errorMessage.set(err?.message || 'Error inesperado al guardar los cambios.');
    } finally {
      this.guardando.set(false);
    }
  }
}
