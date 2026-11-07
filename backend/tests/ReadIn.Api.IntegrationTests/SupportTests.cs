using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Support;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F35 Help & support, the member's side against SQL Server: the public config, sending a ticket with screenshots (by their
/// bytes, stored privately), the limits, My tickets, the conversation without internal notes, the statuses, closing and
/// reopening, the private screenshots and deleting an account with tickets.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class SupportTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static byte[] Fixture(string name) => File.ReadAllBytes(Path.Combine(AppContext.BaseDirectory, "fixtures", "media", name));

    private static MultipartFormDataContent Form(
        string? category = "app_problem", string? subject = "The reader crashes", string? message = "It crashes when I open a PDF attachment.",
        IEnumerable<(byte[] Bytes, string Name, string ContentType)>? screenshots = null, IDictionary<string, string>? extra = null)
    {
        var form = new MultipartFormDataContent();
        if (category is not null) form.Add(new StringContent(category), "category");
        if (subject is not null) form.Add(new StringContent(subject), "subject");
        if (message is not null) form.Add(new StringContent(message), "message");
        foreach (var (key, value) in extra ?? new Dictionary<string, string>()) form.Add(new StringContent(value), key);
        foreach (var (bytes, name, contentType) in screenshots ?? [])
        {
            var file = new ByteArrayContent(bytes);
            file.Headers.ContentType = new MediaTypeHeaderValue(contentType);
            form.Add(file, "screenshots", name);
        }
        return form;
    }

    private static Task<HttpResponseMessage> CreateAsync(HttpClient client, MultipartFormDataContent form) =>
        client.PostAsync("/api/v1/support/tickets", form, Ct);

    private static async Task<JsonObject> CreatedAsync(HttpClient client, MultipartFormDataContent? form = null)
    {
        var response = await CreateAsync(client, form ?? Form());
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        return JsonNode.Parse(body)!.AsObject();
    }

    private Task<T> InDbAsync<T>(Func<Infrastructure.Persistence.AppDbContext, Task<T>> work) => api.InDbAsync(work);

    /// <summary>Changes a ticket in the database, as support (F35's admin side) or time would.</summary>
    private Task ChangeTicketAsync(Guid id, Action<SupportTicket> change) => api.InDbAsync(async db =>
    {
        var ticket = await db.SupportTickets.SingleAsync(t => t.Id == id, Ct);
        change(ticket);
        await db.SaveChangesAsync(Ct);
    });

    // ---- Config ----

    [Fact]
    public async Task The_config_is_public_and_lists_the_form_rules()
    {
        var response = await api.GuestClient().GetAsync("/api/v1/support/config", Ct);
        response.Headers.CacheControl!.Public.Should().BeTrue();
        var config = JsonNode.Parse(await response.Content.ReadAsStringAsync(Ct))!.AsObject();

        config.Select(p => p.Key).Should().BeEquivalentTo("email", "categories", "maxAttachments", "maxAttachmentBytes", "attachmentTypes");
        config["email"].Should().BeNull("Support:Email isn't set in the tests");
        config["categories"]!.AsArray().Select(c => c!.GetValue<string>()).Should()
            .Equal("app_problem", "account", "content", "verification", "suggestion", "other");
        (config["maxAttachments"]!.GetValue<int>(), config["maxAttachmentBytes"]!.GetValue<int>()).Should().Be((3, 5 * 1024 * 1024));
        config["attachmentTypes"]!.AsArray().Select(c => c!.GetValue<string>()).Should().Equal("image/jpeg", "image/png", "image/webp");
    }

    // ---- A new ticket ----

    [Fact]
    public async Task A_ticket_with_screenshots_is_open_and_its_files_are_private()
    {
        var member = await api.UserAsync("Ticket Sender");
        var png = Fixture("small.png");
        var webp = Fixture("medium.webp");
        var response = await CreateAsync(member.Client, Form(
            subject: "  The reader crashes  ",
            screenshots: [(png, "Screenshot 1.png", "image/png"), (webp, "shot.jpg", "image/jpeg")],
            extra: new Dictionary<string, string>
            {
                ["platform"] = "Android", ["osVersion"] = "Android 15", ["appVersion"] = "1.2.0+57", ["language"] = "fr", ["screen"] = "/a/rag",
            }));
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        var ticket = JsonNode.Parse(body)!.AsObject();
        var id = ticket["id"]!.GetValue<Guid>();
        response.Headers.Location!.ToString().Should().Be($"/api/v1/support/tickets/{id}");

        ticket.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "number", "category", "subject", "status", "createdAt", "updatedAt", "lastMessage", "closedAt", "canReopen", "device", "messages");
        ticket["number"]!.GetValue<int>().Should().BePositive();
        (ticket["status"]!.GetValue<string>(), ticket["subject"]!.GetValue<string>(), ticket["category"]!.GetValue<string>())
            .Should().Be(("open", "The reader crashes", "app_problem"));
        var device = ticket["device"]!;
        (device["platform"]!.GetValue<string>(), device["osVersion"]!.GetValue<string>(), device["appVersion"]!.GetValue<string>(),
                device["screen"]!.GetValue<string>())
            .Should().Be(("android", "Android 15", "1.2.0+57", "/a/rag"));
        device["language"].Should().BeNull("only ar and en are UI languages");
        var message = ticket["messages"]!.AsArray().Single()!;
        message.AsObject().Select(p => p.Key).Should().BeEquivalentTo("id", "fromSupport", "body", "attachments", "createdAt");
        message["fromSupport"]!.GetValue<bool>().Should().BeFalse();
        var attachments = message["attachments"]!.AsArray();
        attachments.Select(a => a!["contentType"]!.GetValue<string>()).Should()
            .Equal(new[] { "image/png", "image/webp" }, "the bytes decide, never the name or the part's type");
        attachments.Select(a => a!["sizeBytes"]!.GetValue<int>()).Should().Equal(png.Length, webp.Length);
        ticket["lastMessage"]!["excerpt"]!.GetValue<string>().Should().Be("It crashes when I open a PDF attachment.");

        // Stored privately as support/{messageId}/{n}{.ext}, never under /uploads.
        var messageId = message["id"]!.GetValue<Guid>();
        File.ReadAllBytes(Path.Combine(api.PrivatePath, "support", messageId.ToString(), "1.png")).Should().Equal(png);
        File.Exists(Path.Combine(api.PrivatePath, "support", messageId.ToString(), "2.webp")).Should().BeTrue();
        Directory.EnumerateFiles(api.UploadsPath, $"*{messageId}*", SearchOption.AllDirectories).Should().BeEmpty();

        // Only its owner sees it.
        (await member.Client.GetAsync($"/api/v1/support/tickets/{id}", Ct).OkJsonAsync())["id"]!.GetValue<Guid>().Should().Be(id);
        var other = await api.UserAsync("Someone Else");
        await other.Client.GetAsync($"/api/v1/support/tickets/{id}", Ct).ProblemAsync(HttpStatusCode.NotFound, "support.ticket_not_found");
        (await api.GuestClient().GetAsync($"/api/v1/support/tickets/{id}", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await api.GuestClient().PostAsync("/api/v1/support/tickets", Form(), Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Bad_fields_are_validation_errors_and_json_is_unsupported()
    {
        var member = await api.UserAsync("Form Tester");

        var problem = await CreateAsync(member.Client, Form(category: "billing", subject: "Hey", message: "   "))
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        problem["errors"]!["category"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("support.category_invalid");
        problem["errors"]!["subject"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.length");
        problem["errors"]!["message"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.required");

        var tooShort = await CreateAsync(member.Client, Form(message: "Too short"))
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        tooShort["errors"]!["message"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.length");
        await CreateAsync(member.Client, Form(subject: new string('s', 121))).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        await CreateAsync(member.Client, Form(message: new string('m', 2001))).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");

        await member.Client.PostAsJsonAsync("/api/v1/support/tickets", new { category = "other", subject = "Hello there", message = "A message long enough." }, Ct)
            .ProblemAsync(HttpStatusCode.UnsupportedMediaType, "request.unsupported_media_type");
        (await InDbAsync(db => db.SupportTickets.CountAsync(t => t.UserId == member.Id, Ct))).Should().Be(0);
    }

    [Fact]
    public async Task Screenshots_must_be_up_to_three_images_of_at_most_5_MB_by_their_bytes()
    {
        var member = await api.UserAsync("Screenshot Tester");
        var png = Fixture("small.png");

        await CreateAsync(member.Client, Form(screenshots: Enumerable.Repeat((png, "a.png", "image/png"), 4)))
            .ProblemAsync(HttpStatusCode.BadRequest, "support.too_many_attachments");
        var refused = new (byte[], string, string)[]
        {
            (Fixture("sample.heic"), "photo.heic", "image/heic"),
            ([.. "GIF89a"u8, 1, 0, 1, 0, 0, 0, 0, 0], "anim.png", "image/png"),
            (Fixture("normal-12-pages.pdf"), "scan.png", "image/png"),
            ([], "empty.png", "image/png"),
            ([.. png, .. new byte[SupportAttachment.MaxBytes]], "huge.png", "image/png"),
        };
        foreach (var file in refused)
            await CreateAsync(member.Client, Form(screenshots: [file])).ProblemAsync(HttpStatusCode.BadRequest, "support.attachment_invalid");
        // Far beyond the limit the server stops reading the body, with the same answer.
        await CreateAsync(member.Client, Form(screenshots: [([.. png, .. new byte[3 * SupportAttachment.MaxBytes + 512 * 1024]], "huge.png", "image/png")]))
            .ProblemAsync(HttpStatusCode.BadRequest, "support.attachment_invalid");

        (await InDbAsync(db => db.SupportTickets.CountAsync(t => t.UserId == member.Id, Ct))).Should().Be(0, "nothing is saved");
        var jpeg = Fixture("exif-rotated.jpg");
        var ok = await CreatedAsync(member.Client, Form(screenshots: [(jpeg, "photo.webp", "image/webp")]));
        ok["messages"]![0]!["attachments"]![0]!["contentType"]!.GetValue<string>().Should().Be("image/jpeg");
    }

    [Fact]
    public async Task Five_new_tickets_a_day_and_ten_open_at_once()
    {
        var member = await api.UserAsync("Busy Member");
        for (var i = 0; i < 5; i++) await CreatedAsync(member.Client);
        var daily = await CreateAsync(member.Client, Form()).ProblemAsync(HttpStatusCode.TooManyRequests, "support.limit");
        daily["limit"]!.GetValue<string>().Should().Be("daily");

        // A day later five more: ten open.
        await api.InDbAsync(db => db.SupportTickets.Where(t => t.UserId == member.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.CreatedAt, t => t.CreatedAt.AddDays(-2)), Ct));
        for (var i = 0; i < 5; i++) await CreatedAsync(member.Client);
        await api.InDbAsync(db => db.SupportTickets.Where(t => t.UserId == member.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.CreatedAt, t => t.CreatedAt.AddDays(-2)), Ct));
        var open = await CreateAsync(member.Client, Form()).ProblemAsync(HttpStatusCode.TooManyRequests, "support.limit");
        open["limit"]!.GetValue<string>().Should().Be("open");

        // Closing one frees a place.
        var one = await InDbAsync(db => db.SupportTickets.Where(t => t.UserId == member.Id).Select(t => t.Id).FirstAsync(Ct));
        (await member.Client.PostAsync($"/api/v1/support/tickets/{one}/close", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        await CreatedAsync(member.Client);
    }

    // ---- My tickets ----

    [Fact]
    public async Task My_tickets_are_mine_newest_activity_first_with_status_filters_and_cursor_pages()
    {
        var member = await api.UserAsync("List Owner");
        var first = (await CreatedAsync(member.Client, Form(subject: "First ticket")))["id"]!.GetValue<Guid>();
        var second = (await CreatedAsync(member.Client, Form(subject: "Second ticket")))["id"]!.GetValue<Guid>();
        var third = (await CreatedAsync(member.Client, Form(subject: "Third ticket")))["id"]!.GetValue<Guid>();
        await CreatedAsync((await api.UserAsync("Not Me")).Client);
        (await member.Client.PostAsync($"/api/v1/support/tickets/{second}/close", null, Ct)).EnsureSuccessStatusCode();
        // Writing again on the first moves it to the top.
        (await member.Client.PostAsync($"/api/v1/support/tickets/{first}/messages", Form(category: null, subject: null, message: "Any news?"), Ct))
            .StatusCode.Should().Be(HttpStatusCode.Created);

        async Task<List<Guid>> IdsAsync(string query = "") =>
            [.. (await member.Client.GetAsync($"/api/v1/me/support/tickets{query}", Ct).OkJsonAsync())["items"]!.AsArray()
                .Select(t => t!["id"]!.GetValue<Guid>())];

        (await IdsAsync()).Should().Equal(first, third, second);
        (await IdsAsync("?status=active")).Should().Equal(first, third);
        (await IdsAsync("?status=closed")).Should().Equal(second);

        var page = await member.Client.GetAsync("/api/v1/me/support/tickets?limit=2", Ct).OkJsonAsync();
        page["items"]!.AsArray().Select(t => t!["id"]!.GetValue<Guid>()).Should().Equal(first, third);
        var row = page["items"]![0]!.AsObject();
        row.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "number", "category", "subject", "status", "createdAt", "updatedAt", "lastMessage", "closedAt", "canReopen");
        row["lastMessage"]!["excerpt"]!.GetValue<string>().Should().Be("Any news?");
        var next = page["nextCursor"]!.GetValue<string>();
        (await IdsAsync($"?limit=2&cursor={next}")).Should().Equal(second);

        var bad = await member.Client.GetAsync("/api/v1/me/support/tickets?status=open", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        bad["errors"]!["status"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.invalid");
        (await api.GuestClient().GetAsync("/api/v1/me/support/tickets", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    // ---- The conversation ----

    [Fact]
    public async Task Messages_move_the_status_and_internal_notes_never_reach_the_member()
    {
        var member = await api.UserAsync("Chatty Member");
        var id = (await CreatedAsync(member.Client))["id"]!.GetValue<Guid>();
        var adminId = (await api.SuperAdminAsync("Support Agent")).Id;

        await ChangeTicketAsync(id, t =>
        {
            t.AddNote(adminId, "Internal: looks like the PDF viewer bug.", DateTime.UtcNow);
            t.Reply(adminId, "Which phone do you use?", DateTime.UtcNow.AddSeconds(1));
        });
        var answered = await member.Client.GetAsync($"/api/v1/support/tickets/{id}", Ct).OkJsonAsync();
        answered["status"]!.GetValue<string>().Should().Be("answered");
        var messages = answered["messages"]!.AsArray();
        messages.Select(m => m!["body"]!.GetValue<string>()).Should().Equal("It crashes when I open a PDF attachment.", "Which phone do you use?");
        messages[1]!["fromSupport"]!.GetValue<bool>().Should().BeTrue();
        messages[1]!.AsObject().Should().NotContainKey("author", "support stays anonymous to the member");
        answered.ToJsonString().Should().NotContain("Internal:");

        var png = Fixture("small.png");
        var response = await member.Client.PostAsync($"/api/v1/support/tickets/{id}/messages",
            Form(category: null, subject: null, message: " A Pixel 8. ", screenshots: [(png, "s.png", "image/png")]), Ct);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        var posted = JsonNode.Parse(body)!;
        (posted["body"]!.GetValue<string>(), posted["fromSupport"]!.GetValue<bool>()).Should().Be(("A Pixel 8.", false));
        posted["attachments"]!.AsArray().Should().ContainSingle();
        (await member.Client.GetAsync($"/api/v1/support/tickets/{id}", Ct).OkJsonAsync())["status"]!.GetValue<string>().Should().Be("open");

        var empty = await member.Client.PostAsync($"/api/v1/support/tickets/{id}/messages", Form(category: null, subject: null, message: " "), Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        empty["errors"]!["message"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.required");
        var other = await api.UserAsync("Not The Owner");
        await other.Client.PostAsync($"/api/v1/support/tickets/{id}/messages", Form(category: null, subject: null, message: "Hi"), Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "support.ticket_not_found");
    }

    [Fact]
    public async Task Closing_and_reopening_follow_the_30_day_rule()
    {
        var member = await api.UserAsync("Closer");
        var id = (await CreatedAsync(member.Client))["id"]!.GetValue<Guid>();

        await member.Client.PostAsync($"/api/v1/support/tickets/{id}/close", null, Ct).NoContentAsync();
        await member.Client.PostAsync($"/api/v1/support/tickets/{id}/close", null, Ct).NoContentAsync();
        var closed = await member.Client.GetAsync($"/api/v1/support/tickets/{id}", Ct).OkJsonAsync();
        (closed["status"]!.GetValue<string>(), closed["canReopen"]!.GetValue<bool>()).Should().Be(("closed", true));
        closed["closedAt"].Should().NotBeNull();
        await member.Client.PostAsync($"/api/v1/support/tickets/{id}/messages", Form(category: null, subject: null, message: "Hello?"), Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "support.ticket_closed");

        await member.Client.PostAsync($"/api/v1/support/tickets/{id}/reopen", null, Ct).NoContentAsync();
        (await member.Client.GetAsync($"/api/v1/support/tickets/{id}", Ct).OkJsonAsync())["status"]!.GetValue<string>().Should().Be("open");
        await member.Client.PostAsync($"/api/v1/support/tickets/{id}/reopen", null, Ct).NoContentAsync();

        // Closed 31 days ago: too late, send a new one.
        await member.Client.PostAsync($"/api/v1/support/tickets/{id}/close", null, Ct).NoContentAsync();
        var longAgo = DateTime.UtcNow.AddDays(-31);
        await api.InDbAsync(db => db.SupportTickets.Where(t => t.Id == id).ExecuteUpdateAsync(s => s.SetProperty(t => t.ClosedAt, longAgo), Ct));
        (await member.Client.GetAsync($"/api/v1/support/tickets/{id}", Ct).OkJsonAsync())["canReopen"]!.GetValue<bool>().Should().BeFalse();
        await member.Client.PostAsync($"/api/v1/support/tickets/{id}/reopen", null, Ct).ProblemAsync(HttpStatusCode.Conflict, "support.reopen_expired");

        var other = await api.UserAsync("Not Mine");
        await other.Client.PostAsync($"/api/v1/support/tickets/{id}/close", null, Ct).ProblemAsync(HttpStatusCode.NotFound, "support.ticket_not_found");
        await other.Client.PostAsync($"/api/v1/support/tickets/{id}/reopen", null, Ct).ProblemAsync(HttpStatusCode.NotFound, "support.ticket_not_found");
        await member.Client.PostAsync($"/api/v1/support/tickets/{Guid.NewGuid()}/close", null, Ct).ProblemAsync(HttpStatusCode.NotFound, "support.ticket_not_found");
    }

    // ---- Screenshots ----

    [Fact]
    public async Task A_screenshot_is_for_its_owner_and_support_only_as_an_attachment()
    {
        var member = await api.UserAsync("Shot Owner");
        var png = Fixture("small.png");
        var ticket = await CreatedAsync(member.Client, Form(screenshots: [(png, "screen.png", "image/png")]));
        var number = ticket["number"]!.GetValue<int>();
        var attachmentId = ticket["messages"]![0]!["attachments"]![0]!["id"]!.GetValue<Guid>();
        var url = $"/api/v1/support/attachments/{attachmentId}";

        var mine = await member.Client.GetAsync(url, Ct);
        mine.StatusCode.Should().Be(HttpStatusCode.OK);
        mine.Content.Headers.ContentType!.MediaType.Should().Be("image/png");
        mine.Content.Headers.ContentDisposition!.ToString().Should().Be($"attachment; filename=\"support-{number}-1.png\"");
        mine.Headers.CacheControl!.NoStore.Should().BeTrue();
        mine.Headers.GetValues("X-Content-Type-Options").Should().Equal("nosniff");
        (await mine.Content.ReadAsByteArrayAsync(Ct)).Should().Equal(png);

        var support = await api.UserWithPermissionsAsync("Support Only", Permissions.Support.Manage);
        (await support.Client.GetAsync(url, Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        var other = await api.UserAsync("Curious Member");
        await other.Client.GetAsync(url, Ct).ProblemAsync(HttpStatusCode.NotFound, "support.attachment_not_found");
        (await api.GuestClient().GetAsync(url, Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        await member.Client.GetAsync($"/api/v1/support/attachments/{Guid.NewGuid()}", Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "support.attachment_not_found");

        // Nothing else reaches the private folder.
        var messageId = ticket["messages"]![0]!["id"]!.GetValue<string>();
        foreach (var path in new[] { $"/support/{messageId}/1.png", $"/uploads/support/{messageId}/1.png", $"/App_Data/private/support/{messageId}/1.png" })
            (await member.Client.GetAsync(path, Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    // ---- Account deletion (SPEC §9.6) ----

    [Fact]
    public async Task Deleting_an_account_deletes_its_tickets_and_files_and_unlinks_its_replies_on_others()
    {
        var member = await api.UserAsync("Leaving Member");
        var ticket = await CreatedAsync(member.Client, Form(screenshots: [(Fixture("small.png"), "s.png", "image/png")]));
        var id = ticket["id"]!.GetValue<Guid>();
        var folder = Path.Combine(api.PrivatePath, "support", ticket["messages"]![0]!["id"]!.GetValue<string>());
        Directory.Exists(folder).Should().BeTrue();

        // A support agent who answered and closed someone else's ticket, then leaves.
        var agent = await api.UserWithPermissionsAsync("Leaving Agent", Permissions.Support.Manage);
        var stays = await api.UserAsync("Staying Member");
        var kept = (await CreatedAsync(stays.Client))["id"]!.GetValue<Guid>();
        await ChangeTicketAsync(kept, t =>
        {
            t.Reply(agent.Id, "We fixed it.", DateTime.UtcNow);
            t.AddNote(agent.Id, "Shipped in 1.2.", DateTime.UtcNow);
            t.CloseBySupport(agent.Id, DateTime.UtcNow);
        });

        foreach (var leaving in new[] { member, agent })
        {
            var delete = new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me") { Content = JsonContent.Create(new { password = ApiFactory.TestPassword }) };
            (await leaving.Client.SendAsync(delete, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        }

        (await InDbAsync(db => db.SupportTickets.AnyAsync(t => t.Id == id, Ct))).Should().BeFalse();
        (await InDbAsync(db => db.SupportMessages.AnyAsync(m => m.TicketId == id, Ct))).Should().BeFalse();
        Directory.Exists(folder).Should().BeFalse("its screenshots went right after the commit");

        var keptTicket = await InDbAsync(db => db.SupportTickets.AsNoTracking().Include(t => t.Messages).SingleAsync(t => t.Id == kept, Ct));
        keptTicket.ClosedById.Should().BeNull();
        keptTicket.ClosedBy.Should().Be(SupportClosedBy.Support);
        keptTicket.Messages.Should().HaveCount(3, "the agent's reply and note stay");
        keptTicket.Messages.Where(m => m.FromSupport).Should().OnlyContain(m => m.AuthorId == null);
        keptTicket.Messages.Single(m => !m.FromSupport).AuthorId.Should().Be(stays.Id);
    }
}
