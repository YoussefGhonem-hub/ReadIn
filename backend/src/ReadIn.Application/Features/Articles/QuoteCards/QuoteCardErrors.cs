using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.QuoteCards;

/// <summary>
/// Error codes of <c>POST /articles/{id}/quote-card</c> (SPEC F24, contract "Quote card (F24)"); clients translate them.
/// An article the caller can't open gets <see cref="Domain.Articles.ArticleErrors.NotFound"/> instead.
/// </summary>
public static class QuoteCardErrors
{
    /// <summary>The fewest UTF-16 code units a quote has after trimming (the same as a highlight).</summary>
    public const int MinLength = 3;

    /// <summary>The most UTF-16 code units a quote has after trimming: longer selections are refused, never cut.</summary>
    public const int MaxLength = 400;

    /// <summary>The version or block isn't there, or the offsets don't hold exactly that text.</summary>
    public static readonly Error TextMismatch =
        Error.Validation("quote.text_mismatch", "This text has changed in the article. Reload and try again.");

    /// <summary>Code, code tabs, table, steps, image, divider or embed: the blocks a highlight can't use either.</summary>
    public static readonly Error BlockNotAllowed = Error.Validation("quote.block_not_allowed", "This part can't be shared as a quote.");

    public static readonly Error TooShort = Error.Validation("quote.too_short", "Select at least 3 characters.");

    /// <summary>Over 400 after trimming (or, in theory, a quote that fits no card even with its line breaks as spaces).</summary>
    public static readonly Error TooLong = Error.Validation("quote.too_long", "A quote can be at most 400 characters. Select less text.");

    /// <summary>Hidden by moderators (F22), answered to its author and moderators: the card carries the ReadIn logo.</summary>
    public static readonly Error Hidden = Error.Conflict("quote.hidden", "Moderators hid this article, so its quotes can't be shared.");

    /// <summary>No Chromium build slot (shared with article PDFs) within the queue timeout.</summary>
    public static readonly Error Busy = Error.Unavailable("quote.busy", "Many cards are being prepared right now. Try again in a moment.");

    /// <summary>Drawing failed or ran out of time.</summary>
    public static readonly Error Failed = Error.Failure("quote.failed", "We couldn't prepare the quote card. Try again.");

    /// <summary>More than the hourly cards of one user (guests: one IP address), 30 by default, per API instance.</summary>
    public static readonly Error Limit = Error.TooManyRequests("quote.limit", "You've made many quote cards this hour. Try again later.");
}
