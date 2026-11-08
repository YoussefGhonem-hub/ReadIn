using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Features.Moderation;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F22 store requirements (App Review, Guideline 1.2): reposts are reportable and moderators can remove them, "report and
/// block", what the reporter reported is flagged for them (reportedByMe), each case's age and urgency against the 24-hour
/// target, the dashboard's open-past-24h count, system reports from the content filter, report_new to staff (one push per
/// target per hour) and report_resolved to the reporter.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ReportAdditionsTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static Task<HttpResponseMessage> ReportAsync(HttpClient client, object body) => client.PostAsJsonAsync("/api/v1/reports", body, Ct);

    private static Task<HttpResponseMessage> ActAsync(HttpClient client, object body) => client.PostAsJsonAsync("/api/v1/moderation/actions", body, Ct);

    private static async Task<List<JsonObject>> NotificationsAsync(HttpClient client, string type) =>
        [.. (await client.GetAsync("/api/v1/me/notifications?limit=50", Ct).OkJsonAsync())["items"]!.AsArray()
            .Select(n => n!.AsObject()).Where(n => n["type"]!.GetValue<string>() == type)];

    private async Task<Guid> RepostAsync(SignedInUser reposter, Guid articleId, string caption)
    {
        (await reposter.Client.PutAsJsonAsync($"/api/v1/articles/{articleId}/repost", new { caption }, Ct)).EnsureSuccessStatusCode();
        return await api.InDbAsync(db => db.Reposts.Where(r => r.UserId == reposter.Id && r.ArticleId == articleId).Select(r => r.Id).SingleAsync(Ct));
    }

    private static async Task<Guid> CommentAsync(HttpClient client, Guid articleId, string body)
    {
        var response = await client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body }, Ct);
        var text = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, text);
        return JsonNode.Parse(text)!["id"]!.GetValue<Guid>();
    }

    // ---- Reposts as a report target ----

    [Fact]
    public async Task A_repost_can_be_reported_and_a_moderator_removes_it()
    {
        var admin = await api.SuperAdminAsync();
        var author = await api.UserAsync("Repost Author");
        var reposter = await api.UserAsync("Reposter");
        var reader = await api.UserAsync("Repost Reporter");
        var (articleId, _) = await author.Client.PublishAsync();
        var repostId = await RepostAsync(reposter, articleId, "Look at this nonsense caption");

        await ReportAsync(reposter.Client, new { targetType = "repost", targetId = repostId, reason = "spam" })
            .ProblemAsync(HttpStatusCode.BadRequest, "report.own_content");
        await ReportAsync(reader.Client, new { targetType = "repost", targetId = Guid.NewGuid(), reason = "spam" })
            .ProblemAsync(HttpStatusCode.NotFound, "report.target_not_found");
        await ReportAsync(reader.Client, new { targetType = "repost", targetId = repostId, reason = "harassment" }).NoContentAsync();

        var queue = await admin.Client.GetAsync("/api/v1/moderation/reports?type=repost&limit=50", Ct).OkJsonAsync();
        var item = queue["items"]!.AsArray().Single(i => i!["targetId"]!.GetValue<Guid>() == repostId)!;
        item["targetType"]!.GetValue<string>().Should().Be("repost");
        item["target"]!["author"]!["id"]!.GetValue<Guid>().Should().Be(reposter.Id);
        item["target"]!["body"]!.GetValue<string>().Should().Be("Look at this nonsense caption");
        item["target"]!["articleId"]!.GetValue<Guid>().Should().Be(articleId);
        item["target"]!["state"]!.GetValue<string>().Should().Be("visible");
        (await admin.Client.GetAsync($"/api/v1/moderation/reports/repost/{repostId}", Ct).OkJsonAsync())["reports"]!.AsArray().Should().HaveCount(1);
        (await admin.Client.GetAsync("/api/v1/moderation/summary", Ct).OkJsonAsync())["open"]!["repost"]!.GetValue<int>().Should().BeGreaterThan(0);

        await ActAsync(admin.Client, new { action = "hide", targetType = "repost", targetId = repostId })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.action_invalid");
        await ActAsync(admin.Client, new { action = "delete", targetType = "repost", targetId = repostId }).NoContentAsync();

        (await api.InDbAsync(db => db.Reposts.AnyAsync(r => r.Id == repostId, Ct))).Should().BeFalse();
        (await api.InDbAsync(db => db.Reports.Where(r => r.TargetId == repostId).Select(r => r.Status).SingleAsync(Ct))).Should().Be(ReportStatus.Resolved);
        (await api.InDbAsync(db => db.ModerationActions.CountAsync(
            m => m.TargetId == repostId && m.Action == ModerationActionTypes.RepostDelete && m.TargetUserId == reposter.Id, Ct))).Should().Be(1);
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.RepostDeleted && a.UserId == reposter.Id, Ct))).Should().Be(1);
        (await admin.Client.GetAsync($"/api/v1/moderation/reports/repost/{repostId}", Ct).OkJsonAsync())["item"]!["target"]!["state"]!
            .GetValue<string>().Should().Be("deleted");

        await ActAsync(admin.Client, new { action = "delete", targetType = "repost", targetId = repostId })
            .ProblemAsync(HttpStatusCode.NotFound, "repost.not_found");
        // A repost that is gone can still have its leftover reports dismissed.
        await ActAsync(admin.Client, new { action = "dismiss", targetType = "repost", targetId = repostId }).NoContentAsync();
    }

    // ---- Report and block ----

    [Fact]
    public async Task Report_and_block_blocks_the_author_in_the_same_step()
    {
        var author = await api.UserAsync("Blocked By Report");
        var reader = await api.UserAsync("Reporting Blocker");
        var (articleId, _) = await author.Client.PublishAsync();

        await ReportAsync(reader.Client, new { targetType = "article", targetId = articleId, reason = "spam", alsoBlock = true }).NoContentAsync();

        (await api.InDbAsync(db => db.UserBlocks.AnyAsync(b => b.BlockerId == reader.Id && b.BlockedId == author.Id, Ct))).Should().BeTrue();
        (await api.InDbAsync(db => db.Reports.CountAsync(r => r.ReporterId == reader.Id && r.TargetId == articleId, Ct))).Should().Be(1);

        // Without it, only the report.
        var other = await api.UserAsync("Report Only");
        await ReportAsync(other.Client, new { targetType = "user", targetId = author.Id, reason = "harassment" }).NoContentAsync();
        (await api.InDbAsync(db => db.UserBlocks.AnyAsync(b => b.BlockerId == other.Id, Ct))).Should().BeFalse();

        // A user report with alsoBlock blocks that user; reporting again (a no-op) still blocks.
        var again = await api.UserAsync("Second Thoughts");
        await ReportAsync(again.Client, new { targetType = "user", targetId = author.Id, reason = "spam" }).NoContentAsync();
        await ReportAsync(again.Client, new { targetType = "user", targetId = author.Id, reason = "spam", alsoBlock = true }).NoContentAsync();
        (await api.InDbAsync(db => db.UserBlocks.AnyAsync(b => b.BlockerId == again.Id && b.BlockedId == author.Id, Ct))).Should().BeTrue();
    }

    // ---- Hidden for the reporter ----

    [Fact]
    public async Task What_you_reported_is_flagged_for_you_only()
    {
        var author = await api.UserAsync("Flagged Author");
        var reader = await api.UserAsync("Flag Reporter");
        var bystander = await api.UserAsync("Bystander");
        var (articleId, slug) = await author.Client.PublishAsync();
        var commentId = await CommentAsync(author.Client, articleId, "A comment someone will report.");

        await ReportAsync(reader.Client, new { targetType = "article", targetId = articleId, reason = "misinformation" }).NoContentAsync();
        await ReportAsync(reader.Client, new { targetType = "comment", targetId = commentId, reason = "harassment" }).NoContentAsync();

        (await reader.Client.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["reportedByMe"]!.GetValue<bool>().Should().BeTrue();
        (await bystander.Client.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["reportedByMe"]!.GetValue<bool>().Should().BeFalse();
        (await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync())["reportedByMe"]!.GetValue<bool>().Should().BeFalse();

        var card = await reader.Client.FindInForYouAsync(articleId);
        card["reportedByMe"]!.GetValue<bool>().Should().BeTrue("the card stays in the feed, and the reporter's client collapses it");

        JsonNode Comment(JsonObject page) => page["items"]!.AsArray().Single(c => c!["id"]!.GetValue<Guid>() == commentId)!;
        Comment(await reader.Client.GetAsync($"/api/v1/articles/{articleId}/comments?sort=new", Ct).OkJsonAsync())["reportedByMe"]!
            .GetValue<bool>().Should().BeTrue();
        Comment(await bystander.Client.GetAsync($"/api/v1/articles/{articleId}/comments?sort=new", Ct).OkJsonAsync())["reportedByMe"]!
            .GetValue<bool>().Should().BeFalse();
    }

    // ---- The 24-hour target ----

    [Fact]
    public async Task Cases_show_their_age_turn_urgent_after_12_hours_and_count_on_the_dashboard_after_24()
    {
        var admin = await api.SuperAdminAsync();
        var author = await api.UserAsync("Aging Author");
        var reader = await api.UserAsync("Aging Reporter");
        var (fresh, _) = await author.Client.PublishAsync();
        var (old, _) = await author.Client.PublishAsync();
        var (overdue, _) = await author.Client.PublishAsync();
        foreach (var id in new[] { fresh, old, overdue })
            await ReportAsync(reader.Client, new { targetType = "article", targetId = id, reason = "spam" }).NoContentAsync();

        var before = (await admin.Client.GetAsync("/api/v1/admin/summary", Ct).OkJsonAsync())["openReportsOver24h"]!.GetValue<int>();
        await api.InDbAsync(db => db.Reports.Where(r => r.TargetId == old).ExecuteUpdateAsync(s => s.SetProperty(r => r.CreatedAt, DateTime.UtcNow.AddHours(-13)), Ct));
        await api.InDbAsync(db => db.Reports.Where(r => r.TargetId == overdue).ExecuteUpdateAsync(s => s.SetProperty(r => r.CreatedAt, DateTime.UtcNow.AddHours(-25)), Ct));

        var items = (await admin.Client.GetAsync("/api/v1/moderation/reports?type=article&limit=50", Ct).OkJsonAsync())["items"]!.AsArray();
        JsonNode Item(Guid id) => items.Single(i => i!["targetId"]!.GetValue<Guid>() == id)!;
        (Item(fresh)["ageHours"]!.GetValue<int>(), Item(fresh)["urgent"]!.GetValue<bool>()).Should().Be((0, false));
        (Item(old)["ageHours"]!.GetValue<int>(), Item(old)["urgent"]!.GetValue<bool>()).Should().Be((13, true));
        Item(overdue)["ageHours"]!.GetValue<int>().Should().Be(25);
        (await admin.Client.GetAsync($"/api/v1/moderation/reports/article/{old}", Ct).OkJsonAsync())["item"]!["urgent"]!.GetValue<bool>().Should().BeTrue();

        (await admin.Client.GetAsync("/api/v1/admin/summary", Ct).OkJsonAsync())["openReportsOver24h"]!.GetValue<int>().Should().Be(before + 1);
        (await admin.Client.GetAsync("/api/v1/admin/dashboard?period=today", Ct).OkJsonAsync())["cards"]!["openReportsOver24h"]!.GetValue<int>()
            .Should().Be(before + 1);

        // A closed case has no age.
        await ActAsync(admin.Client, new { action = "dismiss", targetType = "article", targetId = overdue }).NoContentAsync();
        var dismissed = (await admin.Client.GetAsync("/api/v1/moderation/reports?status=dismissed&type=article&limit=50", Ct).OkJsonAsync())["items"]!
            .AsArray().Single(i => i!["targetId"]!.GetValue<Guid>() == overdue)!;
        dismissed["ageHours"].Should().BeNull();
        dismissed["urgent"]!.GetValue<bool>().Should().BeFalse();
        (await admin.Client.GetAsync("/api/v1/admin/summary", Ct).OkJsonAsync())["openReportsOver24h"]!.GetValue<int>().Should().Be(before);

        // Without moderation.manage there is no count.
        var other = await api.UserWithPermissionsAsync("Console Only", Application.Common.Security.Permissions.Admin.Access);
        (await other.Client.GetAsync("/api/v1/admin/summary", Ct).OkJsonAsync())["openReportsOver24h"].Should().BeNull();
    }

    // ---- report_new ----

    [Fact]
    public async Task Staff_hear_about_a_new_report_once_per_target_and_at_most_one_push_an_hour()
    {
        var admin = await api.SuperAdminAsync();
        var author = await api.UserAsync("Reported Writer");
        var first = await api.UserAsync("First Reporter");
        var second = await api.UserAsync("Second Reporter");
        var (articleId, _) = await author.Client.PublishAsync("A title to report");

        await ReportAsync(first.Client, new { targetType = "article", targetId = articleId, reason = "spam" }).NoContentAsync();
        var entry = (await NotificationsAsync(admin.Client, "report_new")).Single(n => n["data"]!["targetId"]!.GetValue<Guid>() == articleId);
        entry["data"]!["targetType"]!.GetValue<string>().Should().Be("article");
        entry["data"]!["targetLabel"]!.GetValue<string>().Should().Be("A title to report");
        entry["data"]!["reportCount"]!.GetValue<int>().Should().Be(1);
        entry["data"]!["system"].Should().BeNull();
        entry["actor"].Should().BeNull("reporters stay anonymous in the notification");
        entry["link"]!.GetValue<string>().Should().Be($"readin://admin/reports/article/{articleId}");
        // Members never get it, the reporter neither.
        (await NotificationsAsync(first.Client, "report_new")).Should().BeEmpty();

        // The entry was just pushed: the next report on the target waits until an hour after that push.
        var entryId = entry["id"]!.GetValue<Guid>();
        var pushedAt = DateTime.UtcNow.AddMinutes(-10);
        await api.InDbAsync(db => db.Notifications.Where(n => n.Id == entryId).ExecuteUpdateAsync(s => s
            .SetProperty(n => n.PushedAt, pushedAt)
            .SetProperty(n => n.PushStatus, NotificationPushStatus.Sent), Ct));
        await ReportAsync(second.Client, new { targetType = "article", targetId = articleId, reason = "misinformation" }).NoContentAsync();

        var joined = (await NotificationsAsync(admin.Client, "report_new")).Where(n => n["data"]!["targetId"]!.GetValue<Guid>() == articleId).ToList();
        joined.Should().ContainSingle("one entry per target");
        joined[0]["data"]!["reportCount"]!.GetValue<int>().Should().Be(2);
        var push = await api.InDbAsync(db => db.Notifications.AsNoTracking().Where(n => n.Id == entryId)
            .Select(n => new { n.PushStatus, n.PushAfter }).SingleAsync(Ct));
        push.PushStatus.Should().Be(NotificationPushStatus.Pending);
        push.PushAfter!.Value.Should().BeCloseTo(pushedAt.AddHours(1), TimeSpan.FromSeconds(1));
    }

    [Fact]
    public async Task Report_new_is_a_setting_for_moderators_only_and_turning_it_off_writes_nothing()
    {
        var admin = await api.SuperAdminAsync();
        var member = await api.UserAsync("Settings Member");
        (await member.Client.GetAsync("/api/v1/me/notification-settings", Ct).OkJsonAsync())["types"]!.AsObject().Select(t => t.Key)
            .Should().NotContain("report_new").And.NotContain("report_resolved");
        (await member.Client.PutAsJsonAsync("/api/v1/me/notification-settings", new { types = new Dictionary<string, string> { ["report_new"] = "off" } }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await admin.Client.PutAsJsonAsync("/api/v1/me/notification-settings", new { types = new Dictionary<string, string> { ["report_resolved"] = "off" } }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.BadRequest);

        (await admin.Client.GetAsync("/api/v1/me/notification-settings", Ct).OkJsonAsync())["types"]!["report_new"]!.GetValue<string>().Should().Be("all");
        (await admin.Client.PutAsJsonAsync("/api/v1/me/notification-settings", new { types = new Dictionary<string, string> { ["report_new"] = "off" } }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        var author = await api.UserAsync("Quiet Author");
        var (articleId, _) = await author.Client.PublishAsync();
        await ReportAsync(member.Client, new { targetType = "article", targetId = articleId, reason = "spam" }).NoContentAsync();
        (await NotificationsAsync(admin.Client, "report_new")).Where(n => n["data"]!["targetId"]!.GetValue<Guid>() == articleId).Should().BeEmpty();
    }

    // ---- report_resolved ----

    [Fact]
    public async Task The_reporter_learns_the_outcome_in_app_without_who_acted_or_what_was_done()
    {
        var admin = await api.SuperAdminAsync();
        var author = await api.UserAsync("Outcome Author");
        var reader = await api.UserAsync("Outcome Reporter");
        var (removed, _) = await author.Client.PublishAsync("The removed one");
        var (kept, _) = await author.Client.PublishAsync("The kept one");
        foreach (var id in new[] { removed, kept })
            await ReportAsync(reader.Client, new { targetType = "article", targetId = id, reason = "spam" }).NoContentAsync();
        await ReportAsync(reader.Client, new { targetType = "user", targetId = author.Id, reason = "harassment" }).NoContentAsync();

        await ActAsync(admin.Client, new { action = "hide", targetType = "article", targetId = removed }).NoContentAsync();
        await ActAsync(admin.Client, new { action = "dismiss", targetType = "article", targetId = kept }).NoContentAsync();
        await ActAsync(admin.Client, new { action = "warn", targetType = "user", targetId = author.Id, note = "Be kind." }).NoContentAsync();

        var outcomes = await NotificationsAsync(reader.Client, "report_resolved");
        outcomes.Should().HaveCount(3);
        JsonNode Of(string label) => outcomes.Single(n => n["data"]!["targetLabel"]?.GetValue<string>() == label)["data"]!;
        (Of("The removed one")["outcome"]!.GetValue<string>(), Of("The removed one")["targetType"]!.GetValue<string>()).Should().Be(("actioned", "article"));
        Of("The kept one")["outcome"]!.GetValue<string>().Should().Be("no_violation");
        var username = author.Me["username"]!.GetValue<string>();
        (Of($"@{username}")["outcome"]!.GetValue<string>(), Of($"@{username}")["targetType"]!.GetValue<string>()).Should().Be(("actioned", "user"));
        foreach (var outcome in outcomes)
        {
            outcome["actor"].Should().BeNull();
            outcome["article"].Should().BeNull("it stays when the content is gone, and never points at it");
            outcome["link"]!.GetValue<string>().Should().Be("readin://notifications");
        }
        (await api.InDbAsync(db => db.Notifications.Where(n => n.UserId == reader.Id && n.Type == NotificationTypes.ReportResolved)
            .Select(n => n.PushStatus).Distinct().ToListAsync(Ct))).Should().Equal(NotificationPushStatus.None);
    }

    // ---- System reports (the content filter, F37) ----

    [Fact]
    public async Task A_system_report_shows_as_the_content_filter_with_its_terms_and_reopens_on_a_new_flag()
    {
        var admin = await api.SuperAdminAsync();
        var author = await api.UserAsync("Filtered Writer");
        var (articleId, _) = await author.Client.PublishAsync();
        var commentId = await CommentAsync(author.Client, articleId, "A comment the filter flags.");

        await FlagAsync(ReportTargetType.Comment, commentId, ["placeholder-one", "placeholder-two"]);

        var @case = await admin.Client.GetAsync($"/api/v1/moderation/reports/comment/{commentId}", Ct).OkJsonAsync();
        var report = @case["reports"]!.AsArray().Single()!;
        report["isSystem"]!.GetValue<bool>().Should().BeTrue();
        report["reporter"].Should().BeNull("the reporter is the content filter");
        report["matchedTerms"]!.AsArray().Select(t => t!.GetValue<string>()).Should().Equal("placeholder-one", "placeholder-two");
        var entry = (await NotificationsAsync(admin.Client, "report_new")).Single(n => n["data"]!["targetId"]!.GetValue<Guid>() == commentId);
        entry["data"]!["system"]!.GetValue<bool>().Should().BeTrue();

        // Dismissed, then flagged again: the one system report is open again, with the new terms.
        await ActAsync(admin.Client, new { action = "dismiss", targetType = "comment", targetId = commentId }).NoContentAsync();
        await FlagAsync(ReportTargetType.Comment, commentId, ["placeholder-three"]);
        var reports = await api.InDbAsync(db => db.Reports.AsNoTracking().Where(r => r.TargetId == commentId).ToListAsync(Ct));
        reports.Should().ContainSingle();
        (reports[0].Status, reports[0].IsSystem).Should().Be((ReportStatus.Open, true));
        reports[0].MatchedTermList.Should().Equal("placeholder-three");

        // A human report on the same target is a report of its own.
        var reader = await api.UserAsync("Human Reporter");
        await ReportAsync(reader.Client, new { targetType = "comment", targetId = commentId, reason = "harassment" }).NoContentAsync();
        (await api.InDbAsync(db => db.Reports.CountAsync(r => r.TargetId == commentId, Ct))).Should().Be(2);
    }

    private Task FlagAsync(ReportTargetType type, Guid targetId, string[] terms) =>
        api.InScopeAsync(async services =>
        {
            await services.GetRequiredService<SystemReports>().FlagAsync(type, targetId, terms, DateTime.UtcNow, Ct);
            await services.GetRequiredService<Application.Common.Interfaces.IAppDbContext>().SaveChangesAsync(Ct);
        });
}
