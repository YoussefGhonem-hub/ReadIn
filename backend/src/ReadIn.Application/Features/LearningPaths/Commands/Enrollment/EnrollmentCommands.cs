using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Learning;

namespace ReadIn.Application.Features.LearningPaths.Commands.Enrollment;

/// <summary>
/// PUT /me/paths/{pathId} — enroll in a path (SPEC F09); idempotent. Returns the path card with your progress. When you
/// already read every article, the enrollment is completed at once (the badge).
/// </summary>
[Authenticated]
public sealed record EnrollInPathCommand(Guid PathId) : ICommand<Result<PathCardDto>>;

/// <summary>DELETE /me/paths/{pathId} — leave a path; idempotent. Reading history stays, so enrolling again shows the same progress.</summary>
[Authenticated]
public sealed record LeavePathCommand(Guid PathId) : ICommand<Result>;

internal sealed class EnrollInPathCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock, PathCards cards)
    : ICommandHandler<EnrollInPathCommand, Result<PathCardDto>>
{
    public async ValueTask<Result<PathCardDto>> Handle(EnrollInPathCommand command, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        var language = await cards.ArticleLanguageOfAsync(userId, currentUser.UiLanguage, ct);
        if (await cards.LoadAsync([command.PathId], userId, currentUser.UiLanguage, language, ct) is not [var path])
            return LearningPathErrors.NotFound;
        if (path.Enrollment is not null) return path.Card;

        var now = clock.GetUtcNow().UtcDateTime;
        var enrollment = new PathEnrollment(userId, command.PathId, now);
        enrollment.CompleteIfDone(path.Card.Progress!.ReadCount, path.Card.Progress.Total, now);
        db.PathEnrollments.Add(enrollment);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // Enrolled by a concurrent request (unique index): the outcome is the same.
            db.PathEnrollments.Entry(enrollment).State = EntityState.Detached;
            if (!await db.PathEnrollments.AnyAsync(e => e.UserId == userId && e.PathId == command.PathId, ct)) throw;
            return (await cards.BuildAsync([command.PathId], userId, currentUser.UiLanguage, language, ct))[0];
        }

        return path.Card with { Enrollment = new PathEnrollmentDto(enrollment.EnrolledAt, enrollment.CompletedAt) };
    }
}

internal sealed class LeavePathCommandHandler(IAppDbContext db, ICurrentUser currentUser) : ICommandHandler<LeavePathCommand, Result>
{
    public async ValueTask<Result> Handle(LeavePathCommand command, CancellationToken ct)
    {
        var userId = currentUser.RequireUserId();
        await db.PathEnrollments.Where(e => e.UserId == userId && e.PathId == command.PathId).ExecuteDeleteAsync(ct);
        return Result.Success();
    }
}
