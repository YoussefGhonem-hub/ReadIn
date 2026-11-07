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

    private static RefreshToken Issue(Guid family, string hash, Guid? userId = null)
    {
        var token = RefreshToken.Issue(userId ?? Guid.NewGuid(), hash, family, Now, TimeSpan.FromDays(30), null, null);
        typeof(RefreshToken).GetProperty(nameof(RefreshToken.Id))!.SetValue(token, Guid.NewGuid()); // EF assigns it on Add
        return token;
    }

    [Fact]
    public void A_rotation_with_a_retry_key_can_be_retried_with_that_key_while_the_new_token_is_unused()
    {
        var family = Guid.NewGuid();
        var first = Issue(family, "a");
        var second = Issue(family, "b", first.UserId);

        first.RotateTo(second, Now, retryKeyHash: "K");

        first.RetryKeyHash.Should().Be("K");
        first.CanBeRetriedWith("K", second, Now.AddDays(1)).Should().BeTrue();
        first.CanBeRetriedWith("other", second, Now.AddDays(1)).Should().BeFalse("another key is another client");
        first.CanBeRetriedWith("K", Issue(family, "c", first.UserId), Now).Should().BeFalse("only the token that replaced it");
        second.CanBeRetriedWith("K", first, Now).Should().BeFalse("a token that was never rotated isn't retried");
    }

    [Fact]
    public void A_rotation_without_a_retry_key_cannot_be_retried()
    {
        var family = Guid.NewGuid();
        var first = Issue(family, "a");
        var second = Issue(family, "b", first.UserId);

        first.RotateTo(second, Now);

        first.RetryKeyHash.Should().BeNull();
        first.CanBeRetriedWith("K", second, Now).Should().BeFalse();
    }

    [Fact]
    public void A_retry_is_refused_once_the_new_token_was_used_revoked_or_expired()
    {
        var family = Guid.NewGuid();
        var first = Issue(family, "a");
        var used = Issue(family, "b", first.UserId);
        first.RotateTo(used, Now, "K");
        used.RotateTo(Issue(family, "c", first.UserId), Now.AddMinutes(5));

        first.CanBeRetriedWith("K", used, Now.AddMinutes(10)).Should().BeFalse("the new token reached the client and was used");

        var revokedFirst = Issue(family, "d");
        var revoked = Issue(family, "e", revokedFirst.UserId);
        revokedFirst.RotateTo(revoked, Now, "K");
        revoked.Revoke(Now.AddMinutes(1));
        revokedFirst.CanBeRetriedWith("K", revoked, Now.AddMinutes(2)).Should().BeFalse("the session was signed out");

        var expiredFirst = Issue(family, "f");
        var expired = Issue(family, "g", expiredFirst.UserId);
        expiredFirst.RotateTo(expired, Now, "K");
        expiredFirst.CanBeRetriedWith("K", expired, Now.AddDays(30)).Should().BeFalse();
    }

    [Fact]
    public void A_retry_replaces_the_unused_token_and_keeps_the_key_for_another_retry()
    {
        var family = Guid.NewGuid();
        var first = Issue(family, "a");
        var lost = Issue(family, "b", first.UserId);
        var next = Issue(family, "c", first.UserId);
        first.RotateTo(lost, Now, "K");

        first.RetryTo(lost, next, Now.AddMinutes(1));

        first.ReplacedById.Should().Be(next.Id);
        first.RetryKeyHash.Should().Be("K");
        first.RevokedAt.Should().Be(Now, "it was revoked when it was first rotated");
        lost.WasRotated.Should().BeTrue("presenting the lost token later is reuse");
        lost.ReplacedById.Should().Be(next.Id);
        lost.RetryKeyHash.Should().BeNull("the client never held it, so it can't retry with it");
        lost.IsActiveAt(Now.AddMinutes(1)).Should().BeFalse();
        next.IsActiveAt(Now.AddMinutes(1)).Should().BeTrue();
        first.CanBeRetriedWith("K", next, Now.AddMinutes(2)).Should().BeTrue("a second lost answer can be retried too");
        first.CanBeRetriedWith("K", lost, Now.AddMinutes(2)).Should().BeFalse();
    }

    [Fact]
    public void Only_the_unused_token_that_replaced_it_can_be_replaced_on_a_retry()
    {
        var family = Guid.NewGuid();
        var first = Issue(family, "a");
        var lost = Issue(family, "b", first.UserId);
        first.RotateTo(lost, Now, "K");

        var stranger = () => first.RetryTo(Issue(family, "c", first.UserId), Issue(family, "d", first.UserId), Now);
        stranger.Should().Throw<InvalidOperationException>();

        lost.RotateTo(Issue(family, "e", first.UserId), Now);
        var used = () => first.RetryTo(lost, Issue(family, "f", first.UserId), Now);
        used.Should().Throw<InvalidOperationException>();
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
