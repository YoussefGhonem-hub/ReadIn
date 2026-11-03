using ReadIn.Domain.Users;

namespace ReadIn.Domain.UnitTests.Users;

/// <summary>Following fields and topics one at a time (SPEC F02, F12).</summary>
public sealed class InterestTests
{
    private static readonly Guid[] Fields = [Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()];

    private static User Onboarded()
    {
        var user = User.Register("+12015550101", "password-hash", "reader_abc123", Guid.NewGuid());
        user.SetInterests(Fields, []).IsSuccess.Should().BeTrue();
        return user;
    }

    [Fact]
    public void Following_is_idempotent()
    {
        var user = Onboarded();
        var topic = Guid.NewGuid();

        user.FollowField(Fields[0]);
        user.FollowTopic(topic);
        user.FollowTopic(topic);

        user.Interests.Should().HaveCount(4);
        user.Interests.Should().ContainSingle(i => i.TopicId == topic);
    }

    [Fact]
    public void Unfollowing_never_leaves_fewer_than_three()
    {
        var user = Onboarded();

        user.UnfollowField(Fields[0]).Error.Should().Be(UserErrors.InterestsMinThree);
        user.Interests.Should().HaveCount(3);

        var topic = Guid.NewGuid();
        user.FollowTopic(topic);
        user.UnfollowField(Fields[0]).IsSuccess.Should().BeTrue("three remain");
        user.UnfollowTopic(topic).Error.Should().Be(UserErrors.InterestsMinThree);
    }

    [Fact]
    public void Unfollowing_what_you_do_not_follow_is_a_no_op()
    {
        var user = Onboarded();

        user.UnfollowTopic(Guid.NewGuid()).IsSuccess.Should().BeTrue();
        user.Interests.Should().HaveCount(3);
    }
}
