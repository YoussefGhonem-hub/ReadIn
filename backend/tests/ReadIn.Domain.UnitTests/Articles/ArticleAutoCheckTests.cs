using ReadIn.Domain.Articles;

namespace ReadIn.Domain.UnitTests.Articles;

/// <summary>Content-pipeline articles (SPEC §19.3, F07): auto-checked is not reviewed, and no reviewer is ever invented.</summary>
public sealed class ArticleAutoCheckTests
{
    private static readonly DateTime CheckedAt = new(2026, 11, 3, 0, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Auto_checked_sets_the_last_reviewed_date_without_a_reviewer()
    {
        var article = Article.CreateDraft(Guid.NewGuid(), Guid.NewGuid(), topicId: null, "hashing-is-not-encryption");

        article.MarkAutoChecked(CheckedAt);

        article.AutoCheckedAt.Should().Be(CheckedAt);
        article.LastReviewedAt.Should().Be(CheckedAt);
        article.IsReviewed.Should().BeFalse();
        article.ReviewedById.Should().BeNull();
    }

    [Fact]
    public void A_human_review_date_is_never_overwritten_by_an_automatic_check()
    {
        var article = Article.CreateDraft(Guid.NewGuid(), Guid.NewGuid(), topicId: null, "reviewed-article");
        var reviewedAt = CheckedAt.AddDays(-10);
        article.MarkReviewed(Guid.NewGuid(), reviewedAt);

        article.MarkAutoChecked(CheckedAt);

        article.LastReviewedAt.Should().Be(reviewedAt);
        article.IsReviewed.Should().BeTrue();
    }
}
