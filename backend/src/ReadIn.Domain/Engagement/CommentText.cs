using System.Text.RegularExpressions;
using ReadIn.Domain.Common;

namespace ReadIn.Domain.Engagement;

/// <summary>Comment text rules (SPEC F11): normalizing, @mentions and the duplicate check.</summary>
public static partial class CommentText
{
    /// <summary>
    /// Trims the text and the end of each line, unifies line breaks and keeps at most one empty line in a row. Mixed
    /// Arabic/English is kept as is.
    /// </summary>
    public static Result<string> Normalize(string? body)
    {
        var lines = (body ?? string.Empty).Replace("\r\n", "\n").Replace('\r', '\n').Split('\n').Select(l => l.TrimEnd());
        var text = ExtraBlankLines().Replace(string.Join('\n', lines).Trim(), "\n\n");
        if (text.Length == 0) return CommentErrors.Empty;
        if (text.Length > Comment.MaxBodyLength) return CommentErrors.TooLong;
        return text;
    }

    /// <summary>
    /// The @usernames in <paramref name="text"/>, lowercase, distinct, in order, at most <see cref="Comment.MaxMentions"/>.
    /// A username follows the profile rules (3–30 of a–z, 0–9, _); "a@b" (an email) is not a mention.
    /// </summary>
    public static IReadOnlyList<string> MentionedUsernames(string text) =>
        [.. Mention().Matches(text).Select(m => m.Groups[1].Value.ToLowerInvariant()).Distinct().Take(Comment.MaxMentions)];

    /// <summary>What two comments must share to count as the same text: case and spacing don't matter.</summary>
    public static string DuplicateKey(string text) => Whitespace().Replace(text, " ").Trim().ToLowerInvariant();

    [GeneratedRegex(@"\n{3,}")]
    private static partial Regex ExtraBlankLines();

    // Not after a Latin letter, digit, _, . or @ (that's an email), but fine after an Arabic letter: "و@writer1" is
    // "and @writer1".
    [GeneratedRegex(@"(?<![A-Za-z0-9_@.])@([A-Za-z0-9_]{3,30})(?![A-Za-z0-9_])")]
    private static partial Regex Mention();

    [GeneratedRegex(@"\s+")]
    private static partial Regex Whitespace();
}
