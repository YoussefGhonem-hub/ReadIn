using ReadIn.Api.Errors;
using ReadIn.Application.Features.Auth;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Common;

namespace ReadIn.Api.Auth;

/// <summary>
/// A session as sent to clients. Mobile keeps <see cref="RefreshToken"/> in secure storage; the web gets it as an
/// <c>HttpOnly</c> cookie instead and <see cref="RefreshToken"/> is null (SPEC §9.3).
/// </summary>
public sealed record SessionResponse(
    string AccessToken,
    DateTime AccessTokenExpiresAt,
    string? RefreshToken,
    DateTime RefreshTokenExpiresAt,
    MeDto User);

/// <summary>Body of <c>/auth/refresh</c> and <c>/auth/logout</c>; empty for the web, which uses the cookie.</summary>
public sealed record RefreshTokenRequest(string? RefreshToken);

/// <summary>
/// The web's refresh token cookie: <c>HttpOnly</c>, <c>Secure</c>, <c>SameSite=Strict</c>, path <c>/api/v1/auth</c>. The web
/// marks its auth calls with <c>X-ReadIn-Client: web</c>; a cross-site page can't send that header without passing CORS,
/// so the cookie is only read when it's there.
/// </summary>
public static class RefreshCookie
{
    public const string Name = "readin_refresh";
    public const string ClientHeader = "X-ReadIn-Client";
    public const string WebClient = "web";
    private const string Path = "/api/v1/auth";

    public static bool IsWebClient(HttpContext http) =>
        string.Equals(http.Request.Headers[ClientHeader], WebClient, StringComparison.OrdinalIgnoreCase);

    /// <summary>The token from the body (mobile) or, for the web, from the cookie.</summary>
    public static string? Read(HttpContext http, RefreshTokenRequest? body) =>
        body?.RefreshToken is { Length: > 0 } token ? token : IsWebClient(http) ? http.Request.Cookies[Name] : null;

    public static void Clear(HttpContext http) =>
        http.Response.Cookies.Delete(Name, Options(DateTimeOffset.UnixEpoch));

    /// <summary>Sends the session; for the web the refresh token moves from the body into the cookie.</summary>
    public static IResult ToSession(this Result<AuthSessionDto> result, HttpContext http)
    {
        if (result.IsFailure)
        {
            if (result.Error.Code is "auth.refresh_invalid" && IsWebClient(http)) Clear(http);
            return result.Error.ToProblem(http);
        }

        var session = result.Value;
        if (!IsWebClient(http))
            return TypedResults.Ok(new SessionResponse(
                session.AccessToken, session.AccessTokenExpiresAt, session.RefreshToken, session.RefreshTokenExpiresAt, session.User));

        http.Response.Cookies.Append(Name, session.RefreshToken, Options(session.RefreshTokenExpiresAt));
        return TypedResults.Ok(new SessionResponse(
            session.AccessToken, session.AccessTokenExpiresAt, RefreshToken: null, session.RefreshTokenExpiresAt, session.User));
    }

    private static CookieOptions Options(DateTimeOffset expires) => new()
    {
        HttpOnly = true,
        Secure = true,
        SameSite = SameSiteMode.Strict,
        Path = Path,
        Expires = expires,
        IsEssential = true,
    };
}
