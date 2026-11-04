using ReadIn.Domain.Articles;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Domain.UnitTests.Articles;

public sealed class ArticleTests
{
    private static readonly DateTime Now = new(2026, 11, 2, 8, 0, 0, DateTimeKind.Utc);
    private static readonly Guid AuthorId = Guid.NewGuid();
    private static readonly Guid ReviewerId = Guid.NewGuid();

    private static ArticleContent Content(int words = 900) =>
        new("{}", "text", "text", null, ReadingTimeMinutes: 5, WordCount: words);

    private static Field SoftwareField() => new("dotnet", ".NET", ".NET", "code", "primary", 1);

    private static Field SensitiveField()
    {
        var field = new Field("medicine", "الطب", "Medicine", "stethoscope", "error", 2);
        field.Update("الطب", "Medicine", "stethoscope", "error", 2, isSensitive: true, requiresSources: true, isEnabled: true);
        return field;
    }

    private static Article Draft(Field field, bool withSources = true)
    {
        var article = Article.CreateDraft(AuthorId, field.Id, topicId: null, "di-in-aspnet-core");
        article.AddTranslation("en", "Dependency Injection", null, Content()).IsSuccess.Should().BeTrue();
        if (withSources) article.SetSources([("Microsoft Learn", "https://learn.microsoft.com")]);
        return article;
    }

    [Fact]
    public void First_translation_becomes_the_source_language()
    {
        var article = Draft(SoftwareField());
        article.AddTranslation("ar-EG", "الـ DI", null, Content());

        article.SourceLanguage.Should().Be("en");
        article.Translations.Should().ContainSingle(t => t.IsSource).Which.Language.Should().Be("en");
    }

    [Fact]
    public void Adding_the_same_language_twice_is_a_conflict()
    {
        var article = Draft(SoftwareField());

        var result = article.AddTranslation("en", "Again", null, Content());

        result.Error.Should().Be(ArticleErrors.TranslationExists);
    }

    [Fact]
    public void Unsupported_language_is_rejected()
    {
        var article = Article.CreateDraft(AuthorId, Guid.NewGuid(), null, "slug");

        article.AddTranslation("fr", "Titre", null, Content()).Error.Should().Be(ArticleErrors.InvalidLanguage);
    }

    [Fact]
    public void Non_sensitive_article_can_be_published_without_review()
    {
        var field = SoftwareField();
        var article = Draft(field);

        var result = article.Publish(field, Now);

        result.IsSuccess.Should().BeTrue();
        article.Status.Should().Be(ArticleStatus.Published);
        article.PublishedAt.Should().Be(Now);
        article.IsReviewed.Should().BeFalse();
        article.DomainEvents.Should().ContainSingle(e => e is ArticlePublishedDomainEvent);
    }

    [Fact]
    public void Publishing_requires_sources_when_the_field_requires_them()
    {
        var field = SoftwareField();
        var article = Draft(field, withSources: false);

        article.Publish(field, Now).Error.Should().Be(ArticleErrors.SourcesRequired);
        article.Status.Should().Be(ArticleStatus.Draft);
    }

    [Fact]
    public void Health_fields_can_be_published_without_review()
    {
        var field = SensitiveField();
        var article = Draft(field);

        article.Publish(field, Now).IsSuccess.Should().BeTrue();
        article.Status.Should().Be(ArticleStatus.Published);
        article.IsReviewed.Should().BeFalse();
    }

    [Fact]
    public void Authors_cannot_approve_their_own_article()
    {
        var article = Draft(SoftwareField());
        article.SubmitForReview();

        article.Approve(AuthorId, Now).Error.Should().Be(ArticleErrors.CannotReviewOwnArticle);
    }

    [Fact]
    public void Review_flow_moves_through_the_lifecycle()
    {
        var article = Draft(SoftwareField());

        article.SubmitForReview();
        article.Status.Should().Be(ArticleStatus.Submitted);
        article.StartReview();
        article.Status.Should().Be(ArticleStatus.InReview);
        article.RequestChanges(ReviewerId);
        article.Status.Should().Be(ArticleStatus.ChangesRequested);
        article.SubmitForReview();
        article.Approve(ReviewerId, Now);

        article.Status.Should().Be(ArticleStatus.Approved);
        article.ReviewedById.Should().Be(ReviewerId);
        article.LastReviewedAt.Should().Be(Now);
    }

    [Fact]
    public void Approve_without_a_pending_review_is_a_conflict()
    {
        var article = Draft(SoftwareField());

        article.Approve(ReviewerId, Now).Error.Should().Be(ArticleErrors.NotPendingReview);
    }

    [Fact]
    public void Significant_edit_of_a_published_article_creates_a_revision_and_resets_the_reviewed_badge()
    {
        var field = SoftwareField();
        var article = Draft(field);
        article.SubmitForReview();
        article.Approve(ReviewerId, Now);
        article.Publish(field, Now);

        article.UpdateTranslation("en", "Dependency Injection v2", null, Content(words: 1500), AuthorId, Now.AddDays(1));

        article.Revisions.Should().ContainSingle().Which.Title.Should().Be("Dependency Injection");
        article.IsReviewed.Should().BeFalse();
        article.ReviewedById.Should().BeNull();
    }

    [Fact]
    public void Small_edit_keeps_the_reviewed_badge()
    {
        var field = SoftwareField();
        var article = Draft(field);
        article.SubmitForReview();
        article.Approve(ReviewerId, Now);
        article.Publish(field, Now);

        article.UpdateTranslation("en", "Dependency Injection", null, Content(words: 950), AuthorId, Now.AddDays(1));

        article.IsReviewed.Should().BeTrue();
    }

    [Fact]
    public void Scheduling_in_the_past_is_rejected()
    {
        var field = SoftwareField();
        var article = Draft(field);

        article.Schedule(field, Now.AddMinutes(-1), Now).Error.Should().Be(ArticleErrors.ScheduleInPast);
        article.Schedule(field, Now.AddDays(1), Now).IsSuccess.Should().BeTrue();
        article.Status.Should().Be(ArticleStatus.Scheduled);
    }

    [Fact]
    public void An_article_has_at_most_five_tags()
    {
        var article = Draft(SoftwareField());

        article.SetTags([.. Enumerable.Range(0, 6).Select(_ => Guid.NewGuid())]).Error.Should().Be(ArticleErrors.TooManyTags);
        article.SetTags([.. Enumerable.Range(0, 5).Select(_ => Guid.NewGuid())]).IsSuccess.Should().BeTrue();
    }

    [Fact]
    public void Archived_articles_cannot_be_published()
    {
        var field = SoftwareField();
        var article = Draft(field);
        article.Archive();

        article.Publish(field, Now).IsFailure.Should().BeTrue();
    }
}
