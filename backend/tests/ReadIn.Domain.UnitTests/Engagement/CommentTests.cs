using ReadIn.Domain.Engagement;

namespace ReadIn.Domain.UnitTests.Engagement;

public sealed class CommentTests
{
    private static readonly DateTime Now = new(2026, 11, 3, 18, 0, 0, DateTimeKind.Utc);
    private static readonly Guid ArticleId = Guid.NewGuid();
    private static readonly Guid Author = Guid.NewGuid();
    private static readonly Guid Other = Guid.NewGuid();

    private static Comment TopLevel(Guid? author = null)
    {
        var comment = Comment.Post(ArticleId, author ?? Author, "مقال مفيد جدًا", [], Now);
        typeof(Comment).GetProperty(nameof(Comment.Id))!.SetValue(comment, Guid.NewGuid()); // EF assigns it on Add
        return comment;
    }

    [Fact]
    public void Posting_raises_a_created_event()
    {
        var comment = TopLevel();

        comment.DomainEvents.Should().ContainSingle().Which.Should().BeEquivalentTo(
            new { ArticleId, CommentId = comment.Id, ParentId = (Guid?)null, Change = CommentChange.Created });
    }

    [Fact]
    public void Replying_to_a_reply_joins_the_top_level_thread()
    {
        var top = TopLevel();
        var reply = Comment.Reply(top, Other, "@writer1 متفق", [], Now).Value;
        typeof(Comment).GetProperty(nameof(Comment.Id))!.SetValue(reply, Guid.NewGuid());

        var replyToReply = Comment.Reply(reply, Author, "شكرًا", [], Now).Value;

        reply.ParentId.Should().Be(top.Id);
        replyToReply.ParentId.Should().Be(top.Id, "threads are one level deep (SPEC F11)");
        replyToReply.ArticleId.Should().Be(ArticleId);
    }

    [Fact]
    public void Deleted_or_hidden_comments_cant_be_replied_to()
    {
        var deleted = TopLevel();
        deleted.Delete(Author, Now);
        var hidden = TopLevel();
        hidden.Hide(Guid.NewGuid(), Now);

        Comment.Reply(deleted, Other, "رد", [], Now).Error.Should().Be(CommentErrors.NotAvailable);
        Comment.Reply(hidden, Other, "رد", [], Now).Error.Should().Be(CommentErrors.NotAvailable);
    }

    [Fact]
    public void Only_the_author_edits_and_an_edit_shows_edited()
    {
        var comment = TopLevel();

        comment.Edit(Other, "تعديل", [], Now).Error.Should().Be(CommentErrors.NotOwner);
        comment.Edit(Author, "مقال مفيد جدًا", [], Now.AddMinutes(1)).IsSuccess.Should().BeTrue();
        comment.EditedAt.Should().BeNull("the same text is no edit");

        comment.Edit(Author, "مقال مفيد جدًا، شكرًا", [], Now.AddMinutes(2)).IsSuccess.Should().BeTrue();
        comment.EditedAt.Should().Be(Now.AddMinutes(2));
    }

    [Fact]
    public void Only_the_author_deletes_and_deleting_is_soft_and_unpins()
    {
        var comment = TopLevel();
        comment.Pin(Now);

        comment.Delete(Other, Now).Error.Should().Be(CommentErrors.NotOwner);
        comment.Delete(Author, Now).IsSuccess.Should().BeTrue();

        comment.IsDeleted.Should().BeTrue();
        comment.IsPinned.Should().BeFalse();
        comment.Body.Should().Be("مقال مفيد جدًا", "deleting is soft (SPEC F11)");
    }

    [Fact]
    public void Moderators_hide_unhide_and_delete()
    {
        var moderator = Guid.NewGuid();
        var comment = TopLevel();
        comment.Pin(Now);

        comment.Hide(moderator, Now);
        comment.IsHidden.Should().BeTrue();
        comment.IsVisible.Should().BeFalse();
        comment.IsPinned.Should().BeFalse("a hidden comment isn't pinned any more");
        comment.HiddenById.Should().Be(moderator);

        comment.Unhide();
        comment.IsVisible.Should().BeTrue();

        comment.DeleteByModerator(Now);
        comment.IsDeleted.Should().BeTrue();
        comment.DeletedByModerator.Should().BeTrue();
    }

    [Fact]
    public void Only_visible_top_level_comments_can_be_pinned()
    {
        var top = TopLevel();
        var reply = Comment.Reply(top, Other, "رد", [], Now).Value;
        var hidden = TopLevel();
        hidden.Hide(Guid.NewGuid(), Now);

        reply.Pin(Now).Error.Should().Be(CommentErrors.PinReply);
        hidden.Pin(Now).Error.Should().Be(CommentErrors.NotAvailable);
        top.Pin(Now).IsSuccess.Should().BeTrue();
        top.IsPinned.Should().BeTrue();
    }

    [Fact]
    public void Mentions_are_distinct_capped_and_follow_edits()
    {
        var users = Enumerable.Range(0, 15).Select(_ => Guid.NewGuid()).ToList();
        var comment = Comment.Post(ArticleId, Author, "@a", [users[0], users[0], .. users], Now);

        comment.Mentions.Select(m => m.UserId).Should().OnlyHaveUniqueItems().And.HaveCount(Comment.MaxMentions);

        comment.Edit(Author, "@b", [users[1]], Now);
        comment.Mentions.Select(m => m.UserId).Should().Equal(users[1]);
    }

    [Fact]
    public void Count_changes_are_the_ones_readers_see()
    {
        new CommentChangedDomainEvent(ArticleId, Guid.NewGuid(), null, CommentChange.Created).ChangesCount.Should().BeTrue();
        new CommentChangedDomainEvent(ArticleId, Guid.NewGuid(), null, CommentChange.Hidden).ChangesCount.Should().BeTrue();
        new CommentChangedDomainEvent(ArticleId, Guid.NewGuid(), null, CommentChange.Liked).ChangesCount.Should().BeFalse();
        new CommentChangedDomainEvent(ArticleId, Guid.NewGuid(), null, CommentChange.Edited).ChangesCount.Should().BeFalse();
    }
}
