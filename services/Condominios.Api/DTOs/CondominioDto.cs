using System.Text.Json.Serialization;

namespace Condominios.Api.DTOs;

public class CondominioDto
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("nombre")]
    public string Nombre { get; set; } = string.Empty;

    [JsonPropertyName("activo")]
    public bool Activo { get; set; }

    [JsonPropertyName("creado_en")]
    public DateTime CreadoEn { get; set; }
}
