using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Usuarios.Api.DTOs;

public class CompletarPerfilRequestDto
{
    [Required(ErrorMessage = "El nombre es obligatorio")]
    [MaxLength(100, ErrorMessage = "El nombre no puede exceder 100 caracteres")]
    [JsonPropertyName("nombre")]
    public string Nombre { get; set; } = string.Empty;

    [Required(ErrorMessage = "Los apellidos son obligatorios")]
    [MaxLength(100, ErrorMessage = "Los apellidos no pueden exceder 100 caracteres")]
    [JsonPropertyName("apellidos")]
    public string Apellidos { get; set; } = string.Empty;

    [Phone(ErrorMessage = "El formato del teléfono no es valido")]
    [MinLength(8, ErrorMessage = "El teléfono debe tener al menos 8 caracteres")]
    [MaxLength(20, ErrorMessage = "El teléfono no puede exceder 20 caracteres")]
    [JsonPropertyName("telefono")]
    public string? Telefono { get; set; }
}
