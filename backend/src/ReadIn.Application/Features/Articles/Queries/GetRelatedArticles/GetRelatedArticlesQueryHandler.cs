using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetRelatedArticles;

/// <summary>
/// Ranks by what an article shares with the open one: the same topic, then the same field, then tags and glossary terms
/// in common (each capped, so they only order articles within a topic or field). Ties go to the quality score, then the
/// newest. The open article's neighbours in a learning path are left out: the "Next in path" block shows them (F09).
/// </summary>
internal sealed class GetRelatedArticlesQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    ArticleCards cards,
    BlockRelations blocks)
    : IQueryHandler<GetRelatedArticlesQuery, Result<IReadOnlyList<ArticleCardDto>>>
{
    private const int TopicWeight = 100;
    private const int FieldWeight = 20;
    private const int TagWeight = 3;
    private const int MaxTags = 3;
    private const int TermWeight = 2;
    private const int MaxTerms = 4;

    public async ValueTask<Result<IReadOnlyList<ArticleCardDto>>> Handle(GetRelatedArticlesQuery query, CancellationToken cancellationToken)
    {
        // F36: the blocker gets 403 block.blocked, the blocked person the same not-found as a deleted article.
        if (await blocks.ArticleErrorAsync(currentUser, query.ArticleId, cancellationToken) is { } blocked) return blocked;
        var limit = Math.Clamp(query.Limit, 1, GetRelatedArticlesQuery.MaxLimit);

        var source = await db.Articles.AsNoTracking()
            .Visible()
            .Where(a => a.Id == query.ArticleId)
            // A hidden tag (F32) is not shown, so it relates nothing either.
            .Select(a => new { a.Id, a.FieldId, a.TopicId, TagIds = a.Tags.Where(t => !t.Tag.IsHidden).Select(t => t.TagId).ToList() })
            .FirstOrDefaultAsync(cancellationToken);
        if (source is null) return ArticleErrors.NotFound;

        var termIds = await db.ArticleTerms.AsNoTracking()
            .Where(t => t.ArticleId == source.Id)
            .Select(t => t.TermId)
            .ToListAsync(cancellationToken);

        List<Guid> excluded = [source.Id, .. await PathNeighboursAsync(source.Id, cancellationToken)];
        var viewerId = currentUser.UserId;

        var candidates = db.Articles.AsNoTracking()
            .Visible()
            .Where(a => a.PublishedAt != null && !excluded.Contains(a.Id))
            .Where(a => a.FieldId == source.FieldId
                || (source.TopicId != null && a.TopicId == source.TopicId)
                || a.Tags.Any(t => source.TagIds.Contains(t.TagId))
                || db.ArticleTerms.Any(t => t.ArticleId == a.Id && termIds.Contains(t.TermId)));
        if (viewerId is not null)
        {
            // Not your own, nor what you muted or marked "show less" (F28).
            candidates = candidates.Where(a => a.AuthorId != viewerId).WithoutMutedFor(db, viewerId).WithoutShownLessFor(db, viewerId);
        }

        var ids = await candidates
            .Select(a => new
            {
                a.Id,
                a.QualityScore,
                a.PublishedAt,
                Tags = a.Tags.Count(t => source.TagIds.Contains(t.TagId)),
                Terms = db.ArticleTerms.Count(t => t.ArticleId == a.Id && termIds.Contains(t.TermId)),
                Topic = source.TopicId != null && a.TopicId == source.TopicId,
                Field = a.FieldId == source.FieldId,
                Read = viewerId != null && db.ReadingProgress.Any(p => p.UserId == viewerId && p.ArticleId == a.Id && p.CompletedAt != null),
            })
            .Select(a => new
            {
                a.Id,
                a.QualityScore,
                a.PublishedAt,
                a.Read,
                Score = (a.Topic ? TopicWeight : 0)
                    + (a.Field ? FieldWeight : 0)
                    + (a.Tags > MaxTags ? MaxTags : a.Tags) * TagWeight
                    + (a.Terms > MaxTerms ? MaxTerms : a.Terms) * TermWeight,
            })
            .OrderBy(a => a.Read)
            .ThenByDescending(a => a.Score)
            .ThenByDescending(a => a.QualityScore)
            .ThenByDescending(a => a.PublishedAt)
            .ThenByDescending(a => a.Id)
            .Take(limit)
            .Select(a => a.Id)
            .ToListAsync(cancellationToken);

        if (ids.Count == 0) return Array.Empty<ArticleCardDto>();

        using var _ = LocalizedProjection.Begin(query.UiLanguage, query.Language);

        var projected = await db.Articles.AsNoTracking()
            .Where(a => ids.Contains(a.Id))
            .ProjectToType<ArticleCardDto>(mapping)
            .ToListAsync(cancellationToken);

        var ranked = projected.OrderBy(c => ids.IndexOf(c.Id)).ToList();
        return await cards.CompleteAsync(ranked, cancellationToken);
    }

    /// <summary>The articles just before and after this one in each published learning path that holds it.</summary>
    private async Task<IReadOnlyList<Guid>> PathNeighboursAsync(Guid articleId, CancellationToken cancellationToken)
    {
        var visible = db.Articles.Visible();
        var items = await db.LearningPaths.AsNoTracking()
            .Where(p => p.IsPublished && p.Items.Any(i => i.ArticleId == articleId))
            .SelectMany(p => p.Items)
            .Where(i => visible.Any(a => a.Id == i.ArticleId))
            .Select(i => new { i.PathId, i.ArticleId, i.Order })
            .ToListAsync(cancellationToken);

        var neighbours = new List<Guid>();
        foreach (var path in items.GroupBy(i => i.PathId))
        {
            var ordered = path.OrderBy(i => i.Order).ToList();
            var at = ordered.FindIndex(i => i.ArticleId == articleId);
            if (at > 0) neighbours.Add(ordered[at - 1].ArticleId);
            if (at >= 0 && at < ordered.Count - 1) neighbours.Add(ordered[at + 1].ArticleId);
        }
        return neighbours;
    }
}
