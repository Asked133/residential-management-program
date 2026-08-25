using HavenApi.DTOs;

namespace HavenApi.Services;

public interface ISupabaseService
{
    Task<UsuarioDto?> GetUsuarioByIdAsync(Guid userId, string accessToken);
    Task<string?> GetDbVersionAsync();
    Task<(UsuarioDto? usuario, string? error)> RegisterUsuarioAsync(RegisterRequestDto datos);
    Task<List<UsuarioDto>> GetResidentesAsync();
    Task<List<ViviendaDto>> GetViviendasAsync();
    Task<ViviendaDto?> GetViviendaByIdAsync(int id);
    Task<(ViviendaDto? vivienda, string? error)> CreateViviendaAsync(CreateViviendaRequestDto dto);
    Task<(ViviendaDto? vivienda, string? error)> UpdateViviendaAsync(int id, UpdateViviendaRequestDto dto);
    Task<bool> DeleteViviendaAsync(int id);
}