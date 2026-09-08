using System.Text.Json.Serialization;

namespace Viviendas.Api.DTOs;

public class MiViviendaDto
{
    [JsonPropertyName("vivienda_id")]
    public int ViviendaId { get; set; }

    [JsonPropertyName("numero_casa")]
    public string NumeroCasa { get; set; } = string.Empty;

    [JsonPropertyName("tipo")]
    public string? Tipo { get; set; }

    [JsonPropertyName("activo")]
    public bool Activo { get; set; }

    [JsonPropertyName("creado_en")]
    public DateTime CreadoEn { get; set; }
}
