using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F37 content filter end to end with the test word list (<c>tests/fixtures/content/moderation</c>, neutral placeholders:
/// block سلحفاة, قط, sel7efa, wombat, "spoon fork"; flag بطيخ, kumquat): a 422 naming the field on every field family, flags
/// in the moderation queue, the console's routes, and the spam limits. Also the F36 block guard on comment, reply and
/// repost writes.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ContentFilterTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static Task<HttpResponseMessage> CommentAsync(SignedInUser user, Guid articleId, string body) =>
        user.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body }, Ct);

    private static Task<HttpResponseMessage> ReplyAsync(SignedInUser user, Guid commentId, string body) =>
        user.Client.PostAsJsonAsync($"/api/v1/comments/{commentId}/replies", new { body }, Ct);

    private static async Task<Guid> CreatedIdAsync(Task<HttpResponseMessage> request)
    {
        var response = await request;
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        return JsonNode.Parse(body)!["id"]!.GetValue<Guid>();
    }

    /// <summary>A 422 <c>content.objectionable</c> naming <paramref name="field"/>, never the matched words.</summary>
    private static async Task<JsonObject> RefusedAsync(Task<HttpResponseMessage> request, string field, params string[] words)
    {
        var problem = await request.ProblemAsync(HttpStatusCode.UnprocessableEntity, "content.objectionable");
        problem["field"]!.GetValue<string>().Should().Be(field);
        problem["title"]!.GetValue<string>().Should().Be("This text breaks our Community Guidelines. Edit it and try again.");
        foreach (var word in words) problem.ToJsonString().Should().NotContain(word, "the matched words stay for staff");
        return problem;
    }

    private Task<List<Report>> SystemReportsAsync(ReportTargetType type, Guid targetId) => api.InDbAsync(db =>
        db.Reports.AsNoTracking().Where(r => r.ReporterId == null && r.TargetType == type && r.TargetId == targetId).ToListAsync(Ct));

    private static object Link(string label) => new { platform = "other", url = $"https://example.com/{Guid.NewGuid():N}", label };

    // ── The filter on every field family ───────────────────────

    [Fact]
    public async Task A_term_with_stacked_prefixes_and_a_suffix_is_refused_on_a_comment_and_a_flag_term_goes_to_the_queue()
    {
        var writer = await api.UserAsync("Filter Writer");
        var reader = await api.UserAsync("Filter Reader");
        var (articleId, _) = await writer.Client.PublishAsync();

        // و + ب + سلحفاة written with ت before the suffix هم: the matcher strips the clitics back to the listed word.
        await RefusedAsync(CommentAsync(reader, articleId, "قرأت عن وبسلحفاتهم اليوم"), "body", "سلحف");
        await RefusedAsync(CommentAsync(reader, articleId, "a w0mb4t here"), "body", "wombat");
        (await api.InDbAsync(db => db.Comments.IgnoreQueryFilters().CountAsync(c => c.AuthorId == reader.Id, Ct)))
            .Should().Be(0, "nothing refused is saved");

        // A flag term is posted all the same, and the comment waits in the queue as a system report (F22).
        var flagged = await CreatedIdAsync(CommentAsync(reader, articleId, "أحب والبطيخ كثيرا"));
        var report = (await SystemReportsAsync(ReportTargetType.Comment, flagged)).Should().ContainSingle().Subject;
        report.Status.Should().Be(ReportStatus.Open);
        report.MatchedTerms.Should().Contain("بطيخ");

        // Spam signs flag too: a phone number in the text.
        var phone = await CreatedIdAsync(CommentAsync(reader, articleId, "call me on +20 122 939 1155"));
        (await SystemReportsAsync(ReportTargetType.Comment, phone)).Should().ContainSingle().Which.MatchedTerms.Should().Contain("[phone number]");

        // A clean comment files nothing.
        var clean = await CreatedIdAsync(CommentAsync(reader, articleId, "فقط مقال جميل")); // فقط holds قط: a 2-letter term matches only bare
        (await SystemReportsAsync(ReportTargetType.Comment, clean)).Should().BeEmpty();
    }

    [Fact]
    public async Task Replies_edits_and_repost_captions_are_screened_too()
    {
        var writer = await api.UserAsync("Filter Writer");
        var reader = await api.UserAsync("Filter Reader");
        var (articleId, _) = await writer.Client.PublishAsync();
        var commentId = await CreatedIdAsync(CommentAsync(writer, articleId, "Thanks for reading."));

        await RefusedAsync(ReplyAsync(reader, commentId, "و ل ل س ل ح ف ا ة"), "body"); // a joined run of single letters, then ولل stripped
        await RefusedAsync(ReplyAsync(reader, commentId, "a SPOON fork"), "body");
        var reply = await CreatedIdAsync(ReplyAsync(reader, commentId, "a kumquat for you"));
        (await SystemReportsAsync(ReportTargetType.Comment, reply)).Should().ContainSingle();

        await RefusedAsync(writer.Client.PatchAsJsonAsync($"/api/v1/comments/{commentId}", new { body = "w-o-m-b-a-t" }, Ct), "body");
        (await api.InDbAsync(db => db.Comments.AsNoTracking().Where(c => c.Id == commentId).Select(c => c.Body).SingleAsync(Ct)))
            .Should().Be("Thanks for reading.", "a refused edit changes nothing");
        (await writer.Client.PatchAsJsonAsync($"/api/v1/comments/{commentId}", new { body = "Thanks, and a kumquat." }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.OK);
        (await SystemReportsAsync(ReportTargetType.Comment, commentId)).Should().ContainSingle("a flagged edit files a report too");

        await RefusedAsync(reader.Client.PutAsJsonAsync($"/api/v1/articles/{articleId}/repost", new { caption = "الـــسلحفاة" }, Ct), "caption");
        (await api.InDbAsync(db => db.Reposts.CountAsync(r => r.UserId == reader.Id, Ct))).Should().Be(0);
        await reader.Client.PutAsJsonAsync($"/api/v1/articles/{articleId}/repost", new { caption = "Read this, kumquat fans" }, Ct).OkJsonAsync();
        var repostId = await api.InDbAsync(db => db.Reposts.Where(r => r.UserId == reader.Id).Select(r => r.Id).SingleAsync(Ct));
        (await SystemReportsAsync(ReportTargetType.Repost, repostId)).Should().ContainSingle();
    }

    [Fact]
    public async Task Publishing_screens_every_title_block_and_tag_and_points_at_the_block()
    {
        var writer = await api.UserAsync("Filter Writer");
        var fieldId = await writer.Client.FieldIdAsync("dotnet");

        async Task<JsonObject> RefusedPublishAsync(JsonObject document, string field)
        {
            var draft = await writer.Client.CreateDraftAsync(document);
            var id = draft["id"]!.GetValue<Guid>();
            var problem = await RefusedAsync(writer.Client.PublishDraftAsync(id, draft["version"]!.GetValue<int>()), field);
            (await api.InDbAsync(db => db.Articles.AsNoTracking().Where(a => a.Id == id).Select(a => a.PublishedAt).SingleAsync(Ct)))
                .Should().BeNull("a refused publish leaves the draft a draft");
            return problem;
        }

        (await RefusedPublishAsync(ArticleTestKit.Document(fieldId, "All about the wombat"), "title"))["language"]!.GetValue<string>().Should().Be("en");

        var block = await RefusedPublishAsync(ArticleTestKit.Document(fieldId, "A clean title", blocks:
            [ArticleTestKit.Paragraph("A clean opening.", "p1"), ArticleTestKit.Paragraph("And then a w.o.m.b.a.t appears.", "p2")]), "content");
        block["blockId"]!.GetValue<string>().Should().Be("p2");
        block["language"]!.GetValue<string>().Should().Be("en");

        await RefusedPublishAsync(ArticleTestKit.Document(fieldId, "Another clean title", tags: ["dotnet", "Wombat"]), "tags");

        // A flag term publishes, and the article waits in the queue.
        var (flagged, _) = await writer.Client.WriteAndPublishAsync(ArticleTestKit.Document(fieldId, $"Fruit notes {Guid.NewGuid():N}"[..24],
            blocks: [ArticleTestKit.Paragraph("The kumquat is small.")]));
        (await SystemReportsAsync(ReportTargetType.Article, flagged)).Should().ContainSingle().Which.MatchedTerms.Should().Contain("kumquat");
    }

    [Fact]
    public async Task Profiles_categories_collections_and_ticket_subjects_are_screened()
    {
        var user = await api.UserAsync("Filter Profile");
        object Me(object extra)
        {
            var body = new JsonObject { ["displayName"] = user.Me["displayName"]!.GetValue<string>(), ["username"] = user.Me["username"]!.GetValue<string>() };
            foreach (var (key, value) in JsonSerializerHelper.ToObject(extra)) body[key] = value?.DeepClone();
            return body;
        }
        Task<HttpResponseMessage> PatchAsync(object extra) => user.Client.PatchAsJsonAsync("/api/v1/me", Me(extra), Ct);

        await RefusedAsync(PatchAsync(new { displayName = "Mr Wombat" }), "displayName");
        await RefusedAsync(PatchAsync(new { username = $"wombat_{Guid.NewGuid():N}"[..20] }), "username");
        await RefusedAsync(PatchAsync(new { bio = "أحب السلحفاة" }), "bio");
        await RefusedAsync(PatchAsync(new { headline = "Chief sel7efa" }), "headline");
        await RefusedAsync(PatchAsync(new { links = new[] { Link("wombat") } }), "links");

        // A flag term in the bio is saved and the profile waits in the queue.
        (await PatchAsync(new { bio = "I grow kumquat trees." })).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await SystemReportsAsync(ReportTargetType.User, user.Id)).Should().ContainSingle();
        // Only what changed is screened: the flagged bio, unchanged, doesn't stop the next change.
        (await PatchAsync(new { bio = "I grow kumquat trees.", headline = "Gardener" })).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var fresh = await api.SignUpAsync();
        await RefusedAsync(fresh.Client.PutAsJsonAsync("/api/v1/me/profile/complete",
            new { displayName = "سلحفاة", username = $"f_{Guid.NewGuid():N}"[..20] }, Ct), "displayName");

        await RefusedAsync(user.Client.PostAsJsonAsync("/api/v1/me/categories", new { name = "Wombat notes" }, Ct), "name");
        var category = await CreatedIdAsync(user.Client.PostAsJsonAsync("/api/v1/me/categories", new { name = $"Notes {Guid.NewGuid():N}"[..16] }, Ct));
        await RefusedAsync(user.Client.PatchAsJsonAsync($"/api/v1/me/categories/{category}", new { name = "spoon fork" }, Ct), "name");

        await RefusedAsync(user.Client.PostAsJsonAsync("/api/v1/me/collections", new { name = "w0mbat" }, Ct), "name");
        var collection = await CreatedIdAsync(user.Client.PostAsJsonAsync("/api/v1/me/collections", new { name = "Later" }, Ct));
        await RefusedAsync(user.Client.PatchAsJsonAsync($"/api/v1/me/collections/{collection}", new { name = "سلحفاتي" }, Ct), "name");

        var ticket = new MultipartFormDataContent
        {
            { new StringContent("other"), "category" },
            { new StringContent("About the wombat"), "subject" },
            { new StringContent("A message long enough to send."), "message" },
        };
        await RefusedAsync(user.Client.PostAsync("/api/v1/support/tickets", ticket, Ct), "subject");
        (await api.InDbAsync(db => db.SupportTickets.CountAsync(t => t.UserId == user.Id, Ct))).Should().Be(0);
    }

    // ── The console ─────────────────────────────────────────────

    [Fact]
    public async Task The_console_routes_need_system_settings()
    {
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/content-filter");
        await api.AssertAdminOnlyAsync(HttpMethod.Put, "/api/v1/admin/content-filter", new { terms = Array.Empty<object>() });
        await api.AssertAdminOnlyAsync(HttpMethod.Post, "/api/v1/admin/content-filter/test", new { text = "hello" });

        var settings = await api.UserWithPermissionsAsync("Settings Staff", Permissions.System.Settings);
        var list = await settings.Client.GetAsync("/api/v1/admin/content-filter", Ct).OkJsonAsync();
        var terms = list["terms"]!.AsArray();
        terms.Should().Contain(t => t!["term"]!.GetValue<string>() == "wombat" && t["level"]!.GetValue<string>() == "block"
            && t["language"]!.GetValue<string>() == "en" && t["source"]!.GetValue<string>() == "file" && t["isEnabled"]!.GetValue<bool>());
        terms.Should().Contain(t => t!["term"]!.GetValue<string>() == "بطيخ" && t["level"]!.GetValue<string>() == "flag");
        list["counts"]!["block"]!.GetValue<int>().Should().Be(terms.Count(t => t!["isEnabled"]!.GetValue<bool>() && t["level"]!.GetValue<string>() == "block"));
        list["counts"]!["flag"]!.GetValue<int>().Should().Be(terms.Count(t => t!["isEnabled"]!.GetValue<bool>() && t["level"]!.GetValue<string>() == "flag"));
    }

    [Fact]
    public async Task The_console_replaces_the_list_the_filter_reloads_at_once_and_every_change_is_audited()
    {
        var admin = await api.SuperAdminAsync("Filter Admin");
        var writer = await api.UserAsync("Filter Writer");
        var reader = await api.UserAsync("Filter Reader");
        var (articleId, _) = await writer.Client.PublishAsync();
        var original = (await admin.Client.GetAsync("/api/v1/admin/content-filter", Ct).OkJsonAsync())["terms"]!.AsArray()
            .Where(t => t!["isEnabled"]!.GetValue<bool>())
            .Select(t => new { term = t!["term"]!.GetValue<string>(), language = t["language"]!.GetValue<string>(), level = t["level"]!.GetValue<string>() })
            .ToList();
        original.Should().NotBeEmpty();
        // Letters only (hex digits as g–p), so leetspeak never comes into it.
        var newTerm = "zebu" + new string([.. Guid.NewGuid().ToString("N")[..6].Select(ch => char.IsAsciiDigit(ch) ? (char)('g' + (ch - '0')) : ch)]);
        Task<HttpResponseMessage> PutAsync(IEnumerable<object> terms) =>
            admin.Client.PutAsJsonAsync("/api/v1/admin/content-filter", new { terms }, Ct);
        Task<List<string?>> AuditsAsync() => api.InDbAsync(db => db.AuditLogs.AsNoTracking()
            .Where(a => a.Action == AuditActions.ContentFilterUpdated && a.ActorId == admin.Id).OrderBy(a => a.CreatedAt).Select(a => a.Details).ToListAsync(Ct));

        try
        {
            // Added from the console: the matcher has it for the next write.
            var added = await PutAsync([.. original, new { term = $"  {newTerm.ToUpperInvariant()} ", language = "en", level = "block" }]).OkJsonAsync();
            added["terms"]!.AsArray().Should().Contain(t => t!["term"]!.GetValue<string>() == newTerm.ToUpperInvariant() && t["source"]!.GetValue<string>() == "console");
            await RefusedAsync(CommentAsync(reader, articleId, $"a {newTerm} here"), "body");

            // Left out: disabled (kept in the list), so the seeder never brings it back. A changed level sticks.
            var changed = original.Select(t => t.term == "kumquat" ? new { t.term, t.language, level = "block" } : t).ToList();
            var after = await PutAsync(changed).OkJsonAsync();
            after["terms"]!.AsArray().Should().Contain(t => t!["term"]!.GetValue<string>() == newTerm.ToUpperInvariant() && !t["isEnabled"]!.GetValue<bool>());
            await CreatedIdAsync(CommentAsync(reader, articleId, $"a {newTerm} here"));
            await RefusedAsync(CommentAsync(reader, articleId, "kumquats? no, one kumquat"), "body");

            // The same list again changes nothing and records nothing.
            await PutAsync(changed).OkJsonAsync();
            (await AuditsAsync()).Should().Equal("+1 -0 ~0", "+0 -1 ~1");
        }
        finally
        {
            await PutAsync(original).OkJsonAsync();
        }
        (await AuditsAsync()).Should().Equal("+1 -0 ~0", "+0 -1 ~1", "+0 -0 ~1");
        await CreatedIdAsync(CommentAsync(reader, articleId, "one kumquat again")); // flag level again
    }

    [Fact]
    public async Task The_console_refuses_unusable_terms()
    {
        var admin = await api.SuperAdminAsync("Filter Admin");
        Task<HttpResponseMessage> PutAsync(object body) => admin.Client.PutAsJsonAsync("/api/v1/admin/content-filter", body, Ct);

        await PutAsync(new { }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        foreach (var bad in new object[]
                 {
                     new { term = "x", language = "en", level = "block" },
                     new { term = "  ---  ", language = "en", level = "block" },
                     new { term = "1234", language = "en", level = "block" },
                     new { term = new string('a', 101), language = "en", level = "block" },
                 })
        {
            var problem = await PutAsync(new { terms = new[] { bad } }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
            problem["errors"]!.ToJsonString().Should().Contain("content_filter.term_invalid");
        }
        await PutAsync(new { terms = new[] { new { term = "wombat", language = "fr", level = "block" } } }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        await PutAsync(new { terms = new[] { new { term = "wombat", language = "en", level = "ban" } } }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
    }

    [Fact]
    public async Task The_test_route_shows_the_level_and_the_matched_terms()
    {
        var admin = await api.SuperAdminAsync("Filter Admin");
        Task<JsonObject> TestAsync(string text) =>
            admin.Client.PostAsJsonAsync("/api/v1/admin/content-filter/test", new { text }, Ct).OkJsonAsync();

        var both = await TestAsync("وبسلحفاتهم and a k-u-m-q-u-a-t");
        both["level"]!.GetValue<string>().Should().Be("block");
        both["matches"]!.AsArray().Select(m => m!.GetValue<string>()).Should().Equal("kumquat", "سلحفاه");

        var flag = await TestAsync("visit https://a.example https://b.example https://c.example");
        flag["level"]!.GetValue<string>().Should().Be("flag");
        flag["matches"]!.AsArray().Select(m => m!.GetValue<string>()).Should().Equal("[links]");

        var none = await TestAsync("فقط happen spoonful");
        none["level"]!.GetValue<string>().Should().Be("none");
        none["matches"]!.AsArray().Should().BeEmpty();

        await admin.Client.PostAsJsonAsync("/api/v1/admin/content-filter/test", new { text = new string('a', 5001) }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
    }

    // ── Spam limits ─────────────────────────────────────────────

    [Fact]
    public async Task Five_new_articles_a_day_and_updates_dont_count()
    {
        var writer = await api.UserAsync("Busy Writer");
        var first = default(Guid);
        for (var i = 0; i < 5; i++)
        {
            var (id, _) = await writer.Client.PublishAsync();
            if (i == 0) first = id;
        }

        var sixth = await writer.Client.CreateDraftAsync(ArticleTestKit.Document(await writer.Client.FieldIdAsync("dotnet"), "One too many today"));
        var problem = await writer.Client.PublishDraftAsync(sixth["id"]!.GetValue<Guid>(), sixth["version"]!.GetValue<int>())
            .ProblemAsync(HttpStatusCode.TooManyRequests, "content.too_many");
        problem["limit"]!.GetValue<string>().Should().Be("articles_per_day");

        // An Update of a published article is not a new one.
        var edit = await writer.Client.EditAsync(first);
        var document = edit["document"]!.AsObject();
        document["translations"]![0]!["subtitle"] = "Updated today";
        (await writer.Client.SaveDraftAsync(first, edit["version"]!.GetValue<int>(), document)).EnsureSuccessStatusCode();
        (await writer.Client.PublishCurrentAsync(first)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Sixty_comments_and_replies_an_hour()
    {
        var writer = await api.UserAsync("Filter Writer");
        var chatty = await api.UserAsync("Chatty Reader");
        var (articleId, _) = await writer.Client.PublishAsync();
        var parent = await CreatedIdAsync(CommentAsync(writer, articleId, "Questions welcome."));
        var (elsewhere, _) = await writer.Client.PublishAsync(); // the hour's comments, away from the per-article limit

        // 59 in the last hour (straight in the database: the rate limit allows 10 a minute) and older ones that don't count.
        await api.InDbAsync(async db =>
        {
            db.Comments.AddRange(Enumerable.Range(0, 59).Select(i => Comment.Post(elsewhere, chatty.Id, $"تعليق {i}", [], DateTime.UtcNow.AddMinutes(-50))));
            db.Comments.AddRange(Enumerable.Range(0, 20).Select(i => Comment.Post(elsewhere, chatty.Id, $"قديم {i}", [], DateTime.UtcNow.AddHours(-2))));
            foreach (var entry in db.ChangeTracker.Entries<Domain.Common.AggregateRoot>()) entry.Entity.ClearDomainEvents();
            await db.SaveChangesAsync(Ct);
            // Saving stamps the time: date the old ones back afterwards.
            await db.Comments.Where(c => c.AuthorId == chatty.Id && c.Body.StartsWith("قديم"))
                .ExecuteUpdateAsync(s => s.SetProperty(c => c.CreatedAt, DateTime.UtcNow.AddHours(-2)), Ct);
        });

        try
        {
            await CreatedIdAsync(ReplyAsync(chatty, parent, "The sixtieth."));
            var comment = await CommentAsync(chatty, articleId, "The sixty-first.").ProblemAsync(HttpStatusCode.TooManyRequests, "content.too_many");
            comment["limit"]!.GetValue<string>().Should().Be("comments_per_hour");
            (await ReplyAsync(chatty, parent, "A reply counts too.").ProblemAsync(HttpStatusCode.TooManyRequests, "content.too_many"))["limit"]!
                .GetValue<string>().Should().Be("comments_per_hour");
            // Editing isn't a new comment.
            var own = await api.InDbAsync(db => db.Comments.Where(c => c.AuthorId == chatty.Id && c.ParentId == null).Select(c => c.Id).FirstAsync(Ct));
            (await chatty.Client.PatchAsJsonAsync($"/api/v1/comments/{own}", new { body = "Edited." }, Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        }
        finally
        {
            // The suite shares one database: 79 visible comments this week would lead Explore's trending ranking for every later
            // test. Deleted comments don't count there (their notifications keep their rows, so they are soft-deleted).
            await api.InDbAsync(db => db.Comments.IgnoreQueryFilters().Where(c => c.AuthorId == chatty.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(c => c.IsDeleted, true).SetProperty(c => c.DeletedAt, DateTime.UtcNow), CancellationToken.None));
        }
    }

    // ── F36 blocks on comment, reply and repost writes ─────────

    [Fact]
    public async Task The_blocked_person_cant_comment_reply_or_repost_on_the_blocker_and_the_blocker_is_told_why()
    {
        var a = await api.UserAsync("Guard Blocker");
        var b = await api.UserAsync("Guard Blocked");
        var c = await api.UserAsync("Guard Third");
        var (aArticle, _) = await a.Client.PublishAsync();
        var (bArticle, _) = await b.Client.PublishAsync();
        var (cArticle, _) = await c.Client.PublishAsync();
        var aComment = await CreatedIdAsync(CommentAsync(a, cArticle, "A on C's article"));
        var bComment = await CreatedIdAsync(CommentAsync(b, cArticle, "B on C's article"));
        (await a.Client.PutAsync($"/api/v1/users/{b.Id}/block", null, Ct)).EnsureSuccessStatusCode();

        // The blocked person: as if the content were gone.
        await CommentAsync(b, aArticle, "hello").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await ReplyAsync(b, aComment, "hello").ProblemAsync(HttpStatusCode.NotFound, "comment.not_found");
        await b.Client.PutAsJsonAsync($"/api/v1/articles/{aArticle}/repost", new { caption = "look" }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        // The blocker: told to unblock first.
        await CommentAsync(a, bArticle, "hello").ProblemAsync(HttpStatusCode.Forbidden, "block.blocked");
        await ReplyAsync(a, bComment, "hello").ProblemAsync(HttpStatusCode.Forbidden, "block.blocked");
        await a.Client.PutAsJsonAsync($"/api/v1/articles/{bArticle}/repost", new { caption = "look" }, Ct)
            .ProblemAsync(HttpStatusCode.Forbidden, "block.blocked");

        // Others are untouched.
        await CreatedIdAsync(ReplyAsync(c, aComment, "C answers A"));
        await CreatedIdAsync(ReplyAsync(c, bComment, "C answers B"));
    }
}
