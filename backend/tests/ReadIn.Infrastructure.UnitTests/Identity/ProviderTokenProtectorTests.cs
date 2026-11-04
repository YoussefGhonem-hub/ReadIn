using AwesomeAssertions;
using Microsoft.Extensions.Options;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.UnitTests.Identity;

public sealed class ProviderTokenProtectorTests
{
    private static AesGcmProviderTokenProtector Protector(string pepper = "test-only-recovery-pin-pepper-0123456789abcdef") =>
        new(Options.Create(new SecurityOptions { RecoveryPinPepper = pepper }));

    [Fact]
    public void Round_trips_without_storing_the_token_in_the_clear()
    {
        var protector = Protector();

        var stored = protector.Protect("apple-refresh-token");

        stored.Should().StartWith("v1.").And.NotContain("apple-refresh-token");
        protector.Protect("apple-refresh-token").Should().NotBe(stored, "every value gets its own nonce");
        protector.Unprotect(stored).Should().Be("apple-refresh-token");
    }

    [Fact]
    public void Tampered_or_foreign_values_are_rejected()
    {
        var stored = Protector().Protect("apple-refresh-token");
        var tampered = stored[..^2] + (stored[^2] == 'A' ? "B" : "A") + stored[^1];

        Protector().Unprotect(tampered).Should().BeNull();
        Protector("another-pepper-that-is-long-enough-0123456789").Unprotect(stored).Should().BeNull();
        Protector().Unprotect("plain-token").Should().BeNull();
    }
}
