using System.Security.Claims;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Api.Auth;

internal sealed class HttpCurrentUser(IHttpContextAccessor accessor) : ICurrentUser
{
    private ClaimsPrincipal? Principal => accessor.HttpContext?.User;

    public bool IsAuthenticated => Principal?.Identity?.IsAuthenticated == true;

    public string? FirebaseUid => Claim(FirebaseClaims.UserId) ?? Claim(FirebaseClaims.Subject);

    public Guid? UserId => Guid.TryParse(Claim(ReadInClaims.UserId), out var id) ? id : null;

    public string? Email => Claim(FirebaseClaims.Email);

    public string? DisplayName => Claim(FirebaseClaims.Name);

    public string? PictureUrl => Claim(FirebaseClaims.Picture);

    public string UiLanguage => RequestLanguage.Resolve(accessor.HttpContext);

    public IReadOnlySet<string> Roles => ClaimSet(ReadInClaims.Role);

    public IReadOnlySet<string> Permissions => ClaimSet(ReadInClaims.Permission);

    private string? Claim(string type) => IsAuthenticated ? Principal!.FindFirst(type)?.Value : null;

    private HashSet<string> ClaimSet(string type) =>
        Principal?.FindAll(type).Select(c => c.Value).ToHashSet(StringComparer.Ordinal) ?? [];
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
