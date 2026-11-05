using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Mutes;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Articles;

/// <summary>
/// What the signed-in viewer did with an article: their reaction, their save, whether they follow the author, and whether
/// they muted its author, field or topic (F28).
/// </summary>
public sealed record ArticleViewerState(
    ReactionType? MyReaction, bool IsSaved, bool IsFollowingAuthor, bool IsAuthorMuted = false, bool IsFieldMuted = false, bool IsTopicMuted = false);

/// <summary>
/// Loads <see cref="ArticleViewerState"/> for a page of articles in one query: the page's articles LEFT JOIN the viewer's
/// reactions, saves and follows (each at most one row per article, by the unique indexes). Guests skip it entirely. Your
/// own articles and a deleted author's are never "following" or "muted"; the mutes are EXISTS lookups on their unique indexes.
/// </summary>
public sealed class ArticleViewerStateReader(IAppDbContext db)
{
    private static readonly IReadOnlyDictionary<Guid, ArticleViewerState> None = new Dictionary<Guid, ArticleViewerState>();

    public async Task<IReadOnlyDictionary<Guid, ArticleViewerState>> LoadAsync(
        Guid? viewerId, IReadOnlyCollection<Guid> articleIds, CancellationToken cancellationToken)
    {
        if (viewerId is not { } viewer || articleIds.Count == 0) return None;

        var mutedUsers = db.MutedUserIds(viewer);
        var mutedFields = db.MutedIds(viewer, ContentMuteTarget.Field);
        var mutedTopics = db.MutedIds(viewer, ContentMuteTarget.Topic);

        var rows = await (
                from article in db.Articles.AsNoTracking()
                where articleIds.Contains(article.Id)
                join reaction in db.Reactions.Where(r => r.UserId == viewer) on article.Id equals reaction.ArticleId into reactions
                from reaction in reactions.DefaultIfEmpty()
                join saved in db.SavedArticles.Where(s => s.UserId == viewer) on article.Id equals saved.ArticleId into saves
                from saved in saves.DefaultIfEmpty()
                join follow in db.UserFollows.Where(f => f.FollowerId == viewer) on article.AuthorId equals (Guid?)follow.FolloweeId into follows
                from follow in follows.DefaultIfEmpty()
                select new
                {
                    article.Id,
                    MyReaction = reaction != null ? reaction.Type : (ReactionType?)null,
                    IsSaved = saved != null,
                    IsFollowingAuthor = follow != null && article.AuthorId != viewer,
                    IsAuthorMuted = article.AuthorId != viewer && mutedUsers.Any(id => id == article.AuthorId),
                    IsFieldMuted = mutedFields.Contains(article.FieldId),
                    IsTopicMuted = mutedTopics.Any(id => id == article.TopicId),
                })
            .ToListAsync(cancellationToken);

        return rows.ToDictionary(r => r.Id, r => new ArticleViewerState(
            r.MyReaction, r.IsSaved, r.IsFollowingAuthor, r.IsAuthorMuted, r.IsFieldMuted, r.IsTopicMuted));
    }
}

internal static class ArticleViewerStateExtensions
{
    public static TCard WithViewerState<TCard>(this TCard card, IReadOnlyDictionary<Guid, ArticleViewerState> states)
        where TCard : ArticleCardDto =>
        states.TryGetValue(card.Id, out var state)
            ? (TCard)((ArticleCardDto)card with
            {
                MyReaction = state.MyReaction,
                IsSaved = state.IsSaved,
                IsFollowingAuthor = state.IsFollowingAuthor,
                IsAuthorMuted = state.IsAuthorMuted,
                IsFieldMuted = state.IsFieldMuted,
                IsTopicMuted = state.IsTopicMuted,
            })
            : card;
}
