using System.Globalization;
using System.Linq.Expressions;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Admin.Audit;
using ReadIn.Application.Features.Articles;
using ReadIn.Application.Features.Auth;
using ReadIn.Application.Features.Follows;
using ReadIn.Application.Features.Moderation;
using ReadIn.Application.Features.Search;
using ReadIn.Application.Features.Users;
using ReadIn.Application.Features.Verification;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Users;
using ReadIn.Domain.Verification;

namespace ReadIn.Application.Features.Admin.Users;

/// <summary>
/// Records that a signed-in account was seen (SPEC F23, contract decision 7): at most one write an hour per account, in
/// <c>UserPresence</c>, never on the <c>Users</c> row.
/// </summary>
public interface IPresenceTracker
{
    Task SeenAsync(Guid userId, CancellationToken cancellationToken);
}

/// <summary>A row of the console's users table (SPEC F23, contract <c>AdminUserRowDto</c>).</summary>
/// <param name="SignInMethods"><c>phone</c> (phone number + password), <c>google</c>, <c>apple</c>: the ways it can sign in now.</param>
/// <param name="PhoneMasked"><c>+20***1234</c>; null without a phone number.</param>
/// <param name="Status"><c>active</c> | <c>suspended</c> (suspended now).</param>
/// <param name="OpenReports">Open reports about the user, their articles and their comments.</param>
public record AdminUserRowDto(
    Guid Id,
    string DisplayName,
    string Username,
    string? AvatarUrl,
    bool IsVerified,
    bool IsSystemAccount,
    IReadOnlyList<string> Roles,
    IReadOnlyList<string> SignInMethods,
    string? PhoneMasked,
    DateTime JoinedAt,
    DateTime? LastSeenAt,
    int PublishedArticles,
    int Followers,
    string Status,
    DateTime? SuspendedUntil,
    int OpenReports);

public sealed record AdminUserStatsDto(
    int Drafts, int Comments, int Following, int TotalReads, int ArticlesRead, int CurrentStreak, int LongestStreak);

public sealed record AdminUserAccessDto(
    int ActiveSessions, bool HasRecoveryPin, bool RecoveryDisabled, bool MustChangePassword, bool MustSetRecoveryPin, DateTime? LockedOutUntil);

public sealed record AdminUserActionsDto(
    bool CanSuspend, bool CanWarn, bool CanLogoutAll, bool CanResetPassword, bool CanRemoveBadge, bool CanClearProfile, bool CanRestoreContent,
    bool CanRevealPhone);

public sealed record AdminUserModerationDto(
    int Warnings, int Suspensions, int HiddenArticles, int HiddenComments, int HiddenWithAccount, IReadOnlyList<ModerationActionDto> History,
    int HistoryTotal);

/// <param name="TargetLabel">The article's title, the comment's first 80 characters or <c>@username</c>; null once deleted.</param>
/// <param name="Reporter">In the "against" list; null in "filed", or once the reporter deleted the account.</param>
public sealed record AdminUserReportDto(
    Guid Id,
    ReportTargetType TargetType,
    Guid TargetId,
    string? TargetLabel,
    ReportReason Reason,
    string? Details,
    ReportStatus Status,
    DateTime CreatedAt,
    UserSummaryDto? Reporter);

public sealed record AdminUserReportsDto(
    IReadOnlyList<AdminUserReportDto> Against, int AgainstTotal, IReadOnlyList<AdminUserReportDto> Filed, int FiledTotal);

/// <summary>The newest items of a section, with how many there are.</summary>
public sealed record AdminListDto<T>(IReadOnlyList<T> Items, int Total);

/// <summary>A user's page in the console (SPEC F23, contract <c>AdminUserDto</c>): the row plus every section.</summary>
public sealed record AdminUserDto : AdminUserRowDto
{
    public AdminUserDto(AdminUserRowDto row) : base(row)
    {
    }

    public string? Headline { get; init; }
    public string? Bio { get; init; }
    public IReadOnlyList<ProfileLinkDto> Links { get; init; } = [];
    public string UiLanguage { get; init; } = UiLanguages.Arabic;

    /// <summary><c>phone</c> | <c>google</c> | <c>apple</c>; null for system accounts.</summary>
    public string? SignUpMethod { get; init; }

    /// <summary>Yourself, a holder of <c>admin.access</c> or <c>moderation.manage</c>, or a system account.</summary>
    public bool IsStaff { get; init; }

