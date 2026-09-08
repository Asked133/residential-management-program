import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { ViviendasService } from '../../../core/services/viviendas.service';
import { ResidentesService } from '../../../core/services/residentes.service';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink, DatePipe],
  template: `
    <div class="p-6 sm:p-8 lg:p-10 max-w-7xl mx-auto space-y-8">
      
      <!-- Welcome Hero Section -->
      <div class="bg-white border border-slate-200 rounded-2xl p-6 sm:p-8 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-50 border border-indigo-200 text-xs font-semibold text-indigo-700 mb-3">
            <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            Centro de Control Haven
          </div>
          <h1 class="text-2xl sm:text-3xl font-bold text-slate-900 tracking-tight">
            Hola, {{ currentUser()?.nombre || 'Administrador' }}
          </h1>
          <p class="text-sm text-slate-500 mt-1">
            Resumen operativo y estado general del condominio residencial.
          </p>
        </div>

        <div class="flex items-center gap-3">
          <div class="text-right hidden sm:block">
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Fecha</p>
            <p class="text-xs font-medium text-slate-700 font-mono mt-0.5">{{ today | date:'EEEE, dd MMMM yyyy' }}</p>
          </div>
          <div class="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center text-slate-600 border border-slate-200 shrink-0">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
        </div>
      </div>

      <!-- KPI Metrics Grid (4 Live Stat Cards) -->
      <div>
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-sm font-bold text-slate-900 uppercase tracking-wider">
            Indicadores Clave
          </h2>
          <button
            type="button"
            (click)="cargarMetricas()"
            [disabled]="loading()"
            class="text-xs font-medium text-slate-500 hover:text-slate-900 flex items-center gap-1.5 transition-colors cursor-pointer"
            title="Recargar métricas"
          >
            <svg [class.animate-spin]="loading()" class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            <span>Actualizar</span>
          </button>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
          
          <!-- KPI 1: Total Viviendas -->
          <div class="bg-white border border-slate-200 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:border-slate-300 transition-all">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Viviendas</span>
              <div class="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center border border-blue-100">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                </svg>
              </div>
            </div>
            <div class="mt-4">
              <p class="text-3xl font-extrabold text-slate-900 tracking-tight">
                {{ loading() ? '—' : totalViviendas() }}
              </p>
              <p class="text-xs text-slate-500 mt-1">Inmuebles dados de alta</p>
            </div>
            <div class="mt-4 pt-3 border-t border-slate-100">
              <a routerLink="/dashboard/admin/viviendas" class="text-xs font-bold text-[#111C99] hover:underline flex items-center gap-1">
                Ver catálogo completo →
              </a>
            </div>
          </div>

          <!-- KPI 2: Total Residentes -->
          <div class="bg-white border border-slate-200 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:border-slate-300 transition-all">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Padrón</span>
              <div class="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-700 flex items-center justify-center border border-indigo-100">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
            </div>
            <div class="mt-4">
              <p class="text-3xl font-extrabold text-slate-900 tracking-tight">
                {{ loading() ? '—' : totalResidentes() }}
              </p>
              <p class="text-xs text-slate-500 mt-1">Residentes registrados</p>
            </div>
            <div class="mt-4 pt-3 border-t border-slate-100">
              <a routerLink="/dashboard/admin/residentes" class="text-xs font-bold text-[#111C99] hover:underline flex items-center gap-1">
                Ver directorio de residentes →
              </a>
            </div>
          </div>

          <!-- KPI 3: Ocupación Habitacional -->
          <div class="bg-white border border-slate-200 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:border-slate-300 transition-all">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Ocupación</span>
              <div class="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center border border-emerald-100">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
            </div>
            <div class="mt-4">
              <div class="flex items-baseline justify-between">
                <p class="text-3xl font-extrabold text-slate-900 tracking-tight">
                  {{ loading() ? '—' : (porcentajeOcupacion() + '%') }}
                </p>
                <span class="text-xs text-emerald-700 font-semibold">
                  {{ viviendasAsignadas() }} / {{ totalViviendas() }} viv.
                </span>
              </div>
              <!-- Progress Bar -->
              <div class="w-full h-2 bg-slate-100 rounded-full mt-2 overflow-hidden">
                <div
                  class="h-full bg-emerald-500 rounded-full transition-all duration-500"
                  [style.width.%]="porcentajeOcupacion()"
                ></div>
              </div>
            </div>
            <div class="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
              <span>{{ viviendasDisponibles() }} {{ viviendasDisponibles() === 1 ? 'vivienda libre' : 'viviendas libres' }}</span>
              <span class="font-medium text-emerald-700">{{ viviendasAsignadas() }} asignada{{ viviendasAsignadas() === 1 ? '' : 's' }}</span>
            </div>
          </div>

          <!-- KPI 4: Estado del Sistema -->
          <div class="bg-white border border-slate-200 rounded-2xl p-5 shadow-xs flex flex-col justify-between hover:border-slate-300 transition-all">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">Sistema</span>
              <div class="w-9 h-9 rounded-xl bg-purple-50 text-purple-700 flex items-center justify-center border border-purple-100">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
            </div>
            <div class="mt-4">
              <div class="flex items-center gap-2">
                <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
                <p class="text-xl font-bold text-slate-900">En línea</p>
              </div>
              <p class="text-xs text-slate-500 mt-1 font-mono">Supabase Auth & API v1</p>
            </div>
            <div class="mt-4 pt-3 border-t border-slate-100">
              <span class="text-xs text-emerald-700 font-semibold flex items-center gap-1">
                ✓ Sincronización continua
              </span>
            </div>
          </div>

        </div>
      </div>

      <!-- Quick Access & Management Modules (Spacious Cards) -->
      <div>
        <h2 class="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4">
          Módulos de Gestión
        </h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          <!-- Card: Gestión de Residentes -->
          <div class="bg-white border border-slate-200 rounded-2xl p-6 sm:p-7 shadow-xs hover:border-slate-300 transition-all flex flex-col justify-between">
            <div>
              <div class="w-12 h-12 rounded-2xl bg-blue-50 text-[#111C99] flex items-center justify-center border border-blue-100 mb-4 shadow-2xs">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
              <h3 class="text-lg font-bold text-slate-900">Directorio de Residentes</h3>
              <p class="text-xs sm:text-sm text-slate-500 mt-1 leading-relaxed">
                Administra el padrón de habitantes, credenciales de acceso seguro, correos y vinculación con sus respectivos domicilios.
              </p>
            </div>

            <div class="mt-6 pt-5 border-t border-slate-100 flex items-center justify-between flex-wrap gap-3">
              <a
                routerLink="/dashboard/admin/residentes"
                class="inline-flex items-center gap-2 px-4 py-2 bg-[#111C99] hover:bg-[#0d1577] text-white text-xs font-semibold rounded-xl transition-all shadow-xs cursor-pointer"
              >
                Abrir Directorio
              </a>
              <a
                routerLink="/dashboard/admin/residentes/nuevo"
                class="inline-flex items-center gap-1.5 px-3 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold rounded-xl transition-colors cursor-pointer"
              >
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
                Nuevo Residente
              </a>
            </div>
          </div>

          <!-- Card: Gestión de Viviendas -->
          <div class="bg-white border border-slate-200 rounded-2xl p-6 sm:p-7 shadow-xs hover:border-slate-300 transition-all flex flex-col justify-between">
            <div>
              <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-700 flex items-center justify-center border border-emerald-100 mb-4 shadow-2xs">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                </svg>
              </div>
              <h3 class="text-lg font-bold text-slate-900">Directorio de Viviendas</h3>
              <p class="text-xs sm:text-sm text-slate-500 mt-1 leading-relaxed">
                Control de inmuebles, tipos de unidad (casas, departamentos), asignación de habitantes y disponibilidad habitacional.
              </p>
            </div>

            <div class="mt-6 pt-5 border-t border-slate-100 flex items-center justify-between flex-wrap gap-3">
              <a
                routerLink="/dashboard/admin/viviendas"
                class="inline-flex items-center gap-2 px-4 py-2 bg-[#111C99] hover:bg-[#0d1577] text-white text-xs font-semibold rounded-xl transition-all shadow-xs cursor-pointer"
              >
                Abrir Catálogo
              </a>
              <span class="text-xs font-medium text-slate-400">
                Haven Residencial
              </span>
            </div>
          </div>

        </div>
      </div>

    </div>
  `
})
export class AdminDashboardComponent implements OnInit {
  private readonly authService = inject(AuthService);
  private readonly viviendasService = inject(ViviendasService);
  private readonly residentesService = inject(ResidentesService);

