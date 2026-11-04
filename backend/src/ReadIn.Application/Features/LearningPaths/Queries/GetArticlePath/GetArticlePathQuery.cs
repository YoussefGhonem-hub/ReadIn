using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.LearningPaths.Queries.GetArticlePath;

/// <summary>
/// GET /articles/{id}/path — the "Next in path" block at the end of the reader (SPEC F04, F09). Null (→ 204) when the
/// article is in no published path. In several paths: the one the viewer is enrolled in with the latest activity, else
/// the first in editorial order. Guests are allowed.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record GetArticlePathQuery(Guid ArticleId, string UiLanguage) : IQuery<Result<ArticlePathDto?>>;

internal sealed class GetArticlePathQueryHandler(IAppDbContext db, ICurrentUser currentUser, PathCards cards)
    : IQueryHandler<GetArticlePathQuery, Result<ArticlePathDto?>>
{
    public async ValueTask<Result<ArticlePathDto?>> Handle(GetArticlePathQuery query, CancellationToken ct)
    {
        if (!await db.Articles.AsNoTracking().Visible().AnyAsync(a => a.Id == query.ArticleId, ct)) return ArticleErrors.NotFound;

        var candidates = await cards.Listed()
            .Where(p => p.Items.Any(i => i.ArticleId == query.ArticleId))
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.Slug)
            .Select(p => p.Id)
            .ToListAsync(ct);
        if (candidates.Count == 0) return Result.Success<ArticlePathDto?>(null);

        var viewer = currentUser.UserId;
        if (viewer is { } userId)
        {
            var enrolled = await db.PathEnrollments.AsNoTracking()
                .Where(e => e.UserId == userId && candidates.Contains(e.PathId))
                .OrderByDescending(e => e.LastActivityAt)
                .Select(e => e.PathId)
                .ToListAsync(ct);
            // Enrolled paths first (latest activity first), then the rest in editorial order.
            candidates = [.. enrolled, .. candidates.Except(enrolled)];
        }

        var language = await cards.ArticleLanguageOfAsync(viewer, ct);
        var data = await cards.LoadAsync(candidates, viewer, query.UiLanguage, language, ct);
        var path = data.FirstOrDefault(p => p.Items.Any(i => i.Article.Id == query.ArticleId));
        if (path is null) return Result.Success<ArticlePathDto?>(null);

        var index = path.Items.ToList().FindIndex(i => i.Article.Id == query.ArticleId);
        var previous = index > 0 ? path.Items[index - 1].Article : null;
        ArticleCardDto? next = null;
        if (index + 1 < path.Items.Count)
        {
            next = (await cards.ArticleCardsAsync([path.Items[index + 1].Article.Id], query.UiLanguage, language, ct))
                .FirstOrDefault();
        }

        return Result.Success<ArticlePathDto?>(new ArticlePathDto(path.Card, index + 1, path.Items.Count, previous, next));
    }
}
