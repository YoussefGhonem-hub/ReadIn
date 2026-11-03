using System.Text;

namespace ReadIn.Application.Common.Content;

/// <summary>
/// Search normalization applied to <c>SearchText</c> and to queries (SPEC §22): strips diacritics and tatweel,
/// unifies أ إ آ ٱ → ا, ى → ي, ة → ه, lower-cases Latin and collapses whitespace.
/// </summary>
public static class ArabicNormalizer
{
    /// <summary>
    /// Applies the same character rules to a column inside an EF Core query (Infrastructure maps it to
    /// <c>REPLACE(TRANSLATE(column, SqlFrom, SqlTo), 'ـ', '')</c>). Needed because SQL Server's <c>Arabic_100_CI_AI</c>
    /// ignores case but not Arabic diacritics. Compare the result with a <see cref="Normalize"/>d query; the column's
    /// case-insensitive collation still applies, so Latin case doesn't matter.
    /// </summary>
    public static string InSql(string column) =>
        throw new NotSupportedException($"{nameof(InSql)} is translated to SQL and runs only inside EF Core queries.");

    /// <summary>TRANSLATE turns every removed character into tatweel, which the rules remove too; REPLACE then drops it.</summary>
    public const char Tatweel = 'ـ';

    /// <summary>Characters <see cref="InSql"/> translates, and what each becomes (<see cref="Tatweel"/> = removed).</summary>
    public static readonly (string From, string To) SqlTranslation = BuildSqlTranslation();

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

    /// <summary>Derived from <see cref="IsRemoved"/> and <see cref="Map"/>, so the SQL rules never drift from these.</summary>
    private static (string From, string To) BuildSqlTranslation()
    {
        var from = new StringBuilder();
        var to = new StringBuilder();
        for (var ch = '؀'; ch <= 'ۿ'; ch++)
        {
            if (ch == Tatweel) continue;
            if (IsRemoved(ch))
            {
                from.Append(ch);
                to.Append(Tatweel);
            }
            else if (Map(ch) != ch)
            {
                from.Append(ch);
                to.Append(Map(ch));
            }
        }
        return (from.ToString(), to.ToString());
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
