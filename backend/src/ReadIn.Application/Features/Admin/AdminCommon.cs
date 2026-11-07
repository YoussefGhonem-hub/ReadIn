using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using PhoneNumbers;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Admin;

/// <summary>The admin console's settings (SPEC F23): the time zone of its calendar days.</summary>
public sealed class AdminOptions
{
    public const string Section = "Admin";

    /// <summary>An IANA (or Windows) time zone id; the console's days, periods and date filters are in it.</summary>
    public string TimeZone { get; set; } = "Africa/Cairo";
}

/// <summary>A dashboard period (SPEC F23): <c>today</c>, <c>yesterday</c>, <c>7d</c> or <c>30d</c>.</summary>
public static class AdminPeriods
{
    public const string Today = "today";
    public const string Yesterday = "yesterday";
    public const string Last7Days = "7d";
    public const string Last30Days = "30d";

    public static readonly IReadOnlyList<string> All = [Today, Yesterday, Last7Days, Last30Days];

    public static bool IsKnown(string? period) => period is Today or Yesterday or Last7Days or Last30Days;
}

/// <summary>
/// A period's window and the previous one of the same length (SPEC F23 contract, decision 4). Times are UTC, ends exclusive;
/// dates are local, both ends included.
/// </summary>
public readonly record struct AdminWindow(
    DateTime FromUtc, DateTime ToUtc, DateOnly FromDate, DateOnly ToDate, DateTime PreviousFromUtc, DateTime PreviousToUtc,
    DateOnly PreviousFromDate, DateOnly PreviousToDate);

/// <summary>Calendar days in <c>Admin:TimeZone</c> (SPEC F23): periods, date filters and "one a day".</summary>
public sealed class AdminClock(IOptions<AdminOptions> options, TimeProvider clock)
{
    private TimeZoneInfo? _zone;

    public TimeZoneInfo Zone => _zone ??= ResolveZone(options.Value.TimeZone);

    public string TimeZoneId => options.Value.TimeZone;

    public DateTime UtcNow => clock.GetUtcNow().UtcDateTime;

    public DateOnly Today => LocalDate(UtcNow);

    public DateOnly LocalDate(DateTime utc) => DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(utc, Zone));

    /// <summary>The UTC instant of <paramref name="date"/>'s local midnight.</summary>
    public DateTime StartOfDayUtc(DateOnly date) => AdminWindows.ToUtc(date.ToDateTime(TimeOnly.MinValue), Zone);

    /// <summary>The next local midnight, as UTC: when "one a day" opens again.</summary>
    public DateTime NextMidnightUtc() => StartOfDayUtc(Today.AddDays(1));

    public AdminWindow Window(string period) => AdminWindows.For(period, UtcNow, Zone);

    /// <summary>A date filter (both ends included, either may be missing) as a UTC range with an exclusive end.</summary>
    public (DateTime? From, DateTime? To) Range(DateOnly? from, DateOnly? to) =>
        (from is { } f ? StartOfDayUtc(f) : null, to is { } t ? StartOfDayUtc(t.AddDays(1)) : null);

    public static TimeZoneInfo ResolveZone(string? id)
    {
        if (!string.IsNullOrWhiteSpace(id))
        {
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById(id);
            }
            catch (Exception e) when (e is TimeZoneNotFoundException or InvalidTimeZoneException)
            {
            }
        }
        return TimeZoneInfo.Utc;
    }
}

/// <summary>The period math of the dashboard (SPEC F23), pure so it can be tested in any time zone.</summary>
public static class AdminWindows
{
    public static AdminWindow For(string period, DateTime utcNow, TimeZoneInfo zone)
    {
        var localNow = TimeZoneInfo.ConvertTimeFromUtc(utcNow, zone);
        var today = DateOnly.FromDateTime(localNow);
        var (days, fromDate, toDate, toLocal) = period switch
        {
            AdminPeriods.Yesterday => (1, today.AddDays(-1), today.AddDays(-1), today.ToDateTime(TimeOnly.MinValue)),
            AdminPeriods.Last7Days => (7, today.AddDays(-6), today, localNow),
            AdminPeriods.Last30Days => (30, today.AddDays(-29), today, localNow),
            _ => (1, today, today, localNow),
        };
        var fromLocal = fromDate.ToDateTime(TimeOnly.MinValue);
        var toUtc = period == AdminPeriods.Yesterday ? ToUtc(toLocal, zone) : utcNow;
        var previousToUtc = ToUtc(toLocal.AddDays(-days), zone);
        return new AdminWindow(
            ToUtc(fromLocal, zone), toUtc, fromDate, toDate,
            ToUtc(fromLocal.AddDays(-days), zone), previousToUtc, fromDate.AddDays(-days), toDate.AddDays(-days));
    }

    /// <summary>A local wall-clock time as UTC; a time skipped by daylight saving moves to the first valid minute after it.</summary>
    public static DateTime ToUtc(DateTime local, TimeZoneInfo zone)
    {
        var unspecified = DateTime.SpecifyKind(local, DateTimeKind.Unspecified);
        while (zone.IsInvalidTime(unspecified)) unspecified = unspecified.AddMinutes(15);
        return TimeZoneInfo.ConvertTimeToUtc(unspecified, zone);
    }
}

