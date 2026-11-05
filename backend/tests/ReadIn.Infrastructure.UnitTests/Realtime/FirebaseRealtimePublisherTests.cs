using System.Net;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Media;
using ReadIn.Infrastructure.Identity;
using ReadIn.Infrastructure.Media;
using ReadIn.Infrastructure.Realtime;

namespace ReadIn.Infrastructure.UnitTests.Realtime;

/// <summary>The RTDB REST writes behind the live signals (SPEC §21.2): paths, payloads, auth and failure handling.</summary>
public sealed class FirebaseRealtimePublisherTests
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;
    private static readonly Guid ArticleId = Guid.Parse("0197a3c2-7d1e-7b3a-9c4d-5e6f708192a3");
    private static readonly Guid UserId = Guid.Parse("0197a3c2-7d1e-7b3a-9c4d-000000000042");
    private static readonly JsonObject ServerTimestamp = new() { [".sv"] = "timestamp" };

    private static FirebaseOptions Emulator() => new() { ProjectId = "demo-readin", UseEmulator = true, DatabaseEmulatorHost = "127.0.0.1:9000" };

    private static FirebaseOptions RealProject() => new()
    {
        ProjectId = "readin-cca78",
        DatabaseUrl = "https://readin-cca78-default-rtdb.europe-west1.firebasedatabase.app/",
    };

    private static (FirebaseRealtimePublisher Publisher, RecordingHandler Http) Publisher(
        FirebaseOptions? firebase = null, RecordingHandler? http = null, IRealtimeDatabaseCredential? credential = null)
    {
        http ??= new RecordingHandler();
        var client = new RealtimeDatabaseClient(
            new HttpClient(http), Options.Create(firebase ?? Emulator()), credential ?? new FakeCredential(), NullLogger<RealtimeDatabaseClient>.Instance);
        return (new FirebaseRealtimePublisher(client), http);
    }

    [Fact]
    public async Task Article_counters_patch_the_article_node_so_its_events_are_kept()
    {
        var (publisher, http) = Publisher();

        await publisher.PublishArticleCountersAsync(ArticleId, new ArticleLiveCounters(5, 4, 3, 2, CommentCount: 7, SaveCount: 9, RepostCount: 6), Ct);

        var request = http.Requests.Should().ContainSingle().Subject;
        request.Method.Should().Be(HttpMethod.Patch);
        request.Url.Should().Be($"http://127.0.0.1:9000/live/articles/{ArticleId}.json?ns=demo-readin");
        request.Authorization.Should().Be("Bearer owner");
        request.ContentType.Should().Be("application/json");
        JsonNode.DeepEquals(request.Body, new JsonObject
        {
            ["reactions"] = new JsonObject { ["insightful"] = 5, ["love"] = 4, ["fire"] = 3, ["mindBlown"] = 2 },
            ["commentCount"] = 7,
            ["saveCount"] = 9,
            ["repostCount"] = 6,
            ["updatedAt"] = ServerTimestamp.DeepClone(),
        }).Should().BeTrue(request.Body?.ToJsonString());
    }

    [Fact]
    public async Task Comment_events_are_pushed_with_the_server_time()
    {
        var (publisher, http) = Publisher();
        var commentId = Guid.CreateVersion7();
        var parentId = Guid.CreateVersion7();

        await publisher.PublishArticleEventAsync(ArticleId, new ArticleLiveEvent("reply.created", commentId, parentId), Ct);
        await publisher.PublishArticleEventAsync(ArticleId, new ArticleLiveEvent("comment.deleted", commentId), Ct);

        http.Requests.Should().HaveCount(2).And.AllSatisfy(r =>
        {
            r.Method.Should().Be(HttpMethod.Post);
            r.Url.Should().Be($"http://127.0.0.1:9000/live/articles/{ArticleId}/events.json?ns=demo-readin");
        });
        JsonNode.DeepEquals(http.Requests[0].Body, new JsonObject
        {
            ["type"] = "reply.created",
            ["commentId"] = commentId.ToString(),
            ["at"] = ServerTimestamp.DeepClone(),
            ["parentId"] = parentId.ToString(),
        }).Should().BeTrue(http.Requests[0].Body?.ToJsonString());
        http.Requests[1].Body!.AsObject().ContainsKey("parentId").Should().BeFalse("a top-level comment has no parent");
    }

    [Fact]
    public async Task The_feed_signal_is_the_publish_time_in_epoch_ms()
    {
        var (publisher, http) = Publisher();
        var publishedAt = new DateTime(2026, 11, 3, 8, 30, 0, DateTimeKind.Utc);

        await publisher.PublishFeedAsync(publishedAt, Ct);
        // SQL Server values may come back without a kind; they are UTC all the same.
        await publisher.PublishFeedAsync(DateTime.SpecifyKind(publishedAt, DateTimeKind.Unspecified), Ct);

        http.Requests.Should().HaveCount(2).And.AllSatisfy(r =>
        {
            r.Method.Should().Be(HttpMethod.Put);
            r.Url.Should().Be("http://127.0.0.1:9000/live/feed/latestPublishedAt.json?ns=demo-readin");
            r.Body!.GetValue<long>().Should().Be(new DateTimeOffset(publishedAt).ToUnixTimeMilliseconds());
        });
    }

    [Fact]
    public async Task Unread_notifications_patch_the_user_node_so_media_signals_are_kept()
    {
        var (publisher, http) = Publisher();
        var lastAt = new DateTime(2026, 11, 3, 9, 0, 0, DateTimeKind.Utc);

        await publisher.PublishUserNotificationsAsync(UserId, 3, lastAt, Ct);
        await publisher.PublishUserNotificationsAsync(UserId, 0, null, Ct);

        http.Requests.Should().AllSatisfy(r =>
        {
            r.Method.Should().Be(HttpMethod.Patch);
            r.Url.Should().Be($"http://127.0.0.1:9000/live/users/{UserId}.json?ns=demo-readin");
        });
        JsonNode.DeepEquals(http.Requests[0].Body, new JsonObject
        {
            ["unreadNotifications"] = 3,
            ["lastNotificationAt"] = new DateTimeOffset(lastAt).ToUnixTimeMilliseconds(),
        }).Should().BeTrue(http.Requests[0].Body?.ToJsonString());
        JsonNode.DeepEquals(http.Requests[1].Body, new JsonObject { ["unreadNotifications"] = 0, ["lastNotificationAt"] = null })
            .Should().BeTrue(http.Requests[1].Body?.ToJsonString());
    }

    [Fact]
    public async Task Paths_use_the_lowercase_ids_the_clients_and_rules_use()
    {
        var (publisher, http) = Publisher();

        await publisher.PublishUserNotificationsAsync(UserId, 1, null, Ct);

        http.Requests.Single().Url.Should().Contain("/live/users/0197a3c2-7d1e-7b3a-9c4d-000000000042.json");
    }

    [Fact]
    public async Task The_real_project_gets_the_service_account_access_token_and_no_namespace()
    {
        var (publisher, http) = Publisher(RealProject());

        await publisher.PublishFeedAsync(DateTime.UtcNow, Ct);

        var request = http.Requests.Should().ContainSingle().Subject;
        request.Url.Should().Be("https://readin-cca78-default-rtdb.europe-west1.firebasedatabase.app/live/feed/latestPublishedAt.json");
        request.Authorization.Should().Be($"Bearer {FakeCredential.AccessToken}");
    }

    [Fact]
    public async Task Media_status_signals_share_the_client()
    {
        var http = new RecordingHandler();
        var client = new RealtimeDatabaseClient(
            new HttpClient(http), Options.Create(Emulator()), new FakeCredential(), NullLogger<RealtimeDatabaseClient>.Instance);
        var asset = MediaAsset.StartDocument(UserId, "Report", allowDownload: false, originalSizeBytes: 1024, pageCount: 12);
        asset.StartProcessing("documents/2026/11/x/original.pdf");

        await new FirebaseMediaStatusNotifier(client).NotifyAsync(asset, Ct);

        var request = http.Requests.Should().ContainSingle().Subject;
        request.Method.Should().Be(HttpMethod.Put);
        request.Url.Should().Be($"http://127.0.0.1:9000/live/users/{UserId}/media/{asset.Id}.json?ns=demo-readin");
        JsonNode.DeepEquals(request.Body, new JsonObject
        {
            ["status"] = "processing",
            ["pagesReady"] = 0,
            ["pageCount"] = 12,
            ["failureReason"] = null,
            ["updatedAt"] = ServerTimestamp.DeepClone(),
        }).Should().BeTrue(request.Body?.ToJsonString());
    }

    [Fact]
    public async Task Nothing_is_sent_without_a_database()
    {
        FirebaseOptions[] unconfigured =
        [
            new() { ProjectId = "readin-cca78", DatabaseUrl = " " },
            // With the emulator flag only the emulator counts, so the real database never gets development signals.
            new() { UseEmulator = true, DatabaseUrl = RealProject().DatabaseUrl },
        ];

        foreach (var firebase in unconfigured)
        {
            var (publisher, http) = Publisher(firebase);
            await publisher.PublishFeedAsync(DateTime.UtcNow, Ct);
            await publisher.PublishArticleCountersAsync(ArticleId, new ArticleLiveCounters(0, 0, 0, 0, 0, 0), Ct);
            http.Requests.Should().BeEmpty();
        }
    }

    [Fact]
    public async Task Rejections_and_failures_never_reach_the_caller()
    {
        var rejected = Publisher(http: new RecordingHandler(_ => new HttpResponseMessage(HttpStatusCode.Unauthorized))).Publisher;
        var unreachable = Publisher(http: new RecordingHandler(_ => throw new HttpRequestException("connection refused"))).Publisher;
        var timedOut = Publisher(http: new RecordingHandler(_ => throw new TaskCanceledException("timeout"))).Publisher;
        var noCredential = Publisher(RealProject(), credential: new FakeCredential(fail: true)).Publisher;

        foreach (var publisher in new[] { rejected, unreachable, timedOut, noCredential })
        {
            await publisher.Invoking(p => p.PublishFeedAsync(DateTime.UtcNow, Ct)).Should().NotThrowAsync();
            await publisher.Invoking(p => p.PublishArticleEventAsync(ArticleId, new ArticleLiveEvent("comment.created", Guid.NewGuid()), Ct))
                .Should().NotThrowAsync();
        }
    }

    [Fact]
    public async Task The_callers_own_cancellation_still_cancels()
    {
        using var cancelled = new CancellationTokenSource();
        await cancelled.CancelAsync();
        var (publisher, _) = Publisher(http: new RecordingHandler(_ => throw new TaskCanceledException()));

        await publisher.Invoking(p => p.PublishFeedAsync(DateTime.UtcNow, cancelled.Token)).Should().ThrowAsync<OperationCanceledException>();
    }

    [Fact]
    public void The_firebase_publisher_replaces_the_null_one_only_when_a_database_is_configured()
    {
        static IRealtimePublisher Resolve(Dictionary<string, string?> settings)
        {
            var configuration = new ConfigurationBuilder().AddInMemoryCollection(settings).Build();
            var services = new ServiceCollection().AddLogging();
            services.Configure<FirebaseOptions>(configuration.GetSection(FirebaseOptions.Section));
            services.AddRealtime(configuration);
            return services.BuildServiceProvider().GetRequiredService<IRealtimePublisher>();
        }

        Resolve(new() { ["Firebase:UseEmulator"] = "true" }).Should().BeOfType<NullRealtimePublisher>();
        Resolve(new() { ["Firebase:ProjectId"] = "readin-cca78" }).Should().BeOfType<NullRealtimePublisher>();
        Resolve(new() { ["Firebase:UseEmulator"] = "true", ["Firebase:DatabaseEmulatorHost"] = "127.0.0.1:9000" })
            .Should().BeOfType<FirebaseRealtimePublisher>();
        Resolve(new() { ["Firebase:DatabaseUrl"] = "https://readin-cca78-default-rtdb.europe-west1.firebasedatabase.app" })
            .Should().BeOfType<FirebaseRealtimePublisher>();
    }

    [Fact]
    public async Task Transient_failures_are_retried_by_the_registered_client()
    {
        var calls = 0;
        var http = new RecordingHandler(_ => ++calls == 1
            ? new HttpResponseMessage(HttpStatusCode.ServiceUnavailable)
            : new HttpResponseMessage(HttpStatusCode.OK));
        var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Firebase:UseEmulator"] = "true",
            ["Firebase:DatabaseEmulatorHost"] = "127.0.0.1:9000",
        }).Build();
        var services = new ServiceCollection().AddLogging();
        services.Configure<FirebaseOptions>(configuration.GetSection(FirebaseOptions.Section));
        services.AddRealtime(configuration);
        services.AddHttpClient<RealtimeDatabaseClient>().ConfigurePrimaryHttpMessageHandler(() => http);
        await using var provider = services.BuildServiceProvider();

        await provider.GetRequiredService<IRealtimePublisher>().PublishFeedAsync(DateTime.UtcNow, Ct);

        http.Requests.Should().HaveCount(2, "the 503 is retried with backoff");
        http.Requests.Select(r => r.Body!.ToJsonString()).Distinct().Should().ContainSingle("the retry sends the same body");
    }

    private sealed record RecordedRequest(HttpMethod Method, string Url, string? Authorization, string? ContentType, JsonNode? Body);

    private sealed class RecordingHandler(Func<HttpRequestMessage, HttpResponseMessage>? respond = null) : HttpMessageHandler
    {
        public List<RecordedRequest> Requests { get; } = [];

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var body = request.Content is null ? null : await request.Content.ReadAsStringAsync(cancellationToken);
            Requests.Add(new RecordedRequest(
                request.Method,
                request.RequestUri!.ToString(),
                request.Headers.Authorization?.ToString(),
                request.Content?.Headers.ContentType?.MediaType,
                body is null ? null : JsonNode.Parse(body)));
            return respond?.Invoke(request) ?? new HttpResponseMessage(HttpStatusCode.OK);
        }
    }

    private sealed class FakeCredential(bool fail = false) : IRealtimeDatabaseCredential
    {
        public const string AccessToken = "ya29.test-access-token";

        public Task<string> GetAccessTokenAsync(CancellationToken cancellationToken) => fail
            ? throw new InvalidOperationException("The Application Default Credentials are not available.")
            : Task.FromResult(AccessToken);
    }
}
