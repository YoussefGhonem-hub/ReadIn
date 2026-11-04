using Hangfire;
using Hangfire.SqlServer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Auth;
using ReadIn.Infrastructure.Content;
using ReadIn.Infrastructure.Identity;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Media;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Interceptors;
using ReadIn.Infrastructure.Persistence.Outbox;
using ReadIn.Infrastructure.Persistence.Seeding;
using ReadIn.Infrastructure.Push;
using ReadIn.Infrastructure.Realtime;
using ReadIn.Infrastructure.Storage;

namespace ReadIn.Infrastructure;

public static class DependencyInjection
{
    public const string ConnectionStringName = "ReadIn";

    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration, IHostEnvironment environment)
    {
        services.AddSingleton(TimeProvider.System);

        services.Configure<ContentOptions>(configuration.GetSection(ContentOptions.Section));
        services.Configure<FirebaseOptions>(configuration.GetSection(FirebaseOptions.Section));
        services.Configure<SeedOptions>(configuration.GetSection(SeedOptions.Section));
        services.Configure<StorageOptions>(configuration.GetSection(StorageOptions.Section));
        services.Configure<AuthOptions>(configuration.GetSection(AuthOptions.Section));

        // Phone + password sign in (ADR 0007). A missing pepper or an odd PIN length stops the API at startup.
        services.AddOptions<SecurityOptions>()
            .Bind(configuration.GetSection(SecurityOptions.Section))
            .Validate(o => o.RecoveryPinPepper.Length >= 32, "Security:RecoveryPinPepper must be set to at least 32 characters (secrets only, ADR 0009).")
            .ValidateOnStart();
        services.AddOptions<RecoveryOptions>()
            .Bind(configuration.GetSection(RecoveryOptions.Section))
            .Validate(o => o.PinLength is >= 4 and <= 8, "Recovery:PinLength must be between 4 and 8.")
            .ValidateOnStart();
        services.AddMemoryCache();
        services.AddSingleton<IPasswordHasher, IdentityPasswordHasher>();
        services.AddSingleton<IRecoveryPinHasher, PepperedPinHasher>();
        services.AddSingleton<IAttemptThrottle, MemoryAttemptThrottle>();
        services.AddRealtime(configuration);
        services.Configure<ExternalAuthOptions>(configuration.GetSection(ExternalAuthOptions.Section));
        services.AddSingleton<IExternalIdentityVerifier, OidcExternalIdentityVerifier>();

        // Uploads live on this server's disk (ADR 0010); swap IFileStorage to move them to shared storage.
        services.AddSingleton<WwwrootFileStorage>();
        services.AddSingleton<IFileStorage>(sp => sp.GetRequiredService<WwwrootFileStorage>());
        services.AddSingleton<IImageProcessor, SkiaImageProcessor>();
        services.AddMedia(configuration, IsHangfireEnabled(configuration));
        services.AddPush(configuration, environment);

        var connectionString = configuration.GetConnectionString(ConnectionStringName)
            ?? throw new InvalidOperationException($"Connection string '{ConnectionStringName}' is missing.");

        services.AddScoped<AuditingInterceptor>();
        services.AddScoped<OutboxInterceptor>();
        services.AddDbContext<AppDbContext>((sp, options) => options
            .UseSqlServer(connectionString, sql => sql
                .EnableRetryOnFailure(maxRetryCount: 3)
                .UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery))
            .AddInterceptors(sp.GetRequiredService<AuditingInterceptor>(), sp.GetRequiredService<OutboxInterceptor>()));
        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());

        services.AddScoped<OutboxProcessor>();
        services.AddScoped<OutboxJob>();
        services.AddScoped<ScheduledPublishingJob>();
        services.AddScoped<OrphanedUploadsCleanupJob>();
        services.AddScoped<IdentityCleanupJob>();
        services.AddScoped<LiveEventsCleanupJob>();

        if (IsHangfireEnabled(configuration))
        {
            services.AddHangfire(config => config
                .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
                .UseSimpleAssemblyNameTypeSerializer()
                .UseRecommendedSerializerSettings()
                .UseSqlServerStorage(connectionString, new SqlServerStorageOptions
                {
                    SchemaName = "hangfire",
                    PrepareSchemaIfNecessary = true,
                    QueuePollInterval = TimeSpan.FromSeconds(5),
                }));
            services.AddHangfireServer(options => options.WorkerCount = Math.Max(2, Environment.ProcessorCount));
            services.AddScoped<IOutboxSignal, HangfireOutboxSignal>();
        }
        else
        {
            services.AddScoped<IOutboxSignal, InlineOutboxSignal>();
        }

        services.AddSingleton<ContentRepository>();

        // Seeding order: SPEC §18.2. Comments join the demo interactions with F11.
        services.AddScoped<ISeeder, RolesAndPermissionsSeeder>();
        services.AddScoped<ISeeder, TaxonomySeeder>();
        services.AddScoped<ISeeder, SystemAccountsSeeder>();
        services.AddScoped<ISeeder, DemoUsersSeeder>();
        services.AddScoped<ISeeder, OfficialAccountAvatarSeeder>();
        services.AddScoped<ISeeder, ArticlesSeeder>();
        services.AddScoped<ISeeder, LearningPathsSeeder>();
        services.AddScoped<ISeeder, GlossarySeeder>();
        services.AddScoped<ISeeder, DemoMediaSeeder>();
        services.AddScoped<ISeeder, DemoReadingSeeder>();
        services.AddScoped<ISeeder, DemoCommentsSeeder>();
        services.AddScoped<ISeeder, DemoInteractionsSeeder>();
        services.AddScoped<SeedRunner>();

        services.AddHealthChecks().AddDbContextCheck<AppDbContext>("sql");

        return services;
    }

    public static bool IsHangfireEnabled(IConfiguration configuration) => configuration.GetValue("Hangfire:Enabled", true);

    /// <summary>Applies EF migrations and optionally runs the seeders (SPEC §18.1).</summary>
    public static async Task InitializeDatabaseAsync(this IServiceProvider services, bool seed, bool forceSeed = false, CancellationToken ct = default)
    {
        await using var scope = services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.MigrateAsync(ct);

        if (seed) await scope.ServiceProvider.GetRequiredService<SeedRunner>().RunAsync(forceSeed, ct);
    }

    /// <summary>Registers recurring Hangfire jobs (no-op when Hangfire is disabled).</summary>
    public static void RegisterRecurringJobs(this IServiceProvider services, IConfiguration configuration)
    {
        if (!IsHangfireEnabled(configuration)) return;

        var jobs = services.GetRequiredService<IRecurringJobManager>();
        jobs.AddOrUpdate<OutboxJob>("outbox", job => job.RunAsync(CancellationToken.None), Cron.Minutely());
        jobs.AddOrUpdate<ScheduledPublishingJob>("publish-scheduled", job => job.RunAsync(CancellationToken.None), Cron.Minutely());
        jobs.AddOrUpdate<OrphanedUploadsCleanupJob>("uploads-orphan-cleanup", job => job.RunAsync(CancellationToken.None), Cron.Daily(3));
        jobs.AddOrUpdate<IdentityCleanupJob>("identity-cleanup", job => job.RunAsync(CancellationToken.None), Cron.Daily(3, 30));
        jobs.AddOrUpdate<DailyArticleJob>("daily-article", job => job.RunAsync(CancellationToken.None), DailyArticleJob.Schedule);
        jobs.AddOrUpdate<LiveEventsCleanupJob>("rtdb-events-cleanup", job => job.RunAsync(CancellationToken.None), Cron.Hourly());
    }

    /// <summary>
    /// Creates the uploads folder (and one sub-folder per purpose) and checks that it is writable. Fails fast with a
    /// clear message otherwise, so a server with a missing or read-only folder never starts (ADR 0010).
    /// </summary>
    /// <returns>The absolute path of the uploads folder.</returns>
    public static string PrepareUploadsFolder(this IServiceProvider services)
    {
        var storage = services.GetRequiredService<WwwrootFileStorage>();
        try
        {
            storage.EnsureWritable();
            return storage.RootPath;
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            var message = $"The uploads folder '{storage.RootPath}' is not writable. Create it and give the app's identity "
                + "write permission (docs/setup/deployment.md), or point Storage:UploadsPath at a writable folder.";
            services.GetRequiredService<ILoggerFactory>().CreateLogger(typeof(DependencyInjection)).LogCritical(ex, "{Message}", message);
            throw new InvalidOperationException(message, ex);
        }
    }
}
