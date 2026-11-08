using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.LearningPaths;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Reading.Queries.GetContinueReading;

/// <summary>
/// GET /me/continue-reading?limit= — the Home "continue reading" card (SPEC F03): unfinished articles, most recently read
/// first. Each card is in the language you were reading; the reader restores <c>lastPosition</c> itself.
/// </summary>
[Authenticated]
public sealed record GetContinueReadingQuery(int Limit, string UiLanguage) : IQuery<Result<IReadOnlyList<ContinueReadingDto>>>
{
    public const int DefaultLimit = 3;
    public const int MaxLimit = 10;

    /// <summary>Below this an article was only opened, not started.</summary>
    public const int MinPercent = 5;

    /// <summary>Older unfinished articles drop off the card.</summary>
    public const int WindowDays = 30;
}

/// <param name="Percent">How far you scrolled (5–100).</param>
/// <param name="Language">The version you were reading.</param>
/// <param name="UpdatedAt">Your last progress report.</param>
public sealed record ContinueReadingDto(ArticleCardDto Article, int Percent, string Language, DateTime UpdatedAt);

internal sealed class GetContinueReadingQueryHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock, PathCards cards)
    : IQueryHandler<GetContinueReadingQuery, Result<IReadOnlyList<ContinueReadingDto>>>
{
    public async ValueTask<Result<IReadOnlyList<ContinueReadingDto>>> Handle(GetContinueReadingQuery query, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        var limit = Math.Clamp(query.Limit, 1, GetContinueReadingQuery.MaxLimit);
        var since = clock.GetUtcNow().UtcDateTime.AddDays(-GetContinueReadingQuery.WindowDays);

        var rows = await db.ReadingProgress.AsNoTracking()
            .Where(r => r.UserId == userId
                && r.CompletedAt == null
                && r.Percent >= GetContinueReadingQuery.MinPercent
                && r.UpdatedAt >= since
                // F36: not the articles of people you are blocked with.
                && db.Articles.Visible().WithoutBlockedFor(db, userId).Any(a => a.Id == r.ArticleId))
            .OrderByDescending(r => r.UpdatedAt)
            .ThenByDescending(r => r.Id)
            .Take(limit)
            .Select(r => new { r.ArticleId, r.Percent, r.Language, r.UpdatedAt })
            .ToListAsync(ct);

        // One projection per language read (at most two), so each card shows the version you were reading.
        var articles = new Dictionary<Guid, ArticleCardDto>();
        foreach (var group in rows.GroupBy(r => r.Language))
        {
            foreach (var card in await cards.ArticleCardsAsync([.. group.Select(r => r.ArticleId)], query.UiLanguage, group.Key, ct))
                articles[card.Id] = card;
        }

        return rows
            .Where(r => articles.ContainsKey(r.ArticleId))
            .Select(r => new ContinueReadingDto(articles[r.ArticleId], r.Percent, articles[r.ArticleId].Language, r.UpdatedAt))
            .ToList();
    }
}
