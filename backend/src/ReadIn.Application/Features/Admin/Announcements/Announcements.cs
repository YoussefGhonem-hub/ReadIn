using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Admin;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Notifications;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Admin.Announcements;

// ---- Requests and DTOs (contract "Announcements (notifications.broadcast, web only)") ----

/// <param name="Type"><c>article</c> | <c>path</c>.</param>
public sealed record AnnouncementLinkInput(string? Type, Guid Id);

/// <param name="Type"><c>all</c> | <c>field</c> | <c>language</c>.</param>
/// <param name="FieldId">The <c>field</c> audience: an enabled field.</param>
/// <param name="Language">The <c>language</c> audience: <c>ar-EG</c> | <c>en</c>.</param>
public sealed record AnnouncementAudienceInput(string? Type, Guid? FieldId = null, string? Language = null);

/// <summary>What every announcement request carries: titles ≤ 60 and bodies ≤ 180 in both languages, a link, an audience.</summary>
public interface IAnnouncementInput
{
    string? TitleAr { get; }
    string? TitleEn { get; }
    string? BodyAr { get; }
    string? BodyEn { get; }
    AnnouncementLinkInput? Link { get; }
    AnnouncementAudienceInput? Audience { get; }
}

/// <summary>The body of POST /admin/announcements, /preview and /test.</summary>
public sealed record AnnouncementRequest(
    string? TitleAr, string? TitleEn, string? BodyAr, string? BodyEn, AnnouncementLinkInput? Link, AnnouncementAudienceInput? Audience)
    : IAnnouncementInput;

/// <param name="RecipientCount">Accounts that get the entry (their <c>announcement</c> mode isn't off).</param>
/// <param name="PushCount">Of those, with push on (<c>all</c>) and at least one device.</param>
/// <param name="CanSend">No announcement was sent today (in <c>Admin:TimeZone</c>).</param>
/// <param name="NextAllowedAt">When <see cref="CanSend"/> is false: the next local midnight.</param>
public sealed record AnnouncementPreviewDto(int RecipientCount, int PushCount, bool CanSend, DateTime? NextAllowedAt);

/// <param name="Title">In the caller's UI language.</param>
public sealed record AnnouncementLinkDto(string Type, Guid Id, string Slug, string Title);

public sealed record AnnouncementFieldDto(Guid Id, string Slug, string Name);

public sealed record AnnouncementAudienceDto(string Type, AnnouncementFieldDto? Field, string? Language);

public sealed record AnnouncementSenderDto(Guid Id, string Username);

/// <param name="Status"><c>sending</c> | <c>sent</c>.</param>
/// <param name="RecipientCount">While sending, the preview's count; the entries written once sent.</param>
/// <param name="SentBy">Null once that account is deleted.</param>
public sealed record AnnouncementDto(
    Guid Id,
    string TitleAr,
    string TitleEn,
    string BodyAr,
    string BodyEn,
    AnnouncementLinkDto? Link,
    AnnouncementAudienceDto Audience,
    string Status,
    int RecipientCount,
    AnnouncementSenderDto? SentBy,
    DateTime CreatedAt,
    DateTime? CompletedAt);

/// <param name="Items">The latest <see cref="GetAnnouncementsQuery.Limit"/>, newest first.</param>
public sealed record AnnouncementsDto(bool CanSend, DateTime? NextAllowedAt, IReadOnlyList<AnnouncementDto> Items);

// ---- Messages ----

/// <summary>GET /admin/announcements: whether one can be sent today, and the latest 50.</summary>
[RequirePermission(Permissions.Notifications.Broadcast)]
public sealed record GetAnnouncementsQuery : IQuery<Result<AnnouncementsDto>>
{
    public const int Limit = 50;
}

/// <summary>POST /admin/announcements/preview: who it would reach now. Nothing is sent or written.</summary>
[RequirePermission(Permissions.Notifications.Broadcast)]
public sealed record PreviewAnnouncementQuery(
    string? TitleAr, string? TitleEn, string? BodyAr, string? BodyEn, AnnouncementLinkInput? Link, AnnouncementAudienceInput? Audience)
    : IQuery<Result<AnnouncementPreviewDto>>, IAnnouncementInput;

