import { Injectable, inject } from '@angular/core';
import { ApiService } from './api.service';
import { Residente } from '../models/residente.model';
import { firstValueFrom } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ResidentesService {
  private readonly apiService = inject(ApiService);

  listar(): Promise<Residente[]> {
    return firstValueFrom(this.apiService.get<Residente[]>('/api/auth/residentes'));
  }

  crear(payload: {
    nombre: string;
    apellidos: string;
    telefono: string;
    email: string;
    password: string;
    rol: string;
  }): Promise<Residente> {
    return firstValueFrom(this.apiService.post<Residente>('/api/auth/register', payload));
  }
}
