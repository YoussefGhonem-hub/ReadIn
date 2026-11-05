using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Authorization;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #1 (all environments): the role/permission matrix from SPEC §10.2, and nothing else. It makes the database match
/// <see cref="RoleMatrix"/> exactly: only Guest, Member and SuperAdmin with their permissions; any other role (with its
/// <c>UserRoles</c> and <c>RolePermissions</c>) and any permission that no longer exists (<c>roles.manage</c>) are
/// deleted, and every account left without a role becomes a Member. The checksum covers the database as well as the
/// matrix, so a start after anything drifted runs it again: every start leaves the database in this state.
/// </summary>
internal sealed class RolesAndPermissionsSeeder(AppDbContext db) : ISeeder
{
    public string Name => "roles-and-permissions";
    public int Order => 1;
    public int Version => 2;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public async Task<string> ComputeChecksumAsync(CancellationToken cancellationToken)
    {
        var desired = Desired();
        var actual = await ActualAsync(cancellationToken);
        return actual.SequenceEqual(desired, StringComparer.Ordinal)
            ? SeedChecksum.Of([.. desired])
            : SeedChecksum.Of([.. desired, "drift", .. actual]);
    }

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var permissions = await db.Permissions.ToDictionaryAsync(p => p.Code, cancellationToken);
        foreach (var (code, description) in Permissions.All)
        {
            if (permissions.TryGetValue(code, out var existing))
            {
                existing.Describe(description);
                continue;
            }
            var permission = new Permission(code, description);
            db.Permissions.Add(permission);
            permissions[code] = permission;
        }

        var roles = await db.Roles.Include(r => r.Permissions).ToListAsync(cancellationToken);
        var known = roles.ToDictionary(r => r.Id);
        foreach (var definition in RoleMatrix.Roles)
        {
            if (!known.TryGetValue(definition.Id, out var role))
            {
                role = new Role(definition.Name, definition.Description, definition.Id);
                db.Roles.Add(role);
            }
            role.Describe(definition.Description);
            role.SetPermissions(definition.Permissions.Select(code => permissions[code].Id));
        }

        // Roles that left the matrix (Admin, Moderator, VerifiedWriter, or one made by hand): their UserRoles and
        // RolePermissions go with them (cascade). Then permissions that no longer exist.
        var matrix = RoleMatrix.Roles.Select(r => r.Id).ToHashSet();
        db.Roles.RemoveRange(roles.Where(r => !matrix.Contains(r.Id)));
        db.Permissions.RemoveRange(permissions.Values.Where(p => !Permissions.All.ContainsKey(p.Code)));
        await db.SaveChangesAsync(cancellationToken);

        // Every account has a role: one left without any is a Member.
        await db.Database.ExecuteSqlAsync(
            $"""
            INSERT INTO [UserRoles] ([UserId], [RoleId])
            SELECT u.[Id], {RoleIds.Member} FROM [Users] u
            WHERE NOT EXISTS (SELECT 1 FROM [UserRoles] ur WHERE ur.[UserId] = u.[Id])
            """, cancellationToken);
        return true;
    }

    /// <summary>The state the database must be in.</summary>
    private static List<string> Desired() =>
    [
        .. Permissions.All.Select(p => $"permission|{p.Key}|{p.Value}").Order(StringComparer.Ordinal),
        .. RoleMatrix.Roles.Select(r => RoleLine(r.Id, r.Name, r.Description, r.Permissions)).Order(StringComparer.Ordinal),
        "accounts without a role|False",
    ];

    /// <summary>The state the database is in, written like <see cref="Desired"/>.</summary>
    private async Task<List<string>> ActualAsync(CancellationToken ct)
    {
        var permissions = await db.Permissions.AsNoTracking().Select(p => new { p.Id, p.Code, p.Description }).ToListAsync(ct);
        var codes = permissions.ToDictionary(p => p.Id, p => p.Code);
        var roles = await db.Roles.AsNoTracking()
            .Select(r => new { r.Id, r.Name, r.Description, PermissionIds = r.Permissions.Select(p => p.PermissionId).ToList() })
            .ToListAsync(ct);
        var roleless = await db.Users.IgnoreQueryFilters().AnyAsync(u => !u.Roles.Any(), ct);

        return
        [
            .. permissions.Select(p => $"permission|{p.Code}|{p.Description}").Order(StringComparer.Ordinal),
            .. roles.Select(r => RoleLine(r.Id, r.Name, r.Description, [.. r.PermissionIds.Select(id => codes[id])])).Order(StringComparer.Ordinal),
            $"accounts without a role|{roleless}",
        ];
    }

    private static string RoleLine(Guid id, string name, string? description, IEnumerable<string> permissions) =>
        $"role|{id}|{name}|{description}|{string.Join(',', permissions.Order(StringComparer.Ordinal))}";
}
