using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// Daily: anonymizes accounts deleted more than 30 days ago (SPEC F01: their content stays as "Deleted user"; the
/// orphaned avatar is removed by <see cref="OrphanedUploadsCleanupJob"/>), and drops expired refresh and reset tokens
/// and old recovery attempts.
/// </summary>
public sealed partial class IdentityCleanupJob(AppDbContext db, TimeProvider clock, ILogger<IdentityCleanupJob> logger)
{
    private static readonly TimeSpan TokenRetention = TimeSpan.FromDays(7);
    private static readonly TimeSpan AttemptRetention = TimeSpan.FromDays(30);

    [DisableConcurrentExecution(timeoutInSeconds: 600)]
    [AutomaticRetry(Attempts = 1)]
    public async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var anonymized = await AnonymizeDeletedAccountsAsync(now, cancellationToken);

        var tokensBefore = now - TokenRetention;
        await db.RefreshTokens.Where(t => t.ExpiresAt < tokensBefore || t.RevokedAt < tokensBefore).ExecuteDeleteAsync(cancellationToken);
        await db.PasswordResetTokens.Where(t => t.ExpiresAt < tokensBefore).ExecuteDeleteAsync(cancellationToken);
        var attemptsBefore = now - AttemptRetention;
        await db.RecoveryAttempts.Where(a => a.CreatedAt < attemptsBefore).ExecuteDeleteAsync(cancellationToken);

        if (anonymized > 0) LogAnonymized(logger, anonymized);
        return anonymized;
    }

    private async Task<int> AnonymizeDeletedAccountsAsync(DateTime now, CancellationToken ct)
    {
        var cutoff = now - AccountSecurity.DeletionGracePeriod;
        var users = await db.Users.IgnoreQueryFilters()
            .Include(u => u.Devices)
            .Include(u => u.Interests)
            .Include(u => u.ExternalLogins)
            .Where(u => u.IsDeleted && u.DeletedAt < cutoff && u.AnonymizedAt == null)
            .Take(500)
            .ToListAsync(ct);

        foreach (var user in users)
        {
            user.Anonymize(now);
            db.AuditLogs.Add(AuditLog.Record(AuditActions.AccountAnonymized, actorId: null, user.Id, ip: null, now));
        }
        await db.SaveChangesAsync(ct);
        return users.Count;
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Anonymized {Count} accounts deleted more than 30 days ago")]
    private static partial void LogAnonymized(ILogger logger, int count);
}
