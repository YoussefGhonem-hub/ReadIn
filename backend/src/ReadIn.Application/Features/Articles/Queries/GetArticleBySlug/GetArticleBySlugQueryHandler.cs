using Mapster;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Mapping;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.Features.Articles.Queries.GetArticleBySlug;

internal sealed class GetArticleBySlugQueryHandler(
    IAppDbContext db,
    TypeAdapterConfig mapping,
    IFileStorage storage,
    ArticleAttachmentsReader attachmentsReader)
    : IQueryHandler<GetArticleBySlugQuery, Result<ArticleDetailsDto>>
{
    public async ValueTask<Result<ArticleDetailsDto>> Handle(GetArticleBySlugQuery query, CancellationToken cancellationToken)
    {
        using var _ = LocalizedProjection.Begin(query.UiLanguage, query.Language);

        // Hidden articles too: the cached copy is the same for every caller, and the query turns a hidden one into
        // article.not_found for everyone but its author and moderators (SPEC F22).
        var article = await db.Articles.AsNoTracking()
            .Published()
            .Where(a => a.Slug == query.Slug)
            .ProjectToType<ArticleDetailsDto>(mapping)
            .FirstOrDefaultAsync(cancellationToken);

        if (article is null) return ArticleErrors.NotFound;

        // Cached for every reader, so canDownload is the author's switch here; the query personalizes it per caller.
        var attachments = await attachmentsReader.LoadAsync([article.Id], pageLimit: null, viewer: null, cancellationToken);
        var details = new[] { article.WithPublicUrls(storage) }.WithAttachments(attachments)[0];
        return details with
        {
            Content = storage.ToPublicContent(article.ContentJson),
            Moderation = article.Moderation is { } moderation
                ? moderation with { Note = await HideNoteAsync(article.Id, cancellationToken) }
                : null,
        };
    }

    /// <summary>The note of the latest <c>article.hide</c>: what the author is told in the "Hidden by moderators" banner.</summary>
    private Task<string?> HideNoteAsync(Guid articleId, CancellationToken ct) =>
        db.ModerationActions.AsNoTracking()
            .Where(m => m.TargetType == ReportTargetType.Article && m.TargetId == articleId && m.Action == ModerationActionTypes.ArticleHide)
            .OrderByDescending(m => m.CreatedAt)
            .Select(m => m.Note)
            .FirstOrDefaultAsync(ct);
}
