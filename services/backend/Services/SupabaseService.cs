using System.Net.Http.Headers;
using System.Text.Json;
using HavenApi.DTOs;

namespace HavenApi.Services;

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

    public async Task<UsuarioDto?> GetUsuarioByIdAsync(Guid userId, string accessToken)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/usuarios?id=eq.{userId}&select=*";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Add("apikey", _anonKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return null;

        var usuarios = await response.Content.ReadFromJsonAsync<List<UsuarioDto>>();
        return usuarios?.FirstOrDefault();
    }

    public async Task<string?> GetDbVersionAsync()
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/version?select=numero_version&order=numero_version.desc&limit=1";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Add("apikey", _anonKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _anonKey);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return null;

        var records = await response.Content.ReadFromJsonAsync<List<Dictionary<string, object>>>();
        var version = records?.FirstOrDefault()?["numero_version"]?.ToString();

        return version;
    }

    public async Task<(UsuarioDto? usuario, string? error)> RegisterUsuarioAsync(RegisterRequestDto datos)
    {
        var signupUrl = $"{_supabaseUrl}/auth/v1/admin/users";
        var signupPayload = new { email = datos.Email, password = datos.Password, email_confirm = true };

        var signupRequest = new HttpRequestMessage(HttpMethod.Post, signupUrl);
        signupRequest.Headers.Add("apikey", _serviceRoleKey);
        signupRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        signupRequest.Content = JsonContent.Create(signupPayload);

        var signupResponse = await _httpClient.SendAsync(signupRequest);
        var signupBody = await signupResponse.Content.ReadAsStringAsync();

        if (!signupResponse.IsSuccessStatusCode)
        {
            if ((int)signupResponse.StatusCode == 422 || signupBody.Contains("already been registered"))
                return (null, "El email ya esta registrado");

            return (null, $"Error al crear cuenta en Auth: {signupBody}");
        }

        var signupJson = JsonDocument.Parse(signupBody);

        Guid userId;
        if (signupJson.RootElement.TryGetProperty("id", out var directId))
        {
            userId = Guid.Parse(directId.GetString()!);
        }
        else
        {
            return (null, "No se pudo obtener el ID del usuario creado");
        }

        var insertUrl = $"{_supabaseUrl}/rest/v1/usuarios";
        var insertPayload = new
        {
            id = userId,
            rol_id = 2,
            email = datos.Email,
            nombre = datos.Nombre,
            apellidos = datos.Apellidos,
            telefono = datos.Telefono
        };

        var insertRequest = new HttpRequestMessage(HttpMethod.Post, insertUrl);
        insertRequest.Headers.Add("apikey", _serviceRoleKey);
        insertRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        insertRequest.Headers.Add("Prefer", "return=representation");
        insertRequest.Content = JsonContent.Create(insertPayload);

        var insertResponse = await _httpClient.SendAsync(insertRequest);

        if (!insertResponse.IsSuccessStatusCode)
        {
            var insertError = await insertResponse.Content.ReadAsStringAsync();

            if (insertError.Contains("23505"))
                return (null, "El email ya esta registrado");

            return (null, $"Usuario creado en Auth pero fallo al insertar en tabla: {insertError}");
        }

        var created = await insertResponse.Content.ReadFromJsonAsync<List<UsuarioDto>>();
        return (created?.FirstOrDefault(), null);
    }

    public async Task<List<UsuarioDto>> GetResidentesAsync()
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/usuarios?rol_id=eq.2&select=*";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return new List<UsuarioDto>();

        var residentes = await response.Content.ReadFromJsonAsync<List<UsuarioDto>>();
        return residentes ?? new List<UsuarioDto>();
    }

    public async Task<List<ViviendaDto>> GetViviendasAsync()
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/viviendas?select=*";

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
        var requestUrl = $"{_supabaseUrl}/rest/v1/viviendas?id=eq.{id}&select=*";

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
        var requestUrl = $"{_supabaseUrl}/rest/v1/viviendas";
        var payload = new
        {
            numero_casa = dto.NumeroCasa,
            tipo = dto.Tipo
        };

        var request = new HttpRequestMessage(HttpMethod.Post, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        request.Headers.Add("Prefer", "return=representation");
        request.Content = JsonContent.Create(payload);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            if (errorBody.Contains("23505") || errorBody.Contains("uq_viviendas_numero_casa"))
                return (null, "Ya existe una vivienda registrada con ese número de casa");

            return (null, $"Error al crear vivienda: {errorBody}");
        }

        var result = await response.Content.ReadFromJsonAsync<List<ViviendaDto>>();
        return (result?.FirstOrDefault(), null);
    }

    public async Task<(ViviendaDto? vivienda, string? error)> UpdateViviendaAsync(int id, UpdateViviendaRequestDto dto)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/viviendas?id=eq.{id}";
        
        var payload = new Dictionary<string, object>();
        if (dto.NumeroCasa != null) payload["numero_casa"] = dto.NumeroCasa;
        if (dto.Tipo != null) payload["tipo"] = dto.Tipo;

        var request = new HttpRequestMessage(HttpMethod.Patch, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        request.Headers.Add("Prefer", "return=representation");
        request.Content = JsonContent.Create(payload);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            if (errorBody.Contains("23505") || errorBody.Contains("uq_viviendas_numero_casa"))
                return (null, "Ya existe una vivienda registrada con ese número de casa");

            return (null, $"Error al actualizar vivienda: {errorBody}");
        }

        var result = await response.Content.ReadFromJsonAsync<List<ViviendaDto>>();
        var updated = result?.FirstOrDefault();
        if (updated == null)
            return (null, "Vivienda no encontrada o no se pudo actualizar");

        return (updated, null);
    }

    public async Task<bool> DeleteViviendaAsync(int id)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/viviendas?id=eq.{id}";

        var request = new HttpRequestMessage(HttpMethod.Delete, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        request.Headers.Add("Prefer", "return=representation");

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return false;

        var deleted = await response.Content.ReadFromJsonAsync<List<ViviendaDto>>();
        return deleted != null && deleted.Count > 0;
    }
}