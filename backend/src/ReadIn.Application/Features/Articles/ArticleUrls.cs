using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;

namespace ReadIn.Application.Features.Articles;

/// <summary>Projections read stored values from SQL; this turns uploaded covers and avatars into absolute URLs (ADR 0010).</summary>
internal static class ArticleUrls
{
    public static TCard WithPublicUrls<TCard>(this TCard card, IFileStorage storage) where TCard : ArticleCardDto =>
        // `with` on the base type keeps the runtime type, so details stay details.
        (TCard)((ArticleCardDto)card with
        {
            CoverUrl = storage.ToPublicUrl(card.CoverUrl),
            Author = card.Author with { AvatarUrl = storage.ToPublicUrl(card.Author.AvatarUrl) },
        });
}
