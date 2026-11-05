using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Users;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #3 (all environments): the official ReadIn account (author of seeded articles, cannot sign in; a Member with the
/// Verified badge) and the SuperAdmin (only the SuperAdmin role). In production the SuperAdmin gets <c>Seed:SuperAdminPhone</c> + <c>Seed:SuperAdminPassword</c>, must change
/// the password on first sign in and then set a recovery PIN (SPEC §18.3).
/// </summary>
internal sealed class SystemAccountsSeeder(
    AppDbContext db,
    IPasswordHasher passwords,
    IOptions<SeedOptions> options,
    IHostEnvironment environment,
    TimeProvider clock) : ISeeder
{
    private const string OfficialBio = "الحساب الرسمي لمنصة ReadIn. مقالات منظمة وموثوقة في البرمجة والذكاء الاصطناعي، بالعربي والإنجليزي.";

    public string Name => "system-accounts";
    public int Order => 3;
    public int Version => 3;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(SeedChecksum.Of(
        Version.ToString(),
        SystemUsers.OfficialPhone,
        OfficialBio,
        options.Value.SuperAdminPhone ?? string.Empty,
        (options.Value.SuperAdminPassword is not null).ToString()));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var official = await SeedUserStore.UpsertByIdAsync(db, SystemUsers.EditorialId, () => User.CreateSeeded(
            SystemUsers.OfficialPhone, "ReadIn", "readin", SystemUsers.EditorialId, systemAccount: true), cancellationToken);
        if (official.PhoneNumber != SystemUsers.OfficialPhone) official.AssignSeedPhoneNumber(SystemUsers.OfficialPhone);
        // The avatar is set by its own seeder from content/assets; keep it.
        official.UpdateProfile("ReadIn", "readin", OfficialBio, official.AvatarUrl, new UserLinks());
        official.GrantRole(RoleIds.Member);
        official.Verify(clock.GetUtcNow().UtcDateTime); // the badge, not a role (SPEC §10.1)

        var phone = SuperAdminPhone();
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

    private string? SuperAdminPhone()
    {
        if (PhoneNumberRules.TryNormalize(options.Value.SuperAdminPhone, out var configured)) return configured;
        return SeedEnvironments.AllowsDemoData(environment) ? SystemUsers.LocalSuperAdminPhone : null;
    }
}
