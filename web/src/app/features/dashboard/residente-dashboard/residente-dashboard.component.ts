import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { ViviendasService } from '../../../core/services/viviendas.service';
import { Vivienda } from '../../../core/models/vivienda.model';
import { UserMenuComponent } from '../../../core/components/user-menu/user-menu.component';

@Component({
  selector: 'app-residente-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink, UserMenuComponent],
  template: `
    <div class="min-h-screen bg-[#F7F7F7] text-[#0f172a] font-sans antialiased">
      <!-- Navbar -->
      <header class="bg-white border-b border-slate-200 sticky top-0 z-30">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <img src="/haven-logo.png" alt="Haven" class="w-9 h-9 rounded-lg object-contain" />
            <div>
              <span class="font-bold text-lg tracking-tight text-slate-900">Haven</span>
              <span class="ml-2 text-xs font-semibold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                Portal Residente
              </span>
            </div>
          </div>

          <app-user-menu [user]="currentUser()" (logout)="onLogout()" />
        </div>
      </header>

      <!-- Main Content -->
      <main class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Welcome Hero -->
        <div class="bg-white border border-slate-200 rounded-xl p-6 sm:p-8 shadow-xs mb-8">
          <h1 class="text-2xl sm:text-3xl font-bold text-slate-900">
            ¡Hola, {{ currentUser()?.nombre || 'Residente' }}!
          </h1>
          <p class="text-slate-600 mt-2">
            Bienvenido a tu portal condominal.
          </p>
        </div>

        <!-- Estado de Carga -->
        <div *ngIf="isLoadingVivienda()" class="bg-white border border-slate-200 rounded-xl p-8 shadow-xs mb-8 animate-pulse">
          <div class="h-6 bg-slate-200 rounded w-1/3 mb-4"></div>
          <div class="h-24 bg-slate-100 rounded-xl"></div>
        </div>

        <!-- Caso A: Si YA tiene una o mas viviendas asignadas -->
        <div *ngIf="!isLoadingVivienda() && misViviendas().length > 0" class="bg-white border border-slate-200 rounded-xl p-6 sm:p-8 shadow-xs mb-8">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-blue-50 text-[#111C99] flex items-center justify-center shrink-0">
                <svg class="w-5 h-5 text-[#111C99]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                </svg>
              </div>
              <div>
                <h2 class="text-lg sm:text-xl font-bold text-slate-900">Mi Vivienda</h2>
                <p class="text-xs text-slate-500">Unidades residenciales asociadas a tu cuenta</p>
              </div>
            </div>
            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 self-start sm:self-auto">
              <svg class="w-3.5 h-3.5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
              </svg>
              {{ misViviendas().length === 1 ? 'Vivienda Asignada' : misViviendas().length + ' Viviendas Asignadas' }}
            </span>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div *ngFor="let v of misViviendas()" class="p-5 rounded-xl bg-[#F8FAFC] border border-slate-200 flex flex-col justify-between hover:border-slate-300 transition-colors">
              <div>
                <div class="flex items-center justify-between gap-2 mb-2">
                  <span class="text-xs font-semibold text-slate-500 uppercase tracking-wider">Unidad Física</span>
                  <span class="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                    Activa
                  </span>
                </div>
                <p class="text-2xl font-bold text-slate-900">Casa #{{ v.numeroCasa }}</p>
                <p class="text-sm text-slate-600 mt-1">Tipo: <span class="font-medium text-slate-800">{{ v.tipo || 'Residencial' }}</span></p>
              </div>
              <div class="mt-4 pt-3 border-t border-slate-200/80 flex items-center justify-between text-xs text-slate-500">
                <span>Haven Condominio</span>
                <span class="font-medium text-[#111C99]">Residente Oficial</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Caso B: Si NO tiene vivienda asignada (Pendiente de Asignacion) -->
        <div *ngIf="!isLoadingVivienda() && misViviendas().length === 0" class="bg-white border border-slate-200 rounded-xl p-6 sm:p-8 shadow-xs mb-8">
          <!-- Header de la tarjeta -->
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-blue-50 text-[#111C99] flex items-center justify-center shrink-0">
                <svg class="w-5 h-5 text-[#111C99]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                </svg>
              </div>
              <h2 class="text-lg sm:text-xl font-bold text-slate-900">Mi Vivienda</h2>
            </div>

            <!-- Badge de estado -->
            <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#FFFBEB] text-[#B45309] border border-[#FDE68A] self-start sm:self-auto">
              <svg class="w-3.5 h-3.5 text-[#B45309]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="10" stroke-width="2" />
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6l4 2" />
              </svg>
              Pendiente de Asignación
            </span>
          </div>

          <!-- Contenedor interior -->
          <div class="p-5 sm:p-6 rounded-xl bg-[#F8FAFC] border border-[#E2E8F0]">
            <h3 class="text-sm sm:text-base font-bold text-slate-900">
              Asignación de unidad física en proceso
            </h3>
            <p class="text-xs sm:text-sm text-slate-600 mt-1.5 leading-relaxed">
              La administración de Haven verificará tu número de teléfono registrado y asociará tu vivienda correspondiente. Una vez completado, verás aquí el número de casa, visitas programadas y accesos.
            </p>

            <div class="h-px bg-[#E2E8F0] my-5"></div>

            <!-- Checklist de Requisitos -->
            <div class="space-y-3.5">
              <!-- Cuenta de Residente -->
              <div class="flex items-start gap-3">
                <div class="mt-0.5 w-5 h-5 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                  </svg>
                </div>
                <div>
                  <p class="text-xs sm:text-sm font-semibold text-slate-900">Cuenta de Residente Haven</p>
                  <p class="text-xs text-slate-500">{{ currentUser()?.email || 'Activo' }}</p>
                </div>
              </div>

              <!-- Teléfono de Contacto -->
              <div class="flex items-start gap-3">
                <div *ngIf="hasTelefono(); else noPhoneIcon" class="mt-0.5 w-5 h-5 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                  </svg>
                </div>
                <ng-template #noPhoneIcon>
                  <div class="mt-0.5 w-5 h-5 rounded-full border-2 border-slate-300 shrink-0"></div>
                </ng-template>
                <div>
                  <p class="text-xs sm:text-sm font-semibold text-slate-900">Teléfono de Contacto</p>
                  <p class="text-xs text-slate-500">{{ currentUser()?.telefono || 'No registrado' }}</p>
                </div>
              </div>

              <!-- Vivienda Condominal -->
              <div class="flex items-start gap-3">
                <div class="mt-0.5 w-5 h-5 rounded-full border-2 border-slate-300 shrink-0"></div>
                <div>
                  <p class="text-xs sm:text-sm font-semibold text-slate-600">Vivienda Condominal</p>
                  <p class="text-xs text-slate-400">En espera de vinculación por el administrador</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Botón de Actualizar Perfil -->
          <div class="mt-5">
            <a
              routerLink="/perfil"
              class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border border-[#111C99] text-[#111C99] hover:bg-indigo-50 font-semibold text-sm transition-colors cursor-pointer"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              Ver y actualizar mi perfil de contacto
            </a>
          </div>
        </div>
      </main>
    </div>
  `
})
export class ResidenteDashboardComponent implements OnInit {
  private readonly authService = inject(AuthService);
  private readonly viviendasService = inject(ViviendasService);

  readonly currentUser = this.authService.currentUser;
  readonly misViviendas = signal<Vivienda[]>([]);
  readonly isLoadingVivienda = signal<boolean>(true);

  readonly hasTelefono = computed(() => {
    const tel = this.currentUser()?.telefono;
    return !!tel && tel.trim().length >= 10 && tel !== 'No registrado';
  });

  async ngOnInit(): Promise<void> {
    try {
      const list = await this.viviendasService.obtenerMisViviendas();
      this.misViviendas.set(list);
    } catch {
      this.misViviendas.set([]);
    } finally {
      this.isLoadingVivienda.set(false);
    }
  }

  onLogout(): void {
    this.authService.logout();
  }
}
