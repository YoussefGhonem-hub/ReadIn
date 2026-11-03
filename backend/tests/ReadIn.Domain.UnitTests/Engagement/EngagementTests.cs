using ReadIn.Domain.Articles;
using ReadIn.Domain.Engagement;

namespace ReadIn.Domain.UnitTests.Engagement;

public sealed class ReactionTests
{
    private static readonly Guid UserId = Guid.NewGuid();
    private static readonly Guid ArticleId = Guid.NewGuid();
    private static readonly DateTime Now = new(2026, 11, 3, 10, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void The_first_reaction_creates_one_and_raises_an_event()
    {
        var reaction = Reaction.Set(null, UserId, ArticleId, ReactionType.Fire, Now);

        reaction.Type.Should().Be(ReactionType.Fire);
        reaction.ReactedAt.Should().Be(Now);
        var raised = reaction.DomainEvents.Should().ContainSingle().Which.Should().BeOfType<ReactionChangedDomainEvent>().Subject;
        (raised.ArticleId, raised.UserId, raised.Type).Should().Be((ArticleId, UserId, ReactionType.Fire));
    }

    [Fact]
    public void Reacting_again_changes_the_same_reaction() // one reaction per user per article (SPEC F10)
    {
        var first = Reaction.Set(null, UserId, ArticleId, ReactionType.Insightful, Now);
        first.ClearDomainEvents();

        var second = Reaction.Set(first, UserId, ArticleId, ReactionType.MindBlown, Now.AddMinutes(5));

        second.Should().BeSameAs(first);
        second.Type.Should().Be(ReactionType.MindBlown);
        second.ReactedAt.Should().Be(Now.AddMinutes(5), "a changed reaction moves to the top of \"who reacted\"");
        second.DomainEvents.Should().ContainSingle(e => ((ReactionChangedDomainEvent)e).Type == ReactionType.MindBlown);
    }

    [Fact]
    public void Choosing_the_same_reaction_changes_nothing()
    {
        var reaction = Reaction.Set(null, UserId, ArticleId, ReactionType.Love, Now);
        reaction.ClearDomainEvents();

        Reaction.Set(reaction, UserId, ArticleId, ReactionType.Love, Now.AddHours(1));

        reaction.ReactedAt.Should().Be(Now);
        reaction.DomainEvents.Should().BeEmpty("nothing to recompute");
    }

    [Fact]
    public void Another_users_reaction_can_not_be_changed()
    {
        var reaction = Reaction.Set(null, UserId, ArticleId, ReactionType.Love, Now);

        var act = () => Reaction.Set(reaction, Guid.NewGuid(), ArticleId, ReactionType.Fire, Now);

        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Removing_raises_an_event_without_a_type()
    {
        var reaction = Reaction.Set(null, UserId, ArticleId, ReactionType.Love, Now);
        reaction.ClearDomainEvents();

        reaction.Remove();

        reaction.DomainEvents.Should().ContainSingle(e => ((ReactionChangedDomainEvent)e).Type == null);
    }

    [Theory]
    [InlineData("insightful", ReactionType.Insightful)]
    [InlineData("love", ReactionType.Love)]
    [InlineData("fire", ReactionType.Fire)]
    [InlineData("mindBlown", ReactionType.MindBlown)]
    [InlineData("MINDBLOWN", ReactionType.MindBlown)]
    public void Api_names_parse(string value, ReactionType expected)
    {
        ReactionTypes.TryParse(value, out var type).Should().BeTrue();
        type.Should().Be(expected);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("like")]
    [InlineData("1")]
    [InlineData("mind_blown")]
    public void Anything_else_is_refused(string? value) => ReactionTypes.TryParse(value, out _).Should().BeFalse();

    [Fact]
    public void Article_counters_keep_the_total_equal_to_the_sum()
    {
        var article = Article.CreateDraft(Guid.NewGuid(), Guid.NewGuid(), null, "counters");

        article.ApplyCounters(new ReactionCounts(4, 3, 2, 1), comments: 5, saves: 6, reads: 7);

        (article.InsightfulCount, article.LoveCount, article.FireCount, article.MindBlownCount).Should().Be((4, 3, 2, 1));
        article.ReactionCount.Should().Be(10);
        article.SaveCount.Should().Be(6);
    }
}

public sealed class SavedArticleTests
{
    private static readonly DateTime Now = new(2026, 11, 3, 10, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Saving_and_unsaving_raise_events_for_the_counters()
    {
        var articleId = Guid.NewGuid();
        var saved = SavedArticle.Create(Guid.NewGuid(), articleId, Now);

        saved.SavedAt.Should().Be(Now);
        saved.DomainEvents.Should().ContainSingle(e => ((ArticleSaveChangedDomainEvent)e).IsSaved && ((ArticleSaveChangedDomainEvent)e).ArticleId == articleId);

        saved.ClearDomainEvents();
        saved.Remove();
        saved.DomainEvents.Should().ContainSingle(e => !((ArticleSaveChangedDomainEvent)e).IsSaved);
    }
}

public sealed class CollectionTests
{
    private static readonly Guid UserId = Guid.NewGuid();
    private static readonly DateTime Now = new(2026, 11, 3, 10, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Names_are_trimmed()
    {
        var collection = Collection.Create(UserId, "  Interview prep  ", existingCount: 0, Now).Value;

        collection.Name.Should().Be("Interview prep");
        collection.CreatedAt.Should().Be(Now);
    }

    [Fact]
    public void A_user_has_at_most_fifty_collections()
    {
        Collection.Create(UserId, "Fiftieth", existingCount: Collection.MaxPerUser - 1, Now).IsSuccess.Should().BeTrue();

        Collection.Create(UserId, "Fifty-first", existingCount: Collection.MaxPerUser, Now).Error.Should().Be(CollectionErrors.LimitReached);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Empty_names_are_a_programming_error(string name)
    {
        var act = () => Collection.Create(UserId, name, 0, Now);

        act.Should().Throw<ArgumentException>("requests are validated before they reach the domain");
    }

    [Fact]
    public void Names_longer_than_sixty_characters_are_refused()
    {
        var collection = Collection.Create(UserId, new string('a', Collection.MaxNameLength), 0, Now).Value;

        var act = () => collection.Rename(new string('a', Collection.MaxNameLength + 1));

        act.Should().Throw<ArgumentOutOfRangeException>();
    }

    [Fact]
    public void Articles_are_added_and_removed_once()
    {
        var collection = Collection.Create(UserId, "Later", 0, Now).Value;
        var articleId = Guid.NewGuid();

        collection.AddArticle(articleId, Now).Should().BeTrue();
        collection.AddArticle(articleId, Now).Should().BeFalse("adding twice is idempotent");
        collection.Items.Should().ContainSingle();

        collection.RemoveArticle(articleId).Should().BeTrue();
        collection.RemoveArticle(articleId).Should().BeFalse();
        collection.Items.Should().BeEmpty();
    }
}

public sealed class UserFollowTests
{
    private static readonly DateTime Now = new(2026, 11, 3, 10, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Nobody_follows_themselves()
    {
        var userId = Guid.NewGuid();

        UserFollow.Create(userId, userId, Now).Error.Should().Be(FollowErrors.Self);
    }

    [Fact]
    public void Following_raises_the_new_follower_event()
    {
        var (follower, followee) = (Guid.NewGuid(), Guid.NewGuid());

        var follow = UserFollow.Create(follower, followee, Now).Value;

        follow.CreatedAt.Should().Be(Now);
        follow.DomainEvents.Should().ContainSingle(e =>
            ((UserFollowedDomainEvent)e).FollowerId == follower && ((UserFollowedDomainEvent)e).FolloweeId == followee);
    }
}
