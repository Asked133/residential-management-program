import { TestBed } from '@angular/core/testing';
import { Router, UrlTree, ActivatedRouteSnapshot } from '@angular/router';
import { roleGuard } from './role.guard';
import { AuthService } from '../services/auth.service';
import { signal, computed } from '@angular/core';
import { Observable } from 'rxjs';

describe('roleGuard', () => {
  let mockAuthService: any;
  let mockRouter: any;

  beforeEach(() => {
    mockAuthService = {
      isLoading: signal(false),
      authStatus: signal<'loading' | 'authenticated' | 'unauthenticated'>('unauthenticated'),
      currentUser: signal<any>(null),
      userRole: computed(() => {
        const user = mockAuthService.currentUser();
        if (!user) return null;
        return mockAuthService.normalizeRole(user.role || user.rol);
      }),
      normalizeRole: (r: string) => {
        const raw = (r || '').toString().trim().toLowerCase();
        if (raw === 'administrador' || raw === 'admin') return 'administrador';
        if (raw === 'vigilante' || raw === 'guardia') return 'vigilante';
        return 'residente';
      },
      getDashboardRoute: jasmine.createSpy('getDashboardRoute').and.callFake(() => {
        const role = mockAuthService.userRole();
        if (role === 'administrador') return '/dashboard/admin';
        if (role === 'vigilante') return '/dashboard/vigilante';
        return '/dashboard/residente';
      })
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

  it('should redirect to /login if user is unauthenticated', (done) => {
    mockAuthService.authStatus.set('unauthenticated');
    mockAuthService.currentUser.set(null);
    mockAuthService.isLoading.set(false);

    const guard = roleGuard(['administrador']);
    const result$ = TestBed.runInInjectionContext(() => guard({} as ActivatedRouteSnapshot, {} as any)) as Observable<boolean | UrlTree>;

    result$.subscribe((res) => {
      expect(mockRouter.createUrlTree).toHaveBeenCalledWith(['/login']);
      done();
    });
  });

  it('should allow access if user role matches allowed roles (admin -> admin)', (done) => {
    mockAuthService.authStatus.set('authenticated');
    mockAuthService.currentUser.set({ id: '1', email: 'admin@haven.com', role: 'Administrador' });
    mockAuthService.isLoading.set(false);

    const guard = roleGuard(['administrador']);
    const result$ = TestBed.runInInjectionContext(() => guard({} as ActivatedRouteSnapshot, {} as any)) as Observable<boolean | UrlTree>;

    result$.subscribe((res) => {
      expect(res).toBe(true);
      done();
    });
  });

  it('should allow access if user role matches allowed roles (residente -> residente)', (done) => {
    mockAuthService.authStatus.set('authenticated');
    mockAuthService.currentUser.set({ id: '2', email: 'res@haven.com', role: 'Residente' });
    mockAuthService.isLoading.set(false);

    const guard = roleGuard(['residente']);
    const result$ = TestBed.runInInjectionContext(() => guard({} as ActivatedRouteSnapshot, {} as any)) as Observable<boolean | UrlTree>;

    result$.subscribe((res) => {
      expect(res).toBe(true);
      done();
    });
  });

  it('should allow access if user role matches allowed roles (vigilante -> vigilante)', (done) => {
    mockAuthService.authStatus.set('authenticated');
    mockAuthService.currentUser.set({ id: '3', email: 'guard@haven.com', role: 'Vigilante' });
    mockAuthService.isLoading.set(false);

    const guard = roleGuard(['vigilante']);
    const result$ = TestBed.runInInjectionContext(() => guard({} as ActivatedRouteSnapshot, {} as any)) as Observable<boolean | UrlTree>;

    result$.subscribe((res) => {
      expect(res).toBe(true);
      done();
    });
  });

  it('should redirect to user specific dashboard if user role does not match allowed roles (residente trying admin)', (done) => {
    mockAuthService.authStatus.set('authenticated');
    mockAuthService.currentUser.set({ id: '2', email: 'res@haven.com', role: 'Residente' });
    mockAuthService.isLoading.set(false);

    const guard = roleGuard(['administrador']);
    const result$ = TestBed.runInInjectionContext(() => guard({} as ActivatedRouteSnapshot, {} as any)) as Observable<boolean | UrlTree>;

    result$.subscribe(() => {
      expect(mockRouter.createUrlTree).toHaveBeenCalledWith(['/dashboard/residente']);
      done();
    });
  });
});
