import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ViviendasService } from '../../../core/services/viviendas.service';
import { Vivienda } from '../../../core/models/vivienda.model';

@Component({
  selector: 'app-viviendas-list',
  standalone: true,
  imports: [CommonModule, RouterLink, DatePipe],
  template: `
    <div class="min-h-screen bg-[#f8fafc] text-slate-900 font-sans antialiased relative selection:bg-slate-900 selection:text-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">

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
                Consulta las viviendas registradas en el condominio.
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
            </div>
          </div>
        </div>

        <div *ngIf="isLoading() && viviendas().length === 0" class="flex flex-col items-center justify-center py-24 gap-3 bg-white rounded-2xl border border-slate-200 shadow-xs">
          <div class="w-10 h-10 border-3 border-slate-200 border-t-slate-900 rounded-full animate-spin"></div>
          <p class="text-sm font-semibold text-slate-600">Sincronizando viviendas...</p>
        </div>

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

        <div
          *ngIf="!isLoading() && !errorMessage() && viviendas().length === 0"
          class="bg-white border border-slate-200/80 rounded-2xl shadow-xs flex flex-col items-center justify-center py-20 px-4 text-center"
        >
          <div class="w-16 h-16 rounded-2xl bg-indigo-50 border border-indigo-100 flex items-center justify-center mb-4 text-indigo-600">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
          </div>
          <h3 class="text-lg font-bold text-slate-900">No hay viviendas registradas</h3>
          <p class="text-sm text-slate-500 max-w-sm mt-1">
            Cuando se registren viviendas en el condominio, aparecerán aquí.
          </p>
        </div>

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
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 bg-white">
                <tr
                  *ngFor="let v of viviendas()"
                  class="group hover:bg-slate-50/60 transition-colors"
                >
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <div class="flex items-center gap-3.5">
                      <div class="w-10 h-10 rounded-full bg-slate-900 text-white flex items-center justify-center shadow-2xs ring-2 ring-slate-100 group-hover:scale-105 transition-transform">
                        <svg xmlns="http://www.w3.org/2000/svg" class="w-4.5 h-4.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                        </svg>
                      </div>
                      <div class="text-sm font-bold text-slate-900 group-hover:text-indigo-600 transition-colors">
                        {{ v.numeroCasa }}
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <span class="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">
                      {{ v.tipo || 'Sin especificar' }}
                    </span>
                  </td>
                  <td class="px-6 py-4.5 whitespace-nowrap">
                    <div class="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-500 bg-slate-100/80 px-2.5 py-1 rounded-md">
                      <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      <span>{{ v.creadoEn ? (v.creadoEn | date:'dd/MM/yyyy') : '—' }}</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </div>
  `
})
export class ViviendasListComponent implements OnInit {
  private readonly viviendasService = inject(ViviendasService);

  readonly viviendas = signal<Vivienda[]>([]);
  readonly isLoading = signal<boolean>(true);
  readonly errorMessage = signal<string | null>(null);

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
}
