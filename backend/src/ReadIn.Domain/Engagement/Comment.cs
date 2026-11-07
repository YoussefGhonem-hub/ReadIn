using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>
/// A comment on an article, or a reply to one (SPEC F11). Threads are one level deep: a reply always belongs to a
/// top-level comment (<see cref="ParentId"/>), and replying to a reply joins the same thread. Deleting is soft, so a
/// comment with replies stays as a placeholder. A comment whose author deleted their account keeps its text and shows
/// as "Deleted user" (<see cref="AuthorId"/> null), as the public account-deletion page promises.
/// </summary>
public sealed class Comment : AggregateRoot, IAuditable, ISoftDeletable, IHasRowVersion
{
    public const int MaxBodyLength = 2000;
    public const int MaxMentions = 10;

    private readonly List<CommentMention> _mentions = [];

    private Comment() { } // EF

    public Guid ArticleId { get; private set; }

    /// <summary>The top-level comment of the thread; null for top-level comments.</summary>
    public Guid? ParentId { get; private set; }

    /// <summary>Null once the author deleted their account.</summary>
    public Guid? AuthorId { get; private set; }

    public string Body { get; private set; } = default!;
    public bool IsPinned { get; private set; }
    public DateTime? PinnedAt { get; private set; }

    /// <summary>Recomputed from <see cref="CommentLike"/> rows after every like change.</summary>
    public int LikeCount { get; private set; }

    /// <summary>Visible replies of a top-level comment; recomputed after every reply change.</summary>
    public int ReplyCount { get; private set; }

    /// <summary>Set when the author changed the text ("edited").</summary>
    public DateTime? EditedAt { get; private set; }

    /// <summary>Hidden by a moderator (SPEC F22 hooks): only the author and moderators still see the text.</summary>
    public DateTime? HiddenAt { get; private set; }
    public Guid? HiddenById { get; private set; }

    /// <summary>
    /// Hidden by <c>hide_content</c> with all of its author's content (SPEC F23), so <c>unhide_content</c> brings back exactly
    /// this; any unhide clears it.
    /// </summary>
    public bool HiddenWithAccount { get; private set; }

    /// <summary>Removed by a moderator rather than by its author.</summary>
    public bool DeletedByModerator { get; private set; }

    public DateTime CreatedAt { get; private set; }
    public Guid? CreatedBy { get; private set; }
    public DateTime? UpdatedAt { get; private set; }
    public Guid? UpdatedBy { get; private set; }
    public bool IsDeleted { get; private set; }
    public DateTime? DeletedAt { get; private set; }
    public byte[] RowVersion { get; private set; } = [];

    public IReadOnlyCollection<CommentMention> Mentions => _mentions.AsReadOnly();

    // Read-side navigation for query projections only.
    public Users.User? Author { get; private set; }

    public bool IsReply => ParentId is not null;
    public bool IsHidden => HiddenAt is not null;

    /// <summary>Shown to everyone: not deleted and not hidden.</summary>
    public bool IsVisible => !IsDeleted && HiddenAt is null;

    /// <summary>A new top-level comment. <paramref name="body"/> must already be normalized (<see cref="CommentText"/>).</summary>
    public static Comment Post(Guid articleId, Guid authorId, string body, IReadOnlyCollection<Guid> mentionedUserIds, DateTime now)
    {
        var comment = new Comment { ArticleId = articleId, AuthorId = authorId, Body = body, CreatedAt = now };
        comment.SetMentions(mentionedUserIds);
        comment.Raise(() => new CommentChangedDomainEvent(comment.ArticleId, comment.Id, null, CommentChange.Created));
        return comment;
    }

