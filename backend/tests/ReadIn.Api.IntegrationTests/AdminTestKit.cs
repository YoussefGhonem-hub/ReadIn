using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Caching.Hybrid;
using Microsoft.Extensions.DependencyInjection;
using ReadIn.Infrastructure.Persistence;

namespace ReadIn.Api.IntegrationTests;

/// <summary>
/// Helpers for the admin console tests (SPEC F23): the database, the "SuperAdmin allowed, Member 403, guest 401" check every
/// admin route gets, and offset pages.
/// </summary>
internal static class AdminTestKit
{
    private static readonly CancellationToken Ct = TestContext.Current.CancellationToken;

    public static async Task<T> InDbAsync<T>(this ApiFactory api, Func<AppDbContext, Task<T>> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        return await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    public static async Task InDbAsync(this ApiFactory api, Func<AppDbContext, Task> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await work(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    }

    public static async Task InScopeAsync(this ApiFactory api, Func<IServiceProvider, Task> work)
    {
        await using var scope = api.Services.CreateAsyncScope();
        await work(scope.ServiceProvider);
    }

    /// <summary>Drops cached entries by tag, e.g. the dashboard's, so a test sees fresh numbers.</summary>
    public static Task DropCacheAsync(this ApiFactory api, params string[] tags) =>
        api.InScopeAsync(async services => await services.GetRequiredService<HybridCache>().RemoveByTagAsync(tags, Ct));

    /// <summary>A guest gets 401 and a Member 403 <c>auth.forbidden</c> on the route (every <c>/admin</c> route, SPEC F23).</summary>
    public static async Task AssertAdminOnlyAsync(this ApiFactory api, HttpMethod method, string url, object? body = null)
    {
        var member = await api.UserAsync("Plain Member");
        (await api.GuestClient().SendAsync(Request(method, url, body), Ct)).StatusCode.Should().Be(HttpStatusCode.Unauthorized, url);
        await member.Client.SendAsync(Request(method, url, body), Ct).ProblemAsync(HttpStatusCode.Forbidden, "auth.forbidden");
    }

    public static HttpRequestMessage Request(HttpMethod method, string url, object? body = null) =>
        new(method, url) { Content = body is null ? null : JsonContent.Create(body) };

    public static Task<HttpResponseMessage> SendJsonAsync(this HttpClient client, HttpMethod method, string url, object? body = null) =>
        client.SendAsync(Request(method, url, body), Ct);

    /// <summary>Asserts a 204.</summary>
    public static async Task NoContentAsync(this Task<HttpResponseMessage> request)
    {
        var response = await request;
        var body = await response.Content.ReadAsStringAsync(Ct);
        response.StatusCode.Should().Be(HttpStatusCode.NoContent, body);
    }

    /// <summary>The <c>items</c> of a <c>PagedList</c>, after checking its shape.</summary>
    public static JsonArray PageItems(this JsonObject page)
    {
        page.Select(p => p.Key).Should().BeEquivalentTo("items", "page", "pageSize", "totalCount", "totalPages");
        return page["items"]!.AsArray();
    }
}
