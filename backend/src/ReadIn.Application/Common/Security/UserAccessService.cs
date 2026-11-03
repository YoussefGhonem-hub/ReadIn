using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Application.Common.Security;

public sealed record UserAccess(
    Guid UserId,
    bool IsSuspended,
    DateTime? SuspendedUntil,
    IReadOnlyList<string> Roles,
    IReadOnlyList<string> Permissions)
{
    public bool IsSuspendedAt(DateTime now) => IsSuspended && (SuspendedUntil is null || SuspendedUntil > now);
}

/// <summary>Loads a user's roles and permissions from SQL Server, cached for 5 minutes (SPEC §9.2 step 5).</summary>
public interface IUserAccessService
{
    ValueTask<UserAccess?> GetAsync(string firebaseUid, CancellationToken cancellationToken);
    ValueTask<IReadOnlySet<string>> GetGuestPermissionsAsync(CancellationToken cancellationToken);
    ValueTask InvalidateAsync(string firebaseUid, CancellationToken cancellationToken);
}

internal sealed class UserAccessService(IAppDbContext db, HybridCache cache) : IUserAccessService
{
    private static readonly HybridCacheEntryOptions Ttl = new()
    {
        Expiration = TimeSpan.FromMinutes(5),
        LocalCacheExpiration = TimeSpan.FromMinutes(5),
    };

    private static string Key(string firebaseUid) => $"user-access:{firebaseUid}";

    public ValueTask<UserAccess?> GetAsync(string firebaseUid, CancellationToken cancellationToken) =>
        cache.GetOrCreateAsync(Key(firebaseUid), (db, firebaseUid), static async (state, ct) =>
        {
            var (db, uid) = state;
            var user = await db.Users.AsNoTracking()
                .Where(u => u.FirebaseUid == uid)
                .Select(u => new { u.Id, u.IsSuspended, u.SuspendedUntil, RoleIds = u.Roles.Select(r => r.RoleId).ToList() })
                .FirstOrDefaultAsync(ct);
            if (user is null) return null;

            var roles = await db.Roles.AsNoTracking()
                .Where(r => user.RoleIds.Contains(r.Id))
                .Select(r => new { r.Name, PermissionIds = r.Permissions.Select(p => p.PermissionId).ToList() })
                .ToListAsync(ct);
            var permissionIds = roles.SelectMany(r => r.PermissionIds).Distinct().ToList();
            var permissions = await db.Permissions.AsNoTracking()
                .Where(p => permissionIds.Contains(p.Id))
                .Select(p => p.Code)
                .ToListAsync(ct);

            return new UserAccess(user.Id, user.IsSuspended, user.SuspendedUntil, [.. roles.Select(r => r.Name)], permissions);
        }, Ttl, cancellationToken: cancellationToken);

    public async ValueTask<IReadOnlySet<string>> GetGuestPermissionsAsync(CancellationToken cancellationToken)
    {
        var codes = await cache.GetOrCreateAsync("guest-permissions", db, static async (db, ct) =>
        {
            var ids = await db.Roles.AsNoTracking()
                .Where(r => r.Id == RoleIds.Guest)
                .SelectMany(r => r.Permissions.Select(p => p.PermissionId))
                .ToListAsync(ct);
            return await db.Permissions.AsNoTracking().Where(p => ids.Contains(p.Id)).Select(p => p.Code).ToArrayAsync(ct);
        }, Ttl, cancellationToken: cancellationToken);

        return codes.ToHashSet(StringComparer.Ordinal);
    }

    public ValueTask InvalidateAsync(string firebaseUid, CancellationToken cancellationToken) =>
        cache.RemoveAsync(Key(firebaseUid), cancellationToken);
}
