import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import Swal from 'sweetalert2';
import { ViviendasService } from '../../../core/services/viviendas.service';
import { Vivienda } from '../../../core/models/vivienda.model';
import { ViviendasDetalleComponent } from '../viviendas-detalle/viviendas-detalle.component';

@Component({
  selector: 'app-viviendas-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, DatePipe, ViviendasDetalleComponent],
  template: `
    <div class="min-h-screen bg-[#f8fafc] text-slate-900 font-sans antialiased relative selection:bg-slate-900 selection:text-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">

        <!-- Top Navigation -->
        <div class="flex items-center justify-between mb-6">
          <a
            [routerLink]="['/dashboard/admin']"
            class="inline-flex items-center gap-2 text-xs font-semibold text-slate-500 hover:text-slate-900 transition-colors py-1.5 px-2.5 rounded-lg hover:bg-slate-100"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Volver al Panel
          </a>
        </div>

        <!-- Header Card -->
        <div class="bg-white border border-slate-200/80 rounded-2xl p-6 sm:p-8 shadow-xs mb-8">
          <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
            <div>
              <div class="flex items-center gap-3">
                <h1 class="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
                  Directorio de Viviendas
                </h1>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-slate-100 text-slate-700 border border-slate-200">
                  {{ viviendas().length }} {{ viviendas().length === 1 ? 'vivienda' : 'viviendas' }}
                </span>
              </div>
              <p class="text-sm text-slate-500 mt-1.5">
                Consulta, registra y administra las viviendas del condominio.
              </p>
            </div>

            <div class="flex items-center gap-3 shrink-0">
              <button
                (click)="cargarViviendas()"
                [disabled]="isLoading()"
                title="Actualizar datos"
                class="p-2.5 bg-slate-50 hover:bg-slate-100 active:bg-slate-200 border border-slate-200 text-slate-600 rounded-xl transition-all shadow-2xs cursor-pointer disabled:opacity-50"
              >
                <svg
                  [class.animate-spin]="isLoading()"
                  xmlns="http://www.w3.org/2000/svg"
                  class="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
              </button>

              <button
                (click)="abrirModalCrear()"
                class="inline-flex items-center gap-2 px-4 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-sm font-semibold shadow-xs hover:shadow transition-all cursor-pointer"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
                <span>Nueva Vivienda</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Loading State -->
        <div *ngIf="isLoading() && viviendas().length === 0" class="flex flex-col items-center justify-center py-24 gap-3 bg-white rounded-2xl border border-slate-200 shadow-xs">
          <div class="w-10 h-10 border-3 border-slate-200 border-t-slate-900 rounded-full animate-spin"></div>
          <p class="text-sm font-semibold text-slate-600">Sincronizando viviendas...</p>
        </div>

        <!-- Error State -->
        <div
          *ngIf="!isLoading() && errorMessage()"
          class="p-6 rounded-2xl bg-red-50/80 border border-red-200 text-red-800 flex items-center justify-between shadow-xs mb-8"
        >
          <div class="flex items-center gap-3">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-6 h-6 shrink-0 text-red-600">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
            </svg>
            <div>
              <p class="text-sm font-bold text-red-900">Error de conexión</p>
              <p class="text-xs text-red-700 mt-0.5">{{ errorMessage() }}</p>
            </div>
          </div>
          <button
            (click)="cargarViviendas()"
            class="px-4 py-2 bg-red-100 hover:bg-red-200 text-red-900 font-semibold text-xs rounded-lg transition-colors cursor-pointer"
          >
            Reintentar
          </button>
        </div>

        <!-- Empty State -->
        <div
          *ngIf="!isLoading() && !errorMessage() && viviendas().length === 0"
          class="bg-white border border-slate-200/80 rounded-2xl shadow-xs flex flex-col items-center justify-center py-20 px-4 text-center"
        >
          <div class="w-16 h-16 rounded-2xl bg-blue-50 border border-blue-100 flex items-center justify-center mb-4 text-blue-600">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
          </div>
          <h3 class="text-lg font-bold text-slate-900">No hay viviendas registradas</h3>
          <p class="text-sm text-slate-500 max-w-sm mt-1">
            Comienza dando de alta la primera vivienda del condominio.
          </p>
          <button
            (click)="abrirModalCrear()"
            class="mt-6 inline-flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-semibold shadow-xs transition-all cursor-pointer"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Dar de alta vivienda
          </button>
        </div>

        <!-- Table View (Mobile Parity UI) -->
        <div
          *ngIf="!isLoading() && !errorMessage() && viviendas().length > 0"
          class="bg-white border border-slate-200/80 rounded-2xl shadow-xs overflow-hidden"
        >
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100">
              <thead>
                <tr class="bg-slate-50/80">
                  <th class="px-6 py-4 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Vivienda
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Tipo
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Fecha de Alta
                  </th>
                  <th class="px-6 py-4 text-right text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Acciones
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 bg-white">
                <tr
                  *ngFor="let v of viviendas()"
                  (click)="abrirDetalle(v)"
                  class="group hover:bg-blue-50/40 transition-colors cursor-pointer"
                >
                  <!-- Numero Casa / Avatar -->
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <div class="flex items-center gap-3.5">
                      <!-- Badge circular idéntico al de Mobile (CircleAvatar #EFF6FF / #3B82F6) -->
                      <div class="w-10 h-10 rounded-full bg-[#eff6ff] text-[#3b82f6] flex items-center justify-center shadow-2xs ring-1 ring-blue-100 group-hover:scale-105 transition-transform">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                        </svg>
                      </div>
                      <div>
                        <span class="text-sm font-bold text-slate-900 group-hover:text-blue-600 transition-colors">
                          {{ v.numeroCasa }}
                        </span>
                      </div>
                    </div>
                  </td>

                  <!-- Tipo -->
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <span class="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">
                      {{ v.tipo || 'Sin especificar' }}
                    </span>
                  </td>

                  <!-- Fecha de Alta -->
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <div class="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-500 bg-slate-100/80 px-2.5 py-1 rounded-md">
                      <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      <span>{{ v.creadoEn ? (v.creadoEn | date:'dd/MM/yyyy') : '—' }}</span>
                    </div>
                  </td>

                  <!-- Acciones (Ver Detalle, Editar y Eliminar) -->
                  <td class="px-6 py-4.5 whitespace-nowrap text-right text-sm">
                    <div class="inline-flex items-center gap-1.5">
                      <!-- Ver Detalle (Issue #50) -->
                      <button
                        (click)="$event.stopPropagation(); abrirDetalle(v)"
                        title="Ver detalle de vivienda y residentes"
                        class="p-2 text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded-lg transition-colors cursor-pointer"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                      </button>

                      <!-- Editar (Lapicito) -->
                      <button
                        (click)="$event.stopPropagation(); abrirModalEditar(v)"
                        title="Editar vivienda"
                        class="p-2 text-slate-500 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-colors cursor-pointer"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                        </svg>
                      </button>

                      <!-- Borrar (Cesto) -->
                      <button
                        (click)="$event.stopPropagation(); confirmarEliminar(v)"
                        title="Eliminar vivienda"
                        class="p-2 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-lg transition-colors cursor-pointer"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

      </div>

      <!-- Modal de Creación / Edición (Inspirado en Mobile AlertDialog) -->
      <div
        *ngIf="showModal()"
        class="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-150"
      >
        <div
          class="bg-white rounded-2xl shadow-xl border border-slate-200 w-full max-w-md overflow-hidden animate-in zoom-in-95 duration-150"
          (click)="$event.stopPropagation()"
        >
          <!-- Header del Modal -->
          <div class="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-9 h-9 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                </svg>
              </div>
              <div>
                <h3 class="text-lg font-bold text-slate-900">
                  {{ isEditing() ? 'Editar Vivienda' : 'Nueva Vivienda' }}
                </h3>
                <p class="text-xs text-slate-500">
                  {{ isEditing() ? 'Actualiza los datos del inmueble' : 'Captura el número y tipo de vivienda' }}
                </p>
              </div>
            </div>
            <button
              (click)="cerrarModal()"
              class="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Formulario -->
          <form (ngSubmit)="guardarVivienda()" class="p-6 space-y-4">
            <!-- Mensaje de error local -->
            <div
              *ngIf="formError()"
              class="p-3 bg-red-50 border border-red-200 text-red-700 text-xs rounded-xl flex items-center gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 shrink-0" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
              </svg>
              <span>{{ formError() }}</span>
            </div>

            <!-- Campo: Número de Casa -->
            <div>
              <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">
                Número de Casa o Depto <span class="text-red-500">*</span>
              </label>
              <input
                type="text"
                name="numeroCasa"
                [(ngModel)]="formNumeroCasa"
                required
                maxlength="50"
                placeholder="ej. Casa 14, Depto 302..."
                class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition-all"
              />
            </div>

            <!-- Campo: Tipo de Vivienda -->
            <div>
              <div class="flex items-center justify-between mb-1.5">
                <label class="block text-xs font-bold text-slate-700 uppercase tracking-wider">
                  Tipo de Vivienda <span class="text-slate-400 font-normal lowercase">(opcional)</span>
                </label>
              </div>

              <!-- Quick Chips -->
              <div class="flex flex-wrap gap-1.5 mb-2">
                <button
                  type="button"
                  *ngFor="let t of ['Casa', 'Departamento', 'Penthouse', 'Townhouse']"
                  (click)="formTipo = t"
                  [class.bg-blue-50]="formTipo === t"
                  [class.border-blue-200]="formTipo === t"
                  [class.text-blue-700]="formTipo === t"
                  class="px-2.5 py-1 text-xs font-medium rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  {{ t }}
                </button>
              </div>

              <input
                type="text"
                name="tipo"
                [(ngModel)]="formTipo"
                maxlength="20"
                placeholder="ej. Casa, Departamento..."
                class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:bg-white focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition-all"
              />
            </div>

            <!-- Footer con Botones -->
            <div class="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
              <button
                type="button"
                (click)="cerrarModal()"
                [disabled]="isSaving()"
                class="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-xl transition-colors cursor-pointer disabled:opacity-50"
              >
                Cancelar
              </button>

              <button
                type="submit"
                [disabled]="isSaving() || !formNumeroCasa.trim()"
                class="inline-flex items-center gap-2 px-5 py-2 bg-slate-900 hover:bg-slate-800 active:bg-black text-white text-sm font-semibold rounded-xl shadow-xs transition-all cursor-pointer disabled:opacity-50"
              >
                <div *ngIf="isSaving()" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                <span>{{ isSaving() ? 'Guardando...' : (isEditing() ? 'Actualizar' : 'Guardar') }}</span>
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Slide-over Drawer Detalle Vivienda (Issue #50 & #87) -->
      <app-viviendas-detalle
        [vivienda]="viviendaSeleccionada()"
        [isOpen]="isDetalleOpen()"
        (close)="cerrarDetalle()"
        (viviendaUpdated)="cargarViviendas()"
      />

    </div>
  `
})
export class ViviendasListComponent implements OnInit {
  private readonly viviendasService = inject(ViviendasService);

