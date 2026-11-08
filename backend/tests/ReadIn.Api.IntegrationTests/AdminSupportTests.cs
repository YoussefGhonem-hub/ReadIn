using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Domain.Identity;
using ReadIn.Infrastructure.Persistence.Outbox;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F35 Help &amp; support, the console's side: the queue (order, filters, search), a ticket's page, replies and internal
/// notes, closing, reopening and the category, with their audit entries; and the two notifications, <c>support_reply</c>
/// to the member and <c>support_ticket</c> to support staff, with their settings; the badge and a user's page.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AdminSupportTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static string Tag() => $"Tk{Guid.NewGuid():N}"[..12];

    /// <summary>
    /// Opens a ticket as <paramref name="member"/> through the member route (multipart). The ticket is saved inside the
    /// per-member lock's transaction; the outbox is signalled when that transaction commits, so the <c>support_ticket</c>
    /// entries are there when the request returns, with no extra outbox run.
    /// </summary>
    private static Task<JsonObject> OpenAsync(HttpClient member, string subject, string category = "account") =>
        PostTicketAsync(member, subject, category);

    private static async Task<JsonObject> PostTicketAsync(HttpClient member, string subject, string category)
    {
        using var form = new MultipartFormDataContent
        {
            { new StringContent(category), "category" },
            { new StringContent(subject), "subject" },
            { new StringContent("I can't sign in since yesterday, please help."), "message" },
            { new StringContent("ios"), "platform" },
            { new StringContent("iOS 18.1"), "osVersion" },
            { new StringContent("1.2.0+57"), "appVersion" },
            { new StringContent("en"), "language" },
            { new StringContent("/settings/support"), "screen" },
        };
        var response = await member.PostAsync("/api/v1/support/tickets", form, Ct);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    private static Task<HttpResponseMessage> ReplyAsync(HttpClient admin, Guid ticketId, string body, bool @internal = false) =>
        admin.PostAsJsonAsync($"/api/v1/admin/support/tickets/{ticketId}/messages", new { body, @internal }, Ct);

    private static Task<HttpResponseMessage> PatchAsync(HttpClient admin, Guid ticketId, object body) =>
        admin.PatchAsJsonAsync($"/api/v1/admin/support/tickets/{ticketId}", body, Ct);

    /// <summary>The caller's notification entries about the ticket.</summary>
    private static async Task<List<JsonObject>> EntriesAsync(HttpClient client, Guid ticketId) =>
        [.. (await client.GetAsync("/api/v1/me/notifications?limit=50", Ct).OkJsonAsync())["items"]!.AsArray()
            .Select(n => n!.AsObject())
            .Where(n => n["data"]?["ticketId"]?.GetValue<Guid>() == ticketId)];

    [Fact]
    public async Task Every_admin_ticket_route_is_for_support_staff_only()
    {
        var member = await api.UserAsync("Ticket Owner");
        var id = (await OpenAsync(member.Client, $"Guarded {Tag()}"))["id"]!.GetValue<Guid>();

        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/support/tickets");
        await api.AssertAdminOnlyAsync(HttpMethod.Get, $"/api/v1/admin/support/tickets/{id}");
        await api.AssertAdminOnlyAsync(HttpMethod.Post, $"/api/v1/admin/support/tickets/{id}/messages", new { body = "Hi", @internal = false });
        await api.AssertAdminOnlyAsync(HttpMethod.Patch, $"/api/v1/admin/support/tickets/{id}", new { status = "closed" });
        // The owner is a Member too: the console's routes are closed to them as well.
        await member.Client.GetAsync($"/api/v1/admin/support/tickets/{id}", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
    }

    [Fact]
    public async Task The_queue_shows_open_tickets_waiting_longest_first_with_filters_and_search()
    {
        var admin = await api.SuperAdminAsync();
        var tag = Tag();
        var first = await api.UserAsync($"Waiting {tag}");
        var second = await api.UserAsync("Second Member");
        var older = await OpenAsync(first.Client, $"Login problem {tag}");
        var newer = await OpenAsync(second.Client, $"Idea {tag}", category: "suggestion");

        async Task<List<Guid>> IdsAsync(string query) =>
            [.. (await admin.Client.GetAsync($"/api/v1/admin/support/tickets?{query}", Ct).OkJsonAsync()).PageItems()
                .Select(r => r!["id"]!.GetValue<Guid>())];

        var olderId = older["id"]!.GetValue<Guid>();
        var newerId = newer["id"]!.GetValue<Guid>();
        (await IdsAsync($"q={tag}")).Should().Equal(olderId, newerId);
        (await IdsAsync($"q={tag}&category=suggestion")).Should().Equal(newerId);
        (await IdsAsync($"q=%23{older["number"]!.GetValue<int>()}")).Should().Equal(olderId);
        (await IdsAsync($"q={Uri.EscapeDataString($"Waiting {tag}")}")).Should().Equal([olderId], "the member's name finds their tickets");

        var row = (await admin.Client.GetAsync($"/api/v1/admin/support/tickets?q={tag}", Ct).OkJsonAsync()).PageItems()[0]!.AsObject();
        row.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "number", "category", "subject", "status", "user", "createdAt", "waitingSince", "lastMessage", "closedAt");
        (row["status"]!.GetValue<string>(), row["user"]!["id"]!.GetValue<Guid>()).Should().Be(("open", first.Id));
        row["waitingSince"]!.GetValue<DateTime>().Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(5));
        row["lastMessage"]!["fromSupport"]!.GetValue<bool>().Should().BeFalse();

        // Answered: out of the open tab, into the answered one.
        (await ReplyAsync(admin.Client, olderId, "We're on it.")).StatusCode.Should().Be(HttpStatusCode.Created);
        (await IdsAsync($"q={tag}")).Should().Equal(newerId);
        (await IdsAsync($"q={tag}&status=answered")).Should().Equal(olderId);
        (await IdsAsync($"q={tag}&status=closed")).Should().BeEmpty();

        var badStatus = await admin.Client.GetAsync("/api/v1/admin/support/tickets?status=waiting", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        badStatus["errors"]!["status"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.invalid");
        var badCategory = await admin.Client.GetAsync("/api/v1/admin/support/tickets?category=bugs", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        badCategory["errors"]!["category"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("support.category_invalid");
    }

    [Fact]
    public async Task A_reply_answers_the_ticket_tells_the_member_and_their_answer_tells_support()
    {
        var admin = await api.SuperAdminAsync("Support Agent");
        var member = await api.UserAsync("Needs Help");
        var ticket = await OpenAsync(member.Client, $"Sign in {Tag()}");
        var id = ticket["id"]!.GetValue<Guid>();
        var number = ticket["number"]!.GetValue<int>();

        // The new ticket told support staff: actor = the member, the console's link.
        var staffEntry = (await EntriesAsync(admin.Client, id)).Single();
        (staffEntry["type"]!.GetValue<string>(), staffEntry["actor"]!["id"]!.GetValue<Guid>()).Should().Be(("support_ticket", member.Id));
        staffEntry["link"]!.GetValue<string>().Should().Be($"readin://admin/support/{id}");
        staffEntry["data"]!["ticketNumber"]!.GetValue<int>().Should().Be(number);

        var reply = await ReplyAsync(admin.Client, id, "  Try resetting your password from Settings.  ").OkOrCreatedAsync();
        reply.Select(p => p.Key).Should().BeEquivalentTo("id", "fromSupport", "body", "attachments", "createdAt", "isInternalNote", "author");
        (reply["fromSupport"]!.GetValue<bool>(), reply["isInternalNote"]!.GetValue<bool>()).Should().Be((true, false));
        reply["body"]!.GetValue<string>().Should().Be("Try resetting your password from Settings.");
        reply["author"]!["id"]!.GetValue<Guid>().Should().Be(admin.Id);

        var page = await admin.Client.GetAsync($"/api/v1/admin/support/tickets/{id}", Ct).OkJsonAsync();
        page["status"]!.GetValue<string>().Should().Be("answered");
        page["device"]!["platform"]!.GetValue<string>().Should().Be("ios");
        page["member"]!["ticketCount"]!.GetValue<int>().Should().Be(1);
        page["messages"]!.AsArray().Select(m => m!["fromSupport"]!.GetValue<bool>()).Should().Equal(false, true);
        page["reportsFiled"]!["total"]!.GetValue<int>().Should().Be(0);
        page["moderation"]!.AsArray().Should().BeEmpty();

        // The member: one support_reply, support stays anonymous.
        var memberEntry = (await EntriesAsync(member.Client, id)).Single();
        memberEntry["type"]!.GetValue<string>().Should().Be("support_reply");
        memberEntry["actor"].Should().BeNull();
        memberEntry["link"]!.GetValue<string>().Should().Be($"readin://support/{id}");
        memberEntry["data"]!["subject"]!.GetValue<string>().Should().Be(ticket["subject"]!.GetValue<string>());
        memberEntry["data"]!.AsObject().ContainsKey("closed").Should().BeFalse();
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.TicketReplied && a.TargetId == id && a.UserId == member.Id, Ct)))
            .Should().Be(1);

        // A second reply joins the member's unread entry.
        (await ReplyAsync(admin.Client, id, "Did that work?")).StatusCode.Should().Be(HttpStatusCode.Created);
        (await EntriesAsync(member.Client, id)).Should().ContainSingle();

        // The member answers: Open again, and support's entry for the ticket moves up (still one).
        using var form = new MultipartFormDataContent { { new StringContent("Still can't."), "message" } };
        (await member.Client.PostAsync($"/api/v1/support/tickets/{id}/messages", form, Ct)).StatusCode.Should().Be(HttpStatusCode.Created);
        (await admin.Client.GetAsync($"/api/v1/admin/support/tickets/{id}", Ct).OkJsonAsync())["status"]!.GetValue<string>().Should().Be("open");
        (await EntriesAsync(admin.Client, id)).Should().ContainSingle().Which["actorCount"]!.GetValue<int>().Should().Be(1);
    }

    [Fact]
    public async Task An_internal_note_is_for_admins_only_and_tells_nobody()
    {
        var admin = await api.SuperAdminAsync();
        var member = await api.UserAsync("Note Subject");
        var id = (await OpenAsync(member.Client, $"Notes {Tag()}"))["id"]!.GetValue<Guid>();

        var note = await ReplyAsync(admin.Client, id, "Checked the logs: a lockout.", @internal: true).OkOrCreatedAsync();
        note["isInternalNote"]!.GetValue<bool>().Should().BeTrue();

        var page = await admin.Client.GetAsync($"/api/v1/admin/support/tickets/{id}", Ct).OkJsonAsync();
        page["status"]!.GetValue<string>().Should().Be("open", "a note changes nothing");
        page["messages"]!.AsArray().Select(m => m!["isInternalNote"]!.GetValue<bool>()).Should().Equal(false, true);
        page["lastMessage"]!["isInternalNote"]!.GetValue<bool>().Should().BeTrue();

        var mine = await member.Client.GetAsync($"/api/v1/support/tickets/{id}", Ct).OkJsonAsync();
        mine["messages"]!.AsArray().Should().ContainSingle("the member never sees a note");
        mine.ToJsonString().Should().NotContain("Checked the logs");
        (await EntriesAsync(member.Client, id)).Should().BeEmpty();
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.TicketNoteAdded && a.TargetId == id, Ct))).Should().Be(1);
    }

    [Fact]
    public async Task Support_closes_reopens_and_recategorizes_with_the_member_told_about_the_close()
    {
        var admin = await api.SuperAdminAsync();
        var member = await api.UserAsync("Closed Ticket");
        var id = (await OpenAsync(member.Client, $"Close me {Tag()}"))["id"]!.GetValue<Guid>();

        var closed = await PatchAsync(admin.Client, id, new { status = "closed" }).OkJsonAsync();
        (closed["status"]!.GetValue<string>(), closed["closedBy"]!.GetValue<string>()).Should().Be(("closed", "support"));
        closed["closedAt"].Should().NotBeNull();
        var entry = (await EntriesAsync(member.Client, id)).Single();
        (entry["type"]!.GetValue<string>(), entry["data"]!["closed"]!.GetValue<bool>()).Should().Be(("support_reply", true));

        // Closed: no reply until reopened; a note still works. Closing again changes nothing.
        await ReplyAsync(admin.Client, id, "One more thing").ProblemAsync(HttpStatusCode.Conflict, "support.ticket_closed");
        (await ReplyAsync(admin.Client, id, "Closed after the fix.", @internal: true)).StatusCode.Should().Be(HttpStatusCode.Created);
        await PatchAsync(admin.Client, id, new { status = "closed" }).OkJsonAsync();
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.TicketClosed && a.TargetId == id, Ct))).Should().Be(1);

        var reopened = await PatchAsync(admin.Client, id, new { status = "open" }).OkJsonAsync();
        (reopened["status"]!.GetValue<string>(), reopened["closedBy"]).Should().Be(("open", (JsonNode?)null));
        var moved = await PatchAsync(admin.Client, id, new { category = "verification" }).OkJsonAsync();
        moved["category"]!.GetValue<string>().Should().Be("verification");
        (await api.InDbAsync(db => db.AuditLogs.Where(a => a.Action == AuditActions.TicketCategoryChanged && a.TargetId == id)
            .Select(a => a.Details).SingleAsync(Ct))).Should().Be("account → verification");
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(a => a.Action == AuditActions.TicketReopened && a.TargetId == id, Ct))).Should().Be(1);

        var none = await PatchAsync(admin.Client, id, new { }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        none["errors"]!["status"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.required");
        (await PatchAsync(admin.Client, id, new { status = "answered" }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))
            ["errors"]!["status"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.invalid");
        (await PatchAsync(admin.Client, id, new { category = "bugs" }).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))
            ["errors"]!["category"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("support.category_invalid");
        (await ReplyAsync(admin.Client, id, "   ").ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))
            ["errors"]!["body"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.required");
        (await ReplyAsync(admin.Client, id, new string('x', 2001)).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))
            ["errors"]!["body"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.max_length");

        var unknown = Guid.NewGuid();
        await admin.Client.GetAsync($"/api/v1/admin/support/tickets/{unknown}", Ct).ProblemAsync(HttpStatusCode.NotFound, "support.ticket_not_found");
        await ReplyAsync(admin.Client, unknown, "Hello").ProblemAsync(HttpStatusCode.NotFound, "support.ticket_not_found");
        await PatchAsync(admin.Client, unknown, new { status = "closed" }).ProblemAsync(HttpStatusCode.NotFound, "support.ticket_not_found");
    }

    [Fact]
    public async Task New_tickets_are_a_setting_of_support_staff_only()
    {
        var admin = await api.SuperAdminAsync();
        var member = await api.UserAsync("Settings Member");

        (await admin.Client.GetAsync("/api/v1/me/notification-settings", Ct).OkJsonAsync())["types"]!.AsObject()
            .Select(t => t.Key).Should().Contain("support_ticket").And.Contain("report_new").And.HaveCount(12); // report_new: F22
        (await member.Client.GetAsync("/api/v1/me/notification-settings", Ct).OkJsonAsync())["types"]!.AsObject()
            .Select(t => t.Key).Should().NotContain("support_ticket").And.NotContain("support_reply").And.HaveCount(10);
        foreach (var type in new[] { "support_ticket", "support_reply" })
        {
            await member.Client.PutAsJsonAsync("/api/v1/me/notification-settings", new { types = new Dictionary<string, string> { [type] = "off" } }, Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "notification.type_invalid");
        }
        await admin.Client.PutAsJsonAsync("/api/v1/me/notification-settings", new { types = new Dictionary<string, string> { ["support_reply"] = "off" } }, Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "notification.type_invalid");

        // Turned off: a new ticket writes nothing for this admin.
        (await admin.Client.PutAsJsonAsync("/api/v1/me/notification-settings",
            new { types = new Dictionary<string, string> { ["support_ticket"] = "off" } }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var id = (await OpenAsync(member.Client, $"Quiet {Tag()}"))["id"]!.GetValue<Guid>();
        (await EntriesAsync(admin.Client, id)).Should().BeEmpty();
    }

    [Fact]
    public async Task The_badge_counts_open_tickets_and_a_users_page_lists_theirs()
    {
        var admin = await api.SuperAdminAsync();
        var member = await api.UserAsync("Badge Member");
        async Task<int> OpenTicketsAsync() =>
            (await admin.Client.GetAsync("/api/v1/admin/summary", Ct).OkJsonAsync())["openTickets"]!.GetValue<int>();

        var before = await OpenTicketsAsync();
        var id = (await OpenAsync(member.Client, $"Badge {Tag()}"))["id"]!.GetValue<Guid>();
        (await OpenTicketsAsync()).Should().Be(before + 1);
        (await ReplyAsync(admin.Client, id, "Answered.")).StatusCode.Should().Be(HttpStatusCode.Created);
        (await OpenTicketsAsync()).Should().Be(before, "an answered ticket waits for the member, not for support");

        var userPage = await admin.Client.GetAsync($"/api/v1/admin/users/{member.Id}", Ct).OkJsonAsync();
        userPage["tickets"]!["total"]!.GetValue<int>().Should().Be(1);
        var row = userPage["tickets"]!["items"]!.AsArray().Single()!;
        (row["id"]!.GetValue<Guid>(), row["status"]!.GetValue<string>()).Should().Be((id, "answered"));
    }
}

