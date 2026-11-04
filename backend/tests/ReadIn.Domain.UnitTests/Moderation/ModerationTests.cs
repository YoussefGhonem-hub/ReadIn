using ReadIn.Domain.Articles;
using ReadIn.Domain.Moderation;
using ReadIn.Domain.Users;

namespace ReadIn.Domain.UnitTests.Moderation;

/// <summary>SPEC F22: hidden articles, closing reports, and the moderation log with its notices.</summary>
public sealed class ModerationTests
{
    private static readonly DateTime Now = new(2026, 11, 4, 9, 0, 0, DateTimeKind.Utc);
    private static readonly Guid Moderator = Guid.NewGuid();
    private static readonly Guid UserId = Guid.NewGuid();

    private static ModerationAction WithId(ModerationAction action)
    {
        typeof(ModerationAction).GetProperty(nameof(ModerationAction.Id))!.SetValue(action, Guid.NewGuid()); // EF assigns it on Add
        return action;
    }

    [Fact]
    public void Hiding_an_article_is_idempotent_and_unhiding_clears_it()
    {
        var article = Article.CreateDraft(UserId, Guid.NewGuid(), topicId: null, "hidden-article");

        article.Hide(Moderator, Now);
        article.Hide(Guid.NewGuid(), Now.AddHours(1));

        article.IsHidden.Should().BeTrue();
        article.HiddenAt.Should().Be(Now, "hiding again changes nothing");
        article.HiddenById.Should().Be(Moderator);

        article.Unhide();
        article.IsHidden.Should().BeFalse();
        article.HiddenById.Should().BeNull();
    }

    [Fact]
    public void A_report_is_resolved_or_dismissed_once()
    {
        var resolved = Report.File(ReportTargetType.Article, Guid.NewGuid(), UserId, ReportReason.Spam, "  إعلان  ", Now);
        var dismissed = Report.File(ReportTargetType.User, Guid.NewGuid(), UserId, ReportReason.Other, " ", Now);

        resolved.Resolve(Moderator, Now.AddHours(1));
        resolved.Dismiss(Guid.NewGuid(), Now.AddHours(2));
        dismissed.Dismiss(Moderator, Now.AddHours(3));
        dismissed.Resolve(Guid.NewGuid(), Now.AddHours(4));

        resolved.Details.Should().Be("إعلان");
        resolved.Should().BeEquivalentTo(new { Status = ReportStatus.Resolved, ResolvedAt = Now.AddHours(1), ResolvedById = Moderator });
        dismissed.Details.Should().BeNull();
        dismissed.Should().BeEquivalentTo(new { Status = ReportStatus.Dismissed, ResolvedAt = Now.AddHours(3), ResolvedById = Moderator });
    }

    [Fact]
    public void A_warning_is_a_notice_that_raises_its_push_event()
    {
        var warning = WithId(ModerationAction.Warning(UserId, "reader7", Moderator, "  No spam links.  ", reportsClosed: 2, Now));

        warning.Should().BeEquivalentTo(new
        {
            Action = ModerationActionTypes.UserWarn,
            TargetType = ReportTargetType.User,
            TargetId = UserId,
            TargetUserId = (Guid?)UserId,
            ModeratorId = (Guid?)Moderator,
            TargetLabel = "@reader7",
            Note = "No spam links.",
            ReportsClosed = 2,
            NoticeKind = NoticeKinds.Warning,
            AcknowledgedAt = (DateTime?)null,
        });
        warning.DomainEvents.Should().ContainSingle()
            .Which.Should().BeOfType<ModerationNoticeIssuedDomainEvent>().Which.NoticeId.Should().Be(warning.Id);

        warning.Acknowledge(Now.AddHours(1));
        warning.Acknowledge(Now.AddHours(2));
        warning.AcknowledgedAt.Should().Be(Now.AddHours(1), "acknowledging is idempotent");
    }

