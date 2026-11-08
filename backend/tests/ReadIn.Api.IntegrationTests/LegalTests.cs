using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Application.Features.Legal;
using ReadIn.Domain.Identity;

namespace ReadIn.Api.IntegrationTests;

/// <summary>F37 Terms of Use: the version and pages, the sign-up box, and accepting a newer version (contract "Legal").</summary>
[Collection(ApiCollection.Name)]
public sealed class LegalTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private string Current => api.Services.GetRequiredService<TermsOfUse>().CurrentVersion;

    private Task<HttpResponseMessage> RegisterAsync(string phone, bool? acceptTerms) =>
        api.GuestClient().PostAsJsonAsync("/api/v1/auth/register", new
        {
            phoneNumber = phone,
            password = ApiFactory.TestPassword,
            recoveryPin = ApiFactory.TestPin,
            uiLanguage = "en",
            timeZone = "Africa/Cairo",
            acceptTerms,
        }, Ct);

    private Task<HttpResponseMessage> ExternalAsync(object body) =>
        api.GuestClient().PostAsJsonAsync("/api/v1/auth/external", body, Ct);

    private Task<List<AuditLog>> TermsAuditsAsync(Guid userId) => api.InDbAsync(db =>
        db.AuditLogs.AsNoTracking().Where(a => a.Action == AuditActions.TermsAccepted && a.UserId == userId).ToListAsync(Ct));

    [Fact]
    public async Task Anyone_reads_the_terms_version_and_where_the_legal_pages_are()
    {
        var response = await api.GuestClient().GetAsync("/api/v1/legal", Ct);
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.OK, body);
        response.Headers.CacheControl!.Public.Should().BeTrue();
        response.Headers.CacheControl.MaxAge.Should().Be(TimeSpan.FromMinutes(5));

        var legal = JsonNode.Parse(body)!.AsObject();
        legal.Select(p => p.Key).Should().BeEquivalentTo("termsVersion", "effectiveAt", "summary", "pages");
        legal["termsVersion"]!.GetValue<string>().Should().Be(Current).And.Be("2026-11-08", "appsettings.json's Legal:TermsVersion");
        legal["summary"]!.AsObject().Select(p => p.Key).Should().BeEquivalentTo("ar", "en");
        legal["pages"]!.ToJsonString().Should().Be("""{"terms":"/terms","communityGuidelines":"/community-guidelines","privacy":"/privacy"}""");
    }

    [Fact]
    public async Task Signing_up_needs_the_terms_box_and_records_the_version_accepted()
    {
        var phone = ApiFactory.NewPhoneNumber();

        foreach (var box in new bool?[] { null, false })
        {
            var problem = await RegisterAsync(phone, box).ProblemAsync(HttpStatusCode.BadRequest, "auth.terms_required");
            problem["title"]!.GetValue<string>().Should().Contain("Terms of Use");
        }
        (await api.InDbAsync(db => db.Users.IgnoreQueryFilters().AnyAsync(u => u.PhoneNumber == phone, Ct)))
            .Should().BeFalse("nothing is created without the box");
        // The box is checked first: even a taken number answers that the box is missing.
        await RegisterAsync(ApiFactory.Reader1Phone, acceptTerms: null).ProblemAsync(HttpStatusCode.BadRequest, "auth.terms_required");

        var session = await ApiFactory.ReadSessionAsync(await RegisterAsync(phone, acceptTerms: true));
        var me = session["user"]!;
        me["termsVersion"]!.GetValue<string>().Should().Be(Current);
        me["mustAcceptTerms"]!.GetValue<bool>().Should().BeFalse();

        var id = me["id"]!.GetValue<Guid>();
        var user = await api.InDbAsync(db => db.Users.AsNoTracking().SingleAsync(u => u.Id == id, Ct));
        user.TermsVersion.Should().Be(Current);
        user.TermsAcceptedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(1));
        var audit = (await TermsAuditsAsync(id)).Should().ContainSingle().Subject;
        audit.Details.Should().Be(Current);
        audit.TargetId.Should().Be(id);
    }

    [Fact]
    public async Task Creating_an_account_with_google_or_apple_needs_the_box_but_signing_in_again_does_not()
    {
        var subject = $"sub-{Guid.NewGuid():N}";

        await ExternalAsync(new { provider = "google", idToken = subject, createAccount = true })
            .ProblemAsync(HttpStatusCode.BadRequest, "auth.terms_required");
        await ExternalAsync(new { provider = "google", idToken = subject, createAccount = true, acceptTerms = false })
            .ProblemAsync(HttpStatusCode.BadRequest, "auth.terms_required");
        // Nothing was made: the identity is still unknown.
        await ExternalAsync(new { provider = "google", idToken = subject }).ProblemAsync(HttpStatusCode.NotFound, "auth.external_not_linked");

        var created = await ApiFactory.ReadSessionAsync(
            await ExternalAsync(new { provider = "google", idToken = subject, createAccount = true, acceptTerms = true }));
        created["user"]!["termsVersion"]!.GetValue<string>().Should().Be(Current);
        created["user"]!["mustAcceptTerms"]!.GetValue<bool>().Should().BeFalse();
        (await TermsAuditsAsync(created["user"]!["id"]!.GetValue<Guid>())).Should().ContainSingle();

        var again = await ApiFactory.ReadSessionAsync(await ExternalAsync(new { provider = "google", idToken = subject }));
        again["user"]!["id"]!.GetValue<Guid>().Should().Be(created["user"]!["id"]!.GetValue<Guid>());
    }

    [Fact]
    public async Task A_newer_version_is_accepted_once_and_nothing_else_waits_for_it()
    {
        var user = await api.UserAsync("Terms Reader");
        await api.InDbAsync(async db =>
        {
            var row = await db.Users.SingleAsync(u => u.Id == user.Id, Ct);
            row.AcceptTerms("2020-01-01", DateTime.UtcNow.AddYears(-1)); // an older version, as if the terms changed since
            await db.SaveChangesAsync(Ct);
        });

        var me = await user.Client.GetAsync("/api/v1/me", Ct).OkJsonAsync();
        me["termsVersion"]!.GetValue<string>().Should().Be("2020-01-01");
        me["mustAcceptTerms"]!.GetValue<bool>().Should().BeTrue();
        // Only the terms screen asks: the app keeps working until then.
        (await user.Client.PatchAsJsonAsync("/api/v1/me", new
        {
            displayName = user.Me["displayName"]!.GetValue<string>(),
            username = user.Me["username"]!.GetValue<string>(),
            bio = "Still reading.",
        }, Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);

        var before = (await TermsAuditsAsync(user.Id)).Count;
        var accepted = await user.Client.PostAsync("/api/v1/me/terms/accept", null, Ct).OkJsonAsync();
        accepted["termsVersion"]!.GetValue<string>().Should().Be(Current);
        accepted["mustAcceptTerms"]!.GetValue<bool>().Should().BeFalse();
        accepted["id"]!.GetValue<Guid>().Should().Be(user.Id, "the route answers with the refreshed profile");

        var audits = await TermsAuditsAsync(user.Id);
        audits.Should().HaveCount(before + 1);
        audits.OrderBy(a => a.CreatedAt).Last().Details.Should().Be(Current);

        // Idempotent: a second accept changes nothing and records nothing.
        var at = await api.InDbAsync(db => db.Users.AsNoTracking().Where(u => u.Id == user.Id).Select(u => u.TermsAcceptedAt).SingleAsync(Ct));
        (await user.Client.PostAsync("/api/v1/me/terms/accept", null, Ct).OkJsonAsync())["mustAcceptTerms"]!.GetValue<bool>().Should().BeFalse();
        (await TermsAuditsAsync(user.Id)).Should().HaveCount(before + 1);
        (await api.InDbAsync(db => db.Users.AsNoTracking().Where(u => u.Id == user.Id).Select(u => u.TermsAcceptedAt).SingleAsync(Ct)))
            .Should().Be(at);
    }

    [Fact]
    public async Task Accepting_the_terms_needs_a_session()
    {
        (await api.GuestClient().PostAsync("/api/v1/me/terms/accept", null, Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }
}
