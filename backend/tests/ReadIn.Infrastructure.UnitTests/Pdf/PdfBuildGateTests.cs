using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using ReadIn.Infrastructure.Pdf;

namespace ReadIn.Infrastructure.UnitTests.Pdf;

/// <summary>
/// The limits of SPEC F33: 2 builds at a time, 30 s for a slot (busy), 60 s for a build (failed). A failed build is
/// reported (the renderer then restarts Chromium only if it crashed) and never stops the other build in progress.
/// </summary>
public sealed class PdfBuildGateTests
{
    private static PdfBuildGate Gate(TimeSpan queue, TimeSpan build, int slots = 2) =>
        new(Options.Create(new ArticlePdfOptions { MaxConcurrentBuilds = slots, QueueTimeout = queue, BuildTimeout = build }),
            TimeProvider.System, NullLogger<PdfBuildGate>.Instance);

    private static Func<Exception, Task> NoRestart => _ => Task.CompletedTask;

    [Fact]
    public async Task At_most_two_builds_run_at_once_and_a_third_request_waits_for_a_slot()
    {
        using var gate = Gate(TimeSpan.FromSeconds(10), TimeSpan.FromSeconds(10));
        var release = new TaskCompletionSource();
        var running = 0;
        var peak = 0;

        async Task<int> Build(CancellationToken _)
        {
            var now = Interlocked.Increment(ref running);
            InterlockedMax(ref peak, now);
            await release.Task;
            Interlocked.Decrement(ref running);
            return now;
        }

        var builds = Enumerable.Range(0, 3).Select(_ => gate.RunAsync(Build, NoRestart, CancellationToken.None)).ToList();
        await Task.Delay(300, TestContext.Current.CancellationToken);
        running.Should().Be(2, "the third request waits for a free slot");

        release.SetResult();
        var results = await Task.WhenAll(builds);
        results.Should().OnlyContain(r => r.IsSuccess);
        peak.Should().Be(2);
    }

    [Fact]
    public async Task A_request_that_gets_no_slot_in_time_is_busy()
    {
        using var gate = Gate(TimeSpan.FromMilliseconds(200), TimeSpan.FromSeconds(10), slots: 1);
        var release = new TaskCompletionSource();
        var first = gate.RunAsync(async _ => { await release.Task; return 1; }, NoRestart, CancellationToken.None);

        var second = await gate.RunAsync(_ => Task.FromResult(2), NoRestart, CancellationToken.None);

        second.Error!.Code.Should().Be("article.pdf_busy");
        release.SetResult();
        (await first).IsSuccess.Should().BeTrue();
    }

    [Fact]
    public async Task A_build_that_takes_too_long_fails_frees_its_slot_and_is_reported()
    {
        using var gate = Gate(TimeSpan.FromSeconds(5), TimeSpan.FromMilliseconds(300), slots: 1);
        var reported = 0;
        var hung = new TaskCompletionSource<int>();

        var slow = await gate.RunAsync(_ => hung.Task, _ => { reported++; return Task.CompletedTask; }, CancellationToken.None);
        var next = await gate.RunAsync(_ => Task.FromResult(7), NoRestart, CancellationToken.None);

        slow.Error!.Code.Should().Be("article.pdf_failed");
        reported.Should().Be(1, "the renderer checks whether Chromium crashed");
        next.Value.Should().Be(7, "the slot of a hung build is given back");
    }

    [Fact]
    public async Task A_build_that_runs_out_of_time_has_its_token_cancelled_so_it_closes_its_own_page()
    {
        using var gate = Gate(TimeSpan.FromSeconds(5), TimeSpan.FromMilliseconds(300));
        var token = new TaskCompletionSource<CancellationToken>();

        var result = await gate.RunAsync(async t => { token.SetResult(t); await Task.Delay(Timeout.Infinite, t); return 1; }, NoRestart,
            CancellationToken.None);

        result.Error!.Code.Should().Be("article.pdf_failed");
        (await token.Task).IsCancellationRequested.Should().BeTrue("the renderer closes the page of a build whose token is cancelled");
    }

    /// <summary>Bug F33-2: one failed build took the other build in progress down with it.</summary>
    [Fact]
    public async Task One_failed_build_leaves_the_other_build_in_progress_alone()
    {
        using var gate = Gate(TimeSpan.FromSeconds(5), TimeSpan.FromSeconds(10));
        var started = new TaskCompletionSource<CancellationToken>();
        var release = new TaskCompletionSource();
        var other = gate.RunAsync(async t => { started.SetResult(t); await release.Task; return 1; }, NoRestart, CancellationToken.None);
        var otherToken = await started.Task;

        var failed = await gate.RunAsync<int>(_ => throw new InvalidOperationException("Protocol error (Page.printToPDF)"), NoRestart,
            CancellationToken.None);

        failed.Error!.Code.Should().Be("article.pdf_failed");
        otherToken.IsCancellationRequested.Should().BeFalse("only the failed build stops");
        other.IsCompleted.Should().BeFalse("the other build is still printing");
        release.SetResult();
        (await other).Value.Should().Be(1);
    }

    [Fact]
    public async Task A_build_that_throws_fails_and_is_reported()
    {
        using var gate = Gate(TimeSpan.FromSeconds(5), TimeSpan.FromSeconds(5));
        Exception? reported = null;

        var result = await gate.RunAsync<int>(_ => throw new InvalidOperationException("Chromium crashed"), e => { reported = e; return Task.CompletedTask; },
            CancellationToken.None);

        result.Error!.Code.Should().Be("article.pdf_failed");
        reported.Should().BeOfType<InvalidOperationException>();
    }

    [Fact]
    public async Task A_request_the_client_gave_up_on_is_cancelled_without_restarting_anything()
    {
        using var gate = Gate(TimeSpan.FromSeconds(5), TimeSpan.FromSeconds(5));
        using var client = new CancellationTokenSource();
        var restarted = false;

        var build = gate.RunAsync(async token => { await Task.Delay(Timeout.Infinite, token); return 1; },
            _ => { restarted = true; return Task.CompletedTask; }, client.Token);
        await client.CancelAsync();

        await FluentActions.Awaiting(() => build).Should().ThrowAsync<OperationCanceledException>();
        restarted.Should().BeFalse();
    }

    private static void InterlockedMax(ref int target, int value)
    {
        int current;
        while (value > (current = Volatile.Read(ref target)) && Interlocked.CompareExchange(ref target, value, current) != current)
        {
        }
    }
}
