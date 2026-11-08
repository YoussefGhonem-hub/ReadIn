using ReadIn.Application.Features.Blocks;
using ReadIn.Application.Features.ContentFilter;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Comments;

/// <summary>
/// The store-requirement checks of a comment or reply write (SPEC F36, F37): no comment on (or under) the content of someone
/// you are blocked with, the content filter on the text, and the 60-an-hour spam limit for new ones.
/// </summary>
public sealed class CommentGuard(BlockRelations blocks, ContentScreening screening, ContentLimits limits)
{
    /// <summary>
    /// The blocked person gets <paramref name="notFound"/> (as if the content were deleted); the blocker
    /// <c>403 block.blocked</c>; null when nobody blocked anybody.
    /// </summary>
    public Task<Error?> BlockedAsync(Guid writerId, Guid? ownerId, Error notFound, CancellationToken ct) =>
        blocks.ErrorForAsync(writerId, ownerId, notFound, ct);

    /// <summary>A new comment or reply: the spam limit, then the filter (<c>body</c>). The flagged terms on success.</summary>
    public async Task<Result<IReadOnlyList<string>>> ScreenNewAsync(Guid writerId, string body, CancellationToken ct)
    {
        var limit = await limits.CheckCommentAsync(writerId, ct);
        if (limit.IsFailure) return limit.Error;
        return await ScreenAsync(body, ct);
    }

    /// <summary>The filter on a comment's text (<c>body</c>), spam signs included.</summary>
    public Task<Result<IReadOnlyList<string>>> ScreenAsync(string body, CancellationToken ct) =>
        screening.ScreenAsync([new ScreenedField("body", body, SpamSignals: true)], ct);

    /// <summary>A flagged comment gets a system report (F22); the caller saves.</summary>
    public Task FlagAsync(Guid commentId, IReadOnlyList<string> flagged, CancellationToken ct) =>
        screening.FlagAsync(ReportTargetType.Comment, commentId, flagged, ct);
}
