using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using ReadIn.Application.Common.Security;

namespace ReadIn.Api.Auth;

/// <summary>
/// Adds the ReadIn user id, roles and permissions to a Firebase-authenticated principal (SPEC §9.2 step 5).
/// Roles live in SQL Server, never in Firebase custom claims.
/// </summary>
internal sealed class ReadInClaimsTransformation(IUserAccessService access, TimeProvider clock) : IClaimsTransformation
{
    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        if (principal.Identity is not ClaimsIdentity { IsAuthenticated: true } identity) return principal;
        if (principal.HasClaim(c => c.Type == ReadInClaims.UserId)) return principal; // already transformed

        var uid = identity.FindFirst(FirebaseClaims.UserId)?.Value ?? identity.FindFirst(FirebaseClaims.Subject)?.Value;
        if (uid is null) return principal;

        var userAccess = await access.GetAsync(uid, CancellationToken.None);
        if (userAccess is null) return principal; // signed in, not synced yet: only POST /auth/sync works

        var claims = new List<Claim> { new(ReadInClaims.UserId, userAccess.UserId.ToString()) };
        claims.AddRange(userAccess.Roles.Select(r => new Claim(ReadInClaims.Role, r)));
        claims.AddRange(userAccess.Permissions.Select(p => new Claim(ReadInClaims.Permission, p)));
        if (userAccess.IsSuspendedAt(clock.GetUtcNow().UtcDateTime)) claims.Add(new Claim(ReadInClaims.Suspended, "true"));

        principal.AddIdentity(new ClaimsIdentity(claims));
        return principal;
    }
}