/// <summary>
/// POST /admin/announcements/test: the announcement to its author alone, at once (their mode and quiet hours are
/// ignored). It isn't an announcement of the day and isn't listed. Audited <c>admin.announcement_tested</c>.
/// </summary>
[RequirePermission(Permissions.Notifications.Broadcast)]
public sealed record TestAnnouncementCommand(
    string? TitleAr, string? TitleEn, string? BodyAr, string? BodyEn, AnnouncementLinkInput? Link, AnnouncementAudienceInput? Audience)
    : ICommand<Result>, IAnnouncementInput;

/// <summary>
/// POST /admin/announcements: one a day (<c>429 announcement.limit</c>), to at least one recipient
/// (<c>400 announcement.no_recipients</c>). The entries are written by the outbox (<see cref="AnnouncementSentDomainEvent"/>).
/// Audited <c>admin.announcement_sent</c>.
/// </summary>
[RequirePermission(Permissions.Notifications.Broadcast)]
public sealed record SendAnnouncementCommand(
    string? TitleAr, string? TitleEn, string? BodyAr, string? BodyEn, AnnouncementLinkInput? Link, AnnouncementAudienceInput? Audience)
    : ICommand<Result<AnnouncementDto>>, IAnnouncementInput;

// ---- Validation ----

/// <summary>The rules every announcement request shares; each request's validator includes them.</summary>
internal sealed class AnnouncementInputValidator : AbstractValidator<IAnnouncementInput>
{
    public AnnouncementInputValidator()
    {
        RuleFor(c => c.TitleAr).NotEmpty().Must(v => Fits(v, Announcement.MaxTitleLength)).WithErrorCode("validation.max_length");
        RuleFor(c => c.TitleEn).NotEmpty().Must(v => Fits(v, Announcement.MaxTitleLength)).WithErrorCode("validation.max_length");
        RuleFor(c => c.BodyAr).NotEmpty().Must(v => Fits(v, Announcement.MaxBodyLength)).WithErrorCode("validation.max_length");
        RuleFor(c => c.BodyEn).NotEmpty().Must(v => Fits(v, Announcement.MaxBodyLength)).WithErrorCode("validation.max_length");
        RuleFor(c => c.Audience).NotNull();
        When(c => c.Audience is not null, () =>
        {
            RuleFor(c => c.Audience!.Type)
                .Must(t => t is AnnouncementAudiences.All or AnnouncementAudiences.Field or AnnouncementAudiences.Language)
                .WithErrorCode("validation.invalid");
            When(c => c.Audience!.Type == AnnouncementAudiences.Field, () => RuleFor(c => c.Audience!.FieldId).NotNull());
            When(c => c.Audience!.Type == AnnouncementAudiences.Language, () =>
                RuleFor(c => c.Audience!.Language).Must(ArticleLanguages.IsValid).WithErrorCode("validation.invalid"));
        });
        When(c => c.Link is not null, () =>
            RuleFor(c => c.Link!.Type).Must(t => t is AnnouncementLinks.Article or AnnouncementLinks.Path).WithErrorCode("validation.invalid"));
    }

    private static bool Fits(string? value, int max) => value is null || value.Trim().Length <= max;
}

internal sealed class PreviewAnnouncementQueryValidator : AbstractValidator<PreviewAnnouncementQuery>
{
    public PreviewAnnouncementQueryValidator() => Include(new AnnouncementInputValidator());
}

internal sealed class TestAnnouncementCommandValidator : AbstractValidator<TestAnnouncementCommand>
{
    public TestAnnouncementCommandValidator() => Include(new AnnouncementInputValidator());
}

internal sealed class SendAnnouncementCommandValidator : AbstractValidator<SendAnnouncementCommand>
{
    public SendAnnouncementCommandValidator() => Include(new AnnouncementInputValidator());
}

// ---- Audience and link ----

