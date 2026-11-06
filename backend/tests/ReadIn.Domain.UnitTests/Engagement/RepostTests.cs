using ReadIn.Domain.Common;
using ReadIn.Domain.Engagement;

namespace ReadIn.Domain.UnitTests.Engagement;

/// <summary>F29 reposts and their caption ("repost with your thoughts").</summary>
public sealed class RepostTests
{
    private static readonly Guid UserId = Guid.NewGuid();
    private static readonly Guid ArticleId = Guid.NewGuid();
    private static readonly DateTime Now = new(2026, 11, 6, 10, 0, 0, DateTimeKind.Utc);

    private static void ShouldBeTooLong(Error? error)
    {
        error.Should().NotBeNull();
        error!.Code.Should().Be("validation.failed");
        error.Type.Should().Be(ErrorType.Validation);
        error.Details.Should().ContainKey("caption").WhoseValue.Should().Equal("repost.caption_too_long");
    }

    [Fact]
    public void A_new_repost_raises_one_event_and_keeps_its_caption()
    {
        var repost = Repost.Create(UserId, ArticleId, "رأيي: مقال مفيد جدًا for .NET devs", Now).Value;

        (repost.UserId, repost.ArticleId, repost.CreatedAt).Should().Be((UserId, ArticleId, Now));
        repost.Caption.Should().Be("رأيي: مقال مفيد جدًا for .NET devs", "mixed Arabic and English is kept as is");
        var raised = repost.DomainEvents.Should().ContainSingle().Which.Should().BeOfType<RepostChangedDomainEvent>().Subject;
        (raised.ArticleId, raised.UserId, raised.IsReposted, raised.OccurredAt).Should().Be((ArticleId, UserId, true, Now));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(" \r\n\t \n ")]
    public void No_caption_or_only_spaces_is_none(string? caption)
    {
        Repost.Create(UserId, ArticleId, caption, Now).Value.Caption.Should().BeNull();
        Repost.NormalizeCaption(caption).Should().BeNull();
    }

    [Fact]
    public void A_caption_is_trimmed_with_unified_line_breaks()
    {
        Repost.NormalizeCaption("  أول سطر\r\nsecond line\r\n\r\n  third  \r\n ").Should().Be("أول سطر\nsecond line\n\n  third");
        Repost.NormalizeCaption("one\rtwo").Should().Be("one\ntwo", "a lone carriage return is a line break too");
        Repost.NormalizeCaption("<b>not markup</b> & @mention").Should().Be("<b>not markup</b> & @mention", "plain text, kept as typed");
    }

    [Fact]
    public void At_most_500_characters_after_trimming()
    {
        var longest = new string('ع', Repost.MaxCaptionLength);

        Repost.Create(UserId, ArticleId, $"  \r\n{longest}\r\n  ", Now).Value.Caption.Should().Be(longest, "the spaces around it don't count");
        Repost.CaptionFits($"   {longest}   ").Should().BeTrue();
        Repost.CaptionFits(null).Should().BeTrue();

        var tooLong = longest + "x";
        Repost.CaptionFits(tooLong).Should().BeFalse();
        ShouldBeTooLong(Repost.Create(UserId, ArticleId, tooLong, Now).Error);
    }

    [Fact]
    public void Line_breaks_count_once_unified()
    {
        // 250 lines of one letter: 499 characters with \n, 748 with \r\n.
        var lines = string.Join("\r\n", Enumerable.Repeat("a", 250));

        Repost.CaptionFits(lines).Should().BeTrue();
        Repost.Create(UserId, ArticleId, lines, Now).Value.Caption.Should().HaveLength(499);
    }

    [Fact]
    public void Editing_the_caption_keeps_the_time_and_raises_nothing()
    {
        var repost = Repost.Create(UserId, ArticleId, "first thoughts", Now).Value;
        repost.ClearDomainEvents();

        repost.SetCaption("  second\r\nthoughts ").IsSuccess.Should().BeTrue();
        repost.Caption.Should().Be("second\nthoughts");
        repost.CreatedAt.Should().Be(Now, "the repost keeps its first time");
        repost.DomainEvents.Should().BeEmpty("the count doesn't move and the author isn't told again");

        repost.SetCaption("   ").IsSuccess.Should().BeTrue();
        repost.Caption.Should().BeNull("a blank caption clears it");
        repost.DomainEvents.Should().BeEmpty();
    }

    [Fact]
    public void A_caption_too_long_changes_nothing()
    {
        var repost = Repost.Create(UserId, ArticleId, "kept", Now).Value;

        ShouldBeTooLong(repost.SetCaption(new string('x', Repost.MaxCaptionLength + 1)).Error);
        repost.Caption.Should().Be("kept");
    }

    [Fact]
    public void Undoing_raises_the_event_that_recounts()
    {
        var repost = Repost.Create(UserId, ArticleId, null, Now).Value;
        repost.ClearDomainEvents();

        repost.Remove();

        repost.DomainEvents.Should().ContainSingle().Which.Should().BeOfType<RepostChangedDomainEvent>()
            .Which.IsReposted.Should().BeFalse();
    }
}
