using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Auth;
using ReadIn.Application.Features.Legal;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// The App Review account (SPEC §18.3, §32), from <c>Seed:ReviewerPhone</c> and <c>Seed:ReviewerPassword</c> (secrets);
/// nothing when either is unset. An account with that number is <b>adopted</b>: it becomes the review account, accepts the
/// current terms, nothing blocks its sign in (no forced password change or PIN screen), and its password is reset only when
/// it differs from the configured one; its profile, interests and content are never touched, and no second account is
/// made. Without one it is <b>created</b> ready to use: "ReadIn Demo" (<c>@readin_demo</c>, or a free variant), onboarding
/// done with 3 interests, terms accepted, and a recovery PIN (<c>Seed:ReviewerPin</c>, else random). Running it again
/// changes nothing. The review account is hidden from search, suggestions and the dashboard's counts.
/// </summary>
internal sealed class ReviewerAccountSeeder(
    AppDbContext db,
    IOptions<SeedOptions> options,
    IOptions<RecoveryOptions> recovery,
    IPasswordHasher passwords,
    IRecoveryPinHasher pins,
    TermsOfUse terms,
    TimeProvider clock) : ISeeder
{
    public const string DisplayName = "ReadIn Demo";
    public const string Username = "readin_demo";

    public string Name => "reviewer-account";
    public int Order => 4;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => true;

    /// <summary>
    /// Configured: a new value every time, so every seed run checks the account (a changed password applies at the next
    /// deploy; nothing derived from the password is ever stored). Unset: constant, so it doesn't run.
    /// </summary>
    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(
        Phone() is null || string.IsNullOrEmpty(options.Value.ReviewerPassword)
            ? SeedChecksum.Of(Version.ToString(), "not-configured")
            : SeedChecksum.Of(Version.ToString(), clock.GetUtcNow().UtcTicks.ToString(System.Globalization.CultureInfo.InvariantCulture)));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var phone = Phone();
        var password = options.Value.ReviewerPassword;
        if (phone is null || string.IsNullOrEmpty(password)) return true;

        var now = clock.GetUtcNow().UtcDateTime;
        var user = await db.Users.IgnoreQueryFilters().Include(u => u.Roles).Include(u => u.Interests)
            .FirstOrDefaultAsync(u => u.PhoneNumber == phone, cancellationToken);

        if (user is not null)
        {
            // Adopt: nothing of the person's account changes but what lets the reviewer sign in.
            var keepsPassword = user.PasswordHash is not null && passwords.Verify(user.PasswordHash, password) != PasswordCheck.Failed;
            user.AdoptAsReviewAccount(keepsPassword ? null : passwords.Hash(password));
            user.AcceptTerms(terms.CurrentVersion, now);
            if (!user.Roles.Any()) user.GrantRole(RoleIds.Member);
            await db.SaveChangesAsync(cancellationToken);
            return true;
        }

        user = User.Register(phone, passwords.Hash(password), PlaceholderUsername(), RoleIds.Member);
        db.Users.Add(user); // assigns the id the PIN hash is bound to
        user.SetRecoveryPin(pins.Hash(user.Id, Pin()), now);
        var profile = user.CompleteProfile(DisplayName, await FreeUsernameAsync(cancellationToken), avatarUrl: null);
        if (profile.IsFailure) throw new InvalidOperationException($"The review account's profile is invalid: {profile.Error.Code}");

        var fields = await db.Fields.AsNoTracking().Where(f => f.IsEnabled)
            .OrderBy(f => f.SortOrder).Select(f => f.Id).Take(User.MinInterests).ToListAsync(cancellationToken);
        if (fields.Count == User.MinInterests) user.SetInterests(fields, []);

        user.AdoptAsReviewAccount(passwordHash: null);
        user.AcceptTerms(terms.CurrentVersion, now);
        await db.SaveChangesAsync(cancellationToken);
        return true;
    }

    /// <summary>Replaced by the profile right after; random so it reveals nothing.</summary>
    private static string PlaceholderUsername() => "reader_" + RandomNumberGenerator.GetString("abcdefghijklmnopqrstuvwxyz0123456789", 10);

    private string? Phone() => PhoneNumberRules.TryNormalize(options.Value.ReviewerPhone, out var phone) ? phone : null;

    /// <summary><c>Seed:ReviewerPin</c> when it has the right digits, else a random one.</summary>
    private string Pin()
    {
        var length = recovery.Value.PinLength;
        var configured = RecoveryPinRules.Normalize(options.Value.ReviewerPin);
        return RecoveryPinRules.Check(configured, length).Count == 0
            ? configured
            : RandomNumberGenerator.GetString("0123456789", length);
    }

    /// <summary><c>readin_demo</c>, or <c>readin_demo2</c>… when someone has it.</summary>
    private async Task<string> FreeUsernameAsync(CancellationToken ct)
    {
        for (var n = 1; ; n++)
        {
            var candidate = n == 1 ? Username : $"{Username}{n}";
            if (!await db.Users.IgnoreQueryFilters().AnyAsync(u => u.Username == candidate, ct)) return candidate;
        }
    }
}
