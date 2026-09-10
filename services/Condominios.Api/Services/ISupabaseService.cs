using Condominios.Api.DTOs;

namespace Condominios.Api.Services;

public interface ISupabaseService
{
    Task<List<CondominioDto>> GetCondominiosAsync();
}
