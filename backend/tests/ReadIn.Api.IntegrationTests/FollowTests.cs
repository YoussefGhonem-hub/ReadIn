using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>F12 Follow end to end: writers, lists, suggestions, the Following feed and interests.</summary>
[Collection(ApiCollection.Name)]
public sealed class FollowTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Following_is_idempotent_counted_and_never_yourself()
    {
        var writer = await api.UserAsync();
        var reader = await api.UserAsync();

        await api.GuestClient().PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
        await reader.Client.PutEmptyAsync($"/api/v1/users/{reader.Id}/follow").ProblemAsync(HttpStatusCode.BadRequest, "follow.self");
        await reader.Client.PutEmptyAsync($"/api/v1/users/{Guid.NewGuid()}/follow").ProblemAsync(HttpStatusCode.NotFound, "user.not_found");

        var followed = await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        followed["isFollowing"]!.GetValue<bool>().Should().BeTrue();
        followed["followerCount"]!.GetValue<int>().Should().Be(1);
        (await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync())["followerCount"]!.GetValue<int>().Should().Be(1);

        var unfollowed = await reader.Client.DeleteAsync($"/api/v1/users/{writer.Id}/follow", Ct).OkJsonAsync();
        unfollowed["isFollowing"]!.GetValue<bool>().Should().BeFalse();
        unfollowed["followerCount"]!.GetValue<int>().Should().Be(0);
        (await reader.Client.DeleteAsync($"/api/v1/users/{writer.Id}/follow", Ct).OkJsonAsync())["isFollowing"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task The_official_account_can_be_followed()
    {
        var reader = await api.UserAsync();

        var state = await reader.Client.PutEmptyAsync($"/api/v1/users/{SystemUsers.EditorialId}/follow").OkJsonAsync();

        state["isFollowing"]!.GetValue<bool>().Should().BeTrue();
        state["followerCount"]!.GetValue<int>().Should().BeGreaterThan(1, "demo users follow it too");
    }

    [Fact]
    public async Task Followers_and_following_are_public_newest_first_searchable_and_relative_to_the_viewer()
    {
        var writer = await api.UserAsync("Writer Person");
        var alice = await api.UserAsync("Alice Reader");
        var bob = await api.UserAsync("Bob Reader");
        await alice.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        await bob.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        await alice.Client.PutEmptyAsync($"/api/v1/users/{bob.Id}/follow").OkJsonAsync();

        var asAlice = (await alice.Client.GetAsync($"/api/v1/users/{writer.Id}/followers", Ct).OkJsonAsync())["items"]!.AsArray();
        asAlice.Select(u => u!["id"]!.GetValue<Guid>()).Should().Equal(bob.Id, alice.Id);
        asAlice[0]!["isFollowing"]!.GetValue<bool>().Should().BeTrue("Alice follows Bob");
        asAlice[0]!["followsYou"]!.GetValue<bool>().Should().BeFalse();
        asAlice[0]!["displayName"]!.GetValue<string>().Should().Be("Bob Reader");
        asAlice[0]!.AsObject().Select(p => p.Key).Should().Equal(
            "id", "displayName", "username", "avatarUrl", "isVerified", "headline", "bio", "isFollowing", "followsYou");

        var asBob = (await bob.Client.GetAsync($"/api/v1/users/{writer.Id}/followers", Ct).OkJsonAsync())["items"]!.AsArray();
        asBob[1]!["followsYou"]!.GetValue<bool>().Should().BeTrue("Alice follows Bob");

        var asGuest = (await api.GuestClient().GetAsync($"/api/v1/users/{writer.Id}/followers", Ct).OkJsonAsync())["items"]!.AsArray();
        asGuest.Should().OnlyContain(u => !u!["isFollowing"]!.GetValue<bool>() && !u["followsYou"]!.GetValue<bool>());

        var search = (await api.GuestClient().GetAsync($"/api/v1/users/{writer.Id}/followers?q=alice", Ct).OkJsonAsync())["items"]!.AsArray();
        search.Select(u => u!["id"]!.GetValue<Guid>()).Should().Equal(alice.Id);
        var handle = bob.Me["username"]!.GetValue<string>();
        (await api.GuestClient().GetAsync($"/api/v1/users/{writer.Id}/followers?q=@{handle}", Ct).OkJsonAsync())["items"]!.AsArray()
            .Select(u => u!["id"]!.GetValue<Guid>()).Should().Equal(bob.Id);

        var first = await api.GuestClient().GetAsync($"/api/v1/users/{writer.Id}/followers?limit=1", Ct).OkJsonAsync();
        var second = await api.GuestClient().GetAsync($"/api/v1/users/{writer.Id}/followers?limit=1&cursor={first["nextCursor"]}", Ct).OkJsonAsync();
        second["items"]!.AsArray().Single()!["id"]!.GetValue<Guid>().Should().Be(alice.Id);

        var following = (await api.GuestClient().GetAsync($"/api/v1/users/{alice.Id}/following", Ct).OkJsonAsync())["items"]!.AsArray();
        following.Select(u => u!["id"]!.GetValue<Guid>()).Should().Equal(bob.Id, writer.Id);

        await api.GuestClient().GetAsync($"/api/v1/users/{Guid.NewGuid()}/followers", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
    }

    [Fact]
    public async Task The_following_feed_has_only_followed_writers_newest_first()
    {
        var followedWriter = await api.UserAsync();
        var otherWriter = await api.UserAsync();
        var reader = await api.UserAsync();
        await reader.Client.PutEmptyAsync($"/api/v1/users/{followedWriter.Id}/follow").OkJsonAsync();
        var (older, _) = await followedWriter.Client.PublishAsync();
        await otherWriter.Client.PublishAsync();
        var (newer, _) = await followedWriter.Client.PublishAsync();
        await reader.Client.ReactAsync(newer, "love").OkJsonAsync();

        var feed = await reader.Client.GetAsync("/api/v1/feed/following", Ct).OkJsonAsync();
        var items = feed["items"]!.AsArray();
        items.Select(i => i!["id"]!.GetValue<Guid>()).Should().Equal(newer, older);
        items[0]!["myReaction"]!.GetValue<string>().Should().Be("love");
        items[0]!["reactions"]!.Counts().Should().Be((0, 1, 0, 0));
        feed["nextCursor"].Should().BeNull();

        var page = await reader.Client.GetAsync("/api/v1/feed/following?limit=1", Ct).OkJsonAsync();
        var next = await reader.Client.GetAsync($"/api/v1/feed/following?limit=1&cursor={page["nextCursor"]}", Ct).OkJsonAsync();
        next["items"]!.AsArray().Single()!["id"]!.GetValue<Guid>().Should().Be(older);

        var nobody = await api.UserAsync();
        (await nobody.Client.GetAsync("/api/v1/feed/following", Ct).OkJsonAsync())["items"]!.AsArray().Should().BeEmpty();
        await api.GuestClient().GetAsync("/api/v1/feed/following", Ct).ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
    }

    [Fact]
    public async Task Suggested_writers_overlap_your_interests_verified_first_and_exclude_follows_and_you()
    {
        // Fields the other tests don't publish in, so the 50 suggestions can't fill up with their writers. The official
        // account has a security article (fixture content).
        var writer = await api.UserAsync("Databases Writer");
        await writer.Client.PublishAsync(field: "databases");
        var reader = await api.UserAsync();
        var fields = (await reader.Client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!;
        var interestSlugs = new[] { "databases", "security" };
        var fieldIds = fields.Where(f => interestSlugs.Contains(f!["slug"]!.GetValue<string>())).Select(f => f!["id"]!.GetValue<Guid>());
        var testingTopic = (await reader.Client.GetFromJsonAsync<JsonArray>("/api/v1/fields/testing/topics", Ct))![0]!["id"]!.GetValue<Guid>();
        (await reader.Client.PutAsJsonAsync("/api/v1/me/interests", new { fieldIds, topicIds = new[] { testingTopic } }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        var suggested = await reader.Client.GetAsync("/api/v1/users/suggested?limit=50", Ct).OkArrayAsync();
        var ids = suggested.Select(u => u!["id"]!.GetValue<Guid>()).ToList();
        ids.Should().Contain(writer.Id).And.Contain(SystemUsers.EditorialId).And.NotContain(reader.Id);
        ids.IndexOf(SystemUsers.EditorialId).Should().BeLessThan(ids.IndexOf(writer.Id), "verified writers come first");
        suggested.Should().OnlyContain(u => !u!["isFollowing"]!.GetValue<bool>());

        await reader.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        (await reader.Client.GetAsync("/api/v1/users/suggested?limit=50", Ct).OkArrayAsync())
            .Select(u => u!["id"]!.GetValue<Guid>()).Should().NotContain(writer.Id, "already followed");

        var outsider = await api.UserAsync();
        await outsider.Client.PublishAsync(field: "mobile");
        var testingWriter = await api.UserAsync();
        await testingWriter.Client.PublishAsync(field: "testing");
        var latest = (await reader.Client.GetAsync("/api/v1/users/suggested?limit=50", Ct).OkArrayAsync())
            .Select(u => u!["id"]!.GetValue<Guid>()).ToList();
        latest.Should().NotContain(outsider.Id, "no field overlap");
        latest.Should().Contain(testingWriter.Id, "a followed topic counts for its field");

        await api.GuestClient().GetAsync("/api/v1/users/suggested", Ct).ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
    }

    [Fact]
    public async Task Fields_and_topics_are_followed_one_at_a_time_keeping_at_least_three()
    {
        var reader = await api.UserAsync();
        var client = reader.Client;
        var fields = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!.Select(f => f!["id"]!.GetValue<Guid>()).ToList();
        var topic = (await client.GetFromJsonAsync<JsonArray>("/api/v1/fields/dotnet/topics", Ct))![0]!["id"]!.GetValue<Guid>();

        for (var i = 0; i < 3; i++)
        {
            var interests = await client.PutEmptyAsync($"/api/v1/me/interests/fields/{fields[i]}").OkJsonAsync();
            interests["fieldIds"]!.AsArray().Should().HaveCount(i + 1);
        }
        (await client.PutEmptyAsync($"/api/v1/me/interests/fields/{fields[0]}").OkJsonAsync())["fieldIds"]!.AsArray()
            .Should().HaveCount(3, "following again is idempotent");
        (await client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["onboardingCompleted"]!.GetValue<bool>().Should().BeTrue();

        await client.DeleteAsync($"/api/v1/me/interests/fields/{fields[0]}", Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "user.interests.min_three");

        var withTopic = await client.PutEmptyAsync($"/api/v1/me/interests/topics/{topic}").OkJsonAsync();
        withTopic["topicIds"]!.AsArray().Select(t => t!.GetValue<Guid>()).Should().Equal(topic);
        var afterUnfollow = await client.DeleteAsync($"/api/v1/me/interests/fields/{fields[0]}", Ct).OkJsonAsync();
        afterUnfollow["fieldIds"]!.AsArray().Select(f => f!.GetValue<Guid>()).Should().BeEquivalentTo([fields[1], fields[2]]);
        await client.DeleteAsync($"/api/v1/me/interests/topics/{topic}", Ct).ProblemAsync(HttpStatusCode.BadRequest, "user.interests.min_three");
        (await client.DeleteAsync($"/api/v1/me/interests/fields/{fields[5]}", Ct).OkJsonAsync())["fieldIds"]!.AsArray()
            .Should().HaveCount(2, "unfollowing what you don't follow is a no-op");

        await client.PutEmptyAsync($"/api/v1/me/interests/fields/{Guid.NewGuid()}").ProblemAsync(HttpStatusCode.NotFound, "field.not_found");
        await client.PutEmptyAsync($"/api/v1/me/interests/topics/{Guid.NewGuid()}").ProblemAsync(HttpStatusCode.NotFound, "topic.not_found");
        await api.GuestClient().PutEmptyAsync($"/api/v1/me/interests/fields/{fields[0]}").ProblemAsync(HttpStatusCode.Unauthorized, "auth.unauthorized");
    }
}
