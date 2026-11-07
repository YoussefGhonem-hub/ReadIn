using System.Diagnostics;
using System.Reflection;
using Hangfire;
using Hangfire.Storage;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using ReadIn.Application.Features.Admin.SystemPage;
using ReadIn.Infrastructure.Identity;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Push;
using ReadIn.Infrastructure.Realtime;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure.Admin;

/// <summary>
/// The admin console's system page (SPEC F23): this process, the database, Firebase, the recurring jobs and the disk. Slow
/// checks are cached: Firebase 60 seconds, storage 10 minutes.
/// </summary>
internal sealed class SystemProbe(
    AppDbContext db,
    IServiceProvider services,
    IOptions<FirebaseOptions> firebase,
    IHostEnvironment environment,
    WwwrootFileStorage uploads,
    LocalPrivateFileStorage privateFiles,
    IMemoryCache cache,
    TimeProvider clock) : ISystemProbe
{
    private static readonly TimeSpan CheckTimeout = TimeSpan.FromSeconds(3);
    private static readonly TimeSpan FirebaseCacheTime = TimeSpan.FromSeconds(60);
    private static readonly TimeSpan StorageCacheTime = TimeSpan.FromMinutes(10);

    private static readonly DateTime ProcessStartedAt = StartTime();
    private static readonly string Version = ReadVersion();

    public SystemApiDto Api => new(Version, ProcessStartedAt, environment.EnvironmentName);

    public async Task<SystemDatabaseDto> CheckDatabaseAsync(CancellationToken cancellationToken)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(CheckTimeout);
        var watch = Stopwatch.StartNew();
        try
        {
            await db.Database.ExecuteSqlRawAsync("SELECT 1", timeout.Token);
            return new SystemDatabaseDto(true, (int)watch.ElapsedMilliseconds);
        }
        catch (Exception ex) when (!cancellationToken.IsCancellationRequested && ex is not OutOfMemoryException)
        {
            return new SystemDatabaseDto(false, null);
        }
    }

    public async Task<SystemFirebaseDto> CheckFirebaseAsync(CancellationToken cancellationToken) =>
        (await cache.GetOrCreateAsync("admin:system:firebase", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = FirebaseCacheTime;
            var options = firebase.Value;
            var messaging = PushRegistration.UsesFcm(options, environment);
            if (options.RealtimeDatabaseBaseUrl is null) return new SystemFirebaseDto(messaging, false, null);

            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeout.CancelAfter(CheckTimeout);
            bool reachable;
            try
            {
                reachable = await services.GetRequiredService<RealtimeDatabaseClient>().GetKeysAsync("live/feed", timeout.Token) is not null;
            }
            catch (Exception ex) when (!cancellationToken.IsCancellationRequested && ex is not OutOfMemoryException)
            {
                reachable = false;
            }
            return new SystemFirebaseDto(messaging, true, reachable);
        }))!;

    public async Task<SystemStorageDto> MeasureStorageAsync(CancellationToken cancellationToken) =>
        (await cache.GetOrCreateAsync("admin:system:storage", entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = StorageCacheTime;
            var (uploadBytes, uploadFiles) = Measure(uploads.RootPath);
            var (privateBytes, privateCount) = Measure(privateFiles.RootPath);
            return Task.FromResult(new SystemStorageDto(uploadBytes, uploadFiles, privateBytes, privateCount, clock.GetUtcNow().UtcDateTime));
        }))!;

    public Task<IReadOnlyList<RecurringJobInfo>> RecurringJobsAsync(CancellationToken cancellationToken)
    {
        // Hangfire's own registrations when it runs; the API's list otherwise (tests, tools).
        if (services.GetService<JobStorage>() is { } storage)
        {
            try
            {
                using var connection = storage.GetConnection();
                var registered = connection.GetRecurringJobs();
                if (registered.Count > 0)
                    return Task.FromResult<IReadOnlyList<RecurringJobInfo>>([.. registered.Select(j => new RecurringJobInfo(j.Id, j.Cron ?? string.Empty))]);
            }
            catch (Exception ex) when (ex is not OutOfMemoryException)
            {
                // Hangfire's storage isn't reachable: fall back to the list.
            }
        }
        return Task.FromResult(RecurringJobCatalog.Infos);
    }

    /// <summary>Bytes and files under <paramref name="root"/>; a missing or unreadable folder counts what it can.</summary>
    internal static (long Bytes, int Files) Measure(string root)
    {
        if (!Directory.Exists(root)) return (0, 0);
        long bytes = 0;
        var files = 0;
        var options = new EnumerationOptions { RecurseSubdirectories = true, IgnoreInaccessible = true, AttributesToSkip = 0 };
        foreach (var file in new DirectoryInfo(root).EnumerateFiles("*", options))
        {
            bytes += file.Length;
            files++;
        }
        return (bytes, files);
    }

    private static DateTime StartTime()
    {
        try
        {
            return Process.GetCurrentProcess().StartTime.ToUniversalTime();
        }
        catch (Exception ex) when (ex is InvalidOperationException or NotSupportedException or System.ComponentModel.Win32Exception)
        {
            return DateTime.UtcNow;
        }
    }

    private static string ReadVersion()
    {
        var assembly = Assembly.GetEntryAssembly() ?? typeof(SystemProbe).Assembly;
        return assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion
            ?? assembly.GetName().Version?.ToString()
            ?? "unknown";
    }
}
