using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Admin;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Comments;
using ReadIn.Application.Features.Tags;
using ReadIn.Application.Features.Users;
using ReadIn.Application.Features.WriterCategories;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Taxonomy;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Moderation;

/// <summary>
/// POST /reports (SPEC F22): a reader reports an article, a comment, a user or a repost. Not their own content or
/// themselves; reporting the same target again is a no-op. Targets the reporter can't see (deleted, or a hidden article)
/// are not found. <paramref name="AlsoBlock"/> (F22 store requirements, F36) blocks the target's author in the same save;
/// <c>400 block.limit</c> saves neither.
/// </summary>
[RequirePermission(Permissions.Reports.Create)]
public sealed record ReportContentCommand(string TargetType, Guid TargetId, string Reason, string? Details, bool AlsoBlock = false)
    : ICommand<Result>;

/// <summary>
/// POST /moderation/actions (SPEC F22). Comments: hide, unhide, delete. Articles: hide, unhide. Users: warn, suspend,
/// unsuspend (both need <c>users.suspend</c>), clear_category (F31), clear_links and clear_headline (F14). Any target: dismiss its open reports. Hide, delete,
/// warn, suspend and clear_category resolve the target's open reports, and those of <see cref="ResolveReportsOf"/> too.
/// An action that changed something is logged in ModerationActions, and in the audit log when it touched a user's content
/// or account; repeating one that changes nothing is a no-op.
/// </summary>
/// <param name="Note">≤ 500; required to warn or suspend.</param>
/// <param name="DurationDays">Suspend only: 1–365, null = permanent.</param>
/// <param name="CategoryId">clear_category only (required there): one of the user's writer categories.</param>
/// <param name="HideContent">suspend only (SPEC F23): also hide all of the user's articles and comments (hide_content).</param>
[RequirePermission(Permissions.Moderation.Manage)]
public sealed record ModerateContentCommand(
    string Action,
    string TargetType,
    Guid TargetId,
    string? Note = null,
    int? DurationDays = null,
    ModerationTargetRef? ResolveReportsOf = null,
    Guid? CategoryId = null,
    bool? HideContent = null) : ICommand<Result>;

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

    /// <summary>Renames one of the user's writer categories to a neutral placeholder (SPEC F31).</summary>
    public const string ClearCategory = "clear_category";

    /// <summary>Removes all of the user's social links (SPEC F14).</summary>
    public const string ClearLinks = "clear_links";

    /// <summary>Removes the user's title (SPEC F14).</summary>
    public const string ClearHeadline = "clear_headline";

    /// <summary>Hides every article and comment of the user at once (SPEC F23), e.g. a spam account.</summary>
    public const string HideContent = "hide_content";

    /// <summary>Brings back what <see cref="HideContent"/> hid and is still hidden (SPEC F23).</summary>
    public const string UnhideContent = "unhide_content";

    public static bool Allows(string? action, ReportTargetType target) => (action, target) switch
    {
        (Hide or Unhide or Delete or Dismiss, ReportTargetType.Comment) => true,
        (Hide or Unhide or Dismiss, ReportTargetType.Article) => true,
        (Warn or Suspend or Unsuspend or ClearCategory or ClearLinks or ClearHeadline or HideContent or UnhideContent or Dismiss,
            ReportTargetType.User) => true,
        // A reported repost (F22 store requirements): removed, or its reports dismissed.
        (Delete or Dismiss, ReportTargetType.Repost) => true,
        _ => false,
    };

    /// <summary>The content actions on a user (F14, F31): allowed on anyone, staff and yourself included, like hiding content.</summary>
    public static bool IsProfileContent(string action) => action is ClearCategory or ClearLinks or ClearHeadline;

    /// <summary>Allowed on anyone, staff and yourself included: content actions, and <see cref="UnhideContent"/>, which only gives back.</summary>
    public static bool IsUnprotected(string action) => action is Dismiss or UnhideContent || IsProfileContent(action);

    /// <summary>
    /// Hide, delete, warn, suspend and the clears (category, links, title) resolve the target's open reports; dismiss closes
    /// them as dismissed.
    /// </summary>
    public static bool ClosesReports(string action) =>
        action is Hide or Delete or Warn or Suspend or ClearCategory or ClearLinks or ClearHeadline or Dismiss;
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
        When(c => c.Action == ModerationVerbs.ClearCategory, () => RuleFor(c => c.CategoryId).NotNull());
        When(c => c.ResolveReportsOf is not null, () =>
            RuleFor(c => c.ResolveReportsOf!.TargetType).Must(t => ModerationValues.TryParseTarget(t, out _)).WithErrorCode("report.target_invalid"));
    }
}

