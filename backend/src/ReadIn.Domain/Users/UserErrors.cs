using ReadIn.Domain.Common;

namespace ReadIn.Domain.Users;

public static class UserErrors
{
    public static readonly Error NotFound = Error.NotFound("user.not_found", "User not found.");
    public static readonly Error Suspended = Error.Forbidden("user.suspended", "This account is suspended.");
    public static readonly Error UsernameTaken = Error.Conflict("user.username_taken", "This username is already taken.");
    public static readonly Error InvalidUsername = Error.Validation("user.username_invalid", "Username must be 3–30 characters: a–z, 0–9 or _.");
    public static readonly Error InvalidLanguage = Error.Validation("user.language_invalid", "Unsupported language.");
    public static readonly Error InterestsMinThree = Error.Validation("user.interests.min_three", "Choose at least 3 interests.");
    public static readonly Error DeviceNotFound = Error.NotFound("user.device_not_found", "This device is not registered.");
}

/// <summary>Sign up, sign in and recovery (SPEC §9). Sign-in and recovery failures are deliberately generic.</summary>
public static class CredentialErrors
{
    public static readonly Error InvalidCredentials =
        Error.Unauthorized("auth.invalid_credentials", "The phone number or password is incorrect.");
    public static readonly Error LockedOut =
        Error.TooManyRequests("auth.locked_out", "Too many attempts. Try again in 15 minutes.");
    public static readonly Error PhoneTaken =
        Error.Conflict("auth.phone_taken", "This number already has an account.");
    public static readonly Error RefreshTokenInvalid =
        Error.Unauthorized("auth.refresh_invalid", "Your session has ended. Sign in again.");
    public static readonly Error RecoveryInvalid =
        Error.Unauthorized("auth.recovery_invalid", "The phone number or PIN is incorrect.");
    public static readonly Error RecoveryLocked =
        Error.TooManyRequests("auth.recovery_locked", "Too many attempts. Try again in an hour.");
    public static readonly Error RecoveryDisabled =
        Error.Forbidden("auth.recovery_disabled", "Recovery is disabled for this account. Contact support.");
    public static readonly Error ResetTokenInvalid =
        Error.Validation("auth.reset_token_invalid", "This reset has expired. Start again.");
    public static readonly Error WrongPassword =
        Error.Validation("auth.wrong_password", "The current password is incorrect.");
    public static readonly Error PinAlreadySet =
        Error.Conflict("auth.pin_already_set", "A recovery PIN is already set. Change it from Settings.");
    public static readonly Error PhoneUnchanged =
        Error.Validation("auth.phone_unchanged", "This is already your number.");

    /// <summary>Per-number limits (SPEC §9.5): 5 sign-in attempts a minute, 5 recovery attempts an hour.</summary>
    public static readonly Error TooManyAttempts =
        Error.TooManyRequests("rate_limited", "Too many requests. Please try again shortly.");
}