    /// <summary>
    /// A reply in <paramref name="target"/>'s thread: replying to a reply joins its top-level comment. Deleted and hidden
    /// comments can't be replied to.
    /// </summary>
    public static Result<Comment> Reply(Comment target, Guid authorId, string body, IReadOnlyCollection<Guid> mentionedUserIds, DateTime now)
    {
        if (!target.IsVisible) return CommentErrors.NotAvailable;

        var reply = new Comment
        {
            ArticleId = target.ArticleId,
            ParentId = target.ParentId ?? target.Id,
            AuthorId = authorId,
            Body = body,
            CreatedAt = now,
        };
        reply.SetMentions(mentionedUserIds);
        reply.Raise(() => new CommentChangedDomainEvent(reply.ArticleId, reply.Id, reply.ParentId, CommentChange.Created));
        return reply;
    }

    public Result Edit(Guid userId, string body, IReadOnlyCollection<Guid> mentionedUserIds, DateTime now)
    {
        if (AuthorId != userId) return CommentErrors.NotOwner;
        if (IsDeleted) return CommentErrors.NotAvailable;
        if (Body == body) return Result.Success();

        Body = body;
        EditedAt = now;
        SetMentions(mentionedUserIds);
        Raise(() => new CommentChangedDomainEvent(ArticleId, Id, ParentId, CommentChange.Edited));
        return Result.Success();
    }

    /// <summary>The author deletes their own comment (soft). A pinned comment is unpinned.</summary>
    public Result Delete(Guid userId, DateTime now)
    {
        if (AuthorId != userId) return CommentErrors.NotOwner;
        if (IsDeleted) return Result.Success();

        MarkDeleted(now);
        return Result.Success();
    }

    /// <summary>A moderator removes the comment (soft); idempotent.</summary>
    public void DeleteByModerator(DateTime now)
    {
        if (IsDeleted) return;
        DeletedByModerator = true;
        MarkDeleted(now);
    }

    /// <summary>A moderator hides the comment; idempotent. Its author and moderators still see it, marked hidden.</summary>
    public void Hide(Guid moderatorId, DateTime now)
    {
        if (IsHidden || IsDeleted) return;
        HiddenAt = now;
        HiddenById = moderatorId;
        IsPinned = false;
        PinnedAt = null;
        Raise(() => new CommentChangedDomainEvent(ArticleId, Id, ParentId, CommentChange.Hidden));
    }

    /// <summary>Hidden with all of the author's content (SPEC F23 <c>hide_content</c>); returns false when nothing changed.</summary>
    public bool HideWithAccount(Guid moderatorId, DateTime now)
    {
        if (IsHidden || IsDeleted) return false;
        Hide(moderatorId, now);
        HiddenWithAccount = true;
        return true;
    }

    public void Unhide()
    {
        if (!IsHidden || IsDeleted) return;
        HiddenAt = null;
        HiddenById = null;
        HiddenWithAccount = false;
        Raise(() => new CommentChangedDomainEvent(ArticleId, Id, ParentId, CommentChange.Unhidden));
    }

    /// <summary>
    /// The article's author pins a top-level comment (SPEC F11: one pinned comment per article; the caller unpins the
    /// previous one with <see cref="Unpin"/>).
    /// </summary>
    public Result Pin(DateTime now)
    {
        if (IsReply) return CommentErrors.PinReply;
        if (!IsVisible) return CommentErrors.NotAvailable;
        if (IsPinned) return Result.Success();

        IsPinned = true;
        PinnedAt = now;
        Raise(() => new CommentChangedDomainEvent(ArticleId, Id, ParentId, CommentChange.Pinned));
        return Result.Success();
    }

    public void Unpin()
    {
        if (!IsPinned) return;
        IsPinned = false;
        PinnedAt = null;
        Raise(() => new CommentChangedDomainEvent(ArticleId, Id, ParentId, CommentChange.Pinned));
    }

    /// <summary>Local demo data only (SPEC §18.2).</summary>
    public void SeedCounts(int likes, int replies)
    {
        LikeCount = likes;
        ReplyCount = replies;
    }

