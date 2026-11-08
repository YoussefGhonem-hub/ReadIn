using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Continue with Google or Apple, account linking and Settings → Account (SPEC §9.1, F18, ADR 0012).</summary>
[Collection(ApiCollection.Name)]
public sealed class ExternalAuthTests(ApiFactory api)
{
    private const string Reader9Phone = "+12025550118";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static string NewSubject() => $"sub-{Guid.NewGuid():N}";

    private static async Task<string> CodeOf(HttpResponseMessage response) =>
        (await TaxonomyAndContentTests.Problem(response))["code"]!.GetValue<string>();

    private Task<HttpResponseMessage> ExternalAsync(object body) =>
        api.GuestClient().PostAsJsonAsync("/api/v1/auth/external", body, Ct);

    private static object Google(string idToken) => new { provider = "google", idToken };

    private static object Apple(string idToken) => new { provider = "apple", idToken, nonce = FakeExternalIdentityVerifier.AppleNonce };

    /// <summary>What the web's own Google button sends: Google's one-time code, no ID token (ADR 0012).</summary>
    private static object GoogleCode(string idToken) =>
        new { provider = "google", authorizationCode = FakeGoogleCodeExchanger.Prefix + idToken };

    /// <summary>A new Google-only account, signed in.</summary>
    private async Task<(HttpClient Client, JsonObject Session, string Subject)> GoogleAccountAsync()
    {
        var subject = NewSubject();
        var session = await ApiFactory.ReadSessionAsync(
            await ExternalAsync(new { provider = "google", idToken = subject, createAccount = true, acceptTerms = true }));
        return (api.ClientWithToken(session["accessToken"]!.GetValue<string>()), session, subject);
    }

    [Fact]
    public async Task Config_lists_the_enabled_providers()
    {
        var config = await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/auth/config", Ct);

        config!["externalProviders"]!.AsArray().Select(p => p!.GetValue<string>()).Should().Equal("google", "apple");
        config["googleCodeSignIn"]!.GetValue<bool>().Should().BeTrue("the web client's secret is configured");
    }

    [Fact]
    public async Task The_web_buttons_google_code_signs_up_signs_in_and_confirms()
    {
        var subject = NewSubject();
        var email = $"{subject}@example.com";

        var unknown = await ExternalAsync(GoogleCode($"{subject}|{email}"));
        (await CodeOf(unknown)).Should().Be("auth.external_not_linked");

        var created = await ApiFactory.ReadSessionAsync(await ExternalAsync(new
        {
            provider = "google", authorizationCode = $"{FakeGoogleCodeExchanger.Prefix}{subject}|{email}", createAccount = true, acceptTerms = true,
        }));
        created["user"]!["email"]!.GetValue<string>().Should().Be(email);

        var again = await ApiFactory.ReadSessionAsync(await ExternalAsync(GoogleCode(subject)));
        again["user"]!["id"]!.GetValue<Guid>().Should().Be(created["user"]!["id"]!.GetValue<Guid>());

        // Settings → link and Delete account confirm with the same kind of credential.
        var user = await api.SignUpAsync();
        var linkSubject = NewSubject();
        var linked = await user.Client.PostAsJsonAsync(
            "/api/v1/me/external-logins", new { credential = GoogleCode(linkSubject), password = ApiFactory.TestPassword }, Ct);
        linked.StatusCode.Should().Be(HttpStatusCode.OK);
        (await linked.Content.ReadFromJsonAsync<JsonObject>(Ct))!["externalLogins"]![0]!["provider"]!.GetValue<string>().Should().Be("google");

        var client = api.ClientWithToken(created["accessToken"]!.GetValue<string>());
        var deleted = await client.SendAsync(
            new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me") { Content = JsonContent.Create(new { external = GoogleCode(subject) }) }, Ct);
        deleted.StatusCode.Should().Be(HttpStatusCode.NoContent);
    }

    [Fact]
    public async Task A_code_is_only_taken_from_google_and_bad_or_unreachable_codes_fail()
    {
        var appleCodeOnly = await ExternalAsync(new { provider = "apple", authorizationCode = "code-1", nonce = FakeExternalIdentityVerifier.AppleNonce });
        appleCodeOnly.StatusCode.Should().Be(HttpStatusCode.BadRequest, "Apple always sends its ID token");

        var nothing = await ExternalAsync(new { provider = "google" });
        nothing.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        var rejected = await ExternalAsync(new { provider = "google", authorizationCode = "used-or-foreign" });
        rejected.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await CodeOf(rejected)).Should().Be("auth.external_invalid");

        var down = await ExternalAsync(new { provider = "google", authorizationCode = FakeGoogleCodeExchanger.Down });
        down.StatusCode.Should().Be(HttpStatusCode.ServiceUnavailable);
        (await CodeOf(down)).Should().Be("auth.external_unavailable");

        var badToken = await ExternalAsync(GoogleCode("invalid"));
        (await CodeOf(badToken)).Should().Be("auth.external_invalid", "the traded ID token is checked like any other");
    }

