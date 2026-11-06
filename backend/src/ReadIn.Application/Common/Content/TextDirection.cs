namespace ReadIn.Application.Common.Content;

/// <summary>
/// Text direction as the readers resolve it (SPEC §14.2 rule 1): the first strong character, what <c>dir="auto"</c> does,
/// else the article's language. The character classes are those of the web's <c>detectDir</c> and of the PDF's
/// <c>BidiText</c> (Infrastructure), which a test keeps equal.
/// </summary>
public static class TextDirection
{
    public const string Rtl = "rtl";
    public const string Ltr = "ltr";

    /// <summary>The direction of an article language: <c>ltr</c> for <c>en</c>, <c>rtl</c> for <c>ar-EG</c>.</summary>
    public static string OfLanguage(string language) => language == "en" ? Ltr : Rtl;

    /// <summary>The direction of the first strong character, or null when there is none.</summary>
    public static string? FirstStrong(string? text)
    {
        if (string.IsNullOrEmpty(text)) return null;
        foreach (var ch in text)
        {
            if (IsRtl(ch)) return Rtl;
            if (IsLtr(ch)) return Ltr;
        }
        return null;
    }

    private static bool IsRtl(char ch) => ch is >= '֐' and <= 'ࣿ' or >= 'יִ' and <= '﷿' or >= 'ﹰ' and <= '﻿';

    private static bool IsLtr(char ch) =>
        ch is >= 'A' and <= 'Z' or >= 'a' and <= 'z' or >= 'À' and <= 'ʸ' or >= 'Ͱ' and <= 'Ͽ' or >= 'Ѐ' and <= 'ӿ';
}
