using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Uploads;
using ReadIn.Domain.Articles;

namespace ReadIn.Application.Features.Articles;

/// <summary>
/// Finishes article cards after the SQL projection, the same way wherever cards are produced (for you, today, following,
/// saved): absolute URLs, attachments (feed cards carry the first PDF pages only) and the signed-in viewer's own
/// reaction and save. A fixed number of queries per page, never one per card.
/// </summary>
public sealed class ArticleCards(
    IFileStorage storage,
    ArticleAttachmentsReader attachments,
    ArticleViewerStateReader viewerState,
    IOptions<MediaOptions> mediaOptions,
    ICurrentUser currentUser)
{
    public async Task<List<ArticleCardDto>> CompleteAsync(IReadOnlyList<ArticleCardDto> cards, CancellationToken cancellationToken)
    {
        if (cards.Count == 0) return [];

        var ids = cards.Select(c => c.Id).ToList();
        var attachmentsById = await attachments.LoadAsync(ids, mediaOptions.Value.FeedDocumentPages, currentUser, cancellationToken);
        var states = await viewerState.LoadAsync(currentUser.UserId, ids, cancellationToken);
        return cards.Select(card => card.WithPublicUrls(storage).WithViewerState(states)).WithAttachments(attachmentsById);
    }
}

internal static class ArticleVisibility
{
    /// <summary>
    /// What readers can open: published, not deleted (query filter), in an enabled field. Everything else, drafts and
    /// archived articles included, is <c>article.not_found</c> for reactions, saves and collections.
    /// </summary>
    public static IQueryable<Article> Visible(this IQueryable<Article> articles) =>
        articles.Where(a => a.Status == ArticleStatus.Published && a.Field.IsEnabled);
}
