using ReadIn.Domain.Reading;

namespace ReadIn.Domain.UnitTests.Reading;

public sealed class DailyPickTests
{
    private static readonly DateTime Now = new(2026, 11, 3, 6, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void The_daily_push_is_claimed_once()
    {
        var pick = new DailyPick(Guid.NewGuid(), new DateOnly(2026, 11, 3), Guid.NewGuid());

        pick.MarkNotified(Now).Should().BeTrue();
        pick.MarkNotified(Now.AddMinutes(5)).Should().BeFalse("a second run must not send it again");
        pick.NotifiedAt.Should().Be(Now);
    }

    [Fact]
    public void A_released_claim_can_be_taken_again()
    {
        var pick = new DailyPick(Guid.NewGuid(), new DateOnly(2026, 11, 3), Guid.NewGuid());
        pick.MarkNotified(Now);

        pick.ReleaseNotification();

        pick.NotifiedAt.Should().BeNull();
        pick.MarkNotified(Now.AddMinutes(5)).Should().BeTrue();
    }
}
