using ReadIn.Application.Features.Feed;

namespace ReadIn.Application.UnitTests.Feed;

/// <summary>The For you ranking's boosts (ADR 0020, contract-v1 "For you ranking"); the SQL computes the same numbers.</summary>
public sealed class FeedRankingTests
{
    private const int Day = 24 * 60 * 60;

    [Theory]
    [InlineData(0, 0.0)]
    [InlineData(20, 0.5)]
    [InlineData(60, 0.75)]
    [InlineData(-5, 0.0)]
    public void Popularity_saturates_with_half_at_twenty_points(int engagement, double expected) =>
        FeedRanking.Popularity(engagement).Should().BeApproximately(expected, 1e-12);

    [Fact]
    public void Nobody_engaging_and_no_badge_is_no_boost() => FeedRanking.BoostSeconds(0, verified: false).Should().Be(0);

    [Fact]
    public void The_verified_badge_is_worth_a_day() => FeedRanking.BoostSeconds(0, verified: true).Should().Be(Day);

    [Fact]
    public void Engagement_is_worth_up_to_four_days_and_never_more()
    {
        FeedRanking.BoostSeconds(20, verified: false).Should().Be(2 * Day, "half of the most popularity can add");
        FeedRanking.BoostSeconds(1_000_000, verified: false).Should().BeLessThan(4 * Day);
        FeedRanking.BoostSeconds(1_000_000, verified: true).Should().BeLessThan(5 * Day);
    }

    [Fact]
    public void More_engagement_never_ranks_lower()
    {
        var boosts = Enumerable.Range(0, 200).Select(e => FeedRanking.BoostSeconds(e, verified: false)).ToList();
        boosts.Should().BeInAscendingOrder();
        boosts.Distinct().Should().HaveCount(boosts.Count, "every point counts at this scale");
    }

    [Fact]
    public void One_reaction_by_someone_else_moves_an_article_up_about_eight_and_a_half_hours() =>
        // E = 2 → popularity 1/11 → 4 days / 11.
        FeedRanking.BoostSeconds(FeedRanking.ReactionWeight, verified: false).Should().Be(31_418);

    [Fact]
    public void A_save_and_a_reaction_beat_the_badge_but_a_reaction_alone_does_not()
    {
        var reaction = FeedRanking.BoostSeconds(FeedRanking.ReactionWeight, verified: false);
        var reactionAndSave = FeedRanking.BoostSeconds(FeedRanking.ReactionWeight + FeedRanking.SaveWeight, verified: false);
        var badge = FeedRanking.BoostSeconds(0, verified: true);

        reaction.Should().BeLessThan(badge);
        reactionAndSave.Should().BeGreaterThan(badge, "E = 8 → popularity 2/7 → about 1.14 days");
    }
}
