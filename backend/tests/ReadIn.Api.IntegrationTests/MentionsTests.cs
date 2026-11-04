using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Notifications.EventHandlers;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Notifications;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// "Who can mention me" (SPEC F18) end to end: the setting, the suggestions, comment mentions (F11), mentions in published
/// articles (F05) and their <c>mention</c> notifications (F17). The push of an article mention is in
/// <see cref="NotificationPushJobTests"/>.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class MentionsTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    // ---- The setting ----

    [Fact]
    public async Task Privacy_has_who_can_mention_and_each_setting_changes_alone()
    {
        var user = await api.UserAsync();
        (await PrivacyAsync(user)).ToJsonString().Should().Be("""{"publicReadingStats":false,"whoCanMention":"everyone"}""", "the defaults");

        (await PutPrivacyAsync(user, new { whoCanMention = "following" })).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await PrivacyAsync(user)).ToJsonString().Should().Be("""{"publicReadingStats":false,"whoCanMention":"following"}""");

        (await PutPrivacyAsync(user, new { publicReadingStats = true })).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await PrivacyAsync(user)).ToJsonString().Should().Be("""{"publicReadingStats":true,"whoCanMention":"following"}""",
            "a client that only knows the stats switch keeps the mention setting");

        (await PutPrivacyAsync(user, new { publicReadingStats = false, whoCanMention = "nobody" })).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await PrivacyAsync(user)).ToJsonString().Should().Be("""{"publicReadingStats":false,"whoCanMention":"nobody"}""");

        var neither = await PutPrivacyAsync(user, new { }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        neither["errors"]!["whoCanMention"]![0]!.GetValue<string>().Should().Be("validation.required");
        await PutRawPrivacyAsync(user, """{"whoCanMention":7}""").ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        (await PutRawPrivacyAsync(user, """{"whoCanMention":"friends"}""")).StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await PrivacyAsync(user)).ToJsonString().Should().Be("""{"publicReadingStats":false,"whoCanMention":"nobody"}""", "nothing changed");

        (await api.GuestClient().PutAsJsonAsync("/api/v1/me/privacy", new { whoCanMention = "nobody" }, Ct)).StatusCode
            .Should().Be(HttpStatusCode.Unauthorized);
    }

    // ---- Suggestions ----

    [Fact]
    public async Task Suggestions_offer_only_people_who_allow_you()
    {
        var token = $"mx{Guid.NewGuid():N}"[..12];
        var viewer = await api.UserAsync($"{token} Viewer");
        var everyone = await api.UserAsync($"{token} Everyone");
        var follower = await api.UserAsync($"{token} Follows the viewer");
        var stranger = await api.UserAsync($"{token} Followed by the viewer");
        var nobody = await api.UserAsync($"{token} Nobody");
        var suspended = await api.UserAsync($"{token} Suspended");

        await SetPolicyAsync(follower, "following");
        await FollowAsync(follower, viewer);
        await SetPolicyAsync(stranger, "following");
        await FollowAsync(viewer, stranger); // "people I follow" is about who the mentioned user follows
        await SetPolicyAsync(nobody, "nobody");
        await SuspendAsync(suspended.Id);

        (await SuggestAsync(viewer, token)).Should().BeEquivalentTo([everyone.Id, follower.Id], "never yourself either");
        (await SuggestAsync(follower, token)).Should().BeEquivalentTo([viewer.Id, everyone.Id],
            "the follower follows the viewer, not themselves; the stranger doesn't follow them");
        (await SuggestAsync(viewer, Username(nobody))).Should().BeEmpty("not even by the exact @username");
    }

    // ---- Comments ----

    [Fact]
    public async Task A_comment_links_and_notifies_only_people_who_allow_its_author()
    {
        var author = await api.UserAsync("Article Author");
        var (articleId, _) = await author.Client.PublishAsync();
        var commenter = await api.UserAsync("Commenter");
        var everyone = await api.UserAsync();
        var follower = await api.UserAsync();
        var stranger = await api.UserAsync();
        var nobody = await api.UserAsync();
        var suspended = await api.UserAsync();
        await SetPolicyAsync(follower, "following");
        await FollowAsync(follower, commenter);
        await SetPolicyAsync(stranger, "following");
        await SetPolicyAsync(nobody, "nobody");
        await SuspendAsync(suspended.Id);

        var body = $"@{Username(everyone)} @{Username(follower)} @{Username(stranger)} @{Username(nobody)} @{Username(suspended)} شوفوا ده";
        var comment = await CommentAsync(commenter, articleId, body);

        comment["body"]!.GetValue<string>().Should().Be(body, "the text stays as written; only the links are decided");
        MentionedIds(comment).Should().BeEquivalentTo([everyone.Id, follower.Id]);
        (await ListAsync(everyone)).Should().ContainSingle().Which!["type"]!.GetValue<string>().Should().Be("mention");
        (await ListAsync(follower)).Should().ContainSingle().Which!["comment"]!["id"]!.GetValue<Guid>().Should().Be(comment["id"]!.GetValue<Guid>());
        (await ListAsync(stranger)).Should().BeEmpty();
        (await ListAsync(nobody)).Should().BeEmpty();
        (await InDbAsync(db => db.Notifications.AnyAsync(n => n.UserId == suspended.Id, Ct))).Should().BeFalse();

        // A later change of the setting leaves existing comments alone; an edit applies it.
        await SetPolicyAsync(everyone, "nobody");
        var id = comment["id"]!.GetValue<Guid>();
        MentionedIds(await commenter.Client.GetAsync($"/api/v1/comments/{id}", Ct).OkJsonAsync()).Should().BeEquivalentTo([everyone.Id, follower.Id]);
        var edited = await commenter.Client.PatchAsJsonAsync($"/api/v1/comments/{id}", new { body = body + "!" }, Ct).OkJsonAsync();
        MentionedIds(edited).Should().Equal(follower.Id);
    }

    // ---- Articles ----

    [Fact]
    public async Task Publishing_keeps_allowed_mentions_with_the_current_username_in_every_language_and_turns_the_rest_into_text()
    {
        var writer = await api.UserAsync("Mention Writer");
        var mona = await api.UserAsync("Mona");
        var omar = await api.UserAsync("Omar");
        var sara = await api.UserAsync("Sara");
        var nour = await api.UserAsync("Nour");
        var gone = await api.UserAsync("Suspended Reader");
        var ghost = Guid.NewGuid();
        await SetPolicyAsync(omar, "nobody");
        await SetPolicyAsync(sara, "following");
        await FollowAsync(sara, writer);
        await SetPolicyAsync(nour, "following");
        await SuspendAsync(gone.Id);

        var field = await writer.Client.FieldIdAsync("dotnet");
        var document = ArticleTestKit.Document(field, "منشن في المقال", "ar-EG", [
            ArticleTestKit.Inline("p1",
                ArticleTestKit.Text("شكرًا "), ArticleTestKit.Mention(mona.Id, "@an_old_handle"), ArticleTestKit.Text(" و"),
                ArticleTestKit.Mention(omar.Id, "@omar"), ArticleTestKit.Text(" وأنا "), ArticleTestKit.Mention(writer.Id, "@me")),
        ]);
        document["translations"]!.AsArray().Add(JsonSerializerHelper.ToNode(new
        {
            language = "en",
            title = "Mentions in an article",
            subtitle = (string?)null,
            content = new
            {
                version = 1,
                language = "en",
                blocks = new object[]
                {
                    new { id = "l1", type = "bulletList", items = new[] { new[] { ArticleTestKit.Mention(sara.Id, "@sara") } } },
                    new { id = "t1", type = "table", header = new[] { new[] { ArticleTestKit.Text("Who") } },
                        rows = new[] { new[] { new[] { ArticleTestKit.Mention(nour.Id, "@nour") } } } },
                    ArticleTestKit.Inline("p2", ArticleTestKit.Mention(gone.Id, "@gone"), ArticleTestKit.Text(" "), ArticleTestKit.Mention(ghost, "@ghost")),
                },
            },
        }));
        var (articleId, slug) = await writer.Client.WriteAndPublishAsync(document);

        var arabic = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}?lang=ar-EG", Ct))!["content"]!;
        Mentions(arabic).Should().Equal((mona.Id, $"@{Username(mona)}"), (writer.Id, $"@{Username(writer)}"));
        Texts(arabic).Should().Contain("@omar", "Omar lets nobody mention him");
        var english = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}?lang=en", Ct))!["content"]!;
        Mentions(english).Should().Equal((sara.Id, $"@{Username(sara)}"));
        Texts(english).Should().Contain(["@nour", "@gone", "@ghost"]);

        // The working copy and the revision keep exactly what went live.
        var edit = await writer.Client.EditAsync(articleId);
        Mentions(edit["document"]!["translations"]![0]!["content"]!).Should().Equal((mona.Id, $"@{Username(mona)}"), (writer.Id, $"@{Username(writer)}"));
        var revision = (await writer.Client.GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/revisions/1", Ct))!;
        Mentions(revision["document"]!["translations"]![1]!["content"]!).Should().Equal((sara.Id, $"@{Username(sara)}"));

        // Sara follows the writer: she also hears about the new article, and the writer about her.
        foreach (var told in new[] { mona, sara })
        {
            var entry = (await MentionsOfAsync(told)).Should().ContainSingle().Subject!;
            entry["actor"]!["id"]!.GetValue<Guid>().Should().Be(writer.Id);
            entry["article"]!["id"]!.GetValue<Guid>().Should().Be(articleId);
            entry["comment"].Should().BeNull("a mention in an article has no comment");
            entry["link"]!.GetValue<string>().Should().Be($"readin://a/{slug}");
        }
        foreach (var untold in new[] { omar, nour, writer }) (await MentionsOfAsync(untold)).Should().BeEmpty();
        (await InDbAsync(db => db.Notifications.AnyAsync(n => n.UserId == gone.Id, Ct))).Should().BeFalse();
    }

    [Fact]
    public async Task An_article_links_and_tells_only_the_first_people_it_mentions_up_to_the_limit()
    {
        var writer = await api.UserAsync("Busy Writer");
        var people = new List<SignedInUser>();
        for (var i = 0; i <= Article.MaxMentions; i++) people.Add(await api.UserAsync($"Mentioned {i}"));
        var field = await writer.Client.FieldIdAsync("dotnet");
        var document = ArticleTestKit.Document(field, $"Many mentions {Guid.NewGuid():N}", blocks: [
            ArticleTestKit.Inline("p1", [ArticleTestKit.Text("Thanks to "), .. people.Select(p => ArticleTestKit.Mention(p.Id, "@extra"))]),
        ]);

        var (articleId, slug) = await writer.Client.WriteAndPublishAsync(document);

        var first = people.Take(Article.MaxMentions).ToList();
        var content = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["content"]!;
        Mentions(content).Select(m => m.UserId).Should().Equal(first.Select(p => p.Id));
        Texts(content).Should().Contain("@extra", "the one past the limit is plain text");
        (await MentionEntriesAsync(articleId)).Should().BeEquivalentTo(first.Select(p => p.Id));
    }

    [Fact]
    public async Task Each_mentioned_user_is_told_once_per_article_and_an_update_tells_only_new_ones()
    {
        var writer = await api.UserAsync("Updating Writer");
        var mona = await api.UserAsync("Mona");
        var layla = await api.UserAsync("Layla");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var title = $"Mentions over updates {Guid.NewGuid():N}";
        object Body(params SignedInUser[] mentioned) =>
            ArticleTestKit.Inline("p1", [ArticleTestKit.Text("Thanks"), .. mentioned.Select(m => ArticleTestKit.Mention(m.Id, "@x"))]);

        var (articleId, _) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, title, blocks: [Body(mona)]));
        (await MentionEntriesAsync(articleId)).Should().Equal(mona.Id);

        await UpdateAsync(writer, articleId, ArticleTestKit.Document(field, title, blocks: [Body(mona, layla)]));
        (await MentionEntriesAsync(articleId)).Should().BeEquivalentTo([mona.Id, layla.Id], "the update tells only Layla");

        await UpdateAsync(writer, articleId, ArticleTestKit.Document(field, title, blocks: [Body(layla)]));
        await UpdateAsync(writer, articleId, ArticleTestKit.Document(field, title, blocks: [Body(mona, layla)]));
        (await MentionEntriesAsync(articleId)).Should().BeEquivalentTo([mona.Id, layla.Id], "removing and re-adding tells nobody again");
        (await ListAsync(mona)).Should().ContainSingle();
        (await InDbAsync(db => db.Notifications.Where(n => n.ArticleId == articleId).Select(n => n.DedupeKey).Distinct().ToListAsync(Ct)))
            .Should().Equal($"mention:article:{articleId}");
    }

    [Fact]
    public async Task An_article_mention_stays_in_the_center_while_the_article_is_readable()
    {
        var writer = await api.UserAsync("Writer");
        var reader = await api.UserAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var (articleId, _) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "Mention that goes away",
            blocks: [ArticleTestKit.Inline("p1", ArticleTestKit.Text("Hi "), ArticleTestKit.Mention(reader.Id, "@reader"))]));
        (await ListAsync(reader)).Should().ContainSingle();
        (await UnreadAsync(reader)).Should().Be(1);

        (await writer.Client.DeleteAsync($"/api/v1/articles/{articleId}", Ct)).EnsureSuccessStatusCode();

        (await ListAsync(reader)).Should().BeEmpty();
        (await UnreadAsync(reader)).Should().Be(0);
    }

    [Fact]
    public async Task The_notification_checks_the_article_and_the_setting_again()
    {
        var writer = await api.UserAsync("Writer");
        var mona = await api.UserAsync();
        var layla = await api.UserAsync();
        var (articleId, _) = await writer.Client.PublishAsync();
        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(await writer.Client.FieldIdAsync("dotnet"), "Never published"));
        await SetPolicyAsync(mona, "nobody"); // changed after the publish, before the outbox ran

        await HandleAsync(new ArticleMentionsDomainEvent(articleId, writer.Id, [mona.Id, layla.Id]));
        await HandleAsync(new ArticleMentionsDomainEvent(draft["id"]!.GetValue<Guid>(), writer.Id, [layla.Id]));
        await HandleAsync(new ArticleMentionsDomainEvent(articleId, layla.Id, [writer.Id]));

        (await ListAsync(mona)).Should().BeEmpty();
        (await ListAsync(layla)).Should().ContainSingle().Which!["article"]!["id"]!.GetValue<Guid>().Should().Be(articleId, "not for a draft");
        (await ListAsync(writer)).Should().BeEmpty("only the article's author mentions in it");
        await HandleAsync(new ArticleMentionsDomainEvent(articleId, writer.Id, [layla.Id]));
        (await ListAsync(layla)).Should().ContainSingle("a redelivered event changes nothing");
    }

    [Fact]
    public async Task Autosave_keeps_mentions_as_written_until_they_go_live()
    {
        var writer = await api.UserAsync("Writer");
        var omar = await api.UserAsync();
        await SetPolicyAsync(omar, "nobody");
        var field = await writer.Client.FieldIdAsync("dotnet");

        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(field, "Draft with a mention",
            blocks: [ArticleTestKit.Inline("p1", ArticleTestKit.Mention(omar.Id, "@whatever"))]));

        Mentions(draft["document"]!["translations"]![0]!["content"]!).Should().Equal((omar.Id, "@whatever"));
        (await ListAsync(omar)).Should().BeEmpty();
    }

    // ---- Helpers ----

    private static string Username(SignedInUser user) => user.Me["username"]!.GetValue<string>();

    private static async Task<JsonObject> PrivacyAsync(SignedInUser user) =>
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["privacy"]!.AsObject();

    private static Task<HttpResponseMessage> PutPrivacyAsync(SignedInUser user, object body) =>
        user.Client.PutAsJsonAsync("/api/v1/me/privacy", body, Ct);

    private static Task<HttpResponseMessage> PutRawPrivacyAsync(SignedInUser user, string json) =>
        user.Client.PutAsync("/api/v1/me/privacy", new StringContent(json, Encoding.UTF8, "application/json"), Ct);

    private static async Task SetPolicyAsync(SignedInUser user, string whoCanMention) =>
        (await PutPrivacyAsync(user, new { whoCanMention })).StatusCode.Should().Be(HttpStatusCode.NoContent);

    private static async Task FollowAsync(SignedInUser follower, SignedInUser followee) =>
        await follower.Client.PutEmptyAsync($"/api/v1/users/{followee.Id}/follow").OkJsonAsync();

    private async Task SuspendAsync(Guid userId) => await InDbAsync(async db =>
    {
        (await db.Users.SingleAsync(u => u.Id == userId, Ct)).Suspend(until: null);
        return await db.SaveChangesAsync(Ct);
    });

    private static async Task<IReadOnlyList<Guid>> SuggestAsync(SignedInUser user, string q) =>
        [.. (await user.Client.GetFromJsonAsync<JsonArray>($"/api/v1/users/mention-suggestions?q={Uri.EscapeDataString(q)}", Ct))!
            .Select(s => s!["id"]!.GetValue<Guid>())];

    private static async Task<JsonObject> CommentAsync(SignedInUser user, Guid articleId, string body)
    {
        var response = await user.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!;
    }

    private static IEnumerable<Guid> MentionedIds(JsonObject comment) =>
        comment["mentions"]!.AsArray().Select(m => m!["userId"]!.GetValue<Guid>());

    private static async Task UpdateAsync(SignedInUser writer, Guid articleId, JsonObject document)
    {
        var saved = await writer.Client.SaveDraftAsync(articleId, (await writer.Client.EditAsync(articleId))["version"]!.GetValue<int>(), document)
            .OkJsonAsync();
        await writer.Client.PublishDraftAsync(articleId, saved["version"]!.GetValue<int>()).OkJsonAsync();
    }

    /// <summary>Every inline object of an RDoc document, in document order.</summary>
    private static IEnumerable<JsonObject> Objects(JsonNode? node) => node switch
    {
        JsonObject obj => [obj, .. obj.SelectMany(p => Objects(p.Value))],
        JsonArray array => array.SelectMany(Objects),
        _ => [],
    };

    private static IEnumerable<(Guid UserId, string Text)> Mentions(JsonNode content) =>
        Objects(content).Where(o => o["type"]?.GetValue<string>() == "mention")
            .Select(o => (o["userId"]!.GetValue<Guid>(), o["text"]!.GetValue<string>()));

    private static IEnumerable<string> Texts(JsonNode content) =>
        Objects(content).Where(o => o["type"]?.GetValue<string>() == "text").Select(o => o["text"]!.GetValue<string>());

    private static async Task<JsonArray> ListAsync(SignedInUser user) =>
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications?limit=50", Ct))!["items"]!.AsArray();

    private static async Task<IReadOnlyList<JsonNode?>> MentionsOfAsync(SignedInUser user) =>
        [.. (await ListAsync(user)).Where(e => e!["type"]!.GetValue<string>() == "mention")];

    private static async Task<int> UnreadAsync(SignedInUser user) =>
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications/unread-count", Ct))!["unread"]!.GetValue<int>();

    /// <summary>The users holding a <c>mention</c> entry about the article.</summary>
    private Task<List<Guid>> MentionEntriesAsync(Guid articleId) => InDbAsync(db => db.Notifications.AsNoTracking()
        .Where(n => n.ArticleId == articleId && n.Type == NotificationTypes.Mention)
        .OrderBy(n => n.CreatedAt)
        .Select(n => n.UserId)
        .ToListAsync(Ct));

    private async Task HandleAsync(ArticleMentionsDomainEvent domainEvent)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var handler = scope.ServiceProvider.GetServices<IDomainEventHandler<ArticleMentionsDomainEvent>>()
            .OfType<ArticleMentionNotificationHandler>().Single();
        await handler.Handle(domainEvent, Ct);
    }

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> query)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await query(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }
}
