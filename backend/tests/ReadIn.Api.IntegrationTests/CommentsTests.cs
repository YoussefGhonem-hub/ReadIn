using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Comments and replies (SPEC F11), with reports and moderator actions (F22 hooks) and live events (F27).</summary>
[Collection(ApiCollection.Name)]
public sealed class CommentsTests(ApiFactory api)
{
    private const string ModeratorPhone = "+12025550103";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Guests_read_comments_but_must_sign_in_to_write()
    {
        var (_, articleId) = await NewArticleAsync();
        var reader = await api.SignUpAsync();
        await PostAsync(reader, articleId, "مقال مفيد جدًا 👏");

        var page = await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments", Ct);
        page!["items"]!.AsArray().Should().ContainSingle().Which!["body"]!.GetValue<string>().Should().Be("مقال مفيد جدًا 👏");

        var post = await api.GuestClient().PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body = "hi" }, Ct);
        post.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Posting_a_comment_links_mentions_counts_it_and_signals_it_live()
    {
        var (author, articleId) = await NewArticleAsync();
        var reader = await api.SignUpAsync();
        var mentioned = (string)author.Me["username"]!;

        var comment = await PostAsync(reader, articleId, $"  شكرًا @{mentioned} على المقال، و@nobody_here كمان \r\n\r\n\r\nتحفة  ");

        comment["body"]!.GetValue<string>().Should().Be($"شكرًا @{mentioned} على المقال، و@nobody_here كمان\n\nتحفة");
        comment["author"]!["id"]!.GetValue<Guid>().Should().Be(reader.Id);
        comment["isArticleAuthor"]!.GetValue<bool>().Should().BeFalse();
        comment["canEdit"]!.GetValue<bool>().Should().BeTrue();
        comment["mentions"]!.AsArray().Should().ContainSingle()
            .Which!["username"]!.GetValue<string>().Should().Be(mentioned, "unknown @handles stay plain text");

        var id = comment["id"]!.GetValue<Guid>();
        await WaitForAsync(() => Task.FromResult(api.Realtime.EventsFor(articleId).Any(e => e.CommentId == id && e.Type == "comment.created")),
            "a live event goes out after the commit (F27)");
        await WaitForAsync(async () => await CommentCountAsync(articleId) == 1, "the article's comment count follows");
        api.Realtime.CountersFor(articleId).Last().CommentCount.Should().Be(1);
    }

    [Fact]
    public async Task Replies_are_one_level_deep_and_the_article_author_gets_the_writer_badge()
    {
        var (author, articleId) = await NewArticleAsync();
        var reader = await api.SignUpAsync();
        var top = await PostAsync(reader, articleId, "سؤال: ده بيفرق في المشاريع الكبيرة؟");
        var topId = top["id"]!.GetValue<Guid>();

        var answer = await ReplyAsync(author, topId, "أيوه، بيفرق جدًا.");
        var followUp = await ReplyAsync(reader, answer["id"]!.GetValue<Guid>(), "تمام، شكرًا!");

        answer["parentId"]!.GetValue<Guid>().Should().Be(topId);
        answer["isArticleAuthor"]!.GetValue<bool>().Should().BeTrue("the \"الكاتب\" badge");
        followUp["parentId"]!.GetValue<Guid>().Should().Be(topId, "replying to a reply joins the thread");

        var page = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments", Ct))!;
        var thread = page["items"]!.AsArray().Should().ContainSingle().Subject!;
        thread["replyCount"]!.GetValue<int>().Should().Be(2);
        thread["replies"]!.AsArray().Select(r => r!["body"]!.GetValue<string>()).Should().Equal("أيوه، بيفرق جدًا.", "تمام، شكرًا!");

        var replies = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/comments/{topId}/replies?limit=1", Ct))!;
        replies["items"]!.AsArray().Should().ContainSingle();
        replies["nextCursor"].Should().NotBeNull();

        await WaitForAsync(() => Task.FromResult(api.Realtime.EventsFor(articleId).Any(e => e.Type == "reply.created" && e.ParentId == topId)),
            "replies are signalled with their thread");
        await WaitForAsync(async () => await CommentCountAsync(articleId) == 3, "replies count too");
    }

    [Fact]
    public async Task Only_the_author_edits_and_the_text_rules_apply()
    {
        var (_, articleId) = await NewArticleAsync();
        var author = await api.SignUpAsync();
        var other = await api.SignUpAsync();
        var id = (await PostAsync(author, articleId, "أول نسخة"))["id"]!.GetValue<Guid>();

        (await other.Client.PatchAsJsonAsync($"/api/v1/comments/{id}", new { body = "تعديل" }, Ct)).StatusCode.Should().Be(HttpStatusCode.Forbidden);
        var empty = await author.Client.PatchAsJsonAsync($"/api/v1/comments/{id}", new { body = "   " }, Ct);
        empty.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await CodeAsync(empty)).Should().Be("comment.empty");
        var tooLong = await author.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body = new string('x', 2001) }, Ct);
        (await CodeAsync(tooLong)).Should().Be("comment.too_long");

        var edited = await ReadAsync(await author.Client.PatchAsJsonAsync($"/api/v1/comments/{id}", new { body = "نسخة متعدلة" }, Ct));
        edited["body"]!.GetValue<string>().Should().Be("نسخة متعدلة");
        edited["editedAt"].Should().NotBeNull("it shows \"edited\"");
    }

    [Fact]
    public async Task A_deleted_comment_with_replies_stays_as_a_placeholder()
    {
        var (_, articleId) = await NewArticleAsync();
        var a = await api.SignUpAsync();
        var b = await api.SignUpAsync();
        var withReplies = (await PostAsync(a, articleId, "عليه رد"))["id"]!.GetValue<Guid>();
        await ReplyAsync(b, withReplies, "ده الرد");
        var alone = (await PostAsync(a, articleId, "من غير ردود"))["id"]!.GetValue<Guid>();

        (await b.Client.DeleteAsync($"/api/v1/comments/{alone}", Ct)).StatusCode.Should().Be(HttpStatusCode.Forbidden);
        (await a.Client.DeleteAsync($"/api/v1/comments/{withReplies}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await a.Client.DeleteAsync($"/api/v1/comments/{alone}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await a.Client.DeleteAsync($"/api/v1/comments/{alone}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent, "DELETE is idempotent");

        var items = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments?sort=new", Ct))!["items"]!.AsArray();
        var placeholder = items.Should().ContainSingle().Subject!;
        placeholder["id"]!.GetValue<Guid>().Should().Be(withReplies);
        placeholder["isDeleted"]!.GetValue<bool>().Should().BeTrue();
        placeholder["body"].Should().BeNull();
        placeholder["author"].Should().BeNull();
        placeholder["replies"]!.AsArray().Should().ContainSingle().Which!["body"]!.GetValue<string>().Should().Be("ده الرد");

        await WaitForAsync(async () => await CommentCountAsync(articleId) == 1, "only the reply is still readable");
    }

    [Fact]
    public async Task Likes_are_idempotent_and_show_for_the_viewer()
    {
        var (_, articleId) = await NewArticleAsync();
        var author = await api.SignUpAsync();
        var fan = await api.SignUpAsync();
        var id = (await PostAsync(author, articleId, "حلو"))["id"]!.GetValue<Guid>();

        (await ReadAsync(await fan.Client.PutAsync($"/api/v1/comments/{id}/like", null, Ct)))["likeCount"]!.GetValue<int>().Should().Be(1);
        (await ReadAsync(await fan.Client.PutAsync($"/api/v1/comments/{id}/like", null, Ct)))["likeCount"]!.GetValue<int>().Should().Be(1);

        var seen = (await fan.Client.GetFromJsonAsync<JsonObject>($"/api/v1/comments/{id}", Ct))!;
        seen["likedByMe"]!.GetValue<bool>().Should().BeTrue();
        seen["likeCount"]!.GetValue<int>().Should().Be(1);

        (await ReadAsync(await fan.Client.DeleteAsync($"/api/v1/comments/{id}/like", Ct)))["likeCount"]!.GetValue<int>().Should().Be(0);
        (await ReadAsync(await fan.Client.DeleteAsync($"/api/v1/comments/{id}/like", Ct)))["liked"]!.GetValue<bool>().Should().BeFalse();
        await WaitForAsync(() => Task.FromResult(api.Realtime.EventsFor(articleId).Count(e => e.CommentId == id && e.Type == "comment.liked") == 2),
            "a like and an unlike, each signalled once");
    }

    [Fact]
    public async Task The_article_author_pins_one_top_level_comment()
    {
        var (author, articleId) = await NewArticleAsync();
        var reader = await api.SignUpAsync();
        var first = (await PostAsync(reader, articleId, "الأول"))["id"]!.GetValue<Guid>();
        var second = (await PostAsync(reader, articleId, "التاني"))["id"]!.GetValue<Guid>();
        var reply = (await ReplyAsync(reader, first, "رد"))["id"]!.GetValue<Guid>();

        (await reader.Client.PostAsync($"/api/v1/comments/{first}/pin", null, Ct)).StatusCode.Should().Be(HttpStatusCode.Forbidden);
        (await CodeAsync(await author.Client.PostAsync($"/api/v1/comments/{reply}/pin", null, Ct))).Should().Be("comment.pin_reply");

        (await ReadAsync(await author.Client.PostAsync($"/api/v1/comments/{first}/pin", null, Ct)))["isPinned"]!.GetValue<bool>().Should().BeTrue();
        (await ReadAsync(await author.Client.PostAsync($"/api/v1/comments/{second}/pin", null, Ct)))["isPinned"]!.GetValue<bool>().Should().BeTrue();

        var items = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments?sort=new", Ct))!["items"]!.AsArray();
        items[0]!["id"]!.GetValue<Guid>().Should().Be(second, "the pinned comment comes first");
        items.Count(i => i!["isPinned"]!.GetValue<bool>()).Should().Be(1, "pinning another one unpins the first");

        (await ReadAsync(await author.Client.DeleteAsync($"/api/v1/comments/{second}/pin", Ct)))["isPinned"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task Newest_and_top_orders()
    {
        var (_, articleId) = await NewArticleAsync();
        var writer = await api.SignUpAsync();
        var fan = await api.SignUpAsync();
        var older = (await PostAsync(writer, articleId, "أقدم تعليق"))["id"]!.GetValue<Guid>();
        var newer = (await PostAsync(writer, articleId, "أحدث تعليق"))["id"]!.GetValue<Guid>();
        await fan.Client.PutAsync($"/api/v1/comments/{older}/like", null, Ct);

        var byNew = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments?sort=new", Ct))!;
        var byTop = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments?sort=top", Ct))!;

        byNew["items"]!.AsArray().Select(i => i!["id"]!.GetValue<Guid>()).Should().Equal(newer, older);
        byTop["items"]!.AsArray().Select(i => i!["id"]!.GetValue<Guid>()).Should().Equal(older, newer);

        var firstPage = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments?sort=new&limit=1", Ct))!;
        var cursor = firstPage["nextCursor"]!.GetValue<string>();
        var secondPage = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments?sort=new&limit=1&cursor={cursor}", Ct))!;
        secondPage["items"]!.AsArray().Single()!["id"]!.GetValue<Guid>().Should().Be(older);
    }

    [Fact]
    public async Task One_account_cant_flood_an_article()
    {
        var (_, articleId) = await NewArticleAsync();
        var spammer = await api.SignUpAsync();

        await PostAsync(spammer, articleId, "نفس الكلام");
        var again = await spammer.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body = "  نفس   الكلام " }, Ct);
        again.StatusCode.Should().Be(HttpStatusCode.Conflict);
        (await CodeAsync(again)).Should().Be("comment.duplicate");

        // 20 in the last hour (written directly, so the 10-a-minute limit isn't what stops the next one).
        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Comments.AddRange(Enumerable.Range(0, 19).Select(i => Comment.Post(articleId, spammer.Id, $"تعليق {i}", [], DateTime.UtcNow)));
            foreach (var entry in db.ChangeTracker.Entries<Domain.Common.AggregateRoot>()) entry.Entity.ClearDomainEvents();
            await db.SaveChangesAsync(Ct);
        }

        var capped = await spammer.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body = "كمان واحد" }, Ct);
        capped.StatusCode.Should().Be(HttpStatusCode.TooManyRequests);
        (await CodeAsync(capped)).Should().Be("comment.article_limit");

        var (_, otherArticle) = await NewArticleAsync();
        (await spammer.Client.PostAsJsonAsync($"/api/v1/articles/{otherArticle}/comments", new { body = "مقال تاني" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.Created, "the cap is per article");
    }

    [Fact]
    public async Task Ten_comments_a_minute_per_user()
    {
        var user = await api.SignUpAsync();
        var articles = new List<Guid>();
        for (var i = 0; i < 2; i++) articles.Add((await NewArticleAsync()).ArticleId);

        var statuses = new List<HttpStatusCode>();
        for (var i = 0; i < 11; i++)
        {
            var response = await user.Client.PostAsJsonAsync($"/api/v1/articles/{articles[i % 2]}/comments", new { body = $"تعليق رقم {i}" }, Ct);
            statuses.Add(response.StatusCode);
        }

        statuses.Take(10).Should().AllBeEquivalentTo(HttpStatusCode.Created);
        statuses[10].Should().Be(HttpStatusCode.TooManyRequests);
    }

    [Fact]
    public async Task Reports_are_filed_once_and_never_for_own_comments()
    {
        var (_, articleId) = await NewArticleAsync();
        var author = await api.SignUpAsync();
        var reporter = await api.SignUpAsync();
        var id = (await PostAsync(author, articleId, "سبام"))["id"]!.GetValue<Guid>();

        object Report(string reason = "spam", string type = "comment") => new { targetType = type, targetId = id, reason, details = "إعلان" };
        (await reporter.Client.PostAsJsonAsync("/api/v1/reports", Report(), Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await reporter.Client.PostAsJsonAsync("/api/v1/reports", Report(), Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await CodeAsync(await author.Client.PostAsJsonAsync("/api/v1/reports", Report(), Ct))).Should().Be("report.own_content");
        (await CodeAsync(await reporter.Client.PostAsJsonAsync("/api/v1/reports", Report(type: "article"), Ct)))
            .Should().Be("report.target_not_found", "the id is a comment's, not an article's");
        (await reporter.Client.PostAsJsonAsync("/api/v1/reports", Report(type: "photo"), Ct)).StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await reporter.Client.PostAsJsonAsync("/api/v1/reports", Report(reason: "rude"), Ct)).StatusCode.Should().Be(HttpStatusCode.BadRequest);

        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        (await db.Reports.CountAsync(r => r.TargetId == id, Ct)).Should().Be(1);
    }

    [Fact]
    public async Task Moderators_hide_unhide_and_delete_with_an_audit_trail()
    {
        var (_, articleId) = await NewArticleAsync();
        var author = await api.SignUpAsync();
        var reporter = await api.SignUpAsync();
        var moderator = await api.SeedUserClientAsync(ModeratorPhone);
        var id = (await PostAsync(author, articleId, "Check my channel!!!"))["id"]!.GetValue<Guid>();
        await reporter.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "comment", targetId = id, reason = "spam" }, Ct);

        object Action(string action) => new { action, targetType = "comment", targetId = id };
        (await reporter.Client.PostAsJsonAsync("/api/v1/moderation/actions", Action("hide"), Ct)).StatusCode.Should().Be(HttpStatusCode.Forbidden);
        (await moderator.PostAsJsonAsync("/api/v1/moderation/actions", Action("hide"), Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{articleId}/comments", Ct))!["items"]!.AsArray()
            .Should().BeEmpty("a hidden comment without replies is left out for readers");
        var forAuthor = (await author.Client.GetFromJsonAsync<JsonObject>($"/api/v1/comments/{id}", Ct))!;
        forAuthor["isHidden"]!.GetValue<bool>().Should().BeTrue();
        forAuthor["body"]!.GetValue<string>().Should().Be("Check my channel!!!", "its author still sees it, marked hidden");
        var forModerator = (await moderator.GetFromJsonAsync<JsonObject>($"/api/v1/comments/{id}", Ct))!;
        forModerator["canModerate"]!.GetValue<bool>().Should().BeTrue();
        forModerator["body"].Should().NotBeNull();

        (await moderator.PostAsJsonAsync("/api/v1/moderation/actions", Action("unhide"), Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/comments/{id}", Ct))!["body"]!.GetValue<string>().Should().Be("Check my channel!!!");
        (await moderator.PostAsJsonAsync("/api/v1/moderation/actions", Action("delete"), Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var stored = await db.Comments.IgnoreQueryFilters().SingleAsync(c => c.Id == id, Ct);
        stored.IsDeleted.Should().BeTrue();
        stored.DeletedByModerator.Should().BeTrue();
        (await db.Reports.SingleAsync(r => r.TargetId == id, Ct)).Status.Should().Be(ReportStatus.Resolved);
        (await db.AuditLogs.Where(l => l.UserId == author.Id).Select(l => l.Action).ToListAsync(Ct))
            .Should().Contain([AuditActions.CommentHidden, AuditActions.CommentUnhidden, AuditActions.CommentDeleted]);
    }

    [Fact]
    public async Task A_deleted_accounts_comments_stay_as_deleted_user()
    {
        var (_, articleId) = await NewArticleAsync();
        var leaving = await api.SignUpAsync();
        var id = (await PostAsync(leaving, articleId, "تعليق هيفضل موجود"))["id"]!.GetValue<Guid>();

        // What account deletion does to the row (readin's AccountEraser): the comment's author becomes null (SET NULL). As
        // there, its rows as the actor of other people's notifications (F17, no cascade) go first.
        using (var scope = api.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            await db.NotificationActors.Where(a => a.ActorId == leaving.Id).ExecuteDeleteAsync(Ct);
            await db.Users.IgnoreQueryFilters().Where(u => u.Id == leaving.Id).ExecuteDeleteAsync(Ct);
        }

        var comment = (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/comments/{id}", Ct))!;
        comment["body"]!.GetValue<string>().Should().Be("تعليق هيفضل موجود", "the account-deletion page promises comments stay");
        comment["author"].Should().BeNull("shown as \"Deleted user\"");
        comment["isDeleted"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task Mention_suggestions_match_handles_and_names()
    {
        var me = await api.SignUpAsync();

        var suggestions = (await me.Client.GetFromJsonAsync<JsonArray>("/api/v1/users/mention-suggestions?q=@reader", Ct))!;

        suggestions.Should().NotBeEmpty();
        suggestions.Select(s => s!["username"]!.GetValue<string>()).Should().AllSatisfy(u => u.Should().StartWith("reader"));
        (await api.GuestClient().GetAsync("/api/v1/users/mention-suggestions?q=reader", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private async Task<(SignedInUser Author, Guid ArticleId)> NewArticleAsync()
    {
        var author = await api.SignUpAsync();
        var fieldId = (await author.Client.GetFromJsonAsync<JsonArray>("/api/v1/fields", Ct))!
            .Single(f => f!["slug"]!.GetValue<string>() == "dotnet")!["id"]!.GetValue<Guid>();
        var (id, _) = await author.Client.WriteAndPublishAsync(ArticleTestKit.Document(
            fieldId, $"Comments test {Guid.NewGuid():N}", sources: [new { title = "Docs", url = "https://learn.microsoft.com/dotnet" }]));
        return (author, id);
    }

    private static async Task<JsonObject> PostAsync(SignedInUser user, Guid articleId, string body)
    {
        var response = await user.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return await ReadAsync(response);
    }

    private static async Task<JsonObject> ReplyAsync(SignedInUser user, Guid commentId, string body)
    {
        var response = await user.Client.PostAsJsonAsync($"/api/v1/comments/{commentId}/replies", new { body }, Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, await response.Content.ReadAsStringAsync(Ct));
        return await ReadAsync(response);
    }

    private static Task<JsonObject> ReadAsync(HttpResponseMessage response) => ApiFactory.ReadSessionAsync(response);

    private static async Task<string?> CodeAsync(HttpResponseMessage response) =>
        (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))?["code"]?.GetValue<string>();

    private async Task<int> CommentCountAsync(Guid articleId)
    {
        using var scope = api.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        return await db.Articles.AsNoTracking().Where(a => a.Id == articleId).Select(a => a.CommentCount).SingleAsync(Ct);
    }

    private static async Task WaitForAsync(Func<Task<bool>> condition, string because)
    {
        for (var i = 0; i < 50; i++)
        {
            if (await condition()) return;
            await Task.Delay(100, Ct);
        }
        (await condition()).Should().BeTrue(because);
    }
}
