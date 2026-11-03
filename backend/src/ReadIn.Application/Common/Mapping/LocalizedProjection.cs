using Mapster;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Common.Mapping;

/// <summary>
/// Passes the request's languages into Mapster projections via <see cref="MapContext"/> (SPEC §6.4).
/// Mapping expressions read <see cref="Ui"/> / <see cref="Lang"/>; EF Core evaluates them once per query
/// and sends them as SQL parameters, so the right translation is picked in SQL.
/// </summary>
public static class LocalizedProjection
{
    private const string UiKey = "ui";
    private const string LangKey = "lang";

    /// <summary>UI language: <c>ar</c> | <c>en</c>.</summary>
    public static string Ui => (string)MapContext.Current!.Parameters[UiKey];

    /// <summary>Requested article language: <c>ar-EG</c> | <c>en</c> (empty = source language).</summary>
    public static string Lang => (string)MapContext.Current!.Parameters[LangKey];

    public static MapContextScope Begin(string uiLanguage, string? articleLanguage = null)
    {
        var scope = new MapContextScope();
        scope.Context.Parameters[UiKey] = UiLanguages.Normalize(uiLanguage);
        scope.Context.Parameters[LangKey] = ArticleLanguages.IsValid(articleLanguage) ? articleLanguage! : string.Empty;
        return scope;
    }
}
