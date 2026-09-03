using System.ComponentModel.DataAnnotations;

namespace Usuarios.Api.DTOs;

public class CompletarPerfilRequestDto
{
    [Required]
    public string Nombre { get; set; } = string.Empty;

    [Required]
    public string Apellidos { get; set; } = string.Empty;

    public string? Telefono { get; set; }
}
