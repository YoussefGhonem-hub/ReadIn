using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;

/// <summary>
/// The cached details are the same for every reader; this adds the signed-in viewer's reaction, save and author follow
/// on top, in one query. Guests keep the defaults (null, false, false).
/// </summary>
internal sealed class ArticleDetailsPersonalizer(ICurrentUser viewer, ArticleViewerStateReader viewerState)
    : IQueryPersonalizer<GetArticleBySlugQuery, Result<ArticleDetailsDto>>
{
    public async ValueTask<Result<ArticleDetailsDto>> PersonalizeAsync(
        GetArticleBySlugQuery message, Result<ArticleDetailsDto> response, CancellationToken cancellationToken)
    {
        if (response.IsFailure || viewer.UserId is not { } viewerId) return response;

        var details = response.Value;
        var states = await viewerState.LoadAsync(viewerId, [details.Id], cancellationToken);
        if (!states.TryGetValue(details.Id, out var state)) return response;

        return details.WithViewerState(states) with
        {
            // Your own articles never show "Following".
            IsFollowingAuthor = state.IsFollowingAuthor && details.Author.Id != viewerId,
        };
    }
}
