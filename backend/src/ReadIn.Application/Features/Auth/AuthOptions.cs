namespace ReadIn.Application.Features.Auth;

/// <summary>Session settings (SPEC §9.3). The access token's signing settings live in the API's <c>Jwt</c> section.</summary>
public sealed class AuthOptions
{
    public const string Section = "Auth";

    /// <summary>Web and unknown clients. Every refresh issues a new token with a full lifetime, so it slides.</summary>
    public TimeSpan RefreshTokenLifetime { get; set; } = TimeSpan.FromDays(30);

    /// <summary>
    /// Sessions of the mobile app (<see cref="Common.Interfaces.IClientInfo.IsMobileApp"/>): they last until the user signs
    /// out, so the lifetime is long, and it slides like <see cref="RefreshTokenLifetime"/>.
    /// </summary>
    public TimeSpan MobileRefreshTokenLifetime { get; set; } = TimeSpan.FromDays(3650);

    /// <summary>
    /// A token rotated this recently may be presented again without revoking its family: two browser tabs refreshing at
    /// once must not sign the user out. Older reuse is treated as theft.
    /// </summary>
    public TimeSpan RefreshReuseGrace { get; set; } = TimeSpan.FromSeconds(30);
}

/// <summary>Recovery PIN settings (SPEC §9.4).</summary>
public sealed class RecoveryOptions
{
    public const string Section = "Recovery";

    public int PinLength { get; set; } = 4;
}
