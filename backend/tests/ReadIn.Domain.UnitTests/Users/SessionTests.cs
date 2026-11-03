using ReadIn.Domain.Identity;

namespace ReadIn.Domain.UnitTests.Users;

public sealed class SessionTests
{
    private static readonly DateTime Now = new(2026, 11, 3, 10, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Refresh_tokens_expire_and_can_be_revoked()
    {
        var token = RefreshToken.Issue(Guid.NewGuid(), "hash", Guid.NewGuid(), Now, TimeSpan.FromDays(30), "1.2.3.4", "Pixel 8");

        token.IsActiveAt(Now.AddDays(29)).Should().BeTrue();
        token.IsActiveAt(Now.AddDays(30)).Should().BeFalse();

        token.Revoke(Now.AddMinutes(1));
        token.Revoke(Now.AddMinutes(5));

        token.IsActiveAt(Now.AddMinutes(2)).Should().BeFalse();
        token.RevokedAt.Should().Be(Now.AddMinutes(1), "the first revocation time is kept");
        token.WasRotated.Should().BeFalse();
    }

    [Fact]
    public void Rotation_links_the_old_token_to_the_new_one()
    {
        var family = Guid.NewGuid();
        var first = RefreshToken.Issue(Guid.NewGuid(), "a", family, Now, TimeSpan.FromDays(30), null, null);
        var second = RefreshToken.Issue(first.UserId, "b", family, Now, TimeSpan.FromDays(30), null, null);

        first.RotateTo(second, Now);

        first.WasRotated.Should().BeTrue();
        first.IsActiveAt(Now).Should().BeFalse();
        second.FamilyId.Should().Be(family);
    }

    [Fact]
    public void Long_device_names_are_trimmed()
    {
        var token = RefreshToken.Issue(Guid.NewGuid(), "hash", Guid.NewGuid(), Now, TimeSpan.FromDays(1), null, new string('x', 500));

        token.DeviceName.Should().HaveLength(200);
    }

    [Fact]
    public void Reset_tokens_are_single_use_short_lived_and_bound_to_the_ip()
    {
        var token = PasswordResetToken.Issue(Guid.NewGuid(), "hash", Now, "1.2.3.4");

        token.IsUsableAt(Now.AddMinutes(9), "1.2.3.4").Should().BeTrue();
        token.IsUsableAt(Now.AddMinutes(10), "1.2.3.4").Should().BeFalse();
        token.IsUsableAt(Now, "5.6.7.8").Should().BeFalse();

        token.MarkUsed(Now);
        token.IsUsableAt(Now.AddMinutes(1), "1.2.3.4").Should().BeFalse();
    }
}