    [Fact]
    public async Task An_unknown_identity_must_choose_and_then_gets_a_google_only_account()
    {
        var subject = NewSubject();
        var email = $"{subject}@example.com";

        var unknown = await ExternalAsync(Google($"{subject}|{email}"));
        unknown.StatusCode.Should().Be(HttpStatusCode.NotFound);
        (await CodeOf(unknown)).Should().Be("auth.external_not_linked");

        var created = await ApiFactory.ReadSessionAsync(
            await ExternalAsync(new { provider = "google", idToken = $"{subject}|{email}", createAccount = true, acceptTerms = true, uiLanguage = "ar" }));
        var me = created["user"]!;
        me["phoneNumber"].Should().BeNull();
        me["email"]!.GetValue<string>().Should().Be(email);
        me["hasPassword"]!.GetValue<bool>().Should().BeFalse();
        me["mustSetRecoveryPin"]!.GetValue<bool>().Should().BeFalse();
        me["isProfileComplete"]!.GetValue<bool>().Should().BeFalse();
        me["uiLanguage"]!.GetValue<string>().Should().Be("ar");
        me["externalLogins"]![0]!["provider"]!.GetValue<string>().Should().Be("google");

        var again = await ApiFactory.ReadSessionAsync(await ExternalAsync(Google(subject)));
        again["user"]!["id"]!.GetValue<Guid>().Should().Be(me["id"]!.GetValue<Guid>());

        // Sessions of accounts without a password refresh like any other.
        var refreshed = await api.GuestClient().PostAsJsonAsync(
            "/api/v1/auth/refresh", new { refreshToken = again["refreshToken"]!.GetValue<string>() }, Ct);
        refreshed.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Apple_needs_the_nonce_and_uses_the_name_the_app_sends()
    {
        var subject = NewSubject();

        var noNonce = await ExternalAsync(new { provider = "apple", idToken = subject, createAccount = true, acceptTerms = true });
        noNonce.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await CodeOf(noNonce)).Should().Be("auth.external_invalid");

        var created = await ApiFactory.ReadSessionAsync(await ExternalAsync(new
        {
            provider = "apple", idToken = subject, nonce = FakeExternalIdentityVerifier.AppleNonce, displayName = "Mona Ali", createAccount = true, acceptTerms = true,
        }));
        created["user"]!["displayName"]!.GetValue<string>().Should().Be("Mona Ali");
    }

    [Fact]
    public async Task Bad_tokens_and_unknown_providers_are_rejected()
    {
        var invalid = await ExternalAsync(Google("invalid"));
        invalid.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await CodeOf(invalid)).Should().Be("auth.external_invalid");

