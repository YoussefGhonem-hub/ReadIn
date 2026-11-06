using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.LearningPaths;
using ReadIn.Application.Features.Articles;
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

    /// <summary>
    /// The stored pick of <paramref name="localDate"/>, or a new one, stored now. Null when nothing is eligible. A stored
    /// pick the user has since muted (its writer, field or topic) or marked "show less" is replaced by the next eligible
    /// one, stored in its place, so it stays the same for the rest of the day (SPEC F28).
    /// </summary>
    public async Task<Guid?> GetOrPickAsync(Guid userId, DateOnly localDate, CancellationToken cancellationToken)
    {
        if (await StoredPickAsync(userId, localDate, cancellationToken) is { } stored)
        {
            if (await IsWantedByAsync(userId, stored, cancellationToken)) return stored;

            // The algorithm leaves out what the user muted, so the replacement never is; null when nothing is left.
            var replacement = await PickAsync(userId, localDate, cancellationToken);
            if (replacement is not { } next) return null;

            await db.DailyPicks
                .Where(p => p.UserId == userId && p.Date == localDate && p.ArticleId == stored)
                .ExecuteUpdateAsync(s => s.SetProperty(p => p.ArticleId, next).SetProperty(p => p.OpenedAt, (DateTime?)null), cancellationToken);
            // A concurrent request may have replaced it first; its choice is the same unless the data moved, so read it back.
            return await StoredPickAsync(userId, localDate, cancellationToken);
        }

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
    /// F07 algorithm: any published article (ADR 0015), in interests, not read before, in the preferred article
    /// language, 4–10 minutes, best <see cref="Article.QualityScore"/> first (equal scores: a verified writer's first,
    /// then the newest), never the same field 3 days in a row.
    /// Constraints relax in order when nothing matches (length, then interests); only when no unread article has the
    /// preferred language at all does the pick fall back to another language (served in its source language).
    /// Before all of that, "prefers the next item in the user's active learning path" (F09).
    /// </summary>
    internal async Task<Guid?> PickAsync(PickerProfile profile, CancellationToken cancellationToken)
    {
        var (userId, language, fieldIds, topicIds, excludedField) = profile;

        // F09: the active path's next unread article comes first, unless it would make 3 days in a row of one field.
        // Paths are curated, so any article a reader can open qualifies (length and interests don't apply), unless the
        // user muted it or marked it "show less" (F28).
        if (profile.PathNext is { } pathNext && pathNext.FieldId != excludedField
            && await IsWantedByAsync(userId, pathNext.ArticleId, cancellationToken))
        {
            return pathNext.ArticleId;
        }

        // Read = completed (≥ 70% and ≥ 30 seconds, SPEC F04), the single "read" marker.
        var completed = db.ReadingProgress.Where(r => r.UserId == userId && r.CompletedAt != null).Select(r => r.ArticleId);

        // A writer never gets their own article as Today's article, nor what they muted or marked "show less" (F28).
        var unread = Readable()
            .Where(a => a.AuthorId != userId && !completed.Contains(a.Id))
            .WithoutMutedFor(db, userId)
            .WithoutShownLessFor(db, userId);
        var hasInterests = fieldIds.Count + topicIds.Count > 0;

        var inLanguage = unread.Where(a => a.Translations.Any(t => t.Language == language));

        IQueryable<Article>[] attempts =
        [
            Narrow(inLanguage, strictLength: true, interests: hasInterests, excludedField),
            Narrow(inLanguage, strictLength: false, interests: hasInterests, excludedField),
            Narrow(inLanguage, strictLength: false, interests: false, excludedField: null),
            // No unread article has the preferred language: the same order, in any language.
            Narrow(unread, strictLength: true, interests: hasInterests, excludedField),
            Narrow(unread, strictLength: false, interests: hasInterests, excludedField),
            Narrow(unread, strictLength: false, interests: false, excludedField: null),
        ];

        foreach (var candidates in attempts)
        {
            var pick = await candidates
                .OrderByDescending(a => a.QualityScore)
                // SPEC §10.1: the Verified badge gives priority, here between equal scores (ADR 0020).
                .ThenByDescending(a => a.Author != null && a.Author.IsVerified)
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

    /// <summary>Guests get a stable daily rotation over the best published articles.</summary>
    public async Task<Guid?> PickForGuestAsync(DateTime utcNow, CancellationToken cancellationToken)
    {
        var top = await TopAsync(Readable(), cancellationToken);
        if (top.Count == 0) return null;

        var dayNumber = DateOnly.FromDateTime(utcNow).DayNumber;
        return top[dayNumber % top.Count];

        static Task<List<Guid>> TopAsync(IQueryable<Article> source, CancellationToken ct) => source
            .OrderByDescending(a => a.QualityScore)
            .ThenByDescending(a => a.Author != null && a.Author.IsVerified)
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

    /// <summary>What readers can open (hidden articles never become anyone's pick, SPEC F22).</summary>
    private IQueryable<Article> Readable() => db.Articles.AsNoTracking().Visible();

    /// <summary>
    /// <paramref name="articleId"/> isn't by a writer, in a field or topic <paramref name="userId"/> muted, nor marked "show
    /// less" (F28). A hidden or deleted pick counts as wanted here: the hero card leaves those out on its own (F22).
    /// </summary>
    private Task<bool> IsWantedByAsync(Guid userId, Guid articleId, CancellationToken ct) =>
        db.Articles.AsNoTracking().IgnoreQueryFilters()
            .Where(a => a.Id == articleId)
            .WithoutMutedFor(db, userId)
            .WithoutShownLessFor(db, userId)
            .AnyAsync(ct);
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
