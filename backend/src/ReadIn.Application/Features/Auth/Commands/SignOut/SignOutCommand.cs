using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Auth.Commands.SignOut;

/// <summary>Ends this device's session (its whole token family). Always succeeds, so clients can sign out offline-first.</summary>
public sealed record SignOutCommand(string? RefreshToken) : ICommand<Result>;

internal sealed class SignOutCommandHandler(IAppDbContext db, TimeProvider clock) : ICommandHandler<SignOutCommand, Result>
{
    public async ValueTask<Result> Handle(SignOutCommand command, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(command.RefreshToken)) return Result.Success();

        var hash = SecretTokens.Hash(command.RefreshToken);
        var familyId = await db.RefreshTokens
            .Where(t => t.TokenHash == hash)
            .Select(t => (Guid?)t.FamilyId)
            .FirstOrDefaultAsync(cancellationToken);
        if (familyId is null) return Result.Success();

        var now = clock.GetUtcNow().UtcDateTime;
        var family = await db.RefreshTokens.Where(t => t.FamilyId == familyId && t.RevokedAt == null).ToListAsync(cancellationToken);
        foreach (var token in family) token.Revoke(now);
        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}
