using System.Net;
using System.Text;
using AwesomeAssertions;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.UnitTests.Identity;

/// <summary>Trading the web button's Google code for its ID token (ADR 0012): the form Google expects, and its answers.</summary>
public sealed class GoogleCodeExchangerTests
{
    private const string WebClient = "web-client.apps.googleusercontent.com";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private readonly List<(string Path, Dictionary<string, string> Form)> _requests = [];
    private readonly Queue<Func<HttpResponseMessage>> _responses = new();
    private readonly MemoryCache _traded = new(new MemoryCacheOptions());

    private GoogleCodeExchanger Exchanger(string? secret = "web-secret") => new(
        new HttpClient(new Handler(this)) { BaseAddress = new Uri("https://oauth2.googleapis.com/") },
        Options.Create(new ExternalAuthOptions
        {
            Google = new GoogleProviderOptions { ClientIds = [WebClient, "ios-client.apps.googleusercontent.com"], ClientSecret = secret },
        }),
        _traded,
        NullLogger<GoogleCodeExchanger>.Instance);

    private static HttpResponseMessage Json(HttpStatusCode status, string body) =>
        new(status) { Content = new StringContent(body, Encoding.UTF8, "application/json") };

    [Fact]
    public async Task A_code_is_traded_for_the_id_token_with_the_web_clients_secret()
    {
        _responses.Enqueue(() => Json(HttpStatusCode.OK, """{"access_token":"a","id_token":"header.payload.signature","token_type":"Bearer"}"""));

        (await Exchanger().ExchangeAsync("4/code-1", Ct)).Value.Should().Be("header.payload.signature");

        var (path, form) = _requests.Should().ContainSingle().Subject;
        path.Should().Be("/token");
        form.Should().Contain("code", "4/code-1")
            .And.Contain("client_id", WebClient)
            .And.Contain("client_secret", "web-secret")
            .And.Contain("redirect_uri", "postmessage")
            .And.Contain("grant_type", "authorization_code");
    }

    [Fact]
    public async Task The_same_code_sent_again_reuses_its_token_instead_of_asking_google_twice()
    {
        _responses.Enqueue(() => Json(HttpStatusCode.OK, """{"id_token":"token-1"}"""));
        _responses.Enqueue(() => Json(HttpStatusCode.OK, """{"id_token":"token-2"}"""));

        // "Not linked" → "create a new account" resends the credential, and Google takes each code only once.
        (await Exchanger().ExchangeAsync("code-1", Ct)).Value.Should().Be("token-1");
        (await Exchanger().ExchangeAsync("code-1", Ct)).Value.Should().Be("token-1");
        (await Exchanger().ExchangeAsync("code-2", Ct)).Value.Should().Be("token-2");
        _requests.Select(r => r.Form["code"]).Should().Equal("code-1", "code-2");
    }

    [Fact]
    public async Task A_rejected_code_or_a_wrong_secret_fails_once_without_a_retry()
    {
        var google = Exchanger();
        _responses.Enqueue(() => Json(HttpStatusCode.BadRequest, """{"error":"invalid_grant"}"""));
        _responses.Enqueue(() => Json(HttpStatusCode.Unauthorized, """{"error":"invalid_client"}"""));
        _responses.Enqueue(() => Json(HttpStatusCode.OK, """{"access_token":"a"}"""));

        (await google.ExchangeAsync("used", Ct)).Error.Should().Be(CredentialErrors.ExternalInvalid);
        (await google.ExchangeAsync("code", Ct)).Error.Should().Be(CredentialErrors.ExternalInvalid);
        (await google.ExchangeAsync("code", Ct)).Error.Should().Be(CredentialErrors.ExternalInvalid, "no ID token came back");
        _requests.Should().HaveCount(3);
    }

    [Fact]
    public async Task Google_being_unreachable_is_reported_as_unavailable()
    {
        var google = Exchanger();
        _responses.Enqueue(() => new HttpResponseMessage(HttpStatusCode.ServiceUnavailable));
        _responses.Enqueue(() => new HttpResponseMessage(HttpStatusCode.TooManyRequests));
        _responses.Enqueue(() => throw new HttpRequestException("reset"));

        for (var i = 0; i < 3; i++)
            (await google.ExchangeAsync("code", Ct)).Error.Should().Be(CredentialErrors.ExternalUnavailable);
        _requests.Should().HaveCount(3, "a code works once, so nothing is retried");
    }

    [Fact]
    public async Task Without_a_secret_it_is_off_and_sends_nothing()
    {
        var google = Exchanger(secret: " ");

        google.IsConfigured.Should().BeFalse();
        (await google.ExchangeAsync("code", Ct)).Error.Should().Be(CredentialErrors.ProviderDisabled);
        _requests.Should().BeEmpty();
        Exchanger().IsConfigured.Should().BeTrue();
    }

    private sealed class Handler(GoogleCodeExchangerTests test) : HttpMessageHandler
    {
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var form = (await request.Content!.ReadAsStringAsync(cancellationToken)).Split('&')
                .Select(pair => pair.Split('='))
                .ToDictionary(p => Uri.UnescapeDataString(p[0]), p => Uri.UnescapeDataString(p[1].Replace('+', ' ')));
            test._requests.Add((request.RequestUri!.AbsolutePath, form));
            return test._responses.Dequeue()();
        }
    }
}
