export interface AuthUser {
  id: string;
  email: string;
  role: 'administrador' | 'residente';
}