    public AdminUserStatsDto Stats { get; init; } = default!;
    public AdminUserAccessDto Access { get; init; } = default!;
    public AdminUserActionsDto Actions { get; init; } = default!;

    /// <summary>Null without <c>moderation.manage</c>.</summary>
    public AdminUserModerationDto? Moderation { get; init; }

    /// <summary>Null without <c>moderation.manage</c>.</summary>
    public AdminUserReportsDto? Reports { get; init; }

    /// <summary>The user's verification requests, newest first; null without <c>verification.manage</c>.</summary>
    public AdminListDto<AdminVerificationRequestDto>? Verification { get; init; }

    /// <summary>The member's support tickets (F35), newest 20; null without <c>support.manage</c>.</summary>
    public AdminListDto<Features.Support.AdminTicketRowDto>? Tickets { get; init; }

    /// <summary>Audit entries about the user, newest first; null without <c>audit.read</c>.</summary>
    public AdminListDto<AuditEntryDto>? Audit { get; init; }
}

public sealed record AdminPhoneDto(string? PhoneNumber);

/// <summary>
/// GET /admin/users (SPEC F23): every account (system ones too, deleted ones never), filtered, sorted and paged (offset,
/// ≤ 100). Parameters are text so a bad value is <c>400 validation.failed</c> on that parameter.
/// </summary>
/// <param name="Q">Name words, <c>@handle</c>, an account id, or (with <c>users.read.pii</c>) an exact phone number; ≤ 100.</param>
/// <param name="Status"><c>active</c> | <c>suspended</c>.</param>
/// <param name="Verified"><c>true</c> | <c>false</c>.</param>
/// <param name="Method"><c>phone</c> | <c>google</c> | <c>apple</c>.</param>
/// <param name="JoinedFrom">A local date (<c>Admin:TimeZone</c>), included.</param>
/// <param name="JoinedTo">A local date, included.</param>
/// <param name="HasReports"><c>true</c>: open reports about the user, their articles or comments.</param>
/// <param name="Sort"><c>joined</c> (default) | <c>lastSeen</c> | <c>followers</c> | <c>openReports</c>.</param>
/// <param name="Dir"><c>desc</c> (default) | <c>asc</c>.</param>
[RequirePermission(Permissions.Users.Read)]
public sealed record GetAdminUsersQuery(
    string? Q = null,
    string? Status = null,
    string? Verified = null,
    string? Method = null,
    string? JoinedFrom = null,
    string? JoinedTo = null,
    string? HasReports = null,
    string? Sort = null,
    string? Dir = null,
    int? Page = null,
    int? PageSize = null) : IQuery<Result<PagedList<AdminUserRowDto>>>
{
    public const int MaxQueryLength = 100;
}

/// <summary>GET /admin/users/{id} (SPEC F23): a user's page. <c>404 user.not_found</c> for an unknown or deleted account.</summary>
[RequirePermission(Permissions.Users.Read)]
public sealed record GetAdminUserQuery(Guid UserId) : IQuery<Result<AdminUserDto>>;

/// <summary>GET /admin/users/{id}/phone (SPEC F23): the full number, one at a time, audited <c>admin.pii_viewed</c>.</summary>
[RequirePermission(Permissions.Users.Read)]
[RequirePermission(Permissions.Users.ReadPii)]
public sealed record RevealUserPhoneCommand(Guid UserId) : ICommand<Result<AdminPhoneDto>>;

/// <summary>
/// POST /admin/users/{id}/logout-all (SPEC F23): ends every session of the account (a new security stamp, every refresh
/// token revoked). Not yourself, staff or a system account. Audited <c>admin.sessions_revoked</c>; the user is told nothing.
/// </summary>
[RequirePermission(Permissions.Users.Suspend)]
public sealed record AdminSignOutUserCommand(Guid UserId) : ICommand<Result>;

/// <summary>The SQL pieces shared by the list and the page (SPEC F23).</summary>
internal static class AdminUserQueries
{
    /// <summary>Open reports about the user, their articles and their comments.</summary>
    public static Expression<Func<User, int>> OpenReports(IAppDbContext db) => u => db.Reports.Count(r =>
        r.Status == ReportStatus.Open &&
        ((r.TargetType == ReportTargetType.User && r.TargetId == u.Id) ||
         (r.TargetType == ReportTargetType.Article && db.Articles.Any(a => a.Id == r.TargetId && a.AuthorId == u.Id)) ||
         (r.TargetType == ReportTargetType.Comment && db.Comments.Any(c => c.Id == r.TargetId && c.AuthorId == u.Id))));

