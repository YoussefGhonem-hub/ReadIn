using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Feed.DailyArticle;
using ReadIn.Application.Features.Moderation;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Authorization;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Reading;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F22 Reporting &amp; Moderation against SQL Server: reports on articles, comments and users, hidden articles, every
/// moderator action and its rules, notices and their push, suspension, the queue, a case and the log.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class ModerationTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    // ---- Reports ----

    [Fact]
    public async Task Readers_report_articles_comments_and_users_once_and_never_their_own()
    {
        var author = await api.UserAsync("Reported Author");
        var (articleId, _) = await author.Client.PublishAsync();
        var commenter = await api.UserAsync();
        var commentId = await CommentAsync(commenter, articleId, "Buy followers here!!!");
        var reporter = await api.UserAsync();

        await ReportAsync(reporter.Client, "article", articleId, "misinformation", "الأرقام غلط");
        await ReportAsync(reporter.Client, "article", articleId, "spam");
        await ReportAsync(reporter.Client, "comment", commentId);
        await ReportAsync(reporter.Client, "user", author.Id, "harassment");
        await ReportAsync(reporter.Client, "user", await UserIdAsync(ApiFactory.SuspendedPhone), "other"); // suspended users can be reported

        await PostReport(author.Client, "article", articleId).ProblemAsync(HttpStatusCode.BadRequest, "report.own_content");
        await PostReport(commenter.Client, "comment", commentId).ProblemAsync(HttpStatusCode.BadRequest, "report.own_content");
        await PostReport(reporter.Client, "user", reporter.Id).ProblemAsync(HttpStatusCode.BadRequest, "report.own_content");
        await PostReport(reporter.Client, "article", Guid.NewGuid()).ProblemAsync(HttpStatusCode.NotFound, "report.target_not_found");
        await PostReport(reporter.Client, "user", Guid.NewGuid()).ProblemAsync(HttpStatusCode.NotFound, "report.target_not_found");
        await PostReport(reporter.Client, "comment", articleId).ProblemAsync(HttpStatusCode.NotFound, "report.target_not_found");

        var invalid = await PostReport(reporter.Client, "photo", articleId, reason: "rude").ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        invalid["errors"]!["targetType"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("report.target_invalid");
        invalid["errors"]!["reason"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("report.reason_invalid");
        (await api.GuestClient().PostAsJsonAsync("/api/v1/reports", new { targetType = "article", targetId = articleId, reason = "spam" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        // Deleted targets are gone.
        (await author.Client.DeleteAsync($"/api/v1/articles/{articleId}", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await PostReport((await api.UserAsync()).Client, "article", articleId).ProblemAsync(HttpStatusCode.NotFound, "report.target_not_found");

        var reports = await InDbAsync(db => db.Reports.Where(r => r.ReporterId == reporter.Id).ToListAsync(Ct));
        reports.Should().HaveCount(4, "reporting the same target again is a no-op");
        reports.Single(r => r.TargetId == articleId).Should().BeEquivalentTo(new
        {
            TargetType = ReportTargetType.Article,
            Reason = ReportReason.Misinformation,
            Details = "الأرقام غلط",
            Status = ReportStatus.Open,
        });
    }

    // ---- Hidden articles ----

    [Fact]
    public async Task A_hidden_article_is_only_for_its_author_and_moderators()
    {
        var author = await api.UserAsync("Hidden Writer");
        var (articleId, slug) = await author.Client.PublishAsync();
        var reader = await api.UserAsync();
        var moderator = await ModeratorAsync();
        (await reader.Client.PutEmptyAsync($"/api/v1/me/saved/{articleId}")).StatusCode.Should().Be(HttpStatusCode.OK);
        var commentId = await CommentAsync(reader, articleId, "Saved for later.");
        await InDbAsync(async db =>
        {
            db.DailyPicks.Add(new DailyPick(reader.Id, DailySchedule.LocalDate(DateTime.UtcNow, "Africa/Cairo"), articleId));
            return await db.SaveChangesAsync(Ct);
        });
        (await reader.Client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct))!["id"]!.GetValue<Guid>().Should().Be(articleId);
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["moderation"].Should().BeNull();

        await ActOkAsync(moderator, new { action = "hide", targetType = "article", targetId = articleId, note = "Copied from another blog." });

        // Everyone else: gone, and so is everything on it.
        await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await reader.Client.GetAsync($"/api/v1/articles/{slug}", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await reader.Client.GetAsync($"/api/v1/articles/{articleId}/comments", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await reader.Client.GetAsync($"/api/v1/comments/{commentId}", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await reader.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body = "hi" }, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await reader.Client.ReactAsync(articleId, "love").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await reader.Client.GetAsync($"/api/v1/articles/{articleId}/reactions", Ct).ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await reader.Client.PutEmptyAsync($"/api/v1/me/saved/{articleId}").ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await reader.Client.PutAsJsonAsync($"/api/v1/articles/{articleId}/progress", Progress(), Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "article.not_found");

        // ...and from every list.
        (await InForYouAsync(api.GuestClient(), articleId)).Should().BeFalse();
        (await InForYouAsync(reader.Client, articleId)).Should().BeFalse();
        (await reader.Client.GetAsync("/api/v1/feed/today", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent, "the hidden pick is no hero card");
        (await reader.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/saved", Ct))!["items"]!.AsArray()
            .Should().NotContain(i => i!["article"]!["id"]!.GetValue<Guid>() == articleId);
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/users/{author.Me["username"]}/articles", Ct))!["items"]!.AsArray()
            .Should().BeEmpty();

        // Its author and moderators still open it, with the banner's data.
        foreach (var client in new[] { author.Client, moderator })
        {
            var details = await client.GetAsync($"/api/v1/articles/{slug}", Ct).OkJsonAsync();
            details["moderation"]!["note"]!.GetValue<string>().Should().Be("Copied from another blog.");
            details["moderation"]!["hiddenAt"]!.GetValue<DateTime>().Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(1));
            (await client.GetAsync($"/api/v1/articles/{articleId}/comments", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        }
        (await author.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body = "Fixed the sources." }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.Created);
        (await author.Client.PutAsJsonAsync($"/api/v1/articles/{articleId}/progress", Progress(), Ct)).StatusCode.Should().Be(HttpStatusCode.OK);

        (await InDbAsync(db => db.AuditLogs.Where(l => l.UserId == author.Id).Select(l => l.Action).ToListAsync(Ct)))
            .Should().Contain(AuditActions.ArticleHidden);

        await ActOkAsync(moderator, new { action = "unhide", targetType = "article", targetId = articleId });
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/articles/{slug}", Ct))!["moderation"].Should().BeNull();
        (await InForYouAsync(api.GuestClient(), articleId)).Should().BeTrue();
        (await reader.Client.GetFromJsonAsync<JsonObject>("/api/v1/feed/today", Ct))!["id"]!.GetValue<Guid>().Should().Be(articleId);
    }

    // ---- Actions: pairs, permissions, inputs ----

    [Fact]
    public async Task Actions_check_the_target_pair_permissions_note_and_duration()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var commentId = await CommentAsync(author, articleId, "A comment.");
        var reader = await api.UserAsync();
        var moderator = await ModeratorAsync();

        await ActAsync(reader.Client, new { action = "hide", targetType = "comment", targetId = commentId })
            .ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");

        foreach (var (action, type, id) in new[]
                 {
                     ("delete", "article", articleId), ("warn", "comment", commentId), ("hide", "user", author.Id),
                     ("explode", "comment", commentId), ("hide", "photo", commentId), ("suspend", "article", articleId),
                 })
            await ActAsync(moderator, new { action, targetType = type, targetId = id }).ProblemAsync(HttpStatusCode.BadRequest, "moderation.action_invalid");

        await ActAsync(moderator, new { action = "warn", targetType = "user", targetId = author.Id })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.note_required");
        await ActAsync(moderator, new { action = "suspend", targetType = "user", targetId = author.Id, note = "   ", durationDays = 7 })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.note_required");
        foreach (var days in new[] { 0, 366 })
        {
            await ActAsync(moderator, new { action = "suspend", targetType = "user", targetId = author.Id, note = "Spam.", durationDays = days })
                .ProblemAsync(HttpStatusCode.BadRequest, "moderation.duration_invalid");
        }
        await ActAsync(moderator, new { action = "hide", targetType = "comment", targetId = commentId, durationDays = 3 })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.duration_invalid");
        var tooLong = await ActAsync(moderator, new { action = "hide", targetType = "comment", targetId = commentId, note = new string('x', 501) })
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        tooLong["errors"]!["note"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.max_length");

        await ActAsync(moderator, new { action = "hide", targetType = "article", targetId = Guid.NewGuid() })
            .ProblemAsync(HttpStatusCode.NotFound, "article.not_found");
        await ActAsync(moderator, new { action = "delete", targetType = "comment", targetId = Guid.NewGuid() })
            .ProblemAsync(HttpStatusCode.NotFound, "comment.not_found");
        await ActAsync(moderator, new { action = "warn", targetType = "user", targetId = Guid.NewGuid(), note = "x" })
            .ProblemAsync(HttpStatusCode.NotFound, "user.not_found");

        // moderation.manage without users.suspend: warns, but can't suspend or unsuspend.
        var triage = await TriageModeratorAsync();
        await ActOkAsync(triage.Client, new { action = "warn", targetType = "user", targetId = author.Id, note = "Be kind." });
        await ActAsync(triage.Client, new { action = "suspend", targetType = "user", targetId = author.Id, note = "Spam." })
            .ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        await ActAsync(triage.Client, new { action = "unsuspend", targetType = "user", targetId = author.Id })
            .ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
    }

    [Fact]
    public async Task Nobody_warns_or_suspends_themselves_or_staff_but_staff_content_can_be_hidden()
    {
        // Staff = whoever holds moderation.manage: today the SuperAdmin (a test's own, and the seeded one).
        var moderator = await ModeratorAsync();
        var admin = (await api.SuperAdminAsync("Second SuperAdmin")).Client;
        var moderatorId = await MeIdAsync(moderator);
        var adminId = await MeIdAsync(admin);
        var officialId = await InDbAsync(db => db.Users.Where(u => u.Username == "readin" && u.IsSystemAccount).Select(u => u.Id).SingleAsync(Ct));

        await ActAsync(moderator, new { action = "warn", targetType = "user", targetId = moderatorId, note = "x" })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.self");
        await ActAsync(moderator, new { action = "suspend", targetType = "user", targetId = moderatorId, note = "x" })
            .ProblemAsync(HttpStatusCode.BadRequest, "moderation.self");
        await ActAsync(moderator, new { action = "warn", targetType = "user", targetId = adminId, note = "x" })
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");
        await ActAsync(admin, new { action = "suspend", targetType = "user", targetId = moderatorId, note = "x", durationDays = 1 })
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");
        await ActAsync(admin, new { action = "unsuspend", targetType = "user", targetId = moderatorId })
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");
        await ActAsync(moderator, new { action = "warn", targetType = "user", targetId = officialId, note = "x" })
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");
        await ActAsync(moderator, new { action = "suspend", targetType = "user", targetId = SystemUsers.SuperAdminId, note = "x" })
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");

        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var response = await moderator.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body = "Moderator's comment." }, Ct);
        var commentId = (await ApiFactory.ReadSessionAsync(response))["id"]!.GetValue<Guid>();
        await ActOkAsync(admin, new { action = "hide", targetType = "comment", targetId = commentId });
    }

    // ---- Suspension ----

    [Fact]
    public async Task A_suspension_blocks_at_once_shows_when_it_ends_and_unsuspend_lifts_it()
    {
        var user = await api.UserAsync();
        var moderator = await ModeratorAsync();
        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);

        await ActOkAsync(moderator, new { action = "suspend", targetType = "user", targetId = user.Id, note = "Spam links.", durationDays = 7 });

        var expected = DateTime.UtcNow.AddDays(7);
        var blocked = await user.Client.GetAsync("/api/v1/me", Ct).ProblemAsync(HttpStatusCode.Forbidden, "user.suspended");
        blocked["suspendedUntil"]!.GetValue<DateTime>().Should().BeCloseTo(expected, TimeSpan.FromMinutes(1));
        var signIn = await api.GuestClient().PostAsJsonAsync("/api/v1/auth/login", new { phoneNumber = user.PhoneNumber, password = ApiFactory.TestPassword }, Ct)
            .ProblemAsync(HttpStatusCode.Forbidden, "user.suspended");
        signIn["suspendedUntil"]!.GetValue<DateTime>().Should().BeCloseTo(expected, TimeSpan.FromMinutes(1));
        var refresh = await api.GuestClient().PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = user.RefreshToken }, Ct)
            .ProblemAsync(HttpStatusCode.Forbidden, "user.suspended");
        refresh["suspendedUntil"]!.GetValue<DateTime>().Should().BeCloseTo(expected, TimeSpan.FromMinutes(1));

        // Permanent: suspendedUntil is null. Repeating it changes nothing and logs nothing.
        await ActOkAsync(moderator, new { action = "suspend", targetType = "user", targetId = user.Id, note = "Again." });
        await ActOkAsync(moderator, new { action = "suspend", targetType = "user", targetId = user.Id, note = "Again." });
        var permanent = await user.Client.GetAsync("/api/v1/me", Ct).ProblemAsync(HttpStatusCode.Forbidden, "user.suspended");
        permanent.ContainsKey("suspendedUntil").Should().BeTrue();
        permanent["suspendedUntil"].Should().BeNull("permanent");

        await ActOkAsync(moderator, new { action = "unsuspend", targetType = "user", targetId = user.Id });
        await ActOkAsync(moderator, new { action = "unsuspend", targetType = "user", targetId = user.Id });
        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "unsuspending lifts it at once");

        var log = await InDbAsync(db => db.ModerationActions.Where(m => m.TargetUserId == user.Id).OrderBy(m => m.CreatedAt).ToListAsync(Ct));
        log.Select(m => m.Action).Should().Equal(ModerationActionTypes.UserSuspend, ModerationActionTypes.UserSuspend, ModerationActionTypes.UserUnsuspend);
        log[0].SuspendedUntil.Should().BeCloseTo(expected, TimeSpan.FromMinutes(1));
        log[1].SuspendedUntil.Should().BeNull();
        log[0].Note.Should().Be("Spam links.");
        (await InDbAsync(db => db.AuditLogs.Where(l => l.UserId == user.Id).Select(l => l.Action).ToListAsync(Ct)))
            .Should().Contain([AuditActions.UserSuspended, AuditActions.UserUnsuspended]);
    }

    [Fact]
    public async Task A_temporary_suspension_ends_by_itself()
    {
        var user = await api.UserAsync();
        var moderator = await ModeratorAsync();
        await ActOkAsync(moderator, new { action = "suspend", targetType = "user", targetId = user.Id, note = "Cool down.", durationDays = 1 });
        await user.Client.GetAsync("/api/v1/me", Ct).ProblemAsync(HttpStatusCode.Forbidden, "user.suspended");

        // A day later (the cached access expires within 5 minutes in real life).
        await InDbAsync(db => db.Users.Where(u => u.Id == user.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(u => u.SuspendedUntil, DateTime.UtcNow.AddMinutes(-1)), Ct));
        await InScopeAsync(scope => scope.GetRequiredService<IUserAccessService>().InvalidateAsync(user.Id, Ct).AsTask());

        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await api.GuestClient().PostAsJsonAsync("/api/v1/auth/login", new { phoneNumber = user.PhoneNumber, password = ApiFactory.TestPassword }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.OK);
        var item = await CaseItemOrNullAsync(moderator, "user", user.Id);
        item.Should().BeNull("nobody reported this user");

        await ActOkAsync(moderator, new { action = "unsuspend", targetType = "user", targetId = user.Id });
        (await InDbAsync(db => db.ModerationActions.CountAsync(m => m.TargetUserId == user.Id && m.Action == ModerationActionTypes.UserUnsuspend, Ct)))
            .Should().Be(0, "an ended suspension has nothing to lift");
    }

    // ---- Notices ----

    [Fact]
    public async Task A_warning_and_a_hidden_article_are_notices_with_a_push()
    {
        var author = await api.UserAsync();
        var (articleId, slug) = await author.Client.PublishAsync("Notices test");
        var token = $"fcm-{Guid.NewGuid():N}";
        (await author.Client.PostAsJsonAsync("/api/v1/me/devices", new { token, platform = "android" }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        // Pushes wait for the end of quiet hours (F17); this test sends them now, whatever the time of day.
        (await author.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
            new { quietHours = new { enabled = false, start = "23:00", end = "07:00" } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var moderator = await ModeratorAsync();

        await ActOkAsync(moderator, new { action = "warn", targetType = "user", targetId = author.Id, note = "No self-promotion in comments." });
        await ActOkAsync(moderator, new { action = "hide", targetType = "article", targetId = articleId, note = "Sources are missing." });

        var notices = (await author.Client.GetAsync("/api/v1/me/moderation-notices", Ct).OkJsonAsync())["items"]!.AsArray();
        notices.Should().HaveCount(2);
        notices[0]!["kind"]!.GetValue<string>().Should().Be("warning");
        notices[0]!["note"]!.GetValue<string>().Should().Be("No self-promotion in comments.");
        notices[0]!["article"].Should().BeNull();
        notices[1]!["kind"]!.GetValue<string>().Should().Be("article_hidden");
        notices[1]!["article"]!["id"]!.GetValue<Guid>().Should().Be(articleId);
        notices[1]!["article"]!["slug"]!.GetValue<string>().Should().Be(slug);
        notices[1]!["article"]!["title"]!.GetValue<string>().Should().Be("Notices test");
        notices[1]!["note"]!.GetValue<string>().Should().Be("Sources are missing.");
        var warningId = notices[0]!["id"]!.GetValue<Guid>();
        var hiddenId = notices[1]!["id"]!.GetValue<Guid>();

        // The outbox ran after the commit: each notice is a moderation_notice entry (F17 took over F22's push).
        var message = await InDbAsync(db => db.OutboxMessages
            .Where(m => m.Type == typeof(ModerationNoticeIssuedDomainEvent).FullName && m.Content.Contains(hiddenId.ToString()))
            .SingleAsync(Ct));
        message.ProcessedAt.Should().NotBeNull();
        message.Error.Should().BeNull();
        var entries = await InDbAsync(db => db.Notifications.AsNoTracking()
            .Where(n => n.UserId == author.Id && n.Type == NotificationTypes.ModerationNotice).ToListAsync(Ct));
        entries.Should().HaveCount(2).And.OnlyContain(n => n.PushStatus == NotificationPushStatus.Pending);
        var hiddenEntry = entries.Single(n => n.ArticleId == articleId);
        var warningEntry = entries.Single(n => n.ArticleId == null);

        // FCM unreachable: the push job only logs it, and tries again later.
        var now = DateTime.UtcNow;
        await PushAsync(new FailingPushSender(), now);
        (await InDbAsync(db => db.Notifications.AsNoTracking().Where(n => n.UserId == author.Id).Select(n => new { n.PushStatus, n.PushAttempts })
                .ToListAsync(Ct)))
            .Should().HaveCount(2).And.OnlyContain(n => n.PushStatus == NotificationPushStatus.Pending && n.PushAttempts == 1);

        // What FCM gets, in the author's UI language (en), once per notice.
        var push = new RecordingPushSender();
        await PushAsync(push, now.AddMinutes(2));
        var sent = push.To(token).Should().HaveCount(2).And.ContainSingle(n => n.Data["noticeId"] == hiddenId.ToString()).Subject;
        sent.Title.Should().Be(NotificationTexts.ArticleHiddenTitleEn);
        sent.Body.Should().Be("Notices test");
        sent.Data.Should().Contain(new Dictionary<string, string>
        {
            ["type"] = "moderation_notice", ["kind"] = "article_hidden", ["noticeId"] = hiddenId.ToString(), ["slug"] = slug,
            ["link"] = $"readin://a/{slug}", ["notificationId"] = hiddenEntry.Id.ToString(),
        });
        push.To(token).Single(n => n.Data["noticeId"] == warningId.ToString()).Should().Match<PushNotification>(n =>
            n.Title == NotificationTexts.ModerationWarningTitleEn && n.Body == "No self-promotion in comments."
            && n.Data["link"] == "readin://notifications" && n.Data["kind"] == "warning" && n.Data["notificationId"] == warningEntry.Id.ToString());
        await PushAsync(push, now.AddMinutes(3));
        push.To(token).Should().HaveCount(2, "a notice is pushed once");

        // Acknowledging is idempotent and only for the notice's user.
        (await author.Client.PostAsync($"/api/v1/me/moderation-notices/{warningId}/acknowledge", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await author.Client.PostAsync($"/api/v1/me/moderation-notices/{warningId}/acknowledge", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await (await api.UserAsync()).Client.PostAsync($"/api/v1/me/moderation-notices/{hiddenId}/acknowledge", null, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "moderation.notice_not_found");
        (await author.Client.GetAsync("/api/v1/me/moderation-notices", Ct).OkJsonAsync())["items"]!.AsArray()
            .Should().ContainSingle().Which!["id"]!.GetValue<Guid>().Should().Be(hiddenId);

        // A notice acknowledged before its push went out is not pushed.
        await ActOkAsync(moderator, new { action = "warn", targetType = "user", targetId = author.Id, note = "Second warning." });
        var second = (await author.Client.GetAsync("/api/v1/me/moderation-notices", Ct).OkJsonAsync())["items"]!.AsArray()
            .Single(n => n!["kind"]!.GetValue<string>() == "warning")!["id"]!.GetValue<Guid>();
        (await author.Client.PostAsync($"/api/v1/me/moderation-notices/{second}/acknowledge", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await PushAsync(push, DateTime.UtcNow.AddSeconds(5));
        (await InDbAsync(db => db.Notifications.AsNoTracking().Where(n => n.UserId == author.Id && n.PushedAt == null).Select(n => n.PushStatus)
                .ToListAsync(Ct)))
            .Should().ContainSingle().Which.Should().Be(NotificationPushStatus.Skipped);
        push.To(token).Should().HaveCount(2, "an acknowledged notice is not pushed");

        // Tokens FCM rejects are removed.
        var rejecting = new RecordingPushSender();
        rejecting.InvalidTokens.Add(token);
        await ActOkAsync(moderator, new { action = "warn", targetType = "user", targetId = author.Id, note = "Third warning." });
        await PushAsync(rejecting, DateTime.UtcNow.AddSeconds(5));
        (await InDbAsync(db => db.Users.Where(u => u.Id == author.Id).SelectMany(u => u.Devices).CountAsync(Ct))).Should().Be(0);
    }

    // ---- Dismiss and resolveReportsOf ----

    [Fact]
    public async Task Dismiss_closes_reports_without_touching_content_and_actions_resolve_the_related_reports()
    {
        var author = await api.UserAsync();
        var (articleId, slug) = await author.Client.PublishAsync();
        var commenter = await api.UserAsync();
        var commentId = await CommentAsync(commenter, articleId, "Totally off-topic link spam.");
        var moderator = await ModeratorAsync();
        var moderatorId = await MeIdAsync(moderator);
        foreach (var reporter in new[] { await api.UserAsync(), await api.UserAsync() })
        {
            await ReportAsync(reporter.Client, "article", articleId, "other");
            await ReportAsync(reporter.Client, "comment", commentId);
            await ReportAsync(reporter.Client, "user", commenter.Id);
        }

        await ActOkAsync(moderator, new { action = "dismiss", targetType = "article", targetId = articleId, note = "Opinion, not misinformation." });
        await ActOkAsync(moderator, new { action = "dismiss", targetType = "article", targetId = articleId });
        (await api.GuestClient().GetAsync($"/api/v1/articles/{slug}", Ct)).StatusCode.Should().Be(HttpStatusCode.OK, "dismissing never touches the content");

        // Warning the commenter also resolves the reports of the comment it was for.
        await ActOkAsync(moderator, new
        {
            action = "warn", targetType = "user", targetId = commenter.Id, note = "No link spam.",
            resolveReportsOf = new { targetType = "comment", targetId = commentId },
        });
        await ActOkAsync(moderator, new { action = "hide", targetType = "comment", targetId = commentId });

        var reports = await InDbAsync(db => db.Reports.Where(r => r.TargetId == articleId || r.TargetId == commentId || r.TargetId == commenter.Id)
            .ToListAsync(Ct));
        reports.Should().HaveCount(6).And.AllSatisfy(r => r.ResolvedById.Should().Be(moderatorId));
        reports.Where(r => r.TargetId == articleId).Should().AllSatisfy(r => r.Status.Should().Be(ReportStatus.Dismissed));
        reports.Where(r => r.TargetId != articleId).Should().AllSatisfy(r => r.Status.Should().Be(ReportStatus.Resolved));

        var log = await InDbAsync(db => db.ModerationActions.Where(m => m.TargetId == articleId || m.TargetId == commentId || m.TargetId == commenter.Id)
            .OrderBy(m => m.CreatedAt).ToListAsync(Ct));
        log.Select(m => (m.Action, m.ReportsClosed)).Should().Equal(
            (ModerationActionTypes.ReportsDismiss, 2), (ModerationActionTypes.UserWarn, 4), (ModerationActionTypes.CommentHide, 0));
        log[0].Should().BeEquivalentTo(new { TargetUserId = (Guid?)author.Id, Note = "Opinion, not misinformation.", NoticeKind = (string?)null });
    }

    // ---- Queue ----

    [Fact]
    public async Task The_queue_groups_by_target_orders_filters_and_pages()
    {
        var moderator = await ModeratorAsync();
        var before = (await moderator.GetAsync("/api/v1/moderation/summary", Ct).OkJsonAsync())["open"]!;

        var author = await api.UserAsync("Queue Writer");
        var (a, aSlug) = await author.Client.PublishAsync("Queue article A");
        var (b, _) = await author.Client.PublishAsync("Queue article B");
        var commenter = await api.UserAsync();
        var c = await CommentAsync(commenter, a, "Queue comment C");
        var u = await api.UserAsync();
        var reporters = new[] { await api.UserAsync(), await api.UserAsync(), await api.UserAsync() };

        await ReportAsync(reporters[0].Client, "article", a, "spam");
        await ReportAsync(reporters[1].Client, "article", a, "spam");
        await ReportAsync(reporters[2].Client, "article", a, "misinformation");
        await ReportAsync(reporters[0].Client, "comment", c, "harassment");
        await ReportAsync(reporters[1].Client, "comment", c, "harassment");
        await ReportAsync(reporters[0].Client, "user", u.Id, "spam");
        await ReportAsync(reporters[1].Client, "user", u.Id, "other");
        await ReportAsync(reporters[2].Client, "article", b, "copyright");

        var after = (await moderator.GetAsync("/api/v1/moderation/summary", Ct).OkJsonAsync())["open"]!;
        Delta("article").Should().Be(2);
        Delta("comment").Should().Be(1);
        Delta("user").Should().Be(1);
        Delta("total").Should().Be(4);

        // Most reports first, then the most recent report (U was reported after C); every page is a keyset step.
        var open = await AllPagesAsync(moderator, "/api/v1/moderation/reports?limit=2");
        open.Select(Key).Should().OnlyHaveUniqueItems();
        open.Select(i => i["targetId"]!.GetValue<Guid>()).Where(new[] { a, b, c, u.Id }.Contains).Should().Equal(a, u.Id, c, b);

        var itemA = open.Single(i => i["targetId"]!.GetValue<Guid>() == a);
        itemA["targetType"]!.GetValue<string>().Should().Be("article");
        itemA["status"]!.GetValue<string>().Should().Be("open");
        itemA["reportCount"]!.GetValue<int>().Should().Be(3);
        itemA["reasons"]!.AsObject().Select(r => (r.Key, r.Value!.GetValue<int>())).Should().Equal(("spam", 2), ("misinformation", 1));
        itemA["closedAt"].Should().BeNull();
        itemA["firstReportedAt"]!.GetValue<DateTime>().Should().BeBefore(itemA["lastReportedAt"]!.GetValue<DateTime>());
        itemA["target"]!["state"]!.GetValue<string>().Should().Be("visible");
        itemA["target"]!["title"]!.GetValue<string>().Should().Be("Queue article A");
        itemA["target"]!["slug"]!.GetValue<string>().Should().Be(aSlug);
        itemA["target"]!["author"]!["id"]!.GetValue<Guid>().Should().Be(author.Id);

        var itemC = open.Single(i => i["targetId"]!.GetValue<Guid>() == c);
        itemC["target"]!["body"]!.GetValue<string>().Should().Be("Queue comment C");
        itemC["target"]!["articleId"]!.GetValue<Guid>().Should().Be(a);
        itemC["target"]!["articleSlug"]!.GetValue<string>().Should().Be(aSlug);
        itemC["target"]!["author"]!["id"]!.GetValue<Guid>().Should().Be(commenter.Id);

        var itemU = open.Single(i => i["targetId"]!.GetValue<Guid>() == u.Id);
        itemU["target"]!["state"]!.GetValue<string>().Should().Be("active");
        itemU["target"]!["warningCount"]!.GetValue<int>().Should().Be(0);
        itemU["target"]!["author"]!["username"]!.GetValue<string>().Should().Be(u.Me["username"]!.GetValue<string>());

        var comments = await AllPagesAsync(moderator, "/api/v1/moderation/reports?type=comment&limit=50");
        comments.Should().AllSatisfy(i => i["targetType"]!.GetValue<string>().Should().Be("comment"));
        comments.Should().Contain(i => i["targetId"]!.GetValue<Guid>() == c);

        // Closed lists: most recently closed first.
        await ActOkAsync(moderator, new { action = "hide", targetType = "article", targetId = a });
        await ActOkAsync(moderator, new { action = "hide", targetType = "comment", targetId = c });
        await ActOkAsync(moderator, new { action = "dismiss", targetType = "article", targetId = b });
        var resolved = await moderator.GetAsync("/api/v1/moderation/reports?status=resolved&limit=1", Ct).OkJsonAsync();
        var first = resolved["items"]!.AsArray().Should().ContainSingle().Subject!;
        first["targetId"]!.GetValue<Guid>().Should().Be(c);
        first["status"]!.GetValue<string>().Should().Be("resolved");
        first["closedAt"]!.GetValue<DateTime>().Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(1));
        first["target"]!["state"]!.GetValue<string>().Should().Be("hidden");
        var second = await moderator.GetAsync($"/api/v1/moderation/reports?status=resolved&limit=1&cursor={resolved["nextCursor"]}", Ct).OkJsonAsync();
        second["items"]!.AsArray().Should().ContainSingle().Which!["targetId"]!.GetValue<Guid>().Should().Be(a);
        (await moderator.GetAsync("/api/v1/moderation/reports?status=dismissed&type=article&limit=1", Ct).OkJsonAsync())["items"]!.AsArray()
            .Should().ContainSingle().Which!["targetId"]!.GetValue<Guid>().Should().Be(b);
        (await AllPagesAsync(moderator, "/api/v1/moderation/reports?limit=50")).Select(i => i["targetId"]!.GetValue<Guid>())
            .Should().NotContain([a, b, c]);

        var invalid = await moderator.GetAsync("/api/v1/moderation/reports?status=closed&type=photo", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        invalid["errors"]!["status"]!.AsArray().Single()!.GetValue<string>().Should().Be("report.status_invalid");
        invalid["errors"]!["type"]!.AsArray().Single()!.GetValue<string>().Should().Be("report.target_invalid");
        await reporters[0].Client.GetAsync("/api/v1/moderation/reports", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        await reporters[0].Client.GetAsync("/api/v1/moderation/summary", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");

        int Delta(string type) => after[type]!.GetValue<int>() - before[type]!.GetValue<int>();
        static string Key(JsonObject item) => $"{item["targetType"]}:{item["targetId"]}";
    }

    [Fact]
    public async Task A_case_shows_the_target_every_report_and_its_history()
    {
        var author = await api.UserAsync();
        var (articleId, _) = await author.Client.PublishAsync();
        var commenter = await api.UserAsync("Case Commenter");
        var commentId = await CommentAsync(commenter, articleId, "Case comment");
        var moderator = await ModeratorAsync();
        var moderatorId = await MeIdAsync(moderator);
        var leaving = await api.UserAsync();
        var staying = await api.UserAsync();
        await ReportAsync(leaving.Client, "comment", commentId, "spam", "Spam!");
        await ReportAsync(staying.Client, "comment", commentId, "harassment");
        // The first reporter deletes their account (soft delete): the report stays, the reporter shows as null.
        await InDbAsync(db => db.Users.Where(x => x.Id == leaving.Id).ExecuteUpdateAsync(s => s.SetProperty(x => x.IsDeleted, true), Ct));

        await ActOkAsync(moderator, new
        {
            action = "warn", targetType = "user", targetId = commenter.Id, note = "Keep it civil.",
            resolveReportsOf = new { targetType = "comment", targetId = commentId },
        });

        var closed = await moderator.GetAsync($"/api/v1/moderation/reports/comment/{commentId}", Ct).OkJsonAsync();
        closed["item"]!["status"]!.GetValue<string>().Should().Be("resolved");
        closed["item"]!["reportCount"]!.GetValue<int>().Should().Be(2);
        closed["item"]!["target"]!["state"]!.GetValue<string>().Should().Be("visible");
        var reports = closed["reports"]!.AsArray();
        reports.Select(r => r!["reason"]!.GetValue<string>()).Should().Equal("harassment", "spam");
        reports[0]!["reporter"]!["id"]!.GetValue<Guid>().Should().Be(staying.Id);
        reports[1]!["reporter"].Should().BeNull();
        reports[1]!["details"]!.GetValue<string>().Should().Be("Spam!");
        reports.Should().AllSatisfy(r =>
        {
            r!["status"]!.GetValue<string>().Should().Be("resolved");
            r["closedBy"]!["id"]!.GetValue<Guid>().Should().Be(moderatorId);
            r["closedAt"].Should().NotBeNull();
        });
        var history = closed["history"]!.AsArray().Should().ContainSingle("the warning was on the comment's author").Subject!;
        history["action"]!.GetValue<string>().Should().Be("user.warn");
        history["targetType"]!.GetValue<string>().Should().Be("user");
        history["targetLabel"]!.GetValue<string>().Should().Be($"@{commenter.Me["username"]}");
        history["targetUser"]!["id"]!.GetValue<Guid>().Should().Be(commenter.Id);
        history["moderator"]!["id"]!.GetValue<Guid>().Should().Be(moderatorId);
        history["note"]!.GetValue<string>().Should().Be("Keep it civil.");
        history["reportsClosed"]!.GetValue<int>().Should().Be(2);
        history["suspendedUntil"].Should().BeNull();

        // A new report reopens the case.
        await ReportAsync((await api.UserAsync()).Client, "comment", commentId, "other");
        var reopened = await moderator.GetAsync($"/api/v1/moderation/reports/comment/{commentId}", Ct).OkJsonAsync();
        reopened["item"]!["status"]!.GetValue<string>().Should().Be("open");
        reopened["item"]!["reportCount"]!.GetValue<int>().Should().Be(1);
        reopened["reports"]!.AsArray().Should().HaveCount(3);

        await moderator.GetAsync($"/api/v1/moderation/reports/comment/{Guid.NewGuid()}", Ct).ProblemAsync(HttpStatusCode.NotFound, "report.target_not_found");
        await moderator.GetAsync($"/api/v1/moderation/reports/photo/{commentId}", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        await staying.Client.GetAsync($"/api/v1/moderation/reports/comment/{commentId}", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
    }

    // ---- Log ----

    [Fact]
    public async Task The_log_filters_by_user_moderator_and_type_and_pages()
    {
        var moderator = await ModeratorAsync();
        var admin = (await api.SuperAdminAsync("Second Moderator")).Client;
        var adminId = await MeIdAsync(admin);
        var warned = await api.UserAsync();
        var commenter = await api.UserAsync();
        var (articleId, _) = await (await api.UserAsync()).Client.PublishAsync();
        var body = "This comment is long enough that its label is cut at eighty characters, as the log promises.";
        var commentId = await CommentAsync(commenter, articleId, body);

        await ActOkAsync(moderator, new { action = "warn", targetType = "user", targetId = warned.Id, note = "First." });
        await ActOkAsync(admin, new { action = "warn", targetType = "user", targetId = warned.Id, note = "Second." });
        await ActOkAsync(moderator, new { action = "hide", targetType = "comment", targetId = commentId, note = "Rude." });

        var byUser = (await moderator.GetAsync($"/api/v1/moderation/actions?targetUserId={warned.Id}", Ct).OkJsonAsync())["items"]!.AsArray();
        byUser.Select(i => i!["note"]!.GetValue<string>()).Should().Equal("Second.", "First.");
        byUser.Should().AllSatisfy(i => i!["targetUser"]!["id"]!.GetValue<Guid>().Should().Be(warned.Id));
        (await moderator.GetAsync($"/api/v1/moderation/actions?targetUserId={warned.Id}&moderatorId={adminId}", Ct).OkJsonAsync())["items"]!
            .AsArray().Should().ContainSingle().Which!["moderator"]!["id"]!.GetValue<Guid>().Should().Be(adminId);

        var hidden = (await moderator.GetAsync($"/api/v1/moderation/actions?targetUserId={commenter.Id}&targetType=comment", Ct).OkJsonAsync())["items"]!
            .AsArray().Should().ContainSingle().Subject!;
        hidden["action"]!.GetValue<string>().Should().Be("comment.hide");
        hidden["targetId"]!.GetValue<Guid>().Should().Be(commentId);
        hidden["targetLabel"]!.GetValue<string>().Should().Be(body[..80]);

        var page1 = await moderator.GetAsync($"/api/v1/moderation/actions?targetUserId={warned.Id}&limit=1", Ct).OkJsonAsync();
        page1["items"]!.AsArray().Single()!["note"]!.GetValue<string>().Should().Be("Second.");
        var page2 = await moderator.GetAsync($"/api/v1/moderation/actions?targetUserId={warned.Id}&limit=1&cursor={page1["nextCursor"]}", Ct).OkJsonAsync();
        page2["items"]!.AsArray().Single()!["note"]!.GetValue<string>().Should().Be("First.");
        page2["nextCursor"].Should().BeNull();

        await moderator.GetAsync("/api/v1/moderation/actions?targetType=photo", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        await warned.Client.GetAsync("/api/v1/moderation/actions", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
    }

    [Fact]
    public async Task The_openapi_document_describes_the_moderation_endpoints()
    {
        var document = await api.GuestClient().GetAsync("/openapi/v1.json", Ct).OkJsonAsync();

        document["paths"]!.AsObject().Select(p => p.Key).Should().Contain([
            "/api/v1/reports", "/api/v1/moderation/summary", "/api/v1/moderation/reports", "/api/v1/moderation/reports/{targetType}/{targetId}",
            "/api/v1/moderation/actions", "/api/v1/me/moderation-notices/{id}/acknowledge"]);
        document["components"]!["schemas"]!["ModerateContentCommand"]!["properties"]!.AsObject().Select(p => p.Key)
            .Should().BeEquivalentTo("action", "targetType", "targetId", "note", "durationDays", "resolveReportsOf", "categoryId"); // categoryId: F31
    }

    // ---- Demo data ----

    [Fact]
    public async Task The_demo_reports_seeder_fills_the_queue_locally_and_can_run_again()
    {
        await using var scope = api.Services.CreateAsyncScope();
        var seeder = scope.ServiceProvider.GetServices<ISeeder>().Single(s => s.Name == "demo-reports");
        seeder.AppliesTo(scope.ServiceProvider.GetRequiredService<IHostEnvironment>()).Should().BeFalse("Development only");

        await seeder.SeedAsync(Ct);
        var first = await DemoRowsAsync();
        await seeder.SeedAsync(Ct);
        var second = await DemoRowsAsync();

        second.Should().BeEquivalentTo(first, "a re-run replaces its rows");
        first.Reports.Should().Contain([ReportStatus.Open, ReportStatus.Resolved, ReportStatus.Dismissed]);
        first.Actions.Should().Contain([ModerationActionTypes.UserWarn, ModerationActionTypes.ReportsDismiss]);

        async Task<(List<ReportStatus> Reports, List<string> Actions)> DemoRowsAsync()
        {
            var moderatorId = SystemUsers.SuperAdminId; // the demo SuperAdmin moderates (there is no demo moderator)
            var reporters = await InDbAsync(db => db.Users.Where(x => x.Email != null && x.Email.EndsWith("@readin.test")).Select(x => x.Id).ToListAsync(Ct));
            return (
                await InDbAsync(db => db.Reports.Where(r => reporters.Contains(r.ReporterId)).OrderBy(r => r.Status).Select(r => r.Status).ToListAsync(Ct)),
                await InDbAsync(db => db.ModerationActions.Where(m => m.ModeratorId == moderatorId && m.Note != null &&
                        (m.Note.StartsWith("روابط") || m.Note.StartsWith("خلاف"))).OrderBy(m => m.Action).Select(m => m.Action).ToListAsync(Ct)));
        }
    }

    // ---- Helpers ----

    /// <summary>
    /// Each test acts as its own moderator, a SuperAdmin (the only role with <c>moderation.manage</c>): the <c>writes</c>
    /// rate limit (30 a minute) is per user.
    /// </summary>
    private async Task<HttpClient> ModeratorAsync() => (await api.SuperAdminAsync("Test Moderator")).Client;

    private static async Task<Guid> MeIdAsync(HttpClient client) => (await client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["id"]!.GetValue<Guid>();

    private Task<Guid> UserIdAsync(string phone) => InDbAsync(db => db.Users.Where(u => u.PhoneNumber == phone).Select(u => u.Id).SingleAsync(Ct));

    private static Task<HttpResponseMessage> ActAsync(HttpClient client, object body) => client.PostAsJsonAsync("/api/v1/moderation/actions", body, Ct);

    private static async Task ActOkAsync(HttpClient client, object body)
    {
        var response = await ActAsync(client, body);
        response.StatusCode.Should().Be(HttpStatusCode.NoContent, await response.Content.ReadAsStringAsync(Ct));
    }

    private static Task<HttpResponseMessage> PostReport(HttpClient client, string type, Guid id, string reason = "spam", string? details = null) =>
        client.PostAsJsonAsync("/api/v1/reports", new { targetType = type, targetId = id, reason, details }, Ct);

    private static async Task ReportAsync(HttpClient client, string type, Guid id, string reason = "spam", string? details = null)
    {
        var response = await PostReport(client, type, id, reason, details);
        response.StatusCode.Should().Be(HttpStatusCode.NoContent, await response.Content.ReadAsStringAsync(Ct));
    }

    private static async Task<Guid> CommentAsync(SignedInUser user, Guid articleId, string body)
    {
        var response = await user.Client.PostAsJsonAsync($"/api/v1/articles/{articleId}/comments", new { body }, Ct);
        return (await ApiFactory.ReadSessionAsync(response))["id"]!.GetValue<Guid>();
    }

    private static object Progress() => new { language = "en", percent = 10, lastPosition = (string?)null, activeSecondsDelta = 5 };

    private static async Task<bool> InForYouAsync(HttpClient client, Guid articleId)
    {
        string? cursor = null;
        for (var page = 0; page < 50; page++)
        {
            var feed = (await client.GetFromJsonAsync<JsonObject>("/api/v1/feed/for-you?limit=50" + (cursor is null ? "" : $"&cursor={cursor}"), Ct))!;
            if (feed["items"]!.AsArray().Any(c => c!["id"]!.GetValue<Guid>() == articleId)) return true;
            cursor = feed["nextCursor"]?.GetValue<string>();
            if (cursor is null) return false;
        }
        return false;
    }

    private static async Task<List<JsonObject>> AllPagesAsync(HttpClient client, string url)
    {
        var items = new List<JsonObject>();
        string? cursor = null;
        for (var page = 0; page < 500; page++)
        {
            var body = await client.GetAsync(url + (cursor is null ? "" : $"&cursor={cursor}"), Ct).OkJsonAsync();
            items.AddRange(body["items"]!.AsArray().Select(i => i!.AsObject()));
            cursor = body["nextCursor"]?.GetValue<string>();
            if (cursor is null) return items;
        }
        throw new InvalidOperationException("Too many pages.");
    }

    private static async Task<JsonObject?> CaseItemOrNullAsync(HttpClient moderator, string type, Guid id)
    {
        var response = await moderator.GetAsync($"/api/v1/moderation/reports/{type}/{id}", Ct);
        return response.StatusCode == HttpStatusCode.NotFound ? null : (await response.Content.ReadFromJsonAsync<JsonObject>(Ct))!["item"]!.AsObject();
    }

    /// <summary>A signed-in user with <c>moderation.manage</c> but not <c>users.suspend</c> (a role made for this test).</summary>
    private async Task<SignedInUser> TriageModeratorAsync()
    {
        var roleId = await InDbAsync(async db =>
        {
            var role = new Role($"Triage {Guid.NewGuid():N}"[..20], "Test only: moderation without suspending.");
            db.Roles.Add(role);
            await db.SaveChangesAsync(Ct);
            string[] codes = [Permissions.Articles.Read, Permissions.Moderation.Manage];
            role.SetPermissions(await db.Permissions.Where(p => codes.Contains(p.Code)).Select(p => p.Id).ToListAsync(Ct));
            await db.SaveChangesAsync(Ct);
            return role.Id;
        });
        return await UserWithRoleAsync(roleId, "Triage");
    }

    /// <summary>A new user with <paramref name="roleId"/>, e.g. each test's own moderator: the <c>writes</c> limit is per user.</summary>
    private async Task<SignedInUser> UserWithRoleAsync(Guid roleId, string displayName)
    {
        var user = await api.UserAsync(displayName);
        await InScopeAsync(async services =>
        {
            var db = services.GetRequiredService<AppDbContext>();
            (await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == user.Id, Ct)).GrantRole(roleId);
            await db.SaveChangesAsync(Ct);
            await services.GetRequiredService<IUserAccessService>().InvalidateAsync(user.Id, Ct);
        });
        return user;
    }

    /// <summary>One run of the notification push job (F17) at <paramref name="utcNow"/>, with <paramref name="sender"/>.</summary>
    private async Task<NotificationPushRunResult> PushAsync(IPushSender sender, DateTime utcNow)
    {
        await using var scope = api.Services.CreateAsyncScope();
        var pusher = new NotificationPusher(scope.ServiceProvider.GetRequiredService<IAppDbContext>(), sender, NullLogger<NotificationPusher>.Instance);
        return await pusher.RunAsync(utcNow, Ct);
    }

    private async Task<T> InDbAsync<T>(Func<AppDbContext, Task<T>> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    private async Task InScopeAsync(Func<IServiceProvider, Task> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await work(scope.ServiceProvider);
    }

    /// <summary>FCM unreachable: the notice push must swallow it.</summary>
    private sealed class FailingPushSender : IPushSender
    {
        public Task<IReadOnlyList<PushOutcome>> SendAsync(IReadOnlyList<PushNotification> notifications, CancellationToken cancellationToken = default) =>
            throw new HttpRequestException("FCM is down.");
    }
}
