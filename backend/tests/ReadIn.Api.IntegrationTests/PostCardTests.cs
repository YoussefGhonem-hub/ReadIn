using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Security;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F34 post-style feed cards: what every card carries (excerpt, hasMore, tags, isFollowingAuthor), the excerpt backfill,
/// and <c>GET /articles/{id}/preview</c> behind "Read more".
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class PostCardTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static string Words(int count, string word = "word") => string.Join(' ', Enumerable.Repeat(word, count));

    private static object Heading(string text, string id) =>
        new { id, type = "heading", level = 2, dir = "auto", content = new[] { new { type = "text", text } } };

    // ── Cards ───────────────────────────────────────────────────

    [Fact]
    public async Task Cards_carry_the_excerpt_three_tags_and_whether_you_follow_the_writer()
    {
        var writer = await api.UserAsync("Card Writer");
        var follower = await api.UserAsync("Card Follower");
        await follower.Client.PutEmptyAsync($"/api/v1/users/{writer.Id}/follow").OkJsonAsync();
        var mention = "@" + follower.Me["username"]!.GetValue<string>();
        string[] tags = [.. Enumerable.Range(1, 5).Select(i => $"card{i}-{Guid.NewGuid():N}"[..16])];
        var article = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(
            await writer.Client.FieldIdAsync("dotnet"), "A post-style card", tags: tags,
            blocks:
            [
                ArticleTestKit.Paragraph("First paragraph.", "p1"),
                Heading("A heading", "h1"),
                ArticleTestKit.Inline("p2", ArticleTestKit.Text("Hello "), ArticleTestKit.Mention(follower.Id, mention), ArticleTestKit.Text(".")),
            ]));
        var excerpt = $"First paragraph.\nHello {mention}.";

        var forFollower = await ProfileCardAsync(follower.Client, writer, article.Id);
        forFollower["excerpt"]!.GetValue<string>().Should().Be(excerpt, "a heading is skipped, a mention gives its text");
        forFollower["hasMore"]!.GetValue<bool>().Should().BeTrue("the heading is only in the article");
        forFollower["isFollowingAuthor"]!.GetValue<bool>().Should().BeTrue();
        forFollower["tagCount"]!.GetValue<int>().Should().Be(5);

        var details = await api.GuestClient().GetAsync($"/api/v1/articles/{article.Slug}", Ct).OkJsonAsync();
        var allTags = details["tags"]!.AsArray().Select(t => t!.GetValue<string>()).ToList();
        allTags.Should().HaveCount(5, "the details keep every tag").And.BeEquivalentTo(tags);
        forFollower["tags"]!.AsArray().Select(t => t!.GetValue<string>()).Should().Equal(allTags.Take(3), "a card has the article's first three tags");

        (await ProfileCardAsync(api.GuestClient(), writer, article.Id))["isFollowingAuthor"]!.GetValue<bool>().Should().BeFalse("guests follow no one");
        (await ProfileCardAsync(writer.Client, writer, article.Id))["isFollowingAuthor"]!.GetValue<bool>().Should().BeFalse("never on your own article");

        var inFeed = await follower.Client.FindInForYouAsync(article.Id);
        inFeed["excerpt"]!.GetValue<string>().Should().Be(excerpt);
        inFeed["isFollowingAuthor"]!.GetValue<bool>().Should().BeTrue();
        inFeed["tags"]!.AsArray().Should().HaveCount(3);
    }

    [Fact]
    public async Task A_short_text_only_article_shows_whole_in_its_card()
    {
        var writer = await api.UserAsync("Short Writer");
        var article = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(
            await writer.Client.FieldIdAsync("dotnet"), "A short post", blocks: [ArticleTestKit.Paragraph("Just this.")]));

        var card = await ProfileCardAsync(api.GuestClient(), writer, article.Id);

        card["excerpt"]!.GetValue<string>().Should().Be("Just this.");
        card["hasMore"]!.GetValue<bool>().Should().BeFalse();
        card["tags"]!.AsArray().Should().BeEmpty();
        card["tagCount"]!.GetValue<int>().Should().Be(0);
    }

    [Fact]
    public async Task The_backfill_fills_missing_excerpts_once_and_keeps_written_ones()
    {
        var writer = await api.UserAsync("Backfill Writer");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var old = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "Published before F34",
            blocks: [ArticleTestKit.Paragraph(Words(120, "older")), Heading("Then", "h")]));
        var kept = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "Written meanwhile",
            blocks: [ArticleTestKit.Paragraph("Original.")]));

        await InDbAsync(db => db.ArticleTranslations.Where(t => t.ArticleId == old.Id)
            .ExecuteUpdateAsync(set => set.SetProperty(t => t.Excerpt, (string?)null).SetProperty(t => t.ExcerptHasMore, false), Ct));
        await InDbAsync(db => db.ArticleTranslations.Where(t => t.ArticleId == kept.Id)
            .ExecuteUpdateAsync(set => set.SetProperty(t => t.Excerpt, "Kept as written."), Ct));

        var before = await ProfileCardAsync(api.GuestClient(), writer, old.Id);
        before["excerpt"].Should().BeNull("not backfilled yet");
        before["hasMore"]!.GetValue<bool>().Should().BeTrue("a card without an excerpt has everything left to read");

        (await RunBackfillAsync()).Should().BeGreaterThanOrEqualTo(1);
        (await RunBackfillAsync()).Should().Be(0, "nothing is left, so a run after every start does nothing");

        var after = await ProfileCardAsync(api.GuestClient(), writer, old.Id);
        after["excerpt"]!.GetValue<string>().Should().Be(Words(66, "older"), "cut at a word within 400 characters");
        after["hasMore"]!.GetValue<bool>().Should().BeTrue();
        (await ProfileCardAsync(api.GuestClient(), writer, kept.Id))["excerpt"]!.GetValue<string>().Should().Be("Kept as written.");
    }

    // ── Preview ─────────────────────────────────────────────────

    [Fact]
    public async Task The_preview_takes_whole_blocks_up_to_about_300_words()
    {
        var writer = await api.UserAsync("Preview Writer");
        var blocks = Enumerable.Range(1, 10).Select(i => ArticleTestKit.Paragraph(Words(50, $"w{i}"), $"p{i}")).ToArray();
        var article = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(
            await writer.Client.FieldIdAsync("dotnet"), "A long post", blocks: blocks));

        var preview = await api.GuestClient().GetAsync(Preview(article.Id), Ct).OkJsonAsync();

        preview["id"]!.GetValue<Guid>().Should().Be(article.Id);
        preview["language"]!.GetValue<string>().Should().Be("en");
        preview["isComplete"]!.GetValue<bool>().Should().BeFalse();
        var content = preview["content"]!.AsObject();
        content["version"]!.GetValue<int>().Should().Be(1);
        var taken = content["blocks"]!.AsArray();
        taken.Should().HaveCount(6, "the sixth 50-word paragraph reaches 300 words");

        var details = await api.GuestClient().GetAsync($"/api/v1/articles/{article.Slug}", Ct).OkJsonAsync();
        var whole = details["content"]!["blocks"]!.AsArray();
        for (var i = 0; i < taken.Count; i++)
            JsonNode.DeepEquals(taken[i], whole[i]).Should().BeTrue("blocks come whole and as the reader gets them");
    }

    [Fact]
    public async Task A_short_article_preview_is_the_whole_article_and_one_long_block_is_kept_whole()
    {
        var writer = await api.UserAsync("Preview Writer");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var shortOne = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "A short post",
            blocks: [ArticleTestKit.Paragraph("One.", "a"), Heading("Two", "h"), ArticleTestKit.Paragraph("Three.", "b")]));
        var longBlock = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "One long paragraph",
            blocks: [ArticleTestKit.Paragraph(Words(700), "a"), ArticleTestKit.Paragraph("After.", "b")]));

        var complete = await api.GuestClient().GetAsync(Preview(shortOne.Id), Ct).OkJsonAsync();
        complete["isComplete"]!.GetValue<bool>().Should().BeTrue();
        var details = await api.GuestClient().GetAsync($"/api/v1/articles/{shortOne.Slug}", Ct).OkJsonAsync();
        JsonNode.DeepEquals(complete["content"], details["content"]).Should().BeTrue("a complete preview is the article's content");

        var cut = await api.GuestClient().GetAsync(Preview(longBlock.Id), Ct).OkJsonAsync();
        cut["isComplete"]!.GetValue<bool>().Should().BeFalse();
        var only = cut["content"]!["blocks"]!.AsArray().Should().ContainSingle("there is always at least one block").Subject;
        only!["content"]![0]!["text"]!.GetValue<string>().Should().Be(Words(700), "a block is never cut");
    }

    [Fact]
    public async Task The_preview_serves_the_requested_version_else_the_source_language()
    {
        var writer = await api.UserAsync("Preview Writer");
        var field = await writer.Client.FieldIdAsync("dotnet");
        var englishOnly = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "English only",
            blocks: [ArticleTestKit.Paragraph("English text.")]));
        var bilingual = ArticleTestKit.Document(field, "مقال بلغتين", "ar-EG", [ArticleTestKit.Paragraph("نص عربي.")]);
        bilingual["translations"]!.AsArray().Add(JsonSerializerHelper.ToNode(new
        {
            language = "en",
            title = "A two-language post",
            subtitle = (string?)null,
            content = new { version = 1, language = "en", blocks = new[] { ArticleTestKit.Paragraph("English version.") } },
        }));
        var both = await writer.Client.WriteAndPublishAsync(bilingual);

        var fallback = await api.GuestClient().GetAsync(Preview(englishOnly.Id, "ar-EG"), Ct).OkJsonAsync();
        fallback["language"]!.GetValue<string>().Should().Be("en");
        FirstText(fallback).Should().Be("English text.");

        var english = await api.GuestClient().GetAsync(Preview(both.Id, "en"), Ct).OkJsonAsync();
        english["language"]!.GetValue<string>().Should().Be("en");
        FirstText(english).Should().Be("English version.");

        foreach (var lang in new string?[] { null, "fr" })
        {
            var source = await api.GuestClient().GetAsync(Preview(both.Id, lang), Ct).OkJsonAsync();
            source["language"]!.GetValue<string>().Should().Be("ar-EG", "no or an unknown language gives the source version");
            FirstText(source).Should().Be("نص عربي.");
        }

        // A guest's cards are in the UI's language: a card's excerpt is from the version it serves.
        var englishCard = await ProfileCardAsync(api.GuestClient("en"), writer, both.Id);
        englishCard["language"]!.GetValue<string>().Should().Be("en");
        englishCard["excerpt"]!.GetValue<string>().Should().Be("English version.");
        var arabicCard = await ProfileCardAsync(api.GuestClient("ar"), writer, both.Id);
        arabicCard["language"]!.GetValue<string>().Should().Be("ar-EG");
        arabicCard["excerpt"]!.GetValue<string>().Should().Be("نص عربي.");
    }

    [Fact]
    public async Task The_preview_is_visible_exactly_like_the_article()
    {
        var writer = await api.UserAsync("Hidden Writer");
        var reader = await api.UserAsync("Hidden Reader");
        var moderator = await ModeratorAsync();
        var field = await writer.Client.FieldIdAsync("dotnet");
        var article = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(field, "Soon hidden"));
        var draft = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(field, "Never published"));

        await api.GuestClient().GetAsync(Preview(Guid.NewGuid()), Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await writer.Client.GetAsync(Preview(draft["id"]!.GetValue<Guid>()), Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await api.GuestClient().GetAsync(Preview(article.Id), Ct).OkJsonAsync(); // cached for everyone

        await ModerateAsync(moderator, "hide", article.Id);
        await api.GuestClient().GetAsync(Preview(article.Id), Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await reader.Client.GetAsync(Preview(article.Id), Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await writer.Client.GetAsync(Preview(article.Id), Ct).OkJsonAsync();
        await moderator.GetAsync(Preview(article.Id), Ct).OkJsonAsync();

        await ModerateAsync(moderator, "unhide", article.Id);
        await api.GuestClient().GetAsync(Preview(article.Id), Ct).OkJsonAsync();

        (await writer.Client.DeleteAsync($"/api/v1/articles/{article.Id}", Ct)).EnsureSuccessStatusCode();
        await api.GuestClient().GetAsync(Preview(article.Id), Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await writer.Client.GetAsync(Preview(article.Id), Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
    }

    [Fact]
    public async Task An_update_replaces_the_cached_preview()
    {
        var writer = await api.UserAsync("Update Writer");
        var article = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(
            await writer.Client.FieldIdAsync("dotnet"), "Before the update", blocks: [ArticleTestKit.Paragraph("Before.")]));
        FirstText(await api.GuestClient().GetAsync(Preview(article.Id), Ct).OkJsonAsync()).Should().Be("Before.");

        var edit = await writer.Client.EditAsync(article.Id);
        var document = edit["document"]!.AsObject();
        document["translations"]![0]!["content"]!["blocks"] = JsonSerializerHelper.ToNode(new[] { ArticleTestKit.Paragraph("After.") });
        (await writer.Client.SaveDraftAsync(article.Id, edit["version"]!.GetValue<int>(), document)).EnsureSuccessStatusCode();
        (await writer.Client.PublishCurrentAsync(article.Id)).StatusCode.Should().Be(HttpStatusCode.OK);

        FirstText(await api.GuestClient().GetAsync(Preview(article.Id), Ct).OkJsonAsync()).Should().Be("After.");
        (await ProfileCardAsync(api.GuestClient(), writer, article.Id))["excerpt"]!.GetValue<string>().Should().Be("After.");
    }

    // ── Helpers ─────────────────────────────────────────────────

    private static string Preview(Guid id, string? lang = null) =>
        $"/api/v1/articles/{id}/preview" + (lang is null ? "" : $"?lang={lang}");

    private static string FirstText(JsonObject preview) => preview["content"]!["blocks"]![0]!["content"]![0]!["text"]!.GetValue<string>();

    /// <summary>The article's card in its writer's profile Articles, as <paramref name="client"/> sees it.</summary>
    private static async Task<JsonObject> ProfileCardAsync(HttpClient client, SignedInUser writer, Guid articleId)
    {
        var page = await client.GetAsync($"/api/v1/users/{writer.Me["username"]!.GetValue<string>()}/articles?limit=50", Ct).OkJsonAsync();
        return page["items"]!.AsArray().Single(c => c!["id"]!.GetValue<Guid>() == articleId)!.AsObject();
    }

    private async Task<int> RunBackfillAsync()
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await scope.ServiceProvider.GetRequiredService<ArticleExcerptsBackfillJob>().RunAsync(Ct);
    }

    private async Task InDbAsync(Func<AppDbContext, Task> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    private async Task<HttpClient> ModeratorAsync()
    {
        var user = await api.UserAsync("Preview Moderator");
        await using var scope = api.Services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        (await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == user.Id, Ct)).GrantRole(RoleIds.Moderator);
        await db.SaveChangesAsync(Ct);
        await scope.ServiceProvider.GetRequiredService<IUserAccessService>().InvalidateAsync(user.Id, Ct);
        return user.Client;
    }

    private static async Task ModerateAsync(HttpClient moderator, string action, Guid articleId)
    {
        var response = await moderator.PostAsJsonAsync(
            "/api/v1/moderation/actions", new { action, targetType = "article", targetId = articleId, note = "F34 preview test." }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.NoContent, await response.Content.ReadAsStringAsync(Ct));
    }
}
