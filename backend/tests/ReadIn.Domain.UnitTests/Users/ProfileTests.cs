using ReadIn.Domain.Users;

namespace ReadIn.Domain.UnitTests.Users;

/// <summary>Fields of expertise and the reading stats privacy setting (SPEC F14, F18).</summary>
public sealed class ProfileTests
{
    private static readonly Guid[] Fields = [.. Enumerable.Range(0, 6).Select(_ => Guid.NewGuid())];

    private static User NewUser() => User.Register("+12015550101", "password-hash", "reader_abc123", Guid.NewGuid());

    private static IEnumerable<Guid> Ordered(User user) => user.Expertise.OrderBy(e => e.Position).Select(e => e.FieldId);

    [Fact]
    public void Expertise_keeps_the_given_order()
    {
        var user = NewUser();

        user.SetExpertise([Fields[2], Fields[0], Fields[1]]).IsSuccess.Should().BeTrue();

        Ordered(user).Should().Equal(Fields[2], Fields[0], Fields[1]);
        user.Expertise.Select(e => e.Position).Should().BeEquivalentTo([0, 1, 2]);
    }

    [Fact]
    public void A_repeated_field_counts_once()
    {
        var user = NewUser();

        user.SetExpertise([Fields[0], Fields[1], Fields[0], Fields[2], Fields[3], Fields[4], Fields[1]]).IsSuccess.Should().BeTrue();

        Ordered(user).Should().Equal(Fields[..5]);
    }

    [Fact]
    public void More_than_five_fields_are_refused_and_nothing_changes()
    {
        var user = NewUser();
        user.SetExpertise([Fields[0]]);

        user.SetExpertise(Fields).Error.Should().Be(ProfileErrors.ExpertiseInvalid);

        Ordered(user).Should().Equal(Fields[0]);
        User.MaxExpertiseFields.Should().Be(5);
    }

    [Fact]
    public void Replacing_moves_the_rows_that_stay_instead_of_adding_them_again()
    {
        var user = NewUser();
        user.SetExpertise([Fields[0], Fields[1], Fields[2]]);
        var kept = user.Expertise.Single(e => e.FieldId == Fields[1]);

        user.SetExpertise([Fields[1], Fields[3]]).IsSuccess.Should().BeTrue();

        Ordered(user).Should().Equal(Fields[1], Fields[3]);
        user.Expertise.Should().Contain(kept, "the same row is reused, so its key is never deleted and inserted in one save");
        kept.Position.Should().Be(0);
    }

    [Fact]
    public void An_empty_list_clears_the_expertise()
    {
        var user = NewUser();
        user.SetExpertise([Fields[0], Fields[1]]);

        user.SetExpertise([]).IsSuccess.Should().BeTrue();

        user.Expertise.Should().BeEmpty();
    }

    [Fact]
    public void Reading_stats_are_private_by_default()
    {
        var user = NewUser();
        user.PublicReadingStats.Should().BeFalse();

        user.SetPrivacy(publicReadingStats: true);
        user.PublicReadingStats.Should().BeTrue();

        user.SetPrivacy(publicReadingStats: false);
        user.PublicReadingStats.Should().BeFalse();
    }
}
