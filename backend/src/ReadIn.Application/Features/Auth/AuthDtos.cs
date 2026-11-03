using ReadIn.Application.Features.Users;

namespace ReadIn.Application.Features.Auth;

public sealed record PasswordRulesDto(int MinLength, int MaxLength, bool RequireLetter, bool RequireDigit);

/// <summary><c>GET /auth/config</c>: what the sign-up forms validate live (SPEC §9.4).</summary>
public sealed record AuthConfigDto(int PinLength, PasswordRulesDto Password);

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

/// <summary>Step 1 of "forgot password": a correct phone + PIN returns a 10-minute, single-use reset token.</summary>
public sealed record PasswordResetTokenDto(string ResetToken, DateTime ExpiresAt);
