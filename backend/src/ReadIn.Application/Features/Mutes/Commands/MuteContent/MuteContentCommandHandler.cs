using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Taxonomy;

namespace ReadIn.Application.Features.Mutes.Commands.MuteContent;

internal sealed class MuteContentCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<MuteContentCommand, Result<ContentMutesDto>>
{
    public async ValueTask<Result<ContentMutesDto>> Handle(MuteContentCommand command, CancellationToken cancellationToken)
    {
        if (command.Target == ContentMuteTarget.Field)
        {
            if (!await db.Fields.AnyAsync(f => f.Id == command.TargetId && f.IsEnabled, cancellationToken)) return TaxonomyErrors.FieldNotFound;
        }
        else if (!await db.Topics.AnyAsync(t => t.Id == command.TargetId, cancellationToken))
        {
            return TaxonomyErrors.TopicNotFound;
        }

        var userId = currentUser.RequireUserId();
        if (!await IsMutedAsync(userId, command, cancellationToken))
        {
            db.ContentMutes.Add(new ContentMute(userId, command.Target, command.TargetId, clock.GetUtcNow().UtcDateTime));
            try
            {
                await db.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException)
            {
                // Muted by a concurrent request (unique index): the outcome is the same.
                db.ClearChangeTracker();
                if (!await IsMutedAsync(userId, command, cancellationToken)) throw;
            }
        }

        return await db.ContentMutesAsync(userId, cancellationToken);
    }

    private Task<bool> IsMutedAsync(Guid userId, MuteContentCommand command, CancellationToken ct) =>
        db.ContentMutes.AsNoTracking().AnyAsync(
            m => m.UserId == userId && m.TargetType == command.Target && m.TargetId == command.TargetId, ct);
}
