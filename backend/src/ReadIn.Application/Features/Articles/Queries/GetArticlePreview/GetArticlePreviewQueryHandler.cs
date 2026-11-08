using Mediator;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Hybrid;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Blocks;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;

namespace ReadIn.Application.Features.Articles.Queries.GetArticlePreview;

internal sealed class GetArticlePreviewQueryHandler(
    IAppDbContext db, HybridCache cache, IFileStorage storage, ICurrentUser viewer, BlockRelations blocks)
    : IQueryHandler<GetArticlePreviewQuery, Result<ArticlePreviewDto>>
{
    public async ValueTask<Result<ArticlePreviewDto>> Handle(GetArticlePreviewQuery query, CancellationToken cancellationToken)
    {
        // F36: the blocker gets 403 block.blocked, the blocked person the same not-found as a deleted article.
        if (await blocks.ArticleErrorAsync(viewer, query.ArticleId, cancellationToken) is { } blocked) return blocked;
        var language = ArticleLanguages.IsValid(query.Language) ? query.Language : null;

        CachedArticlePreview cached;
        try
        {
            cached = await cache.GetOrCreateAsync(
                $"article-preview:{query.ArticleId}:{language ?? "source"}",
                (Handler: this, query.ArticleId, Language: language),
                static async (state, ct) =>
                    await state.Handler.LoadAsync(state.ArticleId, state.Language, ct) ?? throw new PreviewNotFoundException(),
                new HybridCacheEntryOptions
                {
                    Expiration = GetArticlePreviewQuery.Expiration,
                    LocalCacheExpiration = GetArticlePreviewQuery.Expiration,
                },
                [CacheTags.ArticleById(query.ArticleId), CacheTags.Articles],
                cancellationToken);
        }
        catch (PreviewNotFoundException)
        {
            return ArticleErrors.NotFound; // never cached, like every failure
        }

        if (cached.IsHidden && !ArticleVisibility.CanSeeHidden(cached.AuthorId, viewer)) return ArticleErrors.NotFound;
        return cached.Preview;
    }

    private async Task<CachedArticlePreview?> LoadAsync(Guid articleId, string? language, CancellationToken ct)
    {
        // Hidden articles too: the copy is the same for every caller, and Handle turns a hidden one into
        // article.not_found for everyone but its author and moderators (SPEC F22).
        var article = await db.Articles.AsNoTracking()
            .Published()
            .Where(a => a.Id == articleId)
            .Select(a => new
            {
                a.AuthorId,
                IsHidden = a.HiddenAt != null,
                Versions = a.Translations
                    .Where(t => t.Language == language || t.IsSource)
                    .Select(t => new { t.Language, t.IsSource, t.ContentJson })
                    .ToList(),
            })
            .FirstOrDefaultAsync(ct);

        var version = article?.Versions.FirstOrDefault(v => v.Language == language) ?? article?.Versions.FirstOrDefault(v => v.IsSource);
        if (article is null || version is null) return null;

        var preview = RDocPreview.Take(version.ContentJson);
        return new CachedArticlePreview(
            new ArticlePreviewDto(articleId, version.Language, storage.ToPublicContent(preview.Json), preview.IsComplete),
            article.IsHidden,
            article.AuthorId);
    }

    private sealed class PreviewNotFoundException : Exception;
}

/// <summary>The cached copy: the same for every reader; whether a hidden article is shown is decided per caller.</summary>
internal sealed record CachedArticlePreview(ArticlePreviewDto Preview, bool IsHidden, Guid? AuthorId);
