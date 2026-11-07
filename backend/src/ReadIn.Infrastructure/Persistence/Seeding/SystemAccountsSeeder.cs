using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #3 (all environments): the official ReadIn account (author of seeded articles, cannot sign in; a Member with the
/// Verified badge, its headline "مقال كل يوم يفرق معاك" and no links) and the SuperAdmin (only the SuperAdmin role). In
/// production the SuperAdmin gets <c>Seed:SuperAdminPhone</c> + <c>Seed:SuperAdminPassword</c>, must change the password on
/// first sign in and then set a recovery PIN (SPEC §18.3).
/// </summary>
internal sealed class SystemAccountsSeeder(
    AppDbContext db,
    IPasswordHasher passwords,
    IOptions<SeedOptions> options,
    IHostEnvironment environment,
    TimeProvider clock) : ISeeder
{
    private const string OfficialBio = "الحساب الرسمي لمنصة ReadIn. مقالات منظمة وموثوقة في البرمجة والذكاء الاصطناعي، بالعربي والإنجليزي.";

    /// <summary>@readin's title under its name on cards and the reader (SPEC F14), in every environment.</summary>
    internal const string OfficialHeadline = "مقال كل يوم يفرق معاك";

    /// <summary>@readin's links: none (it has no social accounts; the seed decides them, nobody edits them by hand).</summary>
    internal static readonly IReadOnlyList<ProfileLink> OfficialLinks = [];

    public string Name => "system-accounts";
    public int Order => 3;
    public int Version => 4; // 4: @readin's headline, and its links set explicitly in the new shape

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(SeedChecksum.Of(
        Version.ToString(),
        SystemUsers.OfficialPhone,
        OfficialBio,
        OfficialHeadline,
        string.Join(' ', OfficialLinks.Select(l => $"{l.Platform}={l.Url}|{l.Label}")),
        SuperAdminPhone() ?? string.Empty,
        (options.Value.SuperAdminPassword is not null).ToString()));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var official = await SeedUserStore.UpsertByIdAsync(db, SystemUsers.EditorialId, () => User.CreateSeeded(
            SystemUsers.OfficialPhone, "ReadIn", "readin", SystemUsers.EditorialId, systemAccount: true), cancellationToken);
        if (official.PhoneNumber != SystemUsers.OfficialPhone) official.AssignSeedPhoneNumber(SystemUsers.OfficialPhone);
        // The avatar is set by its own seeder from content/assets; keep it.
        Ensure(official.UpdateProfile("ReadIn", "readin", OfficialBio, official.AvatarUrl), "profile");
        Ensure(official.SetHeadline(OfficialHeadline), "headline");
        Ensure(official.SetLinks(OfficialLinks), "links");
        official.GrantRole(RoleIds.Member);
        official.Verify(clock.GetUtcNow().UtcDateTime); // the badge, not a role (SPEC §10.1)

        var phone = SuperAdminPhone();
        if (phone == SystemUsers.OfficialPhone)
            throw new InvalidOperationException("Seed:SuperAdminPhone is @readin's number; give the SuperAdmin another one.");

        // Save @readin's number first: when it moves, the SuperAdmin may take the number it gave up, and the unique index
        // on Users.PhoneNumber must never see one number on both rows.
        await db.SaveChangesAsync(cancellationToken);

        var superAdmin = await SeedUserStore.UpsertByIdAsync(db, SystemUsers.SuperAdminId, () => User.CreateSeeded(
            phone, "Super Admin", "superadmin", SystemUsers.SuperAdminId, systemAccount: true), cancellationToken);
        if (phone is not null && superAdmin.PhoneNumber != phone) superAdmin.AssignSeedPhoneNumber(phone);
        superAdmin.GrantRole(RoleIds.SuperAdmin);

        // Production: a first password only, never overwriting one the SuperAdmin already changed. Locally the demo
        // seeder gives the SuperAdmin the demo password and PIN.
        var password = options.Value.SuperAdminPassword;
        if (!SeedEnvironments.AllowsDemoData(environment) && superAdmin.PasswordHash is null && !string.IsNullOrWhiteSpace(password))
        {
            superAdmin.SetInitialPassword(passwords.Hash(password), mustChange: true);
            superAdmin.RequireRecoveryPin();
        }

        await db.SaveChangesAsync(cancellationToken);
        return true;
    }

    /// <summary>Seed data that breaks a profile rule is a bug: it stops the start with a clear error (SPEC §18.1).</summary>
    private static void Ensure(Result result, string part)
    {
        if (result.IsFailure)
            throw new InvalidOperationException($"The official account's seeded {part} is invalid: {result.Error.Code}");
    }

    private string? SuperAdminPhone()
    {
        if (PhoneNumberRules.TryNormalize(options.Value.SuperAdminPhone, out var configured)) return configured;
        return SeedEnvironments.AllowsDemoData(environment) ? SystemUsers.LocalSuperAdminPhone : null;
    }
}
