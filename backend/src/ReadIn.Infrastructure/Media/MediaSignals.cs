using System.Net.Http.Headers;
using System.Net.Http.Json;
using Google.Apis.Auth.OAuth2;
using Hangfire;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Media;
using ReadIn.Infrastructure.Identity;

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
/// Writes <c>/live/users/{userId}/media/{assetId}</c> in the Firebase Realtime Database through its REST API (the .NET
/// Admin SDK has no RTDB client), SPEC §21.2. database.rules.json lets only that user read it: the custom token from
/// <c>POST /realtime/token</c> carries the ReadIn user id as its <c>uid</c>.
/// </summary>
internal sealed partial class FirebaseMediaStatusNotifier(
    HttpClient http,
    IOptions<FirebaseOptions> options,
    ILogger<FirebaseMediaStatusNotifier> logger) : IMediaStatusNotifier
{
    private static readonly string[] Scopes =
        ["https://www.googleapis.com/auth/firebase.database", "https://www.googleapis.com/auth/userinfo.email"];

    private static GoogleCredential? _credential;

    public async Task NotifyAsync(MediaAsset asset, CancellationToken cancellationToken)
    {
        var firebase = options.Value;
        var baseUrl = firebase.UseEmulator
            ? string.IsNullOrWhiteSpace(firebase.DatabaseEmulatorHost) ? null : $"http://{firebase.DatabaseEmulatorHost}"
            : firebase.DatabaseUrl?.TrimEnd('/');
        if (baseUrl is null) return;

        try
        {
            var url = $"{baseUrl}/live/users/{asset.OwnerId}/media/{asset.Id}.json";
            if (firebase.UseEmulator) url += $"?ns={Uri.EscapeDataString(firebase.ProjectId)}";

            using var request = new HttpRequestMessage(HttpMethod.Put, url)
            {
                Content = JsonContent.Create(new Dictionary<string, object?>
                {
                    ["status"] = asset.Status.ToString().ToLowerInvariant(),
                    ["pagesReady"] = asset.Pages.Count,
                    ["pageCount"] = asset.PageCount,
                    ["failureReason"] = asset.FailureReason,
                    ["updatedAt"] = new Dictionary<string, string> { [".sv"] = "timestamp" },
                }),
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", firebase.UseEmulator
                ? "owner" // the emulator's admin token
                : await AccessTokenAsync(firebase, cancellationToken));

            using var response = await http.SendAsync(request, cancellationToken);
            if (!response.IsSuccessStatusCode) LogSignalRejected(logger, asset.Id, (int)response.StatusCode);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or InvalidOperationException or IOException)
        {
            LogSignalFailed(logger, ex, asset.Id);
        }
    }

    private static async Task<string> AccessTokenAsync(FirebaseOptions firebase, CancellationToken cancellationToken)
    {
        _credential ??= FirebaseCredentials.Create(firebase).CreateScoped(Scopes);
        return await ((ITokenAccess)_credential).GetAccessTokenForRequestAsync(cancellationToken: cancellationToken);
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "The live status of media {AssetId} was rejected with HTTP {Status}")]
    private static partial void LogSignalRejected(ILogger logger, Guid assetId, int status);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not publish the live status of media {AssetId}; clients still poll")]
    private static partial void LogSignalFailed(ILogger logger, Exception exception, Guid assetId);
}
