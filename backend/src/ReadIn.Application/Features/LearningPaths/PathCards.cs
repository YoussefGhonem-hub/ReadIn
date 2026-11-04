using Mapster;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Learning;

namespace ReadIn.Application.Features.LearningPaths;

/// <summary>
/// Builds learning path cards (SPEC F09) the same way for every endpoint: only the articles a reader can open count,
/// positions are dense (1..N) in path order, and progress is one user's completed reads (F04). A fixed number of
/// queries per call, never one per path.
/// </summary>
public sealed class PathCards(IAppDbContext db, IFileStorage storage, TypeAdapterConfig mapping, ArticleCards articleCards)
{
    /// <summary>Paths readers can see: published, in an enabled field. Callers still drop paths without visible articles.</summary>
    internal IQueryable<LearningPath> Listed() =>
        db.LearningPaths.AsNoTracking().Where(p => p.IsPublished && db.Fields.Any(f => f.Id == p.FieldId && f.IsEnabled));

    /// <summary>
    /// The cards of <paramref name="pathIds"/> in that order, leaving out the ones readers can't see or that have no
    /// visible article. <paramref name="progressUserId"/> is whose progress and enrollment to show (null: none).
    /// </summary>
    public async Task<List<PathCardDto>> BuildAsync(
        IReadOnlyList<Guid> pathIds, Guid? progressUserId, string uiLanguage, string? articleLanguage, CancellationToken ct) =>
        [.. (await LoadAsync(pathIds, progressUserId, uiLanguage, articleLanguage, ct)).Select(p => p.Card)];

    /// <summary>As <see cref="BuildAsync"/>, keeping each path's visible items and the user's reads for the detail views.</summary>
    internal async Task<List<PathData>> LoadAsync(
        IReadOnlyList<Guid> pathIds, Guid? progressUserId, string uiLanguage, string? articleLanguage, CancellationToken ct)
    {
        if (pathIds.Count == 0) return [];
        var ids = pathIds.Distinct().ToList();
        var english = UiLanguages.Normalize(uiLanguage) == "en";
        var lang = ArticleLanguages.IsValid(articleLanguage) ? articleLanguage! : string.Empty;

        var paths = await Listed()
            .Where(p => ids.Contains(p.Id))
            .Select(p => new
            {
                p.Id,
                p.Slug,
                Title = english ? p.TitleEn : p.TitleAr,
                Description = english ? p.DescriptionEn : p.DescriptionAr,
                p.FieldId,
            })
            .ToListAsync(ct);
        if (paths.Count == 0) return [];

        var fieldIds = paths.Select(p => p.FieldId).Distinct().ToList();
        var fields = await db.Fields.AsNoTracking()
            .Where(f => fieldIds.Contains(f.Id))
            .Select(f => new FieldRefDto(f.Id, f.Slug, english ? f.NameEn : f.NameAr, f.NameAr, f.NameEn, f.IsSensitive))
            .ToDictionaryAsync(f => f.Id, ct);

        var items = await db.LearningPathItems.AsNoTracking()
            .Where(i => ids.Contains(i.PathId))
            .Join(db.Articles.AsNoTracking().Visible(), i => i.ArticleId, a => a.Id, (i, a) => new
            {
                i.PathId,
                i.Order,
                ArticleId = a.Id,
                a.Slug,
                a.CoverUrl,
                Language = a.Translations.Any(t => t.Language == lang) ? lang : a.SourceLanguage,
                Title = a.Translations.Where(t => t.Language == lang).Select(t => t.Title).FirstOrDefault()
                    ?? a.Translations.Where(t => t.IsSource).Select(t => t.Title).FirstOrDefault(),
                Minutes = a.Translations.Any(t => t.Language == lang)
                    ? a.Translations.Where(t => t.Language == lang).Select(t => t.ReadingTimeMinutes).FirstOrDefault()
                    : a.Translations.Where(t => t.IsSource).Select(t => t.ReadingTimeMinutes).FirstOrDefault(),
            })
            .ToListAsync(ct);

        HashSet<Guid> read = [];
        Dictionary<Guid, PathEnrollment> enrollments = [];
        if (progressUserId is { } userId)
        {
            var articleIds = items.Select(i => i.ArticleId).Distinct().ToList();
            read = [.. await db.ReadingProgress.AsNoTracking()
                .Where(r => r.UserId == userId && r.CompletedAt != null && articleIds.Contains(r.ArticleId))
                .Select(r => r.ArticleId)
                .ToListAsync(ct)];
            enrollments = await db.PathEnrollments.AsNoTracking()
                .Where(e => e.UserId == userId && ids.Contains(e.PathId))
                .ToDictionaryAsync(e => e.PathId, ct);
        }

        var itemsByPath = items.ToLookup(i => i.PathId);
        var byId = paths.ToDictionary(p => p.Id);
        var result = new List<PathData>(ids.Count);
        foreach (var id in ids)
        {
            if (!byId.TryGetValue(id, out var path)) continue;
            var ordered = itemsByPath[id]
                .OrderBy(i => i.Order)
                .ThenBy(i => i.ArticleId)
                .Select((i, index) => new PathItemRef(
                    new PathArticleRefDto(i.ArticleId, i.Slug, i.Title ?? i.Slug, i.Language, index + 1, i.Minutes),
                    i.CoverUrl,
                    read.Contains(i.ArticleId)))
                .ToList();
            if (ordered.Count == 0) continue;

            PathProgressDto? progress = null;
            PathEnrollmentDto? enrollment = null;
            if (progressUserId is not null)
            {
                var readCount = ordered.Count(i => i.IsRead);
                progress = new PathProgressDto(
                    readCount, ordered.Count, PathProgressDto.PercentOf(readCount, ordered.Count),
                    ordered.FirstOrDefault(i => !i.IsRead)?.Article);
                if (enrollments.TryGetValue(id, out var e)) enrollment = new PathEnrollmentDto(e.EnrolledAt, e.CompletedAt);
            }

            var card = new PathCardDto
            {
                Id = path.Id,
                Slug = path.Slug,
                Title = path.Title,
                Description = path.Description,
                Field = fields[path.FieldId],
                ArticleCount = ordered.Count,
                ReadingTimeMinutes = ordered.Sum(i => i.Article.ReadingTimeMinutes),
                CoverUrl = storage.ToPublicUrl(ordered.Select(i => i.CoverUrl).FirstOrDefault(c => c is not null)),
                Progress = progress,
                Enrollment = enrollment,
            };
            result.Add(new PathData(card, ordered, enrollments.GetValueOrDefault(id)));
        }
        return result;
    }

