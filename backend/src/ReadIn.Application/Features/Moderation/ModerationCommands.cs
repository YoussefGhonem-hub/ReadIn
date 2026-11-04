using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Comments;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Moderation;

/// <summary>
/// POST /reports (SPEC F22): a reader reports an article, a comment or a user. Not their own content or themselves;
/// reporting the same target again is a no-op. Targets the reporter can't see (deleted, or a hidden article) are not found.
/// </summary>
[RequirePermission(Permissions.Reports.Create)]
public sealed record ReportContentCommand(string TargetType, Guid TargetId, string Reason, string? Details) : ICommand<Result>;

/// <summary>
/// POST /moderation/actions (SPEC F22). Comments: hide, unhide, delete. Articles: hide, unhide. Users: warn, suspend,
/// unsuspend (both need <c>users.suspend</c>). Any target: dismiss its open reports. Hide, delete, warn and suspend resolve
/// the target's open reports, and those of <see cref="ResolveReportsOf"/> too. An action that changed something is logged
/// in ModerationActions, and in the audit log when it touched a user's content or account; repeating one that changes
/// nothing is a no-op.
/// </summary>
/// <param name="Note">≤ 500; required to warn or suspend.</param>
/// <param name="DurationDays">Suspend only: 1–365, null = permanent.</param>
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record ModerateContentCommand(
    string Action,
    string TargetType,
    Guid TargetId,
    string? Note = null,
    int? DurationDays = null,
    ModerationTargetRef? ResolveReportsOf = null) : ICommand<Result>;

/// <summary>Another target, e.g. the article an author is warned for, whose open reports the action also resolves.</summary>
public sealed record ModerationTargetRef(string TargetType, Guid TargetId);

/// <summary>The <c>action</c> of POST /moderation/actions and the targets each one applies to.</summary>
public static class ModerationVerbs
{
    public const string Hide = "hide";
    public const string Unhide = "unhide";
    public const string Delete = "delete";
    public const string Warn = "warn";
    public const string Suspend = "suspend";
    public const string Unsuspend = "unsuspend";
    public const string Dismiss = "dismiss";

    public static bool Allows(string? action, ReportTargetType target) => (action, target) switch
    {
        (Hide or Unhide or Delete or Dismiss, ReportTargetType.Comment) => true,
        (Hide or Unhide or Dismiss, ReportTargetType.Article) => true,
        (Warn or Suspend or Unsuspend or Dismiss, ReportTargetType.User) => true,
        _ => false,
    };

    /// <summary>Hide, delete, warn and suspend resolve the target's open reports; dismiss closes them as dismissed.</summary>
    public static bool ClosesReports(string action) => action is Hide or Delete or Warn or Suspend or Dismiss;
}

internal sealed class ReportContentCommandValidator : AbstractValidator<ReportContentCommand>
{
    public ReportContentCommandValidator()
    {
        RuleFor(c => c.TargetType).Must(t => ModerationValues.TryParseTarget(t, out _)).WithErrorCode("report.target_invalid");
        RuleFor(c => c.Reason).Must(r => ModerationValues.TryParseReason(r, out _)).WithErrorCode("report.reason_invalid");
        RuleFor(c => c.Details).MaximumLength(Report.MaxDetailsLength);
    }
}

internal sealed class ModerateContentCommandValidator : AbstractValidator<ModerateContentCommand>
{
    public ModerateContentCommandValidator()
    {
        // The action and its target, the required note and the duration are business errors with their own codes (handler).
        RuleFor(c => c.Note).MaximumLength(ModerationAction.MaxNoteLength);
        When(c => c.ResolveReportsOf is not null, () =>
            RuleFor(c => c.ResolveReportsOf!.TargetType).Must(t => ModerationValues.TryParseTarget(t, out _)).WithErrorCode("report.target_invalid"));
    }
}

internal sealed class ReportContentCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<ReportContentCommand, Result>
{
    /// <param name="OwnerId">The article's or comment's author, or the user itself; null for a deleted author.</param>
    private sealed record ReportedTarget(Guid? OwnerId);

