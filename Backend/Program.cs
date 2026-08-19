using HavenApi.Data;
using HavenApi.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// 1. Base de datos - Proveedor InMemory (temporal)
builder.Services.AddDbContext<HavenDbContext>(options =>
    options.UseInMemoryDatabase("HavenDb"));

// 2. Autenticacion - Supabase JWT (via OIDC Discovery)
var supabaseUrl = builder.Configuration["Supabase:Url"]!;
var supabaseIssuer = $"{supabaseUrl}/auth/v1";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = supabaseIssuer;

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = supabaseIssuer,
            ValidateAudience = true,
            ValidAudience = "authenticated",
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true
        };
    });

builder.Services.AddAuthorization();

// 3. Supabase Service
builder.Services.AddHttpClient<ISupabaseService, SupabaseService>();

// 4. Controllers
builder.Services.AddControllers();

// 5. OpenAPI / Swagger
builder.Services.AddOpenApi();

// 6. CORS - Permisivo por ahora (temporal)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowClients", policy =>
    {
        policy.AllowAnyOrigin()
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