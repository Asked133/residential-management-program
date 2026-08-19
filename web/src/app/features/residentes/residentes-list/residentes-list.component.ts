import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ResidentesService } from '../../../core/services/residentes.service';
import { Residente } from '../../../core/models/residente.model';

@Component({
  selector: 'app-residentes-list',
  standalone: true,
  imports: [CommonModule, RouterLink, DatePipe],
  template: `
    <div class="min-h-screen bg-[#f8fafc] text-[#0f172a] font-sans antialiased">

      <!-- Page Header -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">

        <!-- Back link -->
        <a
          [routerLink]="['/dashboard/admin']"
          class="inline-flex items-center gap-1.5 text-sm font-medium text-slate-500 hover:text-slate-800 transition-colors mb-6"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          Volver
        </a>

        <!-- Title row -->
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-2xl sm:text-3xl font-bold text-slate-900">Residentes</h1>
          <a
            [routerLink]="['/dashboard/admin/residentes/nuevo']"
            class="inline-flex items-center gap-2 py-2.5 px-4 bg-[#0f172a] hover:bg-[#1e293b] active:bg-[#020617] text-white font-semibold text-sm rounded-lg transition-all shadow-xs cursor-pointer"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Agregar residente
          </a>
        </div>

        <!-- Loading state -->
        <div *ngIf="isLoading()" class="flex flex-col items-center justify-center py-24 gap-3">
          <svg class="animate-spin h-8 w-8 text-slate-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p class="text-sm font-medium text-slate-500">Cargando residentes...</p>
        </div>

        <!-- Error state -->
        <div
          *ngIf="!isLoading() && errorMessage()"
          class="p-4 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm font-medium flex items-center gap-3"
        >
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5 shrink-0 text-red-600">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
          </svg>
          <span>{{ errorMessage() }}</span>
        </div>

        <!-- Empty state -->
        <div
          *ngIf="!isLoading() && !errorMessage() && residentes().length === 0"
          class="bg-white border border-slate-200 rounded-xl shadow-xs flex flex-col items-center justify-center py-20 gap-4"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="w-12 h-12 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <p class="text-slate-500 font-medium text-sm">No hay residentes registrados aún.</p>
          <a
            [routerLink]="['/dashboard/admin/residentes/nuevo']"
            class="inline-flex items-center gap-2 py-2.5 px-4 bg-[#0f172a] hover:bg-[#1e293b] active:bg-[#020617] text-white font-semibold text-sm rounded-lg transition-all shadow-xs cursor-pointer"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Agregar residente
          </a>
        </div>

        <!-- Table -->
        <div
          *ngIf="!isLoading() && !errorMessage() && residentes().length > 0"
          class="bg-white border border-slate-200 rounded-xl shadow-xs overflow-hidden"
        >
          <table class="min-w-full divide-y divide-slate-200">
            <thead>
              <tr class="bg-slate-50">
                <th class="px-6 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Nombre completo
                </th>
                <th class="px-6 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Email
                </th>
                <th class="px-6 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Teléfono
                </th>
                <th class="px-6 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Rol
                </th>
                <th class="px-6 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Fecha de alta
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr *ngFor="let r of residentes()" class="hover:bg-slate-50 transition-colors">
                <td class="px-6 py-4 text-sm font-semibold text-slate-900 whitespace-nowrap">
                  {{ r.nombre }} {{ r.apellidos }}
                </td>
                <td class="px-6 py-4 text-sm text-slate-600 whitespace-nowrap">
                  {{ r.email }}
                </td>
                <td class="px-6 py-4 text-sm text-slate-600 whitespace-nowrap">
                  {{ r.telefono || '—' }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class="bg-indigo-50 text-indigo-700 border border-indigo-200 rounded-full px-2 py-0.5 text-xs font-semibold">
                    {{ capitalize(r.rol) }}
                  </span>
                </td>
                <td class="px-6 py-4 text-sm text-slate-500 whitespace-nowrap">
                  {{ r.creadoEn ? (r.creadoEn | date:'dd/MM/yyyy') : '—' }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

      </div>
    </div>
  `
})
export class ResidentesListComponent implements OnInit {
  private readonly residentesService = inject(ResidentesService);

  readonly residentes = signal<Residente[]>([]);
  readonly isLoading = signal<boolean>(true);
  readonly errorMessage = signal<string | null>(null);

  async ngOnInit(): Promise<void> {
    try {
      const data = await this.residentesService.listar();
      this.residentes.set(data);
    } catch {
      this.errorMessage.set('No fue posible cargar la lista de residentes.');
    } finally {
      this.isLoading.set(false);
    }
  }

  capitalize(value: string): string {
    if (!value) return '';
    return value.charAt(0).toUpperCase() + value.slice(1).toLowerCase();
  }
}
