using ReadIn.Application.Common.Interfaces;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Feed.DailyArticle;

/// <summary>
/// The "مقال النهارده جاهز ☕" push (SPEC F07, §21.1). The title is in the user's UI language, the body is the article
/// title in the version the user reads. The data payload is documented in docs/api/contract-v1.md ("Push payloads").
/// </summary>
public static class DailyArticlePush
{
    /// <summary><c>data.type</c>, also the collapse key: a newer daily push replaces an unread older one.</summary>
    public const string Type = "daily_article";

    public const string TitleAr = "مقال النهارده جاهز ☕";
    public const string TitleEn = "Today's article is ready ☕";

    /// <param name="articleLanguage">The version the user reads (<c>ar-EG</c> | <c>en</c>); the web opens <c>/{ar|en}/a/{slug}</c>.</param>
    public static PushNotification Create(
        IReadOnlyList<string> tokens,
        string uiLanguage,
        Guid articleId,
        string slug,
        string articleTitle,
        string articleLanguage,
        TimeSpan timeToLive) =>
        new(
            tokens,
            uiLanguage == UiLanguages.English ? TitleEn : TitleAr,
            articleTitle,
            new Dictionary<string, string>
            {
                ["type"] = Type,
                ["articleId"] = articleId.ToString(),
                ["slug"] = slug,
                ["link"] = $"readin://a/{Uri.EscapeDataString(slug)}",
                ["lang"] = articleLanguage == ArticleLanguages.English ? "en" : "ar",
            },
            Type,
            timeToLive);
}
