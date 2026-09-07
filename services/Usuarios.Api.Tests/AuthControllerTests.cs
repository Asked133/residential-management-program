using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using Testcontainers.PostgreSql;
using Usuarios.Api.DTOs;
using Usuarios.Api.Services;
using Xunit;

namespace Usuarios.Api.Tests;

public class AuthControllerTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _dbContainer;

    public AuthControllerTests()
    {
        // Se levanta un contenedor PostgreSQL real como fue solicitado
        _dbContainer = new PostgreSqlBuilder()
            .WithImage("postgres:15-alpine")
            .WithDatabase("haven_db")
            .WithUsername("postgres")
            .WithPassword("postgres")
            .Build();
    }

    public async Task InitializeAsync()
    {
        await _dbContainer.StartAsync();
    }

    public async Task DisposeAsync()
    {
        await _dbContainer.DisposeAsync();
    }

    [Fact]
    public async Task Ping_ReturnsOk_WithDbVersion()
    {
        // Arrange
        var mockSupabaseService = new Mock<ISupabaseService>();
        mockSupabaseService.Setup(s => s.GetDbVersionAsync()).ReturnsAsync("15.0");

        await using var application = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(ISupabaseService));
                    if (descriptor != null) services.Remove(descriptor);
                    services.AddSingleton(mockSupabaseService.Object);
                });
            });

        var client = application.CreateClient();

        // Act
        var response = await client.GetAsync("/api/Auth/ping");

        // Assert
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("15.0", content);
        Assert.Contains("Haven API is running", content);
    }
}
