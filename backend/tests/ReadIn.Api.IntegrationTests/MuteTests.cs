using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles.Counters;
using ReadIn.Application.Features.Search;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;
using ReadIn.Infrastructure.Search;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F28 Mute and "show less" (contract-v1 "Mute &amp; feedback"): the endpoints, their errors, limits and permission, the
/// lists that leave out what a reader muted or marked, the For you tiers, the viewer flags, Today's article, comments,
/// notifications and account deletion. Each test works in fields of its own (disabled again afterwards), so the lists it
/// checks are exact; lists shared by the whole suite (Explore's rankings and new writers) are checked for the test's own
/// ids only.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class MuteTests(ApiFactory api) : IAsyncLifetime
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;
    private readonly List<Guid> _fields = [];

    private sealed record TestField(Guid Id, string Slug, string Word, Guid TopicA, string TopicASlug, Guid TopicB);

    public ValueTask InitializeAsync() => ValueTask.CompletedTask;

    public async ValueTask DisposeAsync()
    {
        if (_fields.Count == 0) return;
        await WithDbAsync(async db =>
        {
            foreach (var field in await db.Fields.Where(f => _fields.Contains(f.Id)).ToListAsync())
                field.Update(field.NameAr, field.NameEn, field.Icon, field.Color, field.SortOrder, field.IsSensitive, field.RequiresSources, isEnabled: false);
            await db.SaveChangesAsync();
        });
        await ClearCachesAsync();
    }

    // ── Writers ─────────────────────────────────────────────────

    [Fact]
    public async Task Muting_a_writer_is_idempotent_ends_the_follow_and_the_undo_follows_again()
    {
        var writer = await api.UserAsync("Muted Writer");
        var reader = await api.UserAsync("Muting Reader");

        await api.GuestClient().PutEmptyAsync($"/api/v1/users/{writer.Id}/mute").ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
        await api.GuestClient().GetAsync("/api/v1/me/mutes", Ct).ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
        await reader.Client.PutEmptyAsync($"/api/v1/users/{reader.Id}/mute").ProblemAsync(HttpStatusCode.BadRequest, "mute.self");
        await reader.Client.PutEmptyAsync($"/api/v1/users/{SystemUsers.EditorialId}/mute").ProblemAsync(HttpStatusCode.BadRequest, "mute.system_account");
        await reader.Client.PutEmptyAsync($"/api/v1/users/{Guid.NewGuid()}/mute").ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        await reader.Client.DeleteAsync($"/api/v1/users/{Guid.NewGuid()}/mute", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");

        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        var muted = await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/mute").OkJsonAsync();
        muted.Select(p => p.Key).Should().Equal("isMuted", "isFollowing", "followerCount", "followRemoved");
        (muted["isMuted"]!.GetValue<bool>(), muted["isFollowing"]!.GetValue<bool>(), muted["followerCount"]!.GetValue<int>(), muted["followRemoved"]!.GetValue<bool>())
            .Should().Be((true, false, 0, true), "a mute ends the follow");
        var again = await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/mute").OkJsonAsync();
        (again["isMuted"]!.GetValue<bool>(), again["followRemoved"]!.GetValue<bool>()).Should().Be((true, false), "nothing left to end");

        // The toast's Undo puts the follow back.
        var undone = await reader.Client.DeleteAsync($"/api/v1/users/{writer.Id}/mute?restoreFollow=true", Ct).OkJsonAsync();
        (undone["isMuted"]!.GetValue<bool>(), undone["isFollowing"]!.GetValue<bool>(), undone["followerCount"]!.GetValue<int>(), undone["followRemoved"]!.GetValue<bool>())
            .Should().Be((false, true, 1, false));

        // Following a muted writer ends the mute: the two never hold at once.
        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/mute").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        (await MutesAsync(reader))["users"]!.AsArray().Should().BeEmpty();

        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/mute").OkJsonAsync();
        var plain = await reader.Client.DeleteAsync($"/api/v1/users/{writer.Id}/mute", Ct).OkJsonAsync();
        (plain["isMuted"]!.GetValue<bool>(), plain["isFollowing"]!.GetValue<bool>()).Should().Be((false, false), "Settings → Muted doesn't follow again");
        (await reader.Client.DeleteAsync($"/api/v1/users/{writer.Id}/mute", Ct).OkJsonAsync())["isMuted"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task Restore_follow_follows_again_like_a_follow_and_only_when_the_undo_asks_for_it()
    {
        var writer = await api.UserAsync("Never Followed");
        var reader = await api.UserAsync();
        var url = $"/api/v1/users/{writer.Id}/mute";

        // A mute of a writer you didn't follow ends nothing: followRemoved is false, so the toast's Undo is a plain unmute.
        var muted = await reader.Client.PutEmptyAsync(url).OkJsonAsync();
        State(muted).Should().Be((true, false, 0, false));
        State(await reader.Client.DeleteAsync($"{url}?restoreFollow=false", Ct).OkJsonAsync()).Should().Be((false, false, 0, false));

        // restoreFollow=true is "follow again" as PUT /users/{id}/follow (the server keeps no record of an ended follow;
        // clients send it only after followRemoved: true), and it is idempotent: one follower however often it comes.
        await reader.Client.PutEmptyAsync(url).OkJsonAsync();
        State(await reader.Client.DeleteAsync($"{url}?restoreFollow=true", Ct).OkJsonAsync()).Should().Be((false, true, 1, false));
        State(await reader.Client.DeleteAsync($"{url}?restoreFollow=true", Ct).OkJsonAsync()).Should().Be((false, true, 1, false));

        // After a mute that did end the follow, the plain unmute (the banner, Settings → Muted) doesn't follow again.
        State(await reader.Client.PutEmptyAsync(url).OkJsonAsync()).Should().Be((true, false, 0, true));
        State(await reader.Client.DeleteAsync(url, Ct).OkJsonAsync()).Should().Be((false, false, 0, false));
        (await reader.Client.GetAsync($"/api/v1/users/{writer.Me["username"]!.GetValue<string>()}", Ct).OkJsonAsync())["isFollowing"]!
            .GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task Settings_lists_muted_writers_fields_and_topics_newest_first()
    {
        var field = await NewFieldAsync();
        var first = await api.UserAsync("First Muted");
        var second = await api.UserAsync("Second Muted");
        var reader = await api.UserAsync();

        await reader.Client.PutEmptyAsync($"/api/v1/users/{first.Id}/mute").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/users/{second.Id}/mute").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{Guid.NewGuid()}").ProblemAsync(HttpStatusCode.NotFound, "field.not_found");
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/topics/{Guid.NewGuid()}").ProblemAsync(HttpStatusCode.NotFound, "topic.not_found");

        var topic = await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/topics/{field.TopicA}").OkJsonAsync();
        topic.Select(p => p.Key).Should().Equal("fieldIds", "topicIds");
        Guids(topic["topicIds"]).Should().Equal(field.TopicA);
        var both = await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{field.Id}").OkJsonAsync();
        Guids(both["fieldIds"]).Should().Equal(field.Id);
        Guids(both["topicIds"]).Should().Equal(field.TopicA);
        Guids((await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{field.Id}").OkJsonAsync())["fieldIds"]).Should().Equal(field.Id);

        var mutes = await MutesAsync(reader);
        mutes.Select(p => p.Key).Should().Equal("users", "fields", "topics");
        Ids(mutes["users"]).Should().Equal(second.Id, first.Id);
        mutes["users"]![0]!.AsObject().Select(p => p.Key).Should().Equal(
            "id", "displayName", "username", "avatarUrl", "isVerified", "headline", "bio", "isFollowing", "followsYou");
        var mutedField = mutes["fields"]!.AsArray().Single()!.AsObject();
        mutedField.Select(p => p.Key).Should().Equal("id", "slug", "name", "nameAr", "nameEn", "icon", "color");
        mutedField["name"]!.GetValue<string>().Should().Be($"Field {field.Word}", "names follow Accept-Language");
        var mutedTopic = mutes["topics"]!.AsArray().Single()!.AsObject();
        mutedTopic["id"]!.GetValue<Guid>().Should().Be(field.TopicA);
        mutedTopic["field"]!["slug"]!.GetValue<string>().Should().Be(field.Slug);

        var left = await reader.Client.DeleteAsync($"/api/v1/me/mutes/fields/{field.Id}", Ct).OkJsonAsync();
        Guids(left["fieldIds"]).Should().BeEmpty();
        Guids((await reader.Client.DeleteAsync($"/api/v1/me/mutes/topics/{Guid.NewGuid()}", Ct).OkJsonAsync())["topicIds"]).Should().Equal(field.TopicA);
    }

    // ── Limits and permission ───────────────────────────────────

    [Fact]
    public async Task At_most_500_writers_can_be_muted()
    {
        var reader = await api.UserAsync();
        var oneMore = await api.UserAsync("One Too Many");
        // 500 mutes straight in the database (people without a phone number, so the suite's numbers aren't used up).
        var muted = await PeopleAsync(MuteErrors.MaxMutedUsers, "Mute Limit Filler");
        await WithDbAsync(async db =>
        {
            var now = DateTime.UtcNow;
            db.UserMutes.AddRange(muted.Select(id => UserMute.Create(reader.Id, id, now).Value));
            await db.SaveChangesAsync(Ct);
        });

        await reader.Client.PutEmptyAsync($"/api/v1/users/{oneMore.Id}/mute").ProblemAsync(HttpStatusCode.BadRequest, "mute.limit");
        (await reader.Client.PutEmptyAsync($"/api/v1/users/{muted[0]}/mute").OkJsonAsync())["isMuted"]!.GetValue<bool>()
            .Should().BeTrue("repeating a mute at the limit changes nothing");

        await reader.Client.DeleteAsync($"/api/v1/users/{muted[0]}/mute", Ct).OkJsonAsync();
        (await reader.Client.PutEmptyAsync($"/api/v1/users/{oneMore.Id}/mute").OkJsonAsync())["isMuted"]!.GetValue<bool>()
            .Should().BeTrue("an unmute makes room for one");
        (await WithDbAsync(db => db.UserMutes.CountAsync(m => m.MuterId == reader.Id, Ct))).Should().Be(MuteErrors.MaxMutedUsers);
    }

    [Fact]
    public async Task Mute_writes_share_the_writes_limit_of_30_a_minute_and_the_list_is_unthrottled()
    {
        var writer = await api.UserAsync();
        var user = await api.SignUpAsync(); // no write yet (completing the profile would be one)
        var url = $"/api/v1/users/{writer.Id}/mute";

        var statuses = new List<HttpStatusCode>();
        for (var i = 0; i < 31; i++)
            statuses.Add((i % 2 == 0 ? await user.Client.PutEmptyAsync(url) : await user.Client.DeleteAsync(url, Ct)).StatusCode);

        statuses.Take(30).Should().OnlyContain(s => s == HttpStatusCode.OK);
        statuses[30].Should().Be(HttpStatusCode.TooManyRequests);
        await user.Client.PutEmptyAsync($"/api/v1/me/mutes/topics/{Guid.NewGuid()}").ProblemAsync(HttpStatusCode.TooManyRequests, "rate_limited");
        (await user.Client.PutEmptyAsync($"/api/v1/articles/{Guid.NewGuid()}/show-less")).StatusCode
            .Should().Be(HttpStatusCode.TooManyRequests, "every mute and show-less write shares the budget");
        (await user.Client.GetAsync("/api/v1/me/mutes", Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "GET /me/mutes is unthrottled");
        (await writer.Client.PutEmptyAsync($"/api/v1/users/{user.Id}/mute")).StatusCode.Should().Be(HttpStatusCode.OK, "the limit is per user");
    }

    [Fact]
    public async Task Mute_writes_need_the_follows_manage_permission()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync();
        var articleId = await PublishAsync(writer, field, "Forbidden to mark", field.TopicA);
        var user = await api.UserAsync("Without Follows Manage");
        await WithDbAsync(async db =>
        {
            (await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == user.Id, Ct)).RevokeRole(RoleIds.Member);
            await db.SaveChangesAsync(Ct);
        });
        await using (var scope = api.Services.CreateAsyncScope())
            await scope.ServiceProvider.GetRequiredService<IUserAccessService>().InvalidateAsync(user.Id, Ct);

        (HttpMethod Method, string Url)[] writes =
        [
            (HttpMethod.Put, $"/api/v1/users/{writer.Id}/mute"),
            (HttpMethod.Delete, $"/api/v1/users/{writer.Id}/mute?restoreFollow=true"),
            (HttpMethod.Put, $"/api/v1/me/mutes/fields/{field.Id}"),
            (HttpMethod.Delete, $"/api/v1/me/mutes/fields/{field.Id}"),
            (HttpMethod.Put, $"/api/v1/me/mutes/topics/{field.TopicA}"),
            (HttpMethod.Delete, $"/api/v1/me/mutes/topics/{field.TopicA}"),
            (HttpMethod.Put, $"/api/v1/articles/{articleId}/show-less"),
            (HttpMethod.Delete, $"/api/v1/articles/{articleId}/show-less"),
        ];
        foreach (var (method, url) in writes)
            await user.Client.SendAsync(new HttpRequestMessage(method, url), Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");

        (await user.Client.GetAsync("/api/v1/me/mutes", Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "reading your list needs only a session");
        (await WithDbAsync(db => db.UserMutes.CountAsync(m => m.MuterId == user.Id, Ct))).Should().Be(0);
        (await WithDbAsync(db => db.ContentMutes.CountAsync(m => m.UserId == user.Id, Ct))).Should().Be(0);
        (await WithDbAsync(db => db.ArticleFeedback.CountAsync(f => f.UserId == user.Id, Ct))).Should().Be(0);
        (await WithDbAsync(db => db.UserFollows.CountAsync(f => f.FollowerId == user.Id, Ct))).Should().Be(0, "restoreFollow didn't follow either");
    }

    // ── Where mutes apply ───────────────────────────────────────

    [Fact]
    public async Task Muted_writers_fields_and_topics_leave_the_lists_and_the_pages_you_open_say_so()
    {
        var field = await NewFieldAsync();
        var tag = $"mt{field.Word}";
        var w1 = await api.UserAsync($"Topical Writer {field.Word}");
        var w2 = await api.UserAsync($"Plain Writer {field.Word}");
        var reader = await api.UserAsync();
        var a1 = await PublishAsync(w1, field, "In topic A", field.TopicA, tag);
        var a2 = await PublishAsync(w1, field, "In topic B", field.TopicB, tag);
        var b1 = await PublishAsync(w2, field, "Without a topic", topicId: null, tag);

        (await ForYouAsync(reader, field)).Should().Equal(b1, a2, a1);
        var card = await reader.Client.FindInForYouAsync(a1);
        card["topic"]!["id"]!.GetValue<Guid>().Should().Be(field.TopicA, "cards carry the topic for the mute sheet");
        (card["isAuthorMuted"]!.GetValue<bool>(), card["isFieldMuted"]!.GetValue<bool>(), card["isTopicMuted"]!.GetValue<bool>())
            .Should().Be((false, false, false));

        // A muted topic: gone from For you, the whole field's page and the tag page; its own chip still shows it.
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/topics/{field.TopicA}").OkJsonAsync();
        (await ForYouAsync(reader, field)).Should().Equal(b1, a2);
        (await PageAsync(reader.Client, $"/api/v1/fields/{field.Slug}/articles")).Should().Equal(b1, a2);
        (await PageAsync(reader.Client, $"/api/v1/tags/{tag}/articles")).Should().Equal(b1, a2);
        (await PageAsync(api.GuestClient(), $"/api/v1/tags/{tag}/articles")).Should().Equal(new[] { b1, a2, a1 }, "guests see everything");
        var chip = await reader.Client.GetAsync($"/api/v1/fields/{field.Slug}/articles?topic={field.TopicASlug}", Ct).OkJsonAsync();
        Ids(chip["items"]).Should().Equal(a1);
        chip["items"]![0]!["isTopicMuted"]!.GetValue<bool>().Should().BeTrue();
        (await DetailsAsync(reader.Client, a1))["isTopicMuted"]!.GetValue<bool>().Should().BeTrue();

        // A muted field: gone from For you, Explore's tiles and the topic search (its topics too); its own page stays.
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{field.Id}").OkJsonAsync();
        (await ForYouAsync(reader, field)).Should().BeEmpty();
        (await PageAsync(reader.Client, $"/api/v1/fields/{field.Slug}/articles")).Should().Equal(new[] { b1, a2 }, "you opened the field");
        (await DetailsAsync(reader.Client, b1))["isFieldMuted"]!.GetValue<bool>().Should().BeTrue();
        Ids((await reader.Client.GetAsync("/api/v1/explore", Ct).OkJsonAsync())["fields"]).Should().NotContain(field.Id);
        Ids((await api.GuestClient().GetAsync("/api/v1/explore", Ct).OkJsonAsync())["fields"]).Should().Contain(field.Id);
        Ids((await reader.Client.GetAsync($"/api/v1/search?type=topics&q={field.Word}", Ct).OkJsonAsync())["items"]).Should().BeEmpty();
        Ids((await w1.Client.GetAsync($"/api/v1/search?type=topics&q={field.Word}", Ct).OkJsonAsync())["items"]).Should()
            .BeEquivalentTo(new[] { field.Id, field.TopicA, field.TopicB });
        await reader.Client.DeleteAsync($"/api/v1/me/mutes/fields/{field.Id}", Ct).OkJsonAsync();

        // A muted writer: gone from For you, the field page and people search; the profile and the reader say so.
        await reader.Client.PutEmptyAsync($"/api/v1/users/{w2.Id}/mute").OkJsonAsync();
        (await ForYouAsync(reader, field)).Should().Equal(a2);
        (await PageAsync(reader.Client, $"/api/v1/fields/{field.Slug}/articles")).Should().Equal(a2);
        Ids((await reader.Client.GetAsync($"/api/v1/search?type=users&q=Plain Writer {field.Word}", Ct).OkJsonAsync())["items"]).Should().BeEmpty();
        Ids((await w1.Client.GetAsync($"/api/v1/search?type=users&q=Plain Writer {field.Word}", Ct).OkJsonAsync())["items"]).Should().Equal(w2.Id);
        var details = await DetailsAsync(reader.Client, b1);
        details["isAuthorMuted"]!.GetValue<bool>().Should().BeTrue("the reader's banner");
        (await DetailsAsync(api.GuestClient(), b1))["isAuthorMuted"]!.GetValue<bool>().Should().BeFalse();
        var profile = await reader.Client.GetAsync($"/api/v1/users/{w2.Me["username"]!.GetValue<string>()}", Ct).OkJsonAsync();
        profile["isMuted"]!.GetValue<bool>().Should().BeTrue("the profile's banner");
        var tab = await reader.Client.GetAsync($"/api/v1/users/{w2.Me["username"]!.GetValue<string>()}/articles", Ct).OkJsonAsync();
        Ids(tab["items"]).Should().Equal(b1);
        tab["items"]![0]!["isAuthorMuted"]!.GetValue<bool>().Should().BeTrue("the writer's own pages still list their articles");
        (await w2.Client.GetAsync($"/api/v1/users/{w2.Me["username"]!.GetValue<string>()}", Ct).OkJsonAsync())["isMuted"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task Following_leaves_out_muted_fields_and_topics_and_show_less_marks()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        var b1 = await PublishAsync(writer, field, "Following B", field.TopicB);
        var n1 = await PublishAsync(writer, field, "Following none", topicId: null);
        var a1 = await PublishAsync(writer, field, "Following A", field.TopicA);
        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        const string following = "/api/v1/feed/following?limit=20";

        (await PageAsync(reader.Client, following)).Should().Equal(a1, n1, b1);

        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/topics/{field.TopicA}").OkJsonAsync();
        (await PageAsync(reader.Client, following)).Should().Equal(n1, b1);
        (await reader.Client.PutEmptyAsync($"/api/v1/articles/{n1}/show-less")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await PageAsync(reader.Client, following)).Should().Equal(b1);
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{field.Id}").OkJsonAsync();
        (await PageAsync(reader.Client, following)).Should().BeEmpty("a muted field wins over a followed writer");

        // Each Undo brings its articles back.
        await reader.Client.DeleteAsync($"/api/v1/me/mutes/fields/{field.Id}", Ct).OkJsonAsync();
        (await PageAsync(reader.Client, following)).Should().Equal(b1);
        await reader.Client.DeleteAsync($"/api/v1/me/mutes/topics/{field.TopicA}", Ct).OkJsonAsync();
        (await PageAsync(reader.Client, following)).Should().Equal(a1, b1);
        (await reader.Client.DeleteAsync($"/api/v1/articles/{n1}/show-less", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await PageAsync(reader.Client, following)).Should().Equal(a1, n1, b1);
    }

    [Fact]
    public async Task Related_leaves_out_muted_writers_fields_and_topics()
    {
        var field = await NewFieldAsync();
        var other = await NewFieldAsync();
        var tag = $"mr{field.Word}";
        var w1 = await api.UserAsync();
        var w2 = await api.UserAsync();
        var reader = await api.UserAsync();
        var source = await PublishAsync(w1, field, "Related source", field.TopicA, tag);
        var sameField = await PublishAsync(w1, field, "Related, same field", field.TopicB);
        var sameTopic = await PublishAsync(w2, field, "Related, same topic", field.TopicA);
        var sameTag = await PublishAsync(w2, other, "Related, same tag", topicId: null, tag);
        var url = $"/api/v1/articles/{source}/related?limit=10";
        async Task<List<Guid>> RelatedAsync(HttpClient client) => Ids(await client.GetAsync(url, Ct).OkArrayAsync());

        (await RelatedAsync(reader.Client)).Should().Equal(sameTopic, sameField, sameTag);

        // A muted writer: both of theirs go, for the reader only.
        await reader.Client.PutEmptyAsync($"/api/v1/users/{w2.Id}/mute").OkJsonAsync();
        (await RelatedAsync(reader.Client)).Should().Equal(sameField);
        (await RelatedAsync(api.GuestClient())).Should().Equal(sameTopic, sameField, sameTag);
        await reader.Client.DeleteAsync($"/api/v1/users/{w2.Id}/mute", Ct).OkJsonAsync();

        // A muted field: the other field's article goes; muting the open article's own field leaves only the other's.
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{other.Id}").OkJsonAsync();
        (await RelatedAsync(reader.Client)).Should().Equal(sameTopic, sameField);
        await reader.Client.DeleteAsync($"/api/v1/me/mutes/fields/{other.Id}", Ct).OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{field.Id}").OkJsonAsync();
        (await RelatedAsync(reader.Client)).Should().Equal(sameTag);
        await reader.Client.DeleteAsync($"/api/v1/me/mutes/fields/{field.Id}", Ct).OkJsonAsync();

        // A muted topic.
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/topics/{field.TopicA}").OkJsonAsync();
        (await RelatedAsync(reader.Client)).Should().Equal(sameField, sameTag);
    }

    [Fact]
    public async Task Explore_rankings_new_writers_and_top_writers_leave_out_what_you_muted_after_the_shared_cache()
    {
        var field = await NewFieldAsync();
        var other = await NewFieldAsync();
        var muted = await api.UserAsync($"Muted Ranked {field.Word}");
        var writer = await api.UserAsync($"Ranked Writer {field.Word}");
        var reader = await api.UserAsync();
        var someone = await api.UserAsync();
        var byMuted = await PublishAsync(muted, field, "Ranked, muted writer", field.TopicB);
        var inField = await PublishAsync(writer, other, "Ranked, muted field", topicId: null);
        var inTopic = await PublishAsync(writer, field, "Ranked, muted topic", field.TopicA);
        var marked = await PublishAsync(writer, field, "Ranked, shown less", field.TopicB);
        var kept = await PublishAsync(writer, field, "Ranked, kept", field.TopicB);
        Guid[] all = [byMuted, inField, inTopic, marked, kept];
        Guid[] left = [byMuted, inField, inTopic, marked];
        // 50 saves each this week, far more than anything else in the suite, so all five lead both rankings.
        await SaveManyAsync(all, await PeopleAsync(50, "Mute Saver"));

        await reader.Client.PutEmptyAsync($"/api/v1/users/{muted.Id}/mute").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{other.Id}").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/topics/{field.TopicA}").OkJsonAsync();
        (await reader.Client.PutEmptyAsync($"/api/v1/articles/{marked}/show-less")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await ClearCachesAsync();

        // The rankings in full ("See all"): one cached list for everyone, the reader's mutes applied to their pages only.
        foreach (var ranking in new[] { "/api/v1/explore/trending?limit=50", "/api/v1/explore/most-saved?limit=50" })
        {
            (await PageAsync(reader.Client, ranking)).Should().Contain(kept).And.NotContain(left, ranking);
            (await PageAsync(someone.Client, ranking)).Should().Contain(all, ranking);
            (await PageAsync(api.GuestClient(), ranking)).Should().Contain(all, ranking);
        }

        // Explore's sections, from its shared snapshot.
        var mine = await reader.Client.GetAsync("/api/v1/explore", Ct).OkJsonAsync();
        var guest = await api.GuestClient().GetAsync("/api/v1/explore", Ct).OkJsonAsync();
        foreach (var section in new[] { "trending", "mostSaved" })
        {
            Ids(mine[section]).Should().Contain(kept).And.NotContain(left, section);
            Ids(guest[section]).Should().Contain(all, section);
        }
        Ids(mine["newWriters"]).Should().Contain(writer.Id).And.NotContain(muted.Id);
        Ids(guest["newWriters"]).Should().Contain(new[] { writer.Id, muted.Id });
        Ids(mine["fields"]).Should().Contain(field.Id).And.NotContain(other.Id);

        // A field's top writers: the writer with more articles there first; the muted one only for others.
        var topWriters = $"/api/v1/fields/{field.Slug}/writers";
        Ids(await reader.Client.GetAsync(topWriters, Ct).OkArrayAsync()).Should().Equal(writer.Id);
        Ids(await someone.Client.GetAsync(topWriters, Ct).OkArrayAsync()).Should().Equal(writer.Id, muted.Id);
        Ids(await api.GuestClient().GetAsync(topWriters, Ct).OkArrayAsync()).Should().Equal(writer.Id, muted.Id);
    }

    [Fact]
    public async Task Search_leaves_out_muted_writers_fields_and_topics_but_keeps_show_less_and_a_tag_page_leaves_out_all_four()
    {
        var field = await NewFieldAsync();
        var other = await NewFieldAsync();
        var word = $"mtsq{Guid.NewGuid():N}"[..14];
        var tag = $"ms{field.Word}";
        var muted = await api.UserAsync();
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        var someone = await api.UserAsync();
        var byMuted = await PublishAsync(muted, field, $"{word} muted writer", field.TopicB, tag);
        var inField = await PublishAsync(writer, other, $"{word} muted field", topicId: null, tag);
        var inTopic = await PublishAsync(writer, field, $"{word} muted topic", field.TopicA, tag);
        var marked = await PublishAsync(writer, field, $"{word} shown less", field.TopicB, tag);
        var kept = await PublishAsync(writer, field, $"{word} kept", field.TopicB, tag);
        Guid[] all = [byMuted, inField, inTopic, marked, kept];
        foreach (var id in all) await IndexedAsync(id, word);

        await reader.Client.PutEmptyAsync($"/api/v1/users/{muted.Id}/mute").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{other.Id}").OkJsonAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/topics/{field.TopicA}").OkJsonAsync();
        (await reader.Client.PutEmptyAsync($"/api/v1/articles/{marked}/show-less")).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await SearchIdsAsync(reader.Client, word)).Should().BeEquivalentTo(new[] { marked, kept }, "Search keeps what you marked: you searched for it");
        (await SearchIdsAsync(someone.Client, word)).Should().BeEquivalentTo(all);

        // A tag page leaves out the muted writer, field and topic, and the "show less" article too.
        var tagPage = $"/api/v1/tags/{tag}/articles";
        (await PageAsync(reader.Client, tagPage)).Should().Equal(kept);
        (await PageAsync(api.GuestClient(), tagPage)).Should().Equal(kept, marked, inTopic, inField, byMuted);
    }

    [Fact]
    public async Task Suggested_writers_leave_out_writers_you_muted_even_after_the_mute_ended_your_follow()
    {
        var field = await NewFieldAsync();
        var w1 = await api.UserAsync("Suggested One");
        var w2 = await api.UserAsync("Suggested Two");
        var w3 = await api.UserAsync("Suggested Three");
        var reader = await api.UserAsync();
        var someone = await api.UserAsync();
        await PublishAsync(w1, field, "Suggested one", field.TopicA);
        await PublishAsync(w2, field, "Suggested two", field.TopicB);
        await PublishAsync(w3, field, "Suggested three", topicId: null);
        // An interest in the test's field only, so the suggestions are exactly its writers.
        foreach (var viewer in new[] { reader, someone })
            await viewer.Client.PutEmptyAsync($"/api/v1/me/interests/fields/{field.Id}").OkJsonAsync();
        static async Task<List<Guid>> SuggestedAsync(SignedInUser viewer) =>
            Ids(await viewer.Client.GetAsync("/api/v1/users/suggested?limit=50", Ct).OkArrayAsync());

        (await SuggestedAsync(reader)).Should().BeEquivalentTo(new[] { w1.Id, w2.Id, w3.Id });
        await reader.Client.PutEmptyAsync($"/api/v1/users/{w2.Id}/follow").OkJsonAsync();
        (await SuggestedAsync(reader)).Should().BeEquivalentTo(new[] { w1.Id, w3.Id }, "a writer you follow isn't suggested");

        // Muting w2 ends the follow; they stay out, now because they're muted.
        (await reader.Client.PutEmptyAsync($"/api/v1/users/{w2.Id}/mute").OkJsonAsync())["followRemoved"]!.GetValue<bool>().Should().BeTrue();
        (await SuggestedAsync(reader)).Should().BeEquivalentTo(new[] { w1.Id, w3.Id }, "a muted writer isn't suggested");
        await reader.Client.PutEmptyAsync($"/api/v1/users/{w1.Id}/mute").OkJsonAsync();
        (await SuggestedAsync(reader)).Should().Equal(w3.Id);
        (await SuggestedAsync(someone)).Should().BeEquivalentTo(new[] { w1.Id, w2.Id, w3.Id }, "mutes are the reader's own");

        await reader.Client.DeleteAsync($"/api/v1/users/{w1.Id}/mute", Ct).OkJsonAsync();
        (await SuggestedAsync(reader)).Should().BeEquivalentTo(new[] { w1.Id, w3.Id });
    }

    [Fact]
    public async Task Show_less_leaves_the_feeds_lowers_the_topic_in_for_you_and_the_undo_brings_it_back()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        var y1 = await PublishAsync(writer, field, "Topic B", field.TopicB);
        var z1 = await PublishAsync(writer, field, "No topic", topicId: null);
        var x1 = await PublishAsync(writer, field, "Topic A one", field.TopicA);
        var x2 = await PublishAsync(writer, field, "Topic A two", field.TopicA);

        await api.GuestClient().PutEmptyAsync($"/api/v1/articles/{x2}/show-less").ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
        await writer.Client.PutEmptyAsync($"/api/v1/articles/{x2}/show-less").ProblemAsync(HttpStatusCode.BadRequest, "mute.own_article");
        await reader.Client.PutEmptyAsync($"/api/v1/articles/{Guid.NewGuid()}/show-less").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        Ids(await reader.Client.GetFromJsonAsync<JsonArray>($"/api/v1/articles/{x1}/related?limit=10", Ct)).Should().Contain(x2);

        (await ForYouAsync(reader, field)).Should().Equal(x2, x1, z1, y1);
        (await reader.Client.PutEmptyAsync($"/api/v1/articles/{x2}/show-less")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await reader.Client.PutEmptyAsync($"/api/v1/articles/{x2}/show-less")).StatusCode.Should().Be(HttpStatusCode.NoContent, "idempotent");

        // x2 is gone; the rest of topic A goes to the last tier, and paging one by one crosses tiers without repeats.
        (await ForYouAsync(reader, field)).Should().Equal(z1, y1, x1);
        (await ForYouAsync(reader, field, limit: 1)).Should().Equal(z1, y1, x1);
        (await ForYouAsync(writer, field)).Should().Equal(new[] { x2, x1, z1, y1 }, "marks are per reader");
        (await PageAsync(reader.Client, $"/api/v1/fields/{field.Slug}/articles")).Should().Equal(x1, z1, y1);
        Ids(await reader.Client.GetFromJsonAsync<JsonArray>($"/api/v1/articles/{x1}/related?limit=10", Ct)).Should().NotContain(x2);
        (await DetailsAsync(reader.Client, x2))["id"]!.GetValue<Guid>().Should().Be(x2, "a direct link still opens");

        (await reader.Client.DeleteAsync($"/api/v1/articles/{x2}/show-less", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await reader.Client.DeleteAsync($"/api/v1/articles/{x2}/show-less", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await ForYouAsync(reader, field)).Should().Equal(x2, x1, z1, y1);
    }

    [Fact]
    public async Task Show_less_on_an_article_without_a_topic_lowers_its_field()
    {
        var field = await NewFieldAsync();
        var other = await NewFieldAsync();
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        var old = await PublishAsync(writer, other, "Older, elsewhere", topicId: null);
        var g1 = await PublishAsync(writer, field, "Field only one", topicId: null);
        var g2 = await PublishAsync(writer, field, "Field only two", topicId: null);

        var before = await ForYouOrderAsync(reader, old, g1, g2);
        before.IndexOf(g1).Should().BeLessThan(before.IndexOf(old), "newest first");

        await reader.Client.PutEmptyAsync($"/api/v1/articles/{g2}/show-less");
        var after = await ForYouOrderAsync(reader, old, g1);
        after.Should().NotContain(g2);
        after.IndexOf(g1).Should().BeGreaterThan(after.IndexOf(old), "the whole field is lowered below everything else");
    }

    [Fact]
    public async Task An_undo_while_paging_in_the_lowered_tier_restarts_the_last_tier_from_the_top()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();
        var y1 = await PublishAsync(writer, field, "Topic B", field.TopicB);
        var z1 = await PublishAsync(writer, field, "No topic", topicId: null);
        var x1 = await PublishAsync(writer, field, "Topic A one", field.TopicA);
        var x2 = await PublishAsync(writer, field, "Topic A two", field.TopicA);
        var x3 = await PublishAsync(writer, field, "Topic A three", field.TopicA);
        (await reader.Client.PutEmptyAsync($"/api/v1/articles/{x3}/show-less")).StatusCode.Should().Be(HttpStatusCode.NoContent);

        // With a field filter the tiers are (1) the rest and (2) topic A, lowered. One card a page, into the lowered tier.
        var url = $"/api/v1/feed/for-you?field={field.Slug}&limit=1";
        var page1 = await PageOnceAsync(reader.Client, url, cursor: null);
        page1.Ids.Should().Equal(z1);
        var page2 = await PageOnceAsync(reader.Client, url, page1.Next);
        page2.Ids.Should().Equal(y1);
        var page3 = await PageOnceAsync(reader.Client, url, page2.Next);
        page3.Ids.Should().Equal(x2);
        page3.Next.Should().NotBeNull("x1 is still to come");

        // The Undo removes the lowered tier the cursor names: the last tier left (the only one) starts again from its top,
        // so nothing is skipped (x3, newer than the cursor, comes; x2 comes again and a client drops it).
        (await reader.Client.DeleteAsync($"/api/v1/articles/{x3}/show-less", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await RestAsync(reader.Client, url, page3.Next!)).Should().Equal(x3, x2, x1, z1, y1);
    }

    // ── Today's article ─────────────────────────────────────────

    [Fact]
    public async Task Todays_pick_in_a_muted_field_is_replaced_for_the_rest_of_the_day()
    {
        var reader = await api.UserAsync();
        var pick = await reader.Client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct);
        var fieldId = pick!["field"]!["id"]!.GetValue<Guid>();

        await reader.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{fieldId}").OkJsonAsync();
        var next = await reader.Client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct);
        next!["id"]!.GetValue<Guid>().Should().NotBe(pick["id"]!.GetValue<Guid>());
        next["field"]!["id"]!.GetValue<Guid>().Should().NotBe(fieldId);

        await reader.Client.DeleteAsync($"/api/v1/me/mutes/fields/{fieldId}", Ct).OkJsonAsync();
        (await reader.Client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct))!["id"]!.GetValue<Guid>()
            .Should().Be(next["id"]!.GetValue<Guid>(), "the replacement is the pick for the rest of the day");
    }

    [Fact]
    public async Task Todays_pick_by_a_writer_you_then_mute_is_replaced_for_the_rest_of_the_day()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync("Today's Writer");
        var reader = await api.UserAsync();
        var article = await PublishAsync(writer, field, "Today's pick", field.TopicA);
        await TodayAsync(reader); // stores the day's pick
        // The algorithm picks among the whole suite's articles: make the writer's article the stored pick of the day.
        (await WithDbAsync(db => db.DailyPicks.Where(p => p.UserId == reader.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(p => p.ArticleId, article), Ct))).Should().Be(1, "one pick a day");
        (await TodayAsync(reader))["id"]!.GetValue<Guid>().Should().Be(article);

        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/mute").OkJsonAsync();
        var next = await TodayAsync(reader);
        var nextId = next["id"]!.GetValue<Guid>();
        nextId.Should().NotBe(article);
        Guid? nextAuthor = next["author"]?["id"]?.GetValue<Guid>();
        nextAuthor.Should().NotBe(writer.Id);
        (await TodayAsync(reader))["id"]!.GetValue<Guid>().Should().Be(nextId, "the replacement is stored");

        await reader.Client.DeleteAsync($"/api/v1/users/{writer.Id}/mute", Ct).OkJsonAsync();
        (await TodayAsync(reader))["id"]!.GetValue<Guid>().Should().Be(nextId, "unmuting doesn't bring the first pick back today");
    }

    [Fact]
    public async Task Todays_pick_you_mark_show_less_is_replaced_for_the_rest_of_the_day()
    {
        var reader = await api.UserAsync();
        var pick = (await TodayAsync(reader))["id"]!.GetValue<Guid>();

        (await reader.Client.PutEmptyAsync($"/api/v1/articles/{pick}/show-less")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var next = (await TodayAsync(reader))["id"]!.GetValue<Guid>();
        next.Should().NotBe(pick);
        (await TodayAsync(reader))["id"]!.GetValue<Guid>().Should().Be(next, "the replacement is stored");

        (await reader.Client.DeleteAsync($"/api/v1/articles/{pick}/show-less", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await TodayAsync(reader))["id"]!.GetValue<Guid>().Should().Be(next, "the Undo doesn't bring the first pick back today");
    }

    // ── Comments and notifications ──────────────────────────────

    [Fact]
    public async Task A_muted_writers_comments_are_flagged_and_their_activity_tells_you_nothing()
    {
        var author = await api.UserAsync("Author");
        var muted = await api.UserAsync("Muted Commenter");
        var other = await api.UserAsync("Other Commenter");
        var (articleId, _) = await author.Client.PublishAsync();
        await author.Client.PutEmptyAsync($"/api/v1/users/{muted.Id}/mute").OkJsonAsync();

        await CommentAsync(other, articleId, "A comment from someone else");
        var mine = await CommentAsync(author, articleId, "The author's own comment");
        await CommentAsync(muted, articleId, "A comment from a muted writer");
        (await muted.Client.PostAsJsonAsync($"/api/v1/comments/{mine}/replies", new { body = $"@{author.Me["username"]} a reply" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.Created);
        await muted.Client.PutEmptyAsync($"/api/v1/users/{author.Id}/follow").OkJsonAsync();

        // Only the other commenter's activity: no follow, reply, mention or extra actor from the muted writer.
        var entries = (await author.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications?limit=50", Ct))!["items"]!.AsArray();
        var entry = entries.Should().ContainSingle().Subject!;
        entry["type"]!.GetValue<string>().Should().Be("article_comment");
        entry["actorCount"]!.GetValue<int>().Should().Be(1);
        entry["actor"]!["id"]!.GetValue<Guid>().Should().Be(other.Id);

        var thread = (await author.Client.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments?sort=new", Ct))!["items"]!.AsArray();
        Flags(thread).Should().BeEquivalentTo(new Dictionary<Guid, bool> { [other.Id] = false, [author.Id] = false, [muted.Id] = true });
        var reply = thread.Single(c => c!["author"]!["id"]!.GetValue<Guid>() == author.Id)!["replies"]!.AsArray().Single()!;
        reply["isAuthorMuted"]!.GetValue<bool>().Should().BeTrue("replies are flagged too");
        reply["body"]!.GetValue<string>().Should().NotBeNullOrEmpty("the body is sent, so \"عرض\" expands locally");

        var asGuest = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments", Ct))!["items"]!.AsArray();
        Flags(asGuest).Values.Should().OnlyContain(flag => !flag);
    }

    [Fact]
    public async Task A_mention_in_an_article_by_a_writer_you_muted_tells_you_nothing()
    {
        var field = await NewFieldAsync();
        var writer = await api.UserAsync("Mentioning Writer");
        var muter = await api.UserAsync("Muting Reader");
        var other = await api.UserAsync("Other Reader");
        await muter.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/mute").OkJsonAsync();

        var articleId = await PublishAsync(writer, field, "Mentions", topicId: null, blocks: [ArticleTestKit.Inline("p1",
            ArticleTestKit.Text("Thanks to "), ArticleTestKit.Mention(muter.Id, "@muter"),
            ArticleTestKit.Text(" and "), ArticleTestKit.Mention(other.Id, "@other"))]);

        // The same event told the other reader, so it has run.
        var told = (await NotificationsAsync(other)).Should().ContainSingle().Subject!;
        told["type"]!.GetValue<string>().Should().Be("mention");
        told["article"]!["id"]!.GetValue<Guid>().Should().Be(articleId);
        (await NotificationsAsync(muter)).Should().BeEmpty("no entry comes from a writer you muted");
    }

    // ── Profiles ────────────────────────────────────────────────

    [Fact]
    public async Task A_profile_says_whether_it_is_the_official_account()
    {
        var reader = await api.UserAsync();
        var writer = await api.UserAsync();
        var official = await WithDbAsync(db => db.Users.Where(u => u.Id == SystemUsers.EditorialId).Select(u => u.Username).SingleAsync(Ct));

        var profile = await reader.Client.GetAsync($"/api/v1/users/{official}", Ct).OkJsonAsync();
        profile["id"]!.GetValue<Guid>().Should().Be(SystemUsers.EditorialId);
        profile["isSystemAccount"]!.GetValue<bool>().Should().BeTrue("it can't be muted, so its \"⋯\" has no Mute");
        profile["isMuted"]!.GetValue<bool>().Should().BeFalse();
        (await api.GuestClient().GetAsync($"/api/v1/users/{official}", Ct).OkJsonAsync())["isSystemAccount"]!.GetValue<bool>().Should().BeTrue();

        foreach (var username in new[] { writer.Me["username"]!.GetValue<string>(), reader.Me["username"]!.GetValue<string>() })
            (await reader.Client.GetAsync($"/api/v1/users/{username}", Ct).OkJsonAsync())["isSystemAccount"]!.GetValue<bool>()
                .Should().BeFalse("someone else's profile and your own");
    }

    // ── Account deletion ────────────────────────────────────────

    [Fact]
    public async Task Deleting_an_account_removes_its_mutes_both_ways_and_its_marks()
    {
        var leaving = await api.UserAsync("Leaving");
        var staying = await api.UserAsync("Staying");
        var writer = await api.UserAsync();
        var (articleId, _) = await writer.Client.PublishAsync();
        await leaving.Client.PutEmptyAsync($"/api/v1/users/{staying.Id}/mute").OkJsonAsync();
        await staying.Client.PutEmptyAsync($"/api/v1/users/{leaving.Id}/mute").OkJsonAsync();
        await leaving.Client.PutEmptyAsync($"/api/v1/me/mutes/fields/{await leaving.Client.FieldIdAsync("dotnet")}").OkJsonAsync();
        await leaving.Client.PutEmptyAsync($"/api/v1/articles/{articleId}/show-less");

        var deleted = await leaving.Client.SendAsync(
            new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me") { Content = JsonContent.Create(new { password = ApiFactory.TestPassword }) }, Ct);
        deleted.StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await WithDbAsync(db => db.UserMutes.CountAsync(m => m.MuterId == leaving.Id || m.MutedUserId == leaving.Id, Ct))).Should().Be(0);
        (await WithDbAsync(db => db.ContentMutes.CountAsync(m => m.UserId == leaving.Id, Ct))).Should().Be(0);
        (await WithDbAsync(db => db.ArticleFeedback.CountAsync(f => f.UserId == leaving.Id, Ct))).Should().Be(0);
        (await MutesAsync(staying))["users"]!.AsArray().Should().BeEmpty();
    }

    // ── Helpers ─────────────────────────────────────────────────

    private static List<Guid> Ids(JsonNode? items) => [.. items!.AsArray().Select(x => x!["id"]!.GetValue<Guid>())];

    private static List<Guid> Guids(JsonNode? items) => [.. items!.AsArray().Select(x => x!.GetValue<Guid>())];

    private static Dictionary<Guid, bool> Flags(JsonArray comments) =>
        comments.ToDictionary(c => c!["author"]!["id"]!.GetValue<Guid>(), c => c!["isAuthorMuted"]!.GetValue<bool>());

    private static async Task<JsonObject> MutesAsync(SignedInUser user) =>
        await user.Client.GetAsync("/api/v1/me/mutes", Ct).OkJsonAsync();

    /// <summary>A <c>UserMuteStateDto</c> as (isMuted, isFollowing, followerCount, followRemoved).</summary>
    private static (bool IsMuted, bool IsFollowing, int FollowerCount, bool FollowRemoved) State(JsonObject state) => (
        state["isMuted"]!.GetValue<bool>(),
        state["isFollowing"]!.GetValue<bool>(),
        state["followerCount"]!.GetValue<int>(),
        state["followRemoved"]!.GetValue<bool>());

    private static async Task<JsonObject> TodayAsync(SignedInUser user) =>
        await user.Client.GetAsync("/api/v1/feed/today", Ct).OkJsonAsync();

    private static async Task<JsonArray> NotificationsAsync(SignedInUser user) =>
        (await user.Client.GetAsync("/api/v1/me/notifications?limit=50", Ct).OkJsonAsync())["items"]!.AsArray();

    /// <summary>The articles tab of Search (signed in, so never the guests' cached list).</summary>
    private static async Task<List<Guid>> SearchIdsAsync(HttpClient client, string q) =>
        [.. (await client.GetAsync($"/api/v1/search?q={Uri.EscapeDataString(q)}", Ct).OkJsonAsync())["items"]!.AsArray()
            .Select(item => item!["article"]!["id"]!.GetValue<Guid>())];

    /// <summary>Waits until full-text has indexed the article with <paramref name="word"/> (the LIKE fallback needs no wait).</summary>
    private async Task IndexedAsync(Guid articleId, string word)
    {
        if (api.Services.GetRequiredService<SearchEngineState>().Kind != SearchEngineKind.FullText) return;
        var deadline = DateTime.UtcNow.AddSeconds(60);
        while (true)
        {
            var found = await WithDbAsync(db => db.Database.SqlQueryRaw<int>("""
                SELECT COUNT(*) AS [Value] FROM CONTAINSTABLE([dbo].[ArticleTranslations], [SearchText], {0}, LANGUAGE 1025) AS ct
                JOIN [dbo].[ArticleTranslations] AS t ON t.[Id] = ct.[KEY] WHERE t.[ArticleId] = {1}
                """, $"\"{word}*\"", articleId).SingleAsync(Ct));
            if (found > 0) return;
            if (DateTime.UtcNow > deadline) throw new TimeoutException($"Full-text never indexed {articleId} with \"{word}\".");
            await Task.Delay(200, Ct);
        }
    }

    /// <summary>Completed profiles straight in the database, without a phone number (the suite's numbers are finite).</summary>
    private async Task<List<Guid>> PeopleAsync(int count, string displayName)
    {
        var people = Enumerable.Range(0, count)
            .Select(_ => User.CreateSeeded(null, displayName, $"mx_{Guid.NewGuid():N}"[..20]))
            .ToList();
        await WithDbAsync(async db =>
        {
            db.Users.AddRange(people);
            await db.SaveChangesAsync(Ct);
        });
        return [.. people.Select(p => p.Id)];
    }

    /// <summary>Each of <paramref name="savers"/> saved each article a moment ago (rows in the database, then the counters).</summary>
    private async Task SaveManyAsync(Guid[] articleIds, List<Guid> savers)
    {
        var at = DateTime.UtcNow.AddMinutes(-5);
        await WithDbAsync(async db =>
        {
            foreach (var articleId in articleIds)
            {
                foreach (var saver in savers)
                {
                    var saved = SavedArticle.Create(saver, articleId, at);
                    saved.ClearDomainEvents();
                    db.SavedArticles.Add(saved);
                }
            }
            await db.SaveChangesAsync(Ct);
        });
        await using var scope = api.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<ArticleCounters>().RecomputeAsync(articleIds, Ct);
    }

    /// <summary>One page; repeats are the caller's to judge.</summary>
    private static async Task<(List<Guid> Ids, string? Next)> PageOnceAsync(HttpClient client, string url, string? cursor)
    {
        var separator = url.Contains('?') ? '&' : '?';
        var body = await client.GetAsync(cursor is null ? url : $"{url}{separator}cursor={Uri.EscapeDataString(cursor)}", Ct).OkJsonAsync();
        return (Ids(body["items"]), body["nextCursor"]?.GetValue<string>());
    }

    /// <summary>Every page after <paramref name="cursor"/> to the end, repeats included (clients drop the ids they show).</summary>
    private static async Task<List<Guid>> RestAsync(HttpClient client, string url, string cursor)
    {
        var ids = new List<Guid>();
        string? next = cursor;
        for (var page = 0; page < 20 && next is not null; page++)
        {
            var (items, after) = await PageOnceAsync(client, url, next);
            ids.AddRange(items);
            next = after;
        }
        next.Should().BeNull("the feed ends");
        return ids;
    }

    /// <summary>The slugs of the articles this test published, for <c>GET /articles/{slug}</c>.</summary>
    private readonly Dictionary<Guid, string> _slugs = [];

    private async Task<JsonObject> DetailsAsync(HttpClient client, Guid articleId) =>
        await client.GetAsync($"/api/v1/articles/{_slugs[articleId]}", Ct).OkJsonAsync();

    /// <summary>Every page of the reader's For you feed, filtered to <paramref name="field"/>.</summary>
    private static async Task<List<Guid>> ForYouAsync(SignedInUser user, TestField field, int limit = 20) =>
        await PageAsync(user.Client, $"/api/v1/feed/for-you?field={field.Slug}&limit={limit}");

    /// <summary>The order of <paramref name="wanted"/> in the reader's unfiltered For you feed (all of them must show up).</summary>
    private static async Task<List<Guid>> ForYouOrderAsync(SignedInUser user, params Guid[] wanted)
    {
        var all = await PageAsync(user.Client, "/api/v1/feed/for-you?limit=50", pages: 40);
        var found = all.Where(wanted.Contains).ToList();
        found.Should().HaveCount(wanted.Length, "every article is somewhere in For you");
        return found;
    }

    private static async Task<List<Guid>> PageAsync(HttpClient client, string url, int pages = 10)
    {
        var ids = new List<Guid>();
        string? cursor = null;
        for (var page = 0; page < pages; page++)
        {
            var separator = url.Contains('?') ? '&' : '?';
            var body = await client.GetAsync(cursor is null ? url : $"{url}{separator}cursor={Uri.EscapeDataString(cursor)}", Ct).OkJsonAsync();
            ids.AddRange(Ids(body["items"]));
            cursor = body["nextCursor"]?.GetValue<string>();
            if (cursor is null) break;
        }
        ids.Should().OnlyHaveUniqueItems("paging never repeats a card");
        return ids;
    }

    private static async Task<Guid> CommentAsync(SignedInUser user, Guid articleId, string body)
    {
        var response = await user.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!["id"]!.GetValue<Guid>();
    }

    private async Task<Guid> PublishAsync(
        SignedInUser writer, TestField field, string title, Guid? topicId, string? tag = null, object[]? blocks = null)
    {
        var document = ArticleTestKit.Document(
            field.Id, $"{title} {Guid.NewGuid():N}"[..40], blocks: blocks ?? [ArticleTestKit.Paragraph("Mute test article.")], tags: tag is null ? [] : [tag]);
        document["topicId"] = topicId is { } topic ? JsonValue.Create(topic) : null;
        var (id, slug) = await writer.Client.WriteAndPublishAsync(document);
        _slugs[id] = slug;
        await ClearCachesAsync();
        return id;
    }

    /// <summary>A new enabled field with two topics, disabled again when the test ends.</summary>
    private async Task<TestField> NewFieldAsync()
    {
        var word = $"{Guid.NewGuid():N}"[..10];
        TestField? created = null;
        await WithDbAsync(async db =>
        {
            var field = new Field($"mf-{word}", $"مجال {word}", $"Field {word}", "cpu", "primary", 900);
            field.Update(field.NameAr, field.NameEn, "cpu", "primary", 900, false, requiresSources: false, isEnabled: true);
            db.Fields.Add(field);
            await db.SaveChangesAsync(Ct);
            var a = field.UpsertTopic($"ma-{word}", $"موضوع أ {word}", $"Topic A {word}", 1);
            var b = field.UpsertTopic($"mb-{word}", $"موضوع ب {word}", $"Topic B {word}", 2);
            await db.SaveChangesAsync(Ct);
            created = new TestField(field.Id, field.Slug, word, a.Id, a.Slug, b.Id);
        });
        _fields.Add(created!.Id);
        await ClearCachesAsync();
        return created;
    }

    private async Task WithDbAsync(Func<AppDbContext, Task> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await action(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    private async Task<T> WithDbAsync<T>(Func<AppDbContext, Task<T>> action)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await action(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    private async Task ClearCachesAsync()
    {
        await using var scope = api.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<HybridCache>()
            .RemoveByTagAsync([CacheTags.Feed, CacheTags.Taxonomy, CacheTags.Articles, CacheTags.Tags], Ct);
    }
}
