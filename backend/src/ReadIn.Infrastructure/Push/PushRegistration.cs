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
        if (UsesFcm(configuration.GetSection(FirebaseOptions.Section).Get<FirebaseOptions>() ?? new FirebaseOptions(), environment))
            services.AddSingleton<IPushSender, FcmPushSender>();
        else
            services.AddSingleton<IPushSender, LoggingPushSender>();

        services.AddScoped<DailyArticleJob>();
        return services;
    }

    internal static bool UsesFcm(FirebaseOptions firebase, IHostEnvironment environment) =>
        !firebase.UseEmulator && (!environment.IsDevelopment() || !string.IsNullOrWhiteSpace(firebase.ServiceAccountJson));
}
