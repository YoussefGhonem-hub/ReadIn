using ReadIn.Api;
using ReadIn.Application;
using ReadIn.Infrastructure;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, services, logger) => logger
    .ReadFrom.Configuration(context.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext());

builder.Services
    .AddApplication()
    .AddInfrastructure(builder.Configuration, builder.Environment)
    .AddApi(builder.Configuration, builder.Environment);

var app = builder.Build();

// `dotnet run --project src/ReadIn.Api -- seed [--force]` migrates and seeds, then exits (production path, SPEC §18.1).
if (args.Contains("seed"))
{
    await app.Services.InitializeDatabaseAsync(seed: true, forceSeed: args.Contains("--force"));
    return;
}

if (app.Configuration.GetValue("Database:MigrateOnStartup", false))
    await app.Services.InitializeDatabaseAsync(seed: app.Configuration.GetValue("Seed:RunOnStartup", false));

app.UseSerilogRequestLogging();
app.UseApi();
app.Services.RegisterRecurringJobs(app.Configuration);

await app.RunAsync();

public partial class Program;
