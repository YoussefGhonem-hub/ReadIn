namespace ReadIn.Domain.Common;

/// <summary>UI language axis (SPEC §14.1): controls app strings and layout direction.</summary>
public static class UiLanguages
{
    public const string Arabic = "ar";
    public const string English = "en";

    public static readonly IReadOnlyList<string> All = [Arabic, English];

    public static bool IsValid(string? value) => value is Arabic or English;

    public static string Normalize(string? value) =>
        value is not null && value.StartsWith(English, StringComparison.OrdinalIgnoreCase) ? English : Arabic;
}

/// <summary>Article language axis (SPEC §14.1): which version of an article is shown.</summary>
public static class ArticleLanguages
{
    public const string EgyptianArabic = "ar-EG";
    public const string English = "en";

    public static readonly IReadOnlyList<string> All = [EgyptianArabic, English];

    public static bool IsValid(string? value) => value is EgyptianArabic or English;

    /// <summary>
    /// The version a guest gets on cards (they have no <c>ArticleLanguagePref</c>): the one that matches the UI, so an
    /// Arabic page shows Egyptian Arabic titles where a translation exists; the source language stays the fallback.
    /// </summary>
    public static string ForUi(string? uiLanguage) =>
        UiLanguages.Normalize(uiLanguage) == UiLanguages.English ? English : EgyptianArabic;
}

public enum ThemePreference
{
    System = 0,
    Light = 1,
    Dark = 2,
}
