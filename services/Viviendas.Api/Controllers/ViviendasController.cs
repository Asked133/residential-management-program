using Viviendas.Api.DTOs;
using Viviendas.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Viviendas.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ViviendasController : ControllerBase
{
    private readonly ISupabaseService _supabaseService;

    public ViviendasController(ISupabaseService supabaseService)
    {
        _supabaseService = supabaseService;
    }

    private async Task<IActionResult?> ValidateAdminAsync()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                          ?? User.FindFirst("sub")?.Value;

        if (userIdClaim == null || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { error = "Token invalido: no contiene ID de usuario" });

        var accessToken = HttpContext.Request.Headers["Authorization"]
            .ToString().Replace("Bearer ", "");

        var rol = await _supabaseService.GetUsuarioRolAsync(userId, accessToken);

        if (rol == null)
            return NotFound(new { error = "Usuario no encontrado en la tabla 'usuarios'" });

        if (!string.Equals(rol, "Administrador", StringComparison.OrdinalIgnoreCase))
            return StatusCode(403, new { error = "Se requiere rol de administrador" });

        return null;
    }

    [ProducesResponseType(StatusCodes.Status200OK)]
    [HttpGet]
    public async Task<IActionResult> GetViviendas()
    {
        var viviendas = await _supabaseService.GetViviendasAsync();
        var result = viviendas.Select(v => new
        {
            id = v.Id,
            numeroCasa = v.NumeroCasa,
            tipo = v.Tipo,
            creadoEn = v.CreadoEn
        });

        return Ok(result);
    }

    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [HttpGet("{id}")]
    public async Task<IActionResult> GetVivienda(int id)
    {
        var vivienda = await _supabaseService.GetViviendaByIdAsync(id);
        if (vivienda == null)
            return NotFound(new { error = "Vivienda no encontrada" });

        return Ok(new
        {
            id = vivienda.Id,
            numeroCasa = vivienda.NumeroCasa,
            tipo = vivienda.Tipo,
            creadoEn = vivienda.CreadoEn
        });
    }

    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    [HttpPost]
    public async Task<IActionResult> CreateVivienda([FromBody] CreateViviendaRequestDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminValidation = await ValidateAdminAsync();
        if (adminValidation != null)
            return adminValidation;

        var (vivienda, error) = await _supabaseService.CreateViviendaAsync(dto);
        if (error != null)
        {
            if (error.Contains("Ya existe una vivienda registrada con ese número de casa"))
                return Conflict(new { error });

            return BadRequest(new { error });
        }

        return CreatedAtAction(nameof(GetVivienda), new { id = vivienda!.Id }, new
        {
            id = vivienda.Id,
            numeroCasa = vivienda.NumeroCasa,
            tipo = vivienda.Tipo,
            creadoEn = vivienda.CreadoEn
        });
    }

    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateVivienda(int id, [FromBody] UpdateViviendaRequestDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminValidation = await ValidateAdminAsync();
        if (adminValidation != null)
            return adminValidation;

        var (vivienda, error) = await _supabaseService.UpdateViviendaAsync(id, dto);
        if (error != null)
        {
            if (error.Contains("Ya existe una vivienda registrada con ese número de casa"))
                return Conflict(new { error });

            if (error == "Vivienda no encontrada o no se pudo actualizar")
                return NotFound(new { error });

            return BadRequest(new { error });
        }

        return Ok(new
        {
            id = vivienda!.Id,
            numeroCasa = vivienda.NumeroCasa,
            tipo = vivienda.Tipo,
            creadoEn = vivienda.CreadoEn
        });
    }

    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteVivienda(int id)
    {
        var adminValidation = await ValidateAdminAsync();
        if (adminValidation != null)
            return adminValidation;

        var success = await _supabaseService.DeleteViviendaAsync(id);
        if (!success)
            return NotFound(new { error = "Vivienda no encontrada" });

        return NoContent();
    }

    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    [HttpPost("{id}/residentes")]
    public async Task<IActionResult> AssignResidente(int id, [FromBody] AsignarResidenteRequestDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var adminValidation = await ValidateAdminAsync();
        if (adminValidation != null)
            return adminValidation;

        var (data, error) = await _supabaseService.AssignResidenteAsync(id, dto);
        if (data == null)
        {
            if (error != null && error.Contains("El residente ya está asignado"))
                return Conflict(new { error });
            if (error != null && error.Contains("no encontrad"))
                return NotFound(new { error });
            
            return BadRequest(new { error });
        }

        return StatusCode(201, data);
    }

    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [HttpDelete("{id}/residentes/{usuarioId}")]
    public async Task<IActionResult> RemoveResidente(int id, Guid usuarioId)
    {
        var adminValidation = await ValidateAdminAsync();
        if (adminValidation != null)
            return adminValidation;

        var success = await _supabaseService.RemoveResidenteAsync(id, usuarioId);
        if (!success)
            return NotFound(new { error = "Asignación no encontrada" });

        return NoContent();
    }

    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [HttpGet("mis-viviendas")]
    public async Task<IActionResult> GetMisViviendas()
    {
        var accessToken = HttpContext.Request.Headers["Authorization"]
            .ToString().Replace("Bearer ", "");

        if (string.IsNullOrEmpty(accessToken))
            return Unauthorized(new { error = "Token invalido o ausente" });

        var viviendas = await _supabaseService.GetMisViviendasAsync(accessToken);
        
        var result = viviendas.Select(v => new
        {
            viviendaId = v.ViviendaId,
            numeroCasa = v.NumeroCasa,
            tipo = v.Tipo,
            activo = v.Activo,
            creadoEn = v.CreadoEn
        });

        return Ok(result);
    }
}
