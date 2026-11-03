using ReadIn.Domain.Reading;

namespace ReadIn.Domain.UnitTests.Reading;

public sealed class ReadingProgressTests
{
    private static readonly DateTime Now = new(2026, 11, 2, 8, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Article_is_read_at_70_percent_and_30_seconds()
    {
        var progress = new ReadingProgress(Guid.NewGuid(), Guid.NewGuid(), "ar-EG");

        progress.Record("ar-EG", 80, "b12", activeSecondsDelta: 20, Now).Should().BeFalse("only 20 seconds were spent");
        progress.Record("ar-EG", 80, "b12", activeSecondsDelta: 15, Now).Should().BeTrue();
        progress.Record("ar-EG", 100, "b30", activeSecondsDelta: 60, Now).Should().BeFalse("completion is reported once");
        progress.CompletedAt.Should().Be(Now);
    }

    [Fact]
    public void Scrolling_back_up_never_lowers_the_percent()
    {
        var progress = new ReadingProgress(Guid.NewGuid(), Guid.NewGuid(), "en");

        progress.Record("en", 60, "b5", 10, Now);
        progress.Record("en", 20, "b2", 10, Now);

        progress.Percent.Should().Be(60);
        progress.LastPosition.Should().Be("b2");
    }

    [Fact]
    public void Implausible_time_deltas_are_capped()
    {
        var progress = new ReadingProgress(Guid.NewGuid(), Guid.NewGuid(), "en");

        progress.Record("en", 10, null, activeSecondsDelta: 100_000, Now);

        progress.ActiveSeconds.Should().Be(600);
    }
}
