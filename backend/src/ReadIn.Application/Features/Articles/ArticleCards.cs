using Microsoft.Extensions.Options;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
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
    /// What readers can open: published, not deleted (query filter), in an enabled field, and not hidden by a moderator
    /// (SPEC F22). Everything else, drafts and archived articles included, is <c>article.not_found</c>. Every list, feed
    /// and count goes through this, so a hidden article drops out of all of them.
    /// </summary>
    public static IQueryable<Article> Visible(this IQueryable<Article> articles) =>
        articles.Published().Where(a => a.HiddenAt == null);

    /// <summary>
    /// The reader and what is done on one article (comments, reactions, saves, progress): <see cref="Visible"/>, plus a
    /// hidden article for its author and for moderators (SPEC F22). Everyone else gets <c>article.not_found</c>.
    /// </summary>
    public static IQueryable<Article> VisibleTo(this IQueryable<Article> articles, ICurrentUser viewer)
    {
        if (viewer.Permissions.Contains(Permissions.Moderation.Manage)) return articles.Published();
        if (viewer.UserId is not { } viewerId) return articles.Visible();
        return articles.Published().Where(a => a.HiddenAt == null || a.AuthorId == viewerId);
    }

    /// <summary>The author and moderators still open a hidden article (SPEC F22).</summary>
    /// <summary>A deleted writer's kept article has no author (SPEC F01): then only moderators.</summary>
    public static bool CanSeeHidden(Guid? authorId, ICurrentUser viewer) =>
        (authorId is { } author && viewer.UserId == author) || viewer.Permissions.Contains(Permissions.Moderation.Manage);

    /// <summary>Published in an enabled field, hidden ones included: only for caller-independent results that filter later.</summary>
    public static IQueryable<Article> Published(this IQueryable<Article> articles) =>
        articles.Where(a => a.Status == ArticleStatus.Published && a.Field.IsEnabled);
}
