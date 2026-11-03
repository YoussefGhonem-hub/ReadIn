using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Reactions;

/// <summary>The article's reactions right after your change, counted from the rows (not the denormalized columns).</summary>
public sealed record ArticleReactionsDto(ReactionCountsDto Reactions, int Total, ReactionType? MyReaction);

/// <summary>One row of "who reacted" (SPEC F10).</summary>
public sealed record ReactorDto(AuthorDto User, ReactionType Type, DateTime ReactedAt);

internal static class ArticleReactions
{
    /// <summary>Counts per type with one GROUP BY on the Reactions(ArticleId, Type) index.</summary>
    public static async Task<ArticleReactionsDto> ReadAsync(IAppDbContext db, Guid articleId, ReactionType? mine, CancellationToken ct)
    {
        var counts = await db.Reactions.AsNoTracking()
            .Where(r => r.ArticleId == articleId)
            .GroupBy(r => r.Type)
            .Select(g => new { Type = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Type, x => x.Count, ct);

        var reactions = new ReactionCountsDto(
            counts.GetValueOrDefault(ReactionType.Insightful),
            counts.GetValueOrDefault(ReactionType.Love),
            counts.GetValueOrDefault(ReactionType.Fire),
            counts.GetValueOrDefault(ReactionType.MindBlown));
        return new ArticleReactionsDto(reactions, reactions.Total(), mine);
    }
}
