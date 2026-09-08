import { Component, Input, Output, EventEmitter, HostListener } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { Residente } from '../../../core/models/residente.model';
import { getInitials } from '../../../core/utils/iniciales.util';

@Component({
  selector: 'app-residentes-detalle',
  standalone: true,
  imports: [CommonModule, DatePipe],
  template: `
    <!-- Sticky Drawer Top Bar -->
    <div class="sticky top-0 z-10 bg-white/95 backdrop-blur-md px-6 py-4 border-b border-slate-100 flex items-center justify-between">
      <div class="flex items-center gap-2.5">
        <div class="w-8 h-8 rounded-lg bg-[#111C99] text-white flex items-center justify-center font-bold text-xs shadow-2xs">
          {{ getInitials(residente?.nombre, residente?.apellidos) }}
        </div>
        <span class="text-sm font-bold text-slate-900 tracking-tight">Detalle del Residente</span>
      </div>

      <!-- Close Button -->
      <button
        type="button"
        (click)="cerrar()"
        class="p-2 text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded-xl transition-all cursor-pointer focus:outline-none focus:ring-2 focus:ring-[#111C99]/20"
        aria-label="Cerrar detalle del residente"
        title="Cerrar detalle (Esc)"
      >
        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <!-- Drawer Body -->
    <div class="p-6 sm:p-8 space-y-8 flex-1 flex flex-col justify-between">
      <div class="space-y-6">
        <!-- Hero Profile -->
        <div class="flex flex-col items-center text-center">
          <div class="w-20 h-20 sm:w-24 sm:h-24 rounded-full bg-[#111C99] text-white font-bold text-2xl sm:text-3xl flex items-center justify-center shadow-md ring-4 ring-slate-100">
            {{ getInitials(residente?.nombre, residente?.apellidos) }}
          </div>
          <h2 class="text-xl sm:text-2xl font-extrabold text-slate-900 mt-4 tracking-tight">
            {{ residente?.nombre }} {{ residente?.apellidos }}
          </h2>
          <div class="mt-2">
            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
              <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
              Residente Haven
            </span>
          </div>
        </div>

        <!-- Information Card -->
        <div class="bg-white border border-slate-200/80 rounded-2xl p-5 sm:p-6 shadow-xs divide-y divide-slate-100">
          <!-- Correo Electrónico -->
          <div class="pb-4">
            <span class="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">
              Correo Electrónico
            </span>
            <div class="flex items-center gap-2.5 text-sm font-semibold text-slate-800">
              <svg class="w-4 h-4 text-[#111C99] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
              <span class="break-all">{{ residente?.email || '—' }}</span>
            </div>
          </div>

          <!-- Teléfono -->
          <div class="py-4">
            <span class="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">
              Teléfono
            </span>
            <div class="flex items-center gap-2.5 text-sm font-semibold text-slate-800">
              <svg class="w-4 h-4 text-[#111C99] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
              </svg>
              <span>{{ residente?.telefono || '—' }}</span>
            </div>
          </div>

          <!-- Fecha de Alta -->
          <div class="pt-4">
            <span class="block text-xs font-bold text-slate-400 uppercase tracking-wider mb-1.5">
              Fecha de Alta
            </span>
            <div class="flex items-center gap-2.5 text-sm font-semibold text-slate-800">
              <svg class="w-4 h-4 text-[#111C99] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span>{{ residente?.creadoEn ? (residente?.creadoEn | date:'dd/MM/yyyy') : '—' }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ID de Usuario (Soporte Admin) -->
      <div class="pt-6 border-t border-slate-100 flex items-center justify-between text-xs text-slate-400">
        <span class="font-medium">ID de referencia:</span>
        <span class="font-mono bg-slate-100 px-2 py-1 rounded-md text-slate-600 select-all">{{ residente?.id || '—' }}</span>
      </div>
    </div>
  `
})
export class ResidentesDetalleComponent {
  @Input() residente: Residente | null = null;
  @Output() cerrado = new EventEmitter<void>();

  readonly getInitials = getInitials;

  @HostListener('window:keydown.escape')
  handleEscape(): void {
    this.cerrar();
  }

  cerrar(): void {
    this.cerrado.emit();
  }
}
