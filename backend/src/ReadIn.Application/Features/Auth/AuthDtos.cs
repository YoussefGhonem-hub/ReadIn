using ReadIn.Application.Features.Users;

namespace ReadIn.Application.Features.Auth;

public sealed record PasswordRulesDto(int MinLength, int MaxLength, bool RequireLetter, bool RequireDigit);

/// <summary>
/// <c>GET /auth/config</c>: what the sign-up forms validate live (SPEC §9.4), and which of Google/Apple this server accepts
/// (clients hide the other buttons).
/// </summary>
/// <param name="GoogleCodeSignIn">
/// The API can trade a Google authorization code (its web client secret is configured), so the web shows its own
/// "Continue with Google" button; otherwise Google's (ADR 0012).
/// </param>
public sealed record AuthConfigDto(
    int PinLength, PasswordRulesDto Password, IReadOnlyList<string> ExternalProviders, bool GoogleCodeSignIn = false);

/// <summary>
/// A signed-in session. The web receives the refresh token as an <c>HttpOnly</c> cookie instead of in the body
/// (SPEC §9.3).
/// </summary>
public sealed record AuthSessionDto(
    string AccessToken,
    DateTime AccessTokenExpiresAt,
    string RefreshToken,
    DateTime RefreshTokenExpiresAt,
    MeDto User);

/// <summary>A Google or Apple ID token from the client SDK, plus the raw nonce for Apple (SPEC §9.1).</summary>
/// <param name="IdToken">Empty only for Google's web code flow, which sends <paramref name="AuthorizationCode"/> instead.</param>
/// <param name="AuthorizationCode">
/// Apple: the one-time code that comes with the ID token. Exchanged for a refresh token so the account's Apple
/// authorization can be revoked when it is deleted (SPEC F01). Google: the web button's one-time code, sent without an ID
/// token; the API trades it for the ID token (ADR 0012).
/// </param>
public sealed record ExternalCredentialDto(string Provider, string? IdToken, string? Nonce = null, string? AuthorizationCode = null);

/// <summary>Step 1 of "forgot password": a correct phone + PIN returns a 10-minute, single-use reset token.</summary>
public sealed record PasswordResetTokenDto(string ResetToken, DateTime ExpiresAt);
