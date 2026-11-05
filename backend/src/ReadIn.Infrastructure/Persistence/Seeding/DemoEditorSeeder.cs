using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Articles.Editor;
using ReadIn.Application.Features.Tags;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Local only (demo data, ADR 0005): what the editor (F05, ADR 0015) shows on "My articles". Writer 1 has an unfinished
/// Arabic draft whose live checks list what it still needs; the verified writer has a short draft and a published article
/// with two revisions and unpublished changes in its working copy. Idempotent by slug.
/// </summary>
internal sealed class DemoEditorSeeder(AppDbContext db, IRDocProcessor rdoc, ArticleTagging tagging, TimeProvider clock) : ISeeder
{
    private const string SignalsSlug = "demo-editor-angular-signals-draft";
    private const string RiverpodSlug = "demo-editor-riverpod-draft";
    private const string FoldersSlug = "flutter-feature-first-folders";

    public string Name => "demo-editor";
    public int Order => 12;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => SeedEnvironments.AllowsDemoData(environment);

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        Task.FromResult(SeedChecksum.Of([SignalsSlug, RiverpodSlug, FoldersSlug, "v1"]));

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var fields = await db.Fields.AsNoTracking().Where(f => f.IsEnabled).ToDictionaryAsync(f => f.Slug, cancellationToken);

        if (await UserIdAsync("writer1@readin.test", cancellationToken) is { } writer1)
            await DraftAsync(writer1, SignalsSlug, SignalsDraft(fields.GetValueOrDefault("frontend")?.Id), now.AddHours(-3), cancellationToken);

