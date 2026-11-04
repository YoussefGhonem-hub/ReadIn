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

    /// <summary><see cref="Suspended"/> with when it ends (SPEC F22): <c>suspendedUntil</c>, ISO UTC or null for permanent.</summary>
    public static Error SuspendedUntil(DateTime? until) =>
        Suspended with { Extensions = new Dictionary<string, object?> { ["suspendedUntil"] = until } };
}

/// <summary>The public profile and editing it (SPEC F14, F18).</summary>
public static class ProfileErrors
{
    public static readonly Error ExpertiseInvalid =
        Error.Validation("profile.expertise_invalid", "Choose up to 5 fields of expertise from the list.");
    public static readonly Error AvatarInvalid =
        Error.Validation("profile.avatar_invalid", "This image can't be used as your avatar. Upload it again.");
    public static readonly Error StatsPrivate =
        Error.Forbidden("profile.stats_private", "This user's reading stats are private.");
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

    // ---- Google / Apple (SPEC §9.1) ----

    public static readonly Error ExternalInvalid =
        Error.Unauthorized("auth.external_invalid", "This Google or Apple sign in could not be verified. Try again.");
    public static readonly Error ProviderDisabled =
        Error.Validation("auth.provider_disabled", "This sign-in method is not available.");
    /// <summary>No account has this identity: the client offers "create a new account" or "link my phone account".</summary>
    public static readonly Error ExternalNotLinked =
        Error.NotFound("auth.external_not_linked", "No ReadIn account is linked to this account yet.");
    public static readonly Error ExternalInUse =
        Error.Conflict("auth.external_in_use", "This Google or Apple account is linked to another ReadIn account.");
    public static readonly Error ExternalConflict =
        Error.Conflict("auth.external_conflict", "Another account from this provider is already linked.");
    public static readonly Error ExternalLoginNotFound =
        Error.NotFound("auth.external_login_not_found", "This sign-in method is not linked to your account.");
    public static readonly Error LastSignInMethod =
        Error.Validation("auth.last_sign_in_method", "You can't remove your only way to sign in.");
    public static readonly Error PhoneSignInExists =
        Error.Conflict("auth.phone_sign_in_exists", "This account already signs in with a phone number.");
    public static readonly Error ConfirmationRequired =
        Error.Validation("auth.confirmation_required", "Confirm it's you with your password or with Google or Apple.");
    public static readonly Error ExternalMismatch =
        Error.Validation("auth.external_mismatch", "Use the Google or Apple account that is linked to ReadIn.");

    /// <summary>Per-number limits (SPEC §9.5): 5 sign-in attempts a minute, 5 recovery attempts an hour.</summary>
    public static readonly Error TooManyAttempts =
        Error.TooManyRequests("rate_limited", "Too many requests. Please try again shortly.");
}
