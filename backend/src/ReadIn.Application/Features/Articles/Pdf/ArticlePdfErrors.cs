using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Pdf;

/// <summary>
/// Error codes of <c>GET /articles/{id}/pdf</c> (SPEC F33); clients translate them. Anyone but the author, and a draft,
/// get <see cref="Domain.Articles.ArticleErrors.NotFound"/> instead.
/// </summary>
public static class ArticlePdfErrors
{
    /// <summary>Hidden by moderators (F22): the file carries the ReadIn logo, so it isn't built.</summary>
    public static readonly Error Hidden = Error.Conflict("article.pdf_hidden", "Moderators hid this article, so it can't be downloaded as a PDF.");

    /// <summary>Both build slots stayed taken for 30 seconds.</summary>
    public static readonly Error Busy = Error.Unavailable("article.pdf_busy", "Many PDFs are being prepared right now. Try again in a moment.");

    /// <summary>The build failed or took more than 60 seconds.</summary>
    public static readonly Error Failed = Error.Failure("article.pdf_failed", "We couldn't prepare the PDF. Try again.");

    /// <summary>More than the hourly PDFs of one user (10 by default, per API instance).</summary>
    public static readonly Error Limit = Error.TooManyRequests("article.pdf_limit", "You've downloaded many PDFs this hour. Try again later.");
}
