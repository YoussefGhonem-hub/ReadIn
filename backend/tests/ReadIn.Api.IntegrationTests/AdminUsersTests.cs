using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Identity;
using ReadIn.Infrastructure.Persistence.Seeding;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// F23 admin console, Users: the table (search, filters, sort, masked numbers, last seen), a user's page and its sections per
/// permission, revealing one phone number (audited) and signing an account out of every device, with the protected accounts.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class AdminUsersTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    [Fact]
    public async Task Every_users_route_is_for_admins_only()
    {
        var someone = await api.UserAsync();
        await api.AssertAdminOnlyAsync(HttpMethod.Get, "/api/v1/admin/users");
        await api.AssertAdminOnlyAsync(HttpMethod.Get, $"/api/v1/admin/users/{someone.Id}");
        await api.AssertAdminOnlyAsync(HttpMethod.Get, $"/api/v1/admin/users/{someone.Id}/phone");
        await api.AssertAdminOnlyAsync(HttpMethod.Post, $"/api/v1/admin/users/{someone.Id}/logout-all");
    }

    [Fact]
    public async Task The_table_finds_people_by_name_handle_and_id_with_masked_numbers_and_last_seen()
    {
        var admin = await api.SuperAdminAsync();
        var name = $"Zainab {Guid.NewGuid():N}"[..20];
        var target = await api.UserAsync(name);
        var username = target.Me["username"]!.GetValue<string>();

        var byName = (await admin.Client.GetAsync($"/api/v1/admin/users?q={Uri.EscapeDataString(name)}", Ct).OkJsonAsync()).PageItems();
        var row = byName.Single()!.AsObject();
        row.Select(p => p.Key).Should().BeEquivalentTo(
            "id", "displayName", "username", "avatarUrl", "isVerified", "isSystemAccount", "roles", "signInMethods", "phoneMasked", "joinedAt",
            "lastSeenAt", "publishedArticles", "followers", "status", "suspendedUntil", "openReports");
        row["id"]!.GetValue<Guid>().Should().Be(target.Id);
        row["roles"]!.AsArray().Select(r => r!.GetValue<string>()).Should().Equal("Member");
        row["signInMethods"]!.AsArray().Select(m => m!.GetValue<string>()).Should().Equal("phone");
        row["status"]!.GetValue<string>().Should().Be("active");
        // +1 202 555 01XX → "+1***01XX": never the whole number in a list.
        row["phoneMasked"]!.GetValue<string>().Should().Be($"+1***{target.PhoneNumber[^4..]}");
        // Completing the profile was a signed-in request: the account was seen.
        row["lastSeenAt"]!.GetValue<DateTime>().Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(5));

        (await admin.Client.GetAsync($"/api/v1/admin/users?q=%40{username}", Ct).OkJsonAsync()).PageItems()
            .Select(r => r!["id"]!.GetValue<Guid>()).Should().Equal(target.Id);
        (await admin.Client.GetAsync($"/api/v1/admin/users?q={target.Id}", Ct).OkJsonAsync()).PageItems()
            .Select(r => r!["id"]!.GetValue<Guid>()).Should().Equal(target.Id);
    }

    [Fact]
    public async Task Searching_by_phone_number_needs_users_read_pii()
    {
        var admin = await api.SuperAdminAsync();
        var reader = await api.UserWithPermissionsAsync("Users Reader", Permissions.Users.Read);
        var target = await api.UserAsync("Phone Owner");
        var phone = Uri.EscapeDataString(target.PhoneNumber);

        (await admin.Client.GetAsync($"/api/v1/admin/users?q={phone}", Ct).OkJsonAsync()).PageItems()
            .Select(r => r!["id"]!.GetValue<Guid>()).Should().Equal(target.Id);
        (await reader.Client.GetAsync($"/api/v1/admin/users?q={phone}", Ct).OkJsonAsync()).PageItems().Should().BeEmpty();
    }

    [Fact]
    public async Task Filters_and_sorting_work_and_bad_values_are_validation_errors()
    {
        var admin = await api.SuperAdminAsync();
        var tag = $"Filter{Guid.NewGuid():N}"[..14];
        var plain = await api.UserAsync($"{tag} Plain");
        var popular = await api.UserAsync($"{tag} Popular");
        var reported = await api.UserAsync($"{tag} Reported");
        var suspended = await api.UserAsync($"{tag} Suspended");
        foreach (var fan in new[] { plain, reported })
            (await fan.Client.PutAsync($"/api/v1/users/{popular.Id}/follow", null, Ct)).EnsureSuccessStatusCode();
        (await plain.Client.PostAsJsonAsync("/api/v1/reports", new { targetType = "user", targetId = reported.Id, reason = "spam" }, Ct))
            .EnsureSuccessStatusCode();
        (await admin.Client.PostAsJsonAsync("/api/v1/moderation/actions",
            new { action = "suspend", targetType = "user", targetId = suspended.Id, note = "Spam.", durationDays = 7 }, Ct)).EnsureSuccessStatusCode();

        async Task<List<Guid>> IdsAsync(string query) =>
            [.. (await admin.Client.GetAsync($"/api/v1/admin/users?q={tag}&{query}", Ct).OkJsonAsync()).PageItems()
                .Select(r => r!["id"]!.GetValue<Guid>())];

        (await IdsAsync("status=suspended")).Should().Equal(suspended.Id);
        (await IdsAsync("status=active")).Should().NotContain(suspended.Id).And.HaveCount(3);
        (await IdsAsync("hasReports=true")).Should().Equal(reported.Id);
        (await IdsAsync("method=google")).Should().BeEmpty();
        (await IdsAsync("verified=true")).Should().BeEmpty();
        (await IdsAsync("sort=followers")).First().Should().Be(popular.Id);
        (await IdsAsync("sort=openReports")).First().Should().Be(reported.Id);
        (await IdsAsync("sort=joined&dir=asc")).Should().Equal(plain.Id, popular.Id, reported.Id, suspended.Id);
        (await IdsAsync("pageSize=2&page=2")).Should().HaveCount(2);

        var suspendedRow = (await admin.Client.GetAsync($"/api/v1/admin/users?q={tag}&status=suspended", Ct).OkJsonAsync()).PageItems().Single()!;
        suspendedRow["status"]!.GetValue<string>().Should().Be("suspended");
        suspendedRow["suspendedUntil"]!.GetValue<DateTime>().Should().BeCloseTo(DateTime.UtcNow.AddDays(7), TimeSpan.FromMinutes(5));
        var reportedRow = (await admin.Client.GetAsync($"/api/v1/admin/users?q={tag}&hasReports=true", Ct).OkJsonAsync()).PageItems().Single()!;
        reportedRow["openReports"]!.GetValue<int>().Should().Be(1);

        foreach (var (parameter, value) in new[]
                 {
                     ("status", "gone"), ("verified", "maybe"), ("method", "email"), ("joinedFrom", "07-11-2026"), ("hasReports", "x"), ("sort", "name"),
                     ("dir", "up"),
                 })
        {
            var problem = await admin.Client.GetAsync($"/api/v1/admin/users?{parameter}={value}", Ct)
                .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
            problem["errors"]![parameter]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.invalid");
        }
        var tooLong = await admin.Client.GetAsync($"/api/v1/admin/users?q={new string('a', 101)}", Ct)
            .ProblemAsync(HttpStatusCode.BadRequest, "validation.failed");
        tooLong["errors"]!["q"]!.AsArray().Select(e => e!.GetValue<string>()).Should().Equal("validation.max_length");
    }

    [Fact]
    public async Task A_users_page_has_every_section_for_the_SuperAdmin_and_none_without_their_permissions()
    {
        var admin = await api.SuperAdminAsync();
        var reader = await api.UserWithPermissionsAsync("Users Only", Permissions.Users.Read);
        var target = await api.UserAsync("Page Target");
        await target.Client.PublishAsync();

        var page = await admin.Client.GetAsync($"/api/v1/admin/users/{target.Id}", Ct).OkJsonAsync();
        page["id"]!.GetValue<Guid>().Should().Be(target.Id);
        page["signUpMethod"]!.GetValue<string>().Should().Be("phone");
        page["isStaff"]!.GetValue<bool>().Should().BeFalse();
        page["publishedArticles"]!.GetValue<int>().Should().Be(1);
        page["stats"]!["drafts"]!.GetValue<int>().Should().Be(0);
        page["access"]!["activeSessions"]!.GetValue<int>().Should().Be(1);
        page["access"]!["hasRecoveryPin"]!.GetValue<bool>().Should().BeTrue();
        page["actions"]!.AsObject().Where(p => p.Value!.GetValue<bool>()).Select(p => p.Key).Should().BeEquivalentTo(
            "canSuspend", "canWarn", "canLogoutAll", "canResetPassword", "canClearProfile", "canRevealPhone");
        page["moderation"]!["history"]!.AsArray().Should().BeEmpty();
        page["reports"]!["againstTotal"]!.GetValue<int>().Should().Be(0);
        page["verification"]!["total"]!.GetValue<int>().Should().Be(0);
        page["tickets"]!["items"]!.AsArray().Should().BeEmpty();
        page["audit"]!["items"]!.AsArray().Should().NotBeNull();

        var limited = await reader.Client.GetAsync($"/api/v1/admin/users/{target.Id}", Ct).OkJsonAsync();
        foreach (var section in new[] { "moderation", "reports", "verification", "tickets", "audit" }) limited[section].Should().BeNull(section);
        limited["actions"]!.AsObject().Where(p => p.Value!.GetValue<bool>()).Should().BeEmpty();

        // Another SuperAdmin and the official account are staff: nothing to suspend, warn or sign out.
        var otherAdmin = await api.SuperAdminAsync("Other Admin");
        foreach (var staff in new[] { otherAdmin.Id, SystemUsers.EditorialId })
        {
            var staffPage = await admin.Client.GetAsync($"/api/v1/admin/users/{staff}", Ct).OkJsonAsync();
            staffPage["isStaff"]!.GetValue<bool>().Should().BeTrue();
            (staffPage["actions"]!["canSuspend"]!.GetValue<bool>(), staffPage["actions"]!["canLogoutAll"]!.GetValue<bool>()).Should().Be((false, false));
        }

        await admin.Client.GetAsync($"/api/v1/admin/users/{Guid.NewGuid()}", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
    }

    [Fact]
    public async Task Revealing_a_phone_number_is_audited_and_needs_users_read_pii()
    {
        var admin = await api.SuperAdminAsync();
        var reader = await api.UserWithPermissionsAsync("No PII", Permissions.Users.Read);
        var target = await api.UserAsync("Reveal Me");

        var response = await admin.Client.GetAsync($"/api/v1/admin/users/{target.Id}/phone", Ct);
        response.Headers.CacheControl!.NoStore.Should().BeTrue();
        var phone = JsonNode.Parse(await response.Content.ReadAsStringAsync(Ct))!;
        phone["phoneNumber"]!.GetValue<string>().Should().Be(target.PhoneNumber);
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == AuditActions.PiiViewed && l.UserId == target.Id && l.ActorId == admin.Id, Ct)))
            .Should().Be(1);

        await reader.Client.GetAsync($"/api/v1/admin/users/{target.Id}/phone", Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
        await admin.Client.GetAsync($"/api/v1/admin/users/{Guid.NewGuid()}/phone", Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
    }

    [Fact]
    public async Task Signing_an_account_out_everywhere_ends_its_sessions_but_never_for_protected_accounts()
    {
        var admin = await api.SuperAdminAsync();
        var target = await api.UserAsync("Sign Me Out");
        (await target.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);

        await admin.Client.PostAsync($"/api/v1/admin/users/{target.Id}/logout-all", null, Ct).NoContentAsync();
        (await target.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        await api.GuestClient().PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = target.RefreshToken }, Ct)
            .ProblemAsync(HttpStatusCode.Unauthorized, "auth.refresh_invalid");
        (await api.InDbAsync(db => db.AuditLogs.CountAsync(l => l.Action == AuditActions.SessionsRevoked && l.UserId == target.Id, Ct))).Should().Be(1);

        await admin.Client.PostAsync($"/api/v1/admin/users/{admin.Id}/logout-all", null, Ct).ProblemAsync(HttpStatusCode.BadRequest, "moderation.self");
        var otherAdmin = await api.SuperAdminAsync("Protected Admin");
        await admin.Client.PostAsync($"/api/v1/admin/users/{otherAdmin.Id}/logout-all", null, Ct)
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");
        await admin.Client.PostAsync($"/api/v1/admin/users/{SystemUsers.EditorialId}/logout-all", null, Ct)
            .ProblemAsync(HttpStatusCode.Forbidden, "moderation.staff_target");
        await admin.Client.PostAsync($"/api/v1/admin/users/{Guid.NewGuid()}/logout-all", null, Ct).ProblemAsync(HttpStatusCode.NotFound, "user.not_found");
        (await otherAdmin.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Last_seen_is_written_at_most_once_an_hour_and_never_on_the_users_row()
    {
        var user = await api.UserAsync("Seen Often");
        var rowVersion = await api.InDbAsync(db => db.Users.Where(u => u.Id == user.Id).Select(u => u.RowVersion).SingleAsync(Ct));
        var first = await api.InDbAsync(db => db.UserPresence.Where(p => p.UserId == user.Id).Select(p => p.LastSeenAt).SingleAsync(Ct));

        // Moved back two hours: the next calls this hour still don't write (the in-memory check), so it stays.
        var earlier = first.AddHours(-2);
        await api.InDbAsync(db => db.UserPresence.Where(p => p.UserId == user.Id).ExecuteUpdateAsync(p => p.SetProperty(x => x.LastSeenAt, earlier), Ct));
        for (var i = 0; i < 3; i++) (await user.Client.GetAsync("/api/v1/me", Ct)).EnsureSuccessStatusCode();

        (await api.InDbAsync(db => db.UserPresence.Where(p => p.UserId == user.Id).Select(p => p.LastSeenAt).SingleAsync(Ct)))
            .Should().BeCloseTo(earlier, TimeSpan.FromSeconds(1));
        (await api.InDbAsync(db => db.Users.Where(u => u.Id == user.Id).Select(u => u.RowVersion).SingleAsync(Ct))).Should().Equal(rowVersion);
    }
}
