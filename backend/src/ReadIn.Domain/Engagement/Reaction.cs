using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>The four reactions of SPEC F10: 💡 مفيد, ❤️, 🔥, 🤯.</summary>
public enum ReactionType
{
    Insightful = 0,
    Love = 1,
    Fire = 2,
    MindBlown = 3,
}

public static class ReactionTypes
{
    public static readonly IReadOnlyList<ReactionType> All = [ReactionType.Insightful, ReactionType.Love, ReactionType.Fire, ReactionType.MindBlown];

    /// <summary>The API names (<c>insightful</c>, <c>love</c>, <c>fire</c>, <c>mindBlown</c>), ignoring case. Numbers are refused.</summary>
    public static bool TryParse(string? value, out ReactionType type)
    {
        type = default;
        if (string.IsNullOrWhiteSpace(value)) return false;

        foreach (var candidate in All)
        {
            if (!string.Equals(candidate.ToString(), value.Trim(), StringComparison.OrdinalIgnoreCase)) continue;
            type = candidate;
            return true;
        }
        return false;
    }
}

/// <summary>
/// A user's reaction to an article (SPEC F10). One per user per article: reacting again changes the same row, which the
/// unique (UserId, ArticleId) index also enforces.
/// </summary>
public sealed class Reaction : AggregateRoot
{
    private Reaction() { } // EF

    public Guid UserId { get; private set; }
    public Guid ArticleId { get; private set; }
    public ReactionType Type { get; private set; }

    /// <summary>When the current reaction was chosen; changing it moves it to the top of "who reacted".</summary>
    public DateTime ReactedAt { get; private set; }

    // Read-side navigation for query projections only.
    public Users.User User { get; private set; } = default!;

    /// <summary>
    /// Sets the user's reaction: changes <paramref name="existing"/> (their current one) or creates the first. Choosing the
    /// reaction they already have changes nothing and raises no event.
    /// </summary>
    public static Reaction Set(Reaction? existing, Guid userId, Guid articleId, ReactionType type, DateTime now)
    {
        if (!Enum.IsDefined(type)) throw new ArgumentOutOfRangeException(nameof(type), type, null);

        if (existing is not null)
        {
            if (existing.UserId != userId || existing.ArticleId != articleId)
                throw new ArgumentException("The existing reaction belongs to another user or article.", nameof(existing));
            existing.ChangeTo(type, now);
            return existing;
        }

        var reaction = new Reaction { UserId = userId, ArticleId = articleId, Type = type, ReactedAt = now };
        reaction.Raise(() => new ReactionChangedDomainEvent(articleId, userId, type));
        return reaction;
    }

    /// <summary>Call before deleting the row, so the article's counters are recomputed after the commit.</summary>
    public void Remove() => Raise(() => new ReactionChangedDomainEvent(ArticleId, UserId, null));

    private void ChangeTo(ReactionType type, DateTime now)
    {
        if (Type == type) return;

        Type = type;
        ReactedAt = now;
        Raise(() => new ReactionChangedDomainEvent(ArticleId, UserId, type));
    }
}

/// <summary>A reaction was set, changed or (with a null <see cref="Type"/>) removed; the article's counters follow (F27).</summary>
public sealed record ReactionChangedDomainEvent(Guid ArticleId, Guid UserId, ReactionType? Type) : DomainEvent;
