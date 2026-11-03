using Microsoft.EntityFrameworkCore;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>Seed credentials (SPEC §18.1). Never committed: user-secrets locally, the host's secret store on servers.</summary>
public sealed class SeedOptions
{
    public const string Section = "Seed";

    /// <summary>Password of every demo user (Development/Testing).</summary>
    public string? DemoPassword { get; set; }

    /// <summary>Recovery PIN of the demo users that have one. Must pass the weak-PIN rules.</summary>
    public string? DemoPin { get; set; }

    /// <summary>Production SuperAdmin's number (E.164). Locally the SuperAdmin is <see cref="SystemUsers.LocalSuperAdminPhone"/>.</summary>
    public string? SuperAdminPhone { get; set; }

    /// <summary>Production SuperAdmin's first password; it must be changed on first sign in, then a PIN set.</summary>
    public string? SuperAdminPassword { get; set; }

    /// <summary>Run seeders on startup (Development/Staging). Production uses <c>dotnet run -- seed</c>.</summary>
    public bool RunOnStartup { get; set; }
}

public static class SystemUsers
{
    /// <summary>The official ReadIn account: author of the seeded articles; it cannot sign in.</summary>
    public static readonly Guid EditorialId = new("0195f3a0-0000-7000-8000-00000000e001");
    public static readonly Guid SuperAdminId = new("0195f3a0-0000-7000-8000-00000000e002");

    public const string OfficialPhone = "+201229391155";

    /// <summary>Fictional range +1 202 555 01XX (SPEC §18.3).</summary>
    public const string LocalSuperAdminPhone = "+12025550101";
}

internal static class SeedUserStore
{
    /// <summary>System accounts have fixed ids, so a later change of their number just updates the row.</summary>
    public static async Task<User> UpsertByIdAsync(AppDbContext db, Guid id, Func<User> create, CancellationToken ct)
    {
        var user = await Query(db).FirstOrDefaultAsync(u => u.Id == id, ct);
        if (user is not null) return user;

        user = create();
        db.Users.Add(user);
        return user;
    }

    /// <summary>
    /// Demo users are matched by number, or by @username in databases created before phone sign in (their number is
    /// assigned then). Soft-deleted ones are found too, so seeding never collides with them.
    /// </summary>
    public static async Task<User> UpsertAsync(AppDbContext db, string phoneNumber, string username, Func<User> create, CancellationToken ct)
    {
        var user = await Query(db).FirstOrDefaultAsync(u => u.PhoneNumber == phoneNumber, ct)
            ?? await Query(db).FirstOrDefaultAsync(u => u.Username == username, ct);
        if (user is not null)
        {
            if (user.PhoneNumber != phoneNumber) user.AssignSeedPhoneNumber(phoneNumber);
            return user;
        }

        user = create();
        db.Users.Add(user);
        return user;
    }

    private static IQueryable<User> Query(AppDbContext db) =>
        db.Users.IgnoreQueryFilters().Include(u => u.Roles).Include(u => u.Interests);
}
