using Hangfire;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Notifications;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// Sends the notification pushes that are due (SPEC F17): every minute, and right after new ones are written. The work and
/// its guarantees live in <see cref="NotificationPusher"/>. One run at a time, so no push is sent twice.
/// </summary>
public sealed class NotificationPushJob(NotificationPusher pusher, TimeProvider clock)
{
    [DisableConcurrentExecution(timeoutInSeconds: 60)]
    [AutomaticRetry(Attempts = 0)]
    public Task RunAsync(CancellationToken cancellationToken) => pusher.RunAsync(clock.GetUtcNow().UtcDateTime, cancellationToken);
}

/// <summary>The 20:00 streak reminder (SPEC F17), every 5 minutes; see <see cref="StreakReminders"/>.</summary>
public sealed class StreakReminderJob(StreakReminders reminders, TimeProvider clock)
{
    public const string Schedule = "*/5 * * * *";

    [DisableConcurrentExecution(timeoutInSeconds: 240)]
    [AutomaticRetry(Attempts = 0)]
    public Task RunAsync(CancellationToken cancellationToken) => reminders.RunAsync(clock.GetUtcNow().UtcDateTime, cancellationToken);
}

/// <summary>
/// Enqueues an immediate push run. Like the outbox signal, the job client is resolved lazily and a failed enqueue is only
/// logged: the entries are committed and the per-minute run sends them.
/// </summary>
internal sealed partial class HangfireNotificationPushSignal(IServiceProvider services, ILogger<HangfireNotificationPushSignal> logger)
    : INotificationPushSignal
{
    public Task NotifyAsync(CancellationToken cancellationToken)
    {
        try
        {
            services.GetRequiredService<IBackgroundJobClient>().Enqueue<NotificationPushJob>(job => job.RunAsync(CancellationToken.None));
        }
        catch (Exception ex) when (ex is BackgroundJobClientException or InvalidOperationException)
        {
            LogEnqueueFailed(logger, ex);
        }
        return Task.CompletedTask;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not enqueue the notification push job; the recurring run will send the pushes")]
    private static partial void LogEnqueueFailed(ILogger logger, Exception exception);
}

/// <summary>Without Hangfire (tests, tools) nothing runs the push job on its own; tests run it explicitly.</summary>
internal sealed class NullNotificationPushSignal : INotificationPushSignal
{
    public Task NotifyAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
