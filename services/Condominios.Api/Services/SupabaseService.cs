using System.Net.Http.Headers;
using System.Text.Json;
using Condominios.Api.DTOs;
using HavenApi.Shared.Exceptions;

namespace Condominios.Api.Services;

public class SupabaseService : ISupabaseService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<SupabaseService> _logger;
    private readonly string _supabaseUrl;
    private readonly string _anonKey;
    private readonly string _serviceRoleKey;

    public SupabaseService(HttpClient httpClient, IConfiguration configuration, ILogger<SupabaseService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _supabaseUrl = configuration["Supabase:Url"] ?? throw new InvalidOperationException("Supabase:Url is not configured.");
        _anonKey = configuration["Supabase:AnonKey"] ?? throw new InvalidOperationException("Supabase:AnonKey is not configured.");
        _serviceRoleKey = configuration["Supabase:ServiceRoleKey"] ?? throw new InvalidOperationException("Supabase:ServiceRoleKey is not configured.");
    }

    private async Task<HttpResponseMessage> SendRequestAsync(HttpRequestMessage request)
    {
        try
        {
            return await _httpClient.SendAsync(request);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Network error when calling Supabase at {Url}", request.RequestUri);
            throw new SupabaseUnavailableException("A network error occurred while communicating with Supabase.", ex);
        }
        catch (TaskCanceledException ex)
        {
            _logger.LogError(ex, "Timeout when calling Supabase at {Url}", request.RequestUri);
            throw new SupabaseUnavailableException("The request to Supabase timed out.", ex);
        }
    }

    private async Task<T?> ParseJsonAsync<T>(HttpContent content)
    {
        try
        {
            return await content.ReadFromJsonAsync<T>();
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Failed to parse JSON response from Supabase.");
            throw new SupabaseResponseException("Received an invalid JSON response from Supabase.", ex);
        }
    }

    public async Task<List<CondominioDto>> GetCondominiosAsync()
    {
        var requestUrl = $"{_supabaseUrl}/rest/v1/vw_condominios?select=*";

        var request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Add("apikey", _serviceRoleKey);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _serviceRoleKey);

        var response = await SendRequestAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning("Failed to fetch condominios. Status: {StatusCode}", response.StatusCode);
            return new List<CondominioDto>();
        }

        var condominios = await ParseJsonAsync<List<CondominioDto>>(response.Content);
        return condominios ?? new List<CondominioDto>();
    }
}
