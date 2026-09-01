using System.Text.Json.Serialization;

namespace HavenApi.DTOs;

public class ViviendaDto
{
    [JsonPropertyName("id")]
    public int Id { get; set; }

    [JsonPropertyName("numero_casa")]
    public string NumeroCasa { get; set; } = string.Empty;

    [JsonPropertyName("tipo")]
    public string? Tipo { get; set; }

    [JsonPropertyName("creado_en")]
    public DateTime CreadoEn { get; set; }
}
