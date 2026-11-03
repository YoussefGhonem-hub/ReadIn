using ReadIn.Domain.Reading;

namespace ReadIn.Domain.UnitTests.Reading;

public sealed class ReadingProgressTests
{
    private static readonly DateTime Now = new(2026, 11, 2, 8, 0, 0, DateTimeKind.Utc);

    private static ReadingProgress Opened(string language = "ar-EG") => new(Guid.NewGuid(), Guid.NewGuid(), language, Now);

    [Fact]
    public void Article_is_read_at_70_percent_and_30_seconds()
    {
        var progress = Opened();

        progress.Record("ar-EG", 80, "b12", activeSecondsDelta: 20, Now.AddSeconds(20)).CompletedNow.Should().BeFalse("only 20 seconds were spent");
        progress.Record("ar-EG", 80, "b12", activeSecondsDelta: 15, Now.AddSeconds(35)).CompletedNow.Should().BeTrue();
        progress.Record("ar-EG", 100, "b30", activeSecondsDelta: 60, Now.AddSeconds(95)).CompletedNow.Should().BeFalse("completion is reported once");
        progress.CompletedAt.Should().Be(Now.AddSeconds(35));
    }

    [Fact]
    public void Thirty_seconds_without_70_percent_is_not_read()
    {
        var progress = Opened();

        progress.Record("ar-EG", 69, null, activeSecondsDelta: 120, Now.AddMinutes(2)).CompletedNow.Should().BeFalse();
        progress.IsCompleted.Should().BeFalse();
    }

    [Fact]
    public void Scrolling_back_up_never_lowers_the_percent()
    {
        var progress = Opened("en");

        progress.Record("en", 60, "b5", 10, Now.AddSeconds(10));
        progress.Record("en", 20, "b2", 10, Now.AddSeconds(20));

        progress.Percent.Should().Be(60);
        progress.LastPosition.Should().Be("b2");
    }

    [Fact]
    public void Implausible_time_deltas_are_capped()
    {
        var progress = Opened("en");

        progress.Record("en", 10, null, activeSecondsDelta: 100_000, Now.AddHours(2));

        progress.ActiveSeconds.Should().Be(ReadingProgress.MaxSecondsPerReport);
    }

    [Fact]
    public void The_first_report_credits_no_time()
    {
        var progress = Opened();

        progress.Record("ar-EG", 100, null, activeSecondsDelta: 45, Now).CreditedSeconds.Should().Be(0);

        progress.ActiveSeconds.Should().Be(0);
        progress.IsCompleted.Should().BeFalse("30 seconds can't pass in one request");
    }

    [Fact]
    public void Seconds_are_capped_by_the_time_that_really_passed()
    {
        var progress = Opened();

        var update = progress.Record("ar-EG", 100, null, activeSecondsDelta: 40, Now.AddSeconds(5));

        update.CreditedSeconds.Should().Be(5 + ReadingProgress.ReportSlackSeconds);
        progress.IsCompleted.Should().BeFalse();
    }

    [Fact]
    public void Completing_raises_one_read_event()
    {
        var progress = Opened();

        progress.Record("ar-EG", 90, null, 40, Now.AddSeconds(40));
        progress.Record("ar-EG", 100, null, 40, Now.AddSeconds(80));

        progress.DomainEvents.Should().ContainSingle().Which.Should().BeOfType<ArticleReadCompletedDomainEvent>()
            .Which.ArticleId.Should().Be(progress.ArticleId);
    }
}
