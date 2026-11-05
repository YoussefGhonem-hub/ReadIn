using ReadIn.Domain.Common;

namespace ReadIn.Domain.Verification;

public enum VerificationStatus
{
    Pending = 0,
    Approved = 1,
    Rejected = 2,
}

/// <summary>
/// A request for the Verified badge (SPEC F19, <c>Users.IsVerified</c>; not a role): a field, a job title and proof, a URL
/// (LinkedIn, GitHub…), a private file (a certificate or a syndicate card), or both. The SuperAdmin approves it, or
/// rejects it with a reason. At most one
/// request per user is pending. The proof file is private (never under <c>wwwroot</c>, never at a public URL) and is
/// deleted once the request is decided: the decision, the reviewer, the reason and the URL stay. Withdrawing a pending
/// request deletes it.
/// </summary>
public sealed class VerificationRequest : AggregateRoot
{
    public const int MinJobTitleLength = 2;
    public const int MaxJobTitleLength = 100;
    public const int MaxProofUrlLength = 500;
    public const int MaxNoteLength = 500;
    public const int MinRejectionReasonLength = 5;
    public const int MaxRejectionReasonLength = 500;

    /// <summary>The proof file's name as shown to admins (sanitized), never used to store or serve it.</summary>
    public const int MaxProofFileNameLength = 120;

    public const int MaxProofPathLength = 200;
    public const long MaxProofBytes = 10 * 1024 * 1024;

    private VerificationRequest() { } // EF

    public Guid UserId { get; private set; }
    public Guid FieldId { get; private set; }
    public string JobTitle { get; private set; } = default!;

    /// <summary>An absolute <c>https://</c> URL, e.g. a LinkedIn or GitHub profile. Kept after the decision.</summary>
    public string? ProofUrl { get; private set; }

    /// <summary>Path of the proof file in the private store (<c>verification/{id}{.ext}</c>); null when there is none or it was deleted.</summary>
    public string? ProofFilePath { get; private set; }

    /// <summary>Detected from the file's bytes: <c>application/pdf</c>, <c>image/jpeg</c>, <c>image/png</c> or <c>image/webp</c>.</summary>
    public string? ProofFileContentType { get; private set; }

    public long? ProofFileSizeBytes { get; private set; }
    public string? ProofFileName { get; private set; }

    public string? Note { get; private set; }
    public VerificationStatus Status { get; private set; }
    public DateTime SubmittedAt { get; private set; }
    public DateTime? DecidedAt { get; private set; }

    /// <summary>The admin who decided; no foreign key, and null once that account is deleted (SPEC §9.6).</summary>
    public Guid? DecidedById { get; private set; }

    public string? RejectionReason { get; private set; }

    public bool IsPending => Status == VerificationStatus.Pending;
    public bool HasProofFile => ProofFilePath is not null;

    /// <summary>
    /// A new pending request. Needs proof: <paramref name="proofUrl"/>, a file attached right after with
    /// <see cref="AttachProofFile"/> (<paramref name="withProofFile"/>), or both.
    /// </summary>
    /// <exception cref="ArgumentException">A length the validator already checks.</exception>
    public static Result<VerificationRequest> Submit(
        Guid userId, Guid fieldId, string jobTitle, string? proofUrl, bool withProofFile, string? note, DateTime now)
    {
        var title = jobTitle?.Trim() ?? string.Empty;
        if (title.Length is < MinJobTitleLength or > MaxJobTitleLength)
            throw new ArgumentException($"A job title has {MinJobTitleLength}–{MaxJobTitleLength} characters.", nameof(jobTitle));

        var url = string.IsNullOrWhiteSpace(proofUrl) ? null : proofUrl.Trim();
        if (url is not null && !IsProofUrl(url)) throw new ArgumentException("The proof URL must be an absolute https URL.", nameof(proofUrl));
        if (url is null && !withProofFile) return VerificationErrors.ProofRequired;

        var text = string.IsNullOrWhiteSpace(note) ? null : note.Trim();
        if (text?.Length > MaxNoteLength) throw new ArgumentException($"A note has at most {MaxNoteLength} characters.", nameof(note));

        return new VerificationRequest
        {
            UserId = userId,
            FieldId = fieldId,
            JobTitle = title,
            ProofUrl = url,
            Note = text,
            Status = VerificationStatus.Pending,
            SubmittedAt = now,
        };
    }

    /// <summary>An absolute <c>https://</c> URL of at most <see cref="MaxProofUrlLength"/> characters.</summary>
    public static bool IsProofUrl(string? value) =>
        value is { Length: > 0 and <= MaxProofUrlLength }
        && Uri.TryCreate(value, UriKind.Absolute, out var uri)
        && uri.Scheme == Uri.UriSchemeHttps
        && !string.IsNullOrEmpty(uri.Host);