    public async ValueTask<Result> Handle(ReportContentCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        ModerationValues.TryParseTarget(command.TargetType, out var targetType);
        ModerationValues.TryParseReason(command.Reason, out var reason);

        var target = await FindAsync(targetType, command.TargetId, cancellationToken);
        if (target is null) return ReportErrors.TargetNotFound;
        if (target.OwnerId == userId) return ReportErrors.OwnContent;

        if (await db.Reports.AnyAsync(r => r.ReporterId == userId && r.TargetType == targetType && r.TargetId == command.TargetId, cancellationToken))
            return Result.Success();

        db.Reports.Add(Report.File(targetType, command.TargetId, userId, reason, command.Details, clock.GetUtcNow().UtcDateTime));
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // The same report was filed by a parallel request; the outcome is the same.
        }
        return Result.Success();
    }

    /// <summary>
    /// Deleted rows are gone through the query filters (a suspended user can still be reported); a hidden article and
    /// its comments only exist for the article's author and moderators.
    /// </summary>
    private async Task<ReportedTarget?> FindAsync(ReportTargetType type, Guid id, CancellationToken ct)
    {
        var articles = db.Articles.VisibleTo(currentUser);
        return type switch
        {
            ReportTargetType.Article => await articles.Where(a => a.Id == id).Select(a => new ReportedTarget(a.AuthorId)).FirstOrDefaultAsync(ct),
            ReportTargetType.Comment => await db.Comments
                .Where(c => c.Id == id && articles.Any(a => a.Id == c.ArticleId))
                .Select(c => new ReportedTarget(c.AuthorId))
                .FirstOrDefaultAsync(ct),
            _ => await db.Users.Where(u => u.Id == id).Select(u => new ReportedTarget(u.Id)).FirstOrDefaultAsync(ct),
        };
    }
}

