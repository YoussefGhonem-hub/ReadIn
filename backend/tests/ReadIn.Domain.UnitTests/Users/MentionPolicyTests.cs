using ReadIn.Domain.Articles;
using ReadIn.Domain.Users;

namespace ReadIn.Domain.UnitTests.Users;

/// <summary>"Who can mention me" (SPEC F18): the rule, the account checks and the setting itself.</summary>
public sealed class MentionPolicyTests
{
    private static readonly DateTime Now = new(2026, 11, 4, 12, 0, 0, DateTimeKind.Utc);
    private static readonly Guid AuthorId = Guid.NewGuid();

    private static User NewUser(Guid? id = null, bool systemAccount = false) =>
        User.CreateSeeded("+12015550101", "Mentioned", "mentioned_one", id ?? Guid.NewGuid(), systemAccount);

    [Theory]
    [InlineData(MentionPolicy.Everyone, false, false, true)]
    [InlineData(MentionPolicy.Everyone, false, true, true)]
    [InlineData(MentionPolicy.Following, false, true, true)]
    [InlineData(MentionPolicy.Following, false, false, false)]
    [InlineData(MentionPolicy.Nobody, false, true, false)]
    [InlineData(MentionPolicy.Nobody, false, false, false)]
    [InlineData(MentionPolicy.Nobody, true, false, true)]
    [InlineData(MentionPolicy.Following, true, false, true)]
    public void The_setting_decides_and_you_may_always_mention_yourself(MentionPolicy policy, bool isSelf, bool followsAuthor, bool allowed) =>
        MentionRules.Allows(policy, isSelf, followsAuthor).Should().Be(allowed);

    [Fact]
    public void Everyone_is_the_default()
    {
        var user = NewUser();

        user.WhoCanMention.Should().Be(MentionPolicy.Everyone);
        user.CanBeMentionedBy(AuthorId, followsAuthor: false, Now).Should().BeTrue();
    }

    [Fact]
    public void People_i_follow_means_the_mentioned_user_follows_the_author()
    {
        var user = NewUser();
        user.SetPrivacy(whoCanMention: MentionPolicy.Following);

        user.CanBeMentionedBy(AuthorId, followsAuthor: true, Now).Should().BeTrue();
        user.CanBeMentionedBy(AuthorId, followsAuthor: false, Now).Should().BeFalse();
    }

    [Fact]
    public void Nobody_still_lets_you_mention_yourself()
    {
        var id = Guid.NewGuid();
        var user = NewUser(id);
        user.SetPrivacy(whoCanMention: MentionPolicy.Nobody);

        user.CanBeMentionedBy(AuthorId, followsAuthor: true, Now).Should().BeFalse();
        user.CanBeMentionedBy(id, followsAuthor: false, Now).Should().BeTrue();
    }

    [Fact]
    public void Suspended_and_system_accounts_are_never_linked()
    {
        var suspended = NewUser();
        suspended.Suspend(until: null);
        suspended.CanBeMentionedBy(AuthorId, followsAuthor: true, Now).Should().BeFalse();

        var forAWeek = NewUser();
        forAWeek.Suspend(until: Now.AddDays(7));
        forAWeek.CanBeMentionedBy(AuthorId, followsAuthor: true, Now).Should().BeFalse();
        forAWeek.CanBeMentionedBy(AuthorId, followsAuthor: true, Now.AddDays(8)).Should().BeTrue("the suspension is over");

        NewUser(systemAccount: true).CanBeMentionedBy(AuthorId, followsAuthor: true, Now).Should().BeFalse();
    }

    [Fact]
    public void Privacy_changes_only_the_settings_given()
    {
        var user = NewUser();

        user.SetPrivacy(whoCanMention: MentionPolicy.Nobody);
        user.WhoCanMention.Should().Be(MentionPolicy.Nobody);
        user.PublicReadingStats.Should().BeFalse();

        user.SetPrivacy(publicReadingStats: true);
        user.PublicReadingStats.Should().BeTrue();
        user.WhoCanMention.Should().Be(MentionPolicy.Nobody, "left out = unchanged");

        user.SetPrivacy(publicReadingStats: false, whoCanMention: MentionPolicy.Following);
        (user.PublicReadingStats, user.WhoCanMention).Should().Be((false, MentionPolicy.Following));

        var unknown = () => user.SetPrivacy(whoCanMention: (MentionPolicy)9);
        unknown.Should().Throw<ArgumentOutOfRangeException>();
        user.WhoCanMention.Should().Be(MentionPolicy.Following);
    }

    [Fact]
    public void Recording_mentions_raises_one_event_without_the_author()
    {
        var article = Article.CreateDraft(AuthorId, Guid.NewGuid(), topicId: null, "mentions");
        var mona = Guid.NewGuid();
        var omar = Guid.NewGuid();

        article.RecordMentions([mona, AuthorId, omar, mona]);

        var raised = article.DomainEvents.OfType<ArticleMentionsDomainEvent>().Should().ContainSingle().Subject;
        raised.AuthorId.Should().Be(AuthorId);
        raised.MentionedUserIds.Should().Equal(mona, omar);
    }

    [Fact]
    public void Mentioning_only_yourself_raises_nothing()
    {
        var article = Article.CreateDraft(AuthorId, Guid.NewGuid(), topicId: null, "self-mention");

        article.RecordMentions([AuthorId]);
        article.RecordMentions([]);

        article.DomainEvents.OfType<ArticleMentionsDomainEvent>().Should().BeEmpty();
    }
}
