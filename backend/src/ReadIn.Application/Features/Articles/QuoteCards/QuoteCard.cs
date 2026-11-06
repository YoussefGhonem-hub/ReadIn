namespace ReadIn.Application.Features.Articles.QuoteCards;

/// <summary>The card's colours: the light or dark tokens of SPEC §15.2.</summary>
public enum QuoteCardTheme
{
    Light,
    Dark,
}

/// <summary>The picture's size (SPEC F24): square 1080 × 1080 or landscape 1200 × 630 pixels.</summary>
public enum QuoteCardFormat
{
    Square,
    Landscape,
}

public static class QuoteCardFormats
{
    /// <summary>The PNG's exact size in pixels.</summary>
    public static (int Width, int Height) Size(QuoteCardFormat format) => format switch
    {
        QuoteCardFormat.Landscape => (1200, 630),
        _ => (1080, 1080),
    };
}

/// <summary>
/// Everything one quote card shows (SPEC F24), gathered by <see cref="RenderQuoteCardQueryHandler"/> from the database
/// and the checked F30 range, so the renderer reads nothing else. Its words follow <see cref="Language"/>, not the app's.
/// </summary>
public sealed record QuoteCard
{
    /// <summary>The quoted text: exactly the trimmed range of the block's plain text, 3–400 UTF-16 code units.</summary>
    public required string Quote { get; init; }

    /// <summary><c>ar-EG</c> or <c>en</c>: the article version quoted.</summary>
    public required string Language { get; init; }

    /// <summary>
    /// <c>rtl</c> or <c>ltr</c>: the card's direction, the one the reader gives the quoted block (SPEC §14.2 rule 1; its
    /// explicit <c>dir</c>, else its first strong character, else the article language), not the quote's own first strong
    /// character: an Arabic sentence quoted from "ASP.NET Core، …" stays right to left.
    /// </summary>
    public required string Dir { get; init; }

    /// <summary>The title of that version.</summary>
    public required string Title { get; init; }

    /// <summary>The writer's display name; null for a deleted account ("Deleted user").</summary>
    public string? AuthorName { get; init; }

    public bool AuthorIsVerified { get; init; }

    /// <summary>For the link <c>{web}/{ar|en}/a/{slug}</c>.</summary>
    public required string Slug { get; init; }

    public required QuoteCardTheme Theme { get; init; }

    public required QuoteCardFormat Format { get; init; }
}

/// <param name="FileName"><c>readin-quote-{slug}.png</c>; sent as RFC 5987 <c>filename*</c>, with <see cref="AsciiFileName"/> as the fallback.</param>
public sealed record QuoteCardFile(string FileName, byte[] Content)
{
    public const string AsciiFileName = "readin-quote.png";
}
