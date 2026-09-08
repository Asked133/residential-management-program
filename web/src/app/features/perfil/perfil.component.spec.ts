import { ComponentFixture, TestBed } from '@angular/core/testing';
import { PerfilComponent } from './perfil.component';
import { AuthService } from '../../core/services/auth.service';
import { provideRouter, Router } from '@angular/router';
import { ReactiveFormsModule } from '@angular/forms';
import { signal } from '@angular/core';

describe('PerfilComponent', () => {
  let component: PerfilComponent;
  let fixture: ComponentFixture<PerfilComponent>;
  let mockAuthService: any;
  let router: Router;

  beforeEach(async () => {
    mockAuthService = {
      currentUser: signal({
        id: 'user-1',
        email: 'admin@haven.com',
        nombre: 'Admin',
        apellidos: 'Principal',
        role: 'Administrador',
        telefono: '0',
        creadoEn: '2026-08-16T00:00:00Z'
      }),
      isProfileIncomplete: jasmine.createSpy('isProfileIncomplete').and.returnValue(false),
      getDashboardRoute: jasmine.createSpy('getDashboardRoute').and.returnValue('/dashboard'),
      actualizarPerfil: jasmine.createSpy('actualizarPerfil').and.returnValue(Promise.resolve({ success: true }))
    };

    await TestBed.configureTestingModule({
      imports: [PerfilComponent, ReactiveFormsModule],
      providers: [
        { provide: AuthService, useValue: mockAuthService },
        provideRouter([])
      ]
    }).compileComponents();

    router = TestBed.inject(Router);
    spyOn(router, 'navigate').and.returnValue(Promise.resolve(true));

    fixture = TestBed.createComponent(PerfilComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the perfil component', () => {
    expect(component).toBeTruthy();
  });

  describe('Validación de teléfono', () => {
    it('debe rechazar campo de teléfono vacío (es obligatorio)', () => {
      const telCtrl = component.perfilForm.get('telefono');
      telCtrl?.setValue('');
      telCtrl?.markAsTouched();

      expect(telCtrl?.valid).toBeFalse();
      expect(telCtrl?.hasError('required')).toBeTrue();
    });

    it('debe rechazar un solo dígito como "0" por patrón de 10 dígitos', () => {
      const telCtrl = component.perfilForm.get('telefono');
      telCtrl?.setValue('0');
      telCtrl?.markAsTouched();

      expect(telCtrl?.valid).toBeFalse();
      expect(telCtrl?.hasError('pattern')).toBeTrue();
    });

    it('debe rechazar números de menos de 10 dígitos', () => {
      const telCtrl = component.perfilForm.get('telefono');
      telCtrl?.setValue('442123456'); // 9 dígitos
      expect(telCtrl?.hasError('pattern')).toBeTrue();
    });

    it('debe aceptar números válidos de exactamente 10 dígitos', () => {
      const telCtrl = component.perfilForm.get('telefono');
      telCtrl?.setValue('4421234567');
      expect(telCtrl?.valid).toBeTrue();
      expect(telCtrl?.hasError('pattern')).toBeFalse();
    });

    it('debe limpiar valores "0" heredados de pruebas previas al resetear el formulario', () => {
      component.entrarModoEdicion();
      const telCtrl = component.perfilForm.get('telefono');
      // No debe precargar "0"
      expect(telCtrl?.value).toBe('');
    });
  });

  describe('Filtro de sólo números', () => {
    it('soloNumerosKeydown debe bloquear letras', () => {
      const event = new KeyboardEvent('keydown', { key: 'a' });
      spyOn(event, 'preventDefault');

      component.soloNumerosKeydown(event);
      expect(event.preventDefault).toHaveBeenCalled();
    });

    it('soloNumerosKeydown debe permitir dígitos', () => {
      const event = new KeyboardEvent('keydown', { key: '5' });
      spyOn(event, 'preventDefault');

      component.soloNumerosKeydown(event);
      expect(event.preventDefault).not.toHaveBeenCalled();
    });

    it('onTelefonoInput debe eliminar caracteres no numéricos y truncar a 10', () => {
      const inputEl = document.createElement('input');
      inputEl.value = '442-abc-12345678999';
      const event = { target: inputEl } as unknown as Event;

      component.onTelefonoInput(event);
      expect(inputEl.value).toBe('4421234567');
      expect(component.perfilForm.get('telefono')?.value).toBe('4421234567');
    });
  });
});
