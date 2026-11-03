using System.CommandLine;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ReadIn.Application;
using ReadIn.Application.Common.Interfaces;
using ReadIn.ContentStudio.Authoring;
using ReadIn.ContentStudio.Validation;
using ReadIn.Infrastructure;
using ReadIn.Infrastructure.Content;
using ReadIn.Infrastructure.Persistence.Seeding;

// ReadIn Content Studio — content pipeline CLI (SPEC §19.2).
//   dotnet run --project src/ReadIn.ContentStudio -- compose --slug <slug>
//   dotnet run --project src/ReadIn.ContentStudio -- validate --all
//   dotnet run --project src/ReadIn.ContentStudio -- validate --plan
//   dotnet run --project src/ReadIn.ContentStudio -- import
//   dotnet run --project src/ReadIn.ContentStudio -- generate --field dotnet --limit 20

var root = new RootCommand("ReadIn Content Studio: generate, validate and import articles.");

var allOption = new Option<bool>("--all") { Description = "Every article under content/articles (the default when no filter is given)." };
var slugOption = new Option<string?>("--slug") { Description = "Only this article." };
var fieldOption = new Option<string?>("--field") { Description = "Only articles of this field." };
var planOption = new Option<bool>("--plan") { Description = "Check the plan in taxonomy.yaml (slugs, paths, duplicates, planned sources) instead of articles." };
var noLinksOption = new Option<bool>("--no-links") { Description = "Skip the link checker (quick local loops only; CI always checks links)." };
var noCompileOption = new Option<bool>("--no-compile") { Description = "Skip compile checks (quick local loops only; CI always compiles)." };
var validate = new Command("validate", "Run the automatic checks (SPEC §19.3): schema, structure, parity, length, text, code, links, duplicates.")
{
    allOption, slugOption, fieldOption, planOption, noLinksOption, noCompileOption,
};
validate.SetAction(async (parse, ct) =>
{
    using var host = BuildHost();
    var validator = new ContentValidator(
        host.Services.GetRequiredService<ContentRepository>(),
        host.Services.GetRequiredService<ReadIn.Application.Common.Content.IRDocProcessor>());

    var request = new ValidationRequest(
        parse.GetValue(slugOption), parse.GetValue(fieldOption), parse.GetValue(planOption),
        Links: !parse.GetValue(noLinksOption), Compile: !parse.GetValue(noCompileOption));
    var (findings, stats) = await validator.ValidateAsync(request, ct);
    foreach (var group in findings.GroupBy(f => f.Slug))
    {
        Console.WriteLine(group.Key);
        foreach (var f in group.OrderBy(f => f.Severity))
            Console.WriteLine($"  {(f.Severity == Severity.Error ? "✗" : "!")} [{f.Check}] {f.Message}");
    }

    Console.WriteLine();
    if (!request.Plan) Console.WriteLine($"Articles: {stats.Articles}");
    if (stats.Articles <= 40)
    {
        foreach (var article in stats.Lengths.GroupBy(l => l.Slug))
            Console.WriteLine($"  {article.Key}: {string.Join(", ", article.OrderBy(l => l.Language, StringComparer.Ordinal).Select(l => $"{l.Language} {l.Words} words / {l.Minutes} min"))}");
    }
    if (request.Compile && !request.Plan)
    {
        Console.WriteLine($"Snippets compiled: {(stats.Compiled.Count == 0 ? "0" : string.Join(", ", stats.Compiled.Select(c => $"{c.Key} {c.Value}")))}");
        Console.WriteLine($"Snippets skipped: {stats.Skipped.Count}");
        foreach (var s in stats.Skipped) Console.WriteLine($"  - {s.Slug} {s.Block} ({s.Lang}): {s.Reason}");
    }
    if (request.Links)
        Console.WriteLine($"Links: {stats.LinksChecked} checked ({stats.LinksFromCache} from cache), {stats.LinkFailures.Count} failed");

    var errors = findings.Count(f => f.Severity == Severity.Error);
    Console.WriteLine(errors == 0
        ? $"✓ Content is valid ({findings.Count} warning(s))."
        : $"✗ {errors} error(s), {findings.Count - errors} warning(s).");
    return errors == 0 ? 0 : 1;
});