  readonly viviendas = signal<Vivienda[]>([]);
  readonly isLoading = signal<boolean>(true);
  readonly errorMessage = signal<string | null>(null);

  // Modal State
  readonly showModal = signal<boolean>(false);
  readonly isEditing = signal<boolean>(false);
  readonly editingId = signal<number | null>(null);
  readonly isSaving = signal<boolean>(false);
  readonly formError = signal<string | null>(null);

  // Drawer Detalle State (Issue #50 & #87)
  readonly viviendaSeleccionada = signal<Vivienda | null>(null);
  readonly isDetalleOpen = signal<boolean>(false);

  formNumeroCasa: string = '';
  formTipo: string = '';

  async ngOnInit(): Promise<void> {
    await this.cargarViviendas();
  }

  async cargarViviendas(): Promise<void> {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    try {
      const data = await this.viviendasService.listar();
      this.viviendas.set(data || []);
    } catch {
      this.errorMessage.set('No fue posible cargar la lista de viviendas desde el servidor.');
    } finally {
      this.isLoading.set(false);
    }
  }

  abrirDetalle(vivienda: Vivienda): void {
    this.viviendaSeleccionada.set(vivienda);
    this.isDetalleOpen.set(true);
  }

  cerrarDetalle(): void {
    this.isDetalleOpen.set(false);
  }

