using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ReadIn.Domain.Articles;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Outbox;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>Processes outbox messages: on demand after each commit + every minute as a safety net.</summary>
public sealed class OutboxJob(OutboxProcessor processor)
{
    [DisableConcurrentExecution(timeoutInSeconds: 60)]
    [AutomaticRetry(Attempts = 0)]
    public async Task RunAsync(CancellationToken cancellationToken)
    {
        while (await processor.ProcessAsync(cancellationToken) > 0)
        {
            // Drain the backlog in batches.
        }
    }
}

/// <summary>Publishes articles whose scheduled time has passed (SPEC F05 "schedule").</summary>
public sealed class ScheduledPublishingJob(AppDbContext db, TimeProvider clock)
{
    [DisableConcurrentExecution(timeoutInSeconds: 120)]
    public async Task RunAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var due = await db.Articles
            .Include(a => a.Translations)
            .Include(a => a.Sources)
            .Include(a => a.Field)
            .Where(a => a.Status == ArticleStatus.Scheduled && a.ScheduledAt <= now)
            .Take(100)
            .ToListAsync(cancellationToken);

        foreach (var article in due)
            article.Publish(article.Field, article.ScheduledAt ?? now);

        if (due.Count > 0) await db.SaveChangesAsync(cancellationToken);
    }
}

/// <summary>
/// Enqueues an immediate outbox run. The job client is resolved lazily so that creating a DbContext (e.g. for
/// migrations) never initializes Hangfire storage before the database exists. A failed enqueue is only logged:
/// the messages are already committed and the per-minute recurring job will process them.
/// </summary>
internal sealed partial class HangfireOutboxSignal(IServiceProvider services, ILogger<HangfireOutboxSignal> logger) : IOutboxSignal
{
    public Task NotifyAsync(CancellationToken cancellationToken)
    {
        try
        {
            services.GetRequiredService<IBackgroundJobClient>().Enqueue<OutboxJob>(job => job.RunAsync(CancellationToken.None));
        }
        catch (Exception ex) when (ex is BackgroundJobClientException or InvalidOperationException)
        {
            LogEnqueueFailed(logger, ex);
        }
        return Task.CompletedTask;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not enqueue the outbox job; the recurring run will process the messages")]
    private static partial void LogEnqueueFailed(ILogger logger, Exception exception);
}
