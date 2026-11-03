using ReadIn.Domain.Common;

namespace ReadIn.Domain.Authorization;

/// <summary>A named bundle of permissions (SPEC §10). Roles live in SQL Server, never in Firebase claims.</summary>
public sealed class Role : Entity
{
    private readonly List<RolePermission> _permissions = [];

    private Role() { } // EF

    public Role(string name, string description, Guid? id = null)
    {
        Id = id ?? Guid.CreateVersion7();
        Name = name;
        Description = description;
    }

    public string Name { get; private set; } = default!;
    public string Description { get; private set; } = default!;
    public IReadOnlyCollection<RolePermission> Permissions => _permissions.AsReadOnly();

    public void Describe(string description) => Description = description;

    /// <summary>Replaces the permission set; returns true when it changed.</summary>
    public bool SetPermissions(IEnumerable<Guid> permissionIds)
    {
        var target = permissionIds.ToHashSet();
        var current = _permissions.Select(p => p.PermissionId).ToHashSet();
        if (target.SetEquals(current)) return false;

        _permissions.RemoveAll(p => !target.Contains(p.PermissionId));
        _permissions.AddRange(target.Except(current).Select(pid => new RolePermission(Id, pid)));
        return true;
    }
}

public sealed class Permission : Entity
{
    private Permission() { } // EF

    public Permission(string code, string description, Guid? id = null)
    {
        Id = id ?? Guid.CreateVersion7();
        Code = code;
        Description = description;
    }

    /// <summary>Stable permission code, e.g. <c>articles.create</c>.</summary>
    public string Code { get; private set; } = default!;
    public string Description { get; private set; } = default!;

    public void Describe(string description) => Description = description;
}

public sealed class RolePermission
{
    private RolePermission() { } // EF

    internal RolePermission(Guid roleId, Guid permissionId)
    {
        RoleId = roleId;
        PermissionId = permissionId;
    }

    public Guid RoleId { get; private set; }
    public Guid PermissionId { get; private set; }
}
