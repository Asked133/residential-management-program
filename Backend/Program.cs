using HavenApi.Data;
using HavenApi.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// ──────────────────────────────────────────────────
// 1. Base de datos — Proveedor InMemory (temporal)
// ──────────────────────────────────────────────────
// Para migrar a PostgreSQL, solo cambia esta línea:
//   options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
builder.Services.AddDbContext<HavenDbContext>(options =>
    options.UseInMemoryDatabase("HavenDb"));

// ──────────────────────────────────────────────────
// 2. Autenticación — Supabase JWT (via OIDC Discovery)
// ──────────────────────────────────────────────────
// El middleware descarga automáticamente las llaves públicas (JWKS)
// desde Supabase y las cachea. La validación es 100% local.
var supabaseUrl = builder.Configuration["Supabase:Url"]!;
var supabaseIssuer = $"{supabaseUrl}/auth/v1";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Authority le dice al middleware dónde buscar la configuración OIDC
        // (.well-known/openid-configuration → jwks_uri → llaves públicas)
        options.Authority = supabaseIssuer;

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = supabaseIssuer,
            ValidateAudience = true,
            ValidAudience = "authenticated",  // Audience estándar de Supabase
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true
        };
    });

builder.Services.AddAuthorization();

// ──────────────────────────────────────────────────
// 3. Supabase Service — Consultas a tablas de Supabase
// ──────────────────────────────────────────────────
// AddHttpClient registra el servicio Y configura HttpClientFactory,
// que reutiliza conexiones HTTP (evita socket exhaustion).
builder.Services.AddHttpClient<ISupabaseService, SupabaseService>();

// ──────────────────────────────────────────────────
// 4. Controllers
// ──────────────────────────────────────────────────
builder.Services.AddControllers();

// ──────────────────────────────────────────────────
// 4. OpenAPI / Swagger
// ──────────────────────────────────────────────────
builder.Services.AddOpenApi();

// ──────────────────────────────────────────────────
// 5. CORS — Permitir requests desde Next.js y React Native
// ──────────────────────────────────────────────────
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowClients", policy =>
    {
        policy.WithOrigins(
                "http://localhost:3000",  
                "http://localhost:8081",
                "https://residential-management-program.vercel.app"
              )
              .AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

var app = builder.Build();


if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("AllowClients");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
