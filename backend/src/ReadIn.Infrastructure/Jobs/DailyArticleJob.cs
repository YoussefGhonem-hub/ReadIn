using Hangfire;
using ReadIn.Application.Features.Feed.DailyArticle;

namespace ReadIn.Infrastructure.Jobs;

/// <summary>
/// "مقال النهارده" (SPEC F07): every 5 minutes, stores the picks due 30 minutes before each user's reminder time and sends
/// the pushes due at it, in each user's time zone. The work and its guarantees live in <see cref="DailyArticleDelivery"/>.
/// </summary>
public sealed class DailyArticleJob(DailyArticleDelivery delivery, TimeProvider clock)
{
    public const string Schedule = "*/5 * * * *";

    // One run at a time across servers; a failed run is simply retried by the next one, 5 minutes later.
    [DisableConcurrentExecution(timeoutInSeconds: 240)]
    [AutomaticRetry(Attempts = 0)]
    public Task RunAsync(CancellationToken cancellationToken) =>
        delivery.RunAsync(clock.GetUtcNow().UtcDateTime, cancellationToken);
}
