using HavenApi.DTOs;

namespace HavenApi.Services;

public interface ISupabaseService
{
    Task<UsuarioDto?> GetUsuarioByIdAsync(Guid userId, string accessToken);
    Task<string?> GetDbVersionAsync();
    Task<(UsuarioDto? usuario, string? error)> RegisterUsuarioAsync(RegisterRequestDto datos);
}