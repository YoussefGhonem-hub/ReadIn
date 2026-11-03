using ReadIn.Application.Features.Articles;

namespace ReadIn.Application.Features.Comments;

/// <summary>An @mention that resolved to a user; clients link these handles and leave other "@words" as plain text.</summary>
public sealed record MentionDto(Guid UserId, string Username);

/// <summary>
/// A comment or reply as the viewer sees it (SPEC F11). <see cref="Author"/> is null when the author deleted their
/// account ("Deleted user"); a deleted or hidden comment that still has replies is a placeholder with no body.
/// </summary>
public sealed record CommentDto
{
    public Guid Id { get; init; }
    public Guid ArticleId { get; init; }

    /// <summary>The thread's top-level comment; null for top-level comments.</summary>
    public Guid? ParentId { get; init; }

    /// <summary>Null when the comment is a placeholder or its author deleted their account.</summary>
    public string? Body { get; init; }
    public AuthorDto? Author { get; init; }

    /// <summary>Written by the article's author: the "الكاتب" badge.</summary>
    public bool IsArticleAuthor { get; init; }
    public IReadOnlyList<MentionDto> Mentions { get; init; } = [];
    public int LikeCount { get; init; }
    public bool LikedByMe { get; init; }
    public int ReplyCount { get; init; }
    public bool IsPinned { get; init; }
    public DateTime CreatedAt { get; init; }

    /// <summary>Set when the text was edited ("edited").</summary>
    public DateTime? EditedAt { get; init; }

    /// <summary>A placeholder for a deleted comment kept for its replies.</summary>
    public bool IsDeleted { get; init; }

    /// <summary>Hidden by a moderator. Its author and moderators get the text; everyone else a placeholder.</summary>
    public bool IsHidden { get; init; }

    public bool CanEdit { get; init; }
    public bool CanDelete { get; init; }

    /// <summary>The viewer wrote the article and this is a visible top-level comment.</summary>
    public bool CanPin { get; init; }
    public bool CanReport { get; init; }

    /// <summary>The viewer has <c>moderation.manage</c>: hide, unhide or delete.</summary>
    public bool CanModerate { get; init; }

    /// <summary>Top-level comments in a list: the first replies of the thread (oldest first); the rest via /replies.</summary>
    public IReadOnlyList<CommentDto>? Replies { get; init; }
}

/// <summary>GET /articles/{id}/comments: the pinned comment comes first on the first page.</summary>
/// <param name="Total">Visible comments and replies on the article (<c>Articles.CommentCount</c>).</param>
public sealed record CommentPageDto(IReadOnlyList<CommentDto> Items, string? NextCursor, int Total);

/// <summary>PUT/DELETE /comments/{id}/like.</summary>
public sealed record CommentLikeDto(int LikeCount, bool Liked);

/// <summary>Someone the viewer can @mention while typing.</summary>
public sealed record MentionCandidateDto(Guid Id, string DisplayName, string Username, string? AvatarUrl, bool IsVerified);

public enum CommentSort
{
    Top,
    New,
}
