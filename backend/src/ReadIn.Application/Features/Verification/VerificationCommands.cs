using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Behaviors;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Features.Uploads;
using ReadIn.Domain.Common;
using ReadIn.Domain.Identity;
using ReadIn.Domain.Users;
using ReadIn.Domain.Verification;

namespace ReadIn.Application.Features.Verification;

/// <summary>A proof file as it arrived (multipart <c>proof</c>). Its name is only shown to admins, sanitized.</summary>
public sealed record VerificationProofUpload(Stream Content, string? FileName);

/// <summary>
/// POST /verification-requests (SPEC F19): a field, a job title and proof (a URL, a file, or both), with an optional note.
/// One pending request per user; not for verified writers. The file must be a PDF, JPEG, PNG or WebP of at most 10 MB
/// (magic bytes); it goes to the private store as <c>verification/{id}{.ext}</c>, never under <c>wwwroot</c>.
/// </summary>
/// <param name="FieldId"><see cref="Guid.Empty"/> when the form's value isn't a GUID: an unknown field.</param>
[Authenticated]
public sealed record SubmitVerificationRequestCommand(Guid FieldId, string? JobTitle, string? ProofUrl, string? Note, VerificationProofUpload? Proof)
    : ICommand<Result<MyVerificationRequestDto>>;

/// <summary>DELETE /me/verification: withdraws the pending request, with its file.</summary>
[Authenticated]
public sealed record WithdrawVerificationRequestCommand : ICommand<Result>;

/// <summary>
/// POST /admin/verification-requests/{id}/approve: the user gets the Verified badge (<c>Users.IsVerified</c>; roles and
/// permissions don't change), the proof file is deleted, the user is notified (<c>verification_result</c>) and the audit
/// log records it.
/// </summary>
[RequirePermission(Permissions.Verification.Manage)]
public sealed record ApproveVerificationRequestCommand(Guid RequestId) : ICommand<Result>;

/// <summary>
/// DELETE /admin/users/{id}/verification: takes the Verified badge away (<c>admin.verification_removed</c> in the audit
/// log). The user's requests stay as they were, the user may request again, and nobody is notified. A system account
/// (the official @readin account) keeps its badge: <c>409 verification.system_account</c>.
/// </summary>
[RequirePermission(Permissions.Verification.Manage)]
public sealed record RemoveVerificationCommand(Guid UserId) : ICommand<Result>;

/// <summary>POST /admin/verification-requests/{id}/reject: with a reason the user sees (5–500 characters).</summary>
[RequirePermission(Permissions.Verification.Manage)]
public sealed record RejectVerificationRequestCommand(Guid RequestId, string? Reason) : ICommand<Result>;

internal sealed class SubmitVerificationRequestCommandValidator : AbstractValidator<SubmitVerificationRequestCommand>
{
    public SubmitVerificationRequestCommandValidator()
    {
        RuleFor(c => c.JobTitle).Cascade(CascadeMode.Stop)
            .NotEmpty()
            .Must(t => t!.Trim().Length is >= VerificationRequest.MinJobTitleLength and <= VerificationRequest.MaxJobTitleLength)
            .WithErrorCode("validation.length");
        When(c => !string.IsNullOrWhiteSpace(c.ProofUrl), () =>
            RuleFor(c => c.ProofUrl).Cascade(CascadeMode.Stop)
                .Must(u => u!.Trim().Length <= VerificationRequest.MaxProofUrlLength).WithErrorCode("validation.max_length")
                .Must(u => VerificationRequest.IsProofUrl(u!.Trim())).WithErrorCode("validation.url"));
        RuleFor(c => c.Note).Must(n => n is null || n.Trim().Length <= VerificationRequest.MaxNoteLength).WithErrorCode("validation.max_length");
    }
}

