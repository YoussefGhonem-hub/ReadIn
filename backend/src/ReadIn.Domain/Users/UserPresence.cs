namespace ReadIn.Domain.Users;

/// <summary>
/// When an account was last seen (SPEC F23, the console's users table): set by any signed-in request, at most once an hour.
/// Kept in its own row, keyed by the user, so the hourly write never touches <c>Users</c> and its row version (a request
/// that loaded the user would otherwise fail to save). Goes with the account (cascade).
/// </summary>
public sealed class UserPresence
{
    private UserPresence() { } // EF

    public UserPresence(Guid userId, DateTime lastSeenAt)
    {
        UserId = userId;
        LastSeenAt = lastSeenAt;
    }

    public Guid UserId { get; private set; }
    public DateTime LastSeenAt { get; private set; }
}

/// <summary>The values of <see cref="User.SignUpMethod"/>: how an account was created (SPEC F23).</summary>
public static class SignUpMethods
{
    public const string Phone = "phone";
    public const string Google = ExternalProviders.Google;
    public const string Apple = ExternalProviders.Apple;

    public static readonly IReadOnlyList<string> All = [Phone, Google, Apple];
}
