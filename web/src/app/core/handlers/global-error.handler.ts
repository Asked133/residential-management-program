import { ErrorHandler, Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class GlobalErrorHandler implements ErrorHandler {
  handleError(error: any): void {
    const message = error?.message || error?.toString?.() || '';
    const isChunkFailure =
      message.includes('Failed to fetch dynamically imported module') ||
      message.includes('Loading chunk') ||
      message.includes('Loading CSS chunk');

    if (isChunkFailure) {
      const storageKey = 'haven_chunk_reload_timestamp';
      const lastReload = sessionStorage.getItem(storageKey);
      const now = Date.now();

      // Evita loops infinitos de recarga si hay un error persistente de red (max 1 recarga cada 15 segundos)
      if (!lastReload || now - parseInt(lastReload, 10) > 15000) {
        sessionStorage.setItem(storageKey, now.toString());
        console.warn('[GlobalErrorHandler] Chunk desfasado por nuevo despliegue. Recargando para actualizar bundle...');
        window.location.reload();
        return;
      }
    }

    console.error('[GlobalErrorHandler]', error);
  }
}