internal sealed class RejectVerificationRequestCommandValidator : AbstractValidator<RejectVerificationRequestCommand>
{
    public RejectVerificationRequestCommandValidator() =>
        RuleFor(c => c.Reason).Cascade(CascadeMode.Stop)
            .NotEmpty()
            .Must(r => r!.Trim().Length is >= VerificationRequest.MinRejectionReasonLength and <= VerificationRequest.MaxRejectionReasonLength)
            .WithErrorCode("validation.length");
}

internal sealed class SubmitVerificationRequestCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    IPrivateFileStorage storage,
    VerificationProofFiles files,
    VerificationReader reader,
    TimeProvider clock)
    : ICommandHandler<SubmitVerificationRequestCommand, Result<MyVerificationRequestDto>>
{
    public async ValueTask<Result<MyVerificationRequestDto>> Handle(SubmitVerificationRequestCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        if (await db.Users.AnyAsync(u => u.Id == userId && u.IsVerified, cancellationToken))
            return VerificationErrors.AlreadyVerified;
        if (await HasPendingAsync(userId, cancellationToken)) return VerificationErrors.AlreadyPending;

        var field = (await reader.FieldsAsync([command.FieldId], cancellationToken, enabledOnly: true)).GetValueOrDefault(command.FieldId);
        if (field is null) return VerificationErrors.FieldInvalid;

        byte[]? proof = null;
        VerificationProofFormat? format = null;
        if (command.Proof is { } upload)
        {
            proof = await UploadBuffer.ReadAtMostAsync(upload.Content, VerificationRequest.MaxProofBytes, cancellationToken);
            format = proof.Length is > 0 and <= (int)VerificationRequest.MaxProofBytes
                ? VerificationProofs.Detect(proof.AsSpan(0, Math.Min(proof.Length, VerificationProofs.HeaderLength)))
                : null;
            if (format is null) return VerificationErrors.ProofInvalid;
        }

        var submitted = VerificationRequest.Submit(
            userId, command.FieldId, command.JobTitle!, command.ProofUrl, proof is not null, command.Note, clock.GetUtcNow().UtcDateTime);
        if (submitted.IsFailure) return submitted.Error;

        var request = submitted.Value;
        db.VerificationRequests.Add(request); // EF Core assigns the id here, which names the file
        string? path = null;
        if (proof is not null && format is not null)
        {
            path = VerificationProofs.PathFor(request.Id, format);
            using (var content = new MemoryStream(proof, writable: false))
                await storage.SaveAsync(path, content, cancellationToken);
            request.AttachProofFile(path, format.ContentType, proof.Length, VerificationProofs.DisplayName(command.Proof!.FileName, format));
        }

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException)
        {
            db.VerificationRequests.Entry(request).State = EntityState.Detached;
            await files.DeleteAsync([path], CancellationToken.None);
            // A parallel submit took the one pending slot (the filtered unique index).
            if (await HasPendingAsync(userId, CancellationToken.None)) return VerificationErrors.AlreadyPending;
            throw;
        }

        return VerificationReader.Mine(request, field);
    }

    private Task<bool> HasPendingAsync(Guid userId, CancellationToken ct) =>
        db.VerificationRequests.AnyAsync(r => r.UserId == userId && r.Status == VerificationStatus.Pending, ct);
}

internal sealed class WithdrawVerificationRequestCommandHandler(IAppDbContext db, ICurrentUser currentUser, VerificationProofFiles files)
    : ICommandHandler<WithdrawVerificationRequestCommand, Result>
{
    public async ValueTask<Result> Handle(WithdrawVerificationRequestCommand command, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var request = await db.VerificationRequests
            .FirstOrDefaultAsync(r => r.UserId == userId && r.Status == VerificationStatus.Pending, cancellationToken);
        if (request is null) return VerificationErrors.NotFound;

        var withdrawn = request.Withdraw();
        if (withdrawn.IsFailure) return withdrawn.Error;

        var path = request.ProofFilePath;
        db.VerificationRequests.Remove(request);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            // An admin decided it a moment ago: nothing is pending any more.
            return VerificationErrors.NotFound;
        }

        await files.DeleteAsync([path], cancellationToken);
        return Result.Success();
    }
}

