using ReadIn.Domain.Verification;

namespace ReadIn.Domain.UnitTests.Verification;

/// <summary>SPEC F19: submitting with proof, approving, rejecting with a reason, withdrawing, and the proof file's retention.</summary>
public sealed class VerificationRequestTests
{
    private static readonly DateTime Now = new(2026, 11, 4, 9, 0, 0, DateTimeKind.Utc);
    private static readonly Guid UserId = Guid.NewGuid();
    private static readonly Guid FieldId = Guid.NewGuid();
    private static readonly Guid Admin = Guid.NewGuid();
    private const string ProofPath = "verification/0195f3a0-0000-7000-8000-000000000001.pdf";

    private static VerificationRequest WithId(VerificationRequest request)
    {
        typeof(VerificationRequest).GetProperty(nameof(VerificationRequest.Id))!.SetValue(request, Guid.NewGuid()); // EF assigns it on Add
        return request;
    }

    private static VerificationRequest Pending(string? proofUrl = "https://github.com/someone", bool withFile = true)
    {
        var request = WithId(VerificationRequest.Submit(UserId, FieldId, "Backend Engineer", proofUrl, withFile, null, Now).Value);
        if (withFile) request.AttachProofFile(ProofPath, "application/pdf", 2048, "card.pdf");
        return request;
    }

    [Fact]
    public void Submitting_trims_the_text_and_starts_pending()
    {
        var request = VerificationRequest.Submit(UserId, FieldId, "  Senior .NET Engineer  ", " https://www.linkedin.com/in/someone ", false,
            "  شغال في المجال من 8 سنين  ", Now).Value;

        request.Should().BeEquivalentTo(new
        {
            UserId,
            FieldId,
            JobTitle = "Senior .NET Engineer",
            ProofUrl = "https://www.linkedin.com/in/someone",
            Note = "شغال في المجال من 8 سنين",
            Status = VerificationStatus.Pending,
            SubmittedAt = Now,
            DecidedAt = (DateTime?)null,
            DecidedById = (Guid?)null,
            RejectionReason = (string?)null,
            HasProofFile = false,
        });
        request.IsPending.Should().BeTrue();
        VerificationRequest.Submit(UserId, FieldId, "Engineer", null, false, "   ", Now).Error!.Code.Should().Be("verification.proof_required");
    }

    [Fact]
    public void Proof_is_a_url_a_file_or_both()
    {
        VerificationRequest.Submit(UserId, FieldId, "Engineer", null, withProofFile: false, null, Now).Error
            .Should().Be(VerificationErrors.ProofRequired);
        VerificationRequest.Submit(UserId, FieldId, "Engineer", "   ", withProofFile: false, null, Now).Error
            .Should().Be(VerificationErrors.ProofRequired, "a blank URL is no proof");
        VerificationRequest.Submit(UserId, FieldId, "Engineer", null, withProofFile: true, null, Now).IsSuccess.Should().BeTrue();
        VerificationRequest.Submit(UserId, FieldId, "Engineer", "https://github.com/x", withProofFile: false, null, Now).IsSuccess.Should().BeTrue();
    }

    [Theory]
    [InlineData("https://github.com/someone", true)]
    [InlineData("https://www.linkedin.com/in/someone?trk=x", true)]
    [InlineData("http://github.com/someone", false)]
    [InlineData("ftp://github.com/someone", false)]
    [InlineData("javascript:alert(1)", false)]
    [InlineData("github.com/someone", false)]
    [InlineData("/relative/path", false)]
    [InlineData("", false)]
    public void Proof_urls_are_absolute_https(string url, bool valid) => VerificationRequest.IsProofUrl(url).Should().Be(valid);

    [Fact]
    public void Proof_urls_have_at_most_500_characters()
    {
        var prefix = "https://example.com/";
        VerificationRequest.IsProofUrl(prefix + new string('a', 500 - prefix.Length)).Should().BeTrue();
        VerificationRequest.IsProofUrl(prefix + new string('a', 501 - prefix.Length)).Should().BeFalse();
    }

