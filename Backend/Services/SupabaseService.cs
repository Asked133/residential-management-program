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
        // Paso 1: Crear usuario en Supabase Auth
        var signupUrl = $"{_supabaseUrl}/auth/v1/signup";
        var signupPayload = new { email = datos.Email, password = datos.Password };

        var signupRequest = new HttpRequestMessage(HttpMethod.Post, signupUrl);
        signupRequest.Headers.Add("apikey", _anonKey);
        signupRequest.Content = JsonContent.Create(signupPayload);

        var signupResponse = await _httpClient.SendAsync(signupRequest);
        var signupBody = await signupResponse.Content.ReadAsStringAsync();

        if (!signupResponse.IsSuccessStatusCode)
        {
            if ((int)signupResponse.StatusCode == 422)
                return (null, "El email ya esta registrado");

            return (null, $"Error al crear cuenta en Auth: {signupBody}");
        }

        // Extraer el ID del usuario creado
        var signupJson = JsonDocument.Parse(signupBody);

        Guid userId;
        if (signupJson.RootElement.TryGetProperty("user", out var userElement)
            && userElement.TryGetProperty("id", out var idElement))
        {
            userId = Guid.Parse(idElement.GetString()!);
        }
        else if (signupJson.RootElement.TryGetProperty("id", out var directId))
        {
            userId = Guid.Parse(directId.GetString()!);
        }
        else
        {
            return (null, "No se pudo obtener el ID del usuario creado");
        }

        // Paso 2: Crear registro en la tabla 'usuarios'
        // rol_id = 2 corresponde a "Residente" en la tabla roles (#34)
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

            // Codigo 23505 = unique constraint violation (email o id duplicado)
            if (insertError.Contains("23505"))
                return (null, "El email ya esta registrado");

            return (null, $"Usuario creado en Auth pero fallo al insertar en tabla: {insertError}");
        }

        var created = await insertResponse.Content.ReadFromJsonAsync<List<UsuarioDto>>();
        return (created?.FirstOrDefault(), null);
    }

    public async Task<List<UsuarioDto>> GetResidentesAsync()
    {
        // rol_id = 2 corresponde a "Residente"
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
}