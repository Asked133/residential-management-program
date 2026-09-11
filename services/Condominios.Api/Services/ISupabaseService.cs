using Condominios.Api.DTOs;

namespace Condominios.Api.Services;

public interface ISupabaseService
{
    Task<List<CondominioDto>> GetCondominiosAsync();
    Task<CondominioDto?> GetCondominioByIdAsync(Guid id);
    Task<(CondominioDto? condominio, string? error)> CrearCondominioAsync(CreateCondominioRequestDto dto);
}
