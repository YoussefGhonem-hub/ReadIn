using ReadIn.Domain.Learning;

namespace ReadIn.Domain.UnitTests.Learning;

/// <summary>Editorial learning paths (F09): items follow the plan order and a path without articles stays unlisted.</summary>
public sealed class LearningPathTests
{
    private static LearningPath Path() => new("aspnet-core-basics", Guid.NewGuid(), "أساسيات ASP.NET Core", "ASP.NET Core Fundamentals", 1);

    [Fact]
    public void A_path_without_articles_is_not_published()
    {
        var path = Path();

        path.SetItems([]);

        path.IsPublished.Should().BeFalse();
    }

    [Fact]
    public void Items_are_replaced_and_reordered_without_duplicates()
    {
        var path = Path();
        var (a, b, c) = (Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid());
        path.SetItems([(a, 1), (b, 2)]);
        var kept = path.Items.Single(i => i.ArticleId == b);

        path.SetItems([(b, 1), (c, 2)]);

        path.IsPublished.Should().BeTrue();
        path.Items.Select(i => (i.ArticleId, i.Order)).Should().BeEquivalentTo([(b, 1), (c, 2)]);
        path.Items.Should().Contain(kept, "an article that stays in the path keeps its row");
    }
}
