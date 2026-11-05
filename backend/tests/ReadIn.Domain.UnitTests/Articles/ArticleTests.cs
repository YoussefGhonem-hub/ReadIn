using ReadIn.Domain.Articles;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Domain.UnitTests.Articles;

public sealed class ArticleTests
{
    private static readonly DateTime Now = new(2026, 11, 2, 8, 0, 0, DateTimeKind.Utc);
    private static readonly Guid AuthorId = Guid.NewGuid();

    private static ArticleContent Content(int words = 900) =>
        new("{}", "text", "text", null, ReadingTimeMinutes: 5, WordCount: words, Excerpt: "text", ExcerptHasMore: false);

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
    public void Any_article_publishes_directly_without_review()
    {
        var field = SoftwareField();
        var article = Draft(field);

        var result = article.Publish(field, Now);

        result.IsSuccess.Should().BeTrue();
        article.Status.Should().Be(ArticleStatus.Published);
        article.PublishedAt.Should().Be(Now);
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
    public void Sensitive_fields_publish_directly_too()
    {
        var field = SensitiveField();
        var article = Draft(field);

        article.Publish(field, Now).IsSuccess.Should().BeTrue();
        article.Status.Should().Be(ArticleStatus.Published);
    }

    [Fact]
    public void Publishing_again_is_an_update_that_keeps_the_first_date_and_raises_no_new_event()
    {
        var field = SoftwareField();
        var article = Draft(field);
        article.Publish(field, Now);
        var events = article.DomainEvents.Count;

        article.Publish(field, Now.AddDays(3)).IsSuccess.Should().BeTrue();

        article.PublishedAt.Should().Be(Now);
        article.DomainEvents.Should().HaveCount(events);
    }

    [Fact]
    public void A_first_publish_starts_with_the_quality_score_of_a_new_article()
    {
        var field = SoftwareField();
        var article = Draft(field);

        article.Publish(field, Now);

        article.QualityScore.Should().BeApproximately(ArticleQuality.Score(0, 0, 0, 0, 0, 0), 1e-9);
    }

    [Fact]
    public void Replacing_translations_updates_adds_removes_and_sets_the_source()
    {
        var article = Draft(SoftwareField());
        article.AddTranslation("ar-EG", "الـ DI", null, Content());

        var result = article.ReplaceTranslations("ar-EG", [new TranslationVersion("ar-EG", " الـ DI ببساطة ", "مقدمة", Content(1000))], Now);

        result.IsSuccess.Should().BeTrue();
        article.SourceLanguage.Should().Be("ar-EG");
        var only = article.Translations.Should().ContainSingle().Which;
        only.Language.Should().Be("ar-EG");
        only.Title.Should().Be("الـ DI ببساطة");
        only.Subtitle.Should().Be("مقدمة");
        only.IsSource.Should().BeTrue();
        only.WordCount.Should().Be(1000);

        article.ReplaceTranslations("ar-EG", [new("ar-EG", "الـ DI", null, Content()), new("en", "DI", null, Content())], Now);
        article.Translations.Select(t => (t.Language, t.IsSource)).Should().BeEquivalentTo([("ar-EG", true), ("en", false)]);
    }

    [Fact]
    public void Replacing_translations_needs_the_source_language_and_distinct_languages()
    {
        var article = Draft(SoftwareField());

        article.ReplaceTranslations("ar-EG", [new("en", "DI", null, Content())], Now).Error.Should().Be(ArticleErrors.TranslationNotFound);
        article.ReplaceTranslations("en", [new("en", "A", null, Content()), new("en", "B", null, Content())], Now)
            .Error.Should().Be(ArticleErrors.TranslationExists);
        article.ReplaceTranslations("en", [], Now).Error.Should().Be(ArticleErrors.NoContent);
        article.Translations.Should().ContainSingle().Which.Title.Should().Be("Dependency Injection");
    }

    [Fact]
    public void Autosave_needs_the_current_version_and_bumps_it()
    {
        var article = Article.CreateDraft(AuthorId, Guid.NewGuid(), null, "draft-x", sourceLanguage: "ar-EG");
        article.CurrentDraftVersion.Should().Be(0);

        article.SaveDraft("""{"a":1}""", baseVersion: 0, Now).IsSuccess.Should().BeTrue();
        article.SaveDraft("""{"a":2}""", baseVersion: 1, Now.AddSeconds(10)).IsSuccess.Should().BeTrue();

        article.SaveDraft("""{"a":3}""", baseVersion: 1, Now.AddSeconds(20)).Error.Should().Be(ArticleErrors.DraftConflict);
        article.CurrentDraftVersion.Should().Be(2);
        article.Draft!.DocumentJson.Should().Be("""{"a":2}""");
        article.Draft.SavedAt.Should().Be(Now.AddSeconds(10));
        article.Draft.HasChanges.Should().BeFalse("a never-published draft has nothing published to differ from");
    }

    [Fact]
    public void Editing_a_published_article_marks_unpublished_changes_until_the_next_publish()
    {
        var field = SoftwareField();
        var article = Draft(field);
        article.Publish(field, Now);

        article.SaveDraft("""{"edit":1}""", baseVersion: 0, Now.AddHours(1));
        article.Draft!.HasChanges.Should().BeTrue();

        article.MarkDraftPublished("""{"live":1}""", Now.AddHours(2));
        article.Draft.HasChanges.Should().BeFalse();
        article.Draft.DocumentJson.Should().Be("""{"live":1}""");
        article.CurrentDraftVersion.Should().Be(1, "publishing does not change the version the editor holds");
    }

    [Fact]
    public void Discarding_resets_the_working_copy_and_is_only_for_published_articles()
    {
        var field = SoftwareField();
        var article = Draft(field);
        article.SaveDraft("""{"edit":1}""", 0, Now);

        article.DiscardDraft("""{"live":1}""", 1, Now).Error.Should().Be(ArticleErrors.NotPublished);

        article.Publish(field, Now);
        article.SaveDraft("""{"edit":2}""", 1, Now.AddHours(1));
        article.DiscardDraft("""{"live":1}""", 1, Now).Error.Should().Be(ArticleErrors.DraftConflict);
        article.DiscardDraft("""{"live":1}""", 2, Now.AddHours(2)).IsSuccess.Should().BeTrue();

        article.Draft!.HasChanges.Should().BeFalse();
        article.Draft.DocumentJson.Should().Be("""{"live":1}""");
        article.CurrentDraftVersion.Should().Be(3);
    }

    [Fact]
    public void Restoring_a_revision_puts_it_in_the_working_copy()
    {
        var field = SoftwareField();
        var article = Draft(field);
        article.Publish(field, Now);

        article.RestoreDraft("""{"revision":1}""", baseVersion: 0, Now.AddDays(1)).IsSuccess.Should().BeTrue();

        article.Draft!.DocumentJson.Should().Be("""{"revision":1}""");
        article.Draft.HasChanges.Should().BeTrue();
        article.RestoreDraft("""{"revision":2}""", baseVersion: 0, Now).Error.Should().Be(ArticleErrors.DraftConflict);
    }

    [Fact]
    public void The_slug_is_fixed_at_the_first_publish()
    {
        var field = SoftwareField();
        var article = Draft(field);
        article.AssignSlug("dependency-injection");
        article.Publish(field, Now);

        article.Slug.Should().Be("dependency-injection");
        article.Invoking(a => a.AssignSlug("other")).Should().Throw<InvalidOperationException>();
    }

    [Fact]
    public void Auto_checked_records_the_pipeline_date()
    {
        var article = Article.CreateDraft(Guid.NewGuid(), Guid.NewGuid(), topicId: null, "hashing-is-not-encryption");
        var checkedAt = Now.AddDays(-1);

        article.MarkAutoChecked(checkedAt);

        article.AutoCheckedAt.Should().Be(checkedAt);
    }

    [Fact]
    public void An_article_has_at_most_five_tags()
    {
        var article = Draft(SoftwareField());

        article.SetTags([.. Enumerable.Range(0, 6).Select(_ => Guid.NewGuid())]).Error.Should().Be(ArticleErrors.TooManyTags);
        article.SetTags([.. Enumerable.Range(0, 5).Select(_ => Guid.NewGuid())]).IsSuccess.Should().BeTrue();
    }

    [Fact]
    public void Tags_keep_the_writers_order_and_a_repeat_counts_once()
    {
        var article = Draft(SoftwareField());
        Guid a = Guid.NewGuid(), b = Guid.NewGuid(), c = Guid.NewGuid();

        article.SetTags([a, b, a, c]).IsSuccess.Should().BeTrue();
        article.Tags.OrderBy(t => t.Position).Select(t => t.TagId).Should().Equal(a, b, c);

        article.SetTags([c, a]).IsSuccess.Should().BeTrue();
        article.Tags.OrderBy(t => t.Position).Select(t => t.TagId).Should().Equal(c, a);
        article.Tags.Select(t => t.Position).Should().BeEquivalentTo([0, 1]);
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
