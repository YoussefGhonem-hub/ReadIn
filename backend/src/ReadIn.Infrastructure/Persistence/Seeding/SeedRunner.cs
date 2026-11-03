using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace ReadIn.Infrastructure.Persistence.Seeding;

public sealed class SeedHistory
{
    private SeedHistory() { } // EF

    public SeedHistory(string name) => Name = name;

    public string Name { get; private set; } = default!;
    public int Version { get; private set; }
    public string Checksum { get; private set; } = default!;
    public DateTime AppliedAt { get; private set; }

    public void Record(int version, string checksum, DateTime appliedAt)
    {
        Version = version;
        Checksum = checksum;
        AppliedAt = appliedAt;
    }
}

/// <summary>
/// An idempotent, versioned seeder (SPEC §18.1). It re-runs only when its <see cref="Version"/> or the
/// checksum of its input data changes.
/// </summary>
public interface ISeeder
{
    string Name { get; }
    int Order { get; }
    int Version { get; }

    bool AppliesTo(IHostEnvironment environment);

    Task<string> ComputeChecksumAsync(CancellationToken cancellationToken);

    /// <returns>false when the run was partial (e.g. Firebase unreachable) and must be retried next time.</returns>
    Task<bool> SeedAsync(CancellationToken cancellationToken);
}

public static class SeedChecksum
{
    public static string Of(params string[] parts)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(string.Join('\u001f', parts)));
        return Convert.ToHexString(bytes);
    }
}

public sealed partial class SeedRunner(
    AppDbContext db,
    IEnumerable<ISeeder> seeders,
    IHostEnvironment environment,
    TimeProvider clock,
    ILogger<SeedRunner> logger)
{
    public async Task RunAsync(bool force = false, CancellationToken cancellationToken = default)
    {
        foreach (var seeder in seeders.OrderBy(s => s.Order))
        {
            if (!seeder.AppliesTo(environment))
            {
                LogSkippedEnvironment(logger, seeder.Name, environment.EnvironmentName);
                continue;
            }

            var checksum = await seeder.ComputeChecksumAsync(cancellationToken);
            var history = await db.SeedHistory.FirstOrDefaultAsync(h => h.Name == seeder.Name, cancellationToken);
            if (!force && history is not null && history.Version == seeder.Version && history.Checksum == checksum)
            {
                LogUpToDate(logger, seeder.Name);
                continue;
            }

            LogRunning(logger, seeder.Name, seeder.Version);
            var complete = await seeder.SeedAsync(cancellationToken);
            db.ChangeTracker.Clear();

            if (!complete)
            {
                LogPartial(logger, seeder.Name);
                continue;
            }

            history = await db.SeedHistory.FirstOrDefaultAsync(h => h.Name == seeder.Name, cancellationToken);
            if (history is null)
            {
                history = new SeedHistory(seeder.Name);
                db.SeedHistory.Add(history);
            }
            history.Record(seeder.Version, checksum, clock.GetUtcNow().UtcDateTime);
            await db.SaveChangesAsync(cancellationToken);
        }
    }

    [LoggerMessage(Level = LogLevel.Debug, Message = "Seeder {Seeder} skipped in {Environment}")]
    private static partial void LogSkippedEnvironment(ILogger logger, string seeder, string environment);

    [LoggerMessage(Level = LogLevel.Debug, Message = "Seeder {Seeder} is up to date")]
    private static partial void LogUpToDate(ILogger logger, string seeder);

    [LoggerMessage(Level = LogLevel.Information, Message = "Running seeder {Seeder} v{Version}")]
    private static partial void LogRunning(ILogger logger, string seeder, int version);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Seeder {Seeder} finished partially; it will run again next time")]
    private static partial void LogPartial(ILogger logger, string seeder);
}

public static class SeedEnvironments
{
    /// <summary>
    /// Demo users and demo interactions are seeded only into the Firebase Auth Emulator and the local database, never into
    /// the real Firebase project (SPEC §18.1, ADR 0005): the environment must be local AND Firebase must be the emulator.
    /// </summary>
    public static bool AllowsDemoData(IHostEnvironment env, Identity.FirebaseOptions firebase) =>
        (env.IsDevelopment() || env.IsEnvironment("Testing")) && firebase.UseEmulator;
}
