using ReadIn.Domain.Common;

namespace ReadIn.Domain.Users;

public static class UserErrors
{
    public static readonly Error NotSynced = Error.NotFound("user.not_synced", "The signed-in user has not been synced. Call POST /auth/sync first.");
    public static readonly Error NotFound = Error.NotFound("user.not_found", "User not found.");
    public static readonly Error Suspended = Error.Forbidden("user.suspended", "This account is suspended.");
    public static readonly Error UsernameTaken = Error.Conflict("user.username_taken", "This username is already taken.");
    public static readonly Error InvalidUsername = Error.Validation("user.username_invalid", "Username must be 3–30 characters: a–z, 0–9 or _.");
    public static readonly Error InvalidLanguage = Error.Validation("user.language_invalid", "Unsupported language.");
    public static readonly Error InterestsMinThree = Error.Validation("user.interests.min_three", "Choose at least 3 interests.");
}
