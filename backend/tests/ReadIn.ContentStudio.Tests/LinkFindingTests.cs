using System.Net;
using System.Net.Http.Headers;
using ReadIn.ContentStudio.Validation;

namespace ReadIn.ContentStudio.Tests;

/// <summary>
/// Sources alive (SPEC §19.3): a dead link fails the run, while a host that rate-limits the checker (HTTP 429, as
/// rfc-editor.org does) is only a warning.
/// </summary>
public sealed class LinkFindingTests
{
    private const string Url = "https://www.rfc-editor.org/rfc/rfc9457";

    private static LinkResult Result(int status, string? error = null) => new(Url, status, Url, error, DateTime.UtcNow);

    [Fact]
    public void A_live_link_is_no_finding() =>
        ContentValidator.LinkFinding("a", Url, Result(200)).Should().BeNull();

    [Fact]
    public void A_rate_limited_link_is_a_warning()
    {
        var finding = ContentValidator.LinkFinding("a", Url, Result(429));

        finding.Should().NotBeNull();
        finding!.Severity.Should().Be(Severity.Warning);
        finding.Check.Should().Be("links");
        finding.Message.Should().Contain("429");
    }

    [Theory]
    [InlineData(404)]
    [InlineData(410)]
    [InlineData(500)]
    [InlineData(403)]
    public void A_dead_link_is_an_error(int status) =>
        ContentValidator.LinkFinding("a", Url, Result(status))!.Severity.Should().Be(Severity.Error);

    [Fact]
    public void A_network_failure_is_an_error() =>
        ContentValidator.LinkFinding("a", Url, Result(0, "Name or service not known"))!.Severity.Should().Be(Severity.Error);

    [Fact]
    public void A_rate_limited_link_is_never_cached_as_alive() =>
        Result(429).Ok.Should().BeFalse();

    [Fact]
    public void Retry_after_is_honoured_and_capped()
    {
        using var shortWait = new HttpResponseMessage(HttpStatusCode.TooManyRequests);
        shortWait.Headers.RetryAfter = new RetryConditionHeaderValue(TimeSpan.FromSeconds(5));
        using var longWait = new HttpResponseMessage(HttpStatusCode.TooManyRequests);
        longWait.Headers.RetryAfter = new RetryConditionHeaderValue(TimeSpan.FromMinutes(10));
        using var notLimited = new HttpResponseMessage(HttpStatusCode.ServiceUnavailable);
        notLimited.Headers.RetryAfter = new RetryConditionHeaderValue(TimeSpan.FromSeconds(5));

        LinkChecker.RetryAfter(shortWait).Should().Be(TimeSpan.FromSeconds(5));
        LinkChecker.RetryAfter(longWait).Should().Be(TimeSpan.FromSeconds(30));
        LinkChecker.RetryAfter(notLimited).Should().BeNull();
    }
}
