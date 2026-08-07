import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';
import { environment } from '../../../environments/environment';
import Swal from 'sweetalert2';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const session = authService.currentSession();

  let authReq = req;

  if (req.url.startsWith(environment.apiUrl) && session?.access_token) {
    authReq = req.clone({
      setHeaders: {
        Authorization: `Bearer ${session.access_token}`
      }
    });
  }

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        Swal.fire({
          icon: 'warning',
          title: 'Sesión Expirada',
          text: 'Tu sesión expiró, inicia sesión nuevamente.',
          toast: true,
          position: 'top-end',
          showConfirmButton: false,
          timer: 4000,
          timerProgressBar: true
        });
        authService.logout();
      } else if (error.status === 403) {
        Swal.fire({
          icon: 'error',
          title: 'Acceso Restringido',
          text: 'No tienes permisos para realizar esta acción.',
          toast: true,
          position: 'top-end',
          showConfirmButton: false,
          timer: 4000,
          timerProgressBar: true
        });
      }
      return throwError(() => error);
    })
  );
};
