using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Users;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Comments;

/// <summary>A comment's text after normalizing, and the users its @mentions resolved to.</summary>
public sealed record PreparedComment(string Body, IReadOnlyList<Guid> MentionedUserIds);

/// <summary>
/// Shared by posting, replying and editing (SPEC F11): text rules, @mentions, and the flood limits. Besides the
/// 10-a-minute rate limit of the endpoint, one account can write at most <see cref="PerArticlePerHour"/> comments on one
/// article per hour, and not the same text twice within <see cref="DuplicateWindow"/>.
/// </summary>
public sealed class CommentPosting(IAppDbContext db, UserMentions mentions, TimeProvider clock)
{
    public const int PerArticlePerHour = 20;
    public static readonly TimeSpan DuplicateWindow = TimeSpan.FromMinutes(10);

    /// <summary>
    /// Unknown @usernames, the author's own handle and users who don't allow the author ("who can mention me", SPEC F18:
    /// their setting, or a suspended or system account) stay plain text: not in the mentions, so not linked or notified.
    /// The setting applies when the comment is written or edited; later changes don't touch it.
    /// </summary>
    public async Task<Result<PreparedComment>> PrepareAsync(string? body, Guid authorId, CancellationToken ct)
    {
        var text = CommentText.Normalize(body);
        if (text.IsFailure) return text.Error;

        var usernames = CommentText.MentionedUsernames(text.Value);
        var mentioned = await mentions.AllowedByUsernameAsync(authorId, usernames, ct);
        return new PreparedComment(text.Value, [.. mentioned.Where(id => id != authorId)]);
    }

    /// <summary>Deleted comments still count toward the hourly cap, so deleting doesn't reset it.</summary>
    public async Task<Result> CheckLimitsAsync(Guid authorId, Guid articleId, string body, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var hourAgo = now.AddHours(-1);
        var onArticle = await db.Comments.IgnoreQueryFilters()
            .CountAsync(c => c.AuthorId == authorId && c.ArticleId == articleId && c.CreatedAt >= hourAgo, ct);
        if (onArticle >= PerArticlePerHour) return CommentErrors.ArticleLimit;

        var since = now - DuplicateWindow;
        var recent = await db.Comments.AsNoTracking()
            .Where(c => c.AuthorId == authorId && c.CreatedAt >= since)
            .Select(c => c.Body)
            .ToListAsync(ct);
        var key = CommentText.DuplicateKey(body);
        return recent.Any(b => CommentText.DuplicateKey(b) == key) ? CommentErrors.Duplicate : Result.Success();
    }

    /// <summary>Re-reads a thread's visible replies into its top-level comment (after a reply appears or disappears).</summary>
    public Task RecountRepliesAsync(Guid parentId, CancellationToken ct) =>
        db.Comments.IgnoreQueryFilters()
            .Where(c => c.Id == parentId)
            .ExecuteUpdateAsync(
                set => set.SetProperty(c => c.ReplyCount,
                    c => db.Comments.Count(r => r.ParentId == c.Id && !r.IsDeleted && r.HiddenAt == null)),
                ct);

    /// <summary>Re-reads a comment's likes (after a like or unlike).</summary>
    public Task RecountLikesAsync(Guid commentId, CancellationToken ct) =>
        db.Comments.IgnoreQueryFilters()
            .Where(c => c.Id == commentId)
            .ExecuteUpdateAsync(set => set.SetProperty(c => c.LikeCount, c => db.CommentLikes.Count(l => l.CommentId == c.Id)), ct);
}
