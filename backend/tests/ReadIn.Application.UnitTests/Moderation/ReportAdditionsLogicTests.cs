using ReadIn.Application.Features.Moderation;
using ReadIn.Application.Features.Notifications;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.UnitTests.Moderation;

/// <summary>
/// F22 store requirements: a case's age and urgency against the 24-hour target, system reports (one per target, reopened by
/// a later flag), the report_new / report_resolved texts (never naming who acted or what was done to a user) and who may
/// set report_new.
/// </summary>
public sealed class ReportAdditionsLogicTests
{
    private static readonly DateTime Now = new(2026, 11, 8, 12, 0, 0, DateTimeKind.Utc);

    private static ModerationQueueItemDto Item(ReportStatus status) => new(
        ReportTargetType.Article, Guid.NewGuid(), status, 1, new Dictionary<string, int>(), Now, Now, null,
        new ModerationTargetDto { State = ModerationTargetStates.Visible });

    [Theory]
    [InlineData(0, 0, false)]
    [InlineData(11.9, 11, false)]
    [InlineData(12, 12, true)]
    [InlineData(25.5, 25, true)]
    public void An_open_case_is_aged_from_its_oldest_open_report_and_urgent_from_12_hours(double hoursAgo, int ageHours, bool urgent)
    {
        var aged = Item(ReportStatus.Open).Aged(Now.AddHours(-hoursAgo), Now);
        (aged.AgeHours, aged.Urgent).Should().Be((ageHours, urgent));
    }

    [Theory]
    [InlineData(ReportStatus.Resolved)]
    [InlineData(ReportStatus.Dismissed)]
    public void A_closed_case_has_no_age(ReportStatus status)
    {
        var aged = Item(status).Aged(Now.AddDays(-3), Now);
        (aged.AgeHours, aged.Urgent).Should().Be((null, false));
    }

    [Fact]
    public void A_system_report_has_no_reporter_keeps_its_terms_and_reopens_on_a_new_flag()
    {
        var report = Report.FileSystem(ReportTargetType.Comment, Guid.NewGuid(), ["alpha", "beta", "alpha"], Now);
        (report.IsSystem, report.ReporterId, report.Reason, report.Status).Should().Be((true, null, ReportReason.Other, ReportStatus.Open));
        report.MatchedTermList.Should().Equal("alpha", "beta");
        report.DomainEvents.OfType<ReportFiledDomainEvent>().Should().ContainSingle();

        report.ClearDomainEvents();
        report.Dismiss(Guid.NewGuid(), Now.AddHours(1));
        report.DomainEvents.OfType<ReportClosedDomainEvent>().Single().Status.Should().Be(ReportStatus.Dismissed);

        report.ClearDomainEvents();
        report.Reflag(["gamma"], Now.AddHours(2));
        (report.Status, report.CreatedAt, report.ResolvedAt, report.ResolvedById).Should().Be((ReportStatus.Open, Now.AddHours(2), null, null));
        report.MatchedTermList.Should().Equal("gamma");
        report.DomainEvents.OfType<ReportFiledDomainEvent>().Should().ContainSingle("staff are told again");
    }

    [Fact]
    public void Flagging_an_open_system_report_again_only_updates_its_terms()
    {
        var report = Report.FileSystem(ReportTargetType.Article, Guid.NewGuid(), ["alpha"], Now);
        report.ClearDomainEvents();
        report.Reflag(["beta"], Now.AddHours(1));
        (report.Status, report.CreatedAt).Should().Be((ReportStatus.Open, Now));
        report.MatchedTermList.Should().Equal("beta");
        report.DomainEvents.Should().BeEmpty();
    }

    [Fact]
    public void Matched_terms_are_kept_within_their_column()
    {
        var report = Report.FileSystem(ReportTargetType.Article, Guid.NewGuid(), [.. Enumerable.Range(0, 100).Select(i => $"term-number-{i}")], Now);
        report.MatchedTerms!.Length.Should().BeLessThanOrEqualTo(Report.MaxMatchedTermsLength);
    }

