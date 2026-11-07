using ReadIn.Application.Features.Moderation;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.UnitTests.Moderation;

/// <summary>The F23 user actions of POST /moderation/actions: where they apply, and which are allowed on protected accounts.</summary>
public sealed class ModerationVerbsTests
{
    [Theory]
    [InlineData("hide_content", ReportTargetType.User, true)]
    [InlineData("unhide_content", ReportTargetType.User, true)]
    [InlineData("hide_content", ReportTargetType.Article, false)]
    [InlineData("unhide_content", ReportTargetType.Comment, false)]
    [InlineData("suspend", ReportTargetType.User, true)]
    public void Account_content_actions_apply_to_users_only(string action, ReportTargetType target, bool allowed) =>
        ModerationVerbs.Allows(action, target).Should().Be(allowed);

    [Theory]
    [InlineData("hide_content", false)]
    [InlineData("suspend", false)]
    [InlineData("warn", false)]
    [InlineData("unsuspend", false)]
    [InlineData("unhide_content", true)]
    [InlineData("dismiss", true)]
    [InlineData("clear_links", true)]
    [InlineData("clear_headline", true)]
    [InlineData("clear_category", true)]
    public void Only_actions_that_take_nothing_away_skip_the_protected_accounts(string action, bool unprotected) =>
        ModerationVerbs.IsUnprotected(action).Should().Be(unprotected);

    [Fact]
    public void Account_content_actions_close_no_reports_of_the_user_themselves() =>
        new[] { ModerationVerbs.HideContent, ModerationVerbs.UnhideContent }.Should().OnlyContain(a => !ModerationVerbs.ClosesReports(a));
}
