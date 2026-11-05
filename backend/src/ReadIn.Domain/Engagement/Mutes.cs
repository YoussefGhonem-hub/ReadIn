using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>What a content mute hides (SPEC F28, <c>ContentMutes.TargetType</c>): a whole field or one topic.</summary>
public enum ContentMuteTarget
{
    Field,
    Topic,
}

/// <summary>What a reader said about one article (SPEC F28, <c>ArticleFeedback.Type</c>).</summary>
public enum ArticleFeedbackType
{
    /// <summary>"قلّل من النوع ده": the article leaves the reader's feeds; its topic (or field) goes lower in For you.</summary>
    ShowLess,
}

/// <summary>
/// A reader muted a writer (SPEC F28): the writer's articles leave the reader's lists, their comments collapse and their
/// activity sends no notification. Private: the writer isn't told. One row per pair.
/// </summary>
public sealed class UserMute : Entity
{
    private UserMute() { } // EF

    public Guid MuterId { get; private set; }
    public Guid MutedUserId { get; private set; }
    public DateTime CreatedAt { get; private set; }

    // Read-side navigation for query projections only.
    public Users.User MutedUser { get; private set; } = default!;

    public static Result<UserMute> Create(Guid muterId, Guid mutedUserId, DateTime now)
    {
        if (muterId == mutedUserId) return MuteErrors.Self;
        return new UserMute { MuterId = muterId, MutedUserId = mutedUserId, CreatedAt = now };
    }
}

/// <summary>A reader muted a field or a topic (SPEC F28). <see cref="TargetId"/> has no foreign key: it names either table.</summary>
public sealed class ContentMute : Entity
{
    private ContentMute() { } // EF

    public ContentMute(Guid userId, ContentMuteTarget targetType, Guid targetId, DateTime now)
    {
        UserId = userId;
        TargetType = targetType;
        TargetId = targetId;
        CreatedAt = now;
    }

    public Guid UserId { get; private set; }
    public ContentMuteTarget TargetType { get; private set; }
    public Guid TargetId { get; private set; }
    public DateTime CreatedAt { get; private set; }
}

/// <summary>
/// A reader's "show less" on one article (SPEC F28). The article stays out of their feeds until it is undone; its topic, or
/// its field when it has no topic, is lowered in For you for <see cref="LoweredFor"/> from <see cref="CreatedAt"/>.
/// </summary>
public sealed class ArticleFeedback : Entity
{
    /// <summary>How long a "show less" keeps its topic (or field) at the bottom of For you.</summary>
    public static readonly TimeSpan LoweredFor = TimeSpan.FromDays(90);

    private ArticleFeedback() { } // EF

    public ArticleFeedback(Guid userId, Guid articleId, ArticleFeedbackType type, DateTime now)
    {
        UserId = userId;
        ArticleId = articleId;
        Type = type;
        CreatedAt = now;
    }

    public Guid UserId { get; private set; }
    public Guid ArticleId { get; private set; }
    public ArticleFeedbackType Type { get; private set; }
    public DateTime CreatedAt { get; private set; }
}

/// <summary>Mute and "show less" (SPEC F28).</summary>
public static class MuteErrors
{
    /// <summary>At most this many muted writers per user (<c>mute.limit</c>); fields and topics are bounded by the taxonomy.</summary>
    public const int MaxMutedUsers = 500;

    public static readonly Error Self = Error.Validation("mute.self", "You can't mute yourself.");

    /// <summary>The official ReadIn account (a system account) can't be muted.</summary>
    public static readonly Error SystemAccount = Error.Validation("mute.system_account", "The official ReadIn account can't be muted.");

    public static readonly Error Limit = Error.Validation("mute.limit", "You can mute at most 500 writers.");

    /// <summary>"Show less" on your own article.</summary>
    public static readonly Error OwnArticle = Error.Validation("mute.own_article", "You can't do this on your own article.");
}
