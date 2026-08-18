using HavenApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace HavenApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ISupabaseService _supabaseService;

    public AuthController(ISupabaseService supabaseService)
    {
        _supabaseService = supabaseService;
    }

    // Endpoint público — health check
    [HttpGet("ping")]
    public async Task<IActionResult> Ping()
    {
        var dbVersion = await _supabaseService.GetDbVersionAsync();

        return Ok(new
        {
            message = "Haven API is running",
            timestamp = DateTime.UtcNow,
            dbVersion
        });
    }

    // Endpoint protegido — retorna el perfil completo del usuario
    // Combina datos del JWT (auth) + tabla usuarios (negocio)
    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        // 1. Extraer el ID del usuario desde el JWT (claim "sub")
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                          ?? User.FindFirst("sub")?.Value;

        if (userIdClaim == null || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { error = "Token inválido: no contiene ID de usuario" });

        // 2. Extraer el access_token del header Authorization para pasarlo a Supabase
        var accessToken = HttpContext.Request.Headers["Authorization"]
            .ToString().Replace("Bearer ", "");

        // 3. Consultar la tabla 'usuarios' en Supabase
        var usuario = await _supabaseService.GetUsuarioByIdAsync(userId, accessToken);

        if (usuario == null)
            return NotFound(new { error = "Usuario no encontrado en la tabla 'usuarios'" });

        // 4. Retornar el perfil completo
        return Ok(new
        {
            id = usuario.Id,
            nombre = usuario.Nombre,
            apellidos = usuario.Apellidos,
            telefono = usuario.Telefono,
            rol = usuario.EffectiveRol,
            email = User.FindFirst(ClaimTypes.Email)?.Value
                    ?? User.FindFirst("email")?.Value,
            creadoEn = usuario.CreadoEn
        });
    }
}
