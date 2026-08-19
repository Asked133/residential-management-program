using HavenApi.DTOs;
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

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto datos)
    {
        var (usuario, error) = await _supabaseService.RegisterUsuarioAsync(datos);

        if (error != null)
        {
            if (error.Contains("ya esta registrado"))
                return Conflict(new { error });

            return BadRequest(new { error });
        }

        return Created("/api/auth/me", new
        {
            id = usuario!.Id,
            rolId = usuario.RolId,
            email = usuario.Email,
            nombre = usuario.Nombre,
            apellidos = usuario.Apellidos,
            telefono = usuario.Telefono,
            creadoEn = usuario.CreadoEn
        });
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                          ?? User.FindFirst("sub")?.Value;

        if (userIdClaim == null || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { error = "Token invalido: no contiene ID de usuario" });

        var accessToken = HttpContext.Request.Headers["Authorization"]
            .ToString().Replace("Bearer ", "");

        var usuario = await _supabaseService.GetUsuarioByIdAsync(userId, accessToken);

        if (usuario == null)
            return NotFound(new { error = "Usuario no encontrado en la tabla 'usuarios'" });

        return Ok(new
        {
            id = usuario.Id,
            rolId = usuario.RolId,
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