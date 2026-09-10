namespace Condominios.Api.Services;

public class SupabaseService : ISupabaseService
{
    private readonly HttpClient _httpClient;
    
    public SupabaseService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }
}
