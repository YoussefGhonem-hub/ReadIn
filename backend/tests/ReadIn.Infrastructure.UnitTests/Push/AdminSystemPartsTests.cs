using NSubstitute;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Infrastructure.Admin;
using ReadIn.Infrastructure.Jobs;
using ReadIn.Infrastructure.Push;

namespace ReadIn.Infrastructure.UnitTests.Push;

/// <summary>The parts of the admin console's system page that need no database (SPEC F23).</summary>
public sealed class AdminSystemPartsTests
{
    [Fact]
    public void Push_results_are_counted_per_utc_hour()
    {
        PushDeliveryRecorder.HourOf(new DateTime(2026, 11, 7, 13, 59, 59, DateTimeKind.Utc))
            .Should().Be(new DateTime(2026, 11, 7, 13, 0, 0, DateTimeKind.Utc));
        PushDeliveryRecorder.HourOf(new DateTime(2026, 11, 7, 0, 0, 0, DateTimeKind.Utc)).Kind.Should().Be(DateTimeKind.Utc);
    }

    [Fact]
    public async Task The_recorder_returns_the_senders_outcomes_and_never_fails_a_push_it_cant_record()
    {
        var inner = Substitute.For<IPushSender>();
        IReadOnlyList<PushOutcome> outcomes = [new PushOutcome(2, ["dead"], 1)];
        inner.SendAsync(Arg.Any<IReadOnlyList<PushNotification>>(), Arg.Any<CancellationToken>()).Returns(outcomes);
        // No database behind the scope factory: recording fails, and the push still goes through.
        var scopes = Substitute.For<Microsoft.Extensions.DependencyInjection.IServiceScopeFactory>();
        scopes.CreateScope().Returns(_ => throw new InvalidOperationException("no database"));
        var recorder = new PushDeliveryRecorder(inner, scopes, TimeProvider.System,
            Microsoft.Extensions.Logging.Abstractions.NullLogger<PushDeliveryRecorder>.Instance);

        var push = new PushNotification(["t1", "t2", "dead"], "Title", "Body", new Dictionary<string, string>(), "announcement", TimeSpan.FromHours(1));
        (await recorder.SendAsync([push], TestContext.Current.CancellationToken)).Should().BeSameAs(outcomes);
        recorder.Inner.Should().BeSameAs(inner);
    }

    [Fact]
    public void A_failed_run_keeps_the_innermost_error_cut_to_500_characters()
    {
        var wrapped = new InvalidOperationException("Hangfire wrapper", new TimeoutException("The database timed out."));
        JobRunRecorder.Describe(wrapped).Should().Be("TimeoutException: The database timed out.");
        JobRunRecorder.Describe(new InvalidOperationException(new string('x', 900))).Should().HaveLength(500);
    }

    [Fact]
    public void Every_registered_recurring_job_is_listed_once_with_its_schedule()
    {
        var ids = RecurringJobCatalog.All.Select(j => j.Id).ToList();
        ids.Should().OnlyHaveUniqueItems().And.Contain(["outbox", "notification-push", "daily-article", "admin-cleanup", "tags-cleanup"]);
        RecurringJobCatalog.All.Should().OnlyContain(j => !string.IsNullOrWhiteSpace(j.Schedule));
        RecurringJobCatalog.IdOf(typeof(OutboxJob)).Should().Be("outbox");
        RecurringJobCatalog.IdOf(typeof(NotificationPushJob)).Should().Be("notification-push");
        RecurringJobCatalog.IdOf(typeof(string)).Should().BeNull();
    }

    [Fact]
    public void Storage_is_measured_by_walking_the_folder()
    {
        var root = Path.Combine(Path.GetTempPath(), "readin-tests", $"measure-{Guid.NewGuid():N}");
        try
        {
            SystemProbe.Measure(root).Should().Be((0L, 0), "a missing folder is empty");
            Directory.CreateDirectory(Path.Combine(root, "a", "b"));
            File.WriteAllBytes(Path.Combine(root, "one.webp"), new byte[100]);
            File.WriteAllBytes(Path.Combine(root, "a", "b", "two.png"), new byte[23]);
            SystemProbe.Measure(root).Should().Be((123L, 2));
        }
        finally
        {
            if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        }
    }
}
