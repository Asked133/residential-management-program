using System.Net.Http.Headers;

namespace HavenApi.Shared.Http;

public abstract class BaseHttpClient
{
    protected readonly HttpClient HttpClient;

    protected BaseHttpClient(HttpClient httpClient)
    {
        HttpClient = httpClient;
    }

    protected void AddBearerToken(string token)
    {
        HttpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }
}
