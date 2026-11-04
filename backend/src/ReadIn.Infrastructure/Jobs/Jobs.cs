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

/// <summary>
/// Recomputes <see cref="Article.QualityScore"/> of every published article in one statement (F07, ADR 0015). Hourly,
/// because freshness changes with time; the formula is <see cref="ArticleQuality.Score"/>.
/// </summary>
public sealed class ArticleQualityJob(AppDbContext db, TimeProvider clock)
{
    [DisableConcurrentExecution(timeoutInSeconds: 300)]
    public async Task RunAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        await db.Articles
            .Where(a => a.Status == ArticleStatus.Published && a.PublishedAt != null)
            .ExecuteUpdateAsync(set => set.SetProperty(a => a.QualityScore, a =>
                ArticleQuality.EngagementWeight
                    * (1.0 - 1.0 / (1.0 + (a.ReactionCount + 2.0 * a.CommentCount + 3.0 * a.SaveCount) / ArticleQuality.EngagementHalfPoint))
                + ArticleQuality.CompletionWeight
                    * ((a.ReadCount + 1.0) / ((db.ReadingProgress.Count(r => r.ArticleId == a.Id) > a.ReadCount
                        ? db.ReadingProgress.Count(r => r.ArticleId == a.Id)
                        : a.ReadCount) + 2.0))
                + ArticleQuality.FreshnessWeight
                    * Math.Pow(0.5, (EF.Functions.DateDiffHour(a.PublishedAt, now) ?? 0) / ArticleQuality.FreshnessHalfLifeHours)),
                cancellationToken);
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
