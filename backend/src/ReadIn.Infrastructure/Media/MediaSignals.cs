using Hangfire;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Media;
using ReadIn.Infrastructure.Realtime;

namespace ReadIn.Infrastructure.Media;

/// <summary>Queues PDF rendering on the dedicated <c>media</c> Hangfire queue.</summary>
internal sealed class HangfireMediaJobScheduler(IBackgroundJobClient jobs) : IMediaJobScheduler
{
    public Task EnqueueDocumentAsync(Guid assetId, CancellationToken cancellationToken)
    {
        jobs.Enqueue<DocumentProcessingJob>(job => job.RunAsync(assetId, CancellationToken.None));
        return Task.CompletedTask;
    }
}

/// <summary>
/// Without Hangfire (tests, the ContentStudio CLI) the job runs right away in its own scope, still outside the
/// upload's DbContext and still bounded by the job timeout.
/// </summary>
internal sealed class InlineMediaJobScheduler(IServiceScopeFactory scopes) : IMediaJobScheduler
{
    public async Task EnqueueDocumentAsync(Guid assetId, CancellationToken cancellationToken)
    {
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<DocumentProcessingJob>().RunAsync(assetId, cancellationToken);
    }
}

/// <summary>
/// Writes <c>{ status, pagesReady, pageCount, failureReason, updatedAt }</c> to <c>/live/users/{userId}/media/{assetId}</c>
/// (ADR 0011, SPEC §21.2). database.rules.json lets only that user read it: the custom token from
/// <c>POST /realtime/token</c> carries the ReadIn user id as its <c>uid</c>. Best effort, because clients also poll.
/// </summary>
internal sealed class FirebaseMediaStatusNotifier(RealtimeDatabaseClient database) : IMediaStatusNotifier
{
    public Task NotifyAsync(MediaAsset asset, CancellationToken cancellationToken) =>
        database.PutAsync($"live/users/{asset.OwnerId}/media/{asset.Id}", new Dictionary<string, object?>
        {
            ["status"] = asset.Status.ToString().ToLowerInvariant(),
            ["pagesReady"] = asset.Pages.Count,
            ["pageCount"] = asset.PageCount,
            ["failureReason"] = asset.FailureReason,
            ["updatedAt"] = RealtimeDatabaseClient.ServerTimestamp,
        }, cancellationToken);
}
