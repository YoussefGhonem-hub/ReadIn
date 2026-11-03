using Hangfire;
using Hangfire.SqlServer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure.Content;
using ReadIn.Infrastructure.Identity;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Media;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Interceptors;
using ReadIn.Infrastructure.Persistence.Outbox;
using ReadIn.Infrastructure.Persistence.Seeding;
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

        // Uploads live on this server's disk (ADR 0010); swap IFileStorage to move them to shared storage.
        services.AddSingleton<WwwrootFileStorage>();
        services.AddSingleton<IFileStorage>(sp => sp.GetRequiredService<WwwrootFileStorage>());
        services.AddSingleton<IImageProcessor, SkiaImageProcessor>();
        services.AddMedia(configuration, IsHangfireEnabled(configuration));

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
        services.AddSingleton<IIdentityProvisioner, FirebaseIdentityProvisioner>();

        // Seeding order: SPEC §18.2. Glossary (#5), paths (#7) and demo interactions (#8) arrive with F21/F09/F10–F13.
        services.AddScoped<ISeeder, RolesAndPermissionsSeeder>();
        services.AddScoped<ISeeder, TaxonomySeeder>();
        services.AddScoped<ISeeder, SystemAccountsSeeder>();
        services.AddScoped<ISeeder, DemoUsersSeeder>();
        services.AddScoped<ISeeder, ArticlesSeeder>();
        services.AddScoped<ISeeder, DemoMediaSeeder>();
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