/// <summary>Offset pages of the admin tables (SPEC §17.1): <c>page</c> from 1, <c>pageSize</c> 1–100, default 50.</summary>
public static class AdminPaging
{
    public const int DefaultPageSize = 50;
    public const int MaxPageSize = 100;

    public static (int Page, int PageSize) Normalize(int? page, int? pageSize) =>
        (Math.Max(1, page ?? 1), Math.Clamp(pageSize ?? DefaultPageSize, 1, MaxPageSize));

    /// <summary>One page of an already ordered query, with the total count.</summary>
    public static async Task<PagedList<T>> ToPagedListAsync<T>(this IQueryable<T> query, int page, int pageSize, CancellationToken ct)
    {
        var total = await query.CountAsync(ct);
        var items = total <= (page - 1) * pageSize
            ? []
            : await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);
        return new PagedList<T>(items, page, pageSize, total);
    }
}

/// <summary>The new error codes of the admin console (SPEC F23, contract "Admin console (F23)").</summary>
public static class AdminErrors
{
    public static readonly Error AnnouncementLimit =
        Error.TooManyRequests("announcement.limit", "An announcement was already sent today. You can send one a day.");
    public static readonly Error AnnouncementNoRecipients =
        Error.Validation("announcement.no_recipients", "This announcement has no recipients.");
    public static readonly Error AnnouncementLinkInvalid =
        Error.Validation("announcement.link_invalid", "The link must point to a published article or path.");
    public static readonly Error FieldSlugTaken = Error.Conflict("field.slug_taken", "Another field uses this slug.");
    public static readonly Error TopicSlugTaken = Error.Conflict("topic.slug_taken", "Another topic in this field uses this slug.");
    public static readonly Error OrderInvalid = Error.Validation("admin.order_invalid", "The list must hold every item exactly once.");
    public static readonly Error TagNameTaken =
        Error.Conflict("tag.name_taken", "Another tag already has this name. If they're the same, merge them.");
    public static readonly Error TagMergeSelf = Error.Validation("tag.merge_self", "A tag can't be merged into itself.");
    public static readonly Error PathFeaturedInvalid = Error.Validation("path.featured_invalid", "Choose up to 20 different existing paths.");

    /// <summary>Validation codes in <c>errors</c>.</summary>
    public const string FieldIconInvalid = "field.icon_invalid";
    public const string FieldColorInvalid = "field.color_invalid";

    /// <summary><c>400 validation.failed</c> with <c>validation.invalid</c> on a query parameter (an unknown filter or sort value).</summary>
    public static Error InvalidParameter(string parameter) => ValidationErrors.For(parameter, ["validation.invalid"]);

    /// <summary><c>tag.name_taken</c> with the tag that has the name, so the console can offer a merge.</summary>
    public static Error TagNameTakenBy(Guid tagId, string tagSlug) =>
        TagNameTaken with { Extensions = new Dictionary<string, object?> { ["tagId"] = tagId, ["tagSlug"] = tagSlug } };
}

/// <summary>
/// Accounts nobody suspends, warns, signs out or hides the content of (SPEC F23, contract decision 2): yourself, a holder of
/// <c>admin.access</c> or <c>moderation.manage</c>, and system accounts (the official @readin).
/// </summary>
public sealed class ProtectedAccounts(IUserAccessService access, ICurrentUser currentUser)
{
    /// <summary>Staff: a system account, or an account holding <c>admin.access</c> or <c>moderation.manage</c>.</summary>
    public async Task<bool> IsStaffAsync(Guid userId, bool isSystemAccount, CancellationToken ct)
    {
        if (isSystemAccount) return true;
        var permissions = (await access.GetAsync(userId, ct))?.Permissions;
        return permissions is not null &&
            (permissions.Contains(Permissions.Admin.Access) || permissions.Contains(Permissions.Moderation.Manage));
    }

    /// <summary><c>moderation.self</c> for yourself, <c>moderation.staff_target</c> for staff, null when allowed.</summary>
    public async Task<Error?> CheckAsync(Guid userId, bool isSystemAccount, CancellationToken ct)
    {
        if (userId == currentUser.UserId) return ModerationErrors.Self;
        return await IsStaffAsync(userId, isSystemAccount, ct) ? ModerationErrors.StaffTarget : null;
    }
}

/// <summary>Phone numbers in the console's lists (SPEC F23): masked as <c>+20***1234</c>.</summary>
public static class AdminPhones
{
    private static readonly PhoneNumberUtil Util = PhoneNumberUtil.GetInstance();

    /// <summary>The country code, <c>***</c> and the last 4 digits; null without a number.</summary>
    public static string? Mask(string? e164)
    {
        if (string.IsNullOrEmpty(e164)) return null;
        var digits = e164.TrimStart('+');
        string countryCode;
        try
        {
            countryCode = Util.Parse(e164, null).CountryCode.ToString(System.Globalization.CultureInfo.InvariantCulture);
        }
        catch (NumberParseException)
        {
            countryCode = digits.Length > 2 ? digits[..2] : digits;
        }
        var last = digits.Length >= 4 ? digits[^4..] : digits;
        return $"+{countryCode}***{last}";
    }
}
