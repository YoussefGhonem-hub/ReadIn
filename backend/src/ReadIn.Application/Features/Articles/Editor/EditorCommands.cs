using System.Text.Json;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Glossary;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Media;

namespace ReadIn.Application.Features.Articles.Editor;

/// <summary>POST /articles: a new, never-published draft holding <paramref name="Document"/> (F05).</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record CreateArticleDraftCommand(ArticleDraftDocument Document) : ICommand<Result<ArticleEditDto>>;

/// <summary>PUT /articles/{id}/draft: autosave; replaces the whole working copy if <paramref name="BaseVersion"/> is current.</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record SaveArticleDraftCommand(Guid ArticleId, int BaseVersion, ArticleDraftDocument Document) : ICommand<Result<ArticleEditDto>>;

/// <summary>DELETE /articles/{id}/draft: a published article's working copy goes back to what readers see.</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record DiscardArticleDraftCommand(Guid ArticleId) : ICommand<Result<ArticleEditDto>>;

/// <summary>POST /articles/{id}/publish: first publish or "Update"; the working copy goes live and becomes a revision.</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record PublishArticleDraftCommand(Guid ArticleId, int BaseVersion) : ICommand<Result<PublishedArticleDto>>;

/// <summary>POST /articles/{id}/revisions/{number}/restore: the revision becomes the working copy (live after the next publish).</summary>
[Authenticated]
[RequirePermission(Permissions.Articles.Create)]
public sealed record RestoreArticleRevisionCommand(Guid ArticleId, int Number, int BaseVersion) : ICommand<Result<ArticleEditDto>>;

internal sealed class CreateArticleDraftCommandHandler(IAppDbContext db, ICurrentUser currentUser, ArticleDrafts drafts, TimeProvider clock)
    : ICommandHandler<CreateArticleDraftCommand, Result<ArticleEditDto>>
{
    public async ValueTask<Result<ArticleEditDto>> Handle(CreateArticleDraftCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var taxonomy = await drafts.CheckTaxonomyAsync(command.Document, cancellationToken);
        if (taxonomy.IsFailure) return taxonomy.Error;

        var document = drafts.ToStored(command.Document);

        // The row needs a field; until the writer picks one it holds the first enabled field. Only the document counts.
        var fieldId = document.FieldId ?? await db.Fields.Where(f => f.IsEnabled).OrderBy(f => f.SortOrder).Select(f => f.Id).FirstAsync(cancellationToken);
        var article = Article.CreateDraft(userId, fieldId, document.TopicId, ArticleWriting.PlaceholderSlug(), sourceLanguage: document.SourceLanguage);
        article.SaveDraft(ArticleDraftJson.Serialize(document), baseVersion: 0, clock.GetUtcNow().UtcDateTime);

        db.Articles.Add(article);
        await db.SaveChangesAsync(cancellationToken);

        return drafts.ToEditDto(article, document, await drafts.EvaluateAsync(article.Id, userId, document, cancellationToken));
    }
}

internal sealed class SaveArticleDraftCommandHandler(IAppDbContext db, ICurrentUser currentUser, ArticleDrafts drafts, TimeProvider clock)
    : ICommandHandler<SaveArticleDraftCommand, Result<ArticleEditDto>>
{
    public async ValueTask<Result<ArticleEditDto>> Handle(SaveArticleDraftCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var article = await db.Articles.Include(a => a.Draft).FirstOrDefaultAsync(a => a.Id == command.ArticleId, cancellationToken);
        if (article is null || article.AuthorId != userId) return ArticleErrors.NotFound;

        var taxonomy = await drafts.CheckTaxonomyAsync(command.Document, cancellationToken);
        if (taxonomy.IsFailure) return taxonomy.Error;

        var document = drafts.ToStored(command.Document);
        var saved = article.SaveDraft(ArticleDraftJson.Serialize(document), command.BaseVersion, clock.GetUtcNow().UtcDateTime);
        if (saved.IsFailure) return saved.Error;
        if (!await EditorSaves.TrySaveAsync(db, cancellationToken)) return ArticleErrors.DraftConflict;

        return drafts.ToEditDto(article, document, await drafts.EvaluateAsync(article.Id, userId, document, cancellationToken));
    }
}

