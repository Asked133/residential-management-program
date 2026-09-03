import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';
import { filter, take, map } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (_route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const checkAuthentication = () => {
    if (authService.authStatus() === 'authenticated') {
      if (!state.url.startsWith('/perfil') && authService.isProfileIncomplete()) {
        return router.createUrlTree(['/perfil'], { queryParams: { onboarding: 'true' } });
      }
      return true;
    }
    return router.createUrlTree(['/login']);
  };

  if (!authService.isLoading()) {
    return checkAuthentication();
  }

  return toObservable(authService.isLoading).pipe(
    filter(loading => !loading),
    take(1),
    map(() => checkAuthentication())
  );
};