        if (await UserIdAsync("writer.verified@readin.test", cancellationToken) is { } verified)
        {
            await DraftAsync(verified, RiverpodSlug, RiverpodDraft(), now.AddDays(-1), cancellationToken);
            if (fields.TryGetValue("mobile", out var mobile)) await PublishedWithHistoryAsync(verified, mobile.Id, now, cancellationToken);
        }
        return true;
    }

    /// <summary>A never-published draft: only its working copy (the editor's document) holds the content.</summary>
    private async Task DraftAsync(Guid authorId, string slug, ArticleDraftDocument document, DateTime savedAt, CancellationToken ct)
    {
        if (await db.Articles.IgnoreQueryFilters().AnyAsync(a => a.Slug == slug, ct)) return;

        var fieldId = document.FieldId ?? await db.Fields.Where(f => f.IsEnabled).OrderBy(f => f.SortOrder).Select(f => f.Id).FirstAsync(ct);
        var article = Article.CreateDraft(authorId, fieldId, document.TopicId, slug, sourceLanguage: document.SourceLanguage);
        article.SaveDraft(ArticleDraftJson.Serialize(document), baseVersion: 0, savedAt);
        db.Articles.Add(article);
        await db.SaveChangesAsync(ct);
    }

    /// <summary>Published ten days ago, updated three days ago (two revisions), edited an hour ago without publishing.</summary>
    private async Task PublishedWithHistoryAsync(Guid authorId, Guid fieldId, DateTime now, CancellationToken ct)
    {
        if (await db.Articles.IgnoreQueryFilters().AnyAsync(a => a.Slug == FoldersSlug, ct)) return;
        var field = await db.Fields.FirstAsync(f => f.Id == fieldId, ct);

        var first = Folders(fieldId, "Feature-first folders in Flutter",
            "Group code by feature, not by layer: each feature keeps its data, domain and presentation together.");
        var second = Folders(fieldId, "Feature-first folders in Flutter apps",
            "Group code by feature, not by layer. Each feature keeps its data, domain and presentation together, so a change touches one folder.",
            "Shared code (theme, networking, l10n) lives in core/, and features never import each other.");
        var working = Folders(fieldId, "Feature-first folders in Flutter apps, with examples",
            "Group code by feature, not by layer. Each feature keeps its data, domain and presentation together, so a change touches one folder.",
            "Shared code (theme, networking, l10n) lives in core/, and features never import each other.",
            "Draft note: add the example from the ReadIn app itself.");

        var (firstPublished, firstContent) = Process(first);
        var article = Article.CreateDraft(authorId, fieldId, topicId: null, FoldersSlug);
        article.AddTranslation("en", first.Translations[0].Title, null, firstContent);
        article.SetSources(first.Sources.Select(s => (s.Title, s.Url)));
        // The writer's own tags (F32), so the demo has user-created tags next to the system ones.
        if (article.SetTags(await tagging.ResolveAsync(first.Tags, authorId, ct)).IsFailure) return;
        db.Articles.Add(article);
        await db.SaveChangesAsync(ct);

        var tenDaysAgo = now.AddDays(-10);
        if (article.Publish(field, tenDaysAgo).IsFailure) return;
        article.MarkDraftPublished(ArticleDraftJson.Serialize(firstPublished), tenDaysAgo);
        db.ArticleRevisions.Add(Revision(article.Id, 1, firstPublished, authorId, tenDaysAgo));
        await db.SaveChangesAsync(ct);

        var threeDaysAgo = now.AddDays(-3);
        var (secondPublished, secondContent) = Process(second);
        article.ReplaceTranslations("en", [new TranslationVersion("en", second.Translations[0].Title, null, secondContent)], threeDaysAgo);
        article.MarkDraftPublished(ArticleDraftJson.Serialize(secondPublished), threeDaysAgo);
        db.ArticleRevisions.Add(Revision(article.Id, 2, secondPublished, authorId, threeDaysAgo));
        await db.SaveChangesAsync(ct);

        article.SaveDraft(ArticleDraftJson.Serialize(working), article.CurrentDraftVersion, now.AddHours(-1));
        await db.SaveChangesAsync(ct);
    }

    /// <summary>The document as readers get it: sanitized RDoc (SPEC §13.5), the way a publish stores it.</summary>
    private (ArticleDraftDocument Published, ArticleContent Content) Process(ArticleDraftDocument document)
    {
        var translation = document.Translations[0];
        var processed = rdoc.Process(translation.Content, translation.Language, translation.Title);
        if (processed.IsFailure) throw new InvalidOperationException($"Demo article content is invalid: {processed.Error.Code}");

        var content = processed.Value.Content;
        var published = translation with { Content = JsonDocument.Parse(content.Json).RootElement.Clone() };
        return (document with { Translations = [published] }, content);
    }

    private static ArticleRevision Revision(Guid articleId, int number, ArticleDraftDocument document, Guid editorId, DateTime at) =>
        new(articleId, number, document.Translations[0].Title, document.Translations.Select(t => t.Language), ArticleDraftJson.Serialize(document), editorId, at);

    private static ArticleDraftDocument Folders(Guid fieldId, string title, params string[] paragraphs) => new()
    {
        SourceLanguage = ArticleLanguages.English,
        Translations = [new DraftTranslation(ArticleLanguages.English, title, null, RDoc(ArticleLanguages.English,
            [.. paragraphs.Select((text, i) => Paragraph($"p{i + 1}", text)),
             new { id = "c1", type = "code", lang = "text", filename = "lib/features", code = "features/\n  auth/\n    data/\n    domain/\n    presentation/\n  editor/" }]))],
        FieldId = fieldId,
        Tags = ["Flutter", "Architecture"],
        Sources = [new SourceDto("Flutter app architecture guide", "https://docs.flutter.dev/app-architecture/guide")],
    };

    /// <summary>Unfinished on purpose: no sources yet and an image without alt text, so the editor lists both problems.</summary>
    private static ArticleDraftDocument SignalsDraft(Guid? fieldId) => new()
    {
        SourceLanguage = ArticleLanguages.EgyptianArabic,
        Translations = [new DraftTranslation(ArticleLanguages.EgyptianArabic, "الـ Signals في Angular من غير لف ودوران", null, RDoc(ArticleLanguages.EgyptianArabic,
        [
            Paragraph("p1", "الـ Signal ببساطة قيمة بتعرف مين بيقراها، ولما تتغير بتبلغهم لوحدها."),
            new { id = "h1", type = "heading", level = 2, dir = "auto", content = new[] { new { type = "text", text = "إمتى تستخدم computed؟" } } },
            new { id = "c1", type = "code", lang = "typescript", code = "const count = signal(0);\nconst double = computed(() => count() * 2);" },
            new { id = "i1", type = "image", src = "https://angular.dev/assets/images/press-kit/angular_icon_gradient.gif", alt = "" },
        ]))],
        FieldId = fieldId,
        Tags = ["Angular", "Signals"],
    };

    /// <summary>Just started: no field picked yet.</summary>
    private static ArticleDraftDocument RiverpodDraft() => new()
    {
        SourceLanguage = ArticleLanguages.EgyptianArabic,
        Translations = [new DraftTranslation(ArticleLanguages.EgyptianArabic, "Riverpod ولا Bloc؟", null, RDoc(ArticleLanguages.EgyptianArabic,
            [Paragraph("p1", "السؤال ده بيتسأل كتير، والإجابة مش واحدة لكل المشاريع.")]))],
    };

    private static object Paragraph(string id, string text) =>
        new { id, type = "paragraph", dir = "auto", content = new[] { new { type = "text", text } } };

    private static JsonElement RDoc(string language, object[] blocks) =>
        JsonSerializer.SerializeToElement(new { version = 1, language, blocks });

    private async Task<Guid?> UserIdAsync(string email, CancellationToken ct) =>
        await db.Users.Where(u => u.Email == email).Select(u => (Guid?)u.Id).FirstOrDefaultAsync(ct);
}