var composeSlug = new Option<string?>("--slug") { Description = "Only this article." };
var composeField = new Option<string?>("--field") { Description = "Only articles of this field." };
var compose = new Command("compose", "Convert authoring drafts (en.md, ar-EG.md; see content/AUTHORING.md) into en.json / ar-EG.json.")
{
    composeSlug, composeField,
};
compose.SetAction(async (parse, ct) =>
{
    using var host = BuildHost();
    var content = host.Services.GetRequiredService<ContentRepository>();
    var (slug, field) = (parse.GetValue(composeSlug), parse.GetValue(composeField));
    var failed = 0;
    var composed = 0;
    foreach (var folder in content.ArticleFolders())
    {
        var meta = await content.ReadMetaAsync(folder, ct);
        if ((slug is not null && meta.Slug != slug) || (field is not null && meta.Field != field)) continue;
        if (!File.Exists(Path.Combine(folder, "en.md")) && !File.Exists(Path.Combine(folder, "ar-EG.md"))) continue;

        var errors = await DraftComposer.ComposeAsync(folder, ct);
        composed++;
        if (errors.Count == 0) continue;
        failed++;
        Console.WriteLine(meta.Slug);
        foreach (var e in errors) Console.WriteLine($"  ✗ {e}");
    }
    Console.WriteLine(failed == 0 ? $"✓ Composed {composed} article(s)." : $"✗ {failed} of {composed} article(s) have draft errors.");
    return failed == 0 ? 0 : 1;
});

var status = new Command("plan-status", "Which planned articles exist, per field and learning path (to resume a batch).");
status.SetAction(async (_, ct) =>
{
    using var host = BuildHost();
    var content = host.Services.GetRequiredService<ContentRepository>();
    var taxonomy = await content.ReadTaxonomyAsync(ct);
    var written = new HashSet<string>();
    foreach (var folder in content.ArticleFolders()) written.Add((await content.ReadMetaAsync(folder, ct)).Slug);

    foreach (var path in taxonomy.PlannedArticles.GroupBy(p => p.LearningPath))
    {
        var done = path.Count(p => written.Contains(p.Slug));
        Console.WriteLine($"{path.Key}: {done}/{path.Count()}");
        foreach (var p in path.OrderBy(p => p.Order).Where(p => !written.Contains(p.Slug)))
            Console.WriteLine($"  - {p.Order,2}. {p.Field}/{p.Topic}/{p.Slug}");
    }
    Console.WriteLine($"Total: {taxonomy.PlannedArticles.Count(p => written.Contains(p.Slug))}/{taxonomy.PlannedArticles.Count} written.");
    return 0;
});

var forceOption = new Option<bool>("--force") { Description = "Re-run seeders even if their data didn't change." };
var import = new Command("import", "Migrate the database and import taxonomy + approved articles (runs the seeders).") { forceOption };
import.SetAction(async (parse, ct) =>
{
    using var host = BuildHost();
    await host.Services.InitializeDatabaseAsync(seed: true, forceSeed: parse.GetValue(forceOption), ct);
    Console.WriteLine("✓ Import finished.");
    return 0;
});

var generateField = new Option<string>("--field") { Description = "Field slug from taxonomy.yaml.", Required = true };
var limitOption = new Option<int>("--limit") { Description = "Maximum articles to generate.", DefaultValueFactory = _ => 10 };
var generate = new Command("generate", "Outline → English draft → ar-EG adaptation with Claude.") { generateField, limitOption };
generate.SetAction(_ =>
{
    Console.Error.WriteLine("generate is not implemented yet: it needs the Claude API integration (SPEC §19.2 steps 1–3).");
    return 2;
});

root.Subcommands.Add(validate);
root.Subcommands.Add(compose);
root.Subcommands.Add(status);
root.Subcommands.Add(import);
root.Subcommands.Add(generate);

return await root.Parse(args).InvokeAsync();

static IHost BuildHost()
{
    var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings
    {
        EnvironmentName = Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT") ?? Environments.Development,
        ContentRootPath = AppContext.BaseDirectory,
    });
    builder.Configuration.AddEnvironmentVariables("READIN_");
    builder.Configuration["Hangfire:Enabled"] = "false";
    // Like the API in Development: the local import talks to the Auth emulator, so demo seeders may run (ADR 0005).
    builder.Configuration["Firebase:UseEmulator"] ??= builder.Environment.IsDevelopment() ? "true" : "false";
    builder.Configuration["ConnectionStrings:ReadIn"] ??=
        "Server=localhost,14333;Database=ReadIn;User Id=sa;Password=ReadIn_Local_Dev_1;TrustServerCertificate=True;Encrypt=False";

    // Registration never opens a connection, so offline commands (validate) work without SQL Server.
    builder.Services.AddApplication();
    builder.Services.AddInfrastructure(builder.Configuration, builder.Environment);
    builder.Services.AddSingleton<ICurrentUser, SystemCurrentUser>();
    return builder.Build();
}

/// <summary>The pipeline acts as the system, not as a signed-in user.</summary>
internal sealed class SystemCurrentUser : ICurrentUser
{
    public bool IsAuthenticated => false;
    public Guid? UserId => SystemUsers.EditorialId;
    public string UiLanguage => "en";
    public IReadOnlySet<string> Roles => new HashSet<string>();
    public IReadOnlySet<string> Permissions => new HashSet<string>();
}
