using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Usuarios.Api.DTOs;

public class AsignarCondominioAdminRequestDto
{
    [Required]
    [JsonPropertyName("condominioId")]
    public Guid CondominioId { get; set; }
}
