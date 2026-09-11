using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Condominios.Api.DTOs;

public class UpdateCondominioRequestDto
{
    [MaxLength(150, ErrorMessage = "El nombre no puede exceder 150 caracteres")]
    [JsonPropertyName("nombre")]
    public string? Nombre { get; set; }
}