/// <summary>An announcement's checked audience and link: what it is sent to, and what the entry opens.</summary>
internal sealed record ResolvedAnnouncement(
    string TitleAr, string TitleEn, string BodyAr, string BodyEn, string AudienceType, Guid? FieldId, string? Language, string? LinkType,
    Guid? LinkId, Guid? ArticleId, string? PathSlug);

/// <summary>Who gets an announcement (contract decision 13) and checking its link (SPEC F23).</summary>
internal static class AnnouncementAudience
{
    /// <summary>
    /// Active accounts (not suspended now, not a system account) other than <paramref name="senderId"/>, in the audience,
    /// whose <c>announcement</c> mode isn't off. A field's readers follow the field or one of its topics; a language's
    /// readers have it as their article language.
    /// </summary>
    public static IQueryable<User> Recipients(IAppDbContext db, string audienceType, Guid? fieldId, string? language, Guid? senderId, DateTime now)
    {
        var users = db.Users.AsNoTracking()
            .Where(u => !u.IsSystemAccount && u.Id != senderId && !(u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now)));
        if (audienceType == AnnouncementAudiences.Field)
        {
            users = users.Where(u => u.Interests.Any(i =>
                i.FieldId == fieldId || (i.TopicId != null && db.Topics.Any(t => t.Id == i.TopicId && t.FieldId == fieldId))));
        }
        else if (audienceType == AnnouncementAudiences.Language)
        {
            users = users.Where(u => u.ArticleLanguagePref == language);
        }
        return users.Where(u => !db.UserNotificationSettings.Any(s =>
            s.UserId == u.Id && s.Type == NotificationTypes.Announcement && s.Mode == NotificationMode.Off));
    }

    /// <summary>The entries' data: the text in both languages, and the path a path link opens.</summary>
    public static NotificationData Data(Guid? announcementId, ResolvedAnnouncement resolved) => new()
    {
        AnnouncementId = announcementId,
        TitleAr = resolved.TitleAr,
        TitleEn = resolved.TitleEn,
        BodyAr = resolved.BodyAr,
        BodyEn = resolved.BodyEn,
        PathSlug = resolved.PathSlug,
    };

    /// <summary>
    /// Checks the field (<c>404 field.not_found</c> unless enabled) and the link (<c>400 announcement.link_invalid</c> unless
    /// it is an article readers can open or a published path), and trims the text.
    /// </summary>
    public static async Task<Result<ResolvedAnnouncement>> ResolveAsync(IAppDbContext db, IAnnouncementInput input, CancellationToken ct)
    {
        var audience = input.Audience!;
        if (audience.Type == AnnouncementAudiences.Field &&
            !await db.Fields.AnyAsync(f => f.Id == audience.FieldId && f.IsEnabled, ct))
            return TaxonomyErrors.FieldNotFound;

        Guid? articleId = null;
        string? pathSlug = null;
        if (input.Link is { } link)
        {
            if (link.Type == AnnouncementLinks.Article)
            {
                if (!await db.Articles.Visible().AnyAsync(a => a.Id == link.Id, ct)) return AdminErrors.AnnouncementLinkInvalid;
                articleId = link.Id;
            }
            else
            {
                pathSlug = await db.LearningPaths.Where(p => p.Id == link.Id && p.IsPublished).Select(p => p.Slug).FirstOrDefaultAsync(ct);
                if (pathSlug is null) return AdminErrors.AnnouncementLinkInvalid;
            }
        }

        return new ResolvedAnnouncement(
            input.TitleAr!.Trim(), input.TitleEn!.Trim(), input.BodyAr!.Trim(), input.BodyEn!.Trim(), audience.Type!,
            audience.Type == AnnouncementAudiences.Field ? audience.FieldId : null,
            audience.Type == AnnouncementAudiences.Language ? audience.Language : null,
            input.Link?.Type, input.Link?.Id, articleId, pathSlug);
    }

    /// <summary>A short note for the audit log: the audience, never personal data.</summary>
    public static string AuditDetails(ResolvedAnnouncement resolved, int recipients) => resolved.AudienceType switch
    {
        AnnouncementAudiences.Field => $"field={resolved.FieldId} ({recipients} recipients)",
        AnnouncementAudiences.Language => $"language={resolved.Language} ({recipients} recipients)",
        _ => $"all ({recipients} recipients)",
    };
}

