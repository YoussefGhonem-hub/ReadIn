using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Verification;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Persistence;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F19 Writer Verification against SQL Server: the request (with a file, a URL or both) and its rules, withdrawing, the
/// admin queue (the SuperAdmin's), approve (the Verified badge, no role change) and reject with their notification and
/// retention, removing a badge, and the private store, which is never under wwwroot and never reachable over HTTP.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class VerificationTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static string Fixture(string name) => Path.Combine(AppContext.BaseDirectory, "fixtures", "media", name);

    // ---- Requesting ----

    [Fact]
    public async Task A_request_with_a_file_is_pending_and_its_proof_is_stored_privately()
    {
        var user = await api.UserAsync("Proof Sender");
        var fieldId = await user.Client.FieldIdAsync("dotnet");
        var png = await File.ReadAllBytesAsync(Fixture("small.png"), Ct);

        var created = await SubmitAsync(user.Client, Form(fieldId, "  Senior .NET Engineer ", "https://www.linkedin.com/in/proof-sender",
            "شغال في المجال من 8 سنين", png, @"C:\fakepath\my certificate.png"));

        created.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "status", "field", "jobTitle", "proofUrl", "proofFileName", "note", "submittedAt", "decidedAt", "rejectionReason");
        created["status"]!.GetValue<string>().Should().Be("pending");
        created["field"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("id", "slug", "name");
        created["field"]!["slug"]!.GetValue<string>().Should().Be("dotnet");
        created["jobTitle"]!.GetValue<string>().Should().Be("Senior .NET Engineer");
        created["proofUrl"]!.GetValue<string>().Should().Be("https://www.linkedin.com/in/proof-sender");
        created["proofFileName"]!.GetValue<string>().Should().Be("my certificate.png");
        created["note"]!.GetValue<string>().Should().Be("شغال في المجال من 8 سنين");
        created["decidedAt"].Should().BeNull();
        created["rejectionReason"].Should().BeNull();

        var id = created["id"]!.GetValue<Guid>();
        var stored = await InDbAsync(db => db.VerificationRequests.AsNoTracking().SingleAsync(r => r.Id == id, Ct));
        stored.ProofFilePath.Should().Be($"verification/{id}.png");
        (stored.ProofFileContentType, stored.ProofFileSizeBytes).Should().Be(("image/png", (long?)png.Length));

        // The private store: outside wwwroot and the uploads folder, and nothing serves it.
        var file = Path.Combine(api.PrivatePath, "verification", $"{id}.png");
        (await File.ReadAllBytesAsync(file, Ct)).Should().Equal(png);
        Directory.EnumerateFiles(api.UploadsPath, $"{id}*", SearchOption.AllDirectories).Should().BeEmpty();
        var webRoot = api.Services.GetRequiredService<IWebHostEnvironment>().WebRootPath;
        if (Directory.Exists(webRoot)) Directory.EnumerateFiles(webRoot, $"{id}*", SearchOption.AllDirectories).Should().BeEmpty();

        var status = await user.Client.GetAsync("/api/v1/me/verification", Ct).OkJsonAsync();
        status.Select(p => p.Key).Should().BeEquivalentTo("isVerified", "canRequest", "request");
        (status["isVerified"]!.GetValue<bool>(), status["canRequest"]!.GetValue<bool>()).Should().Be((false, false));
        status["request"]!["id"]!.GetValue<Guid>().Should().Be(id);
    }

    [Fact]
    public async Task Private_proofs_are_not_reachable_over_http()
    {
        var user = await api.UserAsync();
        var webp = await File.ReadAllBytesAsync(Fixture("medium.webp"), Ct);
        var id = (await SubmitAsync(user.Client, Form(await user.Client.FieldIdAsync("dotnet"), "Engineer", file: webp, fileName: "card.webp")))["id"]!
            .GetValue<Guid>();
        File.Exists(Path.Combine(api.PrivatePath, "verification", $"{id}.webp")).Should().BeTrue();

        // .webp is the one type /uploads serves: the proof still isn't there, and no other route leads to the folder.
        foreach (var url in new[]
                 {
                     $"/uploads/verification/{id}.webp", $"/verification/{id}.webp", $"/App_Data/private/verification/{id}.webp",
                     $"/private/verification/{id}.webp", $"/uploads/../App_Data/private/verification/{id}.webp",
                     $"/api/v1/verification/{id}.webp",
                 })
        {
            (await api.GuestClient().GetAsync(url, Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound, url);
            (await user.Client.GetAsync(url, Ct)).StatusCode.Should().Be(HttpStatusCode.NotFound, url);
        }

        // Only the admin endpoint reads it, and only for verification.manage.
        (await api.GuestClient().GetAsync($"/api/v1/admin/verification-requests/{id}/proof", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        await user.Client.GetAsync($"/api/v1/admin/verification-requests/{id}/proof", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
    }

    [Fact]
    public async Task A_url_alone_is_enough_and_proof_is_required()
    {
        var user = await api.UserAsync();
        var fieldId = await user.Client.FieldIdAsync("frontend");

        await PostAsync(user.Client, Form(fieldId, "Frontend Engineer")).ProblemAsync(HttpStatusCode.BadRequest, "verification.proof_required");
        await PostAsync(user.Client, Form(fieldId, "Frontend Engineer", proofUrl: "   ")).ProblemAsync(HttpStatusCode.BadRequest, "verification.proof_required");

        var created = await SubmitAsync(user.Client, Form(fieldId, "Frontend Engineer", proofUrl: "https://github.com/url-only"));
        created["proofFileName"].Should().BeNull();
        created["note"].Should().BeNull();
        var id = created["id"]!.GetValue<Guid>();
        (await InDbAsync(db => db.VerificationRequests.Where(r => r.Id == id).Select(r => r.ProofFilePath).SingleAsync(Ct))).Should().BeNull();
        Directory.EnumerateFiles(api.PrivatePath, $"{id}*", SearchOption.AllDirectories).Should().BeEmpty();
    }

    [Fact]
    public async Task Proof_files_must_be_a_pdf_or_an_image_of_at_most_10_MB_by_their_bytes()
    {
        var user = await api.UserAsync();
        var fieldId = await user.Client.FieldIdAsync("dotnet");

        var notAProof = new Dictionary<string, byte[]>
        {
            ["photo.heic"] = await File.ReadAllBytesAsync(Fixture("sample.heic"), Ct),
            ["animation.gif"] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 1, 0, 1, 0, 0, 0],
            ["certificate.pdf"] = "<html><script>alert(1)</script></html>"u8.ToArray(), // the name and the content type lie
            ["empty.png"] = [],
            ["huge.pdf"] = [.. "%PDF-1.7\n"u8, .. new byte[VerificationRequest.MaxProofBytes]],
        };
        foreach (var (name, bytes) in notAProof)
        {
            await PostAsync(user.Client, Form(fieldId, "Engineer", "https://github.com/x", file: bytes, fileName: name, contentType: "application/pdf"))
                .ProblemAsync(HttpStatusCode.BadRequest, "verification.proof_invalid");
        }
        // Far beyond the limit the server stops reading the body, with the same answer.
        await PostAsync(user.Client, Form(fieldId, "Engineer", "https://github.com/x",
                file: [.. "%PDF-1.7\n"u8, .. new byte[VerificationRequest.MaxProofBytes + 512 * 1024]], fileName: "huge.pdf"))
            .ProblemAsync(HttpStatusCode.BadRequest, "verification.proof_invalid");
        await user.Client.PostAsJsonAsync("/api/v1/verification-requests", new { fieldId, jobTitle = "Engineer", proofUrl = "https://github.com/x" }, Ct)
            .ProblemAsync(HttpStatusCode.UnsupportedMediaType, "request.unsupported_media_type");
        (await InDbAsync(db => db.VerificationRequests.CountAsync(r => r.UserId == user.Id, Ct))).Should().Be(0);

        // A real PDF (whatever it is called) and a JPEG are fine.
        var pdf = await SubmitAsync(user.Client, Form(fieldId, "Engineer", file: await File.ReadAllBytesAsync(Fixture("normal-12-pages.pdf"), Ct),
            fileName: "scan.png", contentType: "image/png"));
        (await InDbAsync(db => db.VerificationRequests.Where(r => r.Id == pdf["id"]!.GetValue<Guid>())
            .Select(r => new { r.ProofFilePath, r.ProofFileContentType }).SingleAsync(Ct)))
            .Should().BeEquivalentTo(new { ProofFilePath = $"verification/{pdf["id"]}.pdf", ProofFileContentType = "application/pdf" });
    }

    [Fact]
    public async Task The_form_is_validated()
    {
        var user = await api.UserAsync();
        var fieldId = await user.Client.FieldIdAsync("dotnet");

        var invalid = await PostAsync(user.Client, Form(fieldId, " a ", "http://github.com/x", note: new string('n', 501)))
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        invalid["errors"]!["jobTitle"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.length");
        invalid["errors"]!["proofUrl"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.url");
        invalid["errors"]!["note"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.max_length");
        (await PostAsync(user.Client, Form(fieldId, null, "https://github.com/x")).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed"))
            ["errors"]!["jobTitle"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.required");
        await PostAsync(user.Client, Form(fieldId, "Engineer", "https://example.com/" + new string('u', 481)))
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");

        await PostAsync(user.Client, Form(Guid.NewGuid(), "Engineer", "https://github.com/x")).ProblemAsync(HttpStatusCode.BadRequest, "verification.field_invalid");
        await PostAsync(user.Client, Form(null, "Engineer", "https://github.com/x")).ProblemAsync(HttpStatusCode.BadRequest, "verification.field_invalid");
        using (var garbage = new MultipartFormDataContent { { new StringContent("not-a-guid"), "fieldId" }, { new StringContent("Engineer"), "jobTitle" } })
            await PostAsync(user.Client, garbage).ProblemAsync(HttpStatusCode.BadRequest, "verification.field_invalid");

        (await api.GuestClient().PostAsync("/api/v1/verification-requests", Form(fieldId, "Engineer", "https://github.com/x"), Ct))
            .StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await InDbAsync(db => db.VerificationRequests.CountAsync(r => r.UserId == user.Id, Ct))).Should().Be(0);
    }

    [Fact]
    public async Task One_request_at_a_time_and_none_for_verified_writers_or_suspended_users()
    {
        var user = await api.UserAsync();
        var fieldId = await user.Client.FieldIdAsync("dotnet");
        await SubmitAsync(user.Client, Form(fieldId, "Engineer", "https://github.com/first"));

        await PostAsync(user.Client, Form(fieldId, "Engineer", "https://github.com/second")).ProblemAsync(HttpStatusCode.Conflict, "verification.already_pending");

        var verified = await api.VerifiedUserAsync("Already Verified");
        await PostAsync(verified.Client, Form(fieldId, "Engineer", "https://github.com/v")).ProblemAsync(HttpStatusCode.Conflict, "verification.already_verified");
        var status = await verified.Client.GetAsync("/api/v1/me/verification", Ct).OkJsonAsync();
        (status["isVerified"]!.GetValue<bool>(), status["canRequest"]!.GetValue<bool>()).Should().Be((true, false));
        status["request"].Should().BeNull();

        var fresh = await api.UserAsync();
        var none = await fresh.Client.GetAsync("/api/v1/me/verification", Ct).OkJsonAsync();
        (none["isVerified"]!.GetValue<bool>(), none["canRequest"]!.GetValue<bool>()).Should().Be((false, true));
        none["request"].Should().BeNull();

        await InScopeAsync(async services =>
        {
            var db = services.GetRequiredService<AppDbContext>();
            (await db.Users.SingleAsync(u => u.Id == fresh.Id, Ct)).Suspend(DateTime.UtcNow.AddDays(1));
            await db.SaveChangesAsync(Ct);
            await services.GetRequiredService<IUserAccessService>().InvalidateAsync(fresh.Id, Ct);
        });
        await PostAsync(fresh.Client, Form(fieldId, "Engineer", "https://github.com/s")).ProblemAsync(HttpStatusCode.Forbidden, "user.suspended");
    }

    [Fact]
    public async Task Withdrawing_deletes_the_pending_request_and_its_file()
    {
        var user = await api.UserAsync();
        var fieldId = await user.Client.FieldIdAsync("dotnet");
        await user.Client.DeleteAsync("/api/v1/me/verification", Ct).ProblemAsync(HttpStatusCode.NotFound, "verification.not_found");

        var id = (await SubmitAsync(user.Client, Form(fieldId, "Engineer", file: await File.ReadAllBytesAsync(Fixture("small.png"), Ct))))["id"]!
            .GetValue<Guid>();
        var file = Path.Combine(api.PrivatePath, "verification", $"{id}.png");
        File.Exists(file).Should().BeTrue();

        (await user.Client.DeleteAsync("/api/v1/me/verification", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        File.Exists(file).Should().BeFalse();
        (await InDbAsync(db => db.VerificationRequests.AnyAsync(r => r.Id == id, Ct))).Should().BeFalse();
        var status = await user.Client.GetAsync("/api/v1/me/verification", Ct).OkJsonAsync();
        (status["canRequest"]!.GetValue<bool>(), status["request"]).Should().Be((true, null));
        await user.Client.DeleteAsync("/api/v1/me/verification", Ct).ProblemAsync(HttpStatusCode.NotFound, "verification.not_found");
        await SubmitAsync(user.Client, Form(fieldId, "Engineer", "https://github.com/again"));
    }

    // ---- Admin ----

    [Fact]
    public async Task Admins_list_open_and_download_proofs_and_members_cant()
    {
        var admin = await api.SuperAdminAsync("Verification Admin");
        var user = await api.UserAsync("Queued Writer");
        var png = await File.ReadAllBytesAsync(Fixture("small.png"), Ct);
        var id = (await SubmitAsync(user.Client, Form(await user.Client.FieldIdAsync("dotnet"), "Engineer", "https://github.com/queued", "Hi",
            png, "card.png")))["id"]!.GetValue<Guid>();

        var pending = await AllPagesAsync(admin.Client, "/api/v1/admin/verification-requests?limit=2");
        pending.Select(p => p["status"]!.GetValue<string>()).Should().OnlyContain(s => s == "pending");
        pending.Select(p => p["submittedAt"]!.GetValue<DateTime>()).Should().BeInAscendingOrder("pending requests are oldest first");
        var item = pending.Should().ContainSingle(p => p["id"]!.GetValue<Guid>() == id).Subject;
        item.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "status", "user", "field", "jobTitle", "proofUrl", "proof", "note", "submittedAt", "decidedAt", "decidedBy", "rejectionReason");
        item["user"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("id", "displayName", "username", "avatarUrl", "isVerified", "headline");
        (item["user"]!["id"]!.GetValue<Guid>(), item["user"]!["displayName"]!.GetValue<string>(), item["user"]!["isVerified"]!.GetValue<bool>())
            .Should().Be((user.Id, "Queued Writer", false));
        item["proof"]!.ToJsonString().Should().Be($"{{\"fileName\":\"card.png\",\"contentType\":\"image/png\",\"sizeBytes\":{png.Length}}}");
        item["decidedBy"].Should().BeNull();

        var detail = await admin.Client.GetAsync($"/api/v1/admin/verification-requests/{id}", Ct).OkJsonAsync();
        detail["jobTitle"]!.GetValue<string>().Should().Be("Engineer");
        await admin.Client.GetAsync($"/api/v1/admin/verification-requests/{Guid.NewGuid()}", Ct).ProblemAsync(HttpStatusCode.NotFound, "verification.not_found");

        var proof = await admin.Client.GetAsync($"/api/v1/admin/verification-requests/{id}/proof", Ct);
        proof.StatusCode.Should().Be(HttpStatusCode.OK);
        proof.Content.Headers.ContentType!.MediaType.Should().Be("image/png");
        proof.Content.Headers.ContentDisposition!.ToString().Should().Be($"attachment; filename=\"verification-proof-{id}.png\"");
        proof.Headers.CacheControl!.NoStore.Should().BeTrue();
        proof.Headers.GetValues("X-Content-Type-Options").Should().Equal("nosniff");
        (await proof.Content.ReadAsByteArrayAsync(Ct)).Should().Equal(png);
        await admin.Client.GetAsync($"/api/v1/admin/verification-requests/{Guid.NewGuid()}/proof", Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "verification.not_found");

        // Without verification.manage: a Member, and a staff role that only moderates (permissions decide, not roles).
        var moderator = await api.UserWithPermissionsAsync("Not An Admin",
            Permissions.Articles.Read, Permissions.Moderation.Manage, Permissions.Users.Suspend);
        foreach (var client in new[] { user.Client, moderator.Client })
        {
            await client.GetAsync("/api/v1/admin/verification-requests", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
            await client.GetAsync($"/api/v1/admin/verification-requests/{id}", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
            await client.GetAsync($"/api/v1/admin/verification-requests/{id}/proof", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
            await client.PostAsync($"/api/v1/admin/verification-requests/{id}/approve", null, Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
            await client.PostAsJsonAsync($"/api/v1/admin/verification-requests/{id}/reject", new { reason = "Not enough." }, Ct)
                .ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        }
        (await api.GuestClient().GetAsync("/api/v1/admin/verification-requests", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        var badStatus = await admin.Client.GetAsync("/api/v1/admin/verification-requests?status=open", Ct).ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        badStatus["errors"]!["status"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("verification.status_invalid");
    }

    [Fact]
    public async Task Approving_makes_a_verified_writer_tells_them_and_deletes_the_proof()
    {
        var admin = await api.SuperAdminAsync("Approving Admin");
        var user = await api.UserAsync("Soon Verified");
        var id = (await SubmitAsync(user.Client, Form(await user.Client.FieldIdAsync("dotnet"), "Engineer", "https://github.com/soon",
            file: await File.ReadAllBytesAsync(Fixture("small.png"), Ct))))["id"]!.GetValue<Guid>();
        var file = Path.Combine(api.PrivatePath, "verification", $"{id}.png");
        var before = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!;
        before["isVerified"]!.GetValue<bool>().Should().BeFalse();

        (await admin.Client.PostAsync($"/api/v1/admin/verification-requests/{id}/approve", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        // The badge, at once on the user's current session; roles and permissions don't change (SPEC §10.1).
        var me = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!;
        me["isVerified"]!.GetValue<bool>().Should().BeTrue();
        Names(me["roles"]).Should().Equal([RoleNames.Member], "the user stays a Member");
        Names(me["permissions"]).Should().BeEquivalentTo(Names(before["permissions"]));
        var badge = await InDbAsync(db => db.Users.AsNoTracking().Where(u => u.Id == user.Id).Select(u => new { u.IsVerified, u.VerifiedAt }).SingleAsync(Ct));
        badge.IsVerified.Should().BeTrue();
        badge.VerifiedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(1));
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/users/{user.Me["username"]}", Ct))!["isVerified"]!.GetValue<bool>()
            .Should().BeTrue();

        // Retention: the file goes, the decision and the URL stay.
        File.Exists(file).Should().BeFalse();
        var stored = await InDbAsync(db => db.VerificationRequests.AsNoTracking().SingleAsync(r => r.Id == id, Ct));
        stored.Should().BeEquivalentTo(new
        {
            Status = VerificationStatus.Approved,
            DecidedById = (Guid?)admin.Id,
            ProofUrl = "https://github.com/soon",
            ProofFilePath = (string?)null,
            ProofFileName = (string?)null,
        });
        stored.DecidedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(1));
        await admin.Client.GetAsync($"/api/v1/admin/verification-requests/{id}/proof", Ct).ProblemAsync(HttpStatusCode.NotFound, "verification.proof_not_found");
        var detail = await admin.Client.GetAsync($"/api/v1/admin/verification-requests/{id}", Ct).OkJsonAsync();
        detail["status"]!.GetValue<string>().Should().Be("approved");
        detail["proof"].Should().BeNull();
        detail["user"]!["isVerified"]!.GetValue<bool>().Should().BeTrue();
        detail["decidedBy"]!.ToJsonString().Should().Be($"{{\"id\":\"{admin.Id}\",\"username\":\"{admin.Me["username"]!.GetValue<string>()}\"}}");
        (await InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == AuditActions.VerificationApproved && l.UserId == user.Id && l.ActorId == admin.Id, Ct)))
            .Should().Be(1);

        // The notification: no actor, no article, approved, links to the verification page.
        var entry = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications", Ct))!["items"]!.AsArray()
            .Should().ContainSingle(n => n!["type"]!.GetValue<string>() == "verification_result").Subject!;
        entry["data"]!.ToJsonString().Should().Be("{\"approved\":true}");
        entry["link"]!.GetValue<string>().Should().Be("readin://verification");
        (entry["actor"], entry["article"], entry["comment"]).Should().Be((null, null, null));
        (await InDbAsync(db => db.Notifications.SingleAsync(n => n.UserId == user.Id && n.Type == NotificationTypes.VerificationResult, Ct)))
            .Should().Match<Notification>(n => n.DedupeKey == $"verification_result:{id}" && n.PushStatus == NotificationPushStatus.Pending);

        // Decided once.
        await admin.Client.PostAsync($"/api/v1/admin/verification-requests/{id}/approve", null, Ct).ProblemAsync(HttpStatusCode.Conflict, "verification.already_decided");
        await admin.Client.PostAsJsonAsync($"/api/v1/admin/verification-requests/{id}/reject", new { reason = "Changed my mind." }, Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "verification.already_decided");
        await admin.Client.PostAsync($"/api/v1/admin/verification-requests/{Guid.NewGuid()}/approve", null, Ct)
            .ProblemAsync(HttpStatusCode.NotFound, "verification.not_found");
        (await InDbAsync(db => db.Notifications.CountAsync(n => n.UserId == user.Id && n.Type == NotificationTypes.VerificationResult, Ct))).Should().Be(1);

        var status = await user.Client.GetAsync("/api/v1/me/verification", Ct).OkJsonAsync();
        (status["isVerified"]!.GetValue<bool>(), status["canRequest"]!.GetValue<bool>()).Should().Be((true, false));
        status["request"]!["status"]!.GetValue<string>().Should().Be("approved");
        status["request"]!["proofFileName"].Should().BeNull("the file was deleted with the decision");
        await PostAsync(user.Client, Form(await user.Client.FieldIdAsync("dotnet"), "Engineer", "https://github.com/again"))
            .ProblemAsync(HttpStatusCode.Conflict, "verification.already_verified");
    }

    [Fact]
    public async Task Rejecting_needs_a_reason_the_user_sees_and_they_can_ask_again()
    {
        var admin = await api.SuperAdminAsync("Rejecting Admin");
        var user = await api.UserAsync();
        var fieldId = await user.Client.FieldIdAsync("dotnet");
        var id = (await SubmitAsync(user.Client, Form(fieldId, "Engineer", "https://github.com/maybe",
            file: await File.ReadAllBytesAsync(Fixture("exif-rotated.jpg"), Ct))))["id"]!.GetValue<Guid>();
        var file = Path.Combine(api.PrivatePath, "verification", $"{id}.jpg");
        File.Exists(file).Should().BeTrue();

        foreach (var body in new object[] { new { }, new { reason = "   " }, new { reason = "Meh." } })
        {
            var problem = await admin.Client.PostAsJsonAsync($"/api/v1/admin/verification-requests/{id}/reject", body, Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
            problem["errors"]!["reason"].Should().NotBeNull();
        }
        File.Exists(file).Should().BeTrue("nothing was decided");

        (await admin.Client.PostAsJsonAsync($"/api/v1/admin/verification-requests/{id}/reject",
            new { reason = "  اللينك مش بيوضّح خبرة في .NET.  " }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        File.Exists(file).Should().BeFalse();
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["isVerified"]!.GetValue<bool>().Should().BeFalse();
        var status = await user.Client.GetAsync("/api/v1/me/verification", Ct).OkJsonAsync();
        status["canRequest"]!.GetValue<bool>().Should().BeTrue("a rejected user may ask again");
        status["request"]!["status"]!.GetValue<string>().Should().Be("rejected");
        status["request"]!["rejectionReason"]!.GetValue<string>().Should().Be("اللينك مش بيوضّح خبرة في .NET.");
        status["request"]!["decidedAt"].Should().NotBeNull();

        var entry = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me/notifications", Ct))!["items"]!.AsArray()
            .Should().ContainSingle(n => n!["type"]!.GetValue<string>() == "verification_result").Subject!;
        entry["data"]!["approved"]!.GetValue<bool>().Should().BeFalse();
        (await InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == AuditActions.VerificationRejected && l.UserId == user.Id, Ct))).Should().Be(1);

        var rejected = (await AllPagesAsync(admin.Client, "/api/v1/admin/verification-requests?status=rejected&limit=50"))
            .Should().ContainSingle(r => r["id"]!.GetValue<Guid>() == id).Subject;
        rejected["rejectionReason"]!.GetValue<string>().Should().Be("اللينك مش بيوضّح خبرة في .NET.");

        var again = await SubmitAsync(user.Client, Form(fieldId, "Senior Engineer", "https://github.com/better"));
        var latest = await user.Client.GetAsync("/api/v1/me/verification", Ct).OkJsonAsync();
        latest["request"]!["id"]!.GetValue<Guid>().Should().Be(again["id"]!.GetValue<Guid>(), "the latest request is shown");
        latest["canRequest"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public async Task Removing_a_badge_keeps_the_requests_and_the_roles_and_lets_the_user_ask_again()
    {
        var admin = await api.SuperAdminAsync("Badge Remover");
        var user = await api.UserAsync("Losing The Badge");
        var fieldId = await user.Client.FieldIdAsync("dotnet");
        var id = (await SubmitAsync(user.Client, Form(fieldId, "Engineer", "https://github.com/badge")))["id"]!.GetValue<Guid>();
        (await admin.Client.PostAsync($"/api/v1/admin/verification-requests/{id}/approve", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var url = $"/api/v1/admin/users/{user.Id}/verification";

        // verification.manage only: not the user, not another Member, not a staff role that only moderates.
        var member = await api.UserAsync();
        var moderator = await api.UserWithPermissionsAsync("Moderation Only", Permissions.Articles.Read, Permissions.Moderation.Manage);
        foreach (var client in new[] { user.Client, member.Client, moderator.Client })
            await client.DeleteAsync(url, Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        (await api.GuestClient().DeleteAsync(url, Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["isVerified"]!.GetValue<bool>().Should().BeTrue();

        (await admin.Client.DeleteAsync(url, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var me = (await user.Client.GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!;
        me["isVerified"]!.GetValue<bool>().Should().BeFalse();
        Names(me["roles"]).Should().Equal([RoleNames.Member]);
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/users/{user.Me["username"]}", Ct))!["isVerified"]!.GetValue<bool>()
            .Should().BeFalse();
        var stored = await InDbAsync(db => db.Users.AsNoTracking().Where(u => u.Id == user.Id).Select(u => new { u.IsVerified, u.VerifiedAt }).SingleAsync(Ct));
        (stored.IsVerified, stored.VerifiedAt).Should().Be((false, (DateTime?)null));
        (await InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == AuditActions.VerificationRemoved && l.UserId == user.Id && l.ActorId == admin.Id, Ct)))
            .Should().Be(1);

        // The approved request stays approved, the user may ask again, and only the approval was ever notified.
        var status = await user.Client.GetAsync("/api/v1/me/verification", Ct).OkJsonAsync();
        (status["isVerified"]!.GetValue<bool>(), status["canRequest"]!.GetValue<bool>()).Should().Be((false, true));
        status["request"]!["status"]!.GetValue<string>().Should().Be("approved");
        var detail = await admin.Client.GetAsync($"/api/v1/admin/verification-requests/{id}", Ct).OkJsonAsync();
        (detail["status"]!.GetValue<string>(), detail["user"]!["isVerified"]!.GetValue<bool>()).Should().Be(("approved", false));
        (await InDbAsync(db => db.Notifications.CountAsync(n => n.UserId == user.Id && n.Type == NotificationTypes.VerificationResult, Ct)))
            .Should().Be(1, "removing a badge tells nobody");

        // Nothing to remove twice, nobody to remove it from; neither is logged.
        await admin.Client.DeleteAsync(url, Ct).ProblemAsync(HttpStatusCode.Conflict, "verification.not_verified");
        await admin.Client.DeleteAsync($"/api/v1/admin/users/{Guid.NewGuid()}/verification", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        (await InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == AuditActions.VerificationRemoved && l.ActorId == admin.Id, Ct))).Should().Be(1);

        await SubmitAsync(user.Client, Form(fieldId, "Senior Engineer", "https://github.com/badge-again"));
    }

    [Fact]
    public async Task The_official_account_keeps_its_badge()
    {
        var admin = await api.SuperAdminAsync("Official Badge Keeper");
        var before = await InDbAsync(db => db.Users.AsNoTracking().Where(u => u.Id == SystemUsers.EditorialId)
            .Select(u => new { u.Username, u.IsVerified, u.VerifiedAt }).SingleAsync(Ct));
        before.IsVerified.Should().BeTrue("the system seeder gives the official account the badge");

        await admin.Client.DeleteAsync($"/api/v1/admin/users/{SystemUsers.EditorialId}/verification", Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "verification.system_account");

        var after = await InDbAsync(db => db.Users.AsNoTracking().Where(u => u.Id == SystemUsers.EditorialId)
            .Select(u => new { u.Username, u.IsVerified, u.VerifiedAt }).SingleAsync(Ct));
        after.Should().Be(before, "nothing changes, VerifiedAt included");
        (await api.GuestClient().GetFromJsonAsync<JsonObject>($"/api/v1/users/{before.Username}", Ct))!["isVerified"]!.GetValue<bool>()
            .Should().BeTrue();
        (await InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == AuditActions.VerificationRemoved && l.UserId == SystemUsers.EditorialId, Ct)))
            .Should().Be(0, "a refused removal is not logged");

        // A system account without a badge (the SuperAdmin) has nothing to remove: that comes first.
        await admin.Client.DeleteAsync($"/api/v1/admin/users/{SystemUsers.SuperAdminId}/verification", Ct)
            .ProblemAsync(HttpStatusCode.Conflict, "verification.not_verified");
    }

    [Fact]
    public async Task Decided_lists_are_newest_decided_first_and_page_with_a_cursor()
    {
        var admin = await api.SuperAdminAsync("Listing Admin");
        var ids = new List<Guid>();
        for (var i = 0; i < 3; i++)
        {
            var user = await api.UserAsync();
            var id = (await SubmitAsync(user.Client, Form(await user.Client.FieldIdAsync("dotnet"), "Engineer", $"https://github.com/list{i}")))["id"]!
                .GetValue<Guid>();
            (await admin.Client.PostAsync($"/api/v1/admin/verification-requests/{id}/approve", null, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
            ids.Add(id);
        }

        var approved = await AllPagesAsync(admin.Client, "/api/v1/admin/verification-requests?status=approved&limit=1");
        approved.Select(a => a["id"]!.GetValue<Guid>()).Should().OnlyHaveUniqueItems().And.ContainInOrder(ids[2], ids[1], ids[0]);
        approved.Select(a => a["decidedAt"]!.GetValue<DateTime>()).Should().BeInDescendingOrder();
        approved.Should().OnlyContain(a => a["status"]!.GetValue<string>() == "approved");
    }

    [Fact]
    public async Task The_openapi_document_describes_the_verification_endpoints()
    {
        var document = await api.GuestClient().GetAsync("/openapi/v1.json", Ct).OkJsonAsync();

        document["paths"]!.AsObject().Select(p => p.Key).Should().Contain([
            "/api/v1/me/verification", "/api/v1/verification-requests", "/api/v1/admin/verification-requests",
            "/api/v1/admin/verification-requests/{id}", "/api/v1/admin/verification-requests/{id}/proof",
            "/api/v1/admin/verification-requests/{id}/approve", "/api/v1/admin/verification-requests/{id}/reject",
            "/api/v1/admin/users/{id}/verification"]);
        document["paths"]!["/api/v1/admin/users/{id}/verification"]!.AsObject().Select(p => p.Key).Should().Contain("delete");
        var form = document["paths"]!["/api/v1/verification-requests"]!["post"]!["requestBody"]!["content"]!["multipart/form-data"]!["schema"]!;
        var properties = form["properties"] ?? document["components"]!["schemas"]![form["$ref"]!.GetValue<string>().Split('/')[^1]]!["properties"];
        properties!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("fieldId", "jobTitle", "proofUrl", "note", "proof");
    }

    // ---- Startup, cleanup and demo data ----

    [Fact]
    public async Task The_api_refuses_to_start_with_a_private_folder_inside_wwwroot()
    {
        await using var misconfigured = api.WithWebHostBuilder(builder => builder
            .UseSetting("Storage:PrivatePath", "wwwroot/private")
            .UseSetting("Database:MigrateOnStartup", "false"));

        var start = () => misconfigured.CreateClient();

        start.Should().Throw<InvalidOperationException>().WithMessage("*Storage:PrivatePath*web root*");
        var webRoot = api.Services.GetRequiredService<IWebHostEnvironment>().WebRootPath;
        Directory.Exists(Path.Combine(webRoot, "private")).Should().BeFalse("nothing was created there");
    }

    [Fact]
    public async Task The_cleanup_job_deletes_old_proofs_no_request_points_at()
    {
        var user = await api.UserAsync();
        var id = (await SubmitAsync(user.Client, Form(await user.Client.FieldIdAsync("dotnet"), "Engineer",
            file: await File.ReadAllBytesAsync(Fixture("small.png"), Ct))))["id"]!.GetValue<Guid>();
        var kept = Path.Combine(api.PrivatePath, "verification", $"{id}.png");
        var orphan = Path.Combine(api.PrivatePath, "verification", $"{Guid.NewGuid()}.pdf");
        var leftover = Path.Combine(api.PrivatePath, "verification", $"{Guid.NewGuid()}.pdf.0a1b.tmp");
        var fresh = Path.Combine(api.PrivatePath, "verification", $"{Guid.NewGuid()}.jpg");
        foreach (var path in new[] { orphan, leftover, fresh }) await File.WriteAllBytesAsync(path, [1, 2, 3], Ct);
        foreach (var path in new[] { kept, orphan, leftover }) File.SetLastWriteTimeUtc(path, DateTime.UtcNow.AddDays(-2));

        await InScopeAsync(services => services.GetRequiredService<VerificationProofsCleanupJob>().RunAsync(Ct));

        File.Exists(kept).Should().BeTrue("a pending request still points at it");
        File.Exists(orphan).Should().BeFalse();
        File.Exists(leftover).Should().BeFalse();
        File.Exists(fresh).Should().BeTrue("younger than 24 hours: a submit may still be saving it");
        File.Delete(fresh);
    }

    [Fact]
    public async Task The_demo_seeder_fills_the_queue_locally_with_private_files_and_can_run_again()
    {
        await using var scope = api.Services.CreateAsyncScope();
        var seeder = scope.ServiceProvider.GetServices<ISeeder>().Single(s => s.Name == "demo-verification");
        seeder.AppliesTo(scope.ServiceProvider.GetRequiredService<IHostEnvironment>()).Should().BeFalse("Development only");
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        string[] emails = ["writer1@readin.test", "writer2@readin.test", "writer3@readin.test", "reader5@readin.test", "reviewer.dotnet@readin.test"];
        var demoUsers = await db.Users.Where(u => u.Email != null && emails.Contains(u.Email)).Select(u => u.Id).ToListAsync(Ct);

        try
        {
            (await seeder.SeedAsync(Ct)).Should().BeTrue();
            var first = await DemoRowsAsync();
            (await seeder.SeedAsync(Ct)).Should().BeTrue();
            var second = await DemoRowsAsync();

            second.Should().HaveSameCount(first, "a re-run replaces its requests").And.HaveCount(5);
            second.Select(r => r.Status).Should().BeEquivalentTo(
            [
                VerificationStatus.Pending, VerificationStatus.Pending, VerificationStatus.Pending, VerificationStatus.Rejected, VerificationStatus.Approved,
            ]);
            second.Where(r => r.ProofFilePath != null).Select(r => r.ProofFileContentType).Should().BeEquivalentTo(["image/png", "application/pdf"]);
            second.Where(r => r.ProofFilePath != null)
                .Should().OnlyContain(r => File.Exists(Path.Combine(api.PrivatePath, r.ProofFilePath!.Replace('/', Path.DirectorySeparatorChar))));
            second.Should().Contain(r => r.ProofFilePath == null && r.ProofUrl != null && r.Status == VerificationStatus.Pending, "one is URL only");
            var dotnetWriter = await db.Users.Where(u => u.Email == "reviewer.dotnet@readin.test").Select(u => u.Id).SingleAsync(Ct);
            second.Single(r => r.Status == VerificationStatus.Approved).UserId.Should().Be(dotnetWriter, "the .NET Writer's request was approved");
            foreach (var old in first.Where(r => r.ProofFilePath != null))
                File.Exists(Path.Combine(api.PrivatePath, old.ProofFilePath!.Replace('/', Path.DirectorySeparatorChar))).Should().BeFalse("replaced with its row");
            (await db.Notifications.CountAsync(n => demoUsers.Contains(n.UserId) && n.Type == NotificationTypes.VerificationResult, Ct))
                .Should().Be(0, "demo data notifies nobody");
        }
        finally
        {
            var files = await db.VerificationRequests.Where(r => demoUsers.Contains(r.UserId) && r.ProofFilePath != null).Select(r => r.ProofFilePath!).ToListAsync(Ct);
            await db.VerificationRequests.Where(r => demoUsers.Contains(r.UserId)).ExecuteDeleteAsync(Ct);
            foreach (var path in files) await scope.ServiceProvider.GetRequiredService<IPrivateFileStorage>().DeleteAsync(path, Ct);
        }

        Task<List<VerificationRequest>> DemoRowsAsync() =>
            db.VerificationRequests.AsNoTracking().Where(r => demoUsers.Contains(r.UserId)).ToListAsync(Ct);
    }

    // ---- Helpers ----

    private static MultipartFormDataContent Form(
        Guid? fieldId,
        string? jobTitle,
        string? proofUrl = null,
        string? note = null,
        byte[]? file = null,
        string fileName = "proof.png",
        string contentType = "application/octet-stream")
    {
        var form = new MultipartFormDataContent();
        if (fieldId is { } id) form.Add(new StringContent(id.ToString()), "fieldId");
        if (jobTitle is not null) form.Add(new StringContent(jobTitle), "jobTitle");
        if (proofUrl is not null) form.Add(new StringContent(proofUrl), "proofUrl");
        if (note is not null) form.Add(new StringContent(note), "note");
        if (file is not null)
        {
            var content = new ByteArrayContent(file);
            content.Headers.ContentType = new MediaTypeHeaderValue(contentType);
            form.Add(content, "proof", fileName);
        }
        return form;
    }

    private static Task<HttpResponseMessage> PostAsync(HttpClient client, MultipartFormDataContent form) =>
        client.PostAsync("/api/v1/verification-requests", form, Ct);

    private static async Task<JsonObject> SubmitAsync(HttpClient client, MultipartFormDataContent form)
    {
        var response = await PostAsync(client, form);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.Created, body);
        response.Headers.Location!.ToString().Should().Be("/api/v1/me/verification");
        return JsonNode.Parse(body)!.AsObject();
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

    private static List<string> Names(JsonNode? array) => [.. array!.AsArray().Select(n => n!.GetValue<string>())];

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
}
