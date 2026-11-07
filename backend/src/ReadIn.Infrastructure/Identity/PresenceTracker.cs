using System.Data.Common;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Features.Admin.Users;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Identity;

/// <summary>
/// "Last seen" of the console's users table (SPEC F23, contract decision 7). A signed-in request writes
/// <c>UserPresence.LastSeenAt</c> at most once an hour per account: an in-memory check skips the database for the rest of the
/// hour, and the conditional upsert skips it when another process wrote it less than an hour ago. It never touches the
/// <c>Users</c> row, so its row version doesn't change under a request that loaded the user.
/// </summary>
internal sealed partial class PresenceTracker(AppDbContext db, IMemoryCache cache, TimeProvider clock, ILogger<PresenceTracker> logger)
    : IPresenceTracker
{
    public static readonly TimeSpan Interval = TimeSpan.FromHours(1);

    public async Task SeenAsync(Guid userId, CancellationToken cancellationToken)
    {
        var key = $"presence:{userId:N}";
        if (cache.TryGetValue(key, out _)) return;
        cache.Set(key, true, Interval);

        var now = clock.GetUtcNow().UtcDateTime;
        var staleBefore = now - Interval;
        try
        {
            await db.Database.ExecuteSqlAsync(
                $"""
                UPDATE [UserPresence] SET [LastSeenAt] = {now} WHERE [UserId] = {userId} AND [LastSeenAt] < {staleBefore};
                IF @@ROWCOUNT = 0
                    INSERT INTO [UserPresence] ([UserId], [LastSeenAt])
                    SELECT {userId}, {now}
                    WHERE NOT EXISTS (SELECT 1 FROM [UserPresence] WHERE [UserId] = {userId})
                      AND EXISTS (SELECT 1 FROM [Users] WHERE [Id] = {userId});
                """, cancellationToken);
        }
        catch (Exception ex) when (ex is DbException or DbUpdateException or InvalidOperationException)
        {
            // Two first requests at once (a duplicate key: the row is there), or the database is busy: last seen is best
            // effort, and the next try is in an hour.
            LogFailed(logger, ex);
        }
    }

    [LoggerMessage(Level = LogLevel.Debug, Message = "Could not record when an account was last seen")]
    private static partial void LogFailed(ILogger logger, Exception exception);
}
