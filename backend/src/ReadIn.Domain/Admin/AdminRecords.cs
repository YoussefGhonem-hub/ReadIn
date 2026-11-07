using ReadIn.Domain.Common;

namespace ReadIn.Domain.Admin;

/// <summary>
/// Searches that found nothing (SPEC §22, F23): one row per normalized query, language and day (in <c>Admin:TimeZone</c>),
/// counted, with no user id or IP. The dashboard lists the top ones; kept 90 days.
/// </summary>
public sealed class SearchMiss : Entity
{
    public const int MaxQueryLength = 100;
    public static readonly TimeSpan Retention = TimeSpan.FromDays(90);

    private SearchMiss() { } // EF

    public SearchMiss(DateOnly date, string language, string query, int count)
    {
        Date = date;
        Language = language;
        Query = query;
        Count = count;
    }

    public DateOnly Date { get; private set; }

    /// <summary><c>ar</c> when the query holds an Arabic letter, else <c>en</c>.</summary>
    public string Language { get; private set; } = default!;

    /// <summary>The cleaned, normalized query (≤ 100 characters).</summary>
    public string Query { get; private set; } = default!;

    public int Count { get; private set; }
}

/// <summary>
/// A broadcast to every reader, or the readers of a field or an article language (SPEC F23 announcements). Saving a new one
/// raises <see cref="AnnouncementSentDomainEvent"/>: the outbox writes the recipients' entries in batches.
/// </summary>
public sealed class Announcement : AggregateRoot
{
    public const int MaxTitleLength = 60;
    public const int MaxBodyLength = 180;

    private Announcement() { } // EF

    public Announcement(
        string titleAr, string titleEn, string bodyAr, string bodyEn, string? linkType, Guid? linkId, string audienceType, Guid? fieldId,
        string? language, Guid sentById, DateOnly localDate, int recipientCount, DateTime now)
    {
        TitleAr = titleAr;
        TitleEn = titleEn;
        BodyAr = bodyAr;
        BodyEn = bodyEn;
        LinkType = linkType;
        LinkId = linkId;
        AudienceType = audienceType;
        FieldId = fieldId;
        Language = language;
        SentById = sentById;
        LocalDate = localDate;
        RecipientCount = recipientCount;
        Status = AnnouncementStatus.Sending;
        CreatedAt = now;
        Raise(() => new AnnouncementSentDomainEvent(Id));
    }

    public string TitleAr { get; private set; } = default!;
    public string TitleEn { get; private set; } = default!;
    public string BodyAr { get; private set; } = default!;
    public string BodyEn { get; private set; } = default!;

    /// <summary><c>article</c> or <c>path</c>; null without a link.</summary>
    public string? LinkType { get; private set; }
    public Guid? LinkId { get; private set; }

    /// <summary><c>all</c>, <c>field</c> or <c>language</c> (<see cref="AnnouncementAudiences"/>).</summary>
    public string AudienceType { get; private set; } = default!;

    /// <summary>The field whose readers get it (<c>field</c> audience); no foreign key.</summary>
    public Guid? FieldId { get; private set; }

    /// <summary>The article language whose readers get it (<c>language</c> audience).</summary>
    public string? Language { get; private set; }

    /// <summary>Who sent it; no foreign key, account deletion nulls it (SPEC §9.6).</summary>
    public Guid? SentById { get; private set; }

    /// <summary>The calendar day in <c>Admin:TimeZone</c>; unique, so at most one announcement a day.</summary>
    public DateOnly LocalDate { get; private set; }

    public AnnouncementStatus Status { get; private set; }

    /// <summary>The preview's count while sending; the entries written once sent.</summary>
    public int RecipientCount { get; private set; }

    public DateTime CreatedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }

    public void MarkSent(int recipientCount, DateTime now)
    {
        Status = AnnouncementStatus.Sent;
        RecipientCount = recipientCount;
        CompletedAt = now;
    }

    public void ForgetSender() => SentById = null;
}

/// <summary>An announcement was saved: write its entries (SPEC F23). Idempotent, so a retried outbox event changes nothing.</summary>
public sealed record AnnouncementSentDomainEvent(Guid AnnouncementId) : DomainEvent;

public enum AnnouncementStatus : byte
{
    Sending = 0,
    Sent = 1,
}

public static class AnnouncementAudiences
{
    public const string All = "all";
    public const string Field = "field";
    public const string Language = "language";
}

public static class AnnouncementLinks
{
    public const string Article = "article";
    public const string Path = "path";
}

/// <summary>One run of a recurring background job (SPEC F23 system page): written by a Hangfire filter, kept 7 days.</summary>
public sealed class JobRun : Entity
{
    public const int MaxErrorLength = 500;
    public static readonly TimeSpan Retention = TimeSpan.FromDays(7);

    private JobRun() { } // EF

    public JobRun(string job, DateTime startedAt, int durationMs, bool succeeded, string? error)
    {
        Job = job;
        StartedAt = startedAt;
        DurationMs = durationMs;
        Succeeded = succeeded;
        Error = error is null ? null : error.Length <= MaxErrorLength ? error : error[..MaxErrorLength];
    }

    /// <summary>The recurring job's id, e.g. <c>notification-push</c>.</summary>
    public string Job { get; private set; } = default!;
    public DateTime StartedAt { get; private set; }
    public int DurationMs { get; private set; }
    public bool Succeeded { get; private set; }

    /// <summary>The exception's type and message (≤ 500); null for a success.</summary>
    public string? Error { get; private set; }
}

/// <summary>
/// Push sends of one UTC hour (SPEC F23 system page): devices reached, failures and invalid tokens removed, added up by a
/// wrapper around the push sender (F17 pushes and the daily article). Kept 7 days.
/// </summary>
public sealed class PushDeliveryStat
{
    public static readonly TimeSpan Retention = TimeSpan.FromDays(7);

    private PushDeliveryStat() { } // EF

    public PushDeliveryStat(DateTime hour, int sent, int failed, int invalidTokens)
    {
        Hour = hour;
        Sent = sent;
        Failed = failed;
        InvalidTokens = invalidTokens;
    }

    /// <summary>The start of the UTC hour: the key.</summary>
    public DateTime Hour { get; private set; }
    public int Sent { get; private set; }
    public int Failed { get; private set; }
    public int InvalidTokens { get; private set; }
}
