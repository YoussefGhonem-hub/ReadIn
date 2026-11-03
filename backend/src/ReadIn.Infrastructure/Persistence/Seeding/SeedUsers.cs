using Microsoft.EntityFrameworkCore;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Seeding;

public sealed class SeedOptions
{
    public const string Section = "Seed";

    /// <summary>Password for demo users (Dev/Staging). Never committed: user-secrets or a secret store (SPEC §18.1).</summary>
    public string? DemoPassword { get; set; }

    /// <summary>Initial SuperAdmin password; must be changed on first login.</summary>
    public string? SuperAdminPassword { get; set; }

    /// <summary>Run seeders on startup (Development/Staging). Production uses <c>dotnet run -- seed</c>.</summary>
    public bool RunOnStartup { get; set; }
}

public static class SystemUsers
{
    public static readonly Guid EditorialId = new("0195f3a0-0000-7000-8000-00000000e001");
    public static readonly Guid SuperAdminId = new("0195f3a0-0000-7000-8000-00000000e002");

    public const string EditorialEmail = "editorial@readin.test";
    public const string SuperAdminEmail = "superadmin@readin.test";
}

internal static class SeedUserStore
{
    /// <summary>Finds a user by email (including soft-deleted ones) or creates it via <paramref name="create"/>.</summary>
    public static async Task<User> UpsertAsync(AppDbContext db, string email, Func<User> create, CancellationToken ct)
    {
        var user = await db.Users.IgnoreQueryFilters()
            .Include(u => u.Roles)
            .Include(u => u.Interests)
            .FirstOrDefaultAsync(u => u.Email == email, ct);
        if (user is not null) return user;

        user = create();
        db.Users.Add(user);
        return user;
    }
}
