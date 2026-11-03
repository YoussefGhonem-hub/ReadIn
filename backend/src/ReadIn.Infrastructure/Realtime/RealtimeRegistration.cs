using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Http.Resilience;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.Realtime;

internal static class RealtimeRegistration
{
    /// <summary>
    /// Live signals (SPEC §21.2, F27): the custom tokens of <c>POST /realtime/token</c> and the RTDB writer. The Firebase
    /// publisher replaces the no-op one whenever a Realtime Database is configured: <c>Firebase:DatabaseUrl</c>, or
    /// <c>Firebase:UseEmulator</c> with <c>Firebase:DatabaseEmulatorHost</c>.
    /// </summary>
    public static IServiceCollection AddRealtime(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddSingleton<IRealtimeTokenIssuer, FirebaseRealtimeTokenIssuer>();
        services.AddSingleton<IRealtimeDatabaseCredential, GoogleRealtimeDatabaseCredential>();
        services.AddHttpClient<RealtimeDatabaseClient>().AddStandardResilienceHandler(ConfigureResilience);

        var firebase = configuration.GetSection(FirebaseOptions.Section).Get<FirebaseOptions>() ?? new FirebaseOptions();
        if (firebase.RealtimeDatabaseBaseUrl is null)
            services.AddSingleton<IRealtimePublisher, NullRealtimePublisher>();
        else
            services.AddTransient<IRealtimePublisher, FirebaseRealtimePublisher>();

        return services;
    }

    /// <summary>
    /// A signal is worth a couple of quick retries, not a slow outbox: at most ~10 s per write. When the database (or the
    /// emulator in development) is down, the circuit opens and writes are skipped for a while instead of each one
    /// waiting for its timeouts.
    /// </summary>
    internal static void ConfigureResilience(HttpStandardResilienceOptions options)
    {
        options.TotalRequestTimeout.Timeout = TimeSpan.FromSeconds(10);
        options.AttemptTimeout.Timeout = TimeSpan.FromSeconds(3);
        options.Retry.MaxRetryAttempts = 2; // exponential backoff with jitter, honoring Retry-After
        options.Retry.Delay = TimeSpan.FromMilliseconds(250);
        options.CircuitBreaker.MinimumThroughput = 5;
        options.CircuitBreaker.FailureRatio = 0.5;
        options.CircuitBreaker.SamplingDuration = TimeSpan.FromSeconds(30);
        options.CircuitBreaker.BreakDuration = TimeSpan.FromSeconds(15);
    }
}
