using System.Net.Http.Headers;
using HavenApi.DTOs;

namespace HavenApi.Services;

public class SupabaseService : ISupabaseService
{
    private readonly HttpClient _httpClient;
    private readonly string _supabaseUrl;
    private readonly string _anonKey;

    public SupabaseService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _supabaseUrl = configuration["Supabase:Url"]!;
        _anonKey = configuration["Supabase:AnonKey"]!;
    }

    public async Task<UsuarioDto?> GetUsuarioByIdAsync(Guid userId, string accessToken)
    {
        // PostgREST API de Supabase:
        // GET /rest/v1/usuarios?id=eq.<uuid>&select=*
        // El filtro eq. significa "equal to"
        var requestUrl = $"{_supabaseUrl}/rest/v1/usuarios?id=eq.{userId}&select=*";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);

        // apikey: identifica el proyecto de Supabase
        request.Headers.Add("apikey", _anonKey);

        // Authorization: el JWT del usuario autenticado.
        // Supabase usa Row Level Security (RLS), así que solo retorna
        // datos que el usuario tiene permiso de ver.
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return null;

        // PostgREST siempre retorna un array, incluso para un solo registro
        var usuarios = await response.Content.ReadFromJsonAsync<List<UsuarioDto>>();

        return usuarios?.FirstOrDefault();
    }
}
