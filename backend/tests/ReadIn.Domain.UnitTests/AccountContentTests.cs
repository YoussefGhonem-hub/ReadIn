using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;
using ReadIn.Domain.Moderation;

namespace ReadIn.Domain.UnitTests;

/// <summary>
/// The admin console's account content actions and featuring (SPEC F23): what hide_content flags, what any unhide clears,
/// and that featuring keeps the first time.
/// </summary>
public sealed class AccountContentTests
{
    private static readonly DateTime Now = new(2026, 11, 7, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Hiding_with_the_account_flags_only_what_it_hid_and_any_unhide_clears_the_flag()
    {
        var moderator = Guid.NewGuid();
        var article = Article.CreateDraft(Guid.NewGuid(), Guid.NewGuid(), null, "spam-article");
        article.HideWithAccount(moderator, Now).Should().BeTrue();
        (article.IsHidden, article.HiddenWithAccount, article.HiddenById).Should().Be((true, true, (Guid?)moderator));
        article.HideWithAccount(moderator, Now.AddMinutes(1)).Should().BeFalse("it was hidden already");
        article.HiddenAt.Should().Be(Now);
        article.Unhide();
        (article.IsHidden, article.HiddenWithAccount).Should().Be((false, false));

        var oneByOne = Article.CreateDraft(Guid.NewGuid(), Guid.NewGuid(), null, "hidden-alone");
        oneByOne.Hide(moderator, Now);
        oneByOne.HideWithAccount(moderator, Now).Should().BeFalse();
        oneByOne.HiddenWithAccount.Should().BeFalse("hidden one by one before: the undo must leave it hidden");

        var comment = Comment.Post(Guid.NewGuid(), Guid.NewGuid(), "Buy now", [], Now);
        comment.HideWithAccount(moderator, Now).Should().BeTrue();
        (comment.IsHidden, comment.HiddenWithAccount).Should().Be((true, true));
        comment.HideWithAccount(moderator, Now).Should().BeFalse();
        comment.Unhide();
        (comment.IsHidden, comment.HiddenWithAccount).Should().Be((false, false));
    }

    [Fact]
    public void Featuring_keeps_the_first_time_and_unfeaturing_says_whether_it_changed()
    {
        var article = Article.CreateDraft(Guid.NewGuid(), Guid.NewGuid(), null, "featured");
        var admin = Guid.NewGuid();
        article.Feature(admin, Now).Should().BeTrue();
        article.Feature(Guid.NewGuid(), Now.AddHours(1)).Should().BeFalse();
        (article.FeaturedAt, article.FeaturedById).Should().Be(((DateTime?)Now, (Guid?)admin));
        article.ForgetFeaturedBy();
        (article.FeaturedAt, article.FeaturedById).Should().Be(((DateTime?)Now, (Guid?)null), "it stays featured without the deleted account");
        article.Unfeature().Should().BeTrue();
        article.Unfeature().Should().BeFalse();
        article.FeaturedAt.Should().BeNull();
    }

    [Fact]
    public void Account_content_actions_are_logged_on_the_user_without_a_notice()
    {
        var user = Guid.NewGuid();
        var hidden = ModerationAction.AccountContent(ModerationActionTypes.UserHideContent, user, "spammer", Guid.NewGuid(), " Spam ", 3, Now);
        (hidden.Action, hidden.TargetType, hidden.TargetId, hidden.TargetUserId, hidden.TargetLabel, hidden.Note, hidden.ReportsClosed)
            .Should().Be(("user.hide_content", ReportTargetType.User, user, (Guid?)user, "@spammer", "Spam", 3));
        hidden.IsNotice.Should().BeFalse();
        ModerationAction.AccountContent(ModerationActionTypes.UserUnhideContent, user, "spammer", Guid.NewGuid(), null, 0, Now).Action
            .Should().Be("user.unhide_content");
        FluentActions.Invoking(() => ModerationAction.AccountContent(ModerationActionTypes.UserWarn, user, "x", Guid.NewGuid(), null, 0, Now))
            .Should().Throw<ArgumentException>();
    }
}
