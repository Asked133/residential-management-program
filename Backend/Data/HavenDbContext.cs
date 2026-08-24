using Microsoft.EntityFrameworkCore;

namespace HavenApi.Data;

public class HavenDbContext : DbContext
{
    public HavenDbContext(DbContextOptions<HavenDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
    }
}