/// <summary>Announcement rows as DTOs, with their link and field in the caller's UI language.</summary>
internal sealed class AnnouncementReader(IAppDbContext db, ICurrentUser currentUser)
{
    public async Task<IReadOnlyList<AnnouncementDto>> LoadAsync(IQueryable<Announcement> announcements, CancellationToken ct)
    {
        var rows = await announcements.AsNoTracking().ToListAsync(ct);
        if (rows.Count == 0) return [];
        var english = currentUser.UiLanguage == UiLanguages.English;

        var articleIds = rows.Where(r => r.LinkType == AnnouncementLinks.Article && r.LinkId != null).Select(r => r.LinkId!.Value).Distinct().ToList();
        var uiArticleLanguage = english ? ArticleLanguages.English : ArticleLanguages.EgyptianArabic;
        var articles = articleIds.Count == 0
            ? []
            : (await db.Articles.IgnoreQueryFilters().AsNoTracking()
                    .Where(a => articleIds.Contains(a.Id))
                    .Select(a => new { a.Id, a.Slug, Translations = a.Translations.Select(t => new { t.Language, t.Title, t.IsSource }).ToList() })
                    .ToListAsync(ct))
                .ToDictionary(a => a.Id, a => (a.Slug, Title: (a.Translations.FirstOrDefault(t => t.Language == uiArticleLanguage)
                    ?? a.Translations.FirstOrDefault(t => t.IsSource))?.Title ?? a.Slug));

        var pathIds = rows.Where(r => r.LinkType == AnnouncementLinks.Path && r.LinkId != null).Select(r => r.LinkId!.Value).Distinct().ToList();
        var paths = pathIds.Count == 0
            ? []
            : await db.LearningPaths.AsNoTracking()
                .Where(p => pathIds.Contains(p.Id))
                .ToDictionaryAsync(p => p.Id, p => (p.Slug, Title: english ? p.TitleEn : p.TitleAr), ct);

        var fieldIds = rows.Where(r => r.FieldId != null).Select(r => r.FieldId!.Value).Distinct().ToList();
        var fields = fieldIds.Count == 0
            ? []
            : await db.Fields.AsNoTracking()
                .Where(f => fieldIds.Contains(f.Id))
                .ToDictionaryAsync(f => f.Id, f => new AnnouncementFieldDto(f.Id, f.Slug, english ? f.NameEn : f.NameAr), ct);

        var senderIds = rows.Where(r => r.SentById != null).Select(r => r.SentById!.Value).Distinct().ToList();
        var senders = await db.Users.AsNoTracking()
            .Where(u => senderIds.Contains(u.Id))
            .ToDictionaryAsync(u => u.Id, u => new AnnouncementSenderDto(u.Id, u.Username), ct);

        return
        [
            .. rows.Select(r => new AnnouncementDto(
                r.Id,
                r.TitleAr,
                r.TitleEn,
                r.BodyAr,
                r.BodyEn,
                LinkOf(r),
                new AnnouncementAudienceDto(r.AudienceType, r.FieldId is { } fieldId ? fields.GetValueOrDefault(fieldId) : null, r.Language),
                r.Status == AnnouncementStatus.Sent ? "sent" : "sending",
                r.RecipientCount,
                r.SentById is { } senderId ? senders.GetValueOrDefault(senderId) : null,
                r.CreatedAt,
                r.CompletedAt)),
        ];

        AnnouncementLinkDto? LinkOf(Announcement r) => (r.LinkType, r.LinkId) switch
        {
            (AnnouncementLinks.Article, { } id) when articles.TryGetValue(id, out var a) => new AnnouncementLinkDto(AnnouncementLinks.Article, id, a.Slug, a.Title),
            (AnnouncementLinks.Path, { } id) when paths.TryGetValue(id, out var p) => new AnnouncementLinkDto(AnnouncementLinks.Path, id, p.Slug, p.Title),
            _ => null,
        };
    }
}

