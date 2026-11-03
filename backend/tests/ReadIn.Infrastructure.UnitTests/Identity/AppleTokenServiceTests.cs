using System.Net;
using System.Security.Cryptography;
using System.Text;
using AwesomeAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using ReadIn.Domain.Users;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.UnitTests.Identity;

/// <summary>The Sign in with Apple REST API client (SPEC F01): client secret, form posts, retries.</summary>
public sealed class AppleTokenServiceTests
{
    private const string Client = "app.readin.readin";
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;
    private static readonly ECDsa Key = ECDsa.Create(ECCurve.NamedCurves.nistP256);

    private readonly List<(string Path, Dictionary<string, string> Form)> _requests = [];
    private readonly Queue<Func<HttpResponseMessage>> _responses = new();

    private AppleTokenService Service(string? privateKey = null) => new(
        new HttpClient(new Handler(this)) { BaseAddress = new Uri("https://appleid.apple.com/") },
        Options.Create(new ExternalAuthOptions
        {
            Apple = new AppleProviderOptions
            {
                ClientIds = [Client],
                TeamId = "TEAM123456",
                KeyId = "KEY1234567",
                PrivateKeyBase64 = privateKey ?? Convert.ToBase64String(Encoding.UTF8.GetBytes(Key.ExportPkcs8PrivateKeyPem())),
            },
        }),
        TimeProvider.System,
        NullLogger<AppleTokenService>.Instance)
    {
        Backoff = [TimeSpan.Zero, TimeSpan.Zero, TimeSpan.Zero],
    };

    private static HttpResponseMessage Json(HttpStatusCode status, string body) =>
        new(status) { Content = new StringContent(body, Encoding.UTF8, "application/json") };

    [Fact]
    public async Task The_client_secret_is_an_ES256_JWT_Apple_accepts()
    {
        var secret = Service().ClientSecret(Client);

        var result = await new JsonWebTokenHandler().ValidateTokenAsync(secret, new TokenValidationParameters
        {
            ValidIssuer = "TEAM123456",
            ValidAudience = "https://appleid.apple.com",
            IssuerSigningKey = new ECDsaSecurityKey(ECDsa.Create(Key.ExportParameters(false))),
            ValidAlgorithms = [SecurityAlgorithms.EcdsaSha256],
        });

        result.IsValid.Should().BeTrue(result.Exception?.Message);
        var token = (JsonWebToken)result.SecurityToken;
        token.Kid.Should().Be("KEY1234567");
        token.Subject.Should().Be(Client);
        (token.ValidTo - token.IssuedAt).Should().BeLessThanOrEqualTo(TimeSpan.FromSeconds(15777000), "Apple's six-month limit");
    }

    [Fact]
    public async Task Exchange_returns_the_refresh_token_and_revoke_posts_it_back()
    {
        var apple = Service();
        _responses.Enqueue(() => Json(HttpStatusCode.OK, """{"access_token":"a","refresh_token":"r-1","id_token":"i","token_type":"bearer"}"""));
        _responses.Enqueue(() => new HttpResponseMessage(HttpStatusCode.OK));

        (await apple.ExchangeCodeAsync(Client, "code-1", Ct)).Value.Should().Be("r-1");
        (await apple.RevokeRefreshTokenAsync(Client, "r-1", Ct)).IsSuccess.Should().BeTrue();

        _requests[0].Path.Should().Be("/auth/token");
        _requests[0].Form.Should().Contain("grant_type", "authorization_code").And.Contain("code", "code-1").And.Contain("client_id", Client);
        _requests[0].Form.Should().ContainKey("client_secret");
        _requests[1].Path.Should().Be("/auth/revoke");
        _requests[1].Form.Should().Contain("token", "r-1").And.Contain("token_type_hint", "refresh_token").And.Contain("client_id", Client);
    }

    [Fact]
    public async Task Transient_failures_are_retried()
    {
        var apple = Service();
        _responses.Enqueue(() => new HttpResponseMessage(HttpStatusCode.ServiceUnavailable));
        _responses.Enqueue(() => throw new HttpRequestException("reset"));
        _responses.Enqueue(() => new HttpResponseMessage(HttpStatusCode.OK));

        (await apple.RevokeRefreshTokenAsync(Client, "r-1", Ct)).IsSuccess.Should().BeTrue();
        _requests.Should().HaveCount(3);
    }

    [Fact]
    public async Task Apple_staying_down_is_reported_not_skipped()
    {
        var apple = Service();
        for (var i = 0; i < 4; i++) _responses.Enqueue(() => new HttpResponseMessage(HttpStatusCode.BadGateway));

        (await apple.RevokeRefreshTokenAsync(Client, "r-1", Ct)).Error.Should().Be(UserErrors.DeletionUnavailable);
        _requests.Should().HaveCount(4, "one try and three retries");
    }

    [Fact]
    public async Task A_rejected_code_is_not_retried()
    {
        var apple = Service();
        _responses.Enqueue(() => Json(HttpStatusCode.BadRequest, """{"error":"invalid_grant"}"""));

        (await apple.ExchangeCodeAsync(Client, "used-code", Ct)).Error.Should().Be(CredentialErrors.ExternalInvalid);
        _requests.Should().ContainSingle();
    }

    [Fact]
    public void The_key_can_be_PEM_or_base64_and_a_broken_key_turns_it_off()
    {
        Service(Key.ExportPkcs8PrivateKeyPem()).IsConfigured.Should().BeTrue();
        Service(Convert.ToBase64String(Key.ExportPkcs8PrivateKey())).IsConfigured.Should().BeTrue();
        Service("not a key").IsConfigured.Should().BeFalse();
    }

    private sealed class Handler(AppleTokenServiceTests test) : HttpMessageHandler
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
