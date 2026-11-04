using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Articles.Editor;

/// <summary>GET /articles/{id}/edit: the working copy with its live checks; the author only (404 for anyone else).</summary>
[Authenticated]
public sealed record GetArticleForEditQuery(Guid ArticleId) : IQuery<Result<ArticleEditDto>>;

/// <summary>GET /me/articles?status=draft|published: the "My articles" page (F05).</summary>
[Authenticated]
public sealed record GetMyArticlesQuery(string? Status, string? Cursor, int Limit, string UiLanguage) : IQuery<Result<CursorPage<MyArticleDto>>>;

/// <summary>GET /articles/{id}/revisions: one entry per publish, newest first.</summary>
[Authenticated]
public sealed record GetArticleRevisionsQuery(Guid ArticleId) : IQuery<Result<IReadOnlyList<ArticleRevisionDto>>>;

/// <summary>GET /articles/{id}/revisions/{number}: a revision's document, for its preview.</summary>
[Authenticated]
public sealed record GetArticleRevisionQuery(Guid ArticleId, int Number) : IQuery<Result<ArticleRevisionDetailsDto>>;

/// <summary>GET /tags?q=: tag suggestions for the editor, most used first.</summary>
public sealed record SearchTagsQuery(string? Query, int Limit) : IQuery<Result<IReadOnlyList<TagDto>>>;

internal sealed class GetArticleForEditQueryHandler(ICurrentUser currentUser, ArticleDrafts drafts)
    : IQueryHandler<GetArticleForEditQuery, Result<ArticleEditDto>>
{
    public async ValueTask<Result<ArticleEditDto>> Handle(GetArticleForEditQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var article = await drafts.LoadAsync(query.ArticleId, cancellationToken);
        if (article is null || article.AuthorId != userId) return ArticleErrors.NotFound;

        var document = ArticleDrafts.Current(article);
        return drafts.ToEditDto(article, document, await drafts.EvaluateAsync(article.Id, userId, document, cancellationToken));
    }
}

internal sealed class GetMyArticlesQueryHandler(IAppDbContext db, ICurrentUser currentUser, IRDocProcessor rdoc, IFileStorage storage)
    : IQueryHandler<GetMyArticlesQuery, Result<CursorPage<MyArticleDto>>>
{
    private const int MaxLimit = 50;

    public async ValueTask<Result<CursorPage<MyArticleDto>>> Handle(GetMyArticlesQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var drafts = query.Status is null or "draft";
        if (!drafts && query.Status != "published") return EditorErrors.StatusInvalid;
        var limit = Math.Clamp(query.Limit, 1, MaxLimit);

        var mine = db.Articles.AsNoTracking().Where(a => a.AuthorId == userId);
        mine = drafts ? mine.Where(a => a.PublishedAt == null) : mine.Where(a => a.Status == ArticleStatus.Published);
        var rows = mine.Select(a => new
        {
            a.Id,
            a.Slug,
            a.SourceLanguage,
            SortKey = drafts ? (a.Draft != null ? a.Draft.SavedAt : a.UpdatedAt ?? a.CreatedAt) : a.PublishedAt ?? a.CreatedAt,
            SavedAt = a.Draft != null ? a.Draft.SavedAt : a.UpdatedAt ?? a.CreatedAt,
            a.PublishedAt,
            HasChanges = a.Draft != null && a.Draft.HasChanges,
            DocumentJson = drafts && a.Draft != null ? a.Draft.DocumentJson : null,
            Title = a.Translations.Where(t => t.IsSource).Select(t => t.Title).FirstOrDefault(),
            ReadingTimeMinutes = a.Translations.Where(t => t.IsSource).Select(t => (int?)t.ReadingTimeMinutes).FirstOrDefault(),
            a.CoverUrl,
            a.FieldId,
            a.ReactionCount,
            a.CommentCount,
            a.ReadCount,
        });

        if (TimeCursor.Decode(query.Cursor) is { } cursor)
            rows = rows.Where(r => r.SortKey < cursor.Timestamp || (r.SortKey == cursor.Timestamp && r.Id.CompareTo(cursor.Id) < 0));

        var page = (await rows.OrderByDescending(r => r.SortKey).ThenByDescending(r => r.Id).Take(limit + 1).ToListAsync(cancellationToken))
            .Select(r => new Row(r.Id, r.Slug, r.SourceLanguage, r.SortKey, r.SavedAt, r.PublishedAt, r.HasChanges, r.DocumentJson, r.Title,
                r.ReadingTimeMinutes, r.CoverUrl, r.FieldId, r.ReactionCount, r.CommentCount, r.ReadCount))
            .ToList();
        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            next = new TimeCursor(page[^1].SortKey, page[^1].Id).Encode();
        }

        var documents = page.ToDictionary(r => r.Id, r => r.DocumentJson is null ? null : ArticleDraftJson.Deserialize(r.DocumentJson));
        var fieldIds = page.Select(r => documents[r.Id] is { } d ? d.FieldId : r.FieldId).OfType<Guid>().Distinct().ToList();
        var fields = await db.Fields.AsNoTracking().Where(f => fieldIds.Contains(f.Id)).ToDictionaryAsync(f => f.Id, cancellationToken);

        return new CursorPage<MyArticleDto>([.. page.Select(r => ToDto(r, documents[r.Id], fields, query.UiLanguage))], next);
    }

    private MyArticleDto ToDto(Row row, ArticleDraftDocument? document, IReadOnlyDictionary<Guid, Field> fields, string uiLanguage)
    {
        // A never-published draft shows its working copy; a published article what readers see.
        var source = document?.Translations.FirstOrDefault(t => t.Language == document.SourceLanguage);
        var fieldId = document is null ? row.FieldId : document.FieldId;
        var field = fieldId is { } id && fields.TryGetValue(id, out var f)
            ? new FieldRefDto(f.Id, f.Slug, uiLanguage == UiLanguages.English ? f.NameEn : f.NameAr, f.NameAr, f.NameEn)
            : null;

        return new MyArticleDto(
            row.Id,
            row.PublishedAt is null ? "draft" : "published",
            row.PublishedAt is null ? null : row.Slug,
            document?.SourceLanguage ?? row.SourceLanguage,
            source?.Title ?? row.Title ?? string.Empty,
            storage.ToPublicUrl(document is null ? row.CoverUrl : document.CoverUrl),
            field,
            source is null ? row.ReadingTimeMinutes ?? 0 : ReadingTime(source),
            row.SavedAt,
            row.PublishedAt,
            row.PublishedAt is not null && row.HasChanges,
            row.ReactionCount,
            row.CommentCount,
            row.ReadCount);
    }

    private int ReadingTime(DraftTranslation translation)
    {
        var processed = rdoc.Process(translation.Content, translation.Language, translation.Title);
        return processed.IsSuccess ? processed.Value.Content.ReadingTimeMinutes : 0;
    }

    private sealed record Row(
        Guid Id,
        string Slug,
        string SourceLanguage,
        DateTime SortKey,
        DateTime SavedAt,
        DateTime? PublishedAt,
        bool HasChanges,
        string? DocumentJson,
        string? Title,
        int? ReadingTimeMinutes,
        string? CoverUrl,
        Guid FieldId,
        int ReactionCount,
        int CommentCount,
        int ReadCount);
}

