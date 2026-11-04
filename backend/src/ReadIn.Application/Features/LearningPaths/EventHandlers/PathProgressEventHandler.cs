using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Reading;

namespace ReadIn.Application.Features.LearningPaths.EventHandlers;

/// <summary>
/// After a read commits (F04), moves the reader's enrolled paths that hold the article: their latest activity (which
/// path is "active" on Home and in F07) and the completion badge once every article is read (SPEC F09). Recomputed
/// from the reads, so the outbox's at-least-once delivery is safe.
/// </summary>
internal sealed class PathProgressEventHandler(IAppDbContext db, TimeProvider clock, PathCards cards)
    : IDomainEventHandler<ArticleReadCompletedDomainEvent>
{
    public async Task Handle(ArticleReadCompletedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var enrollments = await db.PathEnrollments
            .Where(e => e.UserId == domainEvent.UserId
                && db.LearningPathItems.Any(i => i.PathId == e.PathId && i.ArticleId == domainEvent.ArticleId))
            .ToListAsync(cancellationToken);
        if (enrollments.Count == 0) return;

        var now = clock.GetUtcNow().UtcDateTime;
        var progress = (await cards.BuildAsync([.. enrollments.Select(e => e.PathId)], domainEvent.UserId, "en", null, cancellationToken))
            .ToDictionary(c => c.Id, c => c.Progress!);

        foreach (var enrollment in enrollments)
        {
            enrollment.RecordActivity(now);
            if (progress.TryGetValue(enrollment.PathId, out var p)) enrollment.CompleteIfDone(p.ReadCount, p.Total, now);
        }

        await db.SaveChangesAsync(cancellationToken);
    }
}