    private void MarkDeleted(DateTime now)
    {
        IsDeleted = true;
        DeletedAt = now;
        IsPinned = false;
        PinnedAt = null;
        Raise(() => new CommentChangedDomainEvent(ArticleId, Id, ParentId, CommentChange.Deleted));
    }

    private void SetMentions(IReadOnlyCollection<Guid> userIds)
    {
        var wanted = userIds.Distinct().Take(MaxMentions).ToHashSet();
        _mentions.RemoveAll(m => !wanted.Contains(m.UserId));
        foreach (var userId in wanted.Where(id => _mentions.All(m => m.UserId != id)))
            _mentions.Add(new CommentMention(userId));
    }
}

/// <summary>A user @mentioned in a comment (SPEC F11); F17 notifies them once per comment (<c>mention</c>).</summary>
public sealed class CommentMention
{
    private CommentMention() { } // EF

    internal CommentMention(Guid userId) => UserId = userId;

    public Guid Id { get; private set; }
    public Guid CommentId { get; private set; }
    public Guid UserId { get; private set; }

    // Read-side navigation for query projections only.
    public Users.User User { get; private set; } = default!;
}

/// <summary>One user's like on a comment (SPEC F11); unique per user and comment.</summary>
public sealed class CommentLike : AggregateRoot
{
    private CommentLike() { } // EF

    public Guid CommentId { get; private set; }
    public Guid UserId { get; private set; }
    public DateTime LikedAt { get; private set; }

    public static CommentLike Create(Comment comment, Guid userId, DateTime now)
    {
        var like = new CommentLike { CommentId = comment.Id, UserId = userId, LikedAt = now };
        like.Raise(() => new CommentChangedDomainEvent(comment.ArticleId, comment.Id, comment.ParentId, CommentChange.Liked));
        return like;
    }

    /// <summary>Call before deleting the row, so the live "liked" signal goes out after the commit.</summary>
    public void Remove(Comment comment) =>
        Raise(() => new CommentChangedDomainEvent(comment.ArticleId, comment.Id, comment.ParentId, CommentChange.Liked));
}

public enum CommentChange
{
    Created,
    Edited,
    Deleted,
    Hidden,
    Unhidden,
    Liked,
    Pinned,
}

/// <summary>After the commit: the article's comment counter and the live event under <c>/live/articles/{id}/events</c> (F27).</summary>
public sealed record CommentChangedDomainEvent(Guid ArticleId, Guid CommentId, Guid? ParentId, CommentChange Change) : DomainEvent
{
    /// <summary>The change can move the article's comment count (a comment appeared or disappeared for readers).</summary>
    public bool ChangesCount => Change is CommentChange.Created or CommentChange.Deleted or CommentChange.Hidden or CommentChange.Unhidden;
}

public static class CommentErrors
{
    public static readonly Error NotFound = Error.NotFound("comment.not_found", "Comment not found.");
    public static readonly Error NotOwner = Error.Forbidden("comment.not_owner", "Only the author can change this comment.");
    public static readonly Error NotAvailable = Error.Conflict("comment.not_available", "This comment was deleted or hidden.");
    public static readonly Error PinReply = Error.Validation("comment.pin_reply", "Only top-level comments can be pinned.");
    public static readonly Error PinNotArticleAuthor = Error.Forbidden("comment.pin_not_author", "Only the article's author can pin comments.");
    public static readonly Error PinConflict = Error.Conflict("comment.pin_conflict", "Another comment was pinned at the same time. Try again.");
    public static readonly Error ArticleLimit = Error.TooManyRequests("comment.article_limit", "You've commented a lot on this article. Try again later.");
    public static readonly Error Duplicate = Error.Conflict("comment.duplicate", "You just posted the same comment.");
    public static readonly Error Empty = Error.Validation("comment.empty", "Write something first.");
    public static readonly Error TooLong = Error.Validation("comment.too_long", $"A comment can have at most {Comment.MaxBodyLength} characters.");
}
