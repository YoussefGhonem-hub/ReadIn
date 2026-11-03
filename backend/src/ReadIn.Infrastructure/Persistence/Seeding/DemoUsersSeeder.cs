using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #4 (local only): the demo users of SPEC §18.3 in the fictional range +1 202 555 01XX, with realistic
/// mixed-language profiles, <c>Seed:DemoPassword</c> and, for those marked with a PIN, <c>Seed:DemoPin</c>. Locally the
/// SuperAdmin (+12025550101) gets the same credentials.
/// </summary>
internal sealed partial class DemoUsersSeeder(
    AppDbContext db,
    IPasswordHasher passwords,
    IRecoveryPinHasher pins,
    IOptions<SeedOptions> options,
    IOptions<RecoveryOptions> recovery,
    TimeProvider clock,
    ILogger<DemoUsersSeeder> logger) : ISeeder
{
    private sealed record DemoUser(
        string Phone,
        string Handle,
        string DisplayName,
        Guid[] Roles,
        string Bio,
        string[] Interests,
        string[]? ReviewerFields = null,
        bool Suspended = false,
        bool HasPin = true);

    private static readonly DemoUser[] Users =
    [
        new("+12025550102", "admin", "Admin User", [RoleIds.Admin], "بدير المحتوى والمجالات على ReadIn.", ["dotnet", "frontend", "software-architecture"]),
        new("+12025550103", "moderator", "Moderator User", [RoleIds.Moderator], "Moderator — بحافظ إن النقاش يفضل محترم ومفيد.", ["dotnet", "security", "devops-cloud"]),
        new("+12025550104", "reviewer.dotnet", ".NET Reviewer", [RoleIds.Member, RoleIds.VerifiedWriter, RoleIds.Reviewer],
            "Senior .NET engineer. براجع مقالات ASP.NET Core و Clean Architecture.", ["dotnet", "software-architecture", "databases"],
            ["dotnet", "software-architecture"]),
        new("+12025550105", "reviewer.ai", "AI Reviewer", [RoleIds.Member, RoleIds.VerifiedWriter, RoleIds.Reviewer],
            "ML engineer. بشتغل على LLMs و RAG، وبراجع مقالات الـ AI.", ["ai-fundamentals", "machine-learning", "claude-ai-tools"],
            ["ai-fundamentals", "machine-learning", "claude-ai-tools"]),
        new("+12025550106", "writer.verified", "Verified Writer", [RoleIds.Member, RoleIds.VerifiedWriter],
            "Flutter developer بكتب عن الـ mobile architecture.", ["mobile", "frontend", "software-architecture"]),
        new("+12025550107", "writer1", "Writer 1", [RoleIds.Member], "بكتب عن Angular و TypeScript.", ["frontend", "dotnet", "testing"]),
        new("+12025550108", "writer2", "Writer 2", [RoleIds.Member], "Backend developer — Node و .NET.", ["dotnet", "databases", "devops-cloud"]),
        new("+12025550109", "writer3", "Writer 3", [RoleIds.Member], "Data engineer مهتم بالـ SQL والـ performance.", ["databases", "machine-learning", "devops-cloud"]),
        .. Enumerable.Range(1, 10).Select(i => new DemoUser(
            $"+120255501{9 + i:D2}", $"reader{i}", $"Reader {i}", [RoleIds.Member],
            i % 2 == 0 ? "طالب هندسة حاسبات، بقرا مقال كل يوم 📚" : "Junior developer بيتعلم كل يوم حاجة جديدة.",
            ReaderInterests(i),
            HasPin: i != 10)), // reader10 tests the mandatory "set PIN" screen
        new("+12025550120", "suspended", "Suspended User", [RoleIds.Member], "Demo account for the suspended state.", ["dotnet", "frontend", "mobile"],
            Suspended: true, HasPin: false),
    ];

    public string Name => "demo-users";
    public int Order => 4;
    public int Version => 2;

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.AllowsDemoData(environment);

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(SeedChecksum.Of(
        [.. Users.Select(u => $"{u.Phone}|{u.Handle}|{u.DisplayName}|{string.Join(',', u.Roles)}|{u.Bio}|{string.Join(',', u.Interests)}|{u.Suspended}|{u.HasPin}"),
         (options.Value.DemoPassword is not null).ToString(),
         (options.Value.DemoPin is not null).ToString()]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var fieldIds = await db.Fields.AsNoTracking().ToDictionaryAsync(f => f.Slug, f => f.Id, cancellationToken);
        var (passwordHash, pin) = Credentials();
        var now = clock.GetUtcNow().UtcDateTime;

        foreach (var demo in Users)
        {
            var username = demo.Handle.Replace('.', '_');
            var user = await SeedUserStore.UpsertAsync(db, demo.Phone, username, () => User.CreateSeeded(
                demo.Phone, demo.DisplayName, username, email: $"{demo.Handle}@readin.test"), cancellationToken);

            user.UpdateProfile(demo.DisplayName, username, demo.Bio, AvatarFor(demo.Handle), new UserLinks { GitHub = $"https://github.com/{username}" });
            foreach (var role in demo.Roles) user.GrantRole(role);
            if (!demo.Roles.Contains(RoleIds.Member)) user.RevokeRole(RoleIds.Member);
            user.SetInterests([.. demo.Interests.Where(fieldIds.ContainsKey).Select(s => fieldIds[s])], []);
            if (demo.Suspended) user.Suspend(until: null);

            await db.SaveChangesAsync(cancellationToken); // assigns the id the PIN hash is bound to
            SetCredentials(user, passwordHash, demo.HasPin ? pin : null, now);

            foreach (var slug in demo.ReviewerFields ?? [])
            {
                if (fieldIds.TryGetValue(slug, out var fieldId) &&
                    !await db.ReviewerFields.AnyAsync(r => r.UserId == user.Id && r.FieldId == fieldId, cancellationToken))
                    db.ReviewerFields.Add(new ReviewerField(user.Id, fieldId));
            }
            await db.SaveChangesAsync(cancellationToken);
        }

        var superAdmin = await db.Users.FirstOrDefaultAsync(u => u.Id == SystemUsers.SuperAdminId, cancellationToken);
        if (superAdmin is not null)
        {
            SetCredentials(superAdmin, passwordHash, pin, now);
            await db.SaveChangesAsync(cancellationToken);
        }

        return true;
    }

    private (string? PasswordHash, string? Pin) Credentials()
    {
        var password = options.Value.DemoPassword;
        if (string.IsNullOrWhiteSpace(password))
        {
            LogNoPassword(logger);
            return (null, null);
        }

        var pin = RecoveryPinRules.Normalize(options.Value.DemoPin);
        if (pin.Length == 0)
        {
            LogNoPin(logger);
            return (passwords.Hash(password), null);
        }
        if (RecoveryPinRules.Check(pin, recovery.Value.PinLength, phoneNumberE164: null, password).Count > 0)
        {
            LogWeakPin(logger, recovery.Value.PinLength);
            return (passwords.Hash(password), null);
        }
        return (passwords.Hash(password), pin);
    }

    /// <summary>Accounts without a PIN must set one on the next sign in.</summary>
    private void SetCredentials(User user, string? passwordHash, string? pin, DateTime now)
    {
        if (passwordHash is not null) user.SetInitialPassword(passwordHash, mustChange: false);
        if (pin is not null) user.SetRecoveryPin(pins.Hash(user.Id, pin), now);
        else user.RequireRecoveryPin();
    }

    private static string[] ReaderInterests(int i)
    {
        string[] all = ["dotnet", "frontend", "mobile", "ai-fundamentals", "machine-learning", "databases", "devops-cloud", "software-architecture", "security"];
        return [all[i % all.Length], all[(i + 2) % all.Length], all[(i + 5) % all.Length]];
    }

    /// <summary>Deterministic placeholder avatar (no external personas).</summary>
    private static string AvatarFor(string handle) => $"https://api.dicebear.com/9.x/initials/svg?seed=demo-{handle.Replace('.', '-')}";

    [LoggerMessage(Level = LogLevel.Warning, Message = "Seed:DemoPassword is not set; demo users can't sign in. Set it with: dotnet user-secrets set \"Seed:DemoPassword\" \"<password>\" --project backend/src/ReadIn.Api")]
    private static partial void LogNoPassword(ILogger logger);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Seed:DemoPin is not set; demo users must set a recovery PIN on sign in. Set it with: dotnet user-secrets set \"Seed:DemoPin\" \"<pin>\" --project backend/src/ReadIn.Api")]
    private static partial void LogNoPin(ILogger logger);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Seed:DemoPin is not a valid {Length}-digit PIN or is too weak (SPEC §9.4); demo users must set a recovery PIN on sign in")]
    private static partial void LogWeakPin(ILogger logger, int length);
}
