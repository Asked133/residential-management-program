using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace HavenApi.Shared.Filters;

[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class RequireDevKeyAttribute : Attribute, IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var configuration = context.HttpContext.RequestServices.GetService<IConfiguration>();
        var configuredKey = configuration?["DevTools:ApiKey"];

        if (string.IsNullOrEmpty(configuredKey))
        {
            context.Result = new ObjectResult(new { error = "Acceso restringido a herramientas de desarrollo" })
            {
                StatusCode = 401
            };
            return;
        }

        if (!context.HttpContext.Request.Headers.TryGetValue("X-Dev-Key", out var headerKey) || headerKey != configuredKey)
        {
            context.Result = new ObjectResult(new { error = "Acceso restringido a herramientas de desarrollo" })
            {
                StatusCode = 401
            };
            return;
        }

        await next();
    }
}
