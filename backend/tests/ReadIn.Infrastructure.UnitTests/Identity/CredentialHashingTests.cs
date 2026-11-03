using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure.Identity;

namespace ReadIn.Infrastructure.UnitTests.Identity;

public sealed class CredentialHashingTests
{
    private static readonly IdentityPasswordHasher Passwords = new();

    private static PepperedPinHasher Pins(string pepper = "a-test-pepper-that-is-long-enough-0123") =>
        new(Options.Create(new SecurityOptions { RecoveryPinPepper = pepper }), Passwords);

    [Fact]
    public void Passwords_are_salted_pbkdf2_hashes()
    {
        var first = Passwords.Hash("Nile-river-2026");
        var second = Passwords.Hash("Nile-river-2026");

        first.Should().NotBe(second, "every hash has its own salt");
        first.Should().NotContain("Nile");
        Passwords.Verify(first, "Nile-river-2026").Should().Be(PasswordCheck.Success);
        Passwords.Verify(first, "nile-river-2026").Should().Be(PasswordCheck.Failed);
    }

    [Fact]
    public void Pins_are_bound_to_the_user()
    {
        var pins = Pins();
        var user = Guid.NewGuid();
        var hash = pins.Hash(user, "4826");

        pins.Verify(user, hash, "4826").Should().BeTrue();
        pins.Verify(user, hash, "4827").Should().BeFalse();
        pins.Verify(Guid.NewGuid(), hash, "4826").Should().BeFalse("a hash copied to another account must not work");
    }

    [Fact]
    public void Pin_hashes_need_the_pepper()
    {
        var user = Guid.NewGuid();
        var hash = Pins().Hash(user, "4826");

        Pins("another-pepper-that-is-long-enough-012345").Verify(user, hash, "4826").Should().BeFalse(
            "without the pepper, a leaked database can't be used to try the 10,000 PINs");
    }

    [Fact]
    public void Phone_hashes_are_stable_keyed_and_reveal_nothing()
    {
        var hash = Pins().HashPhoneNumber("+201001234567");

        hash.Should().Be(Pins().HashPhoneNumber("+201001234567"));
        hash.Should().HaveLength(64).And.NotContain("1001234567");
        Pins("another-pepper-that-is-long-enough-012345").HashPhoneNumber("+201001234567").Should().NotBe(hash);
    }

    [Fact]
    public void Throttle_counts_per_key_and_window()
    {
        var clock = new ManualClock { Now = new DateTimeOffset(2026, 11, 3, 10, 0, 0, TimeSpan.Zero) };
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var throttle = new MemoryAttemptThrottle(cache, clock);

        for (var i = 0; i < 5; i++) throttle.TryAcquire("sign-in:+201001234567", 5, TimeSpan.FromMinutes(1)).Should().BeTrue();
        throttle.TryAcquire("sign-in:+201001234567", 5, TimeSpan.FromMinutes(1)).Should().BeFalse();
        throttle.TryAcquire("sign-in:+201001234568", 5, TimeSpan.FromMinutes(1)).Should().BeTrue("numbers are counted separately");

        clock.Now += TimeSpan.FromMinutes(1);
        throttle.TryAcquire("sign-in:+201001234567", 5, TimeSpan.FromMinutes(1)).Should().BeTrue("a new window starts");
    }
}

internal sealed class ManualClock : TimeProvider
{
    public DateTimeOffset Now { get; set; }

    public override DateTimeOffset GetUtcNow() => Now;
}
