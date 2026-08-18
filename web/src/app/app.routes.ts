import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard } from './core/guards/role.guard';
import { LoginComponent } from './features/auth/login/login.component';
import { DashboardComponent } from './features/dashboard/dashboard.component';

export const routes: Routes = [
  {
    path: 'login',
    component: LoginComponent
  },
  {
    path: 'dashboard',
    canActivate: [authGuard],
    component: DashboardComponent
  },
  {
    path: 'dashboard/admin',
    canActivate: [authGuard, roleGuard(['administrador'])],
    loadComponent: () =>
      import('./features/dashboard/admin-dashboard/admin-dashboard.component')
        .then(m => m.AdminDashboardComponent)
  },
  {
    path: 'dashboard/residente',
    canActivate: [authGuard, roleGuard(['residente'])],
    loadComponent: () =>
      import('./features/dashboard/residente-dashboard/residente-dashboard.component')
        .then(m => m.ResidenteDashboardComponent)
  },
  {
    path: 'dashboard/vigilante',
    canActivate: [authGuard, roleGuard(['vigilante'])],
    loadComponent: () =>
      import('./features/dashboard/vigilante-dashboard/vigilante-dashboard.component')
        .then(m => m.VigilanteDashboardComponent)
  },
  {
    path: '',
    redirectTo: '/login',
    pathMatch: 'full'
  },
  {
    path: '**',
    redirectTo: '/login'
  }
];
