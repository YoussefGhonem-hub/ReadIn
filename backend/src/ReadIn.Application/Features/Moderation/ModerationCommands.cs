using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Comments;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Moderation;

/// <summary>
/// POST /reports (SPEC F22): a reader reports content. F11 supports comments; articles and users come with F22, which
/// also adds the queue that reviews these reports. Reporting the same thing again is a no-op.
/// </summary>
[RequirePermission(Permissions.Reports.Create)]
public sealed record ReportContentCommand(string TargetType, Guid TargetId, string Reason, string? Details) : ICommand<Result>;

/// <summary>
/// POST /moderation/actions (SPEC F22 hooks in F11): a moderator hides, unhides or deletes a comment. Hiding or deleting
/// resolves the comment's open reports, and every action goes to the audit log.
/// </summary>
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record ModerateContentCommand(string Action, string TargetType, Guid TargetId) : ICommand<Result>;

public static class ModerationActions
{
    public const string Hide = "hide";
    public const string Unhide = "unhide";
    public const string Delete = "delete";

    public static readonly IReadOnlyList<string> All = [Hide, Unhide, Delete];
}

internal sealed class ReportContentCommandValidator : AbstractValidator<ReportContentCommand>
{
    public ReportContentCommandValidator()
    {
        RuleFor(c => c.TargetType).Must(t => Enum.TryParse<ReportTargetType>(t, ignoreCase: true, out _)).WithErrorCode("report.target_invalid");
        RuleFor(c => c.Reason).Must(r => Enum.TryParse<ReportReason>(r, ignoreCase: true, out _) && !int.TryParse(r, out _))
            .WithErrorCode("report.reason_invalid");
        RuleFor(c => c.Details).MaximumLength(Report.MaxDetailsLength);
    }
}

internal sealed class ModerateContentCommandValidator : AbstractValidator<ModerateContentCommand>
{
    public ModerateContentCommandValidator()
    {
        RuleFor(c => c.Action).Must(a => ModerationActions.All.Contains(a)).WithErrorCode("moderation.action_invalid");
        RuleFor(c => c.TargetType).Must(t => string.Equals(t, "comment", StringComparison.OrdinalIgnoreCase))
            .WithErrorCode(ReportErrors.TargetNotSupported.Code);
    }
}

internal sealed class ReportContentCommandHandler(IAppDbContext db, ICurrentUser currentUser, TimeProvider clock)
    : ICommandHandler<ReportContentCommand, Result>
{
    public async ValueTask<Result> Handle(ReportContentCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var targetType = Enum.Parse<ReportTargetType>(command.TargetType, ignoreCase: true);
        if (targetType != ReportTargetType.Comment) return ReportErrors.TargetNotSupported;

        var comment = await db.Comments.AsNoTracking()
            .Where(c => c.Id == command.TargetId)
            .Select(c => new { c.AuthorId })
            .FirstOrDefaultAsync(cancellationToken);
        if (comment is null) return ReportErrors.TargetNotFound;
        if (comment.AuthorId == userId) return ReportErrors.OwnContent;

        if (await db.Reports.AnyAsync(r => r.ReporterId == userId && r.TargetType == targetType && r.TargetId == command.TargetId, cancellationToken))
            return Result.Success();

        db.Reports.Add(Report.File(targetType, command.TargetId, userId, Enum.Parse<ReportReason>(command.Reason, ignoreCase: true),
            command.Details, clock.GetUtcNow().UtcDateTime));
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
}

internal sealed class ModerateContentCommandHandler(
    IAppDbContext db, ICurrentUser currentUser, CommentPosting posting, AuditTrail audit, TimeProvider clock)
    : ICommandHandler<ModerateContentCommand, Result>
{
    public async ValueTask<Result> Handle(ModerateContentCommand command, CancellationToken cancellationToken)
    {
        var moderatorId = currentUser.RequireUserId();
        var now = clock.GetUtcNow().UtcDateTime;
        var comment = await db.Comments.FirstOrDefaultAsync(c => c.Id == command.TargetId, cancellationToken);
        if (comment is null) return CommentErrors.NotFound;

        switch (command.Action)
        {
            case ModerationActions.Hide:
                comment.Hide(moderatorId, now);
                audit.Record(AuditActions.CommentHidden, comment.AuthorId);
                break;
            case ModerationActions.Unhide:
                comment.Unhide();
                audit.Record(AuditActions.CommentUnhidden, comment.AuthorId);
                break;
            default:
                comment.DeleteByModerator(now);
                audit.Record(AuditActions.CommentDeleted, comment.AuthorId);
                break;
        }

        if (command.Action != ModerationActions.Unhide)
        {
            var reports = await db.Reports
                .Where(r => r.TargetType == ReportTargetType.Comment && r.TargetId == comment.Id && r.Status == ReportStatus.Open)
                .ToListAsync(cancellationToken);
            foreach (var report in reports) report.Resolve(moderatorId, now);
        }

        await db.SaveChangesAsync(cancellationToken);
        if (comment.ParentId is { } parentId) await posting.RecountRepliesAsync(parentId, cancellationToken);
        return Result.Success();
    }
}