    public static Expression<Func<User, int>> Followers(IAppDbContext db) => u => db.UserFollows.Count(f => f.FolloweeId == u.Id);

    public static Expression<Func<User, DateTime?>> LastSeen(IAppDbContext db) => u =>
        db.UserPresence.Where(p => p.UserId == u.Id).Select(p => (DateTime?)p.LastSeenAt).FirstOrDefault();

    public static bool IsSuspendedAt(bool isSuspended, DateTime? until, DateTime now) => isSuspended && (until is null || until > now);

    /// <summary>The rows of <paramref name="ids"/>, in that order; unknown ids are left out.</summary>
    public static async Task<List<AdminUserRowDto>> RowsAsync(
        IAppDbContext db, IFileStorage storage, IReadOnlyCollection<Guid> ids, DateTime now, CancellationToken ct)
    {
        if (ids.Count == 0) return [];
        var roleNames = await db.Roles.AsNoTracking().ToDictionaryAsync(r => r.Id, r => r.Name, ct);
        var users = await db.Users.AsNoTracking()
            .Where(u => ids.Contains(u.Id))
            .Select(u => new
            {
                u.Id,
                u.DisplayName,
                u.Username,
                u.AvatarUrl,
                u.IsVerified,
                u.IsSystemAccount,
                RoleIds = u.Roles.Select(r => r.RoleId).ToList(),
                PhoneAndPassword = u.PasswordHash != null && u.PhoneNumber != null,
                Providers = u.ExternalLogins.Select(l => l.Provider).ToList(),
                u.PhoneNumber,
                u.CreatedAt,
                u.IsSuspended,
                u.SuspendedUntil,
            })
            .ToListAsync(ct);

        var published = await db.Articles.AsNoTracking().Visible()
            .Where(a => a.AuthorId != null && ids.Contains(a.AuthorId.Value))
            .GroupBy(a => a.AuthorId!.Value)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.Key, g => g.Count, ct);
        var followers = await db.UserFollows.AsNoTracking()
            .Where(f => ids.Contains(f.FolloweeId))
            .GroupBy(f => f.FolloweeId)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.Key, g => g.Count, ct);
        var lastSeen = await db.UserPresence.AsNoTracking()
            .Where(p => ids.Contains(p.UserId))
            .ToDictionaryAsync(p => p.UserId, p => p.LastSeenAt, ct);
        var reports = await OpenReportCountsAsync(db, ids, ct);

        var byId = users.ToDictionary(u => u.Id);
        return [.. ids.Where(byId.ContainsKey).Select(id =>
        {
            var u = byId[id];
            var suspended = IsSuspendedAt(u.IsSuspended, u.SuspendedUntil, now);
            return new AdminUserRowDto(
                u.Id,
                u.DisplayName,
                u.Username,
                storage.ToPublicUrl(u.AvatarUrl),
                u.IsVerified,
                u.IsSystemAccount,
                [.. u.RoleIds.Select(r => roleNames.GetValueOrDefault(r)).OfType<string>().Order(StringComparer.Ordinal)],
                [.. (u.PhoneAndPassword ? [SignUpMethods.Phone] : Array.Empty<string>()), .. u.Providers.Order(StringComparer.Ordinal)],
                AdminPhones.Mask(u.PhoneNumber),
                u.CreatedAt,
                lastSeen.TryGetValue(id, out var seen) ? seen : (DateTime?)null,
                published.GetValueOrDefault(id),
                followers.GetValueOrDefault(id),
                suspended ? AdminUserStatuses.Suspended : AdminUserStatuses.Active,
                suspended ? u.SuspendedUntil : null,
                reports.GetValueOrDefault(id));
        })];
    }

    private static async Task<Dictionary<Guid, int>> OpenReportCountsAsync(IAppDbContext db, IReadOnlyCollection<Guid> ids, CancellationToken ct)
    {
        var open = db.Reports.AsNoTracking().Where(r => r.Status == ReportStatus.Open);
        var aboutUsers = await open
            .Where(r => r.TargetType == ReportTargetType.User && ids.Contains(r.TargetId))
            .GroupBy(r => r.TargetId)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToListAsync(ct);
        var aboutArticles = await open
            .Where(r => r.TargetType == ReportTargetType.Article)
            .Join(db.Articles.Where(a => a.AuthorId != null && ids.Contains(a.AuthorId.Value)), r => r.TargetId, a => a.Id, (r, a) => a.AuthorId!.Value)
            .GroupBy(id => id)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToListAsync(ct);
        var aboutComments = await open
            .Where(r => r.TargetType == ReportTargetType.Comment)
            .Join(db.Comments.Where(c => c.AuthorId != null && ids.Contains(c.AuthorId.Value)), r => r.TargetId, c => c.Id, (r, c) => c.AuthorId!.Value)
            .GroupBy(id => id)
            .Select(g => new { g.Key, Count = g.Count() })
            .ToListAsync(ct);
        return aboutUsers.Concat(aboutArticles).Concat(aboutComments)
            .GroupBy(x => x.Key)
            .ToDictionary(g => g.Key, g => g.Sum(x => x.Count));
    }
}