  readonly currentUser = this.authService.currentUser;
  readonly today = new Date();

  readonly totalViviendas = signal<number>(0);
  readonly totalResidentes = signal<number>(0);
  readonly viviendasAsignadas = signal<number>(0);
  readonly loading = signal<boolean>(true);

  porcentajeOcupacion(): number {
    const total = this.totalViviendas();
    const asignadas = this.viviendasAsignadas();
    if (total === 0) return 0;
    return Math.min(Math.round((asignadas / total) * 100), 100);
  }

  viviendasDisponibles(): number {
    const total = this.totalViviendas();
    const asignadas = this.viviendasAsignadas();
    return Math.max(total - asignadas, 0);
  }

  async ngOnInit(): Promise<void> {
    await this.cargarMetricas();
  }

  async cargarMetricas(): Promise<void> {
    this.loading.set(true);
    try {
      const [viviendas, residentes] = await Promise.all([
        this.viviendasService.listar().catch(() => []),
        this.residentesService.listar().catch(() => [])
      ]);
      this.totalViviendas.set(viviendas.length);
      this.totalResidentes.set(residentes.length);

      if (viviendas.length > 0) {
        const asignaciones = await Promise.all(
          viviendas.map(v => this.viviendasService.obtenerResidentesVivienda(v.id).catch(() => []))
        );
        const asignadasCount = asignaciones.filter(list => Array.isArray(list) && list.length > 0).length;
        this.viviendasAsignadas.set(asignadasCount);
      } else {
        this.viviendasAsignadas.set(0);
      }
    } catch (err) {
      console.error('Error al cargar métricas del dashboard:', err);
    } finally {
      this.loading.set(false);
    }
  }
}
