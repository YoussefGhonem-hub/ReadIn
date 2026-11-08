using ReadIn.Domain.Common;

namespace ReadIn.Domain.Moderation;

/// <summary>Block: the text is refused. Flag: it is saved and a system report goes to the queue (SPEC F37).</summary>
public enum ContentFilterLevel : byte
{
    Block = 0,
    Flag = 1,
}

/// <summary>Where a term came from: the lists in <c>content/moderation/</c>, or an admin in the console.</summary>
public enum ContentFilterSource : byte
{
    File = 0,
    Console = 1,
}

/// <summary>
/// One term of the content filter (SPEC F37). File terms are seeded from <c>content/moderation/</c>; an admin can add,
/// re-level or remove terms in the console without a release. Removing a file term disables it (and marks it customized),
/// so the seeder never brings it back; a customized term's level is the admin's.
/// </summary>
public sealed class ContentFilterTerm : Entity
{
    public const int MinLength = 2;
    public const int MaxLength = 100;
    public const int MaxTerms = 5000;

    private ContentFilterTerm() { } // EF

    public ContentFilterTerm(
        string term, string normalizedTerm, string language, ContentFilterLevel level, ContentFilterSource source, DateTime now)
    {
        Term = term;
        NormalizedTerm = normalizedTerm;
        Language = language;
        Level = level;
        Source = source;
        IsEnabled = true;
        CreatedAt = now;
        UpdatedAt = now;
        if (source == ContentFilterSource.Console) CustomizedAt = now;
    }

    /// <summary>As written in the list.</summary>
    public string Term { get; private set; } = default!;

    /// <summary>The matcher's form (SPEC §22 normalization, lower case, repeats squeezed); unique.</summary>
    public string NormalizedTerm { get; private set; } = default!;

    /// <summary><c>ar</c> (MSA, Egyptian and Franco-Arabic spellings) or <c>en</c>: the list it belongs to.</summary>
    public string Language { get; private set; } = default!;

    public ContentFilterLevel Level { get; private set; }
    public ContentFilterSource Source { get; private set; }
    public bool IsEnabled { get; private set; }

    /// <summary>The first change in the console; the seeder leaves the row alone from then on.</summary>
    public DateTime? CustomizedAt { get; private set; }

    public DateTime CreatedAt { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    /// <summary>The console's change; returns whether anything changed.</summary>
    public bool SetByAdmin(ContentFilterLevel level, bool isEnabled, DateTime now)
    {
        if (Level == level && IsEnabled == isEnabled) return false;
        Level = level;
        IsEnabled = isEnabled;
        UpdatedAt = now;
        CustomizedAt ??= now;
        return true;
    }

    /// <summary>A file term that left the lists (the seeder): disabled, still not customized, so it comes back if listed again.</summary>
    public void DisableFromFile(DateTime now)
    {
        if (!IsEnabled) return;
        IsEnabled = false;
        UpdatedAt = now;
    }

    /// <summary>The seeder's update of a file term nobody customized; returns whether anything changed.</summary>
    public bool SyncFromFile(string term, string language, ContentFilterLevel level, DateTime now)
    {
        if (CustomizedAt is not null || (Term == term && Language == language && Level == level && IsEnabled)) return false;
        Term = term;
        Language = language;
        Level = level;
        IsEnabled = true;
        UpdatedAt = now;
        return true;
    }
}

/// <summary>The errors of the content filter and the spam limits (SPEC F37).</summary>
public static class ContentErrors
{
    public static readonly Error Objectionable = new(
        "content.objectionable", "This text breaks our Community Guidelines. Edit it and try again.", ErrorType.Unprocessable);

    public static readonly Error TooMany =
        Error.TooManyRequests("content.too_many", "You've reached the limit: 5 articles a day and 60 comments an hour.");

    /// <summary>The validation code of a term the console can't use.</summary>
    public const string TermInvalid = "content_filter.term_invalid";

    public const string ArticlesPerDay = "articles_per_day";
    public const string CommentsPerHour = "comments_per_hour";

    /// <summary><c>content.objectionable</c> naming the field (never the matched words).</summary>
    public static Error ObjectionableIn(string field, string? language = null, string? blockId = null)
    {
        var extensions = new Dictionary<string, object?> { ["field"] = field };
        if (language is not null) extensions["language"] = language;
        if (blockId is not null) extensions["blockId"] = blockId;
        return Objectionable with { Extensions = extensions };
    }

    public static Error TooManyOf(string limit) => TooMany with { Extensions = new Dictionary<string, object?> { ["limit"] = limit } };
}
