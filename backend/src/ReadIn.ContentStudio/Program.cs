using System.CommandLine;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ReadIn.Application;
using ReadIn.Application.Common.Interfaces;
using ReadIn.ContentStudio;
using ReadIn.Infrastructure;
using ReadIn.Infrastructure.Content;
using ReadIn.Infrastructure.Persistence.Seeding;

// ReadIn Content Studio — content pipeline CLI (SPEC §19.2).
//   dotnet run --project src/ReadIn.ContentStudio -- validate --all
//   dotnet run --project src/ReadIn.ContentStudio -- import
//   dotnet run --project src/ReadIn.ContentStudio -- generate --field dotnet --limit 20

var root = new RootCommand("ReadIn Content Studio: generate, validate and import articles.");

var allOption = new Option<bool>("--all") { Description = "Validate every article under content/articles." };
var slugOption = new Option<string?>("--slug") { Description = "Validate a single article by slug." };
var validate = new Command("validate", "Run the automatic checks (schema, parity, sources, quality).") { allOption, slugOption };
validate.SetAction(async (parse, ct) =>
{
    using var host = BuildHost();
    var validator = new ContentValidator(
        host.Services.GetRequiredService<ContentRepository>(),
        host.Services.GetRequiredService<ReadIn.Application.Common.Content.IRDocProcessor>());

    var findings = await validator.ValidateAsync(parse.GetValue(allOption) ? null : parse.GetValue(slugOption), ct);
    foreach (var group in findings.GroupBy(f => f.Slug))
    {
        Console.WriteLine(group.Key);
        foreach (var f in group)
            Console.WriteLine($"  {(f.Severity == Severity.Error ? "✗" : "!")} [{f.Check}] {f.Message}");
    }

    var errors = findings.Count(f => f.Severity == Severity.Error);
    Console.WriteLine(errors == 0
        ? $"✓ Content is valid ({findings.Count} warning(s))."
        : $"✗ {errors} error(s), {findings.Count - errors} warning(s).");
    return errors == 0 ? 0 : 1;
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

var fieldOption = new Option<string>("--field") { Description = "Field slug from taxonomy.yaml.", Required = true };
var limitOption = new Option<int>("--limit") { Description = "Maximum articles to generate.", DefaultValueFactory = _ => 10 };
var generate = new Command("generate", "Outline → English draft → ar-EG adaptation with Claude.") { fieldOption, limitOption };
generate.SetAction(_ =>
{
    Console.Error.WriteLine("generate is not implemented yet: it needs the Claude API integration (SPEC §19.2 steps 1–3).");
    return 2;
});

root.Subcommands.Add(validate);
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
    public string? FirebaseUid => null;
    public Guid? UserId => SystemUsers.EditorialId;
    public string? Email => null;
    public string? DisplayName => "ReadIn Content Studio";
    public string? PictureUrl => null;
    public string UiLanguage => "en";
    public IReadOnlySet<string> Roles => new HashSet<string>();
    public IReadOnlySet<string> Permissions => new HashSet<string>();
}