internal sealed class GetArticleRevisionsQueryHandler(IAppDbContext db, ICurrentUser currentUser)
    : IQueryHandler<GetArticleRevisionsQuery, Result<IReadOnlyList<ArticleRevisionDto>>>
{
    public async ValueTask<Result<IReadOnlyList<ArticleRevisionDto>>> Handle(GetArticleRevisionsQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        if (!await db.Articles.AnyAsync(a => a.Id == query.ArticleId && a.AuthorId == userId, cancellationToken)) return ArticleErrors.NotFound;

        var revisions = await db.ArticleRevisions.AsNoTracking()
            .Where(r => r.ArticleId == query.ArticleId)
            .OrderByDescending(r => r.RevisionNumber)
            .Select(r => new { r.RevisionNumber, r.CreatedAt, r.Title, r.Languages })
            .ToListAsync(cancellationToken);

        return revisions.Select(r => new ArticleRevisionDto(r.RevisionNumber, r.CreatedAt, r.Title, r.Languages.Split(','))).ToList();
    }
}

internal sealed class GetArticleRevisionQueryHandler(IAppDbContext db, ICurrentUser currentUser, ArticleDrafts drafts)
    : IQueryHandler<GetArticleRevisionQuery, Result<ArticleRevisionDetailsDto>>
{
    public async ValueTask<Result<ArticleRevisionDetailsDto>> Handle(GetArticleRevisionQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        if (!await db.Articles.AnyAsync(a => a.Id == query.ArticleId && a.AuthorId == userId, cancellationToken)) return ArticleErrors.NotFound;

        var revision = await db.ArticleRevisions.AsNoTracking()
            .FirstOrDefaultAsync(r => r.ArticleId == query.ArticleId && r.RevisionNumber == query.Number, cancellationToken);
        if (revision is null) return ArticleErrors.RevisionNotFound;

        var document = ArticleDraftJson.Deserialize(revision.DocumentJson);
        return new ArticleRevisionDetailsDto(
            revision.RevisionNumber, revision.CreatedAt, revision.Title, revision.Languages.Split(','),
            drafts.ToPublic(document), await drafts.MediaAsync(userId, document.Attachments, cancellationToken));
    }
}

internal sealed class SearchTagsQueryHandler(IAppDbContext db) : IQueryHandler<SearchTagsQuery, Result<IReadOnlyList<TagDto>>>
{
    private const int MaxLimit = 20;

    public async ValueTask<Result<IReadOnlyList<TagDto>>> Handle(SearchTagsQuery query, CancellationToken cancellationToken)
    {
        var text = (query.Query ?? string.Empty).Trim();
        var slug = Tag.ToSlug(text);
        var tags = db.Tags.AsNoTracking();
        if (text.Length > 0) tags = tags.Where(t => t.Name.StartsWith(text) || (slug.Length > 0 && t.Slug.StartsWith(slug)));

        // Hidden articles (F22) count for nothing, like everywhere readers look.
        var published = db.Articles.Visible();
        var found = await tags
            .Select(t => new { t.Slug, t.Name, Count = published.Count(a => a.Tags.Any(x => x.TagId == t.Id)) })
            .OrderByDescending(t => t.Count).ThenBy(t => t.Name)
            .Take(Math.Clamp(query.Limit, 1, MaxLimit))
            .ToListAsync(cancellationToken);

        return found.Select(t => new TagDto(t.Slug, t.Name, t.Count)).ToList();
    }
}
