using ReadIn.Application.Features.Admin.Tags;
using ReadIn.Application.Features.Admin.Taxonomy;

namespace ReadIn.Application.UnitTests.Admin;

/// <summary>
/// F23 tag merge (contract "Taxonomy and tags"): the merged tag's place goes to the tag it went into, an article that has
/// both keeps it once at the first place, and nothing else moves; and the console's order lists hold every item once.
/// </summary>
public sealed class TagMergeTests
{
    private static readonly Guid A = Guid.Parse("00000000-0000-0000-0000-00000000000a");
    private static readonly Guid B = Guid.Parse("00000000-0000-0000-0000-00000000000b");
    private static readonly Guid C = Guid.Parse("00000000-0000-0000-0000-00000000000c");
    private static readonly Guid D = Guid.Parse("00000000-0000-0000-0000-00000000000d");

    [Fact]
    public void The_merged_tag_s_place_goes_to_the_other_tag() =>
        TagMerge.Replace([C, A, D], from: A, into: B).Should().Equal(C, B, D);

    [Fact]
    public void An_article_with_both_keeps_the_other_tag_once_at_the_first_place()
    {
        TagMerge.Replace([A, C, B], from: A, into: B).Should().Equal(B, C);
        TagMerge.Replace([B, C, A], from: A, into: B).Should().Equal(B, C);
    }

    [Fact]
    public void An_article_never_gains_a_tag()
    {
        IReadOnlyList<Guid> five = [A, C, D, Guid.NewGuid(), Guid.NewGuid()];
        TagMerge.Replace(five, from: A, into: B).Should().HaveCount(5);
        TagMerge.Replace([C, D], from: A, into: B).Should().Equal(new[] { C, D }, "an article without the merged tag doesn't change");
    }

    [Fact]
    public void An_order_list_holds_every_item_exactly_once()
    {
        AdminOrder.IsPermutation([B, A, C], [A, B, C]).Should().BeTrue();
        AdminOrder.IsPermutation([A, B], [A, B, C]).Should().BeFalse("one is missing");
        AdminOrder.IsPermutation([A, B, B], [A, B, C]).Should().BeFalse("a repeat");
        AdminOrder.IsPermutation([A, B, D], [A, B, C]).Should().BeFalse("an unknown id");
        AdminOrder.IsPermutation(null, [A]).Should().BeFalse();
        AdminOrder.IsPermutation([], []).Should().BeTrue();
    }
}
