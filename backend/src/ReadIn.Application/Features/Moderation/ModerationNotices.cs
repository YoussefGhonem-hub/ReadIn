using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;

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

/// <summary>After a notice commits: its best-effort push (SPEC F22). A failed push never fails or repeats the action.</summary>
internal sealed class ModerationNoticeIssuedEventHandler(ModerationNoticePush push) : IDomainEventHandler<ModerationNoticeIssuedDomainEvent>
{
    public async Task Handle(ModerationNoticeIssuedDomainEvent domainEvent, CancellationToken cancellationToken) =>
        await push.SendAsync(domainEvent.NoticeId, cancellationToken);
}

/// <summary>
/// The push of a new warning or hidden article (<c>moderation_notice</c>, docs/api/contract-v1.md "Push payloads"), in the
/// user's UI language, to every device they registered. Best effort: FCM failures are logged and never retried, since
/// the notice waits in GET /me/moderation-notices anyway. Tokens FCM rejects are deleted, as for the daily article.
/// </summary>
public sealed partial class ModerationNoticePush(IAppDbContext db, IPushSender pushSender, ILogger<ModerationNoticePush> logger)
{
    /// <summary><c>data.type</c> and the collapse key.</summary>
    public const string Type = "moderation_notice";

    public const string WarningTitleAr = "وصلك تحذير من فريق الإشراف";
    public const string WarningTitleEn = "You received a warning from the moderators";
    public const string ArticleHiddenTitleAr = "فريق الإشراف خفى مقالك";
    public const string ArticleHiddenTitleEn = "The moderators hid your article";

    /// <summary>The app shows the notice anyway the next time it starts.</summary>
    public static readonly TimeSpan TimeToLive = TimeSpan.FromDays(7);

    /// <returns>Devices FCM accepted the push for.</returns>
    public async Task<int> SendAsync(Guid noticeId, CancellationToken cancellationToken)
    {
        var notice = await db.ModerationActions.AsNoTracking()
            .Where(m => m.Id == noticeId && m.NoticeKind != null && m.AcknowledgedAt == null && m.TargetUserId != null)
            .Select(m => new { m.NoticeKind, m.Note, m.TargetId, m.TargetLabel, UserId = m.TargetUserId!.Value })
            .FirstOrDefaultAsync(cancellationToken);
        if (notice is null) return 0;

        var user = await db.Users.AsNoTracking()
            .Where(u => u.Id == notice.UserId)
            .Select(u => new { u.UiLanguage, Tokens = u.Devices.Select(d => d.Token).ToList() })
            .FirstOrDefaultAsync(cancellationToken);
        if (user is null || user.Tokens.Count == 0) return 0;

        var english = user.UiLanguage == UiLanguages.English;
        var data = new Dictionary<string, string> { ["type"] = Type, ["noticeId"] = noticeId.ToString(), ["kind"] = notice.NoticeKind! };
        string title, body;
        if (notice.NoticeKind == NoticeKinds.ArticleHidden)
        {
            title = english ? ArticleHiddenTitleEn : ArticleHiddenTitleAr;
            body = notice.TargetLabel ?? notice.Note ?? string.Empty;
            // The author opens the article itself, which shows the "Hidden by moderators" banner.
            var slug = await db.Articles.AsNoTracking().Where(a => a.Id == notice.TargetId).Select(a => a.Slug).FirstOrDefaultAsync(cancellationToken);
            if (slug is not null)
            {
                data["articleId"] = notice.TargetId.ToString();
                data["slug"] = slug;
                data["link"] = $"readin://a/{Uri.EscapeDataString(slug)}";
            }
        }
        else
        {
            title = english ? WarningTitleEn : WarningTitleAr;
            body = notice.Note ?? string.Empty;
        }

        var notification = new PushNotification([.. user.Tokens.Distinct(StringComparer.Ordinal)], title, body, data, Type, TimeToLive);
        PushOutcome outcome;
        try
        {
            outcome = (await pushSender.SendAsync([notification], cancellationToken))[0];
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            LogFailed(logger, ex, noticeId);
            return 0;
        }

        if (outcome.InvalidTokens.Count > 0)
        {
            // SPEC §21.1: tokens FCM reports as unregistered or invalid are removed.
            var stale = outcome.InvalidTokens.ToList();
            await db.Users.IgnoreQueryFilters().SelectMany(u => u.Devices).Where(d => stale.Contains(d.Token)).ExecuteDeleteAsync(cancellationToken);
        }
        return outcome.Sent;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "The push of moderation notice {NoticeId} failed; the notice waits in the app")]
    private static partial void LogFailed(ILogger logger, Exception exception, Guid noticeId);
}
