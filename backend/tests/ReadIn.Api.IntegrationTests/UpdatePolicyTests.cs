using System.Net;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Options;

namespace ReadIn.Api.IntegrationTests;

/// <summary><c>GET /app/update-policy</c>: the forced-update policy of the mobile app, from the <c>MobileApp</c> options.</summary>
[Collection(ApiCollection.Name)]
public sealed class UpdatePolicyTests(ApiFactory api)
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    private static async Task<JsonObject> PolicyAsync(HttpClient client)
    {
        var response = await client.GetAsync("/api/v1/app/update-policy", Ct);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        response.Headers.CacheControl!.NoCache.Should().BeTrue("a raised minimum must reach the apps at once");
        return JsonNode.Parse(await response.Content.ReadAsStringAsync(Ct))!.AsObject();
    }

    [Fact]
    public async Task Guests_get_the_default_policy_no_forced_update()
    {
        var policy = await PolicyAsync(api.GuestClient());

        policy.Select(p => p.Key).Should().Equal("ios", "android");
        policy["ios"]!.AsObject().Select(p => p.Key).Should().Equal("minimumVersion", "storeUrl");
        policy["ios"]!["minimumVersion"].Should().BeNull();
        policy["ios"]!["storeUrl"].Should().BeNull("the app has no App Store id yet");
        policy["android"]!["minimumVersion"].Should().BeNull();
        policy["android"]!["storeUrl"]!.GetValue<string>().Should().Be("https://play.google.com/store/apps/details?id=app.readin.readin");
    }

    [Fact]
    public async Task Operators_set_the_minimum_versions_and_store_pages_in_configuration()
    {
        await using var configured = api.WithWebHostBuilder(builder => builder
            .UseSetting("Database:MigrateOnStartup", "false")
            .UseSetting("MobileApp:Ios:MinimumVersion", "1.2.0+57")
            .UseSetting("MobileApp:Ios:StoreUrl", "https://apps.apple.com/app/id1234567890")
            .UseSetting("MobileApp:Android:MinimumVersion", " 1.3 ")
            .UseSetting("MobileApp:Android:StoreUrl", ""));

        var policy = await PolicyAsync(configured.CreateClient());

        policy["ios"]!["minimumVersion"]!.GetValue<string>().Should().Be("1.2.0+57");
        policy["ios"]!["storeUrl"]!.GetValue<string>().Should().Be("https://apps.apple.com/app/id1234567890");
        policy["android"]!["minimumVersion"]!.GetValue<string>().Should().Be("1.3");
        policy["android"]!["storeUrl"].Should().BeNull("an empty value is no value");
    }

    [Theory]
    [InlineData("MobileApp:Android:MinimumVersion", "1.2.x", "*MobileApp:Android:MinimumVersion*")]
    [InlineData("MobileApp:Ios:MinimumVersion", "1.2.3.4", "*MobileApp:Ios:MinimumVersion*")]
    [InlineData("MobileApp:Ios:StoreUrl", "http://apps.apple.com/app/id1", "*MobileApp:Ios:StoreUrl*")]
    [InlineData("MobileApp:Android:StoreUrl", "play.google.com/store", "*MobileApp:Android:StoreUrl*")]
    public async Task The_api_refuses_to_start_with_a_policy_the_app_cannot_read(string key, string value, string message)
    {
        await using var misconfigured = api.WithWebHostBuilder(builder => builder
            .UseSetting("Database:MigrateOnStartup", "false")
            .UseSetting(key, value));

        var start = () => misconfigured.CreateClient();

        start.Should().Throw<OptionsValidationException>().WithMessage(message);
    }
}
