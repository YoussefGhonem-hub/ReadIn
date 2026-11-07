using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Features.Admin.Dashboard;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Content;

/// <summary>
/// The dashboard's content pipeline (SPEC §19, F23): the article folders shipped with the API under <c>content/articles</c>
/// (counted once per process: the folder only changes with a deploy) and the last seed run (<c>SeedHistory</c>).
/// </summary>
internal sealed class ContentPipelineSource(ContentRepository content, AppDbContext db) : IContentPipelineSource
{
    private static readonly object Gate = new();
    private static (string Root, int Count)? _folders;

    public int ArticleFolders()
    {
        lock (Gate)
        {
            if (_folders is { } known && known.Root == content.Root) return known.Count;
            var count = content.ArticleFolders().Count();
            _folders = (content.Root, count);
            return count;
        }
    }

    public async Task<DateTime?> LastSeedRunAsync(CancellationToken cancellationToken) =>
        await db.SeedHistory.AsNoTracking().MaxAsync(h => (DateTime?)h.AppliedAt, cancellationToken);
}
