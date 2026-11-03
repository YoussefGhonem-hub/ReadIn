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
/// the whole family, unless it was rotated within <see cref="AuthOptions.RefreshReuseGrace"/> (parallel refreshes).
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

        var now = clock.GetUtcNow().UtcDateTime;
        var raced = false;
        if (!token.IsActiveAt(now))
        {
            raced = token.WasRotated && token.RevokedAt > now - options.Value.RefreshReuseGrace &&
                await db.RefreshTokens.AnyAsync(t => t.FamilyId == token.FamilyId && t.RevokedAt == null && t.ExpiresAt > now, cancellationToken);
            if (!raced)
            {
                if (token.WasRotated) await RevokeFamilyAsync(token, now, cancellationToken);
                return CredentialErrors.RefreshTokenInvalid;
            }
        }

        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == token.UserId, cancellationToken);
        if (user is null || !user.CanSignIn)
        {
            token.Revoke(now);
            await db.SaveChangesAsync(cancellationToken);
            return CredentialErrors.RefreshTokenInvalid;
        }
        if (user.IsSuspendedAt(now)) return UserErrors.Suspended;

        return raced
            ? await sessions.ContinueAsync(user, token.FamilyId, cancellationToken)
            : await sessions.RotateAsync(user, token, cancellationToken);
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
