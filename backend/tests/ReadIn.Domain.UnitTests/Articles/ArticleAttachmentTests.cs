using ReadIn.Domain.Articles;
using ReadIn.Domain.Media;

namespace ReadIn.Domain.UnitTests.Articles;

/// <summary>Attachment kind rules (ADR 0011): 1–10 images with alt text, or exactly one PDF, never mixed.</summary>
public sealed class ArticleAttachmentTests
{
    private static readonly Guid AuthorId = Guid.NewGuid();

    private static Article Draft() => Article.CreateDraft(AuthorId, Guid.NewGuid(), topicId: null, "post-with-media");

    private static AttachmentCandidate Image(int order = 0, string? alt = "A chart", string? caption = null, Guid? owner = null,
        MediaStatus status = MediaStatus.Ready) =>
        new(Guid.NewGuid(), MediaKind.Image, status, owner ?? AuthorId, order, caption, alt);

    private static AttachmentCandidate Document(MediaStatus status = MediaStatus.Ready) =>
        new(Guid.NewGuid(), MediaKind.Document, status, AuthorId, 0, Caption: null, AltText: null);

    [Fact]
    public void Images_are_stored_in_the_requested_order()
    {
        var article = Draft();
        var (first, second, third) = (Image(order: 2), Image(order: 0), Image(order: 1));

        article.SetAttachments([first, second, third]).IsSuccess.Should().BeTrue();

        article.Attachments.OrderBy(a => a.Order).Select(a => a.MediaAssetId)
            .Should().Equal(second.MediaAssetId, third.MediaAssetId, first.MediaAssetId);
        article.Attachments.Select(a => a.Order).Should().BeEquivalentTo([0, 1, 2]);
    }

    [Fact]
    public void Ten_images_are_allowed_but_not_eleven()
    {
        Draft().SetAttachments([.. Enumerable.Range(0, 10).Select(i => Image(i))]).IsSuccess.Should().BeTrue();

        Draft().SetAttachments([.. Enumerable.Range(0, 11).Select(i => Image(i))]).Error.Should().Be(AttachmentErrors.TooManyImages);
    }

    [Fact]
    public void Images_and_a_document_cannot_be_mixed()
    {
        Draft().SetAttachments([Image(), Document()]).Error.Should().Be(AttachmentErrors.MixedKinds);
    }

    [Fact]
    public void Only_one_document_is_allowed()
    {
        Draft().SetAttachments([Document(), Document()]).Error.Should().Be(AttachmentErrors.SingleDocument);
        Draft().SetAttachments([Document()]).IsSuccess.Should().BeTrue();
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void Every_image_needs_alt_text(string? alt)
    {
        Draft().SetAttachments([Image(alt: "ok"), Image(alt: alt)]).Error.Should().Be(AttachmentErrors.AltTextRequired);
    }

    [Fact]
    public void A_document_does_not_need_alt_text()
    {
        var article = Draft();

        article.SetAttachments([Document()]).IsSuccess.Should().BeTrue();

        article.Attachments.Should().ContainSingle().Which.AltText.Should().BeNull();
    }

    [Fact]
    public void Captions_are_limited_to_5000_characters()
    {
        Draft().SetAttachments([Image(caption: new string('x', 5001))]).Error.Should().Be(AttachmentErrors.CaptionTooLong);
        Draft().SetAttachments([Image(caption: new string('x', 5000))]).IsSuccess.Should().BeTrue();
    }

    [Fact]
    public void Alt_text_is_limited_to_5000_characters()
    {
        Draft().SetAttachments([Image(alt: new string('x', 5001))]).Error.Should().Be(AttachmentErrors.AltTextTooLong);
        Draft().SetAttachments([Image(alt: new string('x', 5000))]).IsSuccess.Should().BeTrue();
    }

    [Fact]
    public void Assets_must_be_ready()
    {
        Draft().SetAttachments([Document(MediaStatus.Processing)]).Error.Should().Be(AttachmentErrors.AssetNotReady);
        Draft().SetAttachments([Image(status: MediaStatus.Failed)]).Error.Should().Be(AttachmentErrors.AssetNotReady);
    }

    [Fact]
    public void Another_users_asset_is_reported_as_not_found()
    {
        Draft().SetAttachments([Image(owner: Guid.NewGuid())]).Error.Should().Be(AttachmentErrors.AssetNotFound);
    }

    [Fact]
    public void The_same_asset_cannot_be_added_twice()
    {
        var image = Image();

        Draft().SetAttachments([image, image with { Order = 1 }]).Error.Should().Be(AttachmentErrors.DuplicateAsset);
    }

    [Fact]
    public void An_empty_list_removes_all_attachments()
    {
        var article = Draft();
        article.SetAttachments([Image(), Image(1)]);

        article.SetAttachments([]).IsSuccess.Should().BeTrue();

        article.Attachments.Should().BeEmpty();
    }

    [Fact]
    public void A_failed_update_keeps_the_previous_attachments()
    {
        var article = Draft();
        article.SetAttachments([Image()]);

        article.SetAttachments([Image(), Document()]).IsFailure.Should().BeTrue();

        article.Attachments.Should().ContainSingle();
    }

    [Fact]
    public void Captions_and_alt_text_are_trimmed()
    {
        var article = Draft();

        article.SetAttachments([Image(alt: "  Diagram  ", caption: "  Advancing Offshore Inspection  ")]);

        var attachment = article.Attachments.Single();
        attachment.AltText.Should().Be("Diagram");
        attachment.Caption.Should().Be("Advancing Offshore Inspection");
    }

    [Fact]
    public void Deleting_the_article_detaches_its_media()
    {
        var article = Draft();
        var (a, b) = (Image(), Image(1));
        article.SetAttachments([a, b]);

        var detached = article.SoftDelete(DateTime.UtcNow);

        detached.Should().BeEquivalentTo([a.MediaAssetId, b.MediaAssetId]);
        article.Attachments.Should().BeEmpty();
        article.IsDeleted.Should().BeTrue();
    }
}