public static class AdminUserStatuses
{
    public const string Active = "active";
    public const string Suspended = "suspended";
}

internal sealed class GetAdminUsersQueryHandler(IAppDbContext db, ICurrentUser currentUser, IFileStorage storage, AdminClock clock)
    : IQueryHandler<GetAdminUsersQuery, Result<PagedList<AdminUserRowDto>>>
{
    public async ValueTask<Result<PagedList<AdminUserRowDto>>> Handle(GetAdminUsersQuery query, CancellationToken ct)
    {
        var now = clock.UtcNow;
        var users = db.Users.AsNoTracking();
        var exact = (Expression<Func<User, bool>>?)null;

        if (!string.IsNullOrWhiteSpace(query.Q))
        {
            var q = query.Q.Trim();
            if (q.Length > GetAdminUsersQuery.MaxQueryLength) return ValidationErrors.For("q", ["validation.max_length"]);
            var filter = Matching(q, out exact);
            if (filter is null) return Empty(query);
            users = users.Where(filter);
        }

        if (query.Status is { } status)
        {
            switch (status)
            {
                case AdminUserStatuses.Active:
                    users = users.Where(u => !u.IsSuspended || (u.SuspendedUntil != null && u.SuspendedUntil <= now));
                    break;
                case AdminUserStatuses.Suspended:
                    users = users.Where(u => u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now));
                    break;
                default:
                    return AdminErrors.InvalidParameter("status");
            }
        }
        if (query.Verified is { } verified)
        {
            if (!bool.TryParse(verified, out var isVerified)) return AdminErrors.InvalidParameter("verified");
            users = users.Where(u => u.IsVerified == isVerified);
        }
        if (query.Method is { } method)
        {
            if (!SignUpMethods.All.Contains(method)) return AdminErrors.InvalidParameter("method");
            users = method == SignUpMethods.Phone
                ? users.Where(u => u.PasswordHash != null && u.PhoneNumber != null)
                : users.Where(u => u.ExternalLogins.Any(l => l.Provider == method));
        }
        if (!TryDate(query.JoinedFrom, out var joinedFrom)) return AdminErrors.InvalidParameter("joinedFrom");
        if (!TryDate(query.JoinedTo, out var joinedTo)) return AdminErrors.InvalidParameter("joinedTo");
        var (from, to) = clock.Range(joinedFrom, joinedTo);
        if (from is { } f) users = users.Where(u => u.CreatedAt >= f);
        if (to is { } t) users = users.Where(u => u.CreatedAt < t);

        var openReports = AdminUserQueries.OpenReports(db);
        if (query.HasReports is { } hasReports)
        {
            if (!bool.TryParse(hasReports, out var withReports)) return AdminErrors.InvalidParameter("hasReports");
            users = withReports
                ? users.Where(openReports.Compose(count => count > 0))
                : users.Where(openReports.Compose(count => count == 0));
        }

        var descending = query.Dir switch
        {
            null or "desc" => true,
            "asc" => false,
            _ => (bool?)null,
        };
        if (descending is not { } desc) return AdminErrors.InvalidParameter("dir");

        IOrderedQueryable<User> ordered;
        var exactFirst = exact ?? (u => false);
        var withExact = users.OrderBy(exactFirst.Compose(isExact => isExact ? 0 : 1));
        switch (query.Sort)
        {
            case null or "joined":
                ordered = desc ? withExact.ThenByDescending(u => u.CreatedAt) : withExact.ThenBy(u => u.CreatedAt);
                break;
            case "followers":
                var followers = AdminUserQueries.Followers(db);
                ordered = desc ? withExact.ThenByDescending(followers) : withExact.ThenBy(followers);
                break;
            case "openReports":
                ordered = desc ? withExact.ThenByDescending(openReports) : withExact.ThenBy(openReports);
                break;
            case "lastSeen":
                // Accounts never seen come last either way.
                var lastSeen = AdminUserQueries.LastSeen(db);
                var seenFirst = withExact.ThenBy(lastSeen.Compose(seen => seen == null ? 1 : 0));
                ordered = desc ? seenFirst.ThenByDescending(lastSeen) : seenFirst.ThenBy(lastSeen);
                break;
            default:
                return AdminErrors.InvalidParameter("sort");
        }
        ordered = ordered.ThenBy(u => u.Id);

        var (page, pageSize) = AdminPaging.Normalize(query.Page, query.PageSize);
        var ids = await ordered.Select(u => u.Id).ToPagedListAsync(page, pageSize, ct);
        var rows = await AdminUserQueries.RowsAsync(db, storage, ids.Items, now, ct);
        return new PagedList<AdminUserRowDto>(rows, ids.Page, ids.PageSize, ids.TotalCount);
    }

    private static PagedList<AdminUserRowDto> Empty(GetAdminUsersQuery query)
    {
        var (page, pageSize) = AdminPaging.Normalize(query.Page, query.PageSize);
        return new PagedList<AdminUserRowDto>([], page, pageSize, 0);
    }

    /// <summary>
    /// What <paramref name="q"/> matches, and which of those come first: <c>@handle</c> → usernames starting with it; an id
    /// → that account; with <c>users.read.pii</c> a phone number → that number; otherwise name words or a username prefix.
    /// Null when nothing can match.
    /// </summary>
    private Expression<Func<User, bool>>? Matching(string q, out Expression<Func<User, bool>>? exact)
    {
        exact = null;
        if (Guid.TryParse(q, out var id))
        {
            exact = u => u.Id == id;
            return exact;
        }
        if (currentUser.Permissions.Contains(Permissions.Users.ReadPii) && LooksLikePhone(q) && PhoneNumberRules.TryNormalize(q, out var e164))
        {
            exact = u => u.PhoneNumber == e164;
            return exact;
        }

        var terms = SearchTerms.Parse(q);
        if (terms.IsFailure) return null;
        var words = terms.Value.Words;
        var handle = terms.Value.Handle;
        if (q.StartsWith('@'))
        {
            if (handle is null) return null;
            var prefix = SearchTerms.EscapeLike(handle) + "%";
            exact = u => u.Username == handle;
            return u => EF.Functions.Like(u.Username, prefix, SearchTerms.LikeEscape);
        }

        var phrase = terms.Value.Phrase;
        var handlePrefix = handle is null ? string.Empty : SearchTerms.EscapeLike(handle) + "%";
        Expression<Func<User, bool>> byName = u => true;
        foreach (var word in words)
        {
            var (plain, withArticle) = SearchTerms.WordStartPatterns(word);
            Expression<Func<User, bool>> matches = u =>
                EF.Functions.Like(" " + ArabicNormalizer.InSql(u.DisplayName), plain, SearchTerms.LikeEscape)
                || EF.Functions.Like(" " + ArabicNormalizer.InSql(u.DisplayName), withArticle, SearchTerms.LikeEscape);
            byName = byName.AndAlso(matches);
        }
        var handleValue = handle ?? string.Empty;
        exact = u => u.Username == handleValue || ArabicNormalizer.InSql(u.DisplayName) == phrase;
        if (words.Count == 0) return handle is null ? null : u => EF.Functions.Like(u.Username, handlePrefix, SearchTerms.LikeEscape);
        return byName.OrElse(u => EF.Functions.Like(u.Username, handlePrefix, SearchTerms.LikeEscape));
    }

    private static bool LooksLikePhone(string q) =>
        q.Count(c => char.IsDigit(c)) >= 6 && q.All(c => char.IsDigit(c) || c is '+' or ' ' or '-' or '(' or ')');

    private static bool TryDate(string? text, out DateOnly? date)
    {
        date = null;
        if (string.IsNullOrWhiteSpace(text)) return true;
        if (!DateOnly.TryParseExact(text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed)) return false;
        date = parsed;
        return true;
    }
}

