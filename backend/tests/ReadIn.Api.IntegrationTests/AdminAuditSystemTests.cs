using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Admin;
using ReadIn.Domain.Identity;
using ReadIn.Infrastructure.Jobs;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// The admin console's audit log (<c>audit.read</c>) and system page (<c>system.settings</c>), SPEC F23, against SQL Server:
/// the two logs merged, filters, paging and IP addresses only with <c>users.read.pii</c>; the API, database, Firebase, job
/// runs, push results and storage; the counters rebuild in the audit log; the daily cleanup.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AdminAuditSystemTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    // ---- Audit log ----

    [Fact]
    public async Task The_audit_log_is_for_audit_read_only()
    {
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/audit");
        var auditor = await api.UserWithPermissionsAsync("Auditor", "audit.read");
        (await auditor.Client.GetAsync("/api/v1/admin/audit", Ct).OkJsonAsync()).PageItems();
        // The system page is another permission.
        await auditor.Client.GetAsync("/api/v1/admin/system", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
    }

    [Fact]
    public async Task Both_logs_come_together_newest_first_without_the_audit_copies_of_moderation()
    {
        var admin = await api.SuperAdminAsync();
        var member = await api.UserAsync("Audited Member");
        (await admin.Client.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "warn", targetType = "user", targetId = member.Id, note = "Be kind." }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await admin.Client.PostAsync($"/api/v1/admin/users/{member.Id}/reset-password", null, Ct)).StatusCode.Should().Be(HttpStatusCode.OK);

        var page = await admin.Client.GetAsync($"/api/v1/admin/audit?actor={admin.Id}", Ct).OkJsonAsync();
        var items = page.PageItems();
        items.Select(i => i!["action"]!.GetValue<string>()).Should().Equal("admin.password_reset", "user.warn");
        page["totalCount"]!.GetValue<int>().Should().Be(2, "moderation.user_warned repeats the moderation log's user.warn");

        var reset = items[0]!.AsObject();
        reset.Select(p => p.Key).Should().BeEquivalentTo("id", "source", "action", "actor", "targetUser", "target", "details", "ip", "createdAt");
        reset["source"]!.GetValue<string>().Should().Be("audit");
        reset["actor"]!["id"]!.GetValue<Guid>().Should().Be(admin.Id);
        reset["actor"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("id", "displayName", "username", "avatarUrl");
        reset["targetUser"]!["id"]!.GetValue<Guid>().Should().Be(member.Id);
        reset["target"].Should().BeNull();

        var warn = items[1]!.AsObject();
        warn["source"]!.GetValue<string>().Should().Be("moderation");
        warn["target"]!["type"]!.GetValue<string>().Should().Be("user");
        warn["target"]!["id"]!.GetValue<Guid>().Should().Be(member.Id);
        warn["target"]!["label"]!.GetValue<string>().Should().Be($"@{member.Me["username"]!.GetValue<string>()}");
        warn["details"]!.GetValue<string>().Should().Be("Be kind.");
        warn["ip"].Should().BeNull();
    }

    [Fact]
    public async Task Filters_narrow_the_log_and_bad_values_are_refused()
    {
        var admin = await api.SuperAdminAsync();
        var member = await api.UserAsync("Filtered Member");
        (await admin.Client.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "warn", targetType = "user", targetId = member.Id, note = "Again." }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await admin.Client.PostAsync($"/api/v1/admin/users/{member.Id}/reset-password", null, Ct)).StatusCode.Should().Be(HttpStatusCode.OK);

        async Task<List<string>> ActionsAsync(string query) =>
            [.. (await admin.Client.GetAsync($"/api/v1/admin/audit?{query}", Ct).OkJsonAsync()).PageItems().Select(i => i!["action"]!.GetValue<string>())];

        // The member's sign-up, the reset (audit) and the warning (moderation log; its audit copy is left out).
        var all = await ActionsAsync($"target={member.Id}");
        all.Should().Equal("admin.password_reset", "user.warn", "auth.sign_up");
        (await ActionsAsync($"target={member.Id}&source=audit")).Should().Equal("admin.password_reset", "auth.sign_up");
        (await ActionsAsync($"target={member.Id}&source=moderation")).Should().Equal("user.warn");
        (await ActionsAsync($"target={member.Id}&action=admin.")).Should().Equal("admin.password_reset");
        (await ActionsAsync($"target={member.Id}&action=user.warn")).Should().Equal("user.warn");
        (await ActionsAsync($"actor={admin.Id}&action=admin.password_reset")).Should().Equal("admin.password_reset");

        var later = DateTime.UtcNow.AddDays(3).ToString("yyyy-MM-dd");
        (await ActionsAsync($"target={member.Id}&from={DateTime.UtcNow.AddDays(-1):yyyy-MM-dd}&to={later}")).Should().Equal(all);
        (await ActionsAsync($"target={member.Id}&from={later}")).Should().BeEmpty();
        (await ActionsAsync($"target={member.Id}&to={DateTime.UtcNow.AddDays(-3):yyyy-MM-dd}")).Should().BeEmpty();

        // Offset pages: one row a page.
        var first = await admin.Client.GetAsync($"/api/v1/admin/audit?target={member.Id}&pageSize=1", Ct).OkJsonAsync();
        var second = await admin.Client.GetAsync($"/api/v1/admin/audit?target={member.Id}&pageSize=1&page=2", Ct).OkJsonAsync();
        (first["totalCount"]!.GetValue<int>(), first["totalPages"]!.GetValue<int>(), first["pageSize"]!.GetValue<int>()).Should().Be((3, 3, 1));
        first.PageItems()[0]!["id"]!.GetValue<Guid>().Should().NotBe(second.PageItems()[0]!["id"]!.GetValue<Guid>());
        (await admin.Client.GetAsync($"/api/v1/admin/audit?target={member.Id}&page=9", Ct).OkJsonAsync()).PageItems().Should().BeEmpty();

        foreach (var (query, parameter) in new[]
                 {
                     ("actor=not-a-guid", "actor"), ("target=42", "target"), ("from=2026-13-01", "from"), ("to=yesterday", "to"),
                     ("source=everything", "source"), ($"action={new string('a', 65)}", "action"),
                 })
        {
            var problem = await admin.Client.GetAsync($"/api/v1/admin/audit?{query}", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
            problem["errors"]![parameter]!.AsArray().Select(c => c!.GetValue<string>()).Should().Equal("validation.invalid");
        }
    }

    [Fact]
    public async Task Ip_addresses_show_only_with_users_read_pii_and_targets_are_named()
    {
        var admin = await api.SuperAdminAsync();
        var auditor = await api.UserWithPermissionsAsync("Plain Auditor", "audit.read");
        var actor = await api.UserAsync("Audited Actor");
        var field = await api.InDbAsync(db => db.Fields.Where(f => f.IsEnabled).Select(f => new { f.Id, f.NameEn }).FirstAsync(Ct));
        await api.InDbAsync(async db =>
        {
            db.AuditLogs.Add(AuditLog.Record(AuditActions.FieldUpdated, actor.Id, null, "203.0.113.9", DateTime.UtcNow, AuditTargets.Field, field.Id,
                "nameEn"));
            await db.SaveChangesAsync(Ct);
        });

        var seen = (await admin.Client.GetAsync($"/api/v1/admin/audit?actor={actor.Id}", Ct).OkJsonAsync()).PageItems().Single()!;
        seen["ip"]!.GetValue<string>().Should().Be("203.0.113.9");
        seen["target"]!["type"]!.GetValue<string>().Should().Be("field");
        seen["target"]!["id"]!.GetValue<Guid>().Should().Be(field.Id);
        seen["target"]!["label"]!.GetValue<string>().Should().Be(field.NameEn);
        seen["details"]!.GetValue<string>().Should().Be("nameEn");

        var masked = (await auditor.Client.GetAsync($"/api/v1/admin/audit?actor={actor.Id}", Ct).OkJsonAsync()).PageItems().Single()!;
        masked["ip"].Should().BeNull("only users.read.pii sees IP addresses");
    }

    // ---- System ----

    [Fact]
    public async Task The_system_page_is_for_system_settings_only_and_reads_the_running_system()
    {
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/system");
        var admin = await api.SuperAdminAsync();

        var system = await admin.Client.GetAsync("/api/v1/admin/system", Ct).OkJsonAsync();
        system.Select(p => p.Key).Should().BeEquivalentTo("api", "updatePolicy", "database", "firebase", "jobs", "push", "storage");
        system["api"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("version", "startedAt", "environment");
        system["api"]!["environment"]!.GetValue<string>().Should().Be("Testing");
        system["api"]!["startedAt"]!.GetValue<DateTime>().Should().BeBefore(DateTime.UtcNow);
        system["updatePolicy"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("ios", "android");
        system["database"]!["reachable"]!.GetValue<bool>().Should().BeTrue();
        system["database"]!["latencyMs"]!.GetValue<int>().Should().BeGreaterThanOrEqualTo(0);
        system["firebase"]!["messagingConfigured"]!.GetValue<bool>().Should().BeFalse("FCM has no emulator");
        var realtime = system["firebase"]!["realtimeConfigured"]!.GetValue<bool>();
        (system["firebase"]!["realtimeReachable"] is null).Should().Be(!realtime);
        system["storage"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("uploadsBytes", "uploadsFiles", "privateBytes", "privateFiles", "measuredAt");
        system["storage"]!["uploadsBytes"]!.GetValue<long>().Should().BeGreaterThanOrEqualTo(0);
        system["push"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("sent", "failed", "invalidTokens", "since");

        // Hangfire is off in tests: every job the API registers is listed, A–Z, with its schedule.
        var jobs = system["jobs"]!.AsArray().Select(j => j!.AsObject()).ToList();
        jobs.Select(j => j["id"]!.GetValue<string>()).Should().Contain(RecurringJobCatalog.All.Select(j => j.Id)).And.BeInAscendingOrder(StringComparer.Ordinal);
        var cleanup = jobs.Single(j => j["id"]!.GetValue<string>() == "admin-cleanup");
        cleanup.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "schedule", "lastRunAt", "lastSucceeded", "lastDurationMs", "lastError", "runs24h", "failures24h");
        cleanup["schedule"]!.GetValue<string>().Should().Be("50 3 * * *");
    }

    [Fact]
    public async Task Job_runs_give_the_last_run_and_the_runs_and_failures_of_the_last_24_hours()
    {
        var admin = await api.SuperAdminAsync();
        var job = $"test-job-{Guid.NewGuid():N}"[..20];
        var now = DateTime.UtcNow;
        await api.InDbAsync(async db =>
        {
            db.JobRuns.Add(new JobRun(job, now.AddHours(-30), 50, true, null));
            db.JobRuns.Add(new JobRun(job, now.AddHours(-2), 120, true, null));
            await db.SaveChangesAsync(Ct);
        });
        // The Hangfire filter's write, as a failed run of a job enqueued on demand would be recorded.
        var recorder = ActivatorUtilities.CreateInstance<JobRunRecorder>(api.Services);
        recorder.Record(job, typeof(OutboxJob), now.AddHours(-1), 340, new InvalidOperationException("wrapper", new TimeoutException("Too slow.")));
        recorder.Record(null, typeof(NotificationPushJob), now.AddMinutes(-1), 5, null);
        recorder.Record(null, typeof(string), now, 1, null); // not a recurring job: not recorded

        var jobs = (await admin.Client.GetAsync("/api/v1/admin/system", Ct).OkJsonAsync())["jobs"]!.AsArray().Select(j => j!.AsObject()).ToList();
        var mine = jobs.Single(j => j["id"]!.GetValue<string>() == job);
        mine["schedule"]!.GetValue<string>().Should().BeEmpty("it isn't registered");
        (mine["runs24h"]!.GetValue<int>(), mine["failures24h"]!.GetValue<int>()).Should().Be((2, 1));
        mine["lastSucceeded"]!.GetValue<bool>().Should().BeFalse();
        mine["lastDurationMs"]!.GetValue<int>().Should().Be(340);
        mine["lastError"]!.GetValue<string>().Should().Be("TimeoutException: Too slow.");
        mine["lastRunAt"]!.GetValue<DateTime>().Should().BeCloseTo(now.AddHours(-1), TimeSpan.FromSeconds(1));

        var push = jobs.Single(j => j["id"]!.GetValue<string>() == "notification-push");
        push["lastSucceeded"]!.GetValue<bool>().Should().BeTrue();
        push["runs24h"]!.GetValue<int>().Should().BeGreaterThanOrEqualTo(1);
        (await api.InDbAsync(db => db.JobRuns.CountAsync(r => r.Job == "System.String", Ct))).Should().Be(0);
    }

    [Fact]
    public async Task Every_push_send_is_counted_for_the_last_24_hours()
    {
        var admin = await api.SuperAdminAsync();
        async Task<JsonNode> PushAsync() => (await admin.Client.GetAsync("/api/v1/admin/system", Ct).OkJsonAsync())["push"]!;
        var before = await PushAsync();

        // The API's sender (wrapped by the recorder): the logging sender in tests, which delivers to every device.
        await api.InScopeAsync(async services =>
        {
            var push = new PushNotification(["t1", "t2", "t3"], "Title", "Body", new Dictionary<string, string> { ["type"] = "announcement" },
                "announcement", TimeSpan.FromHours(1));
            await services.GetRequiredService<IPushSender>().SendAsync([push], Ct);
        });

        var after = await PushAsync();
        (after["sent"]!.GetValue<int>() - before["sent"]!.GetValue<int>()).Should().Be(3);
        after["failed"]!.GetValue<int>().Should().Be(before["failed"]!.GetValue<int>());
        after["since"]!.GetValue<DateTime>().Should().BeCloseTo(DateTime.UtcNow.AddHours(-24), TimeSpan.FromHours(1));
    }

    [Fact]
    public async Task Rebuilding_the_counters_is_audited()
    {
        var admin = await api.SuperAdminAsync();
        var count = (await admin.Client.PostAsync("/api/v1/admin/realtime/rebuild-counters", null, Ct).OkJsonAsync())["articleCount"]!.GetValue<int>();

        var entry = await api.InDbAsync(db => db.AuditLogs.SingleAsync(a => a.Action == AuditActions.CountersRebuilt && a.ActorId == admin.Id, Ct));
        entry.Details.Should().Be($"{count} articles");
        entry.UserId.Should().BeNull();
    }

    [Fact]
    public async Task The_daily_cleanup_deletes_old_misses_job_runs_and_push_results()
    {
        var now = DateTime.UtcNow;
        var hourAgo = new DateTime(now.Year, now.Month, now.Day, now.Hour, 0, 0, DateTimeKind.Utc).AddHours(-1);
        var oldHour = hourAgo.AddDays(-8);
        var query = $"miss-{Guid.NewGuid():N}";
        await api.InDbAsync(async db =>
        {
            db.SearchMisses.Add(new SearchMiss(DateOnly.FromDateTime(now.AddDays(-91)), "en", query, 3));
            db.SearchMisses.Add(new SearchMiss(DateOnly.FromDateTime(now.AddDays(-89)), "en", query, 2));
            db.JobRuns.Add(new JobRun("cleanup-test", now.AddDays(-8), 1, true, null));
            db.JobRuns.Add(new JobRun("cleanup-test", now.AddDays(-6), 1, true, null));
            if (!await db.PushDeliveryStats.AnyAsync(s => s.Hour == oldHour, Ct)) db.PushDeliveryStats.Add(new PushDeliveryStat(oldHour, 1, 0, 0));
            await db.SaveChangesAsync(Ct);
        });

        await api.InScopeAsync(services => services.GetRequiredService<AdminCleanupJob>().RunAsync(Ct));

        (await api.InDbAsync(db => db.SearchMisses.Where(m => m.Query == query).Select(m => m.Count).ToListAsync(Ct))).Should().Equal(2);
        (await api.InDbAsync(db => db.JobRuns.CountAsync(r => r.Job == "cleanup-test", Ct))).Should().Be(1);
        (await api.InDbAsync(db => db.PushDeliveryStats.AnyAsync(s => s.Hour == oldHour, Ct))).Should().BeFalse();
    }
}
