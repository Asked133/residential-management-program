using System.Net.Http.Headers;
using System.Text.Json;
using Usuarios.Api.DTOs;

namespace Usuarios.Api.Services;

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

    public async Task<UsuarioDto?> GetUsuarioByIdAsync(Guid userId, string accessToken, Guid actorId)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/vw_usuarios?id=eq.{userId}&select=*";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Add("apikey", _anonKey);
        request.Headers.Add("x-actor-id", actorId.ToString());
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

    public async Task<(UsuarioDto? usuario, string? error)> RegisterAdminAsync(RegisterRequestDto datos, Guid? actorId = null)
    {
        var signupUrl = $"{_supabaseUrl}/auth/v1/admin/users";
        var signupPayload = new { email = datos.Email, password = datos.Password, email_confirm = true };

        var signupRequest = new HttpRequestMessage(HttpMethod.Post, signupUrl);
        signupRequest.Headers.Add("apikey", _serviceRoleKey);
        if (actorId.HasValue) signupRequest.Headers.Add("x-actor-id", actorId.Value.ToString());
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

        var insertUrl = $"{_supabaseUrl}/rest/v1/rpc/alta_usuario";
        var insertPayload = new
        {
            p_id = userId,
            p_rol_id = 1,
            p_email = datos.Email,
            p_nombre = datos.Nombre,
            p_apellidos = datos.Apellidos,
            p_telefono = datos.Telefono
        };

        var insertRequest = new HttpRequestMessage(HttpMethod.Post, insertUrl);
        insertRequest.Headers.Add("apikey", _serviceRoleKey);
        if (actorId.HasValue) insertRequest.Headers.Add("x-actor-id", actorId.Value.ToString());
        insertRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);
        insertRequest.Content = JsonContent.Create(insertPayload);

        var insertResponse = await _httpClient.SendAsync(insertRequest);

        if (!insertResponse.IsSuccessStatusCode)
        {
            var insertError = await insertResponse.Content.ReadAsStringAsync();

            if (insertError.Contains("23505"))
                return (null, "El email ya esta registrado");

            return (null, $"Usuario creado en Auth pero fallo al insertar en tabla: {insertError}");
        }

        var created = await insertResponse.Content.ReadFromJsonAsync<UsuarioDto>();
        return (created, null);
    }

    public async Task<(UsuarioDto? usuario, string? error)> CompletarPerfilAsync(Guid userId, CompletarPerfilRequestDto datos, string accessToken, Guid actorId)
    {
        var url = $"{_supabaseUrl}/rest/v1/rpc/cambio_usuario";
        var payload = new
        {
            p_id = userId,
            p_nombre = datos.Nombre,
            p_apellidos = datos.Apellidos,
            p_telefono = datos.Telefono
        };

        var request = new HttpRequestMessage(HttpMethod.Post, url);
        request.Headers.Add("apikey", _anonKey);
        request.Headers.Add("x-actor-id", actorId.ToString());
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        request.Content = JsonContent.Create(payload);

        var response = await _httpClient.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            return (null, $"Error al completar perfil: {errorBody}");
        }

        var updated = await response.Content.ReadFromJsonAsync<UsuarioDto>();
        return (updated, null);
    }

    public async Task<List<UsuarioDto>> GetResidentesAsync(Guid actorId)
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/vw_usuarios?rol_id=eq.2&select=*";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Add("x-actor-id", actorId.ToString());
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);

        var response = await _httpClient.SendAsync(request);

        if (!response.IsSuccessStatusCode)
            return new List<UsuarioDto>();

        var residentes = await response.Content.ReadFromJsonAsync<List<UsuarioDto>>();
        return residentes ?? new List<UsuarioDto>();
    }
}