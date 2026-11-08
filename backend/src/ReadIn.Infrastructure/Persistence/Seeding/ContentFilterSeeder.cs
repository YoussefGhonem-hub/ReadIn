using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Features.ContentFilter;
using ReadIn.Domain.Moderation;
using ReadIn.Infrastructure.Content;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// The content filter's word lists (SPEC F37, all environments): <c>content/moderation/{ar,en}.{block,flag}.txt</c>, one term
/// per line, <c>#</c> comments. A file term is added or kept in step with the file; a term the console customized (a level
/// changed, or removed: disabled) is never touched again, and a console term is never removed. A term that left the files
/// is disabled unless the console customized it.
/// </summary>
internal sealed class ContentFilterSeeder(AppDbContext db, ContentRepository content, ContentFilterCatalog catalog, TimeProvider clock)
    : ISeeder
{
    private static readonly (string Language, string Level, ContentFilterLevel Value)[] Lists =
    [
        ("ar", "block", ContentFilterLevel.Block), ("ar", "flag", ContentFilterLevel.Flag),
        ("en", "block", ContentFilterLevel.Block), ("en", "flag", ContentFilterLevel.Flag),
    ];

    public string Name => "content-filter";
    public int Order => 15;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => true;

    private string FileOf(string language, string level) => Path.Combine(content.Root, "moderation", $"{language}.{level}.txt");

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        content.HashFilesAsync(Lists.Select(l => FileOf(l.Language, l.Level)).Where(File.Exists), cancellationToken);

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var listed = new Dictionary<string, (string Term, string Language, ContentFilterLevel Level)>(StringComparer.Ordinal);
        foreach (var (language, level, value) in Lists)
        {
            var path = FileOf(language, level);
            if (!File.Exists(path)) continue;
            foreach (var line in await File.ReadAllLinesAsync(path, cancellationToken))
            {
                var term = line.Trim();
                if (term.Length == 0 || term.StartsWith('#')) continue;
                var key = ContentFilterText.NormalizeTerm(term);
                if (key.Length < ContentFilterTerm.MinLength || key.Length > ContentFilterTerm.MaxLength || !key.Any(char.IsLetter)) continue;
                // The same term in two lists: block wins.
                if (listed.TryGetValue(key, out var seen) && seen.Level == ContentFilterLevel.Block) continue;
                listed[key] = (term, language, value);
            }
        }

        var rows = await db.ContentFilterTerms.ToDictionaryAsync(t => t.NormalizedTerm, StringComparer.Ordinal, cancellationToken);
        foreach (var (key, term) in listed)
        {
            if (rows.TryGetValue(key, out var row)) row.SyncFromFile(term.Term, term.Language, term.Level, now);
            else db.ContentFilterTerms.Add(new ContentFilterTerm(term.Term, key, term.Language, term.Level, ContentFilterSource.File, now));
        }
        foreach (var gone in rows.Values.Where(r => r.Source == ContentFilterSource.File && r.CustomizedAt is null && r.IsEnabled
                                                    && !listed.ContainsKey(r.NormalizedTerm)))
            gone.DisableFromFile(now);

        await db.SaveChangesAsync(cancellationToken);
        catalog.Invalidate();
        return true;
    }
}
