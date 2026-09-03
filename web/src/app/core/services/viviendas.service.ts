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
}
