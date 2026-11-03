using System.Text;

namespace ReadIn.Application.Common.Content;

/// <summary>
/// Search normalization applied to <c>SearchText</c> and to queries (SPEC §22): strips diacritics and tatweel,
/// unifies أ إ آ ٱ → ا, ى → ي, ة → ه, lower-cases Latin and collapses whitespace.
/// </summary>
public static class ArabicNormalizer
{
    public static string Normalize(string? text)
    {
        if (string.IsNullOrEmpty(text)) return string.Empty;

        var sb = new StringBuilder(text.Length);
        var pendingSpace = false;

        foreach (var ch in text)
        {
            if (char.IsWhiteSpace(ch))
            {
                pendingSpace = sb.Length > 0;
                continue;
            }

            if (IsRemoved(ch)) continue;

            if (pendingSpace)
            {
                sb.Append(' ');
                pendingSpace = false;
            }
            sb.Append(Map(ch));
        }

        return sb.ToString();
    }

    private static bool IsRemoved(char ch) =>
        ch is >= 'ً' and <= 'ٟ'   // harakat / tashkeel
            or 'ٰ'                     // superscript alef
            or >= 'ۖ' and <= 'ۭ'  // Quranic annotation marks
            or 'ـ';                    // tatweel

    private static char Map(char ch) => ch switch
    {
        'أ' or 'إ' or 'آ' or 'ٱ' => 'ا', // أ إ آ ٱ → ا
        'ى' => 'ي',                                       // ى → ي
        'ة' => 'ه',                                       // ة → ه
        _ => char.ToLowerInvariant(ch),
    };
}
