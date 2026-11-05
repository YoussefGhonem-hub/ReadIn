using System.Text.RegularExpressions;
using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.Features.Highlights;

/// <summary>
/// POST /articles/{id}/highlights (SPEC F30): highlight a range of one block of the version being read. The range is
/// checked against the version's current plain text, trimmed, and joined with your own highlights it overlaps or
/// touches in that block. Nullable members so a missing one is the validation code <c>validation.required</c>.
/// </summary>
[Authenticated]
[RequirePermission(Permissions.Highlights.Create)]
public sealed record CreateHighlightCommand(
    Guid ArticleId, string? Language, string? BlockId, int? StartOffset, int? EndOffset, string? Text)
    : ICommand<Result<HighlightCreation>>;

/// <summary>What POST answered: <see cref="Created"/> false when the range was already inside one of yours (200, not 201).</summary>
public sealed record HighlightCreation(HighlightCreatedDto Result, bool Created);

/// <summary>DELETE /highlights/{id} (SPEC F30): remove one of your highlights.</summary>
[Authenticated]
[RequirePermission(Permissions.Highlights.Create)]
public sealed record DeleteHighlightCommand(Guid HighlightId) : ICommand<Result>;

internal sealed partial class CreateHighlightCommandValidator : AbstractValidator<CreateHighlightCommand>
{
    public CreateHighlightCommandValidator()
    {
        RuleFor(c => c.Language).Cascade(CascadeMode.Stop).NotEmpty()
            .Must(ArticleLanguages.IsValid).WithErrorCode(ArticleErrors.InvalidLanguage.Code);
        RuleFor(c => c.BlockId).Cascade(CascadeMode.Stop).NotEmpty()
            .Must(id => id is null || BlockIdRegex().IsMatch(id)).WithErrorCode("validation.invalid");
        RuleFor(c => c.StartOffset).Cascade(CascadeMode.Stop).NotNull()
            .GreaterThanOrEqualTo(0).WithErrorCode("validation.invalid");
        RuleFor(c => c.EndOffset).Cascade(CascadeMode.Stop).NotNull()
            .Must((c, end) => end is null || c.StartOffset is null || end > c.StartOffset).WithErrorCode("validation.invalid");
        RuleFor(c => c.Text).NotEmpty();
    }

    /// <summary>The RDoc block id pattern (rdoc.schema.json).</summary>
    [GeneratedRegex("^[A-Za-z0-9_-]{1,64}$")]
    private static partial Regex BlockIdRegex();
}

