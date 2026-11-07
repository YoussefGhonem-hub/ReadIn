using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure.Identity;
using ReadIn.Infrastructure.Jobs;

namespace ReadIn.Infrastructure.Push;

internal static class PushRegistration
{
    /// <summary>
    /// Push delivery (SPEC §21.1) and the daily-article job (F07). FCM has no emulator, so emulator setups and Development
    /// without an Admin SDK key log pushes instead of sending them; everywhere else FCM is used, with
    /// <c>Firebase:ServiceAccountJson</c> or Application Default Credentials (docs/setup/firebase.md).
    /// </summary>
    public static IServiceCollection AddPush(this IServiceCollection services, IConfiguration configuration, IHostEnvironment environment)
    {
        // The sender, wrapped so every send's results reach the admin console's system page (SPEC F23).
        if (UsesFcm(configuration.GetSection(FirebaseOptions.Section).Get<FirebaseOptions>() ?? new FirebaseOptions(), environment))
        {
            services.AddSingleton<FcmPushSender>();
            services.AddSingleton<IPushSender>(sp => Recorded(sp, sp.GetRequiredService<FcmPushSender>()));
        }
        else
        {
            services.AddSingleton<LoggingPushSender>();
            services.AddSingleton<IPushSender>(sp => Recorded(sp, sp.GetRequiredService<LoggingPushSender>()));
        }

        services.AddScoped<DailyArticleJob>();
        return services;
    }

    private static PushDeliveryRecorder Recorded(IServiceProvider services, IPushSender inner) => new(
        inner,
        services.GetRequiredService<IServiceScopeFactory>(),
        services.GetRequiredService<TimeProvider>(),
        services.GetRequiredService<Microsoft.Extensions.Logging.ILogger<PushDeliveryRecorder>>());

    internal static bool UsesFcm(FirebaseOptions firebase, IHostEnvironment environment) =>
        !firebase.UseEmulator && (!environment.IsDevelopment() || !string.IsNullOrWhiteSpace(firebase.ServiceAccountJson));
}
