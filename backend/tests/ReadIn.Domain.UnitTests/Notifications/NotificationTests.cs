using ReadIn.Domain.Notifications;
using ReadIn.Domain.Users;

namespace ReadIn.Domain.UnitTests.Notifications;

/// <summary>SPEC F17: an entry's aggregation, seen and read states, and its push lifecycle.</summary>
public sealed class NotificationTests
{
    private static readonly DateTime Now = new(2026, 11, 4, 9, 0, 0, DateTimeKind.Utc);
    private static readonly Guid UserId = Guid.NewGuid();
    private static readonly Guid Ahmed = Guid.NewGuid();
    private static readonly Guid Mona = Guid.NewGuid();

    private static Notification Comments(DateTime at, DateTime? pushAfter = null) =>
        Notification.Create(UserId, NotificationTypes.ArticleComment, at, pushAfter ?? at, groupKey: "article_comment:1",
            commentId: Guid.NewGuid(), actorId: Ahmed, actorAt: at);

    [Fact]
    public void A_new_entry_has_its_first_actor_and_a_pending_push_unless_it_has_none()
    {
        var pushed = Comments(Now);
        pushed.Actors.Should().ContainSingle().Which.Should().Match<NotificationActor>(a => a.ActorId == Ahmed && a.At == Now);
        (pushed.PushStatus, pushed.PushAfter, pushed.PushAttempts).Should().Be((NotificationPushStatus.Pending, Now, 0));
        (pushed.CreatedAt, pushed.UpdatedAt, pushed.SeenAt, pushed.ReadAt).Should().Be((Now, Now, null, null));

        var inApp = Notification.Create(UserId, NotificationTypes.StreakReminder, Now, pushAfter: null, dedupeKey: "streak_reminder:2026-11-04");
        inApp.PushStatus.Should().Be(NotificationPushStatus.None);
        inApp.Actors.Should().BeEmpty();

        var unknown = () => Notification.Create(UserId, "fan_mail", Now, null);
        unknown.Should().Throw<ArgumentOutOfRangeException>();
    }

    [Fact]
    public void New_activity_moves_the_entry_up_as_unread_and_arms_its_push_again()
    {
        var entry = Comments(Now);
        entry.MarkPushed(Now.AddMinutes(1));
        entry.MarkRead(Now.AddMinutes(2));
        var latest = Guid.NewGuid();

        var later = Now.AddHours(1);
        entry.AddActivity(Mona, later, latest, repeatsCount: true, later, pushAfter: later).Should().BeTrue();

        entry.Actors.Select(a => a.ActorId).Should().Equal(Ahmed, Mona);
        entry.CommentId.Should().Be(latest, "an aggregated entry points at the latest comment");
        (entry.UpdatedAt, entry.SeenAt, entry.ReadAt).Should().Be((later, null, null));
        (entry.PushStatus, entry.PushAfter, entry.PushAttempts).Should().Be((NotificationPushStatus.Pending, later, 0));
    }

    [Fact]
    public void A_redelivered_event_changes_nothing_and_a_repeated_actor_counts_only_where_it_should()
    {
        var entry = Comments(Now);
        var commentId = entry.CommentId;

        entry.AddActivity(Ahmed, Now, Guid.NewGuid(), repeatsCount: true, Now.AddMinutes(5), Now.AddMinutes(5))
            .Should().BeFalse("the same activity again is an outbox retry");
        (entry.CommentId, entry.UpdatedAt).Should().Be((commentId, Now));

        entry.AddActivity(Ahmed, Now.AddMinutes(10), Guid.NewGuid(), repeatsCount: true, Now.AddMinutes(10), Now.AddMinutes(10))
            .Should().BeTrue("a second comment by the same person is news");
        entry.Actors.Should().ContainSingle().Which.At.Should().Be(Now.AddMinutes(10));

        var followers = Notification.Create(UserId, NotificationTypes.NewFollower, Now, Now, groupKey: "new_follower:2026-11-04",
            actorId: Ahmed, actorAt: Now);
        followers.AddActivity(Ahmed, Now.AddMinutes(10), null, repeatsCount: false, Now.AddMinutes(10), Now.AddMinutes(10))
            .Should().BeFalse("following again the same day is not news");
    }

    [Fact]
    public void Only_an_unread_entry_that_moved_in_the_last_24_hours_aggregates()
    {
        var entry = Comments(Now);

        entry.CanAggregate(Now.AddHours(23)).Should().BeTrue();
        entry.CanAggregate(Now.AddHours(25)).Should().BeFalse();

        entry.MarkSeen(Now.AddMinutes(1));
        entry.CanAggregate(Now.AddHours(1)).Should().BeTrue("seen is not read");
        entry.MarkRead(Now.AddMinutes(2));
        entry.CanAggregate(Now.AddHours(1)).Should().BeFalse();
    }

