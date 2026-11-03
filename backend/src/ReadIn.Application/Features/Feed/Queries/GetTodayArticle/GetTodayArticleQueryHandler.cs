using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Reading;

namespace ReadIn.Application.Features.Feed.Queries.GetTodayArticle;

internal sealed class GetTodayArticleQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    TypeAdapterConfig mapping,
    TimeProvider clock,
    IFileStorage storage)
    : IQueryHandler<GetTodayArticleQuery, Result<ArticleCardDto?>>
{
    private const int MinMinutes = 4;
    private const int MaxMinutes = 10;
    private const int GuestRotationSize = 30;

    public async ValueTask<Result<ArticleCardDto?>> Handle(GetTodayArticleQuery query, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;

        if (currentUser.UserId is not { } userId)
        {
            var guestPick = await PickForGuestAsync(now, ct);
            return Result.Success(guestPick is null ? null : await CardAsync(guestPick.Value, query.UiLanguage, null, ct));
        }

        var user = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new
            {
                u.TimeZone,
                u.ArticleLanguagePref,
                FieldIds = u.Interests.Where(i => i.FieldId != null).Select(i => i.FieldId!.Value).ToList(),
                TopicIds = u.Interests.Where(i => i.TopicId != null).Select(i => i.TopicId!.Value).ToList(),
            })
            .FirstAsync(ct);

        var today = LocalDate(now, user.TimeZone);
        var existing = await db.DailyPicks.AsNoTracking()
            .Where(p => p.UserId == userId && p.Date == today)
            .Select(p => (Guid?)p.ArticleId)
            .FirstOrDefaultAsync(ct);

        var articleId = existing ?? await PickForUserAsync(userId, today, user.ArticleLanguagePref, user.FieldIds, user.TopicIds, ct);
        if (articleId is null) return Result.Success<ArticleCardDto?>(null);

        if (existing is null)
        {
            db.DailyPicks.Add(new DailyPick(userId, today, articleId.Value));
            await db.SaveChangesAsync(ct);
        }

        return Result.Success(await CardAsync(articleId.Value, query.UiLanguage, user.ArticleLanguagePref, ct));
    }

    /// <summary>
    /// F07 algorithm: reviewed + published, in interests, not read before, 4–10 minutes, preferred language first,
    /// best quality first, never the same field 3 days in a row. Constraints relax in order when nothing matches.
    /// </summary>
    private async Task<Guid?> PickForUserAsync(
        Guid userId, DateOnly today, string language, List<Guid> fieldIds, List<Guid> topicIds, CancellationToken ct)
    {
        var lastFields = await db.DailyPicks.AsNoTracking()
            .Where(p => p.UserId == userId && p.Date < today)
            .OrderByDescending(p => p.Date)
            .Take(2)
            .Join(db.Articles, p => p.ArticleId, a => a.Id, (_, a) => a.FieldId)
            .ToListAsync(ct);
        Guid? excludedField = lastFields.Count == 2 && lastFields[0] == lastFields[1] ? lastFields[0] : null;

        var completed = db.ReadingProgress.Where(r => r.UserId == userId && r.CompletedAt != null).Select(r => r.ArticleId);

        var eligible = Eligible().Where(a => !completed.Contains(a.Id));
        var hasInterests = fieldIds.Count + topicIds.Count > 0;

        IQueryable<Article>[] attempts =
        [
            Narrow(eligible, strictLength: true, interests: hasInterests, excludedField),
            Narrow(eligible, strictLength: false, interests: hasInterests, excludedField),
            Narrow(eligible, strictLength: false, interests: false, excludedField: null),
        ];

        foreach (var candidates in attempts)
        {
            var pick = await candidates
                .OrderByDescending(a => a.Translations.Any(t => t.Language == language))
                .ThenByDescending(a => a.QualityScore)
                .ThenByDescending(a => a.PublishedAt)
                .Select(a => (Guid?)a.Id)
                .FirstOrDefaultAsync(ct);
            if (pick is not null) return pick;
        }

        return null;

        IQueryable<Article> Narrow(IQueryable<Article> source, bool strictLength, bool interests, Guid? excludedField)
        {
            if (strictLength)
                source = source.Where(a => a.Translations.Any(t => t.IsSource && t.ReadingTimeMinutes >= MinMinutes && t.ReadingTimeMinutes <= MaxMinutes));
            if (interests)
                source = source.Where(a => fieldIds.Contains(a.FieldId) || (a.TopicId != null && topicIds.Contains(a.TopicId.Value)));
            if (excludedField is { } field)
                source = source.Where(a => a.FieldId != field);
            return source;
        }
    }

    /// <summary>Guests get a stable daily rotation over the best reviewed articles.</summary>
    private async Task<Guid?> PickForGuestAsync(DateTime now, CancellationToken ct)
    {
        var top = await Eligible()
            .OrderByDescending(a => a.QualityScore)
            .ThenByDescending(a => a.PublishedAt)
            .Select(a => a.Id)
            .Take(GuestRotationSize)
            .ToListAsync(ct);
        if (top.Count == 0) return null;

        var dayNumber = DateOnly.FromDateTime(now).DayNumber;
        return top[dayNumber % top.Count];
    }

    private IQueryable<Article> Eligible() => db.Articles.AsNoTracking()
        .Where(a => a.Status == ArticleStatus.Published && a.ReviewStatus == ReviewStatus.Approved && a.Field.IsEnabled);

    private async Task<ArticleCardDto?> CardAsync(Guid articleId, string uiLanguage, string? articleLanguage, CancellationToken ct)
    {
        using var _ = LocalizedProjection.Begin(uiLanguage, articleLanguage);
        var card = await db.Articles.AsNoTracking()
            .Where(a => a.Id == articleId)
            .ProjectToType<ArticleCardDto>(mapping)
            .FirstOrDefaultAsync(ct);
        return card?.WithPublicUrls(storage);
    }

    private static DateOnly LocalDate(DateTime utcNow, string timeZone)
    {
        var zone = TimeZoneInfo.TryFindSystemTimeZoneById(timeZone, out var tz) ? tz : TimeZoneInfo.Utc;
        return DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(utcNow, zone));
    }
}
