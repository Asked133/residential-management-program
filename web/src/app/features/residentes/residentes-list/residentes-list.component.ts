import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { ResidentesService } from '../../../core/services/residentes.service';
import { Residente } from '../../../core/models/residente.model';
import { ResidentesFormComponent } from '../residentes-form/residentes-form.component';
import { ResidentesDetalleComponent } from '../residentes-detalle/residentes-detalle.component';
import { getInitials } from '../../../core/utils/iniciales.util';

@Component({
  selector: 'app-residentes-list',
  standalone: true,
  imports: [CommonModule, RouterLink, DatePipe, ResidentesFormComponent, ResidentesDetalleComponent],
  template: `
    <div class="min-h-screen bg-[#F7F7F7] text-slate-900 font-sans antialiased relative selection:bg-[#111C99] selection:text-white">

      <!-- Main Container -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">

        <!-- Top Navigation / Breadcrumb -->
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

        <!-- Page Header & Action Bar -->
        <div class="bg-white border border-slate-200/80 rounded-2xl p-6 sm:p-8 shadow-xs mb-8">
          <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
            <div>
              <div class="flex items-center gap-3">
                <h1 class="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
                  Directorio de Residentes
                </h1>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold bg-slate-100 text-slate-700 border border-slate-200">
                  {{ residentes().length }} {{ residentes().length === 1 ? 'residente' : 'residentes' }}
                </span>
              </div>
              <p class="text-sm text-slate-500 mt-1.5">
                Administra las cuentas y datos de contacto de todos los habitantes de la comunidad.
              </p>
            </div>

            <!-- Action Buttons -->
            <div class="flex items-center gap-3 shrink-0">
              <!-- Refresh Button -->
              <button
                (click)="cargarResidentes()"
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

              <!-- Agregar Residente Trigger Button -->
              <button
                (click)="abrirDrawer()"
                class="inline-flex items-center gap-2 py-2.5 px-4 sm:px-5 bg-[#111C99] hover:bg-[#0c146e] active:bg-[#0a1160] text-white font-semibold text-sm rounded-xl transition-all shadow-md shadow-[#111C99]/10 hover:shadow-lg hover:-translate-y-0.5 cursor-pointer"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4" />
                </svg>
                <span>Agregar residente</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Loading State -->
        <div *ngIf="isLoading() && residentes().length === 0" class="flex flex-col items-center justify-center py-24 gap-3 bg-white rounded-2xl border border-slate-200 shadow-xs">
          <div class="w-10 h-10 border-3 border-slate-200 border-t-[#111C99] rounded-full animate-spin"></div>
          <p class="text-sm font-semibold text-slate-600">Sincronizando residentes...</p>
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
            (click)="cargarResidentes()"
            class="px-4 py-2 bg-red-100 hover:bg-red-200 text-red-900 font-semibold text-xs rounded-lg transition-colors cursor-pointer"
          >
            Reintentar
          </button>
        </div>

        <!-- Empty State (No residents at all) -->
        <div
          *ngIf="!isLoading() && !errorMessage() && residentes().length === 0"
          class="bg-white border border-slate-200/80 rounded-2xl shadow-xs flex flex-col items-center justify-center py-20 px-4 text-center"
        >
          <div class="w-16 h-16 rounded-2xl bg-indigo-50 border border-indigo-100 flex items-center justify-center mb-4 text-indigo-600">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </div>
          <h3 class="text-lg font-bold text-slate-900">No hay residentes registrados</h3>
          <p class="text-sm text-slate-500 max-w-sm mt-1 mb-6">
            Comienza a construir la comunidad de Haven dando de alta al primer residente.
          </p>
          <button
            (click)="abrirDrawer()"
            class="inline-flex items-center gap-2 py-2.5 px-5 bg-[#111C99] hover:bg-[#0c146e] text-white font-semibold text-sm rounded-xl transition-all shadow-sm cursor-pointer"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4" />
            </svg>
            Agregar primer residente
          </button>
        </div>

        <!-- Modern Residents Table -->
        <div
          *ngIf="!isLoading() && !errorMessage() && residentes().length > 0"
          class="bg-white border border-slate-200/80 rounded-2xl shadow-xs overflow-hidden"
        >
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100">
              <thead>
                <tr class="bg-slate-50/80">
                  <th class="px-6 py-4 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Residente
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Contacto
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Teléfono
                  </th>
                  <th class="px-6 py-4 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Fecha de Alta
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 bg-white">
                <tr
                  *ngFor="let r of residentes()"
                  (click)="verDetalle(r)"
                  (keydown.enter)="verDetalle(r)"
                  tabindex="0"
                  class="hover:bg-slate-50/70 transition-colors group cursor-pointer focus:outline-none focus:bg-slate-50/90 focus:ring-1 focus:ring-inset focus:ring-[#111C99]/30"
                >
                  <!-- Name & Avatar Initials -->
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <div class="flex items-center gap-3.5">
                      <div class="w-10 h-10 rounded-full bg-[#111C99] text-white font-bold text-xs flex items-center justify-center shadow-2xs ring-2 ring-slate-100 group-hover:scale-105 transition-transform">
                        {{ getInitials(r.nombre, r.apellidos) }}
                      </div>
                      <div>
                        <div class="text-sm font-bold text-slate-900 group-hover:text-indigo-600 transition-colors">
                          {{ r.nombre }} {{ r.apellidos }}
                        </div>
                        <div class="text-xs text-slate-400">
                          Residente Haven
                        </div>
                      </div>
                    </div>
                  </td>

                  <!-- Email -->
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <div class="inline-flex items-center gap-2 text-sm text-slate-600">
                      <svg class="w-4 h-4 text-slate-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                      </svg>
                      <span class="font-medium">{{ r.email }}</span>
                    </div>
                  </td>

                  <!-- Phone -->
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <div class="inline-flex items-center gap-2 text-sm text-slate-600">
                      <svg class="w-4 h-4 text-slate-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                      </svg>
                      <span>{{ r.telefono || '—' }}</span>
                    </div>
                  </td>

                  <!-- Created Date -->
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <div class="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-500 bg-slate-100/80 px-2.5 py-1 rounded-md">
                      <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      <span>{{ r.creadoEn ? (r.creadoEn | date:'dd/MM/yyyy') : '—' }}</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

      </div>

      <!-- ========================================================= -->
      <!-- SLIDE-OVER DRAWER (MEDIA PÁGINA) PARA AGREGAR RESIDENTE   -->
      <!-- ========================================================= -->

      <!-- Backdrop overlay with smooth fade -->
      <div
        *ngIf="isDrawerOpen()"
        (click)="cerrarDrawer()"
        class="fixed inset-0 z-40 bg-slate-950/40 backdrop-blur-xs transition-opacity duration-300 animate-fade-in"
      ></div>

      <!-- Slide-Over Container (Half page on desktop: w-full md:w-1/2 lg:w-[520px]) -->
      <aside
        *ngIf="isDrawerOpen()"
        class="fixed inset-y-0 right-0 z-50 w-full sm:max-w-md md:max-w-lg lg:max-w-xl bg-white shadow-2xl flex flex-col border-l border-slate-200 overflow-y-auto transform transition-transform duration-300 ease-out animate-slide-left"
      >
        <!-- Sticky Drawer Top Bar -->
        <div class="sticky top-0 z-10 bg-white/95 backdrop-blur-md px-6 py-4 border-b border-slate-100 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-lg bg-[#111C99] text-white flex items-center justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4" />
              </svg>
            </div>
            <span class="text-sm font-bold text-slate-900 tracking-tight">Haven Residents</span>
          </div>

          <!-- Close Button -->
          <button
            (click)="cerrarDrawer()"
            class="p-2 text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded-xl transition-all cursor-pointer"
            title="Cerrar panel (Esc)"
          >
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Embedded Modern Form (Media página) -->
        <app-residentes-form
          [isDrawer]="true"
          (saved)="onResidenteGuardado()"
          (cancelled)="cerrarDrawer()"
        ></app-residentes-form>
      </aside>

      <!-- ========================================================= -->
      <!-- SLIDE-OVER DRAWER (MEDIA PÁGINA) PARA DETALLE RESIDENTE   -->
      <!-- ========================================================= -->

      <!-- Backdrop overlay with smooth fade -->
      <div
        *ngIf="isDetalleOpen()"
        (click)="cerrarDetalle()"
        aria-hidden="true"
        class="fixed inset-0 z-40 bg-slate-950/40 backdrop-blur-xs transition-opacity duration-300 animate-fade-in"
      ></div>

      <!-- Slide-Over Container (Half page on desktop: w-full md:w-1/2 lg:w-[520px]) -->
      <aside
        *ngIf="isDetalleOpen()"
        role="dialog"
        aria-modal="true"
        aria-label="Detalle del residente"
        class="fixed inset-y-0 right-0 z-50 w-full sm:max-w-md md:max-w-lg lg:max-w-xl bg-white shadow-2xl flex flex-col border-l border-slate-200 overflow-y-auto transform transition-transform duration-300 ease-out animate-slide-left"
      >
        <app-residentes-detalle
          [residente]="residenteSeleccionado()"
          (cerrado)="cerrarDetalle()"
        ></app-residentes-detalle>
      </aside>

    </div>
  `
})
export class ResidentesListComponent implements OnInit {
  private readonly residentesService = inject(ResidentesService);
  private readonly route = inject(ActivatedRoute);

