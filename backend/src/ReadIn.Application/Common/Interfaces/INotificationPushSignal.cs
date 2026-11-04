namespace ReadIn.Application.Common.Interfaces;

/// <summary>
/// Starts the notification push job right away once pushes that are due were written (SPEC F17). Best effort: the job
/// also runs every minute, so a lost signal only delays a push. Without Hangfire (tests, tools) it does nothing.
/// </summary>
public interface INotificationPushSignal
{
    Task NotifyAsync(CancellationToken cancellationToken);
}
