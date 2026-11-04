using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Features.Glossary;
using ReadIn.Domain.Glossary;
using ReadIn.Infrastructure.Content;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// Seeder #8 (all environments): glossary terms (SPEC F21) from content/glossary/*.yaml, upserted by term id, then
/// <c>ArticleTerms</c> rebuilt for every article from its stored content. Runs again whenever a glossary file or an
/// article version changes. Terms removed from the files stay, since published articles may still link to them.
/// </summary>
internal sealed partial class GlossarySeeder(
    AppDbContext db,
    ContentRepository content,
    ArticleTermsIndex index,
    ILogger<GlossarySeeder> logger) : ISeeder
{
    public string Name => "glossary";
    public int Order => 8;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => true;

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        content.HashFilesAsync(
            [
                .. content.GlossaryFiles(),
                .. content.ArticleFolders().SelectMany(f => Directory.EnumerateFiles(f, "*.json")),
            ],
            cancellationToken);

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        var terms = await db.GlossaryTerms.ToDictionaryAsync(t => t.Slug, StringComparer.Ordinal, cancellationToken);
        var seen = new HashSet<string>(StringComparer.Ordinal);

        foreach (var file in content.GlossaryFiles())
        {
            foreach (var entry in (await content.ReadGlossaryAsync(file, cancellationToken)).Terms)
            {
                if (!seen.Add(entry.Id))
                {
                    LogDuplicate(logger, entry.Id, Path.GetFileName(file));
                    continue;
                }

                if (terms.TryGetValue(entry.Id, out var term))
                {
                    term.Update(entry.Term, entry.DefinitionEn, entry.DefinitionAr);
                }
                else
                {
                    term = new GlossaryTerm(entry.Id, entry.Term, entry.DefinitionEn, entry.DefinitionAr);
                    db.GlossaryTerms.Add(term);
                    terms.Add(entry.Id, term);
                }
            }
        }

        await db.SaveChangesAsync(cancellationToken);
        db.ChangeTracker.Clear();

        var changes = await index.RebuildAsync(null, cancellationToken);
        LogSeeded(logger, seen.Count, changes);
        return true;
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Glossary term '{Term}' in {File} is defined more than once; the first one wins")]
    private static partial void LogDuplicate(ILogger logger, string term, string file);

    [LoggerMessage(Level = LogLevel.Information, Message = "Glossary: {Terms} terms; {Changes} article-term rows added or removed")]
    private static partial void LogSeeded(ILogger logger, int terms, int changes);
}
