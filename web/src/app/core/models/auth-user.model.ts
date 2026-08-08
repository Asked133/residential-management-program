export interface AuthUser {
  id: string;
  email: string;
  role?: 'administrador' | 'residente';
  rol?: string;
  nombre?: string;
  apellidos?: string;
}

