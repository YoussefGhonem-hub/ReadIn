using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Authorization;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>Seeder #1 (all environments): the role/permission matrix from SPEC §10.2.</summary>
internal sealed class RolesAndPermissionsSeeder(AppDbContext db) : ISeeder
{
    public string Name => "roles-and-permissions";
    public int Order => 1;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) => Task.FromResult(SeedChecksum.Of(
        [.. Permissions.All.Select(p => $"{p.Key}={p.Value}"),
         .. RoleMatrix.Roles.Select(r => $"{r.Id}|{r.Name}|{r.Description}|{string.Join(',', r.Permissions.Order())}")]));

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

        var roles = await db.Roles.Include(r => r.Permissions).ToDictionaryAsync(r => r.Id, cancellationToken);
        foreach (var definition in RoleMatrix.Roles)
        {
            if (!roles.TryGetValue(definition.Id, out var role))
            {
                role = new Role(definition.Name, definition.Description, definition.Id);
                db.Roles.Add(role);
            }
            role.Describe(definition.Description);
            role.SetPermissions(definition.Permissions.Select(code => permissions[code].Id));
        }

        await db.SaveChangesAsync(cancellationToken);
        return true;
    }
}
