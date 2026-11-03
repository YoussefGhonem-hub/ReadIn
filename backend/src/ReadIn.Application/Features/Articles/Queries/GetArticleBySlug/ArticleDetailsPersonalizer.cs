using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;

/// <summary>
/// The cached details are the same for every reader; this adds the signed-in viewer's reaction, save, author follow
/// and the collections that hold the article on top, in two queries. Guests keep the defaults (null, false, false, []).
/// </summary>
internal sealed class ArticleDetailsPersonalizer(IAppDbContext db, ICurrentUser viewer, ArticleViewerStateReader viewerState)
    : IQueryPersonalizer<GetArticleBySlugQuery, Result<ArticleDetailsDto>>
{
    public async ValueTask<Result<ArticleDetailsDto>> PersonalizeAsync(
        GetArticleBySlugQuery message, Result<ArticleDetailsDto> response, CancellationToken cancellationToken)
    {
        if (response.IsFailure || viewer.UserId is not { } viewerId) return response;

        var details = response.Value;
        var states = await viewerState.LoadAsync(viewerId, [details.Id], cancellationToken);
        if (!states.TryGetValue(details.Id, out var state)) return response;

        // Unsaving removes an article from every collection, so an unsaved article has none.
        var collectionIds = state.IsSaved
            ? await db.CollectionItems.AsNoTracking()
                .Where(i => i.ArticleId == details.Id && db.Collections.Any(c => c.Id == i.CollectionId && c.UserId == viewerId))
                .OrderBy(i => i.AddedAt)
                .Select(i => i.CollectionId)
                .ToListAsync(cancellationToken)
            : [];

        return details.WithViewerState(states) with
        {
            // Your own articles never show "Following".
            IsFollowingAuthor = state.IsFollowingAuthor && details.Author is { } author && author.Id != viewerId,
            CollectionIds = collectionIds,
        };
    }
}
