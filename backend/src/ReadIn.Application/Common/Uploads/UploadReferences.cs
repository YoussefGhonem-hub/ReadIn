using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;

namespace ReadIn.Application.Common.Uploads;

/// <summary>
/// Which uploads are still in use: user avatars, article covers, RDoc content of translations, the editor's working
/// copies and revisions (F05; covers, image blocks and attachments by asset id), including soft-deleted rows (they can be
/// restored), and article attachments (ADR 0011). A file is deleted
/// only when nothing here mentions its id. New tables that reference uploads must be added to both queries.
/// <see cref="IsReferencedAsync"/> answers "is it used?"; <see cref="LoadReferencedIdsAsync"/> also keeps the files of
/// every existing MediaAssets row, whose unused rows the media cleanup removes together with their files.
/// </summary>
public sealed class UploadReferences(IAppDbContext db)
{
    private const string Marker = "uploads/";

    public async Task<bool> IsReferencedAsync(string uploadId, CancellationToken cancellationToken)
    {
        return await db.Users.IgnoreQueryFilters()
                   .AnyAsync(u => u.AvatarUrl != null && u.AvatarUrl.Contains(uploadId), cancellationToken)
               || await db.Articles.IgnoreQueryFilters()
                   .AnyAsync(a => a.CoverUrl != null && a.CoverUrl.Contains(uploadId), cancellationToken)
               || await db.ArticleTranslations
                   .AnyAsync(t => t.ContentJson.Contains(uploadId), cancellationToken)
               || await db.ArticleDrafts
                   .AnyAsync(d => d.DocumentJson.Contains(uploadId), cancellationToken)
               || await db.ArticleRevisions
                   .AnyAsync(r => r.DocumentJson.Contains(uploadId), cancellationToken)
               || await db.ArticleAttachments
                   .AnyAsync(a => a.MediaAsset.OriginalPath != null && a.MediaAsset.OriginalPath.Contains(uploadId), cancellationToken);
    }

    /// <summary>
    /// Media assets named by id in a working copy or a revision (F05): an attachment the writer added but hasn't published
    /// yet, or one a revision can bring back. They are kept like attached ones.
    /// </summary>
    public async Task<bool> IsAssetReferencedAsync(Guid assetId, CancellationToken cancellationToken)
    {
        var id = assetId.ToString();
        return await db.ArticleDrafts.AnyAsync(d => d.DocumentJson.Contains(id), cancellationToken)
               || await db.ArticleRevisions.AnyAsync(r => r.DocumentJson.Contains(id), cancellationToken);
    }

    /// <summary>Ids of every referenced upload. Streams the rows, so large content columns are never all in memory.</summary>
    public async Task<HashSet<string>> LoadReferencedIdsAsync(CancellationToken cancellationToken)
    {
        var ids = new HashSet<string>(StringComparer.Ordinal);

        await CollectAsync(db.Users.IgnoreQueryFilters()
            .Where(u => u.AvatarUrl != null && u.AvatarUrl.Contains(Marker)).Select(u => u.AvatarUrl!));
        await CollectAsync(db.Articles.IgnoreQueryFilters()
            .Where(a => a.CoverUrl != null && a.CoverUrl.Contains(Marker)).Select(a => a.CoverUrl!));
        await CollectAsync(db.ArticleTranslations
            .Where(t => t.ContentJson.Contains(Marker)).Select(t => t.ContentJson));
        await CollectAsync(db.ArticleDrafts
            .Where(d => d.DocumentJson.Contains(Marker)).Select(d => d.DocumentJson));
        await CollectAsync(db.ArticleRevisions
            .Where(r => r.DocumentJson.Contains(Marker)).Select(r => r.DocumentJson));

        // Files of an existing MediaAssets row (ADR 0011). Unused rows are removed by the media cleanup, files included,
        // so the file sweep must never delete files behind the back of a live row.
        await foreach (var path in db.MediaAssets.AsNoTracking().Where(m => m.OriginalPath != null).Select(m => m.OriginalPath!)
                           .AsAsyncEnumerable().WithCancellation(cancellationToken))
        {
            if (UploadPath.TryParse(path, out var image)) ids.Add(image.Id);
            else if (DocumentPath.TryParse(path, out var document)) ids.Add(document.Id);
        }

        return ids;

        async Task CollectAsync(IQueryable<string> values)
        {
            await foreach (var value in values.AsNoTracking().AsAsyncEnumerable().WithCancellation(cancellationToken))
                ids.UnionWith(UploadPath.FindIds(value));
        }
    }
}
