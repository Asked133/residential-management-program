import { CanActivateFn, Router, ActivatedRouteSnapshot } from '@angular/router';
import { inject } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';
import { filter, take, map } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';

export const roleGuard = (allowedRoles: string[]): CanActivateFn => {
  return (_route: ActivatedRouteSnapshot) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    return toObservable(authService.isLoading).pipe(
      filter(loading => !loading),
      take(1),
      map(() => {
        if (authService.authStatus() !== 'authenticated') {
          return router.createUrlTree(['/login']);
        }

        const userRole = authService.userRole();
        const normalizedAllowed = allowedRoles.map(r => authService.normalizeRole(r));

        if (userRole && normalizedAllowed.includes(userRole)) {
          return true;
        }

        const targetRoute = authService.getDashboardRoute();
        return router.createUrlTree([targetRoute]);
      })
    );
  };
};
