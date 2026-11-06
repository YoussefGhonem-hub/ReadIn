using ReadIn.Application.Features.Notifications;
using ReadIn.Application.Features.Verification;
using ReadIn.Domain.Notifications;

namespace ReadIn.Application.UnitTests.Verification;

/// <summary>SPEC F19 without a database: the proof file rules, the form's validation and the result notification.</summary>
public sealed class VerificationProofTests
{
    [Theory]
    [InlineData(new byte[] { (byte)'%', (byte)'P', (byte)'D', (byte)'F', (byte)'-', (byte)'1', (byte)'.', (byte)'7', 0x0A, 0, 0, 0 }, "application/pdf", ".pdf")]
    [InlineData(new byte[] { 0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, (byte)'J', (byte)'F', (byte)'I', (byte)'F', 0, 1 }, "image/jpeg", ".jpg")]
    [InlineData(new byte[] { 0x89, (byte)'P', (byte)'N', (byte)'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D }, "image/png", ".png")]
    [InlineData(new byte[] { (byte)'R', (byte)'I', (byte)'F', (byte)'F', 1, 2, 3, 4, (byte)'W', (byte)'E', (byte)'B', (byte)'P' }, "image/webp", ".webp")]
    public void Pdf_jpeg_png_and_webp_are_recognized_by_their_magic_bytes(byte[] header, string contentType, string extension) =>
        VerificationProofs.Detect(header).Should().Be(new VerificationProofFormat(contentType, extension));

    [Theory]
    [InlineData(new byte[] { 0, 0, 0, 0x18, (byte)'f', (byte)'t', (byte)'y', (byte)'p', (byte)'h', (byte)'e', (byte)'i', (byte)'c' })] // HEIC
    [InlineData(new byte[] { 0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0, 0, 0, 0, 0, 0 })]                                                  // GIF89a
    [InlineData(new byte[] { 0x50, 0x4B, 0x03, 0x04, 0x14, 0, 0, 0, 0, 0, 0, 0 })]                                                     // ZIP / DOCX
    [InlineData(new byte[] { 0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00 })]                                // .exe
    [InlineData(new byte[] { (byte)'<', (byte)'h', (byte)'t', (byte)'m', (byte)'l', (byte)'>', 0, 0, 0, 0, 0, 0 })]                    // HTML
    [InlineData(new byte[] { (byte)' ', (byte)'%', (byte)'P', (byte)'D', (byte)'F', (byte)'-', 0, 0, 0, 0, 0, 0 })]                    // not at the start
    [InlineData(new byte[] { (byte)'%', (byte)'P', (byte)'D' })]                                                                       // too short
    [InlineData(new byte[0])]
    public void Anything_else_is_not_a_proof(byte[] header) => VerificationProofs.Detect(header).Should().BeNull();

    [Fact]
    public void Proofs_are_stored_by_request_id_and_downloaded_under_a_neutral_name()
    {
        var id = Guid.Parse("0195f3a0-0000-7000-8000-000000000001");

        VerificationProofs.PathFor(id, VerificationProofFormat.Pdf).Should().Be($"verification/{id}.pdf");
        VerificationProofs.RequestIdOf($"verification/{id}.png").Should().Be(id);
        VerificationProofs.RequestIdOf($"verification/{id}.png.0a1b.tmp").Should().Be(id);
        VerificationProofs.RequestIdOf($"other/{id}.png").Should().BeNull();
        VerificationProofs.RequestIdOf("verification/not-a-guid.png").Should().BeNull();
        VerificationProofs.DownloadName(id, "image/webp").Should().Be($"verification-proof-{id}.webp");
        VerificationProofs.DownloadName(id, "application/pdf").Should().Be($"verification-proof-{id}.pdf");
    }

    [Theory]
    [InlineData("certificate.pdf", "certificate.pdf")]
    [InlineData(@"C:\Users\me\Desktop\card.png", "card.png")]
    [InlineData("../../etc/passwd", "passwd")]
    [InlineData("  my   syndicate\tcard .jpg ", "my syndicate card .jpg")]
    [InlineData("كارنيه النقابة.pdf", "كارنيه النقابة.pdf")]
    [InlineData("invoice\u202Egnp.exe", "invoicegnp.exe")] // a right-to-left override can't disguise the name
    [InlineData("a<b>c:d\"e|f?g*h.png", "a b c d e f g h.png")]
    [InlineData("line\r\nbreak.pdf", "line break.pdf")]
    [InlineData("", "proof.pdf")]
    [InlineData(null, "proof.pdf")]
    [InlineData("....", "proof.pdf")]
    public void Display_names_are_sanitized(string? uploaded, string expected) =>
        VerificationProofs.DisplayName(uploaded, VerificationProofFormat.Pdf).Should().Be(expected);

    [Fact]
    public void Long_display_names_keep_their_extension()
    {
        var name = VerificationProofs.DisplayName(new string('a', 300) + ".pdf", VerificationProofFormat.Pdf);

        name.Should().HaveLength(120).And.EndWith(".pdf");
        VerificationProofs.DisplayName("a" + string.Concat(Enumerable.Repeat("😀", 100)), VerificationProofFormat.Png)
            .Should().HaveLength(119, "a surrogate pair is never cut in half");
    }
}

public sealed class VerificationValidationTests
{
    private static readonly SubmitVerificationRequestCommandValidator Submit = new();
    private static readonly RejectVerificationRequestCommandValidator Reject = new();

    private static SubmitVerificationRequestCommand Form(string? jobTitle = "Engineer", string? proofUrl = null, string? note = null) =>
        new(Guid.NewGuid(), jobTitle, proofUrl, note, null);

    private static Dictionary<string, string[]> Errors(FluentValidation.Results.ValidationResult result) =>
        result.Errors.GroupBy(e => e.PropertyName).ToDictionary(g => g.Key, g => g.Select(e => e.ErrorCode).ToArray());

    [Fact]
    public void A_valid_form_passes()
    {
        Submit.Validate(Form("  QA  ", " https://github.com/someone ", "  ")).IsValid.Should().BeTrue();
        Submit.Validate(Form(new string('t', 100), "https://example.com/" + new string('u', 480), new string('n', 500))).IsValid.Should().BeTrue();
    }

    [Theory]
    [InlineData(null, "NotEmptyValidator")]
    [InlineData("   ", "NotEmptyValidator")]
    [InlineData(" a ", "validation.length")]
    public void The_job_title_has_2_to_100_characters(string? title, string code)
    {
        Errors(Submit.Validate(Form(title)))["JobTitle"].Should().Equal(code);
        Errors(Submit.Validate(Form(new string('t', 101))))["JobTitle"].Should().Equal("validation.length");
    }

    [Theory]
    [InlineData("http://github.com/someone", "validation.url")]
    [InlineData("github.com/someone", "validation.url")]
    [InlineData("javascript:alert(1)", "validation.url")]
    public void The_proof_url_is_an_absolute_https_url(string url, string code) =>
        Errors(Submit.Validate(Form(proofUrl: url)))["ProofUrl"].Should().Equal(code);

    [Fact]
    public void The_proof_url_and_the_note_have_at_most_500_characters()
    {
        var errors = Errors(Submit.Validate(Form(proofUrl: "https://example.com/" + new string('u', 481), note: new string('n', 501))));

        errors["ProofUrl"].Should().Equal("validation.max_length");
        errors["Note"].Should().Equal("validation.max_length");
    }

    [Theory]
    [InlineData(null, "NotEmptyValidator")]
    [InlineData("  ", "NotEmptyValidator")]
    [InlineData(" four ", "validation.length")]
    public void A_rejection_needs_a_reason_of_5_to_500_characters(string? reason, string code)
    {
        Errors(Reject.Validate(new RejectVerificationRequestCommand(Guid.NewGuid(), reason)))["Reason"].Should().Equal(code);
        Errors(Reject.Validate(new RejectVerificationRequestCommand(Guid.NewGuid(), new string('r', 501))))["Reason"].Should().Equal("validation.length");
        Reject.Validate(new RejectVerificationRequestCommand(Guid.NewGuid(), "Five!")).IsValid.Should().BeTrue();
    }
}

public sealed class VerificationNotificationTests
{
    private static NotificationTexts.Input Input(bool? approved) =>
        new(null, 0, null, null, new NotificationData { Approved = approved });

    [Fact]
    public void The_result_links_to_the_verification_page()
    {
        NotificationLinks.For(NotificationTypes.VerificationResult, 0, null, "me", null, null).Should().Be("readin://verification");
        VerificationResultNotificationHandler.DedupeKey(Guid.Parse("0195f3a0-0000-7000-8000-000000000001"))
            .Should().Be("verification_result:0195f3a0-0000-7000-8000-000000000001");
    }

    [Fact]
    public void Approved_and_rejected_have_their_own_texts_and_never_the_reason()
    {
        NotificationTexts.For(NotificationTypes.VerificationResult, english: true, Input(true)).Should().Be(("You're now a verified writer ✓", ""));
        NotificationTexts.For(NotificationTypes.VerificationResult, english: false, Input(true)).Should().Be(("أصبحت الآن كاتبًا موثّقًا ✓", ""));
        NotificationTexts.For(NotificationTypes.VerificationResult, english: true, Input(false))
            .Should().Be(("Your verification request wasn't approved", "Open it to see why"));
        NotificationTexts.For(NotificationTypes.VerificationResult, english: false, Input(false))
            .Should().Be(("لم تتم الموافقة على طلب توثيقك", "افتحه لمعرفة السبب"));
        NotificationTexts.For(NotificationTypes.VerificationResult, english: true, Input(null)).Title
            .Should().Be("Your verification request has an answer", "an entry without data keeps the generic text");
    }

    [Fact]
    public void Approved_is_stored_and_sent_only_when_set()
    {
        var data = NotificationData.Parse(new NotificationData { Approved = false }.Serialize());

        data.Approved.Should().BeFalse();
        data.ToDto().Should().Be(new NotificationDataDto(null, null, null, false));
        NotificationData.Empty.ToDto().Approved.Should().BeNull();
        System.Text.Json.JsonSerializer.Serialize(NotificationData.Empty.ToDto()).Should().Be("{}");
        System.Text.Json.JsonSerializer.Serialize(new NotificationData { Approved = true }.ToDto()).Should().Be("{\"Approved\":true}");
    }
}
