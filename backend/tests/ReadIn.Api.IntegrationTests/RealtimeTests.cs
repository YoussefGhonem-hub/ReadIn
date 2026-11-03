using System.Collections.Concurrent;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// Live updates (SPEC §21.2, F27): the custom token of <c>POST /realtime/token</c> and the feed signal the outbox sends
/// after an article is published. Firebase itself is faked here; the RTDB writes and the Admin SDK path have unit tests.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class RealtimeTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    /// <summary>The API with a fake token issuer and a publisher that records every signal.</summary>
    private WebApplicationFactory<Program> WithFakeFirebase(FakeRealtimeTokenIssuer issuer, RecordingRealtimePublisher publisher) =>
        api.WithWebHostBuilder(builder => builder.ConfigureTestServices(services =>
        {
            services.Replace(ServiceDescriptor.Singleton<IRealtimeTokenIssuer>(issuer));
            services.Replace(ServiceDescriptor.Singleton<IRealtimePublisher>(publisher));
        }));

    private static HttpClient Authorized(WebApplicationFactory<Program> host, SignedInUser user)
    {
        var client = host.CreateClient();
        client.DefaultRequestHeaders.Authorization = user.Client.DefaultRequestHeaders.Authorization;
        return client;
    }

    private static async Task<string> CodeOf(HttpResponseMessage response) =>
        (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!["code"]!.GetValue<string>();

    [Fact]
    public async Task Guests_get_no_realtime_token()
    {
        var response = await api.GuestClient().PostAsync("/api/v1/realtime/token", null, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await CodeOf(response)).Should().Be("auth.unauthorized");
    }

    [Fact]
    public async Task A_signed_in_user_gets_a_custom_token_for_their_own_id()
    {
        var issuer = new FakeRealtimeTokenIssuer();
        await using var host = WithFakeFirebase(issuer, new RecordingRealtimePublisher());
        var user = await api.SignUpAsync();

        var response = await Authorized(host, user).PostAsync("/api/v1/realtime/token", null, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.OK, await response.Content.ReadAsStringAsync(Ct));
        var body = (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
        body.Select(p => p.Key).Should().Equal("token");
        body["token"]!.GetValue<string>().Should().Be(FakeRealtimeTokenIssuer.TokenFor(user.Id));
    }

    [Fact]
    public async Task Without_firebase_the_token_call_fails_with_a_stable_code_and_is_rate_limited()
    {
        var issuer = new FakeRealtimeTokenIssuer();
        await using var host = WithFakeFirebase(issuer, new RecordingRealtimePublisher());
        var user = await api.SignUpAsync("ar");
        var client = Authorized(host, user);
        client.DefaultRequestHeaders.AcceptLanguage.ParseAdd("ar");

        issuer.Unavailable[user.Id] = true;
        var unavailable = await client.PostAsync("/api/v1/realtime/token", null, Ct);
        unavailable.StatusCode.Should().Be(HttpStatusCode.InternalServerError);
        var problem = (await unavailable.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
        problem["code"]!.GetValue<string>().Should().Be("realtime.unavailable");
        problem["title"]!.GetValue<string>().Should().Be("التحديثات اللحظية مش متاحة دلوقتي.");

        issuer.Unavailable.Clear();
        var statuses = new List<HttpStatusCode>();
        for (var i = 0; i < 10; i++) statuses.Add((await client.PostAsync("/api/v1/realtime/token", null, Ct)).StatusCode);

        statuses.Take(9).Should().AllSatisfy(s => s.Should().Be(HttpStatusCode.OK));
        statuses[^1].Should().Be(HttpStatusCode.TooManyRequests, "10 tokens a minute per user, the failed call included");
    }

    [Fact]
    public async Task Publishing_an_article_moves_the_live_feed_signal_to_its_publish_time()
    {
        var publisher = new RecordingRealtimePublisher();
        await using var host = WithFakeFirebase(new FakeRealtimeTokenIssuer(), publisher);
        var author = Authorized(host, await api.SignUpAsync());
        var dotnet = (await author.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Single(f => f!["slug"]!.GetValue<string>() == "dotnet")!["id"]!.GetValue<Guid>();
        var created = await author.PostAsJsonAsync("/api/v1/articles", new
        {
            fieldId = dotnet, language = "en", title = "Live banners need a publish signal",
            content = new
            {
                version = 1, language = "en",
                blocks = new object[] { new { id = "p1", type = "paragraph", dir = "auto", content = new[] { new { type = "text", text = "New." } } } },
            },
            sources = new[] { new { title = "ReadIn", url = "https://readin.app" } },
            isAiAssisted = false,
        }, Ct);
        created.StatusCode.Should().Be(HttpStatusCode.Created, await created.Content.ReadAsStringAsync(Ct));
        var draft = (await created.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
        publisher.FeedSignals.Should().BeEmpty("a draft is not in the feed");

        (await author.PostAsync($"/api/v1/articles/{draft["id"]}/publish", null, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        var article = (await author.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{draft["slug"]}", Ct))!;
        var publishedAt = article["publishedAt"]!.GetValue<DateTime>();
        // Hangfire is off in tests, so the outbox runs right after the commit.
        publisher.FeedSignals.Should().ContainSingle()
            .Which.Should().BeCloseTo(publishedAt.ToUniversalTime(), TimeSpan.FromMilliseconds(1), "it is the newest article in the feed");
    }

    /// <summary>Issues <see cref="TokenFor"/>, or <see cref="RealtimeErrors.Unavailable"/> for the ids in <see cref="Unavailable"/>.</summary>
    internal sealed class FakeRealtimeTokenIssuer : IRealtimeTokenIssuer
    {
        public ConcurrentDictionary<Guid, bool> Unavailable { get; } = new();

        public static string TokenFor(Guid userId) => $"custom-token-for-{userId}";

        public Task<Result<string>> IssueAsync(Guid userId, CancellationToken cancellationToken) => Task.FromResult(
            Unavailable.ContainsKey(userId) ? Result.Failure<string>(RealtimeErrors.Unavailable) : Result.Success(TokenFor(userId)));
    }

    /// <summary>Records the signals; the outbox calls it from its own scope.</summary>
    internal sealed class RecordingRealtimePublisher : IRealtimePublisher
    {
        public ConcurrentQueue<DateTime> FeedSignals { get; } = new();

        public Task PublishArticleCountersAsync(Guid articleId, ArticleLiveCounters counters, CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task PublishArticleEventAsync(Guid articleId, ArticleLiveEvent liveEvent, CancellationToken cancellationToken = default) =>
            Task.CompletedTask;

        public Task PublishFeedAsync(DateTime latestPublishedAt, CancellationToken cancellationToken = default)
        {
            FeedSignals.Enqueue(latestPublishedAt);
            return Task.CompletedTask;
        }

        public Task PublishUserNotificationsAsync(
            Guid userId, int unreadNotifications, DateTime? lastNotificationAt, CancellationToken cancellationToken = default) =>
            Task.CompletedTask;
    }
}
