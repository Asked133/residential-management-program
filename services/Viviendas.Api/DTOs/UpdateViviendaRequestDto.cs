using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Viviendas.Api.DTOs;

public class UpdateViviendaRequestDto
{
    [MaxLength(50, ErrorMessage = "El numero de casa no puede exceder 50 caracteres")]
    [JsonPropertyName("numeroCasa")]
    public string? NumeroCasa { get; set; }

    [MaxLength(20, ErrorMessage = "El tipo no puede exceder 20 caracteres")]
    [JsonPropertyName("tipo")]
    public string? Tipo { get; set; }
}