  readonly residentes = signal<Residente[]>([]);
  readonly isLoading = signal<boolean>(true);
  readonly errorMessage = signal<string | null>(null);
  readonly isDrawerOpen = signal<boolean>(false);
  readonly residenteSeleccionado = signal<Residente | null>(null);
  readonly isDetalleOpen = signal<boolean>(false);

  readonly getInitials = getInitials;

  async ngOnInit(): Promise<void> {
    // Si viene con query param ?nuevo=true, abre el drawer automáticamente
    this.route.queryParams.subscribe(params => {
      if (params['nuevo'] === 'true' || params['nuevo'] === '1') {
        this.isDrawerOpen.set(true);
      }
    });

    await this.cargarResidentes();
  }

  async cargarResidentes(): Promise<void> {
    this.isLoading.set(true);
    this.errorMessage.set(null);
    try {
      const data = await this.residentesService.listar();
      this.residentes.set(data || []);
    } catch {
      this.errorMessage.set('No fue posible cargar la lista de residentes desde el servidor.');
    } finally {
      this.isLoading.set(false);
    }
  }

  abrirDrawer(): void {
    this.isDrawerOpen.set(true);
  }

  cerrarDrawer(): void {
    this.isDrawerOpen.set(false);
  }

  verDetalle(r: Residente): void {
    this.residenteSeleccionado.set(r);
    this.isDetalleOpen.set(true);
  }

  cerrarDetalle(): void {
    this.isDetalleOpen.set(false);
  }

  async onResidenteGuardado(): Promise<void> {
    this.cerrarDrawer();
    // Refrescar automáticamente la lista de residentes para ver los cambios de inmediato
    await this.cargarResidentes();
  }
}