internal sealed class GetAdminUserQueryHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IFileStorage storage,
    AdminClock clock,
    ProtectedAccounts protectedAccounts,
    IUserAccessService access,
    ModerationReader moderation,
    VerificationReader verification,
    ISender sender)
    : IQueryHandler<GetAdminUserQuery, Result<AdminUserDto>>
{
    private const int SectionSize = 20;

    public async ValueTask<Result<AdminUserDto>> Handle(GetAdminUserQuery query, CancellationToken ct)
    {
        var now = clock.UtcNow;
        var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == query.UserId, ct);
        if (user is null) return UserErrors.NotFound;
        var row = (await AdminUserQueries.RowsAsync(db, storage, [user.Id], now, ct)).Single();
        var permissions = currentUser.Permissions;

        var isSelf = user.Id == currentUser.UserId;
        var isStaff = isSelf || await protectedAccounts.IsStaffAsync(user.Id, user.IsSystemAccount, ct);
        var canModerate = permissions.Contains(Permissions.Moderation.Manage);
        var hiddenWithAccount = canModerate
            ? await db.Articles.CountAsync(a => a.AuthorId == user.Id && a.HiddenWithAccount, ct)
              + await db.Comments.CountAsync(c => c.AuthorId == user.Id && c.HiddenWithAccount, ct)
            : 0;
        var targetAccess = await access.GetAsync(user.Id, ct);

        var stats = await db.UserStats.AsNoTracking().Where(s => s.UserId == user.Id)
            .Select(s => new { s.TotalArticles, s.CurrentStreak, s.LongestStreak })
            .FirstOrDefaultAsync(ct);
        var dto = new AdminUserDto(row)
        {
            Headline = user.Headline,
            Bio = user.Bio,
            Links = user.Links.ToDtos(),
            UiLanguage = user.UiLanguage,
            SignUpMethod = user.SignUpMethod,
            IsStaff = isStaff,
            Stats = new AdminUserStatsDto(
                Drafts: await db.Articles.CountAsync(a => a.AuthorId == user.Id && a.Status == ArticleStatus.Draft, ct),
                Comments: await db.Comments.CountAsync(c => c.AuthorId == user.Id, ct),
                Following: await db.UserFollows.CountAsync(f => f.FollowerId == user.Id, ct),
                TotalReads: await db.Articles.Visible().Where(a => a.AuthorId == user.Id).SumAsync(a => a.ReadCount, ct),
                ArticlesRead: stats?.TotalArticles ?? 0,
                CurrentStreak: stats?.CurrentStreak ?? 0,
                LongestStreak: stats?.LongestStreak ?? 0),
            Access = new AdminUserAccessDto(
                ActiveSessions: await db.RefreshTokens
                    .Where(t => t.UserId == user.Id && t.RevokedAt == null && t.ExpiresAt > now)
                    .Select(t => t.FamilyId).Distinct().CountAsync(ct),
                HasRecoveryPin: user.HasRecoveryPin,
                RecoveryDisabled: user.RecoveryDisabled,
                MustChangePassword: user.MustChangePassword,
                MustSetRecoveryPin: user.MustSetRecoveryPin,
                LockedOutUntil: user.LockoutEndAt > now ? user.LockoutEndAt : null),
            Actions = new AdminUserActionsDto(
                CanSuspend: canModerate && permissions.Contains(Permissions.Users.Suspend) && !isStaff,
                CanWarn: canModerate && !isStaff,
                CanLogoutAll: permissions.Contains(Permissions.Users.Suspend) && !isStaff,
                CanResetPassword: permissions.Contains(Permissions.Users.ResetPassword) && user.CanSignInWithPassword
                    && (targetAccess is null || targetAccess.Permissions.All(permissions.Contains)),
                CanRemoveBadge: permissions.Contains(Permissions.Verification.Manage) && user.IsVerified && !user.IsSystemAccount,
                CanClearProfile: canModerate,
                CanRestoreContent: canModerate && hiddenWithAccount > 0,
                CanRevealPhone: permissions.Contains(Permissions.Users.ReadPii) && user.PhoneNumber is not null),
            Moderation = canModerate ? await ModerationAsync(user.Id, hiddenWithAccount, ct) : null,
            Reports = canModerate ? await ReportsAsync(user.Id, ct) : null,
            Verification = permissions.Contains(Permissions.Verification.Manage) ? await VerificationAsync(user.Id, ct) : null,
            Tickets = permissions.Contains(Permissions.Support.Manage) ? await TicketsAsync(user.Id, ct) : null,
            Audit = permissions.Contains(Permissions.Audit.Read) ? await AuditAsync(user.Id, ct) : null,
        };
        return dto;
    }

    private async Task<AdminUserModerationDto> ModerationAsync(Guid userId, int hiddenWithAccount, CancellationToken ct)
    {
        var about = db.ModerationActions.AsNoTracking().Where(a => a.TargetUserId == userId);
        var history = await about.OrderByDescending(a => a.CreatedAt).ThenByDescending(a => a.Id).Take(SectionSize).ToListAsync(ct);
        return new AdminUserModerationDto(
            Warnings: await about.CountAsync(a => a.Action == ModerationActionTypes.UserWarn, ct),
            Suspensions: await about.CountAsync(a => a.Action == ModerationActionTypes.UserSuspend, ct),
            HiddenArticles: await db.Articles.CountAsync(a => a.AuthorId == userId && a.HiddenAt != null, ct),
            HiddenComments: await db.Comments.CountAsync(c => c.AuthorId == userId && c.HiddenAt != null, ct),
            HiddenWithAccount: hiddenWithAccount,
            History: await moderation.ActionsAsync(history, ct),
            HistoryTotal: await about.CountAsync(ct));
    }

    private async Task<AdminUserReportsDto> ReportsAsync(Guid userId, CancellationToken ct)
    {
        var against = db.Reports.AsNoTracking().Where(r =>
            (r.TargetType == ReportTargetType.User && r.TargetId == userId) ||
            (r.TargetType == ReportTargetType.Article && db.Articles.IgnoreQueryFilters().Any(a => a.Id == r.TargetId && a.AuthorId == userId)) ||
            (r.TargetType == ReportTargetType.Comment && db.Comments.IgnoreQueryFilters().Any(c => c.Id == r.TargetId && c.AuthorId == userId)));
        var filed = db.Reports.AsNoTracking().Where(r => r.ReporterId == userId);

        var againstRows = await against.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id).Take(SectionSize).ToListAsync(ct);
        var filedRows = await filed.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id).Take(SectionSize).ToListAsync(ct);
        var labels = await LabelsAsync([.. againstRows, .. filedRows], ct);
        var reporters = await moderation.SummariesAsync(againstRows.Select(r => (Guid?)r.ReporterId), ct);

        AdminUserReportDto Map(Report r, bool withReporter) => new(
            r.Id, r.TargetType, r.TargetId, labels.GetValueOrDefault((r.TargetType, r.TargetId)), r.Reason, r.Details, r.Status, r.CreatedAt,
            withReporter ? reporters.GetValueOrDefault(r.ReporterId) : null);

        return new AdminUserReportsDto(
            [.. againstRows.Select(r => Map(r, withReporter: true))], await against.CountAsync(ct),
            [.. filedRows.Select(r => Map(r, withReporter: false))], await filed.CountAsync(ct));
    }

    /// <summary>The article's source title, the comment's first 80 characters, or <c>@username</c>, for deleted targets none.</summary>
    private async Task<Dictionary<(ReportTargetType, Guid), string>> LabelsAsync(IReadOnlyList<Report> reports, CancellationToken ct)
    {
        var labels = new Dictionary<(ReportTargetType, Guid), string>();
        var articleIds = reports.Where(r => r.TargetType == ReportTargetType.Article).Select(r => r.TargetId).Distinct().ToList();
        var commentIds = reports.Where(r => r.TargetType == ReportTargetType.Comment).Select(r => r.TargetId).Distinct().ToList();
        var userIds = reports.Where(r => r.TargetType == ReportTargetType.User).Select(r => r.TargetId).Distinct().ToList();

        foreach (var t in await db.ArticleTranslations.AsNoTracking()
                     .Where(t => articleIds.Contains(t.ArticleId) && t.IsSource)
                     .Select(t => new { t.ArticleId, t.Title }).ToListAsync(ct))
            labels[(ReportTargetType.Article, t.ArticleId)] = t.Title;
        foreach (var c in await db.Comments.AsNoTracking().Where(c => commentIds.Contains(c.Id)).Select(c => new { c.Id, c.Body }).ToListAsync(ct))
            labels[(ReportTargetType.Comment, c.Id)] = c.Body.Length <= 80 ? c.Body : c.Body[..80];
        foreach (var u in await db.Users.AsNoTracking().Where(u => userIds.Contains(u.Id)).Select(u => new { u.Id, u.Username }).ToListAsync(ct))
            labels[(ReportTargetType.User, u.Id)] = "@" + u.Username;
        return labels;
    }

    private async Task<AdminListDto<AdminVerificationRequestDto>> VerificationAsync(Guid userId, CancellationToken ct)
    {
        var requests = db.VerificationRequests.AsNoTracking().Where(r => r.UserId == userId);
        var rows = await requests.OrderByDescending(r => r.SubmittedAt).ThenByDescending(r => r.Id).Take(SectionSize).ToListAsync(ct);
        return new AdminListDto<AdminVerificationRequestDto>(await verification.AdminAsync(rows, ct), await requests.CountAsync(ct));
    }

    private async Task<AdminListDto<Features.Support.AdminTicketRowDto>> TicketsAsync(Guid userId, CancellationToken ct)
    {
        var tickets = db.SupportTickets.AsNoTracking().Where(t => t.UserId == userId);
        var rows = await Admin.Support.AdminTickets.RowsAsync(
            db, storage, tickets.OrderByDescending(t => t.CreatedAt).ThenByDescending(t => t.Id).Take(SectionSize), ct);
        return new AdminListDto<Features.Support.AdminTicketRowDto>(rows, await tickets.CountAsync(ct));
    }

    private async Task<AdminListDto<AuditEntryDto>?> AuditAsync(Guid userId, CancellationToken ct)
    {
        var page = await sender.Send(new GetAuditLogQuery(Target: userId.ToString(), PageSize: SectionSize), ct);
        return page.IsSuccess ? new AdminListDto<AuditEntryDto>(page.Value.Items, page.Value.TotalCount) : null;
    }
}