    [Theory]
    [InlineData("article", false, "بلاغ جديد عن مقال", "New report: article")]
    [InlineData("comment", false, "بلاغ جديد عن تعليق", "New report: comment")]
    [InlineData("user", false, "بلاغ جديد عن حساب", "New report: account")]
    [InlineData("repost", false, "بلاغ جديد عن إعادة نشر", "New report: repost")]
    [InlineData("comment", true, "بلاغ جديد من فلتر المحتوى", "New report from the content filter")]
    public void Report_new_names_the_kind_of_target_or_the_content_filter(string targetType, bool system, string arabic, string english)
    {
        var data = new NotificationData { TargetType = targetType, System = system ? true : null };
        NotificationTexts.ReportNewTitle(english: false, data).Should().Be(arabic);
        NotificationTexts.ReportNewTitle(english: true, data).Should().Be(english);
    }

    [Theory]
    [InlineData(ReportOutcomes.Actioned, "article", "راجعنا بلاغك وأزلنا المحتوى", "We reviewed your report and removed the content")]
    [InlineData(ReportOutcomes.Actioned, "comment", "راجعنا بلاغك وأزلنا المحتوى", "We reviewed your report and removed the content")]
    [InlineData(ReportOutcomes.Actioned, "user", "راجعنا بلاغك واتخذنا الإجراء المناسب", "We reviewed your report and took action")]
    [InlineData(ReportOutcomes.NoViolation, "article", "راجعنا بلاغك، والمحتوى لا يخالف قواعد المجتمع", "We reviewed your report; the content doesn't break our guidelines")]
    [InlineData(ReportOutcomes.NoViolation, "user", "راجعنا بلاغك، والمحتوى لا يخالف قواعد المجتمع", "We reviewed your report; the content doesn't break our guidelines")]
    public void Report_resolved_tells_the_outcome_but_never_the_action_on_a_user(string outcome, string targetType, string arabic, string english)
    {
        var data = new NotificationData { Outcome = outcome, TargetType = targetType };
        NotificationTexts.ReportResolvedTitle(english: false, data).Should().Be(arabic);
        NotificationTexts.ReportResolvedTitle(english: true, data).Should().Be(english);
    }

    [Fact]
    public void Report_new_opens_its_case_and_report_resolved_the_center()
    {
        var id = Guid.NewGuid();
        NotificationLinks.For(NotificationTypes.ReportNew, 0, null, "me", null, null, reportTargetType: "comment", reportTargetId: id)
            .Should().Be($"readin://admin/reports/comment/{id}");
        NotificationLinks.For(NotificationTypes.ReportResolved, 0, null, "me", null, null).Should().Be(NotificationLinks.Center);
    }

    [Fact]
    public void Only_moderators_can_set_report_new_and_nobody_can_set_report_resolved()
    {
        NotificationTypes.ConfigurableFor(managesSupport: false).Should().NotContain(NotificationTypes.ReportNew);
        NotificationTypes.ConfigurableFor(managesSupport: false, managesModeration: true).Should().Contain(NotificationTypes.ReportNew)
            .And.NotContain(NotificationTypes.SupportTicket);
        NotificationTypes.IsConfigurable(NotificationTypes.ReportResolved).Should().BeFalse();
        NotificationTypes.IsKnown(NotificationTypes.ReportResolved).Should().BeTrue();
    }

    [Fact]
    public void Reposts_can_be_deleted_or_dismissed_and_nothing_else()
    {
        ModerationVerbs.Allows(ModerationVerbs.Delete, ReportTargetType.Repost).Should().BeTrue();
        ModerationVerbs.Allows(ModerationVerbs.Dismiss, ReportTargetType.Repost).Should().BeTrue();
        ModerationVerbs.Allows(ModerationVerbs.Hide, ReportTargetType.Repost).Should().BeFalse();
        ModerationVerbs.Allows(ModerationVerbs.Warn, ReportTargetType.Repost).Should().BeFalse();
    }
}
