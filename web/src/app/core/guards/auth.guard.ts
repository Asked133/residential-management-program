import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';
import { filter, take, map } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = () => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (!authService.isLoading()) {
    if (authService.authStatus() === 'authenticated') {
      return true;
    }
    return router.createUrlTree(['/login']);
  }

  return toObservable(authService.isLoading).pipe(
    filter(loading => !loading),
    take(1),
    map(() => {
      if (authService.authStatus() === 'authenticated') {
        return true;
      }
      return router.createUrlTree(['/login']);
    })
  );
};

