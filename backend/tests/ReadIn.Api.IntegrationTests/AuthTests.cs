using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Hosting;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using ReadIn.Application.Common.Security;

namespace ReadIn.Api.IntegrationTests;

/// <summary>Phone + password sign in, rotating refresh tokens, PIN recovery and account security (SPEC §9, ADR 0007).</summary>
[Collection(ApiCollection.Name)]
public sealed class AuthTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static async Task<string> CodeOf(HttpResponseMessage response) =>
        (await TaxonomyAndContentTests.Problem(response))["code"]!.GetValue<string>();

    private static async Task<string[]> ErrorsOf(HttpResponseMessage response, string property) =>
        ErrorsOf(await TaxonomyAndContentTests.Problem(response), property);

    private static string[] ErrorsOf(JsonObject problem, string property) =>
        [.. problem["errors"]![property]!.AsArray().Select(e => e!.GetValue<string>())];

    private Task<HttpResponseMessage> LoginAsync(string phone, string password, HttpClient? client = null) =>
        (client ?? api.GuestClient()).PostAsJsonAsync("/api/v1/auth/login", new { phoneNumber = phone, password }, Ct);

    private Task<HttpResponseMessage> RefreshAsync(string refreshToken) =>
        api.GuestClient().PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken }, Ct);

    [Fact]
    public async Task Config_exposes_the_pin_length_and_password_rules()
    {
        var config = await api.GuestClient().GetFromJsonAsync<JsonObject>("/api/v1/auth/config", Ct);

        config!["pinLength"]!.GetValue<int>().Should().Be(4);
        config["password"]!["minLength"]!.GetValue<int>().Should().Be(8);
    }

    [Fact]
    public async Task Register_validates_phone_password_and_pin_with_codes()
    {
        var response = await api.GuestClient().PostAsJsonAsync("/api/v1/auth/register",
            new { phoneNumber = "+20223456789", password = "qwerty123", recoveryPin = "1234" }, Ct);

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var problem = await TaxonomyAndContentTests.Problem(response);
        ErrorsOf(problem, "phoneNumber").Should().Equal("phone.invalid");
        ErrorsOf(problem, "password").Should().Contain("password.too_common");
        ErrorsOf(problem, "recoveryPin").Should().Equal("pin.weak");
    }

    [Fact]
    public async Task A_number_can_only_have_one_account()
    {
        var user = await api.SignUpAsync();

        var again = await api.GuestClient().PostAsJsonAsync("/api/v1/auth/register",
            new { phoneNumber = user.PhoneNumber, password = ApiFactory.TestPassword, recoveryPin = ApiFactory.TestPin }, Ct);

        again.StatusCode.Should().Be(HttpStatusCode.Conflict);
        (await CodeOf(again)).Should().Be("auth.phone_taken");
    }

    [Fact]
    public async Task Wrong_password_and_unknown_number_get_the_same_generic_error()
    {
        var user = await api.SignUpAsync();

        var wrong = await LoginAsync(user.PhoneNumber, "Wrong-pass-99");
        var unknown = await LoginAsync(ApiFactory.NewPhoneNumber(), ApiFactory.TestPassword);
        var notANumber = await LoginAsync("hello", ApiFactory.TestPassword);

        foreach (var response in new[] { wrong, unknown, notANumber })
        {
            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
            (await CodeOf(response)).Should().Be("auth.invalid_credentials");
        }
        (await TaxonomyAndContentTests.Problem(await LoginAsync(user.PhoneNumber, "Wrong-pass-99", api.GuestClient("ar"))))["title"]!
            .GetValue<string>().Should().Be("رقم التليفون أو كلمة السر غلط.");
    }

    [Fact]
    public async Task Five_wrong_passwords_lock_the_account()
    {
        var user = await api.SignUpAsync();

        HttpResponseMessage last = null!;
        for (var i = 0; i < 5; i++) last = await LoginAsync(user.PhoneNumber, $"Wrong-pass-{i}");

        last.StatusCode.Should().Be(HttpStatusCode.TooManyRequests);
        (await CodeOf(last)).Should().Be("auth.locked_out");
    }

    [Fact]
    public async Task Refresh_rotates_and_a_reused_token_ends_the_session()
    {
        var user = await api.SignUpAsync();

        var first = await ApiFactory.ReadSessionAsync(await RefreshAsync(user.RefreshToken));
        var second = first["refreshToken"]!.GetValue<string>();
        second.Should().NotBe(user.RefreshToken);
        first["user"]!["id"]!.GetValue<Guid>().Should().Be(user.Id);
        (await api.ClientWithToken(first["accessToken"]!.GetValue<string>()).GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);

        var reused = await RefreshAsync(user.RefreshToken);
        reused.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await CodeOf(reused)).Should().Be("auth.refresh_invalid");

        (await RefreshAsync(second)).StatusCode.Should().Be(HttpStatusCode.Unauthorized, "reuse of a rotated token revokes the whole family");
    }

    [Fact]
    public async Task A_refresh_that_races_another_within_the_grace_window_keeps_the_session()
    {
        await using var graceful = api.WithWebHostBuilder(builder => builder.UseSetting("Auth:RefreshReuseGrace", "00:00:30"));
        var client = graceful.CreateClient();
        var user = await api.SignUpAsync();

        var first = await client.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = user.RefreshToken }, Ct);
        var raced = await client.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = user.RefreshToken }, Ct);

        first.StatusCode.Should().Be(HttpStatusCode.OK);
        raced.StatusCode.Should().Be(HttpStatusCode.OK, "a second tab refreshing at the same moment must not sign the user out");
        var winner = (await ApiFactory.ReadSessionAsync(first))["refreshToken"]!.GetValue<string>();
        (await client.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = winner }, Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Sign_out_ends_only_this_session()
    {
        var user = await api.SignUpAsync();
        var other = await ApiFactory.ReadSessionAsync(await LoginAsync(user.PhoneNumber, ApiFactory.TestPassword));

        (await api.GuestClient().PostAsJsonAsync("/api/v1/auth/logout", new { refreshToken = user.RefreshToken }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await RefreshAsync(user.RefreshToken)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await RefreshAsync(other["refreshToken"]!.GetValue<string>())).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Sign_out_everywhere_keeps_only_this_device()
    {
        var user = await api.SignUpAsync();
        var other = await ApiFactory.ReadSessionAsync(await LoginAsync(user.PhoneNumber, ApiFactory.TestPassword));
        var otherClient = api.ClientWithToken(other["accessToken"]!.GetValue<string>());

        var fresh = await ApiFactory.ReadSessionAsync(await user.Client.PostAsync("/api/v1/auth/logout-all", null, Ct));

        (await otherClient.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized, "the security stamp changed");
        (await RefreshAsync(other["refreshToken"]!.GetValue<string>())).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized, "the old access token is stale too");
        (await api.ClientWithToken(fresh["accessToken"]!.GetValue<string>()).GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await RefreshAsync(fresh["refreshToken"]!.GetValue<string>())).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Tokens_signed_with_another_key_are_rejected()
    {
        var user = await api.SignUpAsync();
        var forged = new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = "https://api.readin.app",
            Audience = "readin",
            Expires = DateTime.UtcNow.AddMinutes(5),
            Claims = new Dictionary<string, object> { ["sub"] = user.Id.ToString(), ["security_stamp"] = "x" },
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(Encoding.UTF8.GetBytes("someone-elses-signing-key-0123456789abcdef")), SecurityAlgorithms.HmacSha256),
        });

        (await api.ClientWithToken(forged).GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task The_web_gets_the_refresh_token_as_an_httponly_cookie()
    {
        var user = await api.SignUpAsync();
        var web = api.GuestClient();
        web.DefaultRequestHeaders.Add("X-ReadIn-Client", "web");

        var login = await LoginAsync(user.PhoneNumber, ApiFactory.TestPassword, web);
        var session = await ApiFactory.ReadSessionAsync(login);
        session["refreshToken"].Should().BeNull("the web never sees the refresh token");
        var cookie = login.Headers.GetValues("Set-Cookie").Single(c => c.StartsWith("readin_refresh=", StringComparison.Ordinal));
        cookie.Should().Contain("httponly").And.Contain("secure").And.Contain("samesite=strict").And.Contain("path=/api/v1/auth");

        var value = cookie.Split(';')[0];
        var withCookie = new HttpRequestMessage(HttpMethod.Post, "/api/v1/auth/refresh") { Content = JsonContent.Create(new { }) };
        withCookie.Headers.Add("Cookie", value);
        withCookie.Headers.Add("X-ReadIn-Client", "web");
        var refreshed = await api.GuestClient().SendAsync(withCookie, Ct);
        refreshed.StatusCode.Should().Be(HttpStatusCode.OK);
        refreshed.Headers.GetValues("Set-Cookie").Should().Contain(c => c.StartsWith("readin_refresh=", StringComparison.Ordinal));

        var noHeader = new HttpRequestMessage(HttpMethod.Post, "/api/v1/auth/refresh") { Content = JsonContent.Create(new { }) };
        noHeader.Headers.Add("Cookie", value);
        (await api.GuestClient().SendAsync(noHeader, Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized,
            "without the client header the cookie is ignored (cross-site requests can't add it)");
    }

    [Fact]
    public async Task Forgot_password_with_the_pin()
    {
        var user = await api.SignUpAsync();
        var guest = api.GuestClient();

        var wrongPin = await guest.PostAsJsonAsync("/api/v1/auth/recovery/verify-pin", new { phoneNumber = user.PhoneNumber, pin = "9999" }, Ct);
        wrongPin.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await CodeOf(wrongPin)).Should().Be("auth.recovery_invalid");

        var verified = await guest.PostAsJsonAsync("/api/v1/auth/recovery/verify-pin", new { phoneNumber = user.PhoneNumber, pin = "٧٣٩١" }, Ct);
        verified.StatusCode.Should().Be(HttpStatusCode.OK, "Arabic-Indic digits are accepted");
        var resetToken = (await verified.Content.ReadFromJsonAsync<JsonObject>(Ct))!["resetToken"]!.GetValue<string>();

        var weak = await guest.PostAsJsonAsync("/api/v1/auth/recovery/reset-password",
            new { resetToken, newPassword = $"x{user.PhoneNumber[2..]}" }, Ct);
        weak.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await ErrorsOf(weak, "newPassword")).Should().Contain("password.contains_phone");

        (await guest.PostAsJsonAsync("/api/v1/auth/recovery/reset-password", new { resetToken, newPassword = "Fresh-start-77" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        var reused = await guest.PostAsJsonAsync("/api/v1/auth/recovery/reset-password", new { resetToken, newPassword = "Another-one-88" }, Ct);
        (await CodeOf(reused)).Should().Be("auth.reset_token_invalid");

        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized, "every session is signed out");
        (await RefreshAsync(user.RefreshToken)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await LoginAsync(user.PhoneNumber, ApiFactory.TestPassword)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await LoginAsync(user.PhoneNumber, "Fresh-start-77")).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Five_wrong_pins_lock_recovery()
    {
        var user = await api.SignUpAsync();

        HttpResponseMessage last = null!;
        foreach (var pin in new[] { "1357", "2468", "3579", "4680", "5791" })
            last = await api.GuestClient().PostAsJsonAsync("/api/v1/auth/recovery/verify-pin", new { phoneNumber = user.PhoneNumber, pin }, Ct);

        last.StatusCode.Should().Be(HttpStatusCode.TooManyRequests);
        (await CodeOf(last)).Should().Be("auth.recovery_locked");
    }

    [Fact]
    public async Task Change_password_signs_out_other_sessions()
    {
        var user = await api.SignUpAsync();

        var wrong = await user.Client.PutAsJsonAsync("/api/v1/me/password", new { currentPassword = "Not-mine-12", newPassword = "Better-pass-31" }, Ct);
        (await CodeOf(wrong)).Should().Be("auth.wrong_password");

        var changed = await ApiFactory.ReadSessionAsync(
            await user.Client.PutAsJsonAsync("/api/v1/me/password", new { currentPassword = ApiFactory.TestPassword, newPassword = "Better-pass-31" }, Ct));

        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await api.ClientWithToken(changed["accessToken"]!.GetValue<string>()).GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await LoginAsync(user.PhoneNumber, "Better-pass-31")).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Change_phone_number_needs_the_password_and_a_free_number()
    {
        var user = await api.SignUpAsync();
        var someoneElse = await api.SignUpAsync();
        var newNumber = ApiFactory.NewPhoneNumber();

        var taken = await user.Client.PutAsJsonAsync("/api/v1/me/phone",
            new { newPhoneNumber = someoneElse.PhoneNumber, currentPassword = ApiFactory.TestPassword }, Ct);
        (await CodeOf(taken)).Should().Be("auth.phone_taken");

        var changed = await ApiFactory.ReadSessionAsync(await user.Client.PutAsJsonAsync("/api/v1/me/phone",
            new { newPhoneNumber = newNumber, currentPassword = ApiFactory.TestPassword }, Ct));
        changed["user"]!["phoneNumber"]!.GetValue<string>().Should().Be(newNumber);

        (await LoginAsync(user.PhoneNumber, ApiFactory.TestPassword)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await LoginAsync(newNumber, ApiFactory.TestPassword)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Change_pin_needs_the_password_and_rejects_weak_pins()
    {
        var user = await api.SignUpAsync();

        var weak = await user.Client.PutAsJsonAsync("/api/v1/me/recovery-pin", new { currentPassword = ApiFactory.TestPassword, newPin = "0000" }, Ct);
        (await ErrorsOf(weak, "newPin")).Should().Equal("pin.weak");

        (await user.Client.PutAsJsonAsync("/api/v1/me/recovery-pin", new { currentPassword = ApiFactory.TestPassword, newPin = "6193" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);

        (await user.Client.PostAsJsonAsync("/api/v1/me/recovery-pin", new { pin = "5283" }, Ct)).StatusCode
            .Should().Be(HttpStatusCode.Conflict, "the first-PIN endpoint is only for accounts without one");
        (await api.GuestClient().PostAsJsonAsync("/api/v1/auth/recovery/verify-pin", new { phoneNumber = user.PhoneNumber, pin = "6193" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Seed_accounts_without_a_pin_must_set_one()
    {
        var reader10 = await ApiFactory.ReadSessionAsync(await LoginAsync(ApiFactory.Reader10Phone, ApiFactory.DemoPassword));
        reader10["user"]!["mustSetRecoveryPin"]!.GetValue<bool>().Should().BeTrue();
        var client = api.ClientWithToken(reader10["accessToken"]!.GetValue<string>());

        var weak = await client.PostAsJsonAsync("/api/v1/me/recovery-pin", new { pin = "0119" }, Ct);
        (await ErrorsOf(weak, "pin")).Should().Equal(["pin.weak"], "the last digits of the phone number are weak");

        var me = await (await client.PostAsJsonAsync("/api/v1/me/recovery-pin", new { pin = "5283" }, Ct)).Content.ReadFromJsonAsync<JsonObject>(Ct);
        me!["mustSetRecoveryPin"]!.GetValue<bool>().Should().BeFalse();
        me["hasRecoveryPin"]!.GetValue<bool>().Should().BeTrue();

        var seeded = await (await api.SeedUserClientAsync(ApiFactory.Reader1Phone)).GetFromJsonAsync<JsonObject>("/api/v1/me", Ct);
        seeded!["mustSetRecoveryPin"]!.GetValue<bool>().Should().BeFalse("readers 1–9 are seeded with the demo PIN");
    }

    [Fact]
    public async Task Admin_reset_gives_a_temporary_password_and_forces_new_credentials()
    {
        var user = await api.SignUpAsync();
        var admin = (await api.SuperAdminAsync("Resetting SuperAdmin")).Client;

        var reset = await admin.PostAsync($"/api/v1/admin/users/{user.Id}/reset-password", null, Ct);
        reset.StatusCode.Should().Be(HttpStatusCode.OK);
        var temporary = (await reset.Content.ReadFromJsonAsync<JsonObject>(Ct))!["temporaryPassword"]!.GetValue<string>();

        (await user.Client.GetAsync("/api/v1/me", Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        var session = await ApiFactory.ReadSessionAsync(await LoginAsync(user.PhoneNumber, temporary));
        session["user"]!["mustChangePassword"]!.GetValue<bool>().Should().BeTrue();
        session["user"]!["mustSetRecoveryPin"]!.GetValue<bool>().Should().BeTrue();
        session["user"]!["hasRecoveryPin"]!.GetValue<bool>().Should().BeFalse();

        // A staff role holding users.reset_password (none exists today) resets Members but can't take over the
        // SuperAdmin, who can do more than it can.
        var superAdminId = (await (await api.SeedUserClientAsync(ApiFactory.SuperAdminPhone)).GetFromJsonAsync<JsonObject>("/api/v1/me", Ct))!["id"]!
            .GetValue<Guid>();
        // A staff role is built on the Member bundle (as Moderator was), plus what it does.
        var desk = await api.UserWithPermissionsAsync("Password Desk",
            [.. RoleMatrix.Roles.Single(r => r.Id == RoleIds.Member).Permissions, Permissions.Users.ResetPassword]);
        (await desk.Client.PostAsync($"/api/v1/admin/users/{superAdminId}/reset-password", null, Ct)).StatusCode
            .Should().Be(HttpStatusCode.Forbidden, "only a SuperAdmin resets a SuperAdmin");
        var member = await api.SignUpAsync();
        (await desk.Client.PostAsync($"/api/v1/admin/users/{member.Id}/reset-password", null, Ct)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await user.Client.PostAsync($"/api/v1/admin/users/{user.Id}/reset-password", null, Ct)).StatusCode
            .Should().BeOneOf(HttpStatusCode.Unauthorized, HttpStatusCode.Forbidden);
        var other = await api.SignUpAsync();
        await other.Client.PostAsync($"/api/v1/admin/users/{member.Id}/reset-password", null, Ct)
            .ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden"); // a Member can't
    }

    [Fact]
    public async Task Devices_can_be_unregistered_on_sign_out()
    {
        var user = await api.SignUpAsync();

        (await user.Client.PostAsJsonAsync("/api/v1/me/devices", new { token = "fcm:token-1", platform = "android" }, Ct))
            .StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.DeleteAsync("/api/v1/me/devices/fcm%3Atoken-1", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await user.Client.DeleteAsync("/api/v1/me/devices/fcm%3Atoken-1", Ct)).StatusCode.Should().Be(HttpStatusCode.NoContent, "idempotent");
    }
}