internal sealed class DiscardArticleDraftCommandHandler(IAppDbContext db, ICurrentUser currentUser, ArticleDrafts drafts, TimeProvider clock)
    : ICommandHandler<DiscardArticleDraftCommand, Result<ArticleEditDto>>
{
    public async ValueTask<Result<ArticleEditDto>> Handle(DiscardArticleDraftCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var article = await drafts.LoadAsync(command.ArticleId, cancellationToken);
        if (article is null || article.AuthorId != userId) return ArticleErrors.NotFound;

        var live = ArticleDrafts.FromLive(article);
        var discarded = article.DiscardDraft(ArticleDraftJson.Serialize(live), article.CurrentDraftVersion, clock.GetUtcNow().UtcDateTime);
        if (discarded.IsFailure) return discarded.Error;
        if (!await EditorSaves.TrySaveAsync(db, cancellationToken)) return ArticleErrors.DraftConflict;

        return drafts.ToEditDto(article, live, await drafts.EvaluateAsync(article.Id, userId, live, cancellationToken));
    }
}

internal sealed class PublishArticleDraftCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    ArticleDrafts drafts,
    IRDocProcessor rdoc,
    ArticleTermsIndex termsIndex,
    HybridCache cache,
    TimeProvider clock)
    : ICommandHandler<PublishArticleDraftCommand, Result<PublishedArticleDto>>
{
    public async ValueTask<Result<PublishedArticleDto>> Handle(PublishArticleDraftCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var article = await drafts.LoadAsync(command.ArticleId, cancellationToken);
        if (article is null || article.AuthorId != userId) return ArticleErrors.NotFound;
        if (article.CurrentDraftVersion != command.BaseVersion) return ArticleErrors.DraftConflict;

        var document = ArticleDrafts.Current(article);
        var evaluation = await drafts.EvaluateAsync(article.Id, userId, document, cancellationToken);
        if (evaluation.Problems.Count > 0) return EditorErrors.NotReady(evaluation.Problems);
        var field = evaluation.Field!;
        var now = clock.GetUtcNow().UtcDateTime;

        // Strict processing (SPEC §13.5): readers get sanitized RDoc, and the revision keeps exactly what went live.
        var versions = new List<TranslationVersion>();
        var published = new List<DraftTranslation>();
        foreach (var translation in document.Translations)
        {
            var processed = rdoc.Process(translation.Content, translation.Language, translation.Title);
            if (processed.IsFailure) return processed.Error;
            versions.Add(new TranslationVersion(translation.Language, translation.Title, translation.Subtitle, processed.Value.Content));
            published.Add(translation with { Content = JsonDocument.Parse(processed.Value.Content.Json).RootElement.Clone() });
        }

        article.SetTaxonomy(field.Id, document.TopicId);
        var applied = article.ReplaceTranslations(document.SourceLanguage, versions, now);
        if (applied.IsFailure) return applied.Error;
        var tagged = article.SetTags(await ArticleWriting.UpsertTagsAsync(db, document.Tags, cancellationToken));
        if (tagged.IsFailure) return tagged.Error;
        article.SetSources(document.Sources.Select(s => (s.Title, s.Url)));
        article.SetMetadata(document.CoverUrl, document.VersionBadge, document.IsAiAssisted);

        var attached = await AttachAsync(article, document.Attachments, evaluation, cancellationToken);
        if (attached.IsFailure) return attached.Error;

        var firstPublish = article.PublishedAt is null;
        if (firstPublish) article.AssignSlug(await ArticleWriting.UniqueSlugAsync(db, published[0].Title, cancellationToken));
        var live = article.Publish(field, now);
        if (live.IsFailure) return live.Error;

        var publishedJson = ArticleDraftJson.Serialize(document with { Translations = published });
        article.MarkDraftPublished(publishedJson, now);
        var number = (await db.ArticleRevisions.Where(r => r.ArticleId == article.Id)
            .MaxAsync(r => (int?)r.RevisionNumber, cancellationToken) ?? 0) + 1;
        db.ArticleRevisions.Add(new ArticleRevision(article.Id, number, published[0].Title, published.Select(t => t.Language), publishedJson, userId, now));

        if (!await EditorSaves.TrySaveAsync(db, cancellationToken)) return ArticleErrors.DraftConflict;

        // A first publish invalidates and indexes glossary terms through ArticlePublishedDomainEvent; an update changes
        // what readers see now, and may add or drop terms (F21).
        if (!firstPublish)
        {
            await cache.RemoveByTagAsync([CacheTags.Feed, CacheTags.Article(article.Slug)], cancellationToken);
            if (await termsIndex.RebuildAsync([article.Id], cancellationToken) > 0)
                await cache.RemoveByTagAsync(CacheTags.Glossary, cancellationToken);
        }
        return new PublishedArticleDto(article.Id, article.Slug, article.PublishedAt!.Value, number, firstPublish);
    }

    /// <summary>The working copy's attachments go live (ADR 0011); a PDF's title and download switch live on its asset.</summary>
    private async Task<Result> AttachAsync(Article article, IReadOnlyList<DraftAttachment> attachments, DraftEvaluation evaluation, CancellationToken ct)
    {
        var candidates = attachments
            .Select(a =>
            {
                var asset = evaluation.Assets[a.MediaAssetId];
                return new AttachmentCandidate(a.MediaAssetId, asset.Kind, asset.Status, asset.OwnerId, a.Order, a.Caption, a.AltText);
            })
            .ToList();
        var result = article.SetAttachments(candidates);
        if (result.IsFailure) return result;

        var documentIds = attachments.Where(a => evaluation.Assets[a.MediaAssetId].Kind == MediaKind.Document).Select(a => a.MediaAssetId).ToList();
        if (documentIds.Count == 0) return Result.Success();

        var documents = await db.MediaAssets.Where(m => documentIds.Contains(m.Id)).ToDictionaryAsync(m => m.Id, ct);
        foreach (var attachment in attachments.Where(a => documents.ContainsKey(a.MediaAssetId)))
        {
            var document = documents[attachment.MediaAssetId];
            var settings = document.UpdateDocumentSettings(attachment.Title ?? document.Title, attachment.AllowDownload ?? document.AllowDownload);
            if (settings.IsFailure) return settings;
        }
        return Result.Success();
    }
}

