using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.MobileApp;
using ReadIn.Application.Features.MobileApp.Queries.GetUpdatePolicy;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Admin.SystemPage;

/// <param name="Version">The API's informational version (the build).</param>
/// <param name="StartedAt">When this process started.</param>
/// <param name="Environment"><c>Production</c>, <c>Staging</c>, <c>Development</c> or <c>Testing</c>.</param>
public sealed record SystemApiDto(string Version, DateTime StartedAt, string Environment);

/// <param name="LatencyMs">The <c>SELECT 1</c>'s time; null when it failed.</param>
public sealed record SystemDatabaseDto(bool Reachable, int? LatencyMs);

/// <param name="RealtimeReachable">A read of the Realtime Database answered within 3 seconds; null when it isn't configured.</param>
public sealed record SystemFirebaseDto(bool MessagingConfigured, bool RealtimeConfigured, bool? RealtimeReachable);

/// <param name="Id">The Hangfire recurring job id, e.g. <c>notification-push</c>.</param>
/// <param name="Schedule">Its cron expression.</param>
/// <param name="LastError">The exception's type and message (≤ 500).</param>
public sealed record AdminJobStatusDto(
    string Id,
    string Schedule,
    DateTime? LastRunAt,
    bool? LastSucceeded,
    int? LastDurationMs,
    string? LastError,
    int Runs24h,
    int Failures24h);

/// <param name="Since">The start of the 24 hours counted.</param>
public sealed record SystemPushDto(int Sent, int Failed, int InvalidTokens, DateTime Since);

public sealed record SystemStorageDto(long UploadsBytes, int UploadsFiles, long PrivateBytes, int PrivateFiles, DateTime MeasuredAt);

/// <summary>GET /admin/system (SPEC F23): read only; settings still change in configuration.</summary>
public sealed record AdminSystemDto(
    SystemApiDto Api,
    UpdatePolicyDto UpdatePolicy,
    SystemDatabaseDto Database,
    SystemFirebaseDto Firebase,
    IReadOnlyList<AdminJobStatusDto> Jobs,
    SystemPushDto Push,
    SystemStorageDto Storage);

/// <summary>A recurring background job as registered (its id and cron).</summary>
public sealed record RecurringJobInfo(string Id, string Schedule);

/// <summary>What only the infrastructure can tell about the running system (SPEC F23 system page).</summary>
public interface ISystemProbe
{
    SystemApiDto Api { get; }

    /// <summary>A <c>SELECT 1</c> within 3 seconds.</summary>
    Task<SystemDatabaseDto> CheckDatabaseAsync(CancellationToken cancellationToken);

    /// <summary>Whether FCM and the Realtime Database are configured, and the database answers (cached 60 seconds).</summary>
    Task<SystemFirebaseDto> CheckFirebaseAsync(CancellationToken cancellationToken);

    /// <summary>Bytes and files under the uploads folder and the private store (cached 10 minutes).</summary>
    Task<SystemStorageDto> MeasureStorageAsync(CancellationToken cancellationToken);

    /// <summary>Every recurring job: Hangfire's registrations when it runs, else the jobs the API registers.</summary>
    Task<IReadOnlyList<RecurringJobInfo>> RecurringJobsAsync(CancellationToken cancellationToken);
}

/// <summary>
/// GET /admin/system (SPEC F23, <c>system.settings</c>): the API, the app update policy, the database and Firebase, every
/// recurring job's last run and its runs and failures in 24 hours (<c>JobRuns</c>), push results in 24 hours
/// (<c>PushDeliveryStats</c>) and the disk used.
/// </summary>
[RequirePermission(Permissions.System.Settings)]
public sealed record GetSystemStatusQuery : IQuery<Result<AdminSystemDto>>;

internal sealed class GetSystemStatusQueryHandler(IAppDbContext db, ISystemProbe probe, ISender sender, TimeProvider clock)
    : IQueryHandler<GetSystemStatusQuery, Result<AdminSystemDto>>
{
    public static readonly TimeSpan Window = TimeSpan.FromHours(24);

    public async ValueTask<Result<AdminSystemDto>> Handle(GetSystemStatusQuery query, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var since = now - Window;
        var database = await probe.CheckDatabaseAsync(ct);
        var firebase = await probe.CheckFirebaseAsync(ct);
        var storage = await probe.MeasureStorageAsync(ct);
        var registered = await probe.RecurringJobsAsync(ct);

        var counts = await db.JobRuns.AsNoTracking()
            .Where(r => r.StartedAt >= since)
            .GroupBy(r => r.Job)
            .Select(g => new { Job = g.Key, Runs = g.Count(), Failures = g.Count(r => !r.Succeeded) })
            .ToDictionaryAsync(g => g.Job, ct);
        var lastRuns = await db.JobRuns.AsNoTracking()
            .Where(r => !db.JobRuns.Any(o => o.Job == r.Job && (o.StartedAt > r.StartedAt || (o.StartedAt == r.StartedAt && o.Id.CompareTo(r.Id) > 0))))
            .Select(r => new { r.Job, r.StartedAt, r.Succeeded, r.DurationMs, r.Error })
            .ToListAsync(ct);
        var last = lastRuns.GroupBy(r => r.Job).ToDictionary(g => g.Key, g => g.First());

        // Every registered job, plus any job that ran without being registered here (e.g. one removed since).
        var ids = registered.Select(j => j.Id).Union(last.Keys).Distinct(StringComparer.Ordinal).Order(StringComparer.Ordinal);
        var schedules = registered.ToDictionary(j => j.Id, j => j.Schedule, StringComparer.Ordinal);
        var jobs = ids.Select(id =>
        {
            var run = last.GetValueOrDefault(id);
            var count = counts.GetValueOrDefault(id);
            return new AdminJobStatusDto(
                id, schedules.GetValueOrDefault(id) ?? string.Empty, run?.StartedAt, run?.Succeeded, run?.DurationMs, run?.Error,
                count?.Runs ?? 0, count?.Failures ?? 0);
        }).ToList();

        var hourFrom = new DateTime(since.Year, since.Month, since.Day, since.Hour, 0, 0, DateTimeKind.Utc);
        // At most 25 hourly rows.
        var push = await db.PushDeliveryStats.AsNoTracking().Where(s => s.Hour >= hourFrom).ToListAsync(ct);

        var updatePolicy = await sender.Send(new GetUpdatePolicyQuery(), ct);
        return new AdminSystemDto(
            probe.Api, updatePolicy, database, firebase, jobs,
            new SystemPushDto(push.Sum(s => s.Sent), push.Sum(s => s.Failed), push.Sum(s => s.InvalidTokens), hourFrom),
            storage);
    }
}
