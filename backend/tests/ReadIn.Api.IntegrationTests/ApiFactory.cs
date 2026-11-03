using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.SqlClient;
using Testcontainers.MsSql;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// Boots the real API (migrations + seeders) against SQL Server 2022 in a container (SPEC §27).
/// Firebase runs in emulator mode, so tests mint unsigned ID tokens exactly like the Auth emulator does.
/// </summary>
public sealed class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    public const string ProjectId = "demo-readin";

    /// <summary>Matches the test server's address, so upload URLs point back at it.</summary>
    public const string PublicBaseUrl = "http://localhost";

    private readonly MsSqlContainer _sql = new MsSqlBuilder("mcr.microsoft.com/mssql/server:2022-latest").Build();

    /// <summary>A fresh uploads folder per test run, deleted afterwards.</summary>
    public string UploadsPath { get; } = Path.Combine(Path.GetTempPath(), "readin-tests", $"uploads-{Guid.NewGuid():N}");

    public async ValueTask InitializeAsync()
    {
        await _sql.StartAsync();
        _ = Server; // start the host now: migrations + seeding run once for the whole collection
    }

    public new async ValueTask DisposeAsync()
    {
        await base.DisposeAsync();
        await _sql.DisposeAsync();
        if (Directory.Exists(UploadsPath)) Directory.Delete(UploadsPath, recursive: true);
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        var connection = new SqlConnectionStringBuilder(_sql.GetConnectionString()) { InitialCatalog = "ReadInTests" };

        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:ReadIn", connection.ConnectionString);
        builder.UseSetting("Firebase:ProjectId", ProjectId);
        builder.UseSetting("Firebase:UseEmulator", "true");
        builder.UseSetting("Hangfire:Enabled", "false");
        builder.UseSetting("Database:MigrateOnStartup", "true");
        builder.UseSetting("Seed:RunOnStartup", "true");
        builder.UseSetting("Storage:UploadsPath", UploadsPath);
        builder.UseSetting("Storage:PublicBaseUrl", PublicBaseUrl);
    }

    /// <summary>An unsigned Firebase-emulator-style ID token.</summary>
    public static string Token(string uid, string email, string? name = null, string projectId = ProjectId)
    {
        static string B64(object value) => Convert.ToBase64String(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(value)))
            .TrimEnd('=').Replace('+', '-').Replace('/', '_');

        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var header = B64(new { alg = "none", typ = "JWT" });
        var payload = B64(new Dictionary<string, object?>
        {
            ["iss"] = $"https://securetoken.google.com/{projectId}",
            ["aud"] = projectId,
            ["sub"] = uid,
            ["user_id"] = uid,
            ["email"] = email,
            ["name"] = name,
            ["iat"] = now,
            ["exp"] = now + 3600,
            ["auth_time"] = now,
        });
        return $"{header}.{payload}.";
    }

    public HttpClient ClientFor(string uid, string email, string uiLanguage = "en")
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", Token(uid, email, "Test User"));
        client.DefaultRequestHeaders.AcceptLanguage.ParseAdd(uiLanguage);
        return client;
    }

    public HttpClient GuestClient(string uiLanguage = "en")
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.AcceptLanguage.ParseAdd(uiLanguage);
        return client;
    }
}

[CollectionDefinition(Name)]
public sealed class ApiCollection : ICollectionFixture<ApiFactory>
{
    public const string Name = "api";
}