    [Fact]
    public void Warnings_and_suspensions_need_a_note_of_at_most_500_characters()
    {
        FluentActions.Invoking(() => ModerationAction.Warning(UserId, "reader7", Moderator, " ", 0, Now)).Should().Throw<ArgumentException>();
        FluentActions.Invoking(() => ModerationAction.Suspension(UserId, "reader7", Moderator, "", null, 0, Now)).Should().Throw<ArgumentException>();
        FluentActions.Invoking(() => ModerationAction.OnComment(ModerationActionTypes.CommentHide, Guid.NewGuid(), UserId, "x", Moderator,
            new string('n', ModerationAction.MaxNoteLength + 1), 0, Now)).Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Only_a_hide_that_changed_the_article_notifies_its_author()
    {
        var articleId = Guid.NewGuid();
        var hidden = ModerationAction.OnArticle(ModerationActionTypes.ArticleHide, articleId, UserId, "RAG vs fine-tuning", Moderator, null, 1, Now);
        var rehidden = ModerationAction.OnArticle(ModerationActionTypes.ArticleHide, articleId, UserId, "RAG", Moderator, null, 1, Now,
            notifyAuthor: false);
        var unhidden = ModerationAction.OnArticle(ModerationActionTypes.ArticleUnhide, articleId, UserId, "RAG", Moderator, null, 0, Now);

        hidden.NoticeKind.Should().Be(NoticeKinds.ArticleHidden);
        hidden.TargetLabel.Should().Be("RAG vs fine-tuning");
        hidden.DomainEvents.Should().ContainSingle();
        rehidden.IsNotice.Should().BeFalse();
        unhidden.IsNotice.Should().BeFalse();
        unhidden.DomainEvents.Should().BeEmpty();
        FluentActions.Invoking(() => ModerationAction.OnArticle(ModerationActionTypes.UserWarn, articleId, UserId, "x", Moderator, null, 0, Now))
            .Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Comment_labels_are_the_first_80_characters_on_one_line()
    {
        var body = "سطر أول\n\nسطر تاني " + new string('x', 100);
        var hidden = ModerationAction.OnComment(ModerationActionTypes.CommentHide, Guid.NewGuid(), null, body, Moderator, null, 0, Now);
        var emoji = ModerationAction.OnComment(ModerationActionTypes.CommentDelete, Guid.NewGuid(), UserId, new string('a', 79) + "🔥🔥", Moderator,
            null, 0, Now);

        hidden.TargetLabel.Should().HaveLength(ModerationAction.CommentLabelLength).And.StartWith("سطر أول سطر تاني x");
        hidden.TargetUserId.Should().BeNull("the author deleted their account");
        emoji.TargetLabel.Should().Be(new string('a', 79), "a surrogate pair is never split");
        FluentActions.Invoking(() => ModerationAction.OnComment(ModerationActionTypes.ArticleHide, Guid.NewGuid(), UserId, "x", Moderator, null, 0, Now))
            .Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Suspensions_keep_their_end_and_dismissals_count_their_reports()
    {
        var until = Now.AddDays(7);
        var suspension = ModerationAction.Suspension(UserId, "reader7", Moderator, "Spam.", until, 3, Now);
        var dismissal = ModerationAction.Dismissal(ReportTargetType.Comment, Guid.NewGuid(), UserId, "تعليق عادي", Moderator, null, 2, Now);

        suspension.SuspendedUntil.Should().Be(until);
        suspension.IsNotice.Should().BeFalse();
        dismissal.Should().BeEquivalentTo(new { Action = ModerationActionTypes.ReportsDismiss, ReportsClosed = 2, TargetLabel = "تعليق عادي" });
        FluentActions.Invoking(() => ModerationAction.Dismissal(ReportTargetType.User, UserId, UserId, "@reader7", Moderator, null, 0, Now))
            .Should().Throw<ArgumentOutOfRangeException>("a dismissal closes at least one report");
    }

    [Fact]
    public void A_temporary_suspension_ends_by_itself()
    {
        var user = User.CreateSeeded("+12025550199", "Reader", "reader_x");

        user.Suspend(Now.AddDays(1));

        user.IsSuspendedAt(Now).Should().BeTrue();
        user.IsSuspendedAt(Now.AddDays(1)).Should().BeFalse("it ends at suspendedUntil");
        user.DomainEvents.OfType<UserRolesChangedDomainEvent>().Should().NotBeEmpty("the cached access is dropped");
    }
}
