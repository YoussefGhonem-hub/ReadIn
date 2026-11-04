using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.Features.Moderation;

/// <summary>
/// GET /me/moderation-notices (SPEC F22): the warnings and hidden articles the caller hasn't acknowledged yet, oldest
/// first. Clients show each one as a dialog on start.
/// </summary>
[Authenticated]
public sealed record GetMyModerationNoticesQuery : IQuery<Result<ModerationNoticesDto>>;

/// <summary>POST /me/moderation-notices/{id}/acknowledge: "فهمت". Idempotent; someone else's notice is not found.</summary>
[Authenticated]
public sealed record AcknowledgeModerationNoticeCommand(Guid NoticeId) : ICommand<Result>;

internal sealed class GetMyModerationNoticesQueryHandler(IAppDbContext db, ICurrentUser currentUser)
    : IQueryHandler<GetMyModerationNoticesQuery, Result<ModerationNoticesDto>>
{
    public async ValueTask<Result<ModerationNoticesDto>> Handle(GetMyModerationNoticesQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        // Served by the filtered (TargetUserId, AcknowledgedAt) index.
        var notices = await db.ModerationActions.AsNoTracking()
            .Where(m => m.TargetUserId == userId && m.NoticeKind != null && m.AcknowledgedAt == null)
            .OrderBy(m => m.CreatedAt)
            .ThenBy(m => m.Id)
            .Select(m => new { m.Id, m.NoticeKind, m.Note, m.TargetId, m.TargetLabel, m.CreatedAt })
            .ToListAsync(cancellationToken);

        // The author may have deleted the article since; the notice still names it.
        var articleIds = notices.Where(n => n.NoticeKind == NoticeKinds.ArticleHidden).Select(n => n.TargetId).ToList();
        var articles = articleIds.Count == 0
            ? []
            : await db.Articles.IgnoreQueryFilters().AsNoTracking()
                .Where(a => articleIds.Contains(a.Id))
                .Select(a => new NoticeArticleDto(a.Id, a.Slug, a.Translations.Where(t => t.IsSource).Select(t => t.Title).FirstOrDefault() ?? ""))
                .ToDictionaryAsync(a => a.Id, cancellationToken);

        return new ModerationNoticesDto(
        [
            .. notices.Select(n => new ModerationNoticeDto(
                n.Id,
                n.NoticeKind!,
                n.Note,
                n.NoticeKind == NoticeKinds.ArticleHidden ? articles.GetValueOrDefault(n.TargetId) : null,
                n.CreatedAt)),
        ]);
    }
}

internal sealed class AcknowledgeModerationNoticeCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<AcknowledgeModerationNoticeCommand, Result>
{
    public async ValueTask<Result> Handle(AcknowledgeModerationNoticeCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var notice = await db.ModerationActions
            .FirstOrDefaultAsync(m => m.Id == command.NoticeId && m.TargetUserId == userId && m.NoticeKind != null, cancellationToken);
        if (notice is null) return ModerationErrors.NoticeNotFound;

        notice.Acknowledge(clock.GetUtcNow().UtcDateTime);
        await db.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}

/// <summary>
/// After a notice commits: a <c>moderation_notice</c> notification for the affected user (SPEC F17). It takes over F22's
/// own push, so the notice is pushed exactly once, by the notification push job; the notice itself still waits in
/// <c>GET /me/moderation-notices</c>, so a lost push loses nothing.
/// </summary>
internal sealed class ModerationNoticeIssuedEventHandler(IAppDbContext db, NotificationWriter writer)
    : IDomainEventHandler<ModerationNoticeIssuedDomainEvent>
{
    public async Task Handle(ModerationNoticeIssuedDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var notice = await db.ModerationActions.AsNoTracking()
            .Where(m => m.Id == domainEvent.NoticeId && m.NoticeKind != null && m.TargetUserId != null)
            .Select(m => new { m.NoticeKind, m.TargetId, UserId = m.TargetUserId!.Value })
            .FirstOrDefaultAsync(cancellationToken);
        if (notice is null) return;

        // The hidden article, unless its author deleted it since.
        Guid? articleId = notice.NoticeKind == NoticeKinds.ArticleHidden
            && await db.Articles.AsNoTracking().AnyAsync(a => a.Id == notice.TargetId, cancellationToken)
                ? notice.TargetId
                : null;

        await writer.WriteAsync(new NotificationRequest(notice.UserId, NotificationTypes.ModerationNotice)
        {
            ArticleId = articleId,
            DedupeKey = $"{NotificationTypes.ModerationNotice}:{domainEvent.NoticeId}",
            Data = new NotificationData { NoticeId = domainEvent.NoticeId, NoticeKind = notice.NoticeKind },
        }, cancellationToken);
    }
}
