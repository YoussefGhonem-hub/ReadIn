using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The admin console's account actions on top of F22 (SPEC F23): suspend and hide everything, hide_content and its undo,
/// the protected accounts (holders of admin.access too), and suspended profiles for holders of users.read.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AdminModerationTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Suspending_with_hideContent_hides_everything_and_unhide_content_brings_back_only_that()
    {
        var admin = await api.SuperAdminAsync();
        var spammer = await api.UserAsync("Spam Account");
        var other = await api.UserAsync("Other Writer");
        var host = await other.Client.PublishAsync("A host article for spam comments");
        var first = await spammer.Client.PublishAsync("Spam article one");
        var second = await spammer.Client.PublishAsync("Spam article two");
        var hiddenBefore = await spammer.Client.PublishAsync("Hidden one by one before");
        var comment = await CommentAsync(spammer, $"/api/v1/articles/{host.Id}/comments", "Buy now!");
        var topByOther = await CommentAsync(other, $"/api/v1/articles/{host.Id}/comments", "A real comment");
        var reply = await CommentAsync(spammer, $"/api/v1/comments/{topByOther}/replies", "Buy now, in a reply");
        await ActAsync(admin.Client, new { action = "hide", targetType = "article", targetId = hiddenBefore.Id }).NoContentAsync();
        var reporter = await api.UserAsync();
        (await reporter.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "article", targetId = first.Id, reason = "spam" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        await ActAsync(admin.Client, new
        {
            action = "suspend", targetType = "user", targetId = spammer.Id, note = "Spam account", durationDays = 30, hideContent = true,
        }).NoContentAsync();

        foreach (var slug in new[] { first.Slug, second.Slug, hiddenBefore.Slug })
            await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        var flags = await api.InDbAsync(db => db.Articles.Where(a => a.AuthorId == spammer.Id)
            .Select(a => new { a.Id, a.HiddenAt, a.HiddenWithAccount }).ToListAsync(Ct));
        flags.Should().OnlyContain(a => a.HiddenAt != null);
        flags.Where(a => a.HiddenWithAccount).Select(a => a.Id).Should().BeEquivalentTo([first.Id, second.Id]);
        var comments = await api.InDbAsync(db => db.Comments.Where(c => c.AuthorId == spammer.Id)
            .Select(c => new { c.Id, c.HiddenAt, c.HiddenWithAccount }).ToListAsync(Ct));
        comments.Should().HaveCount(2).And.OnlyContain(c => c.HiddenAt != null && c.HiddenWithAccount);
        (await api.InDbAsync(db => db.Comments.Where(c => c.Id == topByOther).Select(c => c.ReplyCount).SingleAsync(Ct)))
            .Should().Be(0, "the hidden reply no longer counts");
        (await api.InDbAsync(db => db.Reports.Where(r => r.TargetId == first.Id).Select(r => r.Status).SingleAsync(Ct)))
            .Should().Be(ReportStatus.Resolved);

        var log = await LogAsync(spammer.Id);
        log.Should().Contain([ModerationActionTypes.UserSuspend, ModerationActionTypes.UserHideContent]);
        (await api.InDbAsync(db => db.ModerationActions.Where(m => m.TargetUserId == spammer.Id && m.Action == ModerationActionTypes.UserHideContent)
            .Select(m => m.ReportsClosed).SingleAsync(Ct))).Should().Be(1);
        var audit = await api.InDbAsync(db => db.AuditLogs.Where(l => l.Action == AuditActions.ContentHidden && l.UserId == spammer.Id)
            .Select(l => new { l.ActorId, l.Details, l.TargetType }).SingleAsync(Ct));
        audit.Should().BeEquivalentTo(new { ActorId = (Guid?)admin.Id, Details = "articles=2 comments=2", TargetType = "user" });

        // The undo brings back only what hide_content hid: the article hidden one by one stays hidden.
        await ActAsync(admin.Client, new { action = "unhide_content", targetType = "user", targetId = spammer.Id }).NoContentAsync();
        var after = await api.InDbAsync(db => db.Articles.Where(a => a.AuthorId == spammer.Id)
            .Select(a => new { a.Id, Hidden = a.HiddenAt != null, a.HiddenWithAccount }).ToListAsync(Ct));
        after.Single(a => a.Id == hiddenBefore.Id).Hidden.Should().BeTrue();
        after.Where(a => a.Id != hiddenBefore.Id).Should().OnlyContain(a => !a.Hidden && !a.HiddenWithAccount);
        (await api.InDbAsync(db => db.Comments.CountAsync(c => c.AuthorId == spammer.Id && c.HiddenAt == null, Ct))).Should().Be(2);
        (await api.InDbAsync(db => db.Comments.Where(c => c.Id == topByOther).Select(c => c.ReplyCount).SingleAsync(Ct))).Should().Be(1);
        await ActAsync(admin.Client, new { action = "unsuspend", targetType = "user", targetId = spammer.Id }).NoContentAsync();
        (await api.GuestClient().GetAsync($"/api/v1/articles/{first.Slug}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == AuditActions.ContentRestored && l.UserId == spammer.Id, Ct)))
            .Should().Be(1);

        // Nothing left to restore: nothing logged.
        var logged = (await LogAsync(spammer.Id)).Count;
        await ActAsync(admin.Client, new { action = "unhide_content", targetType = "user", targetId = spammer.Id }).NoContentAsync();
        (await LogAsync(spammer.Id)).Should().HaveCount(logged);
        (await LogAsync(spammer.Id)).Count(a => a == ModerationActionTypes.UserUnhideContent).Should().Be(1);
        _ = comment;
        _ = reply;
    }

    [Fact]
    public async Task Hide_content_has_the_rules_of_suspend_and_its_undo_has_none()
    {
        var admin = await api.SuperAdminAsync();
        var otherAdmin = await api.SuperAdminAsync("Another SuperAdmin");
        var consoleOnly = await api.UserWithPermissionsAsync("Console Viewer", Permissions.Admin.Access);
        var quiet = await api.UserAsync("Nothing To Hide");

        await ActAsync(admin.Client, new { action = "warn", targetType = "user", targetId = quiet.Id, note = "Careful", hideContent = true })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.action_invalid");
        await ActAsync(admin.Client, new { action = "hide_content", targetType = "article", targetId = quiet.Id })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.action_invalid");
        await ActAsync(admin.Client, new { action = "hide_content", targetType = "user", targetId = admin.Id })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.self");
        await ActAsync(admin.Client, new { action = "hide_content", targetType = "user", targetId = otherAdmin.Id })
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");
        await ActAsync(admin.Client, new { action = "hide_content", targetType = "user", targetId = SystemUsers.EditorialId })
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");

        // F23: a holder of admin.access is staff even without moderation.manage.
        await ActAsync(admin.Client, new { action = "warn", targetType = "user", targetId = consoleOnly.Id, note = "Careful" })
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");
        await ActAsync(admin.Client, new { action = "suspend", targetType = "user", targetId = consoleOnly.Id, note = "No" })
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");

        // Nothing to hide, nothing logged; the undo is allowed on anyone.
        await ActAsync(admin.Client, new { action = "hide_content", targetType = "user", targetId = quiet.Id }).NoContentAsync();
        await ActAsync(admin.Client, new { action = "unhide_content", targetType = "user", targetId = otherAdmin.Id }).NoContentAsync();
        (await LogAsync(quiet.Id)).Should().BeEmpty();

        // moderation.manage alone may hide content (it isn't a suspension), but not suspend.
        var moderator = await api.UserWithPermissionsAsync("Content Only Moderator", Permissions.Moderation.Manage);
        var writer = await api.UserAsync("Hidden By Moderator");
        await writer.Client.PublishAsync("One article");
        await ActAsync(moderator.Client, new { action = "hide_content", targetType = "user", targetId = writer.Id }).NoContentAsync();
        (await LogAsync(writer.Id)).Should().Equal(ModerationActionTypes.UserHideContent);
        await ActAsync(moderator.Client, new { action = "suspend", targetType = "user", targetId = writer.Id, note = "Spam", hideContent = true })
            .ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
    }

    [Fact]
    public async Task Holders_of_users_read_see_suspended_profiles_with_their_state()
    {
        var admin = await api.SuperAdminAsync();
        var member = await api.UserAsync("Profile Viewer");
        var target = await api.UserAsync("Soon Suspended");
        var username = target.Me["username"]!.GetValue<string>();
        await target.Client.PublishAsync("Before the suspension");

        var active = await admin.Client.GetAsync($"/api/v1/users/{username}", Ct).OkJsonAsync();
        active["admin"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("isSuspended", "suspendedUntil", "isStaff");
        (active["admin"]!["isSuspended"]!.GetValue<bool>(), active["admin"]!["isStaff"]!.GetValue<bool>()).Should().Be((false, false));
        (await member.Client.GetAsync($"/api/v1/users/{username}", Ct).OkJsonAsync())["admin"].Should().BeNull();
        (await api.GuestClient().GetAsync($"/api/v1/users/{username}", Ct).OkJsonAsync())["admin"].Should().BeNull();

        await ActAsync(admin.Client, new { action = "suspend", targetType = "user", targetId = target.Id, note = "Abuse", durationDays = 7 })
            .NoContentAsync();
        await api.GuestClient().GetAsync($"/api/v1/users/{username}", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        await member.Client.GetAsync($"/api/v1/users/{username}", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        await member.Client.GetAsync($"/api/v1/users/{username}/articles", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");

        var suspended = await admin.Client.GetAsync($"/api/v1/users/{username}", Ct).OkJsonAsync();
        suspended["admin"]!["isSuspended"]!.GetValue<bool>().Should().BeTrue();
        suspended["admin"]!["suspendedUntil"]!.GetValue<DateTime>().Should().BeCloseTo(DateTime.UtcNow.AddDays(7), TimeSpan.FromMinutes(5));
        (await admin.Client.GetAsync($"/api/v1/users/{username}/articles", Ct).OkJsonAsync())["items"]!.AsArray().Should().HaveCount(1);
        (await admin.Client.GetAsync($"/api/v1/users/{username}/reposts", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        await admin.Client.GetAsync($"/api/v1/users/{username}/stats", Ct).ProblemAsync(HttpStatusCode.Forbidden, "profile.stats_private");

        // Staff: another SuperAdmin, and the official account.
        var other = await api.SuperAdminAsync("Staff Profile");
        (await admin.Client.GetAsync($"/api/v1/users/{other.Me["username"]}", Ct).OkJsonAsync())["admin"]!["isStaff"]!.GetValue<bool>()
            .Should().BeTrue();
        (await admin.Client.GetAsync("/api/v1/users/readin", Ct).OkJsonAsync())["admin"]!["isStaff"]!.GetValue<bool>().Should().BeTrue();
    }

    private static Task<HttpResponseMessage> ActAsync(HttpClient client, object body) =>
        client.PostAsJsonAsync("/api/v1/moderation/actions", body, Ct);

    private Task<List<string>> LogAsync(Guid userId) =>
        api.InDbAsync(db => db.ModerationActions.Where(m => m.TargetUserId == userId).OrderBy(m => m.CreatedAt).Select(m => m.Action).ToListAsync(Ct));

    private static async Task<Guid> CommentAsync(SignedInUser user, string url, string body)
    {
        var response = await user.Client.PostAsJsonAsync(url, new { body }, Ct);
        var text = await response.Content.ReadAsStringAsync(Ct);
        response.IsSuccessStatusCode.Should().BeTrue(text);
        return JsonNode.Parse(text)!["id"]!.GetValue<Guid>();
    }
}
