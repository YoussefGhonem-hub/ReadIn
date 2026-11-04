using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Reading;

namespace ReadIn.Application.Features.Reading.Commands.RecordProgress;

internal sealed class RecordReadingProgressCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<RecordReadingProgressCommand, Result<ReadingProgressResultDto>>
{
    public async ValueTask<Result<ReadingProgressResultDto>> Handle(RecordReadingProgressCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var now = clock.GetUtcNow().UtcDateTime;

        // A hidden article is only read by its author and moderators (SPEC F22).
        if (!await db.Articles.AsNoTracking().VisibleTo(currentUser).AnyAsync(a => a.Id == command.ArticleId, cancellationToken))
            return ArticleErrors.NotFound;

        var timeZone = await db.Users.AsNoTracking().Where(u => u.Id == userId).Select(u => u.TimeZone).FirstAsync(cancellationToken);
        var today = ReadingClock.LocalDate(now, timeZone);

        var progress = await db.ReadingProgress
            .FirstOrDefaultAsync(r => r.UserId == userId && r.ArticleId == command.ArticleId, cancellationToken);
        if (progress is null)
        {
            progress = new ReadingProgress(userId, command.ArticleId, command.Language, now);
            db.ReadingProgress.Add(progress);
        }

        var update = progress.Record(command.Language, command.Percent, command.LastPosition, command.ActiveSecondsDelta, now);
        StreakDto? streak = null;
        int? milestone = null;

        if (update.CreditedSeconds > 0 || update.CompletedNow)
        {
            var day = await db.ReadingDays.FirstOrDefaultAsync(d => d.UserId == userId && d.Date == today, cancellationToken);
            if (day is null)
            {
                day = new ReadingDay(userId, today);
                db.ReadingDays.Add(day);
            }

            var stats = await db.UserStats.FirstOrDefaultAsync(s => s.UserId == userId, cancellationToken);
            if (stats is null)
            {
                stats = new UserStats(userId);
                db.UserStats.Add(stats);
            }

            day.AddSeconds(update.CreditedSeconds);
            stats.AddSeconds(update.CreditedSeconds, now);

            if (update.CompletedNow)
            {
                var todayIsNew = !day.CountsForStreak;
                day.AddCompletedArticle();

                var readDates = await db.ReadingDays.AsNoTracking()
                    .Where(d => d.UserId == userId && d.ArticlesRead > 0 && d.Date != today)
                    .Select(d => d.Date)
                    .ToListAsync(cancellationToken);
                readDates.Add(today);
                var history = Streaks.Compute(readDates);

                // This completion isn't saved yet, so it isn't in the count.
                var completed = await db.ReadingProgress.CountAsync(r => r.UserId == userId && r.CompletedAt != null, cancellationToken) + 1;
                stats.Apply(history, completed, now);

                streak = StreakDto.From(Streaks.StatusOn(history, today), today);
                milestone = todayIsNew ? Streaks.MilestoneReachedOn(history, today) : null;
            }
        }

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            return ReadingErrors.Conflict; // another report created the same progress/day/stats row; nothing was saved
        }

        return new ReadingProgressResultDto(progress.Percent, progress.IsCompleted, update.CompletedNow, streak, milestone);
    }
}
