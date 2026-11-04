using ReadIn.Domain.Articles;

namespace ReadIn.Domain.UnitTests.Articles;

/// <summary>The quality score that ranks Today's article (F07, ADR 0015).</summary>
public sealed class ArticleQualityTests
{
    [Fact]
    public void A_brand_new_article_scores_half_completion_and_full_freshness()
    {
        ArticleQuality.Score(0, 0, 0, 0, 0, 0).Should().BeApproximately(0.35 * 0.5 + 0.20, 1e-9);
    }

    [Fact]
    public void Engagement_is_half_at_ten_weighted_interactions_and_saves_weigh_most()
    {
        // 10 reactions = 5 comments ≈ 3.3 saves: each is 10 weighted interactions → engagement 0.5.
        var byReactions = ArticleQuality.Score(10, 0, 0, 0, 0, 0);
        ArticleQuality.Score(0, 5, 0, 0, 0, 0).Should().BeApproximately(byReactions, 1e-9);
        byReactions.Should().BeApproximately(0.45 * 0.5 + 0.35 * 0.5 + 0.20, 1e-9);

        ArticleQuality.Score(0, 0, 4, 0, 0, 0).Should().BeGreaterThan(byReactions);
    }

    [Fact]
    public void Completion_rewards_readers_who_finish_and_is_smoothed_for_few_readers()
    {
        var allFinished = ArticleQuality.Score(0, 0, 0, completedReads: 20, startedReads: 20, 0);
        var fewFinished = ArticleQuality.Score(0, 0, 0, completedReads: 2, startedReads: 20, 0);

        allFinished.Should().BeGreaterThan(fewFinished);
        ArticleQuality.Score(0, 0, 0, 1, 1, 0).Should().BeLessThan(allFinished, "one reader is weaker evidence than twenty");
    }

    [Fact]
    public void Freshness_halves_every_thirty_days()
    {
        var fresh = ArticleQuality.Score(0, 0, 0, 0, 0, 0);
        var month = ArticleQuality.Score(0, 0, 0, 0, 0, 30 * 24);

        (fresh - month).Should().BeApproximately(0.20 * 0.5, 1e-9);
    }

    [Fact]
    public void The_score_stays_between_zero_and_one()
    {
        ArticleQuality.Score(100_000, 100_000, 100_000, 100_000, 100_000, 0).Should().BeLessThanOrEqualTo(1);
        ArticleQuality.Score(0, 0, 0, 0, 1_000_000, 1_000_000).Should().BeGreaterThan(0);
    }
}
