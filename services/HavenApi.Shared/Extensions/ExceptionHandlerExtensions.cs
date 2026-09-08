using HavenApi.Shared.Middleware;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;

namespace HavenApi.Shared.Extensions;

public static class ExceptionHandlerExtensions
{
    public static IServiceCollection AddHavenExceptionHandler(this IServiceCollection services)
    {
        services.AddExceptionHandler<GlobalExceptionHandler>();
        services.AddProblemDetails();
        return services;
    }
    
    public static IApplicationBuilder UseHavenExceptionHandler(this IApplicationBuilder app)
    {
        app.UseExceptionHandler();
        return app;
    }
}
