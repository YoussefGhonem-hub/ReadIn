using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Features.Admin.Dashboard;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Infrastructure.Content;

/// <summary>
/// The dashboard's content pipeline (SPEC §19, F23): the article folders shipped with the API under <c>content/articles</c>
/// (counted once per process: the folder only changes with a deploy) and the last seed run (<c>SeedHistory</c>). Zero
/// folders when the deployment has no <c>content/</c> (production): the dashboard still loads.
/// </summary>
internal sealed class ContentPipelineSource(ContentRepository content, AppDbContext db) : IContentPipelineSource
{
    private static readonly object Gate = new();
    private static (string Root, int Count)? _folders;

    public int ArticleFolders()
    {
        var root = content.RootOrNull;
        if (root is null) return 0;
        lock (Gate)
        {
            if (_folders is { } known && known.Root == root) return known.Count;
            var count = content.ArticleFolders().Count();
            _folders = (root, count);
            return count;
        }
    }

    public async Task<DateTime?> LastSeedRunAsync(CancellationToken cancellationToken) =>
        await db.SeedHistory.AsNoTracking().MaxAsync(h => (DateTime?)h.AppliedAt, cancellationToken);
}
