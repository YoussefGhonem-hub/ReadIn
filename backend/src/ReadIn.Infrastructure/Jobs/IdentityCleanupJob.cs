using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// Daily: drops expired refresh and reset tokens and old recovery attempts (SPEC §9.5), but keeps a rotated token the app
/// may still retry (<see cref="Domain.Identity.RefreshToken.CanBeRetriedWith"/>). It also finishes any account left
/// soft-deleted by the earlier 30-day deletion model: deletion is immediate now (SPEC F01), so those are erased for good.
/// </summary>
public sealed partial class IdentityCleanupJob(AppDbContext db, IAccountEraser eraser, TimeProvider clock, ILogger<IdentityCleanupJob> logger)
{
    private static readonly TimeSpan TokenRetention = TimeSpan.FromDays(7);
    private static readonly TimeSpan AttemptRetention = TimeSpan.FromDays(30);

    [DisableConcurrentExecution(timeoutInSeconds: 600)]
    [AutomaticRetry(Attempts = 1)]
    public async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;

        var tokensBefore = now - TokenRetention;
        // A token rotated with a retry key stays while the token that replaced it is unused: the app that lost that answer
        // may repeat the refresh whenever it is opened next, and must not be signed out for having stayed closed a week.
        await db.RefreshTokens
            .Where(t => t.ExpiresAt < tokensBefore || t.RevokedAt < tokensBefore)
            .Where(t => t.RetryKeyHash == null ||
                !db.RefreshTokens.Any(next => next.Id == t.ReplacedById && next.RevokedAt == null && next.ExpiresAt > now))
            .ExecuteDeleteAsync(cancellationToken);
        await db.PasswordResetTokens.Where(t => t.ExpiresAt < tokensBefore).ExecuteDeleteAsync(cancellationToken);
        var attemptsBefore = now - AttemptRetention;
        await db.RecoveryAttempts.Where(a => a.CreatedAt < attemptsBefore).ExecuteDeleteAsync(cancellationToken);

        var leftovers = await db.Users.IgnoreQueryFilters().Where(u => u.IsDeleted).Select(u => u.Id).Take(500).ToListAsync(cancellationToken);
        foreach (var userId in leftovers) await eraser.EraseAsync(userId, cancellationToken);

        if (leftovers.Count > 0) LogErased(logger, leftovers.Count);
        return leftovers.Count;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Erased {Count} accounts left soft-deleted by the earlier deletion model")]
    private static partial void LogErased(ILogger logger, int count);
}
