using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Devotions;
using ReadIn.Infrastructure.Content;

namespace ReadIn.Infrastructure.Persistence.Seeding;

/// <summary>
/// The SuperAdmin's starter du'as for the private corner (SPEC F38, all environments): <c>content/devotions/starter-duas.json</c>,
/// added to every account with the SuperAdmin role, in the file's order after the du'as it already has. A du'a whose text
/// the account already has is skipped, and the 200 limit holds, so a run only adds what is missing. It runs again only
/// when the file changes: the account edits and deletes them like its own, and a deleted one comes back only then.
/// </summary>
internal sealed class StarterDuasSeeder(AppDbContext db, ContentRepository content, TimeProvider clock) : ISeeder
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    public string Name => "starter-duas";
    public int Order => 17;
    public int Version => 1;

    public bool AppliesTo(IHostEnvironment environment) => true;

    private string FilePath => Path.Combine(content.Root, "devotions", "starter-duas.json");

    public Task<string> ComputeChecksumAsync(CancellationToken cancellationToken) =>
        File.Exists(FilePath) ? content.HashFilesAsync([FilePath], cancellationToken) : Task.FromResult("none");

    public async Task<bool> SeedAsync(CancellationToken cancellationToken)
    {
        if (!File.Exists(FilePath)) return true;
        var owners = await db.Users
            .Where(u => u.Roles.Any(r => r.RoleId == RoleIds.SuperAdmin))
            .Select(u => u.Id)
            .ToListAsync(cancellationToken);
        await SeedForAsync(owners, cancellationToken);
        return true;
    }

    /// <summary>Adds the file's du'as to <paramref name="owners"/> (what <see cref="SeedAsync"/> does for every SuperAdmin).</summary>
    internal async Task SeedForAsync(IReadOnlyCollection<Guid> owners, CancellationToken cancellationToken)
    {
        var starters = await ReadAsync(cancellationToken);
        var now = clock.GetUtcNow().UtcDateTime;
        foreach (var userId in owners)
        {
            var texts = await db.PersonalDuas.Where(d => d.UserId == userId).Select(d => d.Text).ToListAsync(cancellationToken);
            var have = texts.ToHashSet(StringComparer.Ordinal);
            var room = PersonalDua.MaxPerUser - texts.Count;
            var order = 0;
            foreach (var (title, text, repeat) in starters)
            {
                if (room <= 0) break;
                if (!have.Add(text)) continue;
                // A millisecond apart, so "oldest first" keeps the file's order.
                db.PersonalDuas.Add(new PersonalDua(userId, title, text, repeat, now.AddMilliseconds(order++)));
                room--;
            }
        }
        await db.SaveChangesAsync(cancellationToken);
    }

    /// <summary>The file's du'as, cleaned like the API cleans them; a bad entry stops the seed (a broken file is a bug).</summary>
    private async Task<List<(string? Title, string Text, int Repeat)>> ReadAsync(CancellationToken cancellationToken)
    {
        await using var stream = File.OpenRead(FilePath);
        var file = await JsonSerializer.DeserializeAsync<StarterDuasFile>(stream, Json, cancellationToken)
                   ?? throw new InvalidOperationException($"{FilePath} is empty.");
        var duas = new List<(string? Title, string Text, int Repeat)>();
        foreach (var entry in file.Duas)
        {
            var title = PersonalDuaText.Title(entry.Title);
            var text = PersonalDuaText.Text(entry.Text);
            var repeat = entry.Repeat ?? PersonalDua.DefaultRepeat;
            if (text.Length is 0 or > PersonalDua.MaxTextLength || title?.Length > PersonalDua.MaxTitleLength
                || repeat is < 1 or > PersonalDua.MaxRepeat)
                throw new InvalidOperationException($"{FilePath}: a du'a breaks the F38 rules (\"{entry.Title}\").");
            duas.Add((title, text, repeat));
        }
        return duas;
    }

    private sealed record StarterDuasFile(List<StarterDua> Duas);

    private sealed record StarterDua(string? Title, string? Text, int? Repeat);
}
