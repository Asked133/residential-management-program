using System.Text.Json.Serialization;

namespace Usuarios.Api.DTOs;

public class UsuarioDto
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("nombre")]
    public string Nombre { get; set; } = string.Empty;

    [JsonPropertyName("apellidos")]
    public string Apellidos { get; set; } = string.Empty;

    [JsonPropertyName("telefono")]
    public string Telefono { get; set; } = string.Empty;

    [JsonPropertyName("rol")]
    public string Rol { get; set; } = string.Empty;

    [JsonPropertyName("role")]
    public string? Role { get; set; }

    [JsonPropertyName("role_id")]
    public object? RoleId { get; set; }

    [JsonPropertyName("rol_id")]
    public object? RolId { get; set; }

    [JsonIgnore]
    public string EffectiveRol
    {
        get
        {
            if (!string.IsNullOrWhiteSpace(Rol)) return Rol;
            if (!string.IsNullOrWhiteSpace(Role)) return Role;
            var id = (RoleId ?? RolId)?.ToString();
            if (id == "1") return "Administrador";
            if (id == "2") return "Residente";
            if (id == "3") return "Vigilante";
            return id ?? "Residente";
        }
    }

    [JsonPropertyName("creado_en")]
    public DateTime CreadoEn { get; set; }
}