using System.Security.Claims;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Api.Auth;

internal sealed class HttpCurrentUser(IHttpContextAccessor accessor) : ICurrentUser
{
    private ClaimsPrincipal? Principal => accessor.HttpContext?.User;

    public bool IsAuthenticated => Principal?.Identity?.IsAuthenticated == true;

    public Guid? UserId => Guid.TryParse(Claim(JwtClaims.Subject), out var id) ? id : null;

    public string UiLanguage => RequestLanguage.Resolve(accessor.HttpContext);

    public IReadOnlySet<string> Roles => ClaimSet(ReadInClaims.Role);

    public IReadOnlySet<string> Permissions => ClaimSet(ReadInClaims.Permission);

    private string? Claim(string type) => IsAuthenticated ? Principal!.FindFirst(type)?.Value : null;

    private HashSet<string> ClaimSet(string type) =>
        Principal?.FindAll(type).Select(c => c.Value).ToHashSet(StringComparer.Ordinal) ?? [];
}

/// <summary>The caller's address and device, recorded on sessions and recovery attempts (SPEC §16.2).</summary>
internal sealed class HttpClientInfo(IHttpContextAccessor accessor) : IClientInfo
{
    /// <summary>Optional header with a readable device name, e.g. "Pixel 8" (mobile); the user agent otherwise.</summary>
    public const string DeviceNameHeader = "X-Device-Name";

    /// <summary>The mobile app sends <c>X-ReadIn-Client: mobile</c> on every request; the web sends <c>web</c> on its auth calls.</summary>
    public const string MobileClient = "mobile";

    public string? IpAddress => accessor.HttpContext?.Connection.RemoteIpAddress?.ToString();

    public bool IsMobileApp => string.Equals(
        accessor.HttpContext?.Request.Headers[RefreshCookie.ClientHeader].ToString(), MobileClient, StringComparison.OrdinalIgnoreCase);

    public string? DeviceName
    {
        get
        {
            var headers = accessor.HttpContext?.Request.Headers;
            var name = headers?[DeviceNameHeader].ToString();
            if (string.IsNullOrWhiteSpace(name)) name = headers?.UserAgent.ToString();
            return string.IsNullOrWhiteSpace(name) ? null : name.Trim();
        }
    }
}

public static class RequestLanguage
{
    /// <summary>UI language from <c>Accept-Language</c>: <c>en</c> when English is preferred, otherwise <c>ar</c>.</summary>
    public static string Resolve(HttpContext? context)
    {
        var preferred = context?.Request.GetTypedHeaders().AcceptLanguage
            .OrderByDescending(l => l.Quality ?? 1)
            .Select(l => l.Value.Value)
            .FirstOrDefault();
        return UiLanguages.Normalize(preferred);
    }
}
