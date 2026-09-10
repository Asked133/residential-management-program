using Microsoft.AspNetCore.Mvc;
using HavenApi.Shared.Filters;

namespace Condominios.Api.Controllers;

[ApiController]
public class HealthController : ControllerBase
{
    [HttpGet("api/health/public")]
    public IActionResult GetPublicHealth()
    {
        return Ok(new { status = "ok", servicio = "Condominios.Api" });
    }

    [HttpGet("api/health/dev-only")]
    [RequireDevKey]
    public IActionResult GetDevOnlyHealth()
    {
        return Ok(new { status = "ok, autenticado como dev" });
    }
}