// ---- Handlers ----

internal sealed class GetAnnouncementsQueryHandler(IAppDbContext db, AnnouncementReader reader, AdminClock clock)
    : IQueryHandler<GetAnnouncementsQuery, Result<AnnouncementsDto>>
{
    public async ValueTask<Result<AnnouncementsDto>> Handle(GetAnnouncementsQuery query, CancellationToken cancellationToken)
    {
        var today = clock.Today;
        var sentToday = await db.Announcements.AnyAsync(a => a.LocalDate == today, cancellationToken);
        var items = await reader.LoadAsync(
            db.Announcements.OrderByDescending(a => a.CreatedAt).ThenByDescending(a => a.Id).Take(GetAnnouncementsQuery.Limit), cancellationToken);
        return new AnnouncementsDto(!sentToday, sentToday ? clock.NextMidnightUtc() : null, items);
    }
}

internal sealed class PreviewAnnouncementQueryHandler(IAppDbContext db, ICurrentUser currentUser, AdminClock clock)
    : IQueryHandler<PreviewAnnouncementQuery, Result<AnnouncementPreviewDto>>
{
    public async ValueTask<Result<AnnouncementPreviewDto>> Handle(PreviewAnnouncementQuery query, CancellationToken cancellationToken)
    {
        var resolved = await AnnouncementAudience.ResolveAsync(db, query, cancellationToken);
        if (resolved.IsFailure) return resolved.Error!;

        var now = clock.UtcNow;
        var recipients = AnnouncementAudience.Recipients(db, resolved.Value.AudienceType, resolved.Value.FieldId, resolved.Value.Language,
            currentUser.UserId, now);
        var count = await recipients.CountAsync(cancellationToken);
        var pushes = await recipients
            .Where(u => u.Devices.Any() && !db.UserNotificationSettings.Any(s =>
                s.UserId == u.Id && s.Type == NotificationTypes.Announcement && s.Mode != NotificationMode.All))
            .CountAsync(cancellationToken);

        var today = clock.Today;
        var sentToday = await db.Announcements.AnyAsync(a => a.LocalDate == today, cancellationToken);
        return new AnnouncementPreviewDto(count, pushes, !sentToday, sentToday ? clock.NextMidnightUtc() : null);
    }
}

internal sealed class TestAnnouncementCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, NotificationWriter writer, AuditTrail audit)
    : ICommandHandler<TestAnnouncementCommand, Result>
{
    public async ValueTask<Result> Handle(TestAnnouncementCommand command, CancellationToken cancellationToken)
    {
        var resolved = await AnnouncementAudience.ResolveAsync(db, command, cancellationToken);
        if (resolved.IsFailure) return resolved.Error!;

        var userId = currentUser.RequireUserId();
        audit.Record(AuditActions.AnnouncementTested, null, AuditTargets.Announcement, null,
            AnnouncementAudience.AuditDetails(resolved.Value, 1));
        await db.SaveChangesAsync(cancellationToken);

        // At once, whatever the author's mode and quiet hours: a test is for seeing it now.
        await writer.WriteAsync(new NotificationRequest(userId, NotificationTypes.Announcement)
        {
            ArticleId = resolved.Value.ArticleId,
            Data = AnnouncementAudience.Data(null, resolved.Value) with { IsTest = true },
            Forced = true,
        }, cancellationToken);
        return Result.Success();
    }
}

