using AwesomeAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using NSubstitute;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Auth;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.UnitTests.Security;

/// <summary>Apple token capture and revocation on account deletion (SPEC F01, App Store guideline 5.1.1(v)).</summary>
public sealed class AppleTokensTests
{
    private const string Client = "app.readin.readin";
    private static readonly DateTime Now = new(2026, 11, 3, 12, 0, 0, DateTimeKind.Utc);
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private readonly IAppleTokenService _apple = Substitute.For<IAppleTokenService>();
    private readonly AppleTokens _tokens;

    public AppleTokensTests()
    {
        _apple.IsConfigured.Returns(true);
        _apple.ExchangeCodeAsync(Client, Arg.Any<string>(), Arg.Any<CancellationToken>())
            .Returns(call => Result.Success($"refresh-{call.ArgAt<string>(1)}"));
        _apple.RevokeRefreshTokenAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns(Result.Success());
        _tokens = new AppleTokens(_apple, new PrefixProtector(), NullLogger<AppleTokens>.Instance);
    }

    private static User AppleUser() =>
        User.RegisterExternal(ExternalProviders.Apple, "apple-sub", null, "Reader", "reader_apple", Guid.NewGuid(), Now);

    private static ExternalIdentity AppleIdentity() => new(ExternalProviders.Apple, "apple-sub", null, false, null, Client);

    [Fact]
    public async Task Accounts_without_Apple_have_nothing_to_revoke()
    {
        var user = User.Register("+12025550199", "hash", "reader_phone", Guid.NewGuid());

        (await _tokens.RevokeAsync(user, confirmedWith: null, freshCode: null, Ct)).IsSuccess.Should().BeTrue();

        await _apple.DidNotReceiveWithAnyArgs().RevokeRefreshTokenAsync(default!, default!, Ct);
    }

    [Fact]
    public async Task Sign_in_keeps_the_token_encrypted_and_deletion_revokes_it()
    {
        var user = AppleUser();

        await _tokens.CaptureAsync(user, AppleIdentity(), "sign-in-code", Ct);
        user.FindExternalLogin(ExternalProviders.Apple)!.ProviderRefreshToken.Should().Be("enc:refresh-sign-in-code");

        (await _tokens.RevokeAsync(user, confirmedWith: null, freshCode: null, Ct)).IsSuccess.Should().BeTrue("a password confirmation still revokes the stored token");
        await _apple.Received(1).RevokeRefreshTokenAsync(Client, "refresh-sign-in-code", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task A_fresh_Apple_confirmation_revokes_its_own_token_and_the_stored_one()
    {
        var user = AppleUser();
        await _tokens.CaptureAsync(user, AppleIdentity(), "sign-in-code", Ct);

        (await _tokens.RevokeAsync(user, AppleIdentity(), "fresh-code", Ct)).IsSuccess.Should().BeTrue();

        await _apple.Received(1).RevokeRefreshTokenAsync(Client, "refresh-fresh-code", Arg.Any<CancellationToken>());
        await _apple.Received(1).RevokeRefreshTokenAsync(Client, "refresh-sign-in-code", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Without_any_token_the_client_is_asked_to_confirm_with_Apple()
    {
        var result = await _tokens.RevokeAsync(AppleUser(), confirmedWith: null, freshCode: null, Ct);

        result.Error.Should().Be(CredentialErrors.AppleConfirmationRequired);
    }

    [Fact]
    public async Task Revocation_is_never_skipped_when_Apple_fails()
    {
        var user = AppleUser();
        await _tokens.CaptureAsync(user, AppleIdentity(), "sign-in-code", Ct);
        _apple.RevokeRefreshTokenAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<CancellationToken>()).Returns(UserErrors.DeletionUnavailable);

        (await _tokens.RevokeAsync(user, null, null, Ct)).Error.Should().Be(UserErrors.DeletionUnavailable);
    }

    [Fact]
    public async Task Without_the_Apple_key_Apple_accounts_cant_be_deleted()
    {
        _apple.IsConfigured.Returns(false);

        (await _tokens.RevokeAsync(AppleUser(), AppleIdentity(), "fresh-code", Ct)).Error.Should().Be(UserErrors.DeletionUnavailable);
        await _apple.DidNotReceiveWithAnyArgs().ExchangeCodeAsync(default!, default!, Ct);
    }

    [Fact]
    public async Task A_failed_capture_stores_nothing_and_never_blocks_sign_in()
    {
        var user = AppleUser();
        _apple.ExchangeCodeAsync(Client, "bad-code", Arg.Any<CancellationToken>()).Returns(CredentialErrors.ExternalInvalid);

        await _tokens.CaptureAsync(user, AppleIdentity(), "bad-code", Ct);
        await _tokens.CaptureAsync(user, AppleIdentity() with { Provider = ExternalProviders.Google }, "code", Ct);

        user.FindExternalLogin(ExternalProviders.Apple)!.ProviderRefreshToken.Should().BeNull();
    }

    private sealed class PrefixProtector : IProviderTokenProtector
    {
        public string Protect(string token) => "enc:" + token;
        public string? Unprotect(string protectedToken) => protectedToken.StartsWith("enc:", StringComparison.Ordinal) ? protectedToken[4..] : null;
    }
}
