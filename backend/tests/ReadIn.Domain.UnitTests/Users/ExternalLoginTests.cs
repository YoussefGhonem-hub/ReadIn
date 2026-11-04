using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Domain.UnitTests.Users;

public sealed class ExternalLoginTests
{
    private static readonly Guid MemberRole = Guid.NewGuid();
    private static readonly DateTime Now = new(2026, 11, 3, 10, 0, 0, DateTimeKind.Utc);

    private static User GoogleUser(string? name = null) =>
        User.RegisterExternal(ExternalProviders.Google, "google-sub", "mona@example.com", name, "reader_abc123", MemberRole, Now);

    [Fact]
    public void A_google_account_has_no_phone_password_or_pin_to_set()
    {
        var user = GoogleUser();

        user.PhoneNumber.Should().BeNull();
        user.Email.Should().Be("mona@example.com");
        user.HasPassword.Should().BeFalse();
        user.CanSignInWithPassword.Should().BeFalse();
        user.CanSignIn.Should().BeTrue();
        user.MustSetRecoveryPin.Should().BeFalse("the provider handles recovery");
        user.IsProfileComplete.Should().BeFalse();
        user.DisplayName.Should().Be("reader_abc123");
        user.ExternalLogins.Should().ContainSingle(l => l.Provider == ExternalProviders.Google && l.Subject == "google-sub");
        user.HasRole(MemberRole).Should().BeTrue();
    }

    [Fact]
    public void The_name_from_apple_is_used_and_trimmed_to_fit()
    {
        GoogleUser("  Mona Ali ").DisplayName.Should().Be("Mona Ali");
        GoogleUser(new string('a', 80)).DisplayName.Should().HaveLength(User.MaxDisplayNameLength);
    }

    [Fact]
    public void One_identity_per_provider()
    {
        var user = User.Register("+12015550101", "password-hash", "reader_abc123", MemberRole);

        user.LinkExternalLogin(ExternalProviders.Google, "first", null, Now).IsSuccess.Should().BeTrue();
        user.LinkExternalLogin(ExternalProviders.Google, "first", null, Now.AddDays(1)).IsSuccess.Should().BeTrue("linking again is a no-op");
        user.LinkExternalLogin(ExternalProviders.Google, "second", null, Now).Error.Should().Be(CredentialErrors.ExternalConflict);
        user.LinkExternalLogin(ExternalProviders.Apple, "apple-sub", null, Now).IsSuccess.Should().BeTrue();

        user.ExternalLogins.Should().HaveCount(2);
        user.FindExternalLogin(ExternalProviders.Google)!.LastUsedAt.Should().Be(Now.AddDays(1));
        user.DomainEvents.OfType<UserSecurityChangedDomainEvent>()
            .Count(e => e.Change == SecurityChange.ExternalLoginLinked).Should().Be(2);
    }

    [Fact]
    public void The_last_way_to_sign_in_cannot_be_unlinked()
    {
        var user = GoogleUser();

        user.UnlinkExternalLogin(ExternalProviders.Apple).Error.Should().Be(CredentialErrors.ExternalLoginNotFound);
        user.UnlinkExternalLogin(ExternalProviders.Google).Error.Should().Be(CredentialErrors.LastSignInMethod);

        user.LinkExternalLogin(ExternalProviders.Apple, "apple-sub", null, Now);
        user.UnlinkExternalLogin(ExternalProviders.Google).IsSuccess.Should().BeTrue();
        user.ExternalLogins.Should().ContainSingle(l => l.Provider == ExternalProviders.Apple);
    }

    [Fact]
    public void Adding_phone_sign_in_requires_a_pin_and_signs_out_other_sessions()
    {
        var user = GoogleUser();
        var stamp = user.SecurityStamp;

        user.AddPhoneSignIn("+12015550102", "password-hash").IsSuccess.Should().BeTrue();

        user.PhoneNumber.Should().Be("+12015550102");
        user.CanSignInWithPassword.Should().BeTrue();
        user.MustSetRecoveryPin.Should().BeTrue("the handler sets it in the same request");
        user.SecurityStamp.Should().NotBe(stamp);
        user.AddPhoneSignIn("+12015550103", "other-hash").Error.Should().Be(CredentialErrors.PhoneSignInExists);

        user.UnlinkExternalLogin(ExternalProviders.Google).IsSuccess.Should().BeTrue("the password is still there");
    }

    [Fact]
    public void Keeps_the_provider_token_on_the_linked_identity_only()
    {
        var user = GoogleUser();

        user.StoreProviderToken(ExternalProviders.Apple, "app.readin.readin", "v1.secret");
        user.ExternalLogins.Should().OnlyContain(l => l.ProviderRefreshToken == null, "Apple isn't linked");

        user.StoreProviderToken(ExternalProviders.Google, "client", "v1.secret");
        var login = user.FindExternalLogin(ExternalProviders.Google)!;
        login.ProviderRefreshToken.Should().Be("v1.secret");
        login.ProviderClientId.Should().Be("client");
    }
}
