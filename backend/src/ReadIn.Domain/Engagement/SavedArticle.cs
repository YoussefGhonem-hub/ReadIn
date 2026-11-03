using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>A bookmark (SPEC F13). One per user per article; collections group saved articles.</summary>
public sealed class SavedArticle : AggregateRoot
{
    private SavedArticle() { } // EF

    public Guid UserId { get; private set; }
    public Guid ArticleId { get; private set; }
    public DateTime SavedAt { get; private set; }

    // Read-side navigation for query projections only.
    public Articles.Article Article { get; private set; } = default!;

    public static SavedArticle Create(Guid userId, Guid articleId, DateTime now)
    {
        var saved = new SavedArticle { UserId = userId, ArticleId = articleId, SavedAt = now };
        saved.Raise(() => new ArticleSaveChangedDomainEvent(articleId, userId, IsSaved: true));
        return saved;
    }

    /// <summary>Call before deleting the row, so the article's save count is recomputed after the commit.</summary>
    public void Remove() => Raise(() => new ArticleSaveChangedDomainEvent(ArticleId, UserId, IsSaved: false));
}

/// <summary>An article was saved or unsaved; its save count follows (F27).</summary>
public sealed record ArticleSaveChangedDomainEvent(Guid ArticleId, Guid UserId, bool IsSaved) : DomainEvent;