internal sealed class ApproveVerificationRequestCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    VerificationDecisions decisions,
    AuditTrail audit,
    TimeProvider clock)
    : ICommandHandler<ApproveVerificationRequestCommand, Result>
{
    public async ValueTask<Result> Handle(ApproveVerificationRequestCommand command, CancellationToken cancellationToken)
    {
        var request = await db.VerificationRequests.FirstOrDefaultAsync(r => r.Id == command.RequestId, cancellationToken);
        if (request is null) return VerificationErrors.NotFound;

        var now = clock.GetUtcNow().UtcDateTime;
        var approved = request.Approve(currentUser.RequireUserId(), now);
        if (approved.IsFailure) return approved.Error;

        // The badge only: no role or permission changes (SPEC §10.1), so the cached access stays valid. Every read model
        // reads Users.IsVerified, and GET /me shows it at once.
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == request.UserId, cancellationToken);
        user?.Verify(now);
        audit.Record(AuditActions.VerificationApproved, request.UserId);

        return await decisions.SaveAsync(request, approved.Value, cancellationToken);
    }
}

internal sealed class RemoveVerificationCommandHandler(IAppDbContext db, AuditTrail audit)
    : ICommandHandler<RemoveVerificationCommand, Result>
{
    public async ValueTask<Result> Handle(RemoveVerificationCommand command, CancellationToken cancellationToken)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == command.UserId, cancellationToken);
        if (user is null) return UserErrors.NotFound;
        if (!user.IsVerified) return VerificationErrors.NotVerified;
        // The official @readin account always has the badge (SPEC §10.1), and no seeder would give it back.
        if (user.IsSystemAccount) return VerificationErrors.SystemAccount;
        user.RemoveVerification();

        audit.Record(AuditActions.VerificationRemoved, user.Id);
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            // The row changed a moment ago. Removed by another request: nothing left to remove; otherwise let it fail.
            if (await db.Users.AsNoTracking().AnyAsync(u => u.Id == command.UserId && u.IsVerified, CancellationToken.None)) throw;
            return VerificationErrors.NotVerified;
        }
        return Result.Success();
    }
}

internal sealed class RejectVerificationRequestCommandHandler(
    IAppDbContext db,
    ICurrentUser currentUser,
    VerificationDecisions decisions,
    AuditTrail audit,
    TimeProvider clock)
    : ICommandHandler<RejectVerificationRequestCommand, Result>
{
    public async ValueTask<Result> Handle(RejectVerificationRequestCommand command, CancellationToken cancellationToken)
    {
        var request = await db.VerificationRequests.FirstOrDefaultAsync(r => r.Id == command.RequestId, cancellationToken);
        if (request is null) return VerificationErrors.NotFound;

        var rejected = request.Reject(currentUser.RequireUserId(), command.Reason!, clock.GetUtcNow().UtcDateTime);
        if (rejected.IsFailure) return rejected.Error;

        audit.Record(AuditActions.VerificationRejected, request.UserId);
        return await decisions.SaveAsync(request, rejected.Value, cancellationToken);
    }
}

/// <summary>Saves an approval or a rejection, then deletes the proof file it released (retention, SPEC F19).</summary>
public sealed class VerificationDecisions(IAppDbContext db, VerificationProofFiles files)
{
    /// <param name="releasedProof">The proof file the decision released, to delete once the decision is committed.</param>
    public async Task<Result> SaveAsync(VerificationRequest request, string? releasedProof, CancellationToken cancellationToken)
    {
        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException ex) when (ex.Entries.Any(e => e.Entity is VerificationRequest))
        {
            // Another admin decided it, or its author withdrew it, a moment ago (Status is a concurrency token).
            return await db.VerificationRequests.AsNoTracking().AnyAsync(r => r.Id == request.Id, CancellationToken.None)
                ? VerificationErrors.AlreadyDecided
                : VerificationErrors.NotFound;
        }

        await files.DeleteAsync([releasedProof], cancellationToken);
        return Result.Success();
    }
}
