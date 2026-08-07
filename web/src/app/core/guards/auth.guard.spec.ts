import { TestBed } from '@angular/core/testing';
import { Router, UrlTree } from '@angular/router';
import { authGuard } from './auth.guard';
import { AuthService } from '../services/auth.service';
import { signal, computed } from '@angular/core';
import { Observable } from 'rxjs';

describe('authGuard', () => {
  let mockAuthService: any;
  let mockRouter: any;

  beforeEach(() => {
    mockAuthService = {
      isLoading: signal(false),
      authStatus: signal<'loading' | 'authenticated' | 'unauthenticated'>('unauthenticated'),
      currentUser: signal<any>(null),
      isAdmin: computed(() => mockAuthService.currentUser()?.role === 'administrador')
    };

    mockRouter = {
      createUrlTree: jasmine.createSpy('createUrlTree').and.callFake((path: string[]) => path as any)
    };

    TestBed.configureTestingModule({
      providers: [
        { provide: AuthService, useValue: mockAuthService },
        { provide: Router, useValue: mockRouter }
      ]
    });
  });

  it('should grant access if user is authenticated and is admin', (done) => {
    mockAuthService.authStatus.set('authenticated');
    mockAuthService.currentUser.set({ id: '1', email: 'admin@test.com', role: 'administrador' });
    mockAuthService.isLoading.set(false);

    const guardResult = TestBed.runInInjectionContext(() => authGuard({} as any, {} as any)) as Observable<boolean | UrlTree>;

    guardResult.subscribe((result) => {
      expect(result).toBe(true);
      done();
    });
  });

  it('should redirect to /login if user is authenticated but NOT admin', (done) => {
    mockAuthService.authStatus.set('authenticated');
    mockAuthService.currentUser.set({ id: '2', email: 'user@test.com', role: 'residente' });
    mockAuthService.isLoading.set(false);

    const guardResult = TestBed.runInInjectionContext(() => authGuard({} as any, {} as any)) as Observable<boolean | UrlTree>;

    guardResult.subscribe((result) => {
      expect(mockRouter.createUrlTree).toHaveBeenCalledWith(['/login']);
      done();
    });
  });

  it('should redirect to /login if user is unauthenticated', (done) => {
    mockAuthService.authStatus.set('unauthenticated');
    mockAuthService.currentUser.set(null);
    mockAuthService.isLoading.set(false);

    const guardResult = TestBed.runInInjectionContext(() => authGuard({} as any, {} as any)) as Observable<boolean | UrlTree>;

    guardResult.subscribe((result) => {
      expect(mockRouter.createUrlTree).toHaveBeenCalledWith(['/login']);
      done();
    });
  });
});
