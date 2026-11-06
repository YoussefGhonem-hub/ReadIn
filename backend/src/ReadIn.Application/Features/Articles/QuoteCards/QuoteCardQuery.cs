using System.Text.RegularExpressions;
using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Highlights;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.QuoteCards;

/// <summary>
/// <c>POST /articles/{id}/quote-card</c> (SPEC F24, ADR 0019): a picture of an F30 range of the version being read, for
/// social media, drawn in the request and never stored. Guests allowed. Nullable members so a missing one is the
/// validation code <c>validation.required</c>. A query: it changes nothing.
/// </summary>
[RequirePermission(Permissions.Articles.Read)]
public sealed record RenderQuoteCardQuery(
    Guid ArticleId, string? Language, string? BlockId, int? StartOffset, int? EndOffset, string? Text, string? Theme, string? Format)
    : IQuery<Result<QuoteCardFile>>;

internal sealed partial class RenderQuoteCardQueryValidator : AbstractValidator<RenderQuoteCardQuery>
{
    public RenderQuoteCardQueryValidator()
    {
        RuleFor(q => q.Language).Cascade(CascadeMode.Stop).NotEmpty()
            .Must(ArticleLanguages.IsValid).WithErrorCode(ArticleErrors.InvalidLanguage.Code);
        RuleFor(q => q.BlockId).Cascade(CascadeMode.Stop).NotEmpty()
            .Must(id => id is null || BlockIdRegex().IsMatch(id)).WithErrorCode("validation.invalid");
        RuleFor(q => q.StartOffset).Cascade(CascadeMode.Stop).NotNull()
            .GreaterThanOrEqualTo(0).WithErrorCode("validation.invalid");
        RuleFor(q => q.EndOffset).Cascade(CascadeMode.Stop).NotNull()
            .Must((q, end) => end is null || q.StartOffset is null || end > q.StartOffset).WithErrorCode("validation.invalid");
        RuleFor(q => q.Text).NotEmpty();
        RuleFor(q => q.Theme).Cascade(CascadeMode.Stop).NotEmpty()
            .Must(t => QuoteCardRange.Theme(t) is not null).WithErrorCode("validation.invalid");
        RuleFor(q => q.Format).Cascade(CascadeMode.Stop).NotEmpty()
            .Must(f => QuoteCardRange.Format(f) is not null).WithErrorCode("validation.invalid");
    }

    /// <summary>The RDoc block id pattern (rdoc.schema.json), as for highlights.</summary>
    [GeneratedRegex("^[A-Za-z0-9_-]{1,64}$")]
    private static partial Regex BlockIdRegex();
}

/// <summary>
/// The quote card's range checks (SPEC F24): F30's rules on the block's plain text (<see cref="HighlightRanges"/>, the
/// shared fixtures in <c>shared/rdoc/highlight-fixtures.json</c>), with the card's own length limits.
/// </summary>
public static class QuoteCardRange
{
    /// <summary>
    /// The text the card shows: the range of <paramref name="block"/> trimmed at both ends, in the order of the contract's
    /// checks (no block or a wrong range → <c>quote.text_mismatch</c>, a block a highlight can't use →
    /// <c>quote.block_not_allowed</c>, then the length after trimming).
    /// </summary>
    public static Result<string> Quote(RDocTextBlock? block, int startOffset, int endOffset, string text)
    {
        if (block is null) return QuoteCardErrors.TextMismatch;
        if (!block.IsHighlightable) return QuoteCardErrors.BlockNotAllowed;
        if (!HighlightRanges.Matches(block, startOffset, endOffset, text)) return QuoteCardErrors.TextMismatch;

        var (start, end) = HighlightRanges.Trim(block.Text!, startOffset, endOffset);
        if (end - start < QuoteCardErrors.MinLength) return QuoteCardErrors.TooShort;
        if (end - start > QuoteCardErrors.MaxLength) return QuoteCardErrors.TooLong;
        return block.Text![start..end];
    }

    public static QuoteCardTheme? Theme(string? value) => value switch
    {
        "light" => QuoteCardTheme.Light,
        "dark" => QuoteCardTheme.Dark,
        _ => null,
    };

    public static QuoteCardFormat? Format(string? value) => value switch
    {
        "square" => QuoteCardFormat.Square,
        "landscape" => QuoteCardFormat.Landscape,
        _ => null,
    };
}

internal sealed class RenderQuoteCardQueryHandler(
    IAppDbContext db,
    ICurrentUser viewer,
    HighlightTexts texts,
    IQuoteCardRenderer renderer)
    : IQueryHandler<RenderQuoteCardQuery, Result<QuoteCardFile>>
{
    public async ValueTask<Result<QuoteCardFile>> Handle(RenderQuoteCardQuery query, CancellationToken cancellationToken)
    {
        // The reader's rules: unknown, unpublished and deleted articles, and a hidden one to everyone but its author and
        // moderators, are "not found".
        var article = await db.Articles.AsNoTracking()
            .VisibleTo(viewer)
            .Where(a => a.Id == query.ArticleId)
            .Select(a => new
            {
                a.Slug,
                IsHidden = a.HiddenAt != null,
                AuthorName = a.Author == null ? null : a.Author.DisplayName,
                AuthorIsVerified = a.Author != null && a.Author.IsVerified,
            })
            .FirstOrDefaultAsync(cancellationToken);
        if (article is null) return ArticleErrors.NotFound;

        // The card carries the ReadIn logo, so a hidden article has none (SPEC F22), as for its PDF.
        if (article.IsHidden) return QuoteCardErrors.Hidden;

        var language = query.Language!;
        // The shared, cached block texts of the version (dropped on publish, Update, hide and delete).
        var version = await texts.GetVersionAsync(query.ArticleId, language, cancellationToken);
        if (version is null) return ArticleErrors.NotFound;
        var block = version.Language == language ? version.Find(query.BlockId!) : null;

        var quote = QuoteCardRange.Quote(block, query.StartOffset!.Value, query.EndOffset!.Value, query.Text!);
        if (quote.IsFailure) return quote.Error;

        var title = await db.ArticleTranslations.AsNoTracking()
            .Where(t => t.ArticleId == query.ArticleId && t.Language == language)
            .Select(t => t.Title)
            .FirstOrDefaultAsync(cancellationToken);
        if (title is null) return QuoteCardErrors.TextMismatch;

        var image = await renderer.RenderAsync(new QuoteCard
        {
            Quote = quote.Value,
            Language = language,
            // The block's direction in the reader, so the card reads in the same order (SPEC §14.2).
            Dir = block!.Dir ?? TextDirection.OfLanguage(language),
            Title = title,
            AuthorName = article.AuthorName,
            AuthorIsVerified = article.AuthorIsVerified,
            Slug = article.Slug,
            Theme = QuoteCardRange.Theme(query.Theme)!.Value,
            Format = QuoteCardRange.Format(query.Format)!.Value,
        }, cancellationToken);

        return image.IsSuccess
            ? new QuoteCardFile($"readin-quote-{article.Slug}.png", image.Value)
            : image.Error;
    }
}
