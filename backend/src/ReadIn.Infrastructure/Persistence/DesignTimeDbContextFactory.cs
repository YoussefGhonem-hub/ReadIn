using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace ReadIn.Infrastructure.Persistence;

/// <summary>
/// Used by <c>dotnet ef</c> only, so migrations don't need to boot the API host.
/// <code>dotnet ef migrations add &lt;Name&gt; --project src/ReadIn.Infrastructure --output-dir Persistence/Migrations</code>
/// </summary>
internal sealed class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("READIN_DESIGN_CONNECTION")
            ?? "Server=localhost,14333;Database=ReadIn;User Id=sa;Password=ReadIn_Local_Dev_1;TrustServerCertificate=True;Encrypt=False";

        var options = new DbContextOptionsBuilder<AppDbContext>().UseSqlServer(connectionString).Options;
        return new AppDbContext(options);
    }
}