internal sealed class ReportContentCommandHandler(IAppDbContext db, ICurrentUser currentUser, Blocks.BlockRelations blocks, TimeProvider clock)
    : ICommandHandler<ReportContentCommand, Result>
{
    /// <param name="OwnerId">The article's or comment's author, the reposter, or the user itself; null for a deleted author.</param>
    private sealed record ReportedTarget(Guid? OwnerId);

    public async ValueTask<Result> Handle(ReportContentCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        ModerationValues.TryParseTarget(command.TargetType, out var targetType);
        ModerationValues.TryParseReason(command.Reason, out var reason);

        var target = await FindAsync(targetType, command.TargetId, cancellationToken);
        if (target is null) return ReportErrors.TargetNotFound;
        if (target.OwnerId == userId) return ReportErrors.OwnContent;

        var now = clock.GetUtcNow().UtcDateTime;
        // "Report and block" (F22 store requirements, F36): the author is blocked in the same save; a full block list saves
        // neither. A deleted author has nobody to block.
        if (command.AlsoBlock && target.OwnerId is { } ownerId)
        {
            var blocked = await blocks.BlockAsync(userId, ownerId, now, cancellationToken);
            if (blocked.IsFailure) return blocked.Error!;
        }

        if (await db.Reports.AnyAsync(r => r.ReporterId == userId && r.TargetType == targetType && r.TargetId == command.TargetId, cancellationToken))
        {
            if (command.AlsoBlock) await db.SaveChangesAsync(cancellationToken);
            return Result.Success();
        }

        db.Reports.Add(Report.File(targetType, command.TargetId, userId, reason, command.Details, now));
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
            // A repost of an article the reporter can open (its caption is the reposter's text).
            ReportTargetType.Repost => await db.Reposts
                .Where(r => r.Id == id && articles.Any(a => a.Id == r.ArticleId))
                .Select(r => new ReportedTarget(r.UserId))
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
    WriterCategoryReader categories,
    AuthorCaches authorCaches,
    ProtectedAccounts protectedAccounts,
    TimeProvider clock)
    : ICommandHandler<ModerateContentCommand, Result>
{
    /// <summary>What hide_content or unhide_content touched: the articles (whose cached pages go) and the threads to recount.</summary>
    private sealed record AccountContentChange(List<Article> Articles, int Comments, HashSet<Guid> Threads)
    {
        public bool Changed => Articles.Count > 0 || Comments > 0;
    }

    private readonly record struct Acting(Guid ModeratorId, string? Note, DateTime Now);

    public async ValueTask<Result> Handle(ModerateContentCommand command, CancellationToken cancellationToken)
    {
        if (!ModerationValues.TryParseTarget(command.TargetType, out var targetType) || !ModerationVerbs.Allows(command.Action, targetType))
            return ModerationErrors.ActionInvalid;
        if (command.HideContent == true && command.Action != ModerationVerbs.Suspend) return ModerationErrors.ActionInvalid;
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
            ReportTargetType.Repost => await ModerateRepostAsync(command, acting, cancellationToken),
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

    /// <summary>
    /// A reported repost (F22 store requirements): <c>delete</c> removes it, as if its owner had undone it (the counter
    /// follows), and resolves its reports; <c>dismiss</c> closes them. A repost that is gone can still be dismissed.
    /// </summary>
    private async Task<Result> ModerateRepostAsync(ModerateContentCommand command, Acting acting, CancellationToken ct)
    {
        var repost = await db.Reposts.FirstOrDefaultAsync(r => r.Id == command.TargetId, ct);
        if (repost is null && command.Action != ModerationVerbs.Dismiss) return ReportErrors.RepostNotFound;

        string? label = null;
        if (repost is not null)
        {
            label = repost.Caption ?? await db.ArticleTranslations.AsNoTracking()
                .Where(t => t.ArticleId == repost.ArticleId && t.IsSource)
                .Select(t => t.Title)
                .FirstOrDefaultAsync(ct);
        }

        var changed = false;
        if (command.Action == ModerationVerbs.Delete && repost is not null)
        {
            repost.Remove();
            db.Reposts.Remove(repost);
            audit.Record(AuditActions.RepostDeleted, repost.UserId);
            changed = true;
        }
        var closed = await CloseReportsAsync(command, ReportTargetType.Repost, acting, ct);

        if (command.Action == ModerationVerbs.Dismiss)
        {
            if (closed > 0)
                Log(ModerationAction.Dismissal(ReportTargetType.Repost, command.TargetId, repost?.UserId, label, acting.ModeratorId, acting.Note,
                    closed, acting.Now));
        }
        else if (changed)
        {
            Log(ModerationAction.OnRepost(command.TargetId, repost!.UserId, label, acting.ModeratorId, acting.Note, closed, acting.Now));
        }

        await db.SaveChangesAsync(ct);
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

        // Clearing a category name, the links or the title is about content, like hiding an article: allowed on anyone,
        // staff and yourself included. Staff (F23): holders of admin.access or moderation.manage, and system accounts.
        if (!ModerationVerbs.IsUnprotected(command.Action) &&
            await protectedAccounts.CheckAsync(user.Id, user.IsSystemAccount, ct) is { } protectedError)
            return protectedError;

        var accessChanged = false;
        var headlineCleared = false;
        List<string>? clearedCategoryArticles = null;
        AccountContentChange? contentChange = null;
        switch (command.Action)
        {
            case ModerationVerbs.HideContent:
                contentChange = await HideAccountContentAsync(user, acting, ct);
                if (!contentChange.Changed) return Result.Success();
                break;
            case ModerationVerbs.UnhideContent:
                contentChange = await UnhideAccountContentAsync(user, acting, ct);
                if (!contentChange.Changed) return Result.Success();
                break;
            case ModerationVerbs.ClearLinks:
            {
                // Nothing to clear: nothing to log, and the reports stay as they are (as for clear_category).
                var removed = string.Join(' ', user.Links.Select(l => l.Url));
                if (!user.ClearLinks()) return Result.Success();
                var resolved = await CloseReportsAsync(command, ReportTargetType.User, acting, ct);
                audit.Record(AuditActions.LinksCleared, user.Id);
                Log(ModerationAction.ProfileCleared(ModerationActionTypes.UserClearLinks, user.Id, removed, acting.ModeratorId, acting.Note,
                    resolved, acting.Now));
                break;
            }
            case ModerationVerbs.ClearHeadline:
            {
                var removed = user.Headline;
                if (!user.ClearHeadline()) return Result.Success();
                var resolved = await CloseReportsAsync(command, ReportTargetType.User, acting, ct);
                audit.Record(AuditActions.HeadlineCleared, user.Id);
                Log(ModerationAction.ProfileCleared(ModerationActionTypes.UserClearHeadline, user.Id, removed!, acting.ModeratorId, acting.Note,
                    resolved, acting.Now));
                headlineCleared = true;
                break;
            }
            case ModerationVerbs.ClearCategory:
            {
                var category = await db.WriterCategories.FirstOrDefaultAsync(c => c.Id == command.CategoryId && c.UserId == user.Id, ct);
                if (category is null) return WriterCategoryErrors.NotFound;
                // Already a placeholder: nothing to clear, nothing to log.
                if (WriterCategoryNames.IsPlaceholder(category.Name)) return Result.Success();

                var others = await db.WriterCategories.AsNoTracking()
                    .Where(c => c.UserId == user.Id && c.Id != category.Id)
                    .Select(c => new { c.NormalizedName, c.Slug })
                    .ToListAsync(ct);
                var usedNames = others.Select(c => c.NormalizedName).ToHashSet(StringComparer.Ordinal);
                var number = 1;
                while (usedNames.Contains(WriterCategoryNames.Normalize(WriterCategoryNames.Placeholder(user.UiLanguage, number)))) number++;
                var placeholder = WriterCategoryNames.Placeholder(user.UiLanguage, number);
                var slug = TagNames.UniqueSlug(WriterCategoryNames.SlugBase(placeholder), others.Select(c => c.Slug).ToHashSet(StringComparer.Ordinal));

                var oldName = category.Name;
                clearedCategoryArticles = await categories.ArticleSlugsAsync(category.Id, ct);
                category.ClearName(placeholder, WriterCategoryNames.Normalize(placeholder), slug);
                var resolved = await CloseReportsAsync(command, ReportTargetType.User, acting, ct);
                audit.Record(AuditActions.CategoryCleared, user.Id);
                Log(ModerationAction.CategoryCleared(user.Id, oldName, acting.ModeratorId, acting.Note, resolved, acting.Now));
                break;
            }
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
                // F23: "Also hide all of their articles and comments", in the same transaction.
                if (command.HideContent == true) contentChange = await HideAccountContentAsync(user, acting, ct);
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
        if (contentChange is { Changed: true }) await RefreshAccountContentAsync(contentChange, ct);
        // The next request of the account is blocked (or let through) at once; the outbox handler of
        // UserRolesChangedDomainEvent drops the same cache entry a moment later.
        if (accessChanged) await access.InvalidateAsync(user.Id, ct);
        // The writer's category list and pages, and the reader's "في قسم {name}" of its articles.
        if (clearedCategoryArticles is not null) await categories.InvalidateAsync(user.Id, clearedCategoryArticles, ct);
        // The title is on every card, the reader and comments of the user (F14): their cached pages go.
        if (headlineCleared) await authorCaches.DropAsync(user.Id, ct);
        return Result.Success();
    }

    /// <summary>
    /// hide_content (SPEC F23): every published or archived article and every comment of the user that isn't hidden or
    /// deleted, flagged as hidden with the account; the open reports of what it hid are resolved. No notices or pushes. Logged
    /// once on the user and audited, when it hid anything.
    /// </summary>
    private async Task<AccountContentChange> HideAccountContentAsync(User user, Acting acting, CancellationToken ct)
    {
        var articles = await db.Articles
            .Where(a => a.AuthorId == user.Id && a.Status != ArticleStatus.Draft && a.HiddenAt == null)
            .ToListAsync(ct);
        var comments = await db.Comments.Where(c => c.AuthorId == user.Id && c.HiddenAt == null).ToListAsync(ct);
        foreach (var article in articles) article.HideWithAccount(acting.ModeratorId, acting.Now);
        var threads = new HashSet<Guid>();
        foreach (var comment in comments)
        {
            if (comment.HideWithAccount(acting.ModeratorId, acting.Now) && comment.ParentId is { } parentId) threads.Add(parentId);
        }

        var articleIds = articles.Select(a => a.Id).ToList();
        var commentIds = comments.Select(c => c.Id).ToList();
        var open = await db.Reports
            .Where(r => r.Status == ReportStatus.Open &&
                ((r.TargetType == ReportTargetType.Article && articleIds.Contains(r.TargetId)) ||
                 (r.TargetType == ReportTargetType.Comment && commentIds.Contains(r.TargetId))))
            .ToListAsync(ct);
        foreach (var report in open) report.Resolve(acting.ModeratorId, acting.Now);

        var change = new AccountContentChange(articles, comments.Count, threads);
        if (change.Changed)
        {
            audit.Record(AuditActions.ContentHidden, user.Id, AuditTargets.User, user.Id, $"articles={articles.Count} comments={comments.Count}");
            Log(ModerationAction.AccountContent(ModerationActionTypes.UserHideContent, user.Id, user.Username, acting.ModeratorId, acting.Note,
                open.Count, acting.Now));
        }
        return change;
    }

    /// <summary>
    /// unhide_content (SPEC F23): unhides what hide_content hid and is still hidden; content hidden one by one stays hidden.
    /// Closed reports stay closed.
    /// </summary>
    private async Task<AccountContentChange> UnhideAccountContentAsync(User user, Acting acting, CancellationToken ct)
    {
        var articles = await db.Articles.Where(a => a.AuthorId == user.Id && a.HiddenWithAccount).ToListAsync(ct);
        var comments = await db.Comments.Where(c => c.AuthorId == user.Id && c.HiddenWithAccount).ToListAsync(ct);
        foreach (var article in articles) article.Unhide();
        var threads = new HashSet<Guid>();
        foreach (var comment in comments)
        {
            comment.Unhide();
            if (comment.ParentId is { } parentId) threads.Add(parentId);
        }

        var change = new AccountContentChange(articles, comments.Count, threads);
        if (change.Changed)
        {
            audit.Record(AuditActions.ContentRestored, user.Id, AuditTargets.User, user.Id, $"articles={articles.Count} comments={comments.Count}");
            Log(ModerationAction.AccountContent(ModerationActionTypes.UserUnhideContent, user.Id, user.Username, acting.ModeratorId, acting.Note,
                0, acting.Now));
        }
        return change;
    }

    /// <summary>After the commit: reply counts of the threads touched, and the cached pages of the articles touched.</summary>
    private async Task RefreshAccountContentAsync(AccountContentChange change, CancellationToken ct)
    {
        foreach (var parentId in change.Threads) await posting.RecountRepliesAsync(parentId, ct);
        if (change.Articles.Count == 0) return;
        await cache.RemoveByTagAsync(
            [CacheTags.Feed, CacheTags.Tags, .. change.Articles.SelectMany(a => new[] { CacheTags.Article(a.Slug), CacheTags.ArticleById(a.Id) })], ct);
    }

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
