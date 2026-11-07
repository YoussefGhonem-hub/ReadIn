using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Push;

/// <summary>
/// Wraps the push sender (SPEC F23 system page): every send adds its devices reached, failures and invalid tokens to the
/// UTC hour's row of <c>PushDeliveryStats</c>, for the F17 pushes and the daily article alike. FCM unreachable counts every
/// device as failed. Recording never stands in the way of a push: a failed write is only logged.
/// </summary>
internal sealed partial class PushDeliveryRecorder(
    IPushSender inner, IServiceScopeFactory scopes, TimeProvider clock, ILogger<PushDeliveryRecorder> logger) : IPushSender
{
    public async Task<IReadOnlyList<PushOutcome>> SendAsync(IReadOnlyList<PushNotification> notifications, CancellationToken cancellationToken = default)
    {
        IReadOnlyList<PushOutcome> outcomes;
        try
        {
            outcomes = await inner.SendAsync(notifications, cancellationToken);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            await RecordAsync(0, notifications.Sum(n => n.Tokens.Count), 0);
            throw;
        }

        await RecordAsync(outcomes.Sum(o => o.Sent), outcomes.Sum(o => o.Failed), outcomes.Sum(o => o.InvalidTokens.Count));
        return outcomes;
    }

    /// <summary>The sender it wraps (FCM, or the logging sender where FCM isn't used).</summary>
    internal IPushSender Inner => inner;

    internal static DateTime HourOf(DateTime utc) => new(utc.Year, utc.Month, utc.Day, utc.Hour, 0, 0, DateTimeKind.Utc);

    private async Task RecordAsync(int sent, int failed, int invalid)
    {
        if (sent + failed + invalid == 0) return;
        var hour = HourOf(clock.GetUtcNow().UtcDateTime);
        try
        {
            await using var scope = scopes.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            // One row per hour, added to atomically, whoever sends at the same time.
            await db.Database.ExecuteSqlAsync(
                $"""
                MERGE [PushDeliveryStats] WITH (HOLDLOCK) AS t
                USING (SELECT {hour} AS [Hour]) AS s ON t.[Hour] = s.[Hour]
                WHEN MATCHED THEN UPDATE SET [Sent] = t.[Sent] + {sent}, [Failed] = t.[Failed] + {failed}, [InvalidTokens] = t.[InvalidTokens] + {invalid}
                WHEN NOT MATCHED THEN INSERT ([Hour], [Sent], [Failed], [InvalidTokens]) VALUES ({hour}, {sent}, {failed}, {invalid});
                """, CancellationToken.None);
        }
        catch (Exception ex)
        {
            LogNotRecorded(logger, ex);
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Push results could not be recorded for the system page")]
    private static partial void LogNotRecorded(ILogger logger, Exception exception);
}
