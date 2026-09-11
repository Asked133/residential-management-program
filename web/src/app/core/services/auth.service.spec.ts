import { TestBed } from '@angular/core/testing';
import { AuthService } from './auth.service';
import { ApiService } from './api.service';
import { Router } from '@angular/router';
import { of } from 'rxjs';

describe('AuthService', () => {
  let service: AuthService;
  let mockApiService: any;
  let mockRouter: any;

  beforeEach(() => {
    mockApiService = {
      get: jasmine.createSpy('get').and.returnValue(of({}))
    };

    mockRouter = {
      navigate: jasmine.createSpy('navigate').and.returnValue(Promise.resolve(true))
    };

    TestBed.configureTestingModule({
      providers: [
        AuthService,
        { provide: ApiService, useValue: mockApiService },
        { provide: Router, useValue: mockRouter }
      ]
    });

    service = TestBed.inject(AuthService);
  });

  describe('normalizeRole', () => {
    it('should normalize administrador and admin correctly', () => {
      expect(service.normalizeRole('Administrador')).toBe('administrador');
      expect(service.normalizeRole('ADMIN')).toBe('administrador');
      expect(service.normalizeRole('admin')).toBe('administrador');
      expect(service.normalizeRole('administrador')).toBe('administrador');
    });

    it('should normalize vigilante and guardia correctly', () => {
      expect(service.normalizeRole('Vigilante')).toBe('vigilante');
      expect(service.normalizeRole('vigilante')).toBe('vigilante');
      expect(service.normalizeRole('guardia')).toBe('vigilante');
    });

    it('should default to residente for other values or empty role', () => {
      expect(service.normalizeRole('Residente')).toBe('residente');
      expect(service.normalizeRole('residente')).toBe('residente');
      expect(service.normalizeRole('')).toBe('residente');
      expect(service.normalizeRole(null)).toBe('residente');
      expect(service.normalizeRole(undefined)).toBe('residente');
    });
  });

  describe('getDashboardRoute', () => {
    it('should return /dashboard/admin for administrador', () => {
      expect(service.getDashboardRoute('Administrador')).toBe('/dashboard/admin');
      expect(service.getDashboardRoute('admin')).toBe('/dashboard/admin');
    });

    it('should return /dashboard/residente for residente', () => {
      expect(service.getDashboardRoute('Residente')).toBe('/dashboard/residente');
      expect(service.getDashboardRoute('residente')).toBe('/dashboard/residente');
    });

    it('should return /dashboard/vigilante for vigilante', () => {
      expect(service.getDashboardRoute('Vigilante')).toBe('/dashboard/vigilante');
      expect(service.getDashboardRoute('vigilante')).toBe('/dashboard/vigilante');
    });
  });

  describe('computed role helpers', () => {
    it('should compute isAdmin correctly', () => {
      service.currentUser.set({ id: '1', email: 'admin@test.com', role: 'Administrador' });
      expect(service.isAdmin()).toBe(true);
      expect(service.isResidente()).toBe(false);
      expect(service.isVigilante()).toBe(false);
    });

    it('should compute isResidente correctly', () => {
      service.currentUser.set({ id: '2', email: 'res@test.com', role: 'Residente' });
      expect(service.isAdmin()).toBe(false);
      expect(service.isResidente()).toBe(true);
      expect(service.isVigilante()).toBe(false);
    });

    it('should compute isVigilante correctly', () => {
      service.currentUser.set({ id: '3', email: 'guard@test.com', role: 'Vigilante' });
      expect(service.isAdmin()).toBe(false);
      expect(service.isResidente()).toBe(false);
      expect(service.isVigilante()).toBe(true);
    });
  });

  describe('security: setAuthenticatedUser role source', () => {
    it('should fallback to user_metadata when backend profile has no role', () => {
      const sessionUser = {
        id: 'hack-1',
        email: 'user@test.com',
        user_metadata: { rol: 'Administrador', role: 'admin' }
      };

      service['setAuthenticatedUser'](sessionUser, null);

      expect(service.currentUser()?.role).toBe('Administrador');
      expect(service.isAdmin()).toBe(true);
      expect(service.isResidente()).toBe(false);
    });

    it('should honor valid role from backend profile', () => {
      const sessionUser = {
        id: 'admin-1',
        email: 'admin@test.com',
        user_metadata: {}
      };
      const backendProfile = {
        id: 'admin-1',
        email: 'admin@test.com',
        rol: 'Administrador'
      };

      (service as any).setAuthenticatedUser(sessionUser, backendProfile);

      expect(service.currentUser()?.role).toBe('Administrador');
      expect(service.isAdmin()).toBe(true);
    });

    it('should preserve existing user data and ignore google user_metadata when user already exists in database', () => {
      const sessionUser = {
        id: 'usr-123',
        email: 'juan@test.com',
        user_metadata: {
          nombre: 'Google Name',
          given_name: 'Google Given',
          apellidos: 'Google Last',
          family_name: 'Google Family',
          telefono: '9999999999'
        }
      };

      const existingProfile = {
        id: 'usr-123',
        email: 'juan@test.com',
        nombre: 'Juan Carlos',
        apellidos: 'Pérez Gómez',
        telefono: '4421234567',
        rol: 'Residente'
      };

      (service as any).setAuthenticatedUser(sessionUser, existingProfile);

      const user = service.currentUser();
      expect(user?.nombre).toBe('Juan Carlos');
      expect(user?.apellidos).toBe('Pérez Gómez');
      expect(user?.telefono).toBe('4421234567');
      expect(user?.nombre).not.toBe('Google Name');
    });
  });
});
