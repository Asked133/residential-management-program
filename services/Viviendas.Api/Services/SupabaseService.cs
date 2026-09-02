using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;
using Viviendas.Api.DTOs;

namespace Viviendas.Api.Services;

public class SupabaseService : ISupabaseService
{
    private readonly HttpClient _httpClient;
    private readonly string _supabaseUrl;
    private readonly string _anonKey;
    private readonly string _serviceRoleKey;

    public SupabaseService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _supabaseUrl = configuration["Supabase:Url"]!;
        _anonKey = configuration["Supabase:AnonKey"]!;
        _serviceRoleKey = configuration["Supabase:ServiceRoleKey"]!;
    }

    // NOTA: Se consulta usuarios directamente por HTTP a Supabase por compartir la misma BD
    // Esto evita acoplamiento HTTP entre microservicios (Viviendas -> Usuarios)
    public async Task<string?> GetUsuarioRolAsync(Guid userId, string accessToken)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/vw_usuarios?id=eq.{userId}&select=*";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Add("apikey", _anonKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return null;

        var json = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);
        if (doc.RootElement.GetArrayLength() == 0) return null;

        var el = doc.RootElement[0];
        
        if (el.TryGetProperty("rol_nombre", out var rn) && rn.ValueKind != JsonValueKind.Null)
            return rn.GetString();
            
        if (el.TryGetProperty("rol_id", out var ri) && ri.ValueKind != JsonValueKind.Null)
        {
            var rid = ri.ToString();
            if (rid == "1") return "Administrador";
            if (rid == "2") return "Residente";
        }
        
        return "Residente";
    }

    public async Task<List<ViviendaDto>> GetViviendasAsync()
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/vw_viviendas?select=*";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return new List<ViviendaDto>();

        var viviendas = await response.Content.ReadFromJsonAsync<List<ViviendaDto>>();
        return viviendas ?? new List<ViviendaDto>();
    }

    public async Task<ViviendaDto?> GetViviendaByIdAsync(int id)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/vw_viviendas?id=eq.{id}&select=*";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return null;

        var viviendas = await response.Content.ReadFromJsonAsync<List<ViviendaDto>>();
        return viviendas?.FirstOrDefault();
    }

    public async Task<(ViviendaDto? vivienda, string? error)> CreateViviendaAsync(CreateViviendaRequestDto dto)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/rpc/alta_vivienda";
        var payload = new
        {
            p_numero_casa = dto.NumeroCasa,
            p_tipo = dto.Tipo
        };

        var request = new HttpRequestMessage(HttpMethod.Post, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        request.Content = JsonContent.Create(payload);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            if (errorBody.Contains("23505") || errorBody.Contains("uq_viviendas_numero_casa") || errorBody.Contains("viviendas_numero_casa_key"))
                return (null, "Ya existe una vivienda registrada con ese número de casa");

            return (null, $"Error al crear vivienda: {errorBody}");
        }

        var result = await response.Content.ReadFromJsonAsync<ViviendaDto>();
        return (result, null);
    }

    public async Task<(ViviendaDto? vivienda, string? error)> UpdateViviendaAsync(int id, UpdateViviendaRequestDto dto)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/rpc/cambio_vivienda";
        var payload = new Dictionary<string, object> { { "p_id", id } };
        if (dto.NumeroCasa != null) payload["p_numero_casa"] = dto.NumeroCasa;
        if (dto.Tipo != null) payload["p_tipo"] = dto.Tipo;

        var request = new HttpRequestMessage(HttpMethod.Post, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        request.Content = JsonContent.Create(payload);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            if (errorBody.Contains("23505") || errorBody.Contains("uq_viviendas_numero_casa") || errorBody.Contains("viviendas_numero_casa_key"))
                return (null, "Ya existe una vivienda registrada con ese número de casa");

            return (null, $"Error al actualizar vivienda: {errorBody}");
        }

        var updated = await response.Content.ReadFromJsonAsync<ViviendaDto>();
        if (updated == null)
            return (null, "Vivienda no encontrada o no se pudo actualizar");

        return (updated, null);
    }

    public async Task<bool> DeleteViviendaAsync(int id)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/rpc/baja_vivienda";
        var payload = new { p_id = id };

        var request = new HttpRequestMessage(HttpMethod.Post, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        request.Content = JsonContent.Create(payload);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return false;

        var success = await response.Content.ReadFromJsonAsync<bool>();
        return success;
    }
}
