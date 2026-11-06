using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.QuoteCards;

/// <summary>
/// Draws a quote card as a PNG (SPEC F24, ADR 0019) with the article PDFs' headless Chromium, sharing their build slots:
/// <see cref="QuoteCardErrors.Busy"/> when no slot frees up in time, <see cref="QuoteCardErrors.Failed"/> when drawing
/// fails or takes too long, <see cref="QuoteCardErrors.TooLong"/> if the quote fits no font size. Nothing is stored.
/// </summary>
public interface IQuoteCardRenderer
{
    Task<Result<byte[]>> RenderAsync(QuoteCard card, CancellationToken cancellationToken);
}