    [Fact]
    public void Lengths_the_validator_checks_are_guarded_too()
    {
        var shortTitle = () => VerificationRequest.Submit(UserId, FieldId, " a ", "https://x.dev", false, null, Now);
        var longTitle = () => VerificationRequest.Submit(UserId, FieldId, new string('a', 101), "https://x.dev", false, null, Now);
        var badUrl = () => VerificationRequest.Submit(UserId, FieldId, "Engineer", "http://x.dev", false, null, Now);
        var longNote = () => VerificationRequest.Submit(UserId, FieldId, "Engineer", "https://x.dev", false, new string('n', 501), Now);

        shortTitle.Should().Throw<ArgumentException>();
        longTitle.Should().Throw<ArgumentException>();
        badUrl.Should().Throw<ArgumentException>();
        longNote.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void A_proof_file_is_attached_once_while_pending()
    {
        var request = WithId(VerificationRequest.Submit(UserId, FieldId, "Engineer", null, true, null, Now).Value);

        request.AttachProofFile(ProofPath, "application/pdf", 2048, "card.pdf");

        request.Should().BeEquivalentTo(new
        {
            ProofFilePath = ProofPath,
            ProofFileContentType = "application/pdf",
            ProofFileSizeBytes = 2048L,
            ProofFileName = "card.pdf",
            HasProofFile = true,
        });
        request.Invoking(r => r.AttachProofFile(ProofPath, "application/pdf", 1, "again.pdf")).Should().Throw<InvalidOperationException>();
        request.Invoking(r => r.AttachProofFile(ProofPath, "application/pdf", VerificationRequest.MaxProofBytes + 1, "big.pdf"))
            .Should().Throw<InvalidOperationException>("the file is already there");

        var other = WithId(VerificationRequest.Submit(UserId, FieldId, "Engineer", null, true, null, Now).Value);
        other.Invoking(r => r.AttachProofFile(ProofPath, "application/pdf", VerificationRequest.MaxProofBytes + 1, "big.pdf"))
            .Should().Throw<ArgumentOutOfRangeException>();
        other.Invoking(r => r.AttachProofFile(ProofPath, "application/pdf", 10, new string('n', 121)))
            .Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Approving_records_the_decision_releases_the_file_and_keeps_the_url()
    {
        var request = Pending();

        var released = request.Approve(Admin, Now.AddHours(2));

        released.IsSuccess.Should().BeTrue();
        released.Value.Should().Be(ProofPath, "the caller deletes it from the private store after the commit");
        request.Should().BeEquivalentTo(new
        {
            Status = VerificationStatus.Approved,
            DecidedAt = (DateTime?)Now.AddHours(2),
            DecidedById = (Guid?)Admin,
            RejectionReason = (string?)null,
            ProofUrl = "https://github.com/someone",
            ProofFilePath = (string?)null,
            ProofFileContentType = (string?)null,
            ProofFileSizeBytes = (long?)null,
            ProofFileName = (string?)null,
        });
        request.DomainEvents.Should().ContainSingle().Which.Should().BeEquivalentTo(
            new VerificationDecidedDomainEvent(request.Id, UserId, Approved: true), o => o.Excluding(e => e.OccurredAt));
    }

    [Fact]
    public void Rejecting_needs_a_reason_and_releases_the_file()
    {
        var request = Pending();

        request.Invoking(r => r.Reject(Admin, "  no ", Now)).Should().Throw<ArgumentException>("a reason has at least 5 characters");
        request.Invoking(r => r.Reject(Admin, new string('r', 501), Now)).Should().Throw<ArgumentException>();
        request.IsPending.Should().BeTrue("nothing changed");

        var released = request.Reject(Admin, "  The link doesn't show this field.  ", Now.AddHours(1));

        released.Value.Should().Be(ProofPath);
        (request.Status, request.RejectionReason, request.DecidedById, request.HasProofFile)
            .Should().Be((VerificationStatus.Rejected, "The link doesn't show this field.", Admin, false));
        request.DomainEvents.Should().ContainSingle().Which.Should().BeOfType<VerificationDecidedDomainEvent>()
            .Which.Approved.Should().BeFalse();
    }

    [Fact]
    public void A_decided_request_is_decided_once_and_cant_be_withdrawn()
    {
        var approved = Pending(withFile: false);
        approved.Approve(Admin, Now).IsSuccess.Should().BeTrue();
        approved.ClearDomainEvents();

        approved.Approve(Guid.NewGuid(), Now.AddHours(1)).Error.Should().Be(VerificationErrors.AlreadyDecided);
        approved.Reject(Guid.NewGuid(), "Changed my mind.", Now.AddHours(1)).Error.Should().Be(VerificationErrors.AlreadyDecided);
        approved.Withdraw().Error.Should().Be(VerificationErrors.AlreadyDecided);
        (approved.Status, approved.DecidedById, approved.DecidedAt).Should().Be((VerificationStatus.Approved, Admin, Now));
        approved.DomainEvents.Should().BeEmpty("nothing is told twice");
        approved.Invoking(r => r.AttachProofFile(ProofPath, "application/pdf", 1, "late.pdf")).Should().Throw<InvalidOperationException>();

        var rejected = Pending(withFile: false);
        rejected.Reject(Admin, "Not enough proof.", Now);
        rejected.Approve(Admin, Now).Error.Should().Be(VerificationErrors.AlreadyDecided);
    }

    [Fact]
    public void A_pending_request_can_be_withdrawn()
    {
        var request = Pending();

        request.Withdraw().IsSuccess.Should().BeTrue();
        request.DomainEvents.Should().BeEmpty("withdrawing tells nobody");
    }

    [Fact]
    public void A_url_only_decision_releases_nothing()
    {
        Pending(withFile: false).Approve(Admin, Now).Value.Should().BeNull();
    }
}
