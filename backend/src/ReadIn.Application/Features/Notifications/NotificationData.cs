using System.Text.Json;
using System.Text.Json.Serialization;
using ReadIn.Domain.Common;
using ReadIn.Domain.Users;

namespace ReadIn.Application.Features.Notifications;

/// <summary>
/// What <c>Notifications.Data</c> holds, as JSON (SPEC F17). <see cref="Threshold"/>, <see cref="StreakDays"/>,
/// <see cref="SecurityChange"/> and <see cref="Approved"/> reach clients (<see cref="NotificationDataDto"/>), and so does
/// the number of <see cref="ArticleIds"/>; the moderation notice's id and kind stay on the server for the push.
/// </summary>
public sealed record NotificationData
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web)
    {
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
    };

    public static readonly NotificationData Empty = new();

    public int? Threshold { get; init; }
    public int? StreakDays { get; init; }
    public SecurityChange? SecurityChange { get; init; }
    public Guid? NoticeId { get; init; }

    /// <summary><c>warning</c> | <c>article_hidden</c> (F22).</summary>
    public string? NoticeKind { get; init; }

    /// <summary><c>verification_result</c> (F19): the request was approved (true) or rejected (false).</summary>
    public bool? Approved { get; init; }

    /// <summary>
    /// The official account's day entry (<c>followed_writer_article</c>, <see cref="OfficialArticles"/>): the articles it
    /// holds, each once. Clients get only their number (<c>articleCount</c>).
    /// </summary>
    public IReadOnlyList<Guid>? ArticleIds { get; init; }

    /// <summary><c>announcement</c> (F23): which one, and its text in both languages (clients get it in theirs).</summary>
    public Guid? AnnouncementId { get; init; }
    public string? TitleAr { get; init; }
    public string? TitleEn { get; init; }
    public string? BodyAr { get; init; }
    public string? BodyEn { get; init; }

    /// <summary><c>announcement</c> linking to a learning path: its slug (an article link uses the entry's article).</summary>
    public string? PathSlug { get; init; }

    /// <summary>
    /// An announcement sent as a test to its author (F23): it comes at once, whatever their <c>announcement</c> mode and
    /// quiet hours.
    /// </summary>
    public bool? IsTest { get; init; }

    /// <summary><c>support_reply</c> and <c>support_ticket</c> (F35): the ticket, its number and subject.</summary>
    public Guid? TicketId { get; init; }
    public int? TicketNumber { get; init; }
    public string? Subject { get; init; }

    /// <summary><c>support_reply</c>: support closed the ticket (rather than replied).</summary>
    public bool? Closed { get; init; }

    /// <summary>
    /// What the entry last told about (<c>m:{messageId}</c> or <c>c:{ticks}</c>; server only), so a redelivered event changes
    /// nothing in an entry grouped without actors.
    /// </summary>
    public string? SourceKey { get; init; }

    public string? Serialize() => this == Empty ? null : JsonSerializer.Serialize(this, Json);

    /// <summary>Unreadable or missing data is empty rather than an error: the entry still shows.</summary>
    public static NotificationData Parse(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return Empty;
        try
        {
            return JsonSerializer.Deserialize<NotificationData>(json, Json) ?? Empty;
        }
        catch (JsonException)
        {
            return Empty;
        }
    }

    /// <param name="uiLanguage">The reader's UI language: an announcement's text comes in it (Arabic unless <c>en</c>).</param>
    public NotificationDataDto ToDto(string? uiLanguage = null)
    {
        var english = uiLanguage == UiLanguages.English;
        // A test announcement (IsTest) has the text but no announcement behind it.
        return new(Threshold, StreakDays, SecurityChange, Approved, ArticleIds?.Count, AnnouncementId,
            english ? TitleEn : TitleAr,
            english ? BodyEn : BodyAr,
            TicketId, TicketNumber, Subject, Closed);
    }

    /// <summary>The camelCase name clients get (<c>passwordChanged</c>), also used in dedupe keys.</summary>
    public static string Name(SecurityChange change) => JsonNamingPolicy.CamelCase.ConvertName(change.ToString());
}

/// <summary>A comment as a notification shows it: plain text on one line, never splitting a surrogate pair.</summary>
public static class NotificationExcerpt
{
    public const int MaxLength = 140;

    public static string Of(string? text, int maxLength = MaxLength)
    {
        if (string.IsNullOrWhiteSpace(text)) return string.Empty;
        var line = string.Join(' ', text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
        if (line.Length <= maxLength) return line;
        var cut = char.IsHighSurrogate(line[maxLength - 1]) ? maxLength - 1 : maxLength;
        return line[..cut];
    }
}