    [Fact]
    public void Seen_and_read_are_idempotent_and_read_implies_seen()
    {
        var entry = Comments(Now);

        entry.MarkSeen(Now.AddMinutes(1)).Should().BeTrue();
        entry.MarkSeen(Now.AddMinutes(2)).Should().BeFalse();
        entry.SeenAt.Should().Be(Now.AddMinutes(1));

        var unseen = Comments(Now);
        unseen.MarkRead(Now.AddMinutes(3)).Should().BeTrue();
        (unseen.SeenAt, unseen.ReadAt, unseen.IsRead).Should().Be((Now.AddMinutes(3), Now.AddMinutes(3), true));
        unseen.MarkRead(Now.AddMinutes(4)).Should().BeFalse();
        unseen.ReadAt.Should().Be(Now.AddMinutes(3));
    }

    [Fact]
    public void A_failed_push_is_retried_until_the_third_attempt_fails()
    {
        var entry = Comments(Now);

        entry.RecordPushFailure(Now.AddMinutes(1)).Should().BeTrue();
        (entry.PushStatus, entry.PushAfter, entry.PushAttempts).Should().Be((NotificationPushStatus.Pending, Now.AddMinutes(1), 1));
        entry.RecordPushFailure(Now.AddMinutes(6)).Should().BeTrue();
        entry.RecordPushFailure(Now.AddMinutes(20)).Should().BeFalse();
        (entry.PushStatus, entry.PushAfter, entry.PushAttempts).Should().Be((NotificationPushStatus.Failed, null, Notification.MaxPushAttempts));
    }

    [Fact]
    public void Deferring_moves_only_a_pending_push_and_sent_or_skipped_pushes_are_done()
    {
        var entry = Comments(Now);
        entry.DeferPush(Now.AddHours(8));
        entry.PushAfter.Should().Be(Now.AddHours(8));

        entry.MarkPushed(Now.AddHours(8));
        (entry.PushStatus, entry.PushedAt, entry.PushAfter).Should().Be((NotificationPushStatus.Sent, Now.AddHours(8), null));
        entry.DeferPush(Now.AddHours(9));
        entry.PushAfter.Should().BeNull();

        var skipped = Comments(Now);
        skipped.SkipPush();
        (skipped.PushStatus, skipped.PushAfter).Should().Be((NotificationPushStatus.Skipped, null));
    }

    [Fact]
    public void Only_configurable_types_have_settings_and_security_alerts_ignore_quiet_hours()
    {
        NotificationTypes.Configurable.Should().NotContain([NotificationTypes.SecurityAlert, NotificationTypes.ModerationNotice,
            NotificationTypes.VerificationResult]);
        NotificationTypes.All.Should().HaveCount(12, "article_reposted (F29) is the 12th").And.OnlyHaveUniqueItems();
        NotificationTypes.Configurable.Should().Contain(NotificationTypes.ArticleReposted).And.HaveCount(9);
        NotificationTypes.IgnoresQuietHours(NotificationTypes.SecurityAlert).Should().BeTrue();
        NotificationTypes.IgnoresQuietHours(NotificationTypes.ModerationNotice).Should().BeFalse();

        var setting = new UserNotificationSetting(UserId, NotificationTypes.Mention, NotificationMode.InApp);
        setting.Change(NotificationMode.Off);
        setting.Mode.Should().Be(NotificationMode.Off);
        var security = () => new UserNotificationSetting(UserId, NotificationTypes.SecurityAlert, NotificationMode.Off);
        security.Should().Throw<ArgumentOutOfRangeException>();
    }

    [Fact]
    public void Quiet_hours_default_to_23_to_7_and_need_two_different_times()
    {
        var user = User.CreateSeeded(null, "Night Owl", "night_owl");
        (user.QuietHoursEnabled, user.QuietHoursStart, user.QuietHoursEnd).Should().Be((true, new TimeOnly(23, 0), new TimeOnly(7, 0)));

        user.SetQuietHours(false, new TimeOnly(22, 30), new TimeOnly(6, 0));
        (user.QuietHoursEnabled, user.QuietHoursStart, user.QuietHoursEnd).Should().Be((false, new TimeOnly(22, 30), new TimeOnly(6, 0)));

        var empty = () => user.SetQuietHours(true, new TimeOnly(1, 0), new TimeOnly(1, 0));
        empty.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Seeing_or_reading_notifications_raises_the_badge_event()
    {
        var user = User.CreateSeeded(null, "Reader", "reader_badge");

        user.NotificationsChanged();

        user.DomainEvents.Should().ContainSingle().Which.Should().BeOfType<UserNotificationsChangedDomainEvent>();
    }
}
