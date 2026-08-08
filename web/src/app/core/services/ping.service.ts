import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { timeout, catchError } from 'rxjs/operators';
import { of } from 'rxjs';
import Swal from 'sweetalert2';
import { environment } from '../../../environments/environment';

export const PING_TIMEOUT = 45000;

@Injectable({
  providedIn: 'root'
})
export class PingService {
  private readonly http = inject(HttpClient);

  checkBackendConnection(): void {
    const pingUrl = `${environment.apiUrl}/api/auth/ping`;

    const Toast = Swal.mixin({
      toast: true,
      position: 'bottom',
      showConfirmButton: false,
      timer: 5000,
      timerProgressBar: true,
      width: '100%'
    });

    this.http.get<any>(pingUrl).pipe(
      timeout(PING_TIMEOUT),
      catchError(error => {
        console.warn('Backend ping error details:', error);
        let errorMsg = 'No fue posible establecer conexión con el backend.';
        
        if (error.status === 0) {
          errorMsg = 'No fue posible conectar con el backend (Bloqueo de CORS desde localhost o sin conexión).';
        }

        Toast.fire({
          icon: 'error',
          title: errorMsg,
          background: '#fee2e2',
          color: '#991b1b'
        });
        return of(null);
      })
    ).subscribe(response => {
      if (response !== null) {
        Toast.fire({
          icon: 'success',
          title: 'Backend conectado correctamente.',
          background: '#dcfce7',
          color: '#166534'
        });
      }
    });
  }
}
