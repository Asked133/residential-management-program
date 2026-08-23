using System.Text.Json.Serialization;

namespace HavenApi.DTOs;

public class UsuarioDto
{
    //Identificador único del usuario (UUID de Supabase).
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    //Correo electrónico.
    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    //Nombre del usuario.
    [JsonPropertyName("nombre")]
    public string Nombre { get; set; } = string.Empty;

    //Apellidos del usuario.
    [JsonPropertyName("apellidos")]
    public string Apellidos { get; set; } = string.Empty;

    //Teléfono de contacto.
    [JsonPropertyName("telefono")]
    public string Telefono { get; set; } = string.Empty;

    //Rol base (texto).
    [JsonPropertyName("rol")]
    public string Rol { get; set; } = string.Empty;

    [JsonPropertyName("role")]
    public string? Role { get; set; }

    [JsonPropertyName("role_id")]
    public object? RoleId { get; set; }

    [JsonPropertyName("rol_id")]
    public object? RolId { get; set; }

    //Rol efectivo derivado de los campos de rol disponibles.
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

    //Fecha y hora de creación del registro.
    [JsonPropertyName("creado_en")]
    public DateTime CreadoEn { get; set; }
}