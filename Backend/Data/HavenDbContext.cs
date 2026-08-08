using Microsoft.EntityFrameworkCore;

namespace HavenApi.Data;

//El proveedor se configura externamente en Program.cs mediante inyección de dependencias.
public class HavenDbContext : DbContext
{
    public HavenDbContext(DbContextOptions<HavenDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
    }
}
