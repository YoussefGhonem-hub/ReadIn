namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// The caller of the current request. <see cref="UserId"/> comes from the access token's <c>sub</c>; roles and
/// permissions come from SQL Server (SPEC §9.3).
/// </summary>
public interface ICurrentUser
{
    bool IsAuthenticated { get; }

    /// <summary>ReadIn user id; set whenever <see cref="IsAuthenticated"/> is true.</summary>
    Guid? UserId { get; }

    /// <summary>UI language of the request (<c>ar</c> | <c>en</c>), from Accept-Language.</summary>
    string UiLanguage { get; }

    IReadOnlySet<string> Roles { get; }
    IReadOnlySet<string> Permissions { get; }
}

public static class CurrentUserExtensions
{
    public static Guid RequireUserId(this ICurrentUser user) =>
        user.UserId ?? throw new InvalidOperationException("The request is not associated with a signed-in ReadIn user.");
}
