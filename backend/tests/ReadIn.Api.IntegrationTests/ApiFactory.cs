using System.Collections.Concurrent;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using DotNet.Testcontainers.Builders;
using DotNet.Testcontainers.Images;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using ReadIn.Application.Common.Interfaces;
using Testcontainers.MsSql;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// Boots the real API (migrations + seeders) against SQL Server 2022 in a container (SPEC §27). Users sign up and sign in
/// through the API exactly like the clients do (ADR 0007).
/// </summary>
public sealed class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    public const string ProjectId = "demo-readin";

    /// <summary>Matches the test server's address, so upload URLs point back at it.</summary>
    public const string PublicBaseUrl = "http://localhost";

    public const string JwtSigningKey = "test-only-jwt-signing-key-0123456789abcdef";
    public const string DemoPassword = "Demo-pass-2026";
    public const string DemoPin = "4826";
    public const string TestPassword = "Strong-pass-42";
    public const string TestPin = "7391";

    /// <summary>Seed users (SPEC §18.3).</summary>
    public const string ReviewerPhone = "+12025550104";
    public const string Reader1Phone = "+12025550110";
    public const string Reader10Phone = "+12025550119";
    public const string SuspendedPhone = "+12025550120";
    public const string SuperAdminPhone = "+12025550101";

    // Fictional 555-01XX numbers (SPEC §18.3) in area codes the seed users don't use.
    private static readonly string[] AreaCodes = ["201", "212", "213", "305", "312", "415", "617", "646", "702", "718", "917", "206", "303", "404", "503"];
    private static int _phoneCounter;

    /// <summary>
    /// SQL Server 2022 with Full-Text Search, built from <c>docker/sqlserver</c> (the official image has no full-text, F16),
    /// so search is tested with its real engine. Built only when missing and kept after the run (the same tag as
    /// docker-compose.yml): after changing the Dockerfile, rebuild it with <c>docker compose build sqlserver</c>.
    /// Set <c>READIN_TESTS_SQL_IMAGE</c> (e.g. <c>mcr.microsoft.com/mssql/server:2022-latest</c>) to run the suite on
    /// another image; without full-text, search uses its LIKE fallback.
    /// </summary>
    public const string FullTextImage = "readin-sqlserver-fts:local";

    private MsSqlContainer? _sql;
    private readonly ConcurrentDictionary<string, Task<string>> _seedSessions = new();

    /// <summary>A fresh uploads folder per test run, deleted afterwards.</summary>
    public string UploadsPath { get; } = Path.Combine(Path.GetTempPath(), "readin-tests", $"uploads-{Guid.NewGuid():N}");

    /// <summary>A fresh private folder (verification proofs, F19) per test run, outside the uploads folder; deleted afterwards.</summary>
    public string PrivatePath { get; } = Path.Combine(Path.GetTempPath(), "readin-tests", $"private-{Guid.NewGuid():N}");

    public async ValueTask InitializeAsync()
    {
        var image = Environment.GetEnvironmentVariable("READIN_TESTS_SQL_IMAGE");
        if (string.IsNullOrWhiteSpace(image))
        {
            await new ImageFromDockerfileBuilder()
                .WithDockerfileDirectory(CommonDirectoryPath.GetGitDirectory(), "docker/sqlserver")
                .WithName(FullTextImage)
                .WithImageBuildPolicy(PullPolicy.Missing)
                .WithDeleteIfExists(false)
                .WithCleanUp(false)
                .Build()
                .CreateAsync();
            image = FullTextImage;
        }

        _sql = new MsSqlBuilder(image).Build();
        await _sql.StartAsync();
        _ = Server; // start the host now: migrations + seeding run once for the whole collection
    }

    public new async ValueTask DisposeAsync()
    {
        await base.DisposeAsync();
        if (_sql is not null) await _sql.DisposeAsync();
        if (Directory.Exists(UploadsPath)) Directory.Delete(UploadsPath, recursive: true);
        if (Directory.Exists(PrivatePath)) Directory.Delete(PrivatePath, recursive: true);
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        var connection = new SqlConnectionStringBuilder(
            (_sql ?? throw new InvalidOperationException("The SQL Server container starts in InitializeAsync.")).GetConnectionString())
        {
            InitialCatalog = "ReadInTests",
        };

        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:ReadIn", connection.ConnectionString);
        builder.UseSetting("Firebase:ProjectId", ProjectId);
        builder.UseSetting("Firebase:UseEmulator", "true");
        builder.UseSetting("Hangfire:Enabled", "false");
        builder.UseSetting("Database:MigrateOnStartup", "true");
        builder.UseSetting("Seed:RunOnStartup", "true");
        builder.UseSetting("Seed:DemoPassword", DemoPassword);
        builder.UseSetting("Seed:DemoPin", DemoPin);
        builder.UseSetting("Jwt:SigningKey", JwtSigningKey);
        builder.UseSetting("Security:RecoveryPinPepper", "test-only-recovery-pin-pepper-0123456789abcdef");
        // Every test client shares one address; the per-number limits still apply.
        // Every guest request of the suite shares one partition (TestServer has no remote IP).
        builder.UseSetting("RateLimits:GlobalPerMinute", "100000");
        builder.UseSetting("RateLimits:Auth:SignInPerMinute", "100000");
        builder.UseSetting("RateLimits:Auth:RegisterPerHour", "100000");
        builder.UseSetting("RateLimits:Auth:RecoveryPerHour", "100000");
        // Reuse detection is tested strictly; one test turns the grace window back on.
        builder.UseSetting("Auth:RefreshReuseGrace", "00:00:00");
        builder.UseSetting("Storage:UploadsPath", UploadsPath);
        builder.UseSetting("Storage:PrivatePath", PrivatePath);
        builder.UseSetting("Storage:PublicBaseUrl", PublicBaseUrl);
        // Seed from fixture content so tests never depend on which of the real articles exist (content/).
        builder.UseSetting("Content:RootPath", Path.Combine(AppContext.BaseDirectory, "fixtures", "content"));
        builder.ConfigureTestServices(services =>
        {
            services.Replace(ServiceDescriptor.Singleton<IExternalIdentityVerifier, FakeExternalIdentityVerifier>());
            services.Replace(ServiceDescriptor.Singleton<IRealtimePublisher>(Realtime));
            services.Replace(ServiceDescriptor.Singleton<IAppleTokenService, FakeAppleTokenService>());
            services.Replace(ServiceDescriptor.Singleton<IRealtimeAccountData, FakeRealtimeAccountData>());
        });
    }

    /// <summary>What the outbox handlers published to the Realtime Database (F27).</summary>
    public RecordingRealtimePublisher Realtime { get; } = new();

    /// <summary>A valid, unused mobile number in the fictional range.</summary>
    public static string NewPhoneNumber()
    {
        var n = Interlocked.Increment(ref _phoneCounter);
        return $"+1{AreaCodes[n / 100 % AreaCodes.Length]}55501{n % 100:D2}";
    }

    public HttpClient GuestClient(string uiLanguage = "en")
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.AcceptLanguage.ParseAdd(uiLanguage);
        return client;
    }

    public HttpClient ClientWithToken(string accessToken, string uiLanguage = "en")
    {
        var client = GuestClient(uiLanguage);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        return client;
    }

    /// <summary>Signs up a brand-new user (phone + <see cref="TestPassword"/> + <see cref="TestPin"/>) and signs it in.</summary>
    public async Task<SignedInUser> SignUpAsync(string uiLanguage = "en")
    {
        var phone = NewPhoneNumber();
        var response = await GuestClient(uiLanguage).PostAsJsonAsync("/api/v1/auth/register", new
        {
            phoneNumber = phone,
            password = TestPassword,
            recoveryPin = TestPin,
            uiLanguage,
            timeZone = "Africa/Cairo",
        }, TestContext.Current.CancellationToken);
        var session = await ReadSessionAsync(response);
        return new SignedInUser(ClientWithToken(session["accessToken"]!.GetValue<string>(), uiLanguage), session, phone);
    }

    /// <summary>A seed user, signed in once per run (sign in is limited to 5 attempts a minute per number).</summary>
    public async Task<HttpClient> SeedUserClientAsync(string phone, string uiLanguage = "en")
    {
        var token = await _seedSessions.GetOrAdd(phone, async p =>
        {
            var response = await GuestClient().PostAsJsonAsync(
                "/api/v1/auth/login", new { phoneNumber = p, password = DemoPassword }, TestContext.Current.CancellationToken);
            return (await ReadSessionAsync(response))["accessToken"]!.GetValue<string>();
        });
        return ClientWithToken(token, uiLanguage);
    }

    public static async Task<JsonObject> ReadSessionAsync(HttpResponseMessage response)
    {
        var body = await response.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"{(int)response.StatusCode} from {response.RequestMessage?.RequestUri}: {body}");
        return JsonNode.Parse(body)!.AsObject();
    }
}

public sealed record SignedInUser(HttpClient Client, JsonObject Session, string PhoneNumber)
{
    public JsonObject Me => Session["user"]!.AsObject();
    public Guid Id => Me["id"]!.GetValue<Guid>();
    public string RefreshToken => Session["refreshToken"]!.GetValue<string>();
}

[CollectionDefinition(Name)]
public sealed class ApiCollection : ICollectionFixture<ApiFactory>
{
    public const string Name = "api";
}