        var unknown = await ExternalAsync(new { provider = "facebook", idToken = NewSubject() });
        unknown.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await unknown.Content.ReadAsStringAsync(Ct)).Should().Contain("provider.invalid");

        var both = await ExternalAsync(new
        {
            provider = "google", idToken = NewSubject(), createAccount = true, acceptTerms = true, link = new { phoneNumber = Reader9Phone, password = "x" },
        });
        both.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task A_verified_email_links_to_the_account_that_has_it()
    {
        var reader9 = await (await api.SeedUserClientAsync(Reader9Phone)).GetFromJsonAsync<JsonObject>("/api/v1/me", Ct);
        var subject = NewSubject();

        var unverified = await ExternalAsync(Google($"{subject}|reader9@readin.test|unverified"));
        (await CodeOf(unverified)).Should().Be("auth.external_not_linked");

        var linked = await ApiFactory.ReadSessionAsync(await ExternalAsync(Google($"{subject}|reader9@readin.test")));
        linked["user"]!["id"]!.GetValue<Guid>().Should().Be(reader9!["id"]!.GetValue<Guid>());
        linked["user"]!["externalLogins"]!.AsArray().Select(l => l!["provider"]!.GetValue<string>()).Should().Contain("google");
    }

    [Fact]
    public async Task Phone_and_password_link_an_identity_to_an_existing_account()
    {
        var owner = await api.SignUpAsync();
        var other = await api.SignUpAsync();
        var subject = NewSubject();

        var wrong = await ExternalAsync(new
        {
            provider = "google", idToken = subject, link = new { phoneNumber = owner.PhoneNumber, password = "Wrong-pass-1" },
        });
        wrong.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await CodeOf(wrong)).Should().Be("auth.invalid_credentials");

        var linked = await ApiFactory.ReadSessionAsync(await ExternalAsync(new
        {
            provider = "google", idToken = subject, link = new { phoneNumber = owner.PhoneNumber, password = ApiFactory.TestPassword },
        }));
        linked["user"]!["id"]!.GetValue<Guid>().Should().Be(owner.Id);
        linked["user"]!["hasPassword"]!.GetValue<bool>().Should().BeTrue();

        var signedIn = await ApiFactory.ReadSessionAsync(await ExternalAsync(Google(subject)));
        signedIn["user"]!["id"]!.GetValue<Guid>().Should().Be(owner.Id);

        var secondGoogle = await ExternalAsync(new
        {
            provider = "google", idToken = NewSubject(), link = new { phoneNumber = owner.PhoneNumber, password = ApiFactory.TestPassword },
        });
        secondGoogle.StatusCode.Should().Be(HttpStatusCode.Conflict);
        (await CodeOf(secondGoogle)).Should().Be("auth.external_conflict");

        var taken = await ExternalAsync(new
        {
            provider = "google", idToken = subject, link = new { phoneNumber = other.PhoneNumber, password = ApiFactory.TestPassword },
        });
        taken.StatusCode.Should().Be(HttpStatusCode.Conflict);
        (await CodeOf(taken)).Should().Be("auth.external_in_use");
    }

    [Fact]
    public async Task Suspended_accounts_cannot_link_or_sign_in()
    {
        var response = await ExternalAsync(new
        {
            provider = "google", idToken = NewSubject(), link = new { phoneNumber = ApiFactory.SuspendedPhone, password = ApiFactory.DemoPassword },
        });

        response.StatusCode.Should().Be(HttpStatusCode.Forbidden);
        (await CodeOf(response)).Should().Be("user.suspended");
    }

    [Fact]
    public async Task Settings_links_and_unlinks_with_the_password()
    {
        var user = await api.SignUpAsync();
        var (_, _, someoneElses) = await GoogleAccountAsync();
        var subject = NewSubject();

        var unconfirmed = await user.Client.PostAsJsonAsync("/api/v1/me/external-logins", new { credential = Apple(subject) }, Ct);
        (await CodeOf(unconfirmed)).Should().Be("auth.confirmation_required");

        var wrong = await user.Client.PostAsJsonAsync(
            "/api/v1/me/external-logins", new { credential = Apple(subject), password = "Wrong-pass-1" }, Ct);
        (await CodeOf(wrong)).Should().Be("auth.wrong_password");

        var linked = await user.Client.PostAsJsonAsync(
            "/api/v1/me/external-logins", new { credential = Apple(subject), password = ApiFactory.TestPassword }, Ct);
        linked.StatusCode.Should().Be(HttpStatusCode.OK);
        (await linked.Content.ReadFromJsonAsync<JsonObject>(Ct))!["externalLogins"]![0]!["provider"]!.GetValue<string>().Should().Be("apple");

        var inUse = await user.Client.PostAsJsonAsync(
            "/api/v1/me/external-logins", new { credential = Google(someoneElses), password = ApiFactory.TestPassword }, Ct);
        inUse.StatusCode.Should().Be(HttpStatusCode.Conflict);
        (await CodeOf(inUse)).Should().Be("auth.external_in_use");

        var unlinked = await user.Client.DeleteAsync("/api/v1/me/external-logins/apple", Ct);
        unlinked.StatusCode.Should().Be(HttpStatusCode.OK);
        (await unlinked.Content.ReadFromJsonAsync<JsonObject>(Ct))!["externalLogins"]!.AsArray().Should().BeEmpty();

        var notLinked = await user.Client.DeleteAsync("/api/v1/me/external-logins/apple", Ct);
        notLinked.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task A_google_only_account_adds_phone_sign_in_and_keeps_its_last_method()
    {
        var (client, session, subject) = await GoogleAccountAsync();
        var phone = ApiFactory.NewPhoneNumber();

        var last = await client.DeleteAsync("/api/v1/me/external-logins/google", Ct);
        last.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await CodeOf(last)).Should().Be("auth.last_sign_in_method");

        var body = new { phoneNumber = phone, password = ApiFactory.TestPassword, recoveryPin = ApiFactory.TestPin, external = Google(NewSubject()) };
        var mismatch = await client.PostAsJsonAsync("/api/v1/me/phone-sign-in", body, Ct);
        (await CodeOf(mismatch)).Should().Be("auth.external_mismatch");

        var added = await ApiFactory.ReadSessionAsync(await client.PostAsJsonAsync(
            "/api/v1/me/phone-sign-in", body with { external = Google(subject) }, Ct));
        var me = added["user"]!;
        me["phoneNumber"]!.GetValue<string>().Should().Be(phone);
        me["hasPassword"]!.GetValue<bool>().Should().BeTrue();
        me["hasRecoveryPin"]!.GetValue<bool>().Should().BeTrue();
        me["mustSetRecoveryPin"]!.GetValue<bool>().Should().BeFalse();

        // The old access token was signed out with the other sessions.
        (await client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        var login = await api.GuestClient().PostAsJsonAsync("/api/v1/auth/login", new { phoneNumber = phone, password = ApiFactory.TestPassword }, Ct);
        (await ApiFactory.ReadSessionAsync(login))["user"]!["id"]!.GetValue<Guid>().Should().Be(session["user"]!["id"]!.GetValue<Guid>());

        var fresh = api.ClientWithToken(added["accessToken"]!.GetValue<string>());
        var twice = await fresh.PostAsJsonAsync("/api/v1/me/phone-sign-in", body with { external = Google(subject) }, Ct);
        (await CodeOf(twice)).Should().Be("auth.phone_sign_in_exists");

        (await fresh.DeleteAsync("/api/v1/me/external-logins/google", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Deleting_a_google_only_account_is_confirmed_with_google_and_frees_the_identity()
    {
        var (client, session, subject) = await GoogleAccountAsync();

        var unconfirmed = await client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me") { Content = JsonContent.Create(new { }) }, Ct);
        (await CodeOf(unconfirmed)).Should().Be("auth.confirmation_required");

        var mismatch = await client.SendAsync(
            new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me") { Content = JsonContent.Create(new { external = Google(NewSubject()) }) }, Ct);
        (await CodeOf(mismatch)).Should().Be("auth.external_mismatch");

        var deleted = await client.SendAsync(
            new HttpRequestMessage(HttpMethod.Delete, "/api/v1/me") { Content = JsonContent.Create(new { external = Google(subject) }) }, Ct);
        deleted.StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await CodeOf(await ExternalAsync(Google(subject)))).Should().Be("auth.external_not_linked");
        var again = await ApiFactory.ReadSessionAsync(await ExternalAsync(new { provider = "google", idToken = subject, createAccount = true, acceptTerms = true }));
        again["user"]!["id"]!.GetValue<Guid>().Should().NotBe(session["user"]!["id"]!.GetValue<Guid>());
    }
}
