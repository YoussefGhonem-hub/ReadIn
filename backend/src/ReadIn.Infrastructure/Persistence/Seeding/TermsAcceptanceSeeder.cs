using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Features.Legal;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// The seeded accounts accept the current Terms of Use (SPEC F37 decision 2), so a new version never puts the terms screen in
/// front of them: the system accounts (the official @readin and the SuperAdmin) everywhere, and locally the demo users
/// (their <c>@readin.test</c> addresses). Members accept for themselves. Runs again whenever the version changes.
/// </summary>
internal sealed class TermsAcceptanceSeeder(AppDbContext db, TermsOfUse terms, IHostEnvironment environment, TimeProvider clock) : ISeeder
{
    public string Name => "terms-acceptance";
    public int Order => 16;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        Task.FromResult(SeedChecksum.Of(Version.ToString(), terms.CurrentVersion, SeedEnvironments.AllowsDemoData(environment).ToString()));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var demo = SeedEnvironments.AllowsDemoData(environment);
        var version = terms.CurrentVersion;
        var seeded = await db.Users
            .Where(u => u.TermsVersion != version && (u.IsSystemAccount || (demo && u.Email != null && u.Email.EndsWith("@readin.test"))))
            .ToListAsync(cancellationToken);
        var now = clock.GetUtcNow().UtcDateTime;
        foreach (var user in seeded) user.AcceptTerms(version, now);
        await db.SaveChangesAsync(cancellationToken);
        return true;
    }
}
