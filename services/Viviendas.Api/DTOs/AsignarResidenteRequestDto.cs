using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Viviendas.Api.DTOs;

public class AsignarResidenteRequestDto
{
    [Required]
    [JsonPropertyName("usuarioId")]
    public Guid UsuarioId { get; set; }
}
