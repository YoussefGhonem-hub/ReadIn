using ReadIn.Domain.Learning;

namespace ReadIn.Domain.UnitTests.Learning;

/// <summary>
/// Learning paths (F09): editorial paths follow the plan order and stay unlisted without articles; admin paths are
/// published explicitly; enrollments track activity and earn the completion badge once.
/// </summary>
public sealed class LearningPathTests
{
    private static LearningPath Editorial() =>
        LearningPath.CreateEditorial("aspnet-core-basics", Guid.NewGuid(), "أساسيات ASP.NET Core", "ASP.NET Core Fundamentals", 1);

    private static LearningPath AdminPath() => new("my-path", Guid.NewGuid(), "مسار", "Path", 0);

    [Fact]
    public void An_editorial_path_without_articles_is_not_published()
    {
        var path = Editorial();

        path.SyncEditorial([]);

        path.IsPublished.Should().BeFalse();
        path.IsEditorial.Should().BeTrue();
    }

    [Fact]
    public void Editorial_items_are_replaced_and_reordered_without_duplicates()
    {
        var path = Editorial();
        var (a, b, c) = (Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid());
        path.SyncEditorial([(a, 1), (b, 2)]);
        var kept = path.Items.Single(i => i.ArticleId == b);

        path.SyncEditorial([(b, 1), (c, 2)]);

        path.IsPublished.Should().BeTrue();
        path.Items.Select(i => (i.ArticleId, i.Order)).Should().BeEquivalentTo([(b, 1), (c, 2)]);
        path.Items.Should().Contain(kept, "an article that stays in the path keeps its row");
    }

    [Fact]
    public void An_editorial_path_that_loses_its_articles_is_unlisted_again()
    {
        var path = Editorial();
        path.SyncEditorial([(Guid.NewGuid(), 1)]);

        path.SyncEditorial([]);

        path.IsPublished.Should().BeFalse();
    }

    [Fact]
    public void An_admin_path_is_not_editorial_and_needs_items_before_it_is_published()
    {
        var path = AdminPath();

        var result = path.Publish();

        path.IsEditorial.Should().BeFalse();
        result.IsFailure.Should().BeTrue();
        result.Error!.Code.Should().Be("path.items_invalid");
        path.IsPublished.Should().BeFalse();
    }

    [Fact]
    public void Admin_items_follow_the_given_order_and_setting_them_does_not_publish()
    {
        var path = AdminPath();
        var (a, b) = (Guid.NewGuid(), Guid.NewGuid());

        path.SetItemsInOrder([b, a]);

        path.Items.OrderBy(i => i.Order).Select(i => i.ArticleId).Should().Equal(b, a);
        path.IsPublished.Should().BeFalse();
        path.Publish().IsSuccess.Should().BeTrue();
        path.IsPublished.Should().BeTrue();

        path.Unpublish();
        path.IsPublished.Should().BeFalse();
    }

    [Fact]
    public void An_enrollment_completes_once_every_article_is_read_and_keeps_the_badge()
    {
        var start = new DateTime(2026, 11, 4, 8, 0, 0, DateTimeKind.Utc);
        var enrollment = new PathEnrollment(Guid.NewGuid(), Guid.NewGuid(), start);

        enrollment.CompleteIfDone(readCount: 2, total: 3, start.AddHours(1)).Should().BeFalse();
        enrollment.IsCompleted.Should().BeFalse();

        enrollment.CompleteIfDone(readCount: 3, total: 3, start.AddHours(2)).Should().BeTrue();
        enrollment.CompletedAt.Should().Be(start.AddHours(2));

        // The path grows later: the badge stays, and completing "again" doesn't move it.
        enrollment.CompleteIfDone(readCount: 4, total: 4, start.AddHours(3)).Should().BeFalse();
        enrollment.CompletedAt.Should().Be(start.AddHours(2));
    }

    [Fact]
    public void An_empty_path_is_never_completed()
    {
        var enrollment = new PathEnrollment(Guid.NewGuid(), Guid.NewGuid(), DateTime.UtcNow);

        enrollment.CompleteIfDone(readCount: 0, total: 0, DateTime.UtcNow).Should().BeFalse();
    }

    [Fact]
    public void Activity_only_moves_forward()
    {
        var start = new DateTime(2026, 11, 4, 8, 0, 0, DateTimeKind.Utc);
        var enrollment = new PathEnrollment(Guid.NewGuid(), Guid.NewGuid(), start);

        enrollment.RecordActivity(start.AddMinutes(5));
        enrollment.RecordActivity(start.AddMinutes(1)); // a late outbox retry

        enrollment.LastActivityAt.Should().Be(start.AddMinutes(5));
    }
}
