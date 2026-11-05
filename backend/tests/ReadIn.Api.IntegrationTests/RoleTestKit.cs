using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Authorization;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// Accounts for the roles of SPEC §10: a fresh SuperAdmin per test (the <c>writes</c> rate limit, 30 a minute, is per
/// user, so tests don't share the seeded one), a Member with the Verified badge, and a test-only role holding exactly
/// some permissions, like a staff role that may be added later.
/// </summary>
internal static class RoleTestKit
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    /// <summary>A new account with only the SuperAdmin role, like the real one.</summary>
    public static async Task<SignedInUser> SuperAdminAsync(this ApiFactory api, string displayName = "Test SuperAdmin")
    {
        var user = await api.UserAsync(displayName);
        await api.ChangeUserAsync(user.Id, u =>
        {
            u.GrantRole(RoleIds.SuperAdmin);
            u.RevokeRole(RoleIds.Member);
        });
        return user;
    }

    /// <summary>A new Member with the Verified badge (SPEC §10.1): no role changes.</summary>
    public static async Task<SignedInUser> VerifiedUserAsync(this ApiFactory api, string displayName = "Verified Tester")
    {
        var user = await api.UserAsync(displayName);
        await api.ChangeUserAsync(user.Id, u => u.Verify(DateTime.UtcNow));
        return user;
    }

    /// <summary>A new account whose only role is a test-only one holding exactly <paramref name="permissions"/>.</summary>
    public static async Task<SignedInUser> UserWithPermissionsAsync(this ApiFactory api, string displayName, params string[] permissions)
    {
        var user = await api.UserAsync(displayName);
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var role = new Role($"Test {Guid.NewGuid():N}"[..20], "Test only: a staff role with some permissions.");
        db.Roles.Add(role);
        await db.SaveChangesAsync(Ct);
        role.SetPermissions(await db.Permissions.Where(p => permissions.Contains(p.Code)).Select(p => p.Id).ToListAsync(Ct));
        await db.SaveChangesAsync(Ct);
        await api.ChangeUserAsync(user.Id, u =>
        {
            u.GrantRole(role.Id);
            u.RevokeRole(RoleIds.Member);
        });
        return user;
    }

    private static async Task ChangeUserAsync(this ApiFactory api, Guid userId, Action<Domain.Users.User> change)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        change(await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == userId, Ct));
        await db.SaveChangesAsync(Ct);
        await scope.ServiceProvider.GetRequiredService<IUserAccessService>().InvalidateAsync(userId, Ct);
    }
}
