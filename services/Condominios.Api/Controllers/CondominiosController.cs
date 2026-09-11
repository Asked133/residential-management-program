using Condominios.Api.DTOs;
using Condominios.Api.Services;
using HavenApi.Shared.Filters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Condominios.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CondominiosController : ControllerBase
{
    private readonly ISupabaseService _supabaseService;
    private readonly ILogger<CondominiosController> _logger;

    public CondominiosController(ISupabaseService supabaseService, ILogger<CondominiosController> logger)
    {
        _supabaseService = supabaseService;
        _logger = logger;
    }

    [ProducesResponseType(StatusCodes.Status200OK)]
    [HttpGet]
    public async Task<IActionResult> GetCondominios()
    {
        var condominios = await _supabaseService.GetCondominiosAsync();
        var result = condominios.Select(c => new
        {
            id = c.Id,
            nombre = c.Nombre,
            activo = c.Activo,
            creadoEn = c.CreadoEn
        });

        return Ok(result);
    }

    [Authorize]
    [HttpGet("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCondominio(Guid id)
    {
        var condominio = await _supabaseService.GetCondominioByIdAsync(id);
        if (condominio == null)
        {
            _logger.LogWarning("GetCondominio: Condominio {Id} not found.", id);
            return NotFound(new { error = "Condominio no encontrado" });
        }

        return Ok(new
        {
            id = condominio.Id,
            nombre = condominio.Nombre,
            activo = condominio.Activo,
            creadoEn = condominio.CreadoEn
        });
    }

    [AllowAnonymous]
    [RequireDevKey]
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateCondominio([FromBody] CreateCondominioRequestDto dto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var (condominio, error) = await _supabaseService.CrearCondominioAsync(dto);
        if (error != null)
        {
            return BadRequest(new { error });
        }

        return CreatedAtAction(nameof(GetCondominio), new { id = condominio!.Id }, new
        {
            id = condominio.Id,
            nombre = condominio.Nombre,
            activo = condominio.Activo,
            creadoEn = condominio.CreadoEn
        });
    }

    [AllowAnonymous]
    [RequireDevKey]
    [HttpPost("{id}/baja")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> BajaCondominio(Guid id)
    {
        var result = await _supabaseService.DesactivarCondominioAsync(id);
        if (!result)
        {
            return NotFound(new { error = "Condominio no encontrado" });
        }

        return NoContent();
    }
}
