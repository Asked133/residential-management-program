import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { timeout, catchError } from 'rxjs/operators';
import { of } from 'rxjs';
import Swal from 'sweetalert2';
import { environment } from '../../../environments/environment';

export const PING_TIMEOUT = 45000;

export interface PingResponse {
  message?: string;
  timestamp?: string;
  dbVersion?: string;
}

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
      timer: 8000,
      timerProgressBar: true,
      width: '100%'
    });

    this.http.get<PingResponse>(pingUrl).pipe(
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
        const titleMsg = response.message || 'Backend conectado correctamente.';
        const dbVersionText = response.dbVersion ? response.dbVersion : 'No disponible';

        Toast.fire({
          icon: 'success',
          title: titleMsg,
          html: `<div style="font-size: 0.85rem; margin-top: 4px; font-weight: 500;">Versión BD: <strong>${dbVersionText}</strong></div>`,
          background: '#dcfce7',
          color: '#166534'
        });
      }
    });
  }
}

