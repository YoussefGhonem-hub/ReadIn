using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth;

/// <summary>Issues access + refresh tokens and saves pending changes in the same unit of work (SPEC §9.3).</summary>
internal sealed class SessionIssuer(
    IAppDbContext db,
    IAccessTokenIssuer accessTokens,
    IClientInfo client,
    IUserAccessService access,
    MeReader meReader,
    IOptions<AuthOptions> options,
    TimeProvider clock)
{
    /// <summary>A new sign in: starts a new token family.</summary>
    public Task<Result<AuthSessionDto>> StartAsync(User user, CancellationToken ct) =>
        IssueAsync(user, Guid.NewGuid(), previous: null, ct);

    /// <summary>Refresh: the next token of the same family replaces <paramref name="previous"/>.</summary>
    public Task<Result<AuthSessionDto>> RotateAsync(User user, RefreshToken previous, CancellationToken ct) =>
        IssueAsync(user, previous.FamilyId, previous, ct);

    /// <summary>Another token in an existing family, for a refresh that raced another one (<see cref="AuthOptions.RefreshReuseGrace"/>).</summary>
    public Task<Result<AuthSessionDto>> ContinueAsync(User user, Guid familyId, CancellationToken ct) =>
        IssueAsync(user, familyId, previous: null, ct);

    /// <summary>Revokes every refresh token of the user, e.g. after a password change or "sign out of all devices".</summary>
    public async Task RevokeAllAsync(Guid userId, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var active = await db.RefreshTokens.Where(t => t.UserId == userId && t.RevokedAt == null).ToListAsync(ct);
        foreach (var token in active) token.Revoke(now);
    }

    private async Task<Result<AuthSessionDto>> IssueAsync(User user, Guid familyId, RefreshToken? previous, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var (raw, hash) = SecretTokens.Create();
        var refresh = RefreshToken.Issue(user.Id, hash, familyId, now, options.Value.RefreshTokenLifetime, client.IpAddress, client.DeviceName);
        db.RefreshTokens.Add(refresh);
        previous?.RotateTo(refresh, now);

        await db.SaveChangesAsync(ct);
        // The stamp, lockout or flags may have just changed: the next request must see them.
        await access.InvalidateAsync(user.Id, ct);

        var me = await meReader.ReadAsync(user.Id, ct);
        if (me.IsFailure) return me.Error;

        var accessToken = accessTokens.Issue(user.Id, user.SecurityStamp);
        return new AuthSessionDto(accessToken.Value, accessToken.ExpiresAt, raw, refresh.ExpiresAt, me.Value);
    }
}
