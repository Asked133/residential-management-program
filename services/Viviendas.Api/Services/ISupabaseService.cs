using Viviendas.Api.DTOs;

namespace Viviendas.Api.Services;

public interface ISupabaseService
{
    Task<string?> GetUsuarioRolAsync(Guid userId, string accessToken);
    Task<List<ViviendaDto>> GetViviendasAsync();
    Task<ViviendaDto?> GetViviendaByIdAsync(int id);
    Task<(ViviendaDto? vivienda, string? error)> CreateViviendaAsync(CreateViviendaRequestDto dto);
    Task<(ViviendaDto? vivienda, string? error)> UpdateViviendaAsync(int id, UpdateViviendaRequestDto dto);
    Task<bool> DeleteViviendaAsync(int id);
}
