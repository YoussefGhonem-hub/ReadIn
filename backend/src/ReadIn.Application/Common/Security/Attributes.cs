namespace ReadIn.Application.Common.Security;

/// <summary>
/// Declares the permission a command/query needs. Enforced by <c>AuthorizationBehavior</c>.
/// Guests pass when the Guest role has the permission (e.g. <c>articles.read</c>).
/// </summary>
[AttributeUsage(AttributeTargets.Class, AllowMultiple = true, Inherited = false)]
public sealed class RequirePermissionAttribute(string permission) : Attribute
{
    public string Permission { get; } = permission;
}

/// <summary>The message needs a signed-in user who has been synced to SQL Server.</summary>
[AttributeUsage(AttributeTargets.Class, Inherited = false)]
public sealed class AuthenticatedAttribute : Attribute;
