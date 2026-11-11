using System.Text;
using ReadIn.Domain.Common;

namespace ReadIn.Domain.Devotions;

/// <summary>
/// One of an account's own du'as in the private corner (SPEC F38, "أدعيتي"): an optional title and the text as written,
/// line breaks included. Only the account that wrote it ever sees it; it goes with the account (cascade, SPEC §9.6).
/// <see cref="UpdatedAt"/> equals <see cref="CreatedAt"/> until the first edit.
/// </summary>
public sealed class PersonalDua : Entity
{
    /// <summary>Du'as one account may have (<c>dua.limit</c>).</summary>
    public const int MaxPerUser = 200;

    /// <summary>Cleaned lengths in UTF-16 code units (<see cref="PersonalDuaText"/>): a title 0–100, a text 1–2,000.</summary>
    public const int MaxTitleLength = 100;
    public const int MaxTextLength = 2000;

    /// <summary>How many times it is said: the app counts it down like the adhkar (1–1,000, default 1).</summary>
    public const int DefaultRepeat = 1;
    public const int MaxRepeat = 1000;

    private PersonalDua() { } // EF

    /// <param name="title">Already cleaned by <see cref="PersonalDuaText.Title"/>: null or 1–100 characters on one line.</param>
    /// <param name="text">Already cleaned by <see cref="PersonalDuaText.Text"/>: 1–2,000 characters.</param>
    /// <param name="repeat">1–<see cref="MaxRepeat"/>.</param>
    public PersonalDua(Guid userId, string? title, string text, int repeat, DateTime now)
    {
        UserId = userId;
        Set(title, text, repeat);
        CreatedAt = now;
        UpdatedAt = now;
    }

    public Guid UserId { get; private set; }
    public string? Title { get; private set; }
    public string Text { get; private set; } = default!;
    public int Repeat { get; private set; } = DefaultRepeat;
    public DateTime CreatedAt { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    /// <summary>PATCH replaces all three: a null title clears it.</summary>
    public void Edit(string? title, string text, int repeat, DateTime now)
    {
        Set(title, text, repeat);
        UpdatedAt = now;
    }

    private void Set(string? title, string text, int repeat)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(repeat, 1);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(repeat, MaxRepeat);
        ArgumentException.ThrowIfNullOrWhiteSpace(text);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(text.Length, MaxTextLength, nameof(text));
        if (title is not null)
        {
            ArgumentException.ThrowIfNullOrWhiteSpace(title);
            ArgumentOutOfRangeException.ThrowIfGreaterThan(title.Length, MaxTitleLength, nameof(title));
        }
        Title = title;
        Text = text;
        Repeat = repeat;
    }
}

/// <summary>
/// How a du'a's text and title are cleaned before they are checked and stored (<c>docs/api/contract-v1.md</c>, "Private
/// devotions (F38)"): control characters other than line breaks are removed (tabs too) and both ends trimmed; inner
/// whitespace and line breaks are kept as written (a Windows <c>\r\n</c> or a lone <c>\r</c> is stored as <c>\n</c>). A
/// title is one line: its line breaks (<c>\n</c>, <c>\r</c>, U+2028, U+2029) become spaces, and an empty title is null.
/// Lengths are then checked by the caller, in UTF-16 code units.
/// </summary>
public static class PersonalDuaText
{
    private const char LineSeparator = (char)0x2028;
    private const char ParagraphSeparator = (char)0x2029;

    /// <summary>The cleaned text; empty when nothing is left (<c>validation.required</c>).</summary>
    public static string Text(string? raw) => Clean(raw, oneLine: false);

    /// <summary>The cleaned title on one line, or null when nothing is left.</summary>
    public static string? Title(string? raw) => Clean(raw, oneLine: true) is { Length: > 0 } title ? title : null;

    private static string Clean(string? raw, bool oneLine)
    {
        if (string.IsNullOrEmpty(raw)) return string.Empty;

        var lineBreak = oneLine ? ' ' : '\n';
        var text = new StringBuilder(raw.Length);
        for (var i = 0; i < raw.Length; i++)
        {
            var ch = raw[i];
            if (ch == '\r')
            {
                if (i + 1 < raw.Length && raw[i + 1] == '\n') i++;
                text.Append(lineBreak);
            }
            else if (ch == '\n' || (oneLine && ch is LineSeparator or ParagraphSeparator))
            {
                text.Append(lineBreak);
            }
            else if (!char.IsControl(ch))
            {
                text.Append(ch);
            }
        }
        return text.ToString().Trim();
    }
}

public static class PersonalDuaErrors
{
    /// <summary>No such du'a, or another account's: both answer the same.</summary>
    public static readonly Error NotFound = Error.NotFound("dua.not_found", "Du'a not found.");

    public static readonly Error Limit = Error.Conflict("dua.limit", $"You can have at most {PersonalDua.MaxPerUser} du'as.");
}
