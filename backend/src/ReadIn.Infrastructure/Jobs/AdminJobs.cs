using System.Diagnostics;
using Hangfire;
using Hangfire.Server;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Features.Admin.SystemPage;
using ReadIn.Domain.Admin;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Realtime;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// The recurring jobs the API registers (<see cref="DependencyInjection.RegisterRecurringJobs"/>), for the system page when
/// Hangfire doesn't run (tests, tools) and to name the runs of jobs enqueued on demand (the outbox and push signals).
/// Keep it in step with the registrations.
/// </summary>
public static class RecurringJobCatalog
{
    public const string AdminCleanup = "admin-cleanup";

    /// <summary>F35: Answered tickets close 14 days after the last support reply (hourly).</summary>
    public const string SupportAutoClose = "support-auto-close";

    /// <summary>F35: tickets closed more than a year ago go, with their screenshots (daily).</summary>
    public const string SupportRetention = "support-retention";

    public static readonly IReadOnlyList<(string Id, Type JobType, string Schedule)> All =
    [
        (SupportAutoClose, typeof(SupportAutoCloseJob), Cron.Hourly(20)),
        (SupportRetention, typeof(SupportRetentionJob), Cron.Daily(4, 15)),
        ("outbox", typeof(OutboxJob), Cron.Minutely()),
        ("article-quality", typeof(ArticleQualityJob), Cron.Hourly(10)),
        ("article-excerpts-backfill", typeof(ArticleExcerptsBackfillJob), Cron.Never()),
        ("uploads-orphan-cleanup", typeof(OrphanedUploadsCleanupJob), Cron.Daily(3)),
        ("verification-proofs-cleanup", typeof(VerificationProofsCleanupJob), Cron.Daily(3, 15)),
        ("identity-cleanup", typeof(IdentityCleanupJob), Cron.Daily(3, 30)),
        ("tags-cleanup", typeof(TagCleanupJob), Cron.Daily(3, 45)),
        (AdminCleanup, typeof(AdminCleanupJob), Cron.Daily(3, 50)),
        ("daily-article", typeof(DailyArticleJob), DailyArticleJob.Schedule),
        ("rtdb-events-cleanup", typeof(LiveEventsCleanupJob), Cron.Hourly()),
        ("notification-push", typeof(NotificationPushJob), Cron.Minutely()),
        ("streak-reminder", typeof(StreakReminderJob), StreakReminderJob.Schedule),
    ];

    /// <summary>The recurring job id of a job class, for runs enqueued on demand (they carry no recurring job id).</summary>
    public static string? IdOf(Type jobType) => All.FirstOrDefault(j => j.JobType == jobType).Id;

    public static IReadOnlyList<RecurringJobInfo> Infos => [.. All.Select(j => new RecurringJobInfo(j.Id, j.Schedule))];
}

/// <summary>
/// Records every run of a recurring job in <c>JobRuns</c> (SPEC F23 system page): when, how long, and the error of a failed
/// run. A Hangfire server filter, so it sees every job; a run that can't be recorded is only logged.
/// </summary>
internal sealed partial class JobRunRecorder(IServiceScopeFactory scopes, TimeProvider clock, ILogger<JobRunRecorder> logger) : IServerFilter
{
    private const string StartedKey = "readin:job-run-started";
    private const string WatchKey = "readin:job-run-watch";

    public void OnPerforming(PerformingContext context)
    {
        context.Items[StartedKey] = clock.GetUtcNow().UtcDateTime;
        context.Items[WatchKey] = Stopwatch.StartNew();
    }

    public void OnPerformed(PerformedContext context)
    {
        try
        {
            if (!context.Items.TryGetValue(StartedKey, out var startedItem) || startedItem is not DateTime started) return;
            var duration = context.Items.TryGetValue(WatchKey, out var watchItem) && watchItem is Stopwatch watch
                ? (int)Math.Min(int.MaxValue, watch.ElapsedMilliseconds)
                : 0;
            var failed = context.Exception is not null && !context.ExceptionHandled;
            Record(RecurringId(context), context.BackgroundJob.Job.Type, started, duration, failed ? context.Exception : null);
        }
        catch (Exception ex)
        {
            LogNotRecorded(logger, ex, context.BackgroundJob?.Id);
        }
    }

    /// <summary>
    /// Writes one run: named by its recurring job id, or for a job enqueued on demand by its class; a job that isn't a
    /// recurring one (e.g. media processing) isn't recorded.
    /// </summary>
    /// <param name="error">The exception of a failed run; null for a success.</param>
    internal void Record(string? recurringId, Type jobType, DateTime startedAt, int durationMs, Exception? error)
    {
        var id = string.IsNullOrWhiteSpace(recurringId) ? RecurringJobCatalog.IdOf(jobType) : recurringId;
        if (id is null) return;

        using var scope = scopes.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.JobRuns.Add(new JobRun(id, startedAt, durationMs, error is null, error is null ? null : Describe(error)));
        db.SaveChanges();
    }

    private static string? RecurringId(PerformContext context)
    {
        try
        {
            return context.GetJobParameter<string>("RecurringJobId");
        }
        catch (Exception)
        {
            return null; // an unreadable parameter: the run is named by its job class instead
        }
    }

    /// <summary>The innermost exception's type and message: the job's own error, not Hangfire's wrapper.</summary>
    internal static string Describe(Exception exception)
    {
        var inner = exception;
        while (inner.InnerException is not null && inner is not OperationCanceledException) inner = inner.InnerException;
        var text = $"{inner.GetType().Name}: {inner.Message}";
        return text.Length <= JobRun.MaxErrorLength ? text : text[..JobRun.MaxErrorLength];
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "The run of background job {JobId} could not be recorded")]
    private static partial void LogNotRecorded(ILogger logger, Exception exception, string? jobId);
}

/// <summary>
/// Daily (03:50 UTC, SPEC F23): deletes searches with no results older than 90 days, and job runs and push results older
/// than 7 days.
/// </summary>
public sealed partial class AdminCleanupJob(AppDbContext db, TimeProvider clock, ILogger<AdminCleanupJob> logger)
{
    [DisableConcurrentExecution(timeoutInSeconds: 300)]
    public async Task RunAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var missesBefore = DateOnly.FromDateTime(now - SearchMiss.Retention);
        var runsBefore = now - JobRun.Retention;
        var pushBefore = now - PushDeliveryStat.Retention;

        var misses = await db.SearchMisses.Where(m => m.Date < missesBefore).ExecuteDeleteAsync(cancellationToken);
        var runs = await db.JobRuns.Where(r => r.StartedAt < runsBefore).ExecuteDeleteAsync(cancellationToken);
        var stats = await db.PushDeliveryStats.Where(s => s.Hour < pushBefore).ExecuteDeleteAsync(cancellationToken);
        if (misses + runs + stats > 0) LogCleaned(logger, misses, runs, stats);
    }

    [LoggerMessage(Level = LogLevel.Information,
        Message = "Admin cleanup: {Misses} old search misses, {Runs} old job runs and {Stats} old push results deleted")]
    private static partial void LogCleaned(ILogger logger, int misses, int runs, int stats);
}