internal sealed class SendAnnouncementCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, AdminClock clock, AuditTrail audit, AnnouncementReader reader)
    : ICommandHandler<SendAnnouncementCommand, Result<AnnouncementDto>>
{
    public async ValueTask<Result<AnnouncementDto>> Handle(SendAnnouncementCommand command, CancellationToken cancellationToken)
    {
        var resolved = await AnnouncementAudience.ResolveAsync(db, command, cancellationToken);
        if (resolved.IsFailure) return resolved.Error!;
        var r = resolved.Value;

        var today = clock.Today;
        if (await db.Announcements.AnyAsync(a => a.LocalDate == today, cancellationToken)) return AdminErrors.AnnouncementLimit;

        var senderId = currentUser.RequireUserId();
        var now = clock.UtcNow;
        var count = await AnnouncementAudience.Recipients(db, r.AudienceType, r.FieldId, r.Language, senderId, now).CountAsync(cancellationToken);
        if (count == 0) return AdminErrors.AnnouncementNoRecipients;

        var announcement = new Announcement(r.TitleAr, r.TitleEn, r.BodyAr, r.BodyEn, r.LinkType, r.LinkId, r.AudienceType, r.FieldId, r.Language,
            senderId, today, count, now);
        db.Announcements.Add(announcement);
        audit.Record(AuditActions.AnnouncementSent, null, AuditTargets.Announcement, announcement.Id, AnnouncementAudience.AuditDetails(r, count));
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // Another send took today's slot first (the unique day).
            db.ClearChangeTracker();
            return AdminErrors.AnnouncementLimit;
        }

        var id = announcement.Id;
        return (await reader.LoadAsync(db.Announcements.Where(a => a.Id == id), cancellationToken))[0];
    }
}

/// <summary>
/// Writes an announcement's entries (SPEC F23): every recipient of its audience, in batches through the
/// <see cref="NotificationWriter"/> (quiet hours, modes, the push job), then marks it sent with the number written. Each
/// entry has the dedupe key <c>announcement:{id}</c>, so a retried event writes nothing twice.
/// </summary>
internal sealed class AnnouncementFanOutHandler(IAppDbContext db, NotificationWriter writer, TimeProvider clock)
    : IDomainEventHandler<AnnouncementSentDomainEvent>
{
    internal const int BatchSize = 500;

    public async Task Handle(AnnouncementSentDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var announcement = await db.Announcements.AsNoTracking().FirstOrDefaultAsync(a => a.Id == domainEvent.AnnouncementId, cancellationToken);
        if (announcement is null || announcement.Status == AnnouncementStatus.Sent) return;

        string? pathSlug = null;
        if (announcement is { LinkType: AnnouncementLinks.Path, LinkId: { } pathId })
            pathSlug = await db.LearningPaths.Where(p => p.Id == pathId).Select(p => p.Slug).FirstOrDefaultAsync(cancellationToken);
        var resolved = new ResolvedAnnouncement(announcement.TitleAr, announcement.TitleEn, announcement.BodyAr, announcement.BodyEn,
            announcement.AudienceType, announcement.FieldId, announcement.Language, announcement.LinkType, announcement.LinkId,
            announcement.LinkType == AnnouncementLinks.Article ? announcement.LinkId : null, pathSlug);
        var data = AnnouncementAudience.Data(announcement.Id, resolved);
        var key = $"{NotificationTypes.Announcement}:{announcement.Id}";

        var now = clock.GetUtcNow().UtcDateTime;
        var recipients = AnnouncementAudience.Recipients(db, announcement.AudienceType, announcement.FieldId, announcement.Language,
            announcement.SentById, now);
        var written = 0;
        Guid? after = null;
        while (true)
        {
            var page = recipients;
            if (after is { } last) page = page.Where(u => u.Id.CompareTo(last) > 0);
            var ids = await page.OrderBy(u => u.Id).Select(u => u.Id).Take(BatchSize).ToListAsync(cancellationToken);
            if (ids.Count == 0) break;

            var results = await writer.WriteAsync(
                [.. ids.Select(userId => new NotificationRequest(userId, NotificationTypes.Announcement)
                {
                    GroupKey = key,
                    DedupeKey = key,
                    ArticleId = resolved.ArticleId,
                    Data = data,
                })],
                cancellationToken);
            written += results.Count(r => r is not null);
            after = ids[^1];
        }

        await db.Announcements
            .Where(a => a.Id == announcement.Id)
            .ExecuteUpdateAsync(set => set
                .SetProperty(a => a.Status, AnnouncementStatus.Sent)
                .SetProperty(a => a.RecipientCount, written)
                .SetProperty(a => a.CompletedAt, clock.GetUtcNow().UtcDateTime), cancellationToken);
    }
}