internal sealed class CreateHighlightCommandHandler(IAppDbContext db, ICurrentUser currentUser, HybridCache cache, TimeProvider clock)
    : ICommandHandler<CreateHighlightCommand, Result<HighlightCreation>>
{
    public async ValueTask<Result<HighlightCreation>> Handle(CreateHighlightCommand command, CancellationToken cancellationToken)
    {
        // The reader's rules: a hidden article is only there for its author and moderators (F22).
        if (!await db.Articles.VisibleTo(currentUser).AnyAsync(a => a.Id == command.ArticleId, cancellationToken)) return ArticleErrors.NotFound;

        var language = command.Language!;
        var blockId = command.BlockId!;

        // Checked against the database, not the cache: a write must see the text as it is now.
        var version = await HighlightTexts.LoadVersionAsync(db, command.ArticleId, language, cancellationToken);
        if (version is null || version.Language != language || version.Find(blockId) is not { } block) return HighlightErrors.TextMismatch;
        if (!block.IsHighlightable) return HighlightErrors.BlockNotAllowed;
        if (!HighlightRanges.Matches(block, command.StartOffset!.Value, command.EndOffset!.Value, command.Text!)) return HighlightErrors.TextMismatch;

        var plain = block.Text!;
        var (start, end) = HighlightRanges.Trim(plain, command.StartOffset.Value, command.EndOffset.Value);
        if (end - start < ArticleHighlight.MinLength) return HighlightErrors.TooShort;
        if (end - start > ArticleHighlight.MaxLength) return HighlightErrors.TooLong;

        var userId = currentUser.RequireUserId();
        var own = await db.ArticleHighlights
            .Where(h => h.UserId == userId && h.ArticleId == command.ArticleId)
            .ToListAsync(cancellationToken);

        // Highlights an Update left behind in this version are never shown again: they go now and don't count.
        var stale = own.Where(h => h.Language == language && !version.StillMatches(h.BlockId, h.StartOffset, h.EndOffset, h.Text)).ToList();
        var live = own.Except(stale).ToList();
        var sameBlock = live.Where(h => h.Language == language && h.BlockId == blockId).ToList();

        if (sameBlock.FirstOrDefault(h => h.StartOffset <= start && end <= h.EndOffset) is { } existing)
        {
            await RemoveStaleAsync(stale, cancellationToken);
            return new HighlightCreation(new HighlightCreatedDto(ToDto(existing), []), Created: false);
        }

        // Overlapping or touching highlights of yours in the block become one (SPEC F30): yours never overlap.
        var joined = sameBlock.Where(h => h.StartOffset <= end && start <= h.EndOffset).ToList();
        if (joined.Count > 0)
        {
            start = Math.Min(start, joined.Min(h => h.StartOffset));
            end = Math.Max(end, joined.Max(h => h.EndOffset));
            if (end - start > ArticleHighlight.MaxLength) return HighlightErrors.TooLong;
        }

        // Both versions together; the other version's rows are checked against its own text only near the limit.
        if (live.Count - joined.Count + 1 > ArticleHighlight.MaxPerArticle
            && await CountShownAsync(live, version, cancellationToken) - joined.Count + 1 > ArticleHighlight.MaxPerArticle)
        {
            return HighlightErrors.Limit;
        }

        var highlight = ArticleHighlight.Create(
            userId, command.ArticleId, language, blockId, start, end, plain[start..end], clock.GetUtcNow().UtcDateTime);
        db.ArticleHighlights.RemoveRange([.. stale, .. joined]);
        db.ArticleHighlights.Add(highlight);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            // The same range from a concurrent request (a double tap): the unique index kept the one that committed first.
            var winner = await db.ArticleHighlights.AsNoTracking().FirstOrDefaultAsync(
                h => h.UserId == userId && h.ArticleId == command.ArticleId && h.Language == language && h.BlockId == blockId
                    && h.StartOffset == start && h.EndOffset == end,
                cancellationToken);
            if (winner is null) throw;
            return new HighlightCreation(new HighlightCreatedDto(ToDto(winner), []), Created: false);
        }

        await cache.RemoveByTagAsync(CacheTags.ArticleHighlights(command.ArticleId), cancellationToken);
        return new HighlightCreation(new HighlightCreatedDto(ToDto(highlight), [.. joined.Select(h => h.Id)]), Created: true);
    }

    /// <summary>
    /// Your highlights on the article that still show (SPEC F30: the limit counts both versions, and highlights an Update
    /// hid don't count). <paramref name="live"/> holds only matching ones of <paramref name="version"/>; another version's
    /// are checked against that version's current text (none show when it is gone).
    /// </summary>
    private async Task<int> CountShownAsync(List<ArticleHighlight> live, HighlightVersion version, CancellationToken ct)
    {
        var count = live.Count(h => h.Language == version.Language);
        foreach (var other in live.Where(h => h.Language != version.Language).GroupBy(h => h.Language))
        {
            var otherVersion = await HighlightTexts.LoadVersionAsync(db, version.ArticleId, other.Key, ct);
            if (otherVersion is null || otherVersion.Language != other.Key) continue;
            count += other.Count(h => otherVersion.StillMatches(h.BlockId, h.StartOffset, h.EndOffset, h.Text));
        }
        return count;
    }

    private async Task RemoveStaleAsync(List<ArticleHighlight> stale, CancellationToken ct)
    {
        if (stale.Count == 0) return;
        db.ArticleHighlights.RemoveRange(stale);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateConcurrencyException)
        {
            // Already removed by a concurrent request.
        }
    }

    internal static HighlightDto ToDto(ArticleHighlight h) => new(h.Id, h.BlockId, h.StartOffset, h.EndOffset, h.Text, h.CreatedAt);
}

internal sealed class DeleteHighlightCommandHandler(IAppDbContext db, ICurrentUser currentUser, HybridCache cache)
    : ICommandHandler<DeleteHighlightCommand, Result>
{
    public async ValueTask<Result> Handle(DeleteHighlightCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        // Someone else's highlight answers like a missing one: nobody learns who marked what.
        var highlight = await db.ArticleHighlights.FirstOrDefaultAsync(h => h.Id == command.HighlightId && h.UserId == userId, cancellationToken);
        if (highlight is null) return HighlightErrors.NotFound;

        db.ArticleHighlights.Remove(highlight);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            return HighlightErrors.NotFound; // removed by a concurrent request
        }

        await cache.RemoveByTagAsync(CacheTags.ArticleHighlights(highlight.ArticleId), cancellationToken);
        return Result.Success();
    }
}
