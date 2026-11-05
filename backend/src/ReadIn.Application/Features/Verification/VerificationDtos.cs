using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Verification;

namespace ReadIn.Application.Features.Verification;

/// <summary>GET /me/verification (SPEC F19): where the signed-in user stands.</summary>
/// <param name="IsVerified">The user has the Verified badge (<c>Users.IsVerified</c>).</param>
/// <param name="CanRequest">Not verified, not suspended and nothing pending: the form can be sent.</param>
/// <param name="Request">The latest request, whatever its status; null when there was none.</param>
public sealed record VerificationStatusDto(bool IsVerified, bool CanRequest, MyVerificationRequestDto? Request);

/// <summary>A request as its author sees it. The proof file itself is never sent back, only its name while it exists.</summary>
/// <param name="ProofFileName">The uploaded file's name until the request is decided (the file is deleted then).</param>
/// <param name="RejectionReason">Rejected only: what the admin wrote.</param>
public sealed record MyVerificationRequestDto(
    Guid Id,
    VerificationStatus Status,
    VerificationFieldDto Field,
    string JobTitle,
    string? ProofUrl,
    string? ProofFileName,
    string? Note,
    DateTime SubmittedAt,
    DateTime? DecidedAt,
    string? RejectionReason);

/// <param name="Name">In the request's UI language (<c>Accept-Language</c>).</param>
public sealed record VerificationFieldDto(Guid Id, string Slug, string Name);

/// <summary>A request in the admin queue (<c>verification.manage</c>).</summary>
/// <param name="User">The requester (their current profile).</param>
/// <param name="Proof">The proof file while it exists (pending requests); download it from <c>…/{id}/proof</c>.</param>
/// <param name="DecidedBy">The admin who decided; null while pending or once that account was deleted.</param>
public sealed record AdminVerificationRequestDto(
    Guid Id,
    VerificationStatus Status,
    AuthorDto User,
    VerificationFieldDto Field,
    string JobTitle,
    string? ProofUrl,
    VerificationProofDto? Proof,
    string? Note,
    DateTime SubmittedAt,
    DateTime? DecidedAt,
    VerificationDeciderDto? DecidedBy,
    string? RejectionReason);

/// <param name="ContentType"><c>application/pdf</c> | <c>image/jpeg</c> | <c>image/png</c> | <c>image/webp</c>, from the file's bytes.</param>
public sealed record VerificationProofDto(string FileName, string ContentType, long SizeBytes);

public sealed record VerificationDeciderDto(Guid Id, string Username);

/// <summary>Body of POST /admin/verification-requests/{id}/reject.</summary>
public sealed record RejectVerificationRequest(string? Reason);

/// <summary>A proof file to stream to an admin.</summary>
/// <param name="FileName"><c>verification-proof-{id}{.ext}</c>: never the name the user uploaded.</param>
public sealed record VerificationProofContent(Stream Content, string ContentType, string FileName);
