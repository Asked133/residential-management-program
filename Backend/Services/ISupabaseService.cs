using HavenApi.DTOs;

namespace HavenApi.Services;

// Interfaz para desacoplar la lógica de negocio del proveedor.
// Si en el futuro cambian de Supabase a otro servicio, solo se
// reemplaza la implementación, no los controladores.
public interface ISupabaseService
{
    Task<UsuarioDto?> GetUsuarioByIdAsync(Guid userId, string accessToken);
}
