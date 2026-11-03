using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #4 (Development/Staging only): demo users from SPEC §18.3, created in Firebase Auth (emulator
/// locally) with deterministic uids and in SQL Server with realistic mixed-language profiles.
/// </summary>
internal sealed partial class DemoUsersSeeder(
    AppDbContext db,
    IIdentityProvisioner identity,
    IOptions<SeedOptions> options,
    ILogger<DemoUsersSeeder> logger) : ISeeder
{
    private sealed record DemoUser(
        string LocalPart,
        string DisplayName,
        Guid[] Roles,
        string Bio,
        string[] Interests,
        string[]? ReviewerFields = null,
        bool Suspended = false);

    private static readonly DemoUser[] Users =
    [
        new("admin", "Admin User", [RoleIds.Admin], "بدير المحتوى والمجالات على ReadIn.", ["dotnet", "frontend", "software-architecture"]),
        new("moderator", "Moderator User", [RoleIds.Moderator], "Moderator — بحافظ إن النقاش يفضل محترم ومفيد.", ["dotnet", "security", "devops-cloud"]),
        new("reviewer.dotnet", ".NET Reviewer", [RoleIds.Member, RoleIds.VerifiedWriter, RoleIds.Reviewer],
            "Senior .NET engineer. براجع مقالات ASP.NET Core و Clean Architecture.", ["dotnet", "software-architecture", "databases"],
            ["dotnet", "software-architecture"]),
        new("reviewer.ai", "AI Reviewer", [RoleIds.Member, RoleIds.VerifiedWriter, RoleIds.Reviewer],
            "ML engineer. بشتغل على LLMs و RAG، وبراجع مقالات الـ AI.", ["ai-fundamentals", "machine-learning", "claude-ai-tools"],
            ["ai-fundamentals", "machine-learning", "claude-ai-tools"]),
        new("writer.verified", "Verified Writer", [RoleIds.Member, RoleIds.VerifiedWriter],
            "Flutter developer بكتب عن الـ mobile architecture.", ["mobile", "frontend", "software-architecture"]),
        new("writer1", "Writer 1", [RoleIds.Member], "بكتب عن Angular و TypeScript.", ["frontend", "dotnet", "testing"]),
        new("writer2", "Writer 2", [RoleIds.Member], "Backend developer — Node و .NET.", ["dotnet", "databases", "devops-cloud"]),
        new("writer3", "Writer 3", [RoleIds.Member], "Data engineer مهتم بالـ SQL والـ performance.", ["databases", "machine-learning", "devops-cloud"]),
        .. Enumerable.Range(1, 10).Select(i => new DemoUser(
            $"reader{i}", $"Reader {i}", [RoleIds.Member],
            i % 2 == 0 ? "طالب هندسة حاسبات، بقرا مقال كل يوم 📚" : "Junior developer بيتعلم كل يوم حاجة جديدة.",
            ReaderInterests(i))),
        new("suspended", "Suspended User", [RoleIds.Member], "Demo account for the suspended state.", ["dotnet", "frontend", "mobile"], Suspended: true),
    ];

    public string Name => "demo-users";
    public int Order => 4;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.IsDevOrStaging(environment);

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(SeedChecksum.Of(
        [.. Users.Select(u => $"{u.LocalPart}|{u.DisplayName}|{string.Join(',', u.Roles)}|{u.Bio}|{string.Join(',', u.Interests)}|{u.Suspended}"),
         (options.Value.DemoPassword is not null).ToString()]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var fieldIds = await db.Fields.AsNoTracking().ToDictionaryAsync(f => f.Slug, f => f.Id, cancellationToken);
        var password = options.Value.DemoPassword;
        if (string.IsNullOrWhiteSpace(password)) LogNoPassword(logger);

        var complete = true;
        foreach (var demo in Users)
        {
            var email = $"{demo.LocalPart}@readin.test";
            var uid = $"demo-{demo.LocalPart.Replace('.', '-')}";
            var username = User.SuggestUsername(demo.LocalPart);

            var user = await SeedUserStore.UpsertAsync(db, email, () => User.Register(
                uid, email, demo.DisplayName, username, avatarUrl: null, RoleIds.Member, "ar", "Africa/Cairo"), cancellationToken);

            user.UpdateProfile(demo.DisplayName, username, demo.Bio, AvatarFor(uid), new UserLinks { GitHub = $"https://github.com/{username}" });
            foreach (var role in demo.Roles) user.GrantRole(role);
            if (!demo.Roles.Contains(RoleIds.Member)) user.RevokeRole(RoleIds.Member);
            user.SetInterests([.. demo.Interests.Where(fieldIds.ContainsKey).Select(s => fieldIds[s])], []);
            if (demo.Suspended) user.Suspend(until: null);

            await db.SaveChangesAsync(cancellationToken);

            foreach (var slug in demo.ReviewerFields ?? [])
            {
                if (fieldIds.TryGetValue(slug, out var fieldId) &&
                    !await db.ReviewerFields.AnyAsync(r => r.UserId == user.Id && r.FieldId == fieldId, cancellationToken))
                    db.ReviewerFields.Add(new ReviewerField(user.Id, fieldId));
            }
            await db.SaveChangesAsync(cancellationToken);

            if (!string.IsNullOrWhiteSpace(password))
                complete &= await identity.EnsureUserAsync(uid, email, demo.DisplayName, password, disabled: false, cancellationToken);
        }

        return complete;
    }

    private static string[] ReaderInterests(int i)
    {
        string[] all = ["dotnet", "frontend", "mobile", "ai-fundamentals", "machine-learning", "databases", "devops-cloud", "software-architecture", "security"];
        return [all[i % all.Length], all[(i + 2) % all.Length], all[(i + 5) % all.Length]];
    }

    /// <summary>Deterministic placeholder avatar (no external personas).</summary>
    private static string AvatarFor(string uid) => $"https://api.dicebear.com/9.x/initials/svg?seed={uid}";

    [LoggerMessage(Level = LogLevel.Warning, Message = "Seed:DemoPassword is not set; demo users are created in SQL Server only and cannot sign in. Set it with: dotnet user-secrets set \"Seed:DemoPassword\" \"<password>\" --project backend/src/ReadIn.Api")]
    private static partial void LogNoPassword(ILogger logger);
}
