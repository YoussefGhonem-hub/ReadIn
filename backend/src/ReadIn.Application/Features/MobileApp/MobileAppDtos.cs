namespace ReadIn.Application.Features.MobileApp;

/// <summary><c>GET /app/update-policy</c>: what each store build must be at least; the app does the comparison.</summary>
public sealed record UpdatePolicyDto(PlatformUpdatePolicyDto Ios, PlatformUpdatePolicyDto Android);

/// <param name="MinimumVersion">Null: no forced update. "1.2", "1.2.0" or "1.2.0+57" (build 57).</param>
/// <param name="StoreUrl">Where the update button goes; null while the app has no store listing.</param>
public sealed record PlatformUpdatePolicyDto(string? MinimumVersion, string? StoreUrl);
