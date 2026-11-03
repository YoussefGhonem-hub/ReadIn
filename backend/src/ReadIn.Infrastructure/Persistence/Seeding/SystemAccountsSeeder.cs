using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #3 (all environments): "ReadIn Editorial" (author of seeded articles, no login) and the SuperAdmin.
/// </summary>
internal sealed class SystemAccountsSeeder(AppDbContext db, IIdentityProvisioner identity, IOptions<SeedOptions> options) : ISeeder
{
    public string Name => "system-accounts";
    public int Order => 3;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        Task.FromResult(SeedChecksum.Of(Version.ToString(), (options.Value.SuperAdminPassword is not null).ToString()));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var editorial = await SeedUserStore.UpsertAsync(db, SystemUsers.EditorialEmail, () => User.CreateSystemAccount(
            "system-editorial", SystemUsers.EditorialEmail, "ReadIn Editorial", "readin", SystemUsers.EditorialId), cancellationToken);
        editorial.UpdateProfile(
            "ReadIn Editorial",
            "readin",
            "فريق ReadIn التحريري. كل مقال بيتراجع من Reviewer متخصص وبيتوثّق بمصادر رسمية.",
            null,
            new UserLinks { Website = "https://readin.app" });
        editorial.GrantRole(RoleIds.Member);
        editorial.GrantRole(RoleIds.VerifiedWriter);

        var superAdmin = await SeedUserStore.UpsertAsync(db, SystemUsers.SuperAdminEmail, () => User.CreateSystemAccount(
            "system-superadmin", SystemUsers.SuperAdminEmail, "Super Admin", "superadmin", SystemUsers.SuperAdminId), cancellationToken);
        superAdmin.GrantRole(RoleIds.SuperAdmin);

        await db.SaveChangesAsync(cancellationToken);

        // The SuperAdmin can only sign in once a password is configured in the secret store.
        var password = options.Value.SuperAdminPassword;
        if (string.IsNullOrWhiteSpace(password)) return true;

        return await identity.EnsureUserAsync(
            superAdmin.FirebaseUid, superAdmin.Email, superAdmin.DisplayName, password, disabled: false, cancellationToken);
    }
}
