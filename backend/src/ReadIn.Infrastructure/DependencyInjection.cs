using Hangfire;
using Hangfire.SqlServer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Auth;
using ReadIn.Application.Features.MobileApp;
using ReadIn.Application.Features.Search;
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
using ReadIn.Infrastructure.Search;
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
        // The forced-update policy of the app: a version the app can't parse would block nobody or everybody.
        services.AddOptions<MobileAppOptions>()
            .Bind(configuration.GetSection(MobileAppOptions.Section))
            .Validate(o => o.Ios.HasValidMinimumVersion, "MobileApp:Ios:MinimumVersion must look like 1.2, 1.2.0 or 1.2.0+57, or be empty.")
            .Validate(o => o.Android.HasValidMinimumVersion, "MobileApp:Android:MinimumVersion must look like 1.2, 1.2.0 or 1.2.0+57, or be empty.")
            .Validate(o => o.Ios.HasValidStoreUrl, "MobileApp:Ios:StoreUrl must be an absolute https URL, or be empty.")
            .Validate(o => o.Android.HasValidStoreUrl, "MobileApp:Android:StoreUrl must be an absolute https URL, or be empty.")
            .ValidateOnStart();
        services.AddMemoryCache();
        services.AddSingleton<IPasswordHasher, IdentityPasswordHasher>();
        services.AddSingleton<IRecoveryPinHasher, PepperedPinHasher>();
        services.AddSingleton<IAttemptThrottle, MemoryAttemptThrottle>();
        services.AddRealtime(configuration);
        services.Configure<ExternalAuthOptions>(configuration.GetSection(ExternalAuthOptions.Section));
        // The Sign in with Apple key may come as SIWA_KEY_BASE64 (secrets only, never in the repo).
        services.PostConfigure<ExternalAuthOptions>(o =>
            o.Apple.PrivateKeyBase64 = string.IsNullOrWhiteSpace(o.Apple.PrivateKeyBase64) ? configuration["SIWA_KEY_BASE64"] : o.Apple.PrivateKeyBase64);
        services.AddSingleton<IExternalIdentityVerifier, OidcExternalIdentityVerifier>();
        services.AddHttpClient<IGoogleCodeExchanger, GoogleCodeExchanger>(http =>
        {
            http.BaseAddress = new Uri("https://oauth2.googleapis.com/");
            http.Timeout = TimeSpan.FromSeconds(10);
        });
        services.AddHttpClient<IAppleTokenService, AppleTokenService>(http =>
        {
            http.BaseAddress = new Uri("https://appleid.apple.com/");
            http.Timeout = TimeSpan.FromSeconds(10);
        });
        services.AddSingleton<IProviderTokenProtector, AesGcmProviderTokenProtector>();
        services.AddScoped<IAccountEraser, AccountEraser>();

        // Uploads live on this server's disk (ADR 0010); swap IFileStorage to move them to shared storage.
        services.AddSingleton<WwwrootFileStorage>();
        services.AddSingleton<IFileStorage>(sp => sp.GetRequiredService<WwwrootFileStorage>());
        // Files that are never public (verification proofs, SPEC F19): outside wwwroot and the uploads folder.
        services.AddSingleton<LocalPrivateFileStorage>();
        services.AddSingleton<IPrivateFileStorage>(sp => sp.GetRequiredService<LocalPrivateFileStorage>());
        services.AddSingleton<IImageProcessor, SkiaImageProcessor>();
        services.AddMedia(configuration, IsHangfireEnabled(configuration));
        Pdf.ArticlePdfRegistration.AddArticlePdf(services, configuration); // SPEC F33
        QuoteCards.QuoteCardRegistration.AddQuoteCards(services, configuration); // SPEC F24, on the F33 Chromium
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

        // Search (F16): full-text when the server has it, else the LIKE fallback; chosen at startup (SearchEngineSetup).
        services.AddSingleton<SearchEngineState>();
        services.AddScoped<FullTextSearchEngine>();
        services.AddScoped<LikeSearchEngine>();
        services.AddScoped<ISearchEngine>(sp => sp.GetRequiredService<SearchEngineState>().Kind == SearchEngineKind.FullText
            ? sp.GetRequiredService<FullTextSearchEngine>()
            : sp.GetRequiredService<LikeSearchEngine>());

        services.AddScoped<OutboxProcessor>();
        services.AddScoped<OutboxJob>();
        services.AddScoped<ArticleQualityJob>();
        services.AddScoped<ArticleExcerptsBackfillJob>();
        services.AddScoped<OrphanedUploadsCleanupJob>();
        services.AddScoped<TagCleanupJob>();
        services.AddScoped<VerificationProofsCleanupJob>();
        services.AddScoped<IdentityCleanupJob>();
        services.AddScoped<LiveEventsCleanupJob>();
        services.AddScoped<NotificationPushJob>();
        services.AddScoped<StreakReminderJob>();

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
            services.AddScoped<INotificationPushSignal, HangfireNotificationPushSignal>();
        }
        else
        {
            services.AddScoped<IOutboxSignal, InlineOutboxSignal>();
            services.AddScoped<INotificationPushSignal, NullNotificationPushSignal>();
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
        // Every article is @readin's (SPEC §18.1): demo accounts get no articles; this removes the old ones from local databases.
        services.AddScoped<ISeeder, DemoArticlesCleanupSeeder>();
        services.AddScoped<ISeeder, DemoReadingSeeder>();
        services.AddScoped<ISeeder, DemoCommentsSeeder>();
        services.AddScoped<ISeeder, DemoInteractionsSeeder>();
        services.AddScoped<ISeeder, DemoReportsSeeder>();
        services.AddScoped<ISeeder, DemoNotificationsSeeder>();
        services.AddScoped<ISeeder, DemoVerificationSeeder>();
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
        // Tags made before F32 get its rules once (SPEC F32); a no-op afterwards.
        await LegacyTagsUpgrade.RunAsync(db, ct);
        // Search (F16): the full-text indexes if the server has full-text, and the engine this API uses.
        await SearchEngineSetup.ConfigureAsync(scope.ServiceProvider, ct);

        if (seed) await scope.ServiceProvider.GetRequiredService<SeedRunner>().RunAsync(forceSeed, ct);
    }

    /// <summary>
    /// The data upgrades that follow the migrations, for an API start that doesn't migrate itself: production may apply
    /// the migrations as a SQL script or a bundle, which can't run C#. Tags made before F32 get its rules (SPEC F32). The
    /// search engine is chosen (F16), with the full-text indexes created if the server has full-text and they are missing.
    /// Each upgrade waits for its migration, and is one or two small queries once done.
    /// </summary>
    public static async Task UpgradeDataAsync(this IServiceProvider services, CancellationToken ct = default)
    {
        await using var scope = services.CreateAsyncScope();
        await LegacyTagsUpgrade.RunIfMigratedAsync(scope.ServiceProvider.GetRequiredService<AppDbContext>(), ct);
        await SearchEngineSetup.ConfigureAsync(scope.ServiceProvider, ct);
    }

    /// <summary>Registers recurring Hangfire jobs (no-op when Hangfire is disabled).</summary>
    public static void RegisterRecurringJobs(this IServiceProvider services, IConfiguration configuration)
    {
        if (!IsHangfireEnabled(configuration)) return;

        var jobs = services.GetRequiredService<IRecurringJobManager>();
        jobs.AddOrUpdate<OutboxJob>("outbox", job => job.RunAsync(CancellationToken.None), Cron.Minutely());
        jobs.RemoveIfExists("publish-scheduled"); // scheduling was removed (ADR 0015)
        jobs.AddOrUpdate<ArticleQualityJob>("article-quality", job => job.RunAsync(CancellationToken.None), Cron.Hourly(10));
        jobs.Trigger("article-quality"); // scores are fresh right after a deploy, not only at the next hour
        // Feed-card excerpts for versions published before F34: runs after every start and has nothing to do once done.
        jobs.AddOrUpdate<ArticleExcerptsBackfillJob>("article-excerpts-backfill", job => job.RunAsync(CancellationToken.None), Cron.Never());
        jobs.Trigger("article-excerpts-backfill");
        jobs.AddOrUpdate<OrphanedUploadsCleanupJob>("uploads-orphan-cleanup", job => job.RunAsync(CancellationToken.None), Cron.Daily(3));
        jobs.AddOrUpdate<VerificationProofsCleanupJob>("verification-proofs-cleanup", job => job.RunAsync(CancellationToken.None), Cron.Daily(3, 15));
        jobs.AddOrUpdate<IdentityCleanupJob>("identity-cleanup", job => job.RunAsync(CancellationToken.None), Cron.Daily(3, 30));
        jobs.AddOrUpdate<TagCleanupJob>("tags-cleanup", job => job.RunAsync(CancellationToken.None), Cron.Daily(3, 45));
        jobs.AddOrUpdate<DailyArticleJob>("daily-article", job => job.RunAsync(CancellationToken.None), DailyArticleJob.Schedule);
        jobs.AddOrUpdate<LiveEventsCleanupJob>("rtdb-events-cleanup", job => job.RunAsync(CancellationToken.None), Cron.Hourly());
        jobs.AddOrUpdate<NotificationPushJob>("notification-push", job => job.RunAsync(CancellationToken.None), Cron.Minutely());
        jobs.AddOrUpdate<StreakReminderJob>("streak-reminder", job => job.RunAsync(CancellationToken.None), StreakReminderJob.Schedule);
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

    /// <summary>
    /// Checks the private folder (verification proofs, SPEC F19) at startup: it must not overlap the web root or the uploads
    /// folder, and must be writable. Fails fast with a clear message otherwise, so a misconfigured server never starts.
    /// </summary>
    /// <returns>The absolute path of the private folder.</returns>
    public static string PreparePrivateStorage(this IServiceProvider services)
    {
        var logger = services.GetRequiredService<ILoggerFactory>().CreateLogger(typeof(DependencyInjection));
        LocalPrivateFileStorage storage;
        try
        {
            storage = services.GetRequiredService<LocalPrivateFileStorage>();
        }
        catch (InvalidOperationException ex)
        {
            logger.LogCritical(ex, "{Message}", ex.Message);
            throw;
        }

        try
        {
            storage.EnsureWritable();
            return storage.RootPath;
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            var message = $"The private folder '{storage.RootPath}' is not writable. Create it and give the app's identity "
                + "write permission (docs/setup/deployment.md), or point Storage:PrivatePath at a writable folder outside wwwroot.";
            logger.LogCritical(ex, "{Message}", message);
            throw new InvalidOperationException(message, ex);
        }
    }
}
