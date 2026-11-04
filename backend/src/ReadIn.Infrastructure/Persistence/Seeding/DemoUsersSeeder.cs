using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Auth;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Users;
using SkiaSharp;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #4 (local only): the demo users of SPEC §18.3 in the fictional range +1 202 555 01XX, with realistic
/// mixed-language profiles (F14: bio, links, 1–3 fields of expertise for writers, a square avatar drawn here and put
/// through the real image pipeline, public reading stats for about a third), <c>Seed:DemoPassword</c> and, for those
/// marked with a PIN, <c>Seed:DemoPin</c>. Locally the SuperAdmin (+12025550101) gets the same credentials.
/// </summary>
internal sealed partial class DemoUsersSeeder(
    AppDbContext db,
    IPasswordHasher passwords,
    IRecoveryPinHasher pins,
    IImageProcessor images,
    IFileStorage storage,
    UploadCleanup uploads,
    IOptions<SeedOptions> options,
    IOptions<RecoveryOptions> recovery,
    TimeProvider clock,
    ILogger<DemoUsersSeeder> logger) : ISeeder
{
    [Flags]
    private enum Link
    {
        GitHub = 1,
        LinkedIn = 2,
        Website = 4,
    }

    private sealed record DemoUser(
        string Phone,
        string Handle,
        string DisplayName,
        Guid[] Roles,
        string Bio,
        string[] Interests,
        bool Suspended = false,
        bool HasPin = true,
        string[]? Expertise = null,
        Link Links = Link.GitHub,
        bool PublicStats = false,
        bool Avatar = true);

    private static readonly DemoUser[] Users =
    [
        new("+12025550102", "admin", "Admin User", [RoleIds.Admin], "بدير المحتوى والمجالات على ReadIn.", ["dotnet", "frontend", "software-architecture"],
            Expertise: ["software-architecture"]),
        new("+12025550103", "moderator", "Moderator User", [RoleIds.Moderator], "Moderator — بحافظ إن النقاش يفضل محترم ومفيد.", ["dotnet", "security", "devops-cloud"],
            Expertise: ["security"]),
        // The handles (and so the usernames) predate ADR 0015, which removed reviewing; other demo seeders find users by them.
        new("+12025550104", "reviewer.dotnet", ".NET Writer", [RoleIds.Member, RoleIds.VerifiedWriter],
            "Senior .NET engineer. بكتب عن ASP.NET Core و Clean Architecture.", ["dotnet", "software-architecture", "databases"],
            Expertise: ["dotnet", "software-architecture", "databases"], Links: Link.GitHub | Link.LinkedIn | Link.Website, PublicStats: true),
        new("+12025550105", "reviewer.ai", "AI Writer", [RoleIds.Member, RoleIds.VerifiedWriter],
            "ML engineer. بشتغل على LLMs و RAG، وبكتب عن الـ AI.", ["ai-fundamentals", "machine-learning", "claude-ai-tools"],
            Expertise: ["machine-learning", "ai-fundamentals", "claude-ai-tools"], Links: Link.GitHub | Link.LinkedIn),
        new("+12025550106", "writer.verified", "Verified Writer", [RoleIds.Member, RoleIds.VerifiedWriter],
            "Flutter developer بكتب عن الـ mobile architecture.", ["mobile", "frontend", "software-architecture"],
            Expertise: ["mobile", "frontend"], Links: Link.GitHub | Link.Website, PublicStats: true),
        new("+12025550107", "writer1", "Writer 1", [RoleIds.Member], "بكتب عن Angular و TypeScript.", ["frontend", "dotnet", "testing"],
            Expertise: ["frontend"], Links: Link.GitHub | Link.LinkedIn),
        new("+12025550108", "writer2", "Writer 2", [RoleIds.Member], "Backend developer — Node و .NET.", ["dotnet", "databases", "devops-cloud"],
            Expertise: ["dotnet", "databases"], PublicStats: true),
        new("+12025550109", "writer3", "Writer 3", [RoleIds.Member], "Data engineer مهتم بالـ SQL والـ performance.", ["databases", "machine-learning", "devops-cloud"],
            Expertise: ["databases", "machine-learning"], Links: Link.GitHub | Link.LinkedIn | Link.Website),
        .. Enumerable.Range(1, 10).Select(i => new DemoUser(
            $"+120255501{9 + i:D2}", $"reader{i}", $"Reader {i}", [RoleIds.Member],
            i % 2 == 0 ? "طالب هندسة حاسبات، بقرا مقال كل يوم 📚" : "Junior developer بيتعلم كل يوم حاجة جديدة.",
            ReaderInterests(i),
            HasPin: i != 10, // reader10 tests the mandatory "set PIN" screen
            Expertise: i % 3 == 1 ? ReaderInterests(i)[..1] : null,
            PublicStats: i % 3 == 1, // reader1 (12-day streak), reader4, reader7
            Avatar: i != 10)),       // reader10 shows the initials fallback
        new("+12025550120", "suspended", "Suspended User", [RoleIds.Member], "Demo account for the suspended state.", ["dotnet", "frontend", "mobile"],
            Suspended: true, HasPin: false, Avatar: false),
    ];

    public string Name => "demo-users";
    public int Order => 4;
    public int Version => 4;

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.AllowsDemoData(environment);

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(SeedChecksum.Of(
        [.. Users.Select(u => $"{u.Phone}|{u.Handle}|{u.DisplayName}|{string.Join(',', u.Roles)}|{u.Bio}|{string.Join(',', u.Interests)}|{u.Suspended}|{u.HasPin}" +
                              $"|{string.Join(',', u.Expertise ?? [])}|{u.Links}|{u.PublicStats}|{u.Avatar}"),
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

            foreach (var role in demo.Roles) user.GrantRole(role);
            if (!demo.Roles.Contains(RoleIds.Member)) user.RevokeRole(RoleIds.Member);
            user.SetInterests([.. demo.Interests.Where(fieldIds.ContainsKey).Select(s => fieldIds[s])], []);
            user.SetExpertise([.. (demo.Expertise ?? []).Where(fieldIds.ContainsKey).Select(s => fieldIds[s])]);
            user.SetPrivacy(demo.PublicStats);
            if (demo.Suspended) user.Suspend(until: null);

            await db.SaveChangesAsync(cancellationToken); // assigns the id the PIN hash and the avatar's owner are bound to
            SetCredentials(user, passwordHash, demo.HasPin ? pin : null, now);

            var previousAvatar = user.AvatarUrl;
            var avatar = demo.Avatar ? await AvatarAsync(user, demo.Handle, now, cancellationToken) : null;
            user.UpdateProfile(demo.DisplayName, username, demo.Bio, avatar, LinksFor(username, demo.Links));

            await db.SaveChangesAsync(cancellationToken);
            if (previousAvatar != avatar) await uploads.ReleaseAsync(previousAvatar, cancellationToken);
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

    private static UserLinks LinksFor(string username, Link links) => new()
    {
        GitHub = links.HasFlag(Link.GitHub) ? $"https://github.com/{username}" : null,
        LinkedIn = links.HasFlag(Link.LinkedIn) ? $"https://www.linkedin.com/in/{username.Replace('_', '-')}" : null,
        Website = links.HasFlag(Link.Website) ? $"https://example.com/{username}" : null,
    };

    /// <summary>
    /// A deterministic avatar (no external personas, no network) through the same pipeline as a user upload: square
    /// WebP variants 64–512 owned by the user. Users.AvatarUrl gets the 256 variant, as PATCH /me stores it.
    /// </summary>
    private async Task<string?> AvatarAsync(User user, string handle, DateTime now, CancellationToken ct)
    {
        var bytes = DemoAvatars.Draw(handle);
        if (SeedImages.IsStored(user.AvatarUrl, bytes)) return user.AvatarUrl;

        var imported = await SeedImages.ImportAsync(images, storage, db, user.Id, UploadPurpose.Avatar, bytes, now, ct);
        return imported.IsSuccess ? SeedImages.Pick(imported.Value, Avatars.StoredWidth) : null;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Seed:DemoPassword is not set; demo users can't sign in. Set it with: dotnet user-secrets set \"Seed:DemoPassword\" \"<password>\" --project backend/src/ReadIn.Api")]
    private static partial void LogNoPassword(ILogger logger);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Seed:DemoPin is not set; demo users must set a recovery PIN on sign in. Set it with: dotnet user-secrets set \"Seed:DemoPin\" \"<pin>\" --project backend/src/ReadIn.Api")]
    private static partial void LogNoPin(ILogger logger);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Seed:DemoPin is not a valid {Length}-digit PIN or is too weak (SPEC §9.4); demo users must set a recovery PIN on sign in")]
    private static partial void LogWeakPin(ILogger logger, int length);
}

/// <summary>Demo avatars: a gradient with a mirrored 5 × 5 pattern derived from the handle. No text, so no font is needed.</summary>
internal static class DemoAvatars
{
    private const int Size = 512;
    private const int Cells = 5;
    private const int Cell = 72;
    private const int Margin = (Size - Cells * Cell) / 2;

    private static readonly (SKColor From, SKColor To)[] Palettes =
    [
        (new SKColor(0x0F, 0x5E, 0x52), new SKColor(0x3F, 0xB8, 0xA3)),
        (new SKColor(0xC0, 0x39, 0x2B), new SKColor(0xF2, 0xA9, 0x3B)),
        (new SKColor(0x1E, 0x25, 0x30), new SKColor(0x3F, 0xB8, 0xA3)),
        (new SKColor(0x51, 0x2B, 0xD4), new SKColor(0x9B, 0x7B, 0xF2)),
        (new SKColor(0x1F, 0x6F, 0xEB), new SKColor(0x6C, 0xC4, 0xFF)),
    ];

    /// <summary>A 512 × 512 PNG; the same handle always gives the same bytes on the same machine.</summary>
    public static byte[] Draw(string handle)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(handle));
        var (from, to) = Palettes[hash[0] % Palettes.Length];

        using var bitmap = new SKBitmap(Size, Size, SKColorType.Rgba8888, SKAlphaType.Premul);
        using (var canvas = new SKCanvas(bitmap))
        {
            using var shader = SKShader.CreateLinearGradient(new SKPoint(0, 0), new SKPoint(Size, Size), [from, to], SKShaderTileMode.Clamp);
            using var background = new SKPaint { Shader = shader };
            canvas.DrawRect(0, 0, Size, Size, background);

            using var ink = new SKPaint { Color = new SKColor(0xFF, 0xFF, 0xFF, 0xD8), IsAntialias = true };
            for (var row = 0; row < Cells; row++)
            {
                for (var column = 0; column <= Cells / 2; column++)
                {
                    if ((hash[1 + row * 3 + column] & 1) == 0) continue;
                    DrawCell(column);
                    if (column != Cells / 2) DrawCell(Cells - 1 - column); // mirrored

                    void DrawCell(int x) => canvas.DrawRoundRect(Margin + x * Cell + 4, Margin + row * Cell + 4, Cell - 8, Cell - 8, 12, 12, ink);
                }
            }
        }

        using var data = bitmap.Encode(SKEncodedImageFormat.Png, 100);
        return data.ToArray();
    }
}
