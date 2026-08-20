import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ResidentesFormComponent } from './residentes-form.component';
import { ResidentesService } from '../../../core/services/residentes.service';
import { Router, provideRouter } from '@angular/router';
import { ReactiveFormsModule } from '@angular/forms';

describe('ResidentesFormComponent', () => {
  let component: ResidentesFormComponent;
  let fixture: ComponentFixture<ResidentesFormComponent>;
  let mockResidentesService: any;
  let router: Router;

  beforeEach(async () => {
    mockResidentesService = {
      crear: jasmine.createSpy('crear').and.returnValue(Promise.resolve({ id: 'res-1' }))
    };

    await TestBed.configureTestingModule({
      imports: [ResidentesFormComponent, ReactiveFormsModule],
      providers: [
        { provide: ResidentesService, useValue: mockResidentesService },
        provideRouter([])
      ]
    }).compileComponents();

    router = TestBed.inject(Router);
    spyOn(router, 'navigate').and.returnValue(Promise.resolve(true));

    fixture = TestBed.createComponent(ResidentesFormComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the form component', () => {
    expect(component).toBeTruthy();
  });

  describe('Form Validations', () => {
    it('should be invalid when empty', () => {
      expect(component.residenteForm.valid).toBeFalse();
    });

    it('should validate required fields', () => {
      const form = component.residenteForm;
      expect(form.get('nombre')?.hasError('required')).toBeTrue();
      expect(form.get('apellidos')?.hasError('required')).toBeTrue();
      expect(form.get('telefono')?.hasError('required')).toBeTrue();
      expect(form.get('email')?.hasError('required')).toBeTrue();
      expect(form.get('password')?.hasError('required')).toBeTrue();
    });

    it('should validate email format', () => {
      const emailCtrl = component.residenteForm.get('email');
      emailCtrl?.setValue('correo-invalido');
      expect(emailCtrl?.hasError('email')).toBeTrue();

      emailCtrl?.setValue('usuario@haven.com');
      expect(emailCtrl?.hasError('email')).toBeFalse();
    });

    it('should validate phone pattern', () => {
      const phoneCtrl = component.residenteForm.get('telefono');
      phoneCtrl?.setValue('123'); // muy corto
      expect(phoneCtrl?.hasError('pattern')).toBeTrue();

      phoneCtrl?.setValue('4421234567'); // 10 dígitos válido
      expect(phoneCtrl?.hasError('pattern')).toBeFalse();
    });

    it('should validate password minimum length of 8 chars', () => {
      const pwdCtrl = component.residenteForm.get('password');
      pwdCtrl?.setValue('1234567'); // 7 chars
      expect(pwdCtrl?.hasError('minlength')).toBeTrue();

      pwdCtrl?.setValue('12345678'); // 8 chars
      expect(pwdCtrl?.hasError('minlength')).toBeFalse();
    });

    it('should generate secure password with generarPassword()', () => {
      component.generarPassword();
      const pwd = component.residenteForm.get('password')?.value;
      expect(pwd).toBeTruthy();
      expect(pwd.length).toBeGreaterThanOrEqual(8);
      expect(component.showPassword()).toBeTrue();
    });
  });

  describe('Issue #90: Error Handling in onSubmit()', () => {
    beforeEach(() => {
      component.residenteForm.setValue({
        nombre: 'Carlos',
        apellidos: 'Ramírez',
        telefono: '4421234567',
        email: 'carlos@haven.com',
        password: 'Password123!'
      });
    });

    it('should handle duplicate email error (status 409) and set field duplicate error', async () => {
      mockResidentesService.crear.and.returnValue(Promise.reject({
        status: 409,
        error: { message: 'User already registered' }
      }));

      await component.onSubmit();

      expect(component.isSubmitting()).toBeFalse();
      expect(component.errorMessage()).toContain('El correo electrónico ya se encuentra registrado');
      expect(component.residenteForm.get('email')?.hasError('duplicate')).toBeTrue();
    });

    it('should handle duplicate email error from Supabase string message', async () => {
      mockResidentesService.crear.and.returnValue(Promise.reject({
        status: 400,
        error: { message: 'A user with this email_exists already' }
      }));

      await component.onSubmit();

      expect(component.isSubmitting()).toBeFalse();
      expect(component.errorMessage()).toContain('El correo electrónico ya se encuentra registrado');
      expect(component.residenteForm.get('email')?.hasError('duplicate')).toBeTrue();
    });

    it('should clear duplicate error when user edits the email field', async () => {
      mockResidentesService.crear.and.returnValue(Promise.reject({
        status: 409,
        error: { message: 'already registered' }
      }));

      await component.onSubmit();
      expect(component.residenteForm.get('email')?.hasError('duplicate')).toBeTrue();
      expect(component.errorMessage()).toBeTruthy();

      // Usuario empieza a escribir otro correo
      component.residenteForm.get('email')?.setValue('carlos_nuevo@haven.com');

      expect(component.residenteForm.get('email')?.hasError('duplicate')).toBeFalse();
      expect(component.errorMessage()).toBeNull();
    });

    it('should handle structured validation errors from backend (400 / 422)', async () => {
      mockResidentesService.crear.and.returnValue(Promise.reject({
        status: 400,
        error: {
          errors: {
            Nombre: ['El nombre contiene caracteres inválidos'],
            Telefono: ['El teléfono debe ser a 10 dígitos']
          }
        }
      }));

      await component.onSubmit();

      expect(component.isSubmitting()).toBeFalse();
      expect(component.errorMessage()).toContain('Datos inválidos:');
      expect(component.residenteForm.get('nombre')?.errors?.['backend']).toBe('El nombre contiene caracteres inválidos');
      expect(component.residenteForm.get('telefono')?.errors?.['backend']).toBe('El teléfono debe ser a 10 dígitos');
    });

    it('should handle connection / server offline error (status 0)', async () => {
      mockResidentesService.crear.and.returnValue(Promise.reject({
        status: 0,
        message: 'Http failure response for (unknown url): 0 Unknown Error'
      }));

      await component.onSubmit();

      expect(component.isSubmitting()).toBeFalse();
      expect(component.errorMessage()).toContain('No fue posible conectar con el servidor');
    });

    it('should handle internal server error (status 500)', async () => {
      mockResidentesService.crear.and.returnValue(Promise.reject({
        status: 500,
        error: 'Internal server error'
      }));

      await component.onSubmit();

      expect(component.isSubmitting()).toBeFalse();
      expect(component.errorMessage()).toContain('Ocurrió un error interno en el servidor');
    });

    it('should submit successfully and navigate when no errors occur', async () => {
      mockResidentesService.crear.and.returnValue(Promise.resolve({ id: 'res-1' }));

      await component.onSubmit();

      expect(mockResidentesService.crear).toHaveBeenCalledWith({
        nombre: 'Carlos',
        apellidos: 'Ramírez',
        telefono: '4421234567',
        email: 'carlos@haven.com',
        password: 'Password123!',
        rol: 'residente'
      });
      expect(router.navigate).toHaveBeenCalledWith(['/dashboard/admin/residentes']);
    });
  });
});