  abrirModalCrear(): void {
    this.isEditing.set(false);
    this.editingId.set(null);
    this.formNumeroCasa = '';
    this.formTipo = '';
    this.formError.set(null);
    this.showModal.set(true);
  }

  abrirModalEditar(vivienda: Vivienda): void {
    this.isEditing.set(true);
    this.editingId.set(vivienda.id);
    this.formNumeroCasa = vivienda.numeroCasa;
    this.formTipo = vivienda.tipo || '';
    this.formError.set(null);
    this.showModal.set(true);
  }

  cerrarModal(): void {
    if (this.isSaving()) return;
    this.showModal.set(false);
  }

  async guardarVivienda(): Promise<void> {
    const numeroCasa = this.formNumeroCasa.trim();
    if (!numeroCasa) {
      this.formError.set('El número de casa es obligatorio.');
      return;
    }

    this.isSaving.set(true);
    this.formError.set(null);

    const payload = {
      numeroCasa,
      tipo: this.formTipo.trim() || null
    };

    try {
      if (this.isEditing() && this.editingId()) {
        await this.viviendasService.actualizar(this.editingId()!, payload);
        Swal.fire({
          icon: 'success',
          title: 'Vivienda actualizada',
          text: `La vivienda "${numeroCasa}" se actualizó correctamente.`,
          timer: 2000,
          showConfirmButton: false
        });
      } else {
        await this.viviendasService.crear(payload);
        Swal.fire({
          icon: 'success',
          title: 'Vivienda registrada',
          text: `La vivienda "${numeroCasa}" ha sido registrada con éxito.`,
          timer: 2000,
          showConfirmButton: false
        });
      }

      this.showModal.set(false);
      await this.cargarViviendas();
    } catch (err: any) {
      const errorMsg = err?.error?.error || err?.message || 'Error al guardar la vivienda.';
      if (errorMsg.includes('Ya existe una vivienda')) {
        this.formError.set('Ya existe una vivienda registrada con ese número de casa.');
      } else {
        this.formError.set(errorMsg);
      }
    } finally {
      this.isSaving.set(false);
    }
  }

  async confirmarEliminar(vivienda: Vivienda): Promise<void> {
    const result = await Swal.fire({
      title: '¿Eliminar vivienda?',
      text: `Se dará de baja la vivienda "${vivienda.numeroCasa}". Esta acción no se puede deshacer.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#dc2626',
      cancelButtonColor: '#64748b',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    });

    if (!result.isConfirmed) return;

    try {
      await this.viviendasService.eliminar(vivienda.id);
      Swal.fire({
        icon: 'success',
        title: 'Vivienda eliminada',
        text: `La vivienda "${vivienda.numeroCasa}" fue dada de baja correctamente.`,
        timer: 2000,
        showConfirmButton: false
      });
      await this.cargarViviendas();
    } catch (err: any) {
      const errorMsg = err?.error?.error || 'No fue posible eliminar la vivienda.';
      Swal.fire({
        icon: 'error',
        title: 'Error al eliminar',
        text: errorMsg
      });
    }
  }
}