internal sealed class RevealUserPhoneCommandHandler(IAppDbContext db, AuditTrail audit)
    : ICommandHandler<RevealUserPhoneCommand, Result<AdminPhoneDto>>
{
    public async ValueTask<Result<AdminPhoneDto>> Handle(RevealUserPhoneCommand command, CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking()
            .Where(u => u.Id == command.UserId)
            .Select(u => new { u.Id, u.PhoneNumber })
            .FirstOrDefaultAsync(ct);
        if (user is null) return UserErrors.NotFound;
        if (user.PhoneNumber is not null)
        {
            audit.Record(AuditActions.PiiViewed, user.Id, AuditTargets.User, user.Id);
            await db.SaveChangesAsync(ct);
        }
        return new AdminPhoneDto(user.PhoneNumber);
    }
}

internal sealed class AdminSignOutUserCommandHandler(
    IAppDbContext db, ProtectedAccounts protectedAccounts, SessionIssuer sessions, IUserAccessService access, AuditTrail audit)
    : ICommandHandler<AdminSignOutUserCommand, Result>
{
    public async ValueTask<Result> Handle(AdminSignOutUserCommand command, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == command.UserId, ct);
        if (user is null) return UserErrors.NotFound;
        if (await protectedAccounts.CheckAsync(user.Id, user.IsSystemAccount, ct) is { } error) return error;

        // A new stamp rejects every access token at once; revoking the refresh tokens ends every session.
        user.RotateSecurityStamp();
        await sessions.RevokeAllAsync(user.Id, ct);
        audit.Record(AuditActions.SessionsRevoked, user.Id, AuditTargets.User, user.Id);
        await db.SaveChangesAsync(ct);
        await access.InvalidateAsync(user.Id, ct);
        return Result.Success();
    }
}

