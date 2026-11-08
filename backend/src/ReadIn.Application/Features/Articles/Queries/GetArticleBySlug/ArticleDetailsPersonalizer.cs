using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;

/// <summary>
/// The cached details are the same for every reader; this adds the signed-in viewer's reading progress (F04 resume),
/// reaction, save, author follow and the collections that hold the article on top, in three queries. Guests keep the
/// defaults (null, null, false, false, []).
/// </summary>
internal sealed class ArticleDetailsPersonalizer(
    IAppDbContext db, ICurrentUser viewer, ArticleViewerStateReader viewerState, BlockRelations blocks)
    : IQueryPersonalizer<GetArticleBySlugQuery, Result<ArticleDetailsDto>>
{
    public async ValueTask<Result<ArticleDetailsDto>> PersonalizeAsync(
        GetArticleBySlugQuery message, Result<ArticleDetailsDto> response, CancellationToken cancellationToken)
    {
        if (response.IsFailure || viewer.UserId is not { } viewerId) return response;

        // F36: the cached details are the same for everyone; a block decides here, per caller: the blocker gets
        // 403 block.blocked (with an Unblock), the blocked person a plain not-found, as if the article were deleted.
        if (await blocks.DirectLinkErrorAsync(viewer, response.Value.Author?.Id, ArticleErrors.NotFound, cancellationToken) is { } blocked)
            return blocked;

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

        // F36: mentions of people the viewer is blocked with stay as plain text.
        var mentioned = RDocMentions.UserIds(details.Content);
        List<Guid> unlinked = [];
        if (mentioned.Count > 0)
        {
            var blockedWith = db.BlockedWith(viewerId);
            unlinked = await db.Users.AsNoTracking().Where(u => mentioned.Contains(u.Id) && blockedWith.Contains(u.Id)).Select(u => u.Id)
                .ToListAsync(cancellationToken);
        }

        // The viewer state never has your own articles as "Following".
        return details.WithViewerState(states) with { CollectionIds = collectionIds, UnlinkedMentionIds = unlinked };
    }
}
