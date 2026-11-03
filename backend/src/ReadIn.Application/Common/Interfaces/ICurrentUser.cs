namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// The caller of the current request. Identity comes from the Firebase ID token; <see cref="UserId"/>,
/// roles and permissions come from SQL Server (SPEC §9.2 step 5).
/// </summary>
public interface ICurrentUser
{
    bool IsAuthenticated { get; }

    /// <summary>Firebase uid from the token, set whenever <see cref="IsAuthenticated"/> is true.</summary>
    string? FirebaseUid { get; }

    /// <summary>ReadIn user id; null until the user has called POST /auth/sync.</summary>
    Guid? UserId { get; }

    string? Email { get; }
    string? DisplayName { get; }
    string? PictureUrl { get; }

    /// <summary>UI language of the request (<c>ar</c> | <c>en</c>), from Accept-Language.</summary>
    string UiLanguage { get; }

    IReadOnlySet<string> Roles { get; }
    IReadOnlySet<string> Permissions { get; }
}

public static class CurrentUserExtensions
{
    public static Guid RequireUserId(this ICurrentUser user) =>
        user.UserId ?? throw new InvalidOperationException("The request is not associated with a synced ReadIn user.");
}
