using ReadIn.Domain.Engagement;

namespace ReadIn.Domain.UnitTests.Engagement;

public sealed class CommentTextTests
{
    [Fact]
    public void Text_is_trimmed_with_unified_line_breaks_and_at_most_one_empty_line()
    {
        CommentText.Normalize("  سطر أول  \r\n\r\n \r\n\r\nسطر تاني  ").Value.Should().Be("سطر أول\n\nسطر تاني");
        CommentText.Normalize("first\r  second").Value.Should().Be("first\n  second", "leading spaces of a line are kept");
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" \n\t ")]
    public void Empty_text_is_refused(string? body)
    {
        CommentText.Normalize(body).Error.Should().Be(CommentErrors.Empty);
    }

    [Fact]
    public void Text_longer_than_2000_characters_is_refused()
    {
        CommentText.Normalize(new string('ع', Comment.MaxBodyLength)).IsSuccess.Should().BeTrue();
        CommentText.Normalize(new string('ع', Comment.MaxBodyLength + 1)).Error.Should().Be(CommentErrors.TooLong);
    }

    [Fact]
    public void Mentions_are_usernames_in_mixed_text()
    {
        CommentText.MentionedUsernames("شكرًا @Reader1 و@writer_2، وكمان (@reviewer.dotnet)")
            .Should().Equal("reader1", "writer_2", "reviewer");
    }

    [Theory]
    [InlineData("mail me at someone@readin.test")]
    [InlineData("@ab is too short")]
    [InlineData("@@reader1")]
    public void Emails_short_handles_and_double_at_are_not_mentions(string text)
    {
        CommentText.MentionedUsernames(text).Should().BeEmpty();
    }

    [Fact]
    public void Mentions_are_distinct_and_capped()
    {
        var text = string.Join(' ', Enumerable.Range(0, 15).Select(i => $"@user{i:00}")) + " @user00";

        CommentText.MentionedUsernames(text).Should().HaveCount(Comment.MaxMentions).And.OnlyHaveUniqueItems();
    }

    [Fact]
    public void The_duplicate_check_ignores_case_and_spacing()
    {
        CommentText.DuplicateKey("Great   read!\n\nThanks").Should().Be(CommentText.DuplicateKey("great read! thanks"));
        CommentText.DuplicateKey("مقال مفيد").Should().NotBe(CommentText.DuplicateKey("مقال مفيد جدًا"));
    }
}
