using ReadIn.Domain.Moderation;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Domain.UnitTests.Articles;

/// <summary>SPEC F31: a writer category keeps its slug on rename; only a moderator's clear gives it a new one.</summary>
public sealed class WriterCategoryTests
{
    private static readonly DateTime Now = new(2026, 11, 5, 9, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Renaming_keeps_the_slug_and_the_order()
    {
        var category = new WriterCategory(Guid.NewGuid(), "Clean Code", "clean code", "clean-code", 2, Now);

        category.Rename("Clean Architecture", "clean architecture");

        category.Name.Should().Be("Clean Architecture");
        category.NormalizedName.Should().Be("clean architecture");
        category.Slug.Should().Be("clean-code", "links keep working");
        category.SortOrder.Should().Be(2);
    }

    [Fact]
    public void A_moderators_clear_replaces_the_name_and_the_slug()
    {
        var category = new WriterCategory(Guid.NewGuid(), "Offensive", "offensive", "offensive", 1, Now);

        category.ClearName("Category 1", "category 1", "category-1");

        category.Name.Should().Be("Category 1");
        category.Slug.Should().Be("category-1", "the old slug held the name");
    }

    [Fact]
    public void Moving_changes_only_the_order()
    {
        var category = new WriterCategory(Guid.NewGuid(), "A", "a", "a", 1, Now);
        category.MoveTo(5);
        category.SortOrder.Should().Be(5);
        category.Slug.Should().Be("a");
    }

    [Fact]
    public void A_category_needs_a_name_and_a_slug()
    {
        var userId = Guid.NewGuid();
        FluentActions.Invoking(() => new WriterCategory(userId, " ", "x", "x", 1, Now)).Should().Throw<ArgumentException>();
        FluentActions.Invoking(() => new WriterCategory(userId, "x", "x", "", 1, Now)).Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Clearing_a_name_is_logged_on_the_user_with_the_old_name()
    {
        var userId = Guid.NewGuid();
        var logged = ModerationAction.CategoryCleared(userId, "Offensive   words", Guid.NewGuid(), " Not allowed. ", reportsClosed: 2, Now);

        logged.Action.Should().Be(ModerationActionTypes.UserClearCategory);
        logged.TargetType.Should().Be(ReportTargetType.User);
        logged.TargetId.Should().Be(userId);
        logged.TargetUserId.Should().Be(userId);
        logged.TargetLabel.Should().Be("Offensive words");
        logged.Note.Should().Be("Not allowed.");
        logged.ReportsClosed.Should().Be(2);
        logged.IsNotice.Should().BeFalse("the writer gets no notice");
    }
}
