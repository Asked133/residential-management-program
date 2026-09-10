using Microsoft.Extensions.DependencyInjection;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace HavenApi.Shared.Extensions;

public static class SwaggerDevKeyExtensions
{
    public static SwaggerGenOptions AddDevKeySecurityDefinition(this SwaggerGenOptions options)
    {
        options.AddSecurityDefinition("DevKey", new OpenApiSecurityScheme
        {
            Name = "X-Dev-Key",
            Type = SecuritySchemeType.ApiKey,
            In = ParameterLocation.Header,
            Description = "Introduce el ApiKey de desarrollo (DevTools:ApiKey) en el formato: {tu_apikey_aqui}"
        });

        options.AddSecurityRequirement(new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference
                    {
                        Type = ReferenceType.SecurityScheme,
                        Id = "DevKey"
                    }
                },
                Array.Empty<string>()
            }
        });

        return options;
    }
}
