using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Interfaces;

public enum PasswordCheck
{
    Failed,
    Success,

    /// <summary>Correct, but hashed with older parameters: store a new hash.</summary>
    SuccessRehashNeeded,
}

/// <summary>PBKDF2 via ASP.NET Core Identity's <c>PasswordHasher</c> (SPEC §9.5).</summary>
public interface IPasswordHasher
{
    string Hash(string password);

    PasswordCheck Verify(string hash, string password);

    /// <summary>Spends the same time as a real check, so unknown numbers can't be told apart by timing (SPEC §9.5).</summary>
    void VerifyAgainstDummy(string password);
}

/// <summary>
/// Recovery PINs are hashed as <c>PasswordHasher(HMACSHA256(pepper, userId + ":" + pin))</c>. The pepper lives only in
/// secrets, so a leaked database can't be used to try the 10,000 PINs offline (SPEC §9.5).
/// </summary>
public interface IRecoveryPinHasher
{
    string Hash(Guid userId, string pin);

    bool Verify(Guid userId, string hash, string pin);

    void VerifyAgainstDummy(string pin);

    /// <summary>Keyed hash of a phone number, for <c>RecoveryAttempts</c> (the number itself is never stored there).</summary>
    string HashPhoneNumber(string phoneNumber);
}

public sealed record AccessToken(string Value, DateTime ExpiresAt);

/// <summary>Signs the 15-minute JWT access token: <c>sub</c> + <c>security_stamp</c> (SPEC §9.3).</summary>
public interface IAccessTokenIssuer
{
    AccessToken Issue(Guid userId, string securityStamp);
}

/// <summary>The device making the request.</summary>
public interface IClientInfo
{
    string? IpAddress { get; }

    /// <summary>Shown in a future "active sessions" list, e.g. "Pixel 8" or the browser's user agent.</summary>
    string? DeviceName { get; }
}

/// <summary>Fixed-window counters for per-number limits that the IP-based rate limiter can't express (SPEC §9.5).</summary>
public interface IAttemptThrottle
{
    /// <returns>false when <paramref name="limit"/> attempts were already made for <paramref name="key"/> in the window.</returns>
    bool TryAcquire(string key, int limit, TimeSpan window);
}

/// <summary>What Google or Apple vouched for in a verified ID token (SPEC §9.1).</summary>
/// <param name="Subject">The provider's stable user id (<c>sub</c>).</param>
/// <param name="Name">Google's profile name; Apple never puts the name in its token.</param>
public sealed record ExternalIdentity(string Provider, string Subject, string? Email, bool EmailVerified, string? Name);

/// <summary>Checks Google and Apple ID tokens against the providers' published keys and our client ids (ADR 0012).</summary>
public interface IExternalIdentityVerifier
{
    /// <summary>Providers with at least one client id configured, in display order.</summary>
    IReadOnlyList<string> EnabledProviders { get; }

    /// <param name="nonce">The raw nonce the client generated; required for Apple, whose token carries its SHA-256.</param>
    Task<Result<ExternalIdentity>> VerifyAsync(string provider, string idToken, string? nonce, CancellationToken ct);
}
