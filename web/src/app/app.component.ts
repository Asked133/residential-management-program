import { Component, inject, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';
import { PingService } from './core/services/ping.service';
import { AuthService } from './core/services/auth.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, CommonModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnInit {
  private readonly pingService = inject(PingService);
  readonly authService = inject(AuthService);

  ngOnInit(): void {
    // Non-blocking ping check with 45s timeout for Render backend cold start
    this.pingService.checkBackendConnection();
  }
}