    /// <summary>The stored proof file, once it is in the private store. Only while pending, and only once.</summary>
    public void AttachProofFile(string path, string contentType, long sizeBytes, string fileName)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(path);
        ArgumentException.ThrowIfNullOrWhiteSpace(contentType);
        ArgumentException.ThrowIfNullOrWhiteSpace(fileName);
        if (!IsPending) throw new InvalidOperationException("Only a pending request takes a proof file.");
        if (HasProofFile) throw new InvalidOperationException("The request already has a proof file.");
        if (path.Length > MaxProofPathLength) throw new ArgumentException("The proof path is too long.", nameof(path));
        if (sizeBytes is <= 0 or > MaxProofBytes) throw new ArgumentOutOfRangeException(nameof(sizeBytes));
        if (fileName.Length > MaxProofFileNameLength) throw new ArgumentException("The file name is too long.", nameof(fileName));

        ProofFilePath = path;
        ProofFileContentType = contentType;
        ProofFileSizeBytes = sizeBytes;
        ProofFileName = fileName;
    }

    /// <summary>The user becomes a verified writer (the caller gives the user the badge).</summary>
    /// <returns>The proof file to delete from the private store after the commit, if any.</returns>
    public Result<string?> Approve(Guid adminId, DateTime now)
    {
        if (!IsPending) return VerificationErrors.AlreadyDecided;
        return Decide(VerificationStatus.Approved, adminId, null, now);
    }

    /// <returns>The proof file to delete from the private store after the commit, if any.</returns>
    /// <exception cref="ArgumentException">The reason is blank or too long (the validator already checks it).</exception>
    public Result<string?> Reject(Guid adminId, string reason, DateTime now)
    {
        var text = reason?.Trim() ?? string.Empty;
        if (text.Length is < MinRejectionReasonLength or > MaxRejectionReasonLength)
            throw new ArgumentException($"A rejection reason has {MinRejectionReasonLength}–{MaxRejectionReasonLength} characters.", nameof(reason));
        if (!IsPending) return VerificationErrors.AlreadyDecided;
        return Decide(VerificationStatus.Rejected, adminId, text, now);
    }

    /// <summary>The user takes back a pending request; the caller deletes the row and its file.</summary>
    public Result Withdraw() => IsPending ? Result.Success() : VerificationErrors.AlreadyDecided;

    private string? Decide(VerificationStatus status, Guid adminId, string? reason, DateTime now)
    {
        Status = status;
        DecidedAt = now;
        DecidedById = adminId;
        RejectionReason = reason;

        // Retention (SPEC F19): the file goes with the decision; the URL stays.
        var file = ProofFilePath;
        ProofFilePath = null;
        ProofFileContentType = null;
        ProofFileSizeBytes = null;
        ProofFileName = null;

        Raise(() => new VerificationDecidedDomainEvent(Id, UserId, status == VerificationStatus.Approved));
        return file;
    }
}

/// <summary>After the commit: a <c>verification_result</c> notification for the requester (F17).</summary>
public sealed record VerificationDecidedDomainEvent(Guid RequestId, Guid UserId, bool Approved) : DomainEvent;

public static class VerificationErrors
{
    public static readonly Error ProofRequired =
        Error.Validation("verification.proof_required", "Add a proof link or a file.");
    public static readonly Error ProofInvalid =
        Error.Validation("verification.proof_invalid", "The proof file must be a PDF, JPEG, PNG or WebP of at most 10 MB.");
    public static readonly Error FieldInvalid = Error.Validation("verification.field_invalid", "Choose a field from the list.");
    public static readonly Error AlreadyPending =
        Error.Conflict("verification.already_pending", "You already have a request waiting for review.");
    public static readonly Error AlreadyVerified = Error.Conflict("verification.already_verified", "You're already a verified writer.");
    public static readonly Error AlreadyDecided = Error.Conflict("verification.already_decided", "This request was already decided.");
    public static readonly Error NotFound = Error.NotFound("verification.not_found", "Verification request not found.");
    public static readonly Error ProofNotFound = Error.NotFound("verification.proof_not_found", "This request has no proof file.");

    /// <summary>Removing a badge the user doesn't have (DELETE /admin/users/{id}/verification).</summary>
    public static readonly Error NotVerified = Error.Conflict("verification.not_verified", "This user isn't verified.");

    /// <summary>Removing the badge of a system account (the official @readin account keeps it, SPEC §10.1).</summary>
    public static readonly Error SystemAccount =
        Error.Conflict("verification.system_account", "This is ReadIn's official account; its badge stays.");
}
