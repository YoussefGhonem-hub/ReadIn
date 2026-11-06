using System.Text.Json;
using System.Text.Json.Serialization;
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

    public NotificationDataDto ToDto() => new(Threshold, StreakDays, SecurityChange, Approved, ArticleIds?.Count);

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
