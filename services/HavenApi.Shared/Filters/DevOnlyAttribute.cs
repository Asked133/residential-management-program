using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace HavenApi.Shared.Filters;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class DevOnlyAttribute : Attribute, IAsyncActionFilter
{
    private const string DevKeyHeaderName = "X-Dev-Key";

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var configuration = context.HttpContext.RequestServices.GetRequiredService<IConfiguration>();
        var expectedDevKey = configuration["Haven:DevKey"];

        if (string.IsNullOrEmpty(expectedDevKey))
        {
            context.Result = new ObjectResult(new { error = "Dev key is not configured on the server." })
            {
                StatusCode = 500
            };
            return;
        }

        if (!context.HttpContext.Request.Headers.TryGetValue(DevKeyHeaderName, out var providedDevKey))
        {
            context.Result = new UnauthorizedObjectResult(new { error = "Missing dev key header." });
            return;
        }

        if (providedDevKey != expectedDevKey)
        {
            context.Result = new UnauthorizedObjectResult(new { error = "Invalid dev key." });
            return;
        }

        await next();
    }
}
