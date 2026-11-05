using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The comment row and the reply box of the pre-production step (SPEC F11, contract "Comments"): the author's follow
/// state and title, a reply whose @mention the person doesn't allow, and text-only comments.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class CommentRowTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static string Username(SignedInUser user) => user.Me["username"]!.GetValue<string>();

    private static async Task<JsonObject> PostAsync(HttpClient client, string url, object body)
    {
        var response = await client.PostAsJsonAsync(url, body, Ct);
        var raw = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, raw);
        return JsonNode.Parse(raw)!.AsObject();
    }

    private static async Task<JsonArray> NotificationsAsync(SignedInUser user) =>
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications?limit=50", Ct))!["items"]!.AsArray();

    private static async Task<JsonObject> CommentAsync(HttpClient client, Guid commentId) =>
        await client.GetAsync($"/api/v1/comments/{commentId}", Ct).OkJsonAsync();

    [Fact]
    public async Task A_comment_says_whether_you_follow_its_author()
    {
        var writer = await api.UserAsync();
        var (articleId, _) = await writer.Client.PublishAsync();
        var commenter = await api.UserAsync("Commenter");
        var reader = await api.UserAsync();
        var comment = await PostAsync(commenter.Client, $"/api/v1/articles/{articleId}/comments", new { body = "Follow me?" });
        var id = comment["id"]!.GetValue<Guid>();

        comment["isFollowingAuthor"]!.GetValue<bool>().Should().BeFalse("your own comment");
        (await CommentAsync(reader.Client, id))["isFollowingAuthor"]!.GetValue<bool>().Should().BeFalse();
        (await CommentAsync(api.GuestClient(), id))["isFollowingAuthor"]!.GetValue<bool>().Should().BeFalse("guests");

        await reader.Client.PutEmptyAsync($"/api/v1/users/{commenter.Id}/follow").OkJsonAsync();
        (await CommentAsync(reader.Client, id))["isFollowingAuthor"]!.GetValue<bool>().Should().BeTrue();
        var list = await reader.Client.GetAsync($"/api/v1/articles/{articleId}/comments", Ct).OkJsonAsync();
        list["items"]![0]!["isFollowingAuthor"]!.GetValue<bool>().Should().BeTrue("lists carry it too");

        // Replies in a list carry it as well.
        await PostAsync(commenter.Client, $"/api/v1/comments/{id}/replies", new { body = "A reply" });
        (await reader.Client.GetAsync($"/api/v1/articles/{articleId}/comments", Ct).OkJsonAsync())["items"]![0]!["replies"]![0]!["isFollowingAuthor"]!
            .GetValue<bool>().Should().BeTrue();
    }

    [Fact]
    public async Task A_comment_shows_its_authors_title()
    {
        var writer = await api.UserAsync();
        var (articleId, _) = await writer.Client.PublishAsync();
        var commenter = await api.UserAsync("Titled Commenter");
        (await commenter.Client.PatchAsJsonAsync("/api/v1/me",
                new { displayName = "Titled Commenter", username = Username(commenter), headline = "Backend · .NET" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        var comment = await PostAsync(commenter.Client, $"/api/v1/articles/{articleId}/comments", new { body = "Hi" });
        comment["author"]!["headline"]!.GetValue<string>().Should().Be("Backend · .NET");
        comment["author"]!.AsObject().Select(p => p.Key).Should().Equal("id", "displayName", "username", "avatarUrl", "isVerified", "headline");
    }

    [Fact]
    public async Task A_reply_mentioning_someone_who_doesnt_allow_it_is_posted_without_the_mention_and_still_notifies()
    {
        var writer = await api.UserAsync();
        var (articleId, _) = await writer.Client.PublishAsync();
        var privateUser = await api.UserAsync("Private Person");
        (await privateUser.Client.PutAsJsonAsync("/api/v1/me/privacy", new { whoCanMention = "nobody" }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var open = await api.UserAsync("Open Person");
        var replier = await api.UserAsync("Replier");

        var parent = (await PostAsync(privateUser.Client, $"/api/v1/articles/{articleId}/comments", new { body = "Private thoughts" }))["id"]!.GetValue<Guid>();
        var reply = await PostAsync(replier.Client, $"/api/v1/comments/{parent}/replies", new { body = $"@{Username(privateUser)} I agree" });

        reply["body"]!.GetValue<string>().Should().Be($"@{Username(privateUser)} I agree", "the handle stays as plain text");
        reply["mentions"]!.AsArray().Should().BeEmpty("no error, just no mention");
        var entry = (await NotificationsAsync(privateUser)).Should().ContainSingle().Subject!;
        entry["type"]!.GetValue<string>().Should().Be("comment_reply", "the reply notification still goes out");
        entry["comment"]!["id"]!.GetValue<Guid>().Should().Be(reply["id"]!.GetValue<Guid>());

        // Someone who allows it is mentioned (and told once, by the mention).
        var openParent = (await PostAsync(open.Client, $"/api/v1/articles/{articleId}/comments", new { body = "Open thoughts" }))["id"]!.GetValue<Guid>();
        var mentioned = await PostAsync(replier.Client, $"/api/v1/comments/{openParent}/replies", new { body = $"@{Username(open)} agreed" });
        mentioned["mentions"]!.AsArray().Select(m => m!["userId"]!.GetValue<Guid>()).Should().Equal(open.Id);
        (await NotificationsAsync(open)).Should().ContainSingle().Which!["type"]!.GetValue<string>().Should().Be("mention");
    }

    [Fact]
    public async Task Comments_are_text_only_and_media_fields_are_ignored()
    {
        var writer = await api.UserAsync();
        var (articleId, _) = await writer.Client.PublishAsync();
        var commenter = await api.UserAsync();

        var comment = await PostAsync(commenter.Client, $"/api/v1/articles/{articleId}/comments", new
        {
            body = "Text and emoji only 👏",
            attachments = new[] { new { mediaAssetId = Guid.NewGuid() } },
            imageUrl = "https://example.com/a.png",
            gif = "https://media.example.com/funny.gif",
        });
        comment["body"]!.GetValue<string>().Should().Be("Text and emoji only 👏");
        comment.Select(p => p.Key).Should().NotContain(["attachments", "imageUrl", "gif", "media", "images"]);

        var reply = await PostAsync(commenter.Client, $"/api/v1/comments/{comment["id"]!.GetValue<Guid>()}/replies", new { body = "Reply", imageUrl = "https://example.com/b.png" });
        reply.Select(p => p.Key).Should().NotContain("imageUrl");

        using var scope = api.Services.CreateScope();
        var stored = await scope.ServiceProvider.GetRequiredService<AppDbContext>().Comments.AsNoTracking()
            .SingleAsync(c => c.Id == comment["id"]!.GetValue<Guid>(), Ct);
        stored.Body.Should().Be("Text and emoji only 👏");
    }
}
