import { Injectable, inject } from '@angular/core';
import { ApiService } from './api.service';
import { Vivienda } from '../models/vivienda.model';
import { firstValueFrom } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ViviendasService {
  private readonly apiService = inject(ApiService);

  listar(): Promise<Vivienda[]> {
    return firstValueFrom(this.apiService.get<Vivienda[]>('/api/viviendas'));
  }

  crear(payload: { numeroCasa: string; tipo?: string | null }): Promise<Vivienda> {
    return firstValueFrom(this.apiService.post<Vivienda>('/api/viviendas', payload));
  }

  actualizar(id: number, payload: { numeroCasa: string; tipo?: string | null }): Promise<Vivienda> {
    return firstValueFrom(this.apiService.put<Vivienda>(`/api/viviendas/${id}`, payload));
  }

  eliminar(id: number): Promise<void> {
    return firstValueFrom(this.apiService.delete<void>(`/api/viviendas/${id}`));
  }
}