internal sealed class RestoreArticleRevisionCommandHandler(IAppDbContext db, ICurrentUser currentUser, ArticleDrafts drafts, TimeProvider clock)
    : ICommandHandler<RestoreArticleRevisionCommand, Result<ArticleEditDto>>
{
    public async ValueTask<Result<ArticleEditDto>> Handle(RestoreArticleRevisionCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var article = await db.Articles.Include(a => a.Draft).FirstOrDefaultAsync(a => a.Id == command.ArticleId, cancellationToken);
        if (article is null || article.AuthorId != userId) return ArticleErrors.NotFound;

        var revision = await db.ArticleRevisions.AsNoTracking()
            .FirstOrDefaultAsync(r => r.ArticleId == article.Id && r.RevisionNumber == command.Number, cancellationToken);
        if (revision is null) return ArticleErrors.RevisionNotFound;

        var restored = article.RestoreDraft(revision.DocumentJson, command.BaseVersion, clock.GetUtcNow().UtcDateTime);
        if (restored.IsFailure) return restored.Error;
        if (!await EditorSaves.TrySaveAsync(db, cancellationToken)) return ArticleErrors.DraftConflict;

        var document = ArticleDraftJson.Deserialize(revision.DocumentJson);
        return drafts.ToEditDto(article, document, await drafts.EvaluateAsync(article.Id, userId, document, cancellationToken));
    }
}

internal static class EditorSaves
{
    /// <summary>Saves; false when another request changed the working copy in between (its version is a concurrency token).</summary>
    public static async Task<bool> TrySaveAsync(IAppDbContext db, CancellationToken cancellationToken)
    {
        try
        {
            await db.SaveChangesAsync(cancellationToken);
            return true;
        }
        catch (DbUpdateConcurrencyException)
        {
            return false;
        }
    }
}
