using Hangfire;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Uploads;

namespace ReadIn.Infrastructure.Media;

internal static class MediaRegistration
{
    /// <summary>The media pipeline (ADR 0011): PDF inspection and rendering, the processing job and live status signals.</summary>
    public static IServiceCollection AddMedia(this IServiceCollection services, IConfiguration configuration, bool hangfireEnabled)
    {
        var section = configuration.GetSection(MediaOptions.Section);
        services.Configure<MediaOptions>(section);

        services.AddSingleton<IApiUrls, ApiUrls>();
        services.AddSingleton<IPdfInspector, PdfInspector>();
        services.AddSingleton<PdfRenderer>();
        services.AddScoped<DocumentProcessingJob>();
        services.AddHttpClient<IMediaStatusNotifier, FirebaseMediaStatusNotifier>(http => http.Timeout = TimeSpan.FromSeconds(5));

        if (hangfireEnabled)
        {
            services.AddScoped<IMediaJobScheduler, HangfireMediaJobScheduler>();
            // PDF jobs get their own server: its worker count is the concurrency limit, and they never block the default queue.
            var workers = Math.Max(1, section.Get<MediaOptions>()?.MaxConcurrentDocumentJobs ?? new MediaOptions().MaxConcurrentDocumentJobs);
            services.AddHangfireServer(options =>
            {
                options.ServerName = $"{Environment.MachineName}:media";
                options.Queues = [DocumentProcessingJob.Queue];
                options.WorkerCount = workers;
            });
        }
        else
        {
            services.AddScoped<IMediaJobScheduler, InlineMediaJobScheduler>();
        }

        return services;
    }
}
