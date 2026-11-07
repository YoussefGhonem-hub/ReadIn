using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Auth.Commands.RefreshSession;

/// <summary>
/// Rotating refresh (SPEC §9.3): every refresh returns a new refresh token. Presenting an already-rotated token revokes
/// the whole family, unless it was rotated within <see cref="AuthOptions.RefreshReuseGrace"/> (parallel refreshes), or
/// the client that rotated it repeats the refresh with the same retry key because the answer never reached it.
/// </summary>
internal sealed class RefreshSessionCommandHandler(
    IAppDbContext db,
    SessionIssuer sessions,
    AuditTrail audit,
    IOptions<AuthOptions> options,
    TimeProvider clock)
    : ICommandHandler<RefreshSessionCommand, Result<AuthSessionDto>>
{
    public async ValueTask<Result<AuthSessionDto>> Handle(RefreshSessionCommand command, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(command.RefreshToken)) return CredentialErrors.RefreshTokenInvalid;

        var hash = SecretTokens.Hash(command.RefreshToken);
        var token = await db.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == hash, cancellationToken);
        if (token is null) return CredentialErrors.RefreshTokenInvalid;

        var retryKeyHash = string.IsNullOrWhiteSpace(command.RetryKey) ? null : SecretTokens.Hash(command.RetryKey);
        var now = clock.GetUtcNow().UtcDateTime;
        var raced = false;
        RefreshToken? unusedSuccessor = null;
        if (!token.IsActiveAt(now))
        {
            raced = token.WasRotated && token.RevokedAt > now - options.Value.RefreshReuseGrace &&
                await db.RefreshTokens.AnyAsync(t => t.FamilyId == token.FamilyId && t.RevokedAt == null && t.ExpiresAt > now, cancellationToken);
            if (!raced)
            {
                unusedSuccessor = await RetriedSuccessorAsync(token, retryKeyHash, now, cancellationToken);
                if (unusedSuccessor is null)
                {
                    if (token.WasRotated) await RevokeFamilyAsync(token, now, cancellationToken);
                    return CredentialErrors.RefreshTokenInvalid;
                }
            }
        }

        var user = await db.Users.Include(u => u.ExternalLogins).FirstOrDefaultAsync(u => u.Id == token.UserId, cancellationToken);
        if (user is null || !user.CanSignIn)
        {
            token.Revoke(now);
            await db.SaveChangesAsync(cancellationToken);
            return CredentialErrors.RefreshTokenInvalid;
        }
        if (user.IsSuspendedAt(now)) return UserErrors.SuspendedUntil(user.SuspendedUntil);

        if (raced) return await sessions.ContinueAsync(user, token.FamilyId, cancellationToken);
        if (unusedSuccessor is not null) return await sessions.RetryAsync(user, token, unusedSuccessor, cancellationToken);
        return await sessions.RotateAsync(user, token, retryKeyHash, cancellationToken);
    }

    /// <summary>
    /// The token that replaced <paramref name="token"/>, when the client that rotated it repeats the refresh with its retry
    /// key and that token was never used: the answer was lost, so the client gets another one instead of being signed out.
    /// </summary>
    private async Task<RefreshToken?> RetriedSuccessorAsync(RefreshToken token, string? retryKeyHash, DateTime now, CancellationToken ct)
    {
        if (retryKeyHash is null || token.RetryKeyHash is null) return null;

        var successor = await db.RefreshTokens.FirstOrDefaultAsync(t => t.Id == token.ReplacedById, ct);
        return successor is not null && token.CanBeRetriedWith(retryKeyHash, successor, now) ? successor : null;
    }

    /// <summary>A copied token was used after its owner moved on: end that session on every device that holds it.</summary>
    private async Task RevokeFamilyAsync(RefreshToken reused, DateTime now, CancellationToken ct)
    {
        var family = await db.RefreshTokens.Where(t => t.FamilyId == reused.FamilyId && t.RevokedAt == null).ToListAsync(ct);
        foreach (var token in family) token.Revoke(now);
        audit.Record(AuditActions.RefreshTokenReused, reused.UserId);
        await db.SaveChangesAsync(ct);
    }
}