internal sealed class ModerateContentCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IUserAccessService access,
    CommentPosting posting,
    AuditTrail audit,
    HybridCache cache,
    TimeProvider clock)
    : ICommandHandler<ModerateContentCommand, Result>
{
    private readonly record struct Acting(Guid ModeratorId, string? Note, DateTime Now);

    public async ValueTask<Result> Handle(ModerateContentCommand command, CancellationToken cancellationToken)
    {
        if (!ModerationValues.TryParseTarget(command.TargetType, out var targetType) || !ModerationVerbs.Allows(command.Action, targetType))
            return ModerationErrors.ActionInvalid;
        if ((command.Action is ModerationVerbs.Suspend or ModerationVerbs.Unsuspend) && !currentUser.Permissions.Contains(Permissions.Users.Suspend))
            return AuthErrors.Forbidden;

        var note = string.IsNullOrWhiteSpace(command.Note) ? null : command.Note.Trim();
        if (note is null && (command.Action is ModerationVerbs.Warn or ModerationVerbs.Suspend)) return ModerationErrors.NoteRequired;
        if (command.DurationDays is { } days &&
            (command.Action != ModerationVerbs.Suspend || days is < ModerationAction.MinSuspensionDays or > ModerationAction.MaxSuspensionDays))
            return ModerationErrors.DurationInvalid;

        var acting = new Acting(currentUser.RequireUserId(), note, clock.GetUtcNow().UtcDateTime);
        return targetType switch
        {
            ReportTargetType.Comment => await ModerateCommentAsync(command, acting, cancellationToken),
            ReportTargetType.Article => await ModerateArticleAsync(command, acting, cancellationToken),
            _ => await ModerateUserAsync(command, acting, cancellationToken),
        };
    }

    private async Task<Result> ModerateCommentAsync(ModerateContentCommand command, Acting acting, CancellationToken ct)
    {
        var comment = await db.Comments.IgnoreQueryFilters().FirstOrDefaultAsync(c => c.Id == command.TargetId, ct);
        // A deleted comment can only have its leftover reports dismissed.
        if (comment is null || (comment.IsDeleted && command.Action != ModerationVerbs.Dismiss)) return CommentErrors.NotFound;

        var changed = false;
        switch (command.Action)
        {
            case ModerationVerbs.Hide when !comment.IsHidden:
                comment.Hide(acting.ModeratorId, acting.Now);
                audit.Record(AuditActions.CommentHidden, comment.AuthorId);
                changed = true;
                break;
            case ModerationVerbs.Unhide when comment.IsHidden:
                comment.Unhide();
                audit.Record(AuditActions.CommentUnhidden, comment.AuthorId);
                changed = true;
                break;
            case ModerationVerbs.Delete:
                comment.DeleteByModerator(acting.Now);
                audit.Record(AuditActions.CommentDeleted, comment.AuthorId);
                changed = true;
                break;
        }
        var closed = await CloseReportsAsync(command, ReportTargetType.Comment, acting, ct);

        if (command.Action == ModerationVerbs.Dismiss)
        {
            if (closed > 0)
            {
                Log(ModerationAction.Dismissal(ReportTargetType.Comment, comment.Id, comment.AuthorId, comment.Body, acting.ModeratorId, acting.Note,
                    closed, acting.Now));
            }
        }
        else if (changed || closed > 0)
        {
            Log(ModerationAction.OnComment(LogCode(command.Action, ReportTargetType.Comment), comment.Id, comment.AuthorId, comment.Body,
                acting.ModeratorId, acting.Note, closed, acting.Now));
        }

        await db.SaveChangesAsync(ct);
        if (changed && comment.ParentId is { } parentId) await posting.RecountRepliesAsync(parentId, ct);
        return Result.Success();
    }

    private async Task<Result> ModerateArticleAsync(ModerateContentCommand command, Acting acting, CancellationToken ct)
    {
        var article = await db.Articles.IgnoreQueryFilters().FirstOrDefaultAsync(a => a.Id == command.TargetId, ct);
        if (article is null || (article.IsDeleted && command.Action != ModerationVerbs.Dismiss)) return ArticleErrors.NotFound;

        var changed = false;
        if (command.Action == ModerationVerbs.Hide && !article.IsHidden)
        {
            article.Hide(acting.ModeratorId, acting.Now);
            audit.Record(AuditActions.ArticleHidden, article.AuthorId);
            changed = true;
        }
        else if (command.Action == ModerationVerbs.Unhide && article.IsHidden)
        {
            article.Unhide();
            audit.Record(AuditActions.ArticleUnhidden, article.AuthorId);
            changed = true;
        }
        var closed = await CloseReportsAsync(command, ReportTargetType.Article, acting, ct);

        if (changed || closed > 0)
        {
            var title = await db.ArticleTranslations.AsNoTracking()
                .Where(t => t.ArticleId == article.Id && t.IsSource)
                .Select(t => t.Title)
                .FirstOrDefaultAsync(ct);
            Log(command.Action == ModerationVerbs.Dismiss
                ? ModerationAction.Dismissal(ReportTargetType.Article, article.Id, article.AuthorId, title, acting.ModeratorId, acting.Note, closed,
                    acting.Now)
                // Hiding an article that was already hidden only closed reports: its author was told the first time.
                : ModerationAction.OnArticle(LogCode(command.Action, ReportTargetType.Article), article.Id, article.AuthorId, title,
                    acting.ModeratorId, acting.Note, closed, acting.Now, notifyAuthor: changed));
        }

        await db.SaveChangesAsync(ct);
        if (changed) await cache.RemoveByTagAsync([CacheTags.Feed, CacheTags.Article(article.Slug), CacheTags.ArticleById(article.Id)], ct);
        return Result.Success();
    }

    private async Task<Result> ModerateUserAsync(ModerateContentCommand command, Acting acting, CancellationToken ct)
    {
        var user = await db.Users.IgnoreQueryFilters().FirstOrDefaultAsync(u => u.Id == command.TargetId, ct);
        if (user is null || (user.IsDeleted && command.Action != ModerationVerbs.Dismiss)) return UserErrors.NotFound;

        if (command.Action != ModerationVerbs.Dismiss)
        {
            if (user.Id == acting.ModeratorId) return ModerationErrors.Self;
            if (await IsStaffAsync(user, ct)) return ModerationErrors.StaffTarget;
        }

        var accessChanged = false;
        switch (command.Action)
        {
            case ModerationVerbs.Warn:
            {
                var resolved = await CloseReportsAsync(command, ReportTargetType.User, acting, ct);
                audit.Record(AuditActions.UserWarned, user.Id);
                Log(ModerationAction.Warning(user.Id, user.Username, acting.ModeratorId, acting.Note!, resolved, acting.Now));
                break;
            }
            case ModerationVerbs.Suspend:
            {
                DateTime? until = command.DurationDays is { } days ? acting.Now.AddDays(days) : null;
                accessChanged = !user.IsSuspendedAt(acting.Now) || user.SuspendedUntil != until;
                if (accessChanged)
                {
                    user.Suspend(until);
                    audit.Record(AuditActions.UserSuspended, user.Id);
                }
                var resolved = await CloseReportsAsync(command, ReportTargetType.User, acting, ct);
                if (accessChanged || resolved > 0)
                    Log(ModerationAction.Suspension(user.Id, user.Username, acting.ModeratorId, acting.Note!, until, resolved, acting.Now));
                break;
            }
            case ModerationVerbs.Unsuspend:
                if (user.IsSuspendedAt(acting.Now))
                {
                    audit.Record(AuditActions.UserUnsuspended, user.Id);
                    Log(ModerationAction.Unsuspension(user.Id, user.Username, acting.ModeratorId, acting.Note, acting.Now));
                }
                // A temporary suspension that already ended only has its flag cleared: nothing to log.
                accessChanged = user.IsSuspended;
                if (accessChanged) user.Unsuspend();
                break;
            default:
            {
                var dismissed = await CloseReportsAsync(command, ReportTargetType.User, acting, ct);
                if (dismissed > 0)
                {
                    Log(ModerationAction.Dismissal(ReportTargetType.User, user.Id, user.Id, $"@{user.Username}", acting.ModeratorId, acting.Note,
                        dismissed, acting.Now));
                }
                break;
            }
        }

        await db.SaveChangesAsync(ct);
        // The next request of the account is blocked (or let through) at once; the outbox handler of
        // UserRolesChangedDomainEvent drops the same cache entry a moment later.
        if (accessChanged) await access.InvalidateAsync(user.Id, ct);
        return Result.Success();
    }

    /// <summary>Staff can't be warned or suspended (SPEC F22): anyone who holds <c>moderation.manage</c>, and system accounts.</summary>
    private async Task<bool> IsStaffAsync(User user, CancellationToken ct) =>
        user.IsSystemAccount || (await access.GetAsync(user.Id, ct))?.Permissions.Contains(Permissions.Moderation.Manage) == true;

    /// <returns>How many open reports were closed.</returns>
    private async Task<int> CloseReportsAsync(ModerateContentCommand command, ReportTargetType targetType, Acting acting, CancellationToken ct)
    {
        if (!ModerationVerbs.ClosesReports(command.Action)) return 0;

        var dismiss = command.Action == ModerationVerbs.Dismiss;
        var closed = await CloseAsync(targetType, command.TargetId, dismiss, acting, ct);
        if (!dismiss && command.ResolveReportsOf is { } other && ModerationValues.TryParseTarget(other.TargetType, out var otherType) &&
            (otherType != targetType || other.TargetId != command.TargetId))
            closed += await CloseAsync(otherType, other.TargetId, dismiss: false, acting, ct);
        return closed;
    }

    private async Task<int> CloseAsync(ReportTargetType type, Guid id, bool dismiss, Acting acting, CancellationToken ct)
    {
        var open = await db.Reports
            .Where(r => r.TargetType == type && r.TargetId == id && r.Status == ReportStatus.Open)
            .ToListAsync(ct);
        foreach (var report in open)
        {
            if (dismiss) report.Dismiss(acting.ModeratorId, acting.Now);
            else report.Resolve(acting.ModeratorId, acting.Now);
        }
        return open.Count;
    }

    private void Log(ModerationAction action) => db.ModerationActions.Add(action);

    private static string LogCode(string action, ReportTargetType target) => (action, target) switch
    {
        (ModerationVerbs.Hide, ReportTargetType.Comment) => ModerationActionTypes.CommentHide,
        (ModerationVerbs.Unhide, ReportTargetType.Comment) => ModerationActionTypes.CommentUnhide,
        (ModerationVerbs.Delete, ReportTargetType.Comment) => ModerationActionTypes.CommentDelete,
        (ModerationVerbs.Hide, ReportTargetType.Article) => ModerationActionTypes.ArticleHide,
        (ModerationVerbs.Unhide, ReportTargetType.Article) => ModerationActionTypes.ArticleUnhide,
        _ => throw new ArgumentOutOfRangeException(nameof(action), action, "Not a content action."),
    };
}
