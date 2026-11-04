using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;

/// <summary>
/// The cached details are the same for every reader; this adds the signed-in viewer's reading progress (F04 resume),
/// reaction, save, author follow and the collections that hold the article on top, in three queries. Guests keep the
/// defaults (null, null, false, false, []).
/// </summary>
internal sealed class ArticleDetailsPersonalizer(IAppDbContext db, ICurrentUser viewer, ArticleViewerStateReader viewerState)
    : IQueryPersonalizer<GetArticleBySlugQuery, Result<ArticleDetailsDto>>
{
    public async ValueTask<Result<ArticleDetailsDto>> PersonalizeAsync(
        GetArticleBySlugQuery message, Result<ArticleDetailsDto> response, CancellationToken cancellationToken)
    {
        if (response.IsFailure || viewer.UserId is not { } viewerId) return response;

        var details = response.Value with
        {
            MyProgress = await db.ReadingProgress.AsNoTracking()
                .Where(p => p.UserId == viewerId && p.ArticleId == response.Value.Id)
                .Select(p => new MyProgressDto(p.Language, p.Percent, p.LastPosition, p.CompletedAt))
                .FirstOrDefaultAsync(cancellationToken),
        };
        var states = await viewerState.LoadAsync(viewerId, [details.Id], cancellationToken);
        if (!states.TryGetValue(details.Id, out var state)) return details;

        // Unsaving removes an article from every collection, so an unsaved article has none.
        var collectionIds = state.IsSaved
            ? await db.CollectionItems.AsNoTracking()
                .Where(i => i.ArticleId == details.Id && db.Collections.Any(c => c.Id == i.CollectionId && c.UserId == viewerId))
                .OrderBy(i => i.AddedAt)
                .Select(i => i.CollectionId)
                .ToListAsync(cancellationToken)
            : [];

        // The viewer state never has your own articles as "Following".
        return details.WithViewerState(states) with { CollectionIds = collectionIds };
    }
}
