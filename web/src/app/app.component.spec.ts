import { TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';
import { PingService } from './core/services/ping.service';
import { AuthService } from './core/services/auth.service';
import { signal } from '@angular/core';
import { provideRouter } from '@angular/router';

describe('AppComponent', () => {
  let mockPingService: any;
  let mockAuthService: any;

  beforeEach(async () => {
    mockPingService = {
      checkBackendConnection: jasmine.createSpy('checkBackendConnection')
    };

    mockAuthService = {
      isLoading: signal(false),
      authStatus: signal('unauthenticated')
    };

    await TestBed.configureTestingModule({
      imports: [AppComponent],
      providers: [
        provideRouter([]),
        { provide: PingService, useValue: mockPingService },
        { provide: AuthService, useValue: mockAuthService }
      ]
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(AppComponent);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should check backend connection on init', () => {
    const fixture = TestBed.createComponent(AppComponent);
    fixture.detectChanges();
    expect(mockPingService.checkBackendConnection).toHaveBeenCalled();
  });
});
