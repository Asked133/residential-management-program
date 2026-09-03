using Usuarios.Api.DTOs;
using Usuarios.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Usuarios.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ISupabaseService _supabaseService;

    public AuthController(ISupabaseService supabaseService)
    {
        _supabaseService = supabaseService;
    }

    [ProducesResponseType(StatusCodes.Status200OK)]
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

    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    [Authorize] // Protected for admins
    [HttpPost("register-admin")]
    public async Task<IActionResult> RegisterAdmin([FromBody] RegisterRequestDto datos)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? User.FindFirst("sub")?.Value;
        Guid? actorId = userIdClaim != null && Guid.TryParse(userIdClaim, out var parsedId) ? parsedId : null;

        var (usuario, error) = await _supabaseService.RegisterAdminAsync(datos, actorId);

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

    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
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

        var usuario = await _supabaseService.GetUsuarioByIdAsync(userId, accessToken, userId);

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

    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [Authorize]
    [HttpGet("residentes")]
    public async Task<IActionResult> GetResidentes()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                          ?? User.FindFirst("sub")?.Value;

        if (userIdClaim == null || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { error = "Token invalido: no contiene ID de usuario" });

        var accessToken = HttpContext.Request.Headers["Authorization"]
            .ToString().Replace("Bearer ", "");

        var usuario = await _supabaseService.GetUsuarioByIdAsync(userId, accessToken, userId);

        if (usuario == null)
            return NotFound(new { error = "Usuario no encontrado en la tabla 'usuarios'" });

        if (!string.Equals(usuario.EffectiveRol, "Administrador", StringComparison.OrdinalIgnoreCase))
            return StatusCode(403, new { error = "Se requiere rol de administrador" });

        var residentes = await _supabaseService.GetResidentesAsync(userId);

        var result = residentes.Select(r => new
        {
            id = r.Id,
            nombre = r.Nombre,
            apellidos = r.Apellidos,
            telefono = r.Telefono,
            email = r.Email,
            creadoEn = r.CreadoEn
        });

        return Ok(result);
    }

    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [Authorize]
    [HttpPatch("completar-perfil")]
    public async Task<IActionResult> CompletarPerfil([FromBody] CompletarPerfilRequestDto datos)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                          ?? User.FindFirst("sub")?.Value;

        if (userIdClaim == null || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { error = "Token invalido: no contiene ID de usuario" });

        var accessToken = HttpContext.Request.Headers["Authorization"]
            .ToString().Replace("Bearer ", "");

        var (usuario, error) = await _supabaseService.CompletarPerfilAsync(userId, datos, accessToken, userId);

        if (error != null)
        {
            return BadRequest(new { error });
        }

        if (usuario == null)
            return NotFound(new { error = "Usuario no encontrado" });

        return Ok(new
        {
            id = usuario.Id,
            nombre = usuario.Nombre,
            apellidos = usuario.Apellidos,
            telefono = usuario.Telefono
        });
    }
}