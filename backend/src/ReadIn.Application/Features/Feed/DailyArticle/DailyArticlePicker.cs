using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.LearningPaths;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Reading;

namespace ReadIn.Application.Features.Feed.DailyArticle;

/// <summary>
/// Picks "مقال النهارده" (SPEC F07). Shared by <c>GET /feed/today</c>, which picks on demand, and the daily job, which picks
/// 30 minutes before the reminder time; both store the pick in <c>DailyPicks</c> (one per user and local date), so the
/// pushed article is always the hero card of that day.
/// </summary>
public sealed class DailyArticlePicker(IAppDbContext db)
{
    private const int MinMinutes = 4;
    private const int MaxMinutes = 10;
    private const int GuestRotationSize = 30;

    /// <summary>The stored pick of <paramref name="localDate"/>, or a new one, stored now. Null when nothing is eligible.</summary>
    public async Task<Guid?> GetOrPickAsync(Guid userId, DateOnly localDate, CancellationToken cancellationToken)
    {
        if (await StoredPickAsync(userId, localDate, cancellationToken) is { } stored) return stored;

        var articleId = await PickAsync(userId, localDate, cancellationToken);
        if (articleId is null) return null;

        // The job may have stored a pick for the same day in the meantime; then that one is today's article.
        return await StoreAsync([new DailyPick(userId, localDate, articleId.Value)], cancellationToken) == 1
            ? articleId
            : await StoredPickAsync(userId, localDate, cancellationToken);
    }

    /// <summary>Runs the algorithm for one user without storing the result.</summary>
    public async Task<Guid?> PickAsync(Guid userId, DateOnly localDate, CancellationToken cancellationToken)
    {
        var profiles = await LoadProfilesAsync([userId], localDate, cancellationToken);
        return profiles.TryGetValue(userId, out var profile) ? await PickAsync(profile, cancellationToken) : null;
    }

    /// <summary>What the algorithm needs to know about each user, loaded for a whole batch at once.</summary>
    internal async Task<IReadOnlyDictionary<Guid, PickerProfile>> LoadProfilesAsync(
        IReadOnlyCollection<Guid> userIds, DateOnly localDate, CancellationToken cancellationToken)
    {
        var ids = userIds.Distinct().ToList();
        var users = await db.Users.AsNoTracking()
            .Where(u => ids.Contains(u.Id))
            .Select(u => new
            {
                u.Id,
                u.ArticleLanguagePref,
                FieldIds = u.Interests.Where(i => i.FieldId != null).Select(i => i.FieldId!.Value).ToList(),
                TopicIds = u.Interests.Where(i => i.TopicId != null).Select(i => i.TopicId!.Value).ToList(),
            })
            .ToListAsync(cancellationToken);

        // "Not from the same field 3 days in a row": the fields of the picks of the two days before.
        var twoDaysBefore = localDate.AddDays(-2);
        var recent = await db.DailyPicks.AsNoTracking()
            .Where(p => ids.Contains(p.UserId) && p.Date >= twoDaysBefore && p.Date < localDate)
            .Join(db.Articles, p => p.ArticleId, a => a.Id, (p, a) => new { p.UserId, a.FieldId })
            .ToListAsync(cancellationToken);
        var recentFields = recent.ToLookup(r => r.UserId, r => r.FieldId);
        var pathNext = await ActivePathNext.LoadAsync(db, ids, cancellationToken);

        return users.ToDictionary(u => u.Id, u =>
        {
            var fields = recentFields[u.Id].ToList();
            Guid? excludedField = fields.Count == 2 && fields[0] == fields[1] ? fields[0] : null;
            return new PickerProfile(u.Id, u.ArticleLanguagePref, u.FieldIds, u.TopicIds, excludedField)
            {
                PathNext = pathNext.GetValueOrDefault(u.Id),
            };
        });
    }

    /// <summary>
    /// F07 algorithm: reviewed + published, in interests, not read before, 4–10 minutes, preferred language first, best
    /// quality first, never the same field 3 days in a row. Constraints relax in order when nothing matches (length, then
    /// interests), and at each step a published article that passed the content pipeline's automatic checks stands in when
    /// no reviewed article matches (the documented fallback while seeded articles wait for human review). Before all of
    /// that, "prefers the next item in the user's active learning path" (F09).
    /// </summary>
    internal async Task<Guid?> PickAsync(PickerProfile profile, CancellationToken cancellationToken)
    {
        var (userId, language, fieldIds, topicIds, excludedField) = profile;

        // F09: the active path's next unread article comes first, unless it would make 3 days in a row of one field.
        // Paths are curated, so any article a reader can open qualifies (length and interests don't apply).
        if (profile.PathNext is { } pathNext && pathNext.FieldId != excludedField) return pathNext.ArticleId;

        // Read = completed (≥ 70% and ≥ 30 seconds, SPEC F04), the single "read" marker.
        var completed = db.ReadingProgress.Where(r => r.UserId == userId && r.CompletedAt != null).Select(r => r.ArticleId);

        var reviewed = Reviewed().Where(a => !completed.Contains(a.Id));
        var autoChecked = AutoChecked().Where(a => !completed.Contains(a.Id));
        var hasInterests = fieldIds.Count + topicIds.Count > 0;

        IQueryable<Article>[] attempts =
        [
            Narrow(reviewed, strictLength: true, interests: hasInterests, excludedField),
            Narrow(autoChecked, strictLength: true, interests: hasInterests, excludedField),
            Narrow(reviewed, strictLength: false, interests: hasInterests, excludedField),
            Narrow(autoChecked, strictLength: false, interests: hasInterests, excludedField),
            Narrow(reviewed, strictLength: false, interests: false, excludedField: null),
            Narrow(autoChecked, strictLength: false, interests: false, excludedField: null),
        ];

        foreach (var candidates in attempts)
        {
            var pick = await candidates
                .OrderByDescending(a => a.Translations.Any(t => t.Language == language))
                .ThenByDescending(a => a.QualityScore)
                .ThenByDescending(a => a.PublishedAt)
                .Select(a => (Guid?)a.Id)
                .FirstOrDefaultAsync(cancellationToken);
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

    /// <summary>Guests get a stable daily rotation over the best reviewed articles (auto-checked ones when none is reviewed).</summary>
    public async Task<Guid?> PickForGuestAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        var top = await TopAsync(Reviewed(), cancellationToken);
        if (top.Count == 0) top = await TopAsync(AutoChecked(), cancellationToken);
        if (top.Count == 0) return null;

        var dayNumber = DateOnly.FromDateTime(utcNow).DayNumber;
        return top[dayNumber % top.Count];

        static Task<List<Guid>> TopAsync(IQueryable<Article> source, CancellationToken ct) => source
            .OrderByDescending(a => a.QualityScore)
            .ThenByDescending(a => a.PublishedAt)
            .Select(a => a.Id)
            .Take(GuestRotationSize)
            .ToListAsync(ct);
    }

    /// <summary>
    /// Adds <paramref name="picks"/>. One that lost a race (the job and <c>GET /feed/today</c> picking the same user and
    /// day at the same moment) is dropped: the unique (UserId, Date) index keeps the first, and that one is the pick.
    /// </summary>
    /// <returns>How many were stored.</returns>
    internal async Task<int> StoreAsync(IReadOnlyList<DailyPick> picks, CancellationToken cancellationToken)
    {
        if (picks.Count == 0) return 0;

        db.DailyPicks.AddRange(picks);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
            return picks.Count;
        }
        catch (DbUpdateException)
        {
            foreach (var pick in picks) db.DailyPicks.Entry(pick).State = EntityState.Detached;
        }

        var stored = 0;
        foreach (var pick in picks)
        {
            if (await db.DailyPicks.AnyAsync(p => p.UserId == pick.UserId && p.Date == pick.Date, cancellationToken)) continue;

            db.DailyPicks.Add(pick);
            try
            {
                await db.SaveChangesAsync(cancellationToken);
                stored++;
            }
            catch (DbUpdateException)
            {
                db.DailyPicks.Entry(pick).State = EntityState.Detached;
            }
        }
        return stored;
    }

    private Task<Guid?> StoredPickAsync(Guid userId, DateOnly localDate, CancellationToken cancellationToken) =>
        db.DailyPicks.AsNoTracking()
            .Where(p => p.UserId == userId && p.Date == localDate)
            .Select(p => (Guid?)p.ArticleId)
            .FirstOrDefaultAsync(cancellationToken);

    private IQueryable<Article> Published() => db.Articles.AsNoTracking()
        .Where(a => a.Status == ArticleStatus.Published && a.Field.IsEnabled);

    private IQueryable<Article> Reviewed() => Published().Where(a => a.ReviewStatus == ReviewStatus.Approved);

    /// <summary>Fallback pool: published, not (yet) reviewed, but passed the content pipeline's automatic checks.</summary>
    private IQueryable<Article> AutoChecked() => Published().Where(a => a.ReviewStatus != ReviewStatus.Approved && a.AutoCheckedAt != null);
}

/// <param name="ExcludedFieldId">The field of the last two days' picks when both were the same field.</param>
internal sealed record PickerProfile(
    Guid UserId,
    string ArticleLanguage,
    IReadOnlyList<Guid> FieldIds,
    IReadOnlyList<Guid> TopicIds,
    Guid? ExcludedFieldId)
{
    /// <summary>The next unread article of the user's active learning path (F09), picked first.</summary>
    public PathNextArticle? PathNext { get; init; }
}
