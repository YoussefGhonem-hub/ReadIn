using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>
/// A member reposted an article (SPEC F29): it shows on their profile's Reposts tab and in their followers' Following
/// feed, labeled "أعاد نشره {name}". One per user per article (unique (UserId, ArticleId)); never your own article.
/// </summary>
public sealed class Repost : AggregateRoot
{
    private Repost() { } // EF

    public Guid UserId { get; private set; }
    public Guid ArticleId { get; private set; }

    /// <summary>When it was reposted: where it places the article in the Following feed and on the Reposts tab.</summary>
    public DateTime CreatedAt { get; private set; }

    // Read-side navigation for query projections only.
    public Users.User User { get; private set; } = default!;

    public static Repost Create(Guid userId, Guid articleId, DateTime now)
    {
        var repost = new Repost { UserId = userId, ArticleId = articleId, CreatedAt = now };
        repost.Raise(() => new RepostChangedDomainEvent(articleId, userId, IsReposted: true) { OccurredAt = now });
        return repost;
    }

    /// <summary>Call before deleting the row, so the article's repost count is recomputed after the commit.</summary>
    public void Remove() => Raise(() => new RepostChangedDomainEvent(ArticleId, UserId, IsReposted: false));
}

/// <summary>An article was reposted or the repost undone: its count follows (F27), and a new repost tells the author (F17).</summary>
public sealed record RepostChangedDomainEvent(Guid ArticleId, Guid UserId, bool IsReposted) : DomainEvent;

public static class RepostErrors
{
    public static readonly Error OwnArticle = Error.Validation("repost.own_article", "You can't repost your own article.");
}