/// <summary>Combining small predicates into one expression EF can translate.</summary>
internal static class AdminExpressions
{
    public static Expression<Func<T, TResult>> Compose<T, TValue, TResult>(
        this Expression<Func<T, TValue>> inner, Expression<Func<TValue, TResult>> outer) =>
        Expression.Lambda<Func<T, TResult>>(new Replace(outer.Parameters[0], inner.Body).Visit(outer.Body)!, inner.Parameters);

    public static Expression<Func<T, bool>> AndAlso<T>(this Expression<Func<T, bool>> left, Expression<Func<T, bool>> right) =>
        Expression.Lambda<Func<T, bool>>(
            Expression.AndAlso(left.Body, new Replace(right.Parameters[0], left.Parameters[0]).Visit(right.Body)!), left.Parameters);

    public static Expression<Func<T, bool>> OrElse<T>(this Expression<Func<T, bool>> left, Expression<Func<T, bool>> right) =>
        Expression.Lambda<Func<T, bool>>(
            Expression.OrElse(left.Body, new Replace(right.Parameters[0], left.Parameters[0]).Visit(right.Body)!), left.Parameters);

    private sealed class Replace(Expression from, Expression to) : ExpressionVisitor
    {
        public override Expression? Visit(Expression? node) => node == from ? to : base.Visit(node);
    }
}