    /// <summary>Full article cards for <paramref name="articleIds"/>, in that order (viewer state, attachments, URLs).</summary>
    internal async Task<List<ArticleCardDto>> ArticleCardsAsync(
        IReadOnlyList<Guid> articleIds, string uiLanguage, string? articleLanguage, CancellationToken ct)
    {
        if (articleIds.Count == 0) return [];
        List<ArticleCardDto> projected;
        using (LocalizedProjection.Begin(uiLanguage, articleLanguage))
        {
            projected = await db.Articles.AsNoTracking()
                .Where(a => articleIds.Contains(a.Id))
                .ProjectToType<ArticleCardDto>(mapping)
                .ToListAsync(ct);
        }

        var completed = (await articleCards.CompleteAsync(projected, ct)).ToDictionary(c => c.Id);
        return [.. articleIds.Where(completed.ContainsKey).Select(id => completed[id])];
    }

    /// <summary>
    /// The article version cards show: the signed-in viewer's preference; for guests the one matching the UI (ar → ar-EG,
    /// en → en), as the other feeds do (SPEC §17.1). The source language stays the fallback where a version is missing.
    /// </summary>
    internal async Task<string?> ArticleLanguageOfAsync(Guid? userId, string uiLanguage, CancellationToken ct) =>
        userId is { } id
            ? await db.Users.AsNoTracking().Where(u => u.Id == id).Select(u => u.ArticleLanguagePref).FirstOrDefaultAsync(ct)
            : ArticleLanguages.ForUi(uiLanguage);
}

/// <param name="CoverUrl">Stored (relative) cover of the article.</param>
internal sealed record PathItemRef(PathArticleRefDto Article, string? CoverUrl, bool IsRead);

/// <param name="Items">Visible items in path order, positions 1..N.</param>
/// <param name="Enrollment">The progress user's enrollment, untracked.</param>
internal sealed record PathData(PathCardDto Card, IReadOnlyList<PathItemRef> Items, PathEnrollment? Enrollment);
