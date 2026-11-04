using System.Collections.Concurrent;
using System.Net;
using System.Text.Json;

namespace ReadIn.ContentStudio.Validation;

public sealed record LinkResult(string Url, int Status, string? FinalUrl, string? Error, DateTime CheckedAt)
{
    public bool Ok => Status == 200;

    /// <summary>
    /// The host still answered 429 after the retries: it limits automated requests (rfc-editor.org does), which says
    /// nothing about whether the page exists. Reported as a warning, never cached, and checked again next run.
    /// </summary>
    public bool RateLimited => Status == 429;
}

/// <summary>
/// Checks that every source answers HTTP 200 after redirects (SPEC §19.3). Polite: at most 2 requests per host at a
/// time with a pause between them, 8 overall, a real GET (some servers answer HEAD wrongly) reading only the headers,
/// and retries with back-off for 429/5xx/timeouts (a 429's <c>Retry-After</c> is honoured, up to 30 seconds). Successes
/// are cached for a week in <c>content/.cache/links.json</c> (git-ignored); failures are always re-checked.
/// </summary>
public sealed class LinkChecker(string cachePath) : IDisposable
{
    private static readonly TimeSpan CacheFor = TimeSpan.FromDays(7);
    private static readonly TimeSpan HostPause = TimeSpan.FromMilliseconds(400);
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web) { WriteIndented = true };

    private readonly HttpClient _http = CreateClient();
    private readonly SemaphoreSlim _global = new(8);
    private readonly ConcurrentDictionary<string, SemaphoreSlim> _hosts = new(StringComparer.OrdinalIgnoreCase);

    public int FromCache { get; private set; }

    public async Task<IReadOnlyDictionary<string, LinkResult>> CheckAsync(IEnumerable<string> urls, CancellationToken ct)
    {
        var cache = LoadCache();
        var now = DateTime.UtcNow;
        var results = new ConcurrentDictionary<string, LinkResult>();
        var pending = new List<string>();

        foreach (var url in urls.Distinct())
        {
            if (cache.TryGetValue(url, out var hit) && hit.Ok && now - hit.CheckedAt < CacheFor)
            {
                results[url] = hit;
                FromCache++;
            }
            else pending.Add(url);
        }

        await Task.WhenAll(pending.Select(async url => results[url] = await CheckOneAsync(url, ct)));

        foreach (var (url, result) in results) cache[url] = result;
        SaveCache(cache);
        return results;
    }

    private async Task<LinkResult> CheckOneAsync(string url, CancellationToken ct)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri)) return new(url, 0, null, "not an absolute URL", DateTime.UtcNow);
        var host = _hosts.GetOrAdd(uri.Host, _ => new SemaphoreSlim(2));

        LinkResult result = new(url, 0, null, "not checked", DateTime.UtcNow);
        for (var attempt = 1; attempt <= 3; attempt++)
        {
            TimeSpan? retryAfter = null;
            await host.WaitAsync(ct);
            await _global.WaitAsync(ct);
            try
            {
                using var timeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
                timeout.CancelAfter(TimeSpan.FromSeconds(25));
                using var request = new HttpRequestMessage(HttpMethod.Get, uri);
                using var response = await _http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, timeout.Token);
                var final = response.RequestMessage?.RequestUri;
                result = new(url, (int)response.StatusCode, final?.ToString(), null, DateTime.UtcNow);
                if (response.StatusCode == HttpStatusCode.OK && final is not null && await SoftNotFoundAsync(final, response, timeout.Token) is { } why)
                    return result with { Status = 404, Error = why };
                if (!IsTransient(response.StatusCode)) return result;
                retryAfter = RetryAfter(response);
            }
            catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException && !ct.IsCancellationRequested)
            {
                result = new(url, 0, null, ex.Message, DateTime.UtcNow);
            }
            finally
            {
                _global.Release();
                await Task.Delay(HostPause, ct);
                host.Release();
            }
            if (attempt < 3) await Task.Delay(retryAfter ?? TimeSpan.FromSeconds(2 * attempt), ct);
        }
        return result;
    }

    private static bool IsTransient(HttpStatusCode status) => status is HttpStatusCode.TooManyRequests or >= HttpStatusCode.InternalServerError;

    private static readonly TimeSpan MaxRetryAfter = TimeSpan.FromSeconds(30);

    /// <summary>A 429's <c>Retry-After</c> (seconds or a date), capped so one host can't stall the run.</summary>
    internal static TimeSpan? RetryAfter(HttpResponseMessage response)
    {
        if (response.StatusCode != HttpStatusCode.TooManyRequests || response.Headers.RetryAfter is not { } header) return null;
        var wait = header.Delta ?? (header.Date is { } at ? at - DateTimeOffset.UtcNow : null);
        if (wait is not { } w || w <= TimeSpan.Zero) return null;
        return w > MaxRetryAfter ? MaxRetryAfter : w;
    }

    /// <summary>
    /// Single-page doc sites answer 200 for any path. angular.dev serves its home page (title "Home • Angular") for a
    /// path that doesn't exist; rxjs.dev renders every page from <c>/generated/docs/{path}.json</c>, which is a real 404.
    /// </summary>
    private async Task<string?> SoftNotFoundAsync(Uri final, HttpResponseMessage response, CancellationToken ct)
    {
        var path = final.AbsolutePath.Trim('/');
        if (final.Host.Equals("angular.dev", StringComparison.OrdinalIgnoreCase) && path.Length > 0)
        {
            var html = await response.Content.ReadAsStringAsync(ct);
            var start = html.IndexOf("<title>", StringComparison.OrdinalIgnoreCase);
            var end = start < 0 ? -1 : html.IndexOf("</title>", start, StringComparison.OrdinalIgnoreCase);
            var title = end < 0 ? "" : WebUtility.HtmlDecode(html[(start + 7)..end]).Trim();
            if (title is "Home • Angular" or "" || title.Contains("Redirecting", StringComparison.OrdinalIgnoreCase))
                return $"soft 404: angular.dev answered with its fallback page (\"{title}\")";
        }
        else if (final.Host.Equals("rxjs.dev", StringComparison.OrdinalIgnoreCase) && path.Length > 0)
        {
            using var probe = await _http.GetAsync($"https://rxjs.dev/generated/docs/{path}.json", HttpCompletionOption.ResponseHeadersRead, ct);
            if (probe.StatusCode != HttpStatusCode.OK) return $"soft 404: rxjs.dev has no page data for /{path}";
        }
        return null;
    }

    private static HttpClient CreateClient()
    {
        var handler = new SocketsHttpHandler
        {
            AllowAutoRedirect = true,
            MaxAutomaticRedirections = 10,
            AutomaticDecompression = DecompressionMethods.All,
            PooledConnectionLifetime = TimeSpan.FromMinutes(2),
        };
        var client = new HttpClient(handler) { Timeout = Timeout.InfiniteTimeSpan };
        client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (compatible; ReadIn-LinkChecker/1.0; +https://readin.app)");
        client.DefaultRequestHeaders.Accept.ParseAdd("text/html,application/xhtml+xml,application/pdf;q=0.9,*/*;q=0.8");
        client.DefaultRequestHeaders.AcceptLanguage.ParseAdd("en-US,en;q=0.9");
        return client;
    }

    private Dictionary<string, LinkResult> LoadCache()
    {
        try
        {
            return File.Exists(cachePath)
                ? JsonSerializer.Deserialize<Dictionary<string, LinkResult>>(File.ReadAllText(cachePath), Json) ?? []
                : [];
        }
        catch (JsonException)
        {
            return [];
        }
    }

    private void SaveCache(Dictionary<string, LinkResult> cache)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(cachePath)!);
        // Several validator processes may run at once; the last writer wins, which is fine for a cache.
        var temp = $"{cachePath}.{Environment.ProcessId}.tmp";
        File.WriteAllText(temp, JsonSerializer.Serialize(cache, Json));
        File.Move(temp, cachePath, overwrite: true);
    }

    public void Dispose()
    {
        _http.Dispose();
        _global.Dispose();
        foreach (var s in _hosts.Values) s.Dispose();
    }
}
