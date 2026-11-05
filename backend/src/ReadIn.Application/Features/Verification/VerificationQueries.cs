using FluentValidation;
using Mediator;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Models;
using ReadIn.Application.Common.Security;
using ReadIn.Domain.Common;
using ReadIn.Domain.Verification;

namespace ReadIn.Application.Features.Verification;

/// <summary>GET /me/verification (SPEC F19): verified or not, whether the form can be sent, and the latest request.</summary>
[Authenticated]
public sealed record GetMyVerificationQuery : IQuery<Result<VerificationStatusDto>>;

/// <summary>
/// GET /admin/verification-requests?status=&amp;cursor=&amp;limit= (SPEC F19): pending (the default) oldest first, approved
/// and rejected most recently decided first. Keyset paging, so deciding requests while going through the queue never
/// skips any.
/// </summary>
[RequirePermission(Permissions.Verification.Manage)]
public sealed record GetVerificationRequestsQuery(string? Status, string? Cursor, int Limit = 20)
    : IQuery<Result<CursorPage<AdminVerificationRequestDto>>>;

/// <summary>GET /admin/verification-requests/{id}.</summary>
[RequirePermission(Permissions.Verification.Manage)]
public sealed record GetVerificationRequestQuery(Guid RequestId) : IQuery<Result<AdminVerificationRequestDto>>;

/// <summary>GET /admin/verification-requests/{id}/proof: the private proof file, while the request has one.</summary>
[RequirePermission(Permissions.Verification.Manage)]
public sealed record GetVerificationProofQuery(Guid RequestId) : IQuery<Result<VerificationProofContent>>;

internal sealed class GetVerificationRequestsQueryValidator : AbstractValidator<GetVerificationRequestsQuery>
{
    public GetVerificationRequestsQueryValidator() =>
        RuleFor(q => q.Status).Must(s => s is null || VerificationValues.TryParseStatus(s, out _)).WithErrorCode("verification.status_invalid");
}

internal sealed class GetMyVerificationQueryHandler(IAppDbContext db, ICurrentUser currentUser, VerificationReader reader, TimeProvider clock)
    : IQueryHandler<GetMyVerificationQuery, Result<VerificationStatusDto>>
{
    public async ValueTask<Result<VerificationStatusDto>> Handle(GetMyVerificationQuery query, CancellationToken cancellationToken)
    {
        var userId = currentUser.RequireUserId();
        var now = clock.GetUtcNow().UtcDateTime;
        var user = await db.Users.AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new
            {
                u.IsVerified,
                IsSuspended = u.IsSuspended && (u.SuspendedUntil == null || u.SuspendedUntil > now),
            })
            .FirstAsync(cancellationToken);

        // Served by the (UserId, SubmittedAt) index. A pending request is always the latest one.
        var latest = await db.VerificationRequests.AsNoTracking()
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.SubmittedAt)
            .ThenByDescending(r => r.Id)
            .FirstOrDefaultAsync(cancellationToken);

        var canRequest = !user.IsVerified && !user.IsSuspended && latest?.IsPending != true;
        return new VerificationStatusDto(user.IsVerified, canRequest, latest is null ? null : await reader.MineAsync(latest, cancellationToken));
    }
}

internal sealed class GetVerificationRequestsQueryHandler(IAppDbContext db, VerificationReader reader)
    : IQueryHandler<GetVerificationRequestsQuery, Result<CursorPage<AdminVerificationRequestDto>>>
{
    public async ValueTask<Result<CursorPage<AdminVerificationRequestDto>>> Handle(GetVerificationRequestsQuery query, CancellationToken cancellationToken)
    {
        var status = VerificationValues.TryParseStatus(query.Status, out var parsed) ? parsed : VerificationStatus.Pending;
        var limit = Math.Clamp(query.Limit, 1, 50);
        var cursor = VerificationCursor.Decode(query.Cursor);

        // Served by the (Status, SubmittedAt) index.
        var requests = db.VerificationRequests.AsNoTracking().Where(r => r.Status == status);
        if (status == VerificationStatus.Pending)
        {
            if (cursor is { } c)
                requests = requests.Where(r => r.SubmittedAt > c.At || (r.SubmittedAt == c.At && r.Id.CompareTo(c.Id) > 0));
            requests = requests.OrderBy(r => r.SubmittedAt).ThenBy(r => r.Id);
        }
        else
        {
            if (cursor is { } c)
                requests = requests.Where(r => r.DecidedAt < c.At || (r.DecidedAt == c.At && r.Id.CompareTo(c.Id) < 0));
            requests = requests.OrderByDescending(r => r.DecidedAt).ThenByDescending(r => r.Id);
        }

        var page = await requests.Take(limit + 1).ToListAsync(cancellationToken);
        string? next = null;
        if (page.Count > limit)
        {
            page.RemoveAt(limit);
            var last = page[^1];
            next = new VerificationCursor(status == VerificationStatus.Pending ? last.SubmittedAt : last.DecidedAt ?? default, last.Id).Encode();
        }

        return new CursorPage<AdminVerificationRequestDto>(await reader.AdminAsync(page, cancellationToken), next);
    }
}

internal sealed class GetVerificationRequestQueryHandler(IAppDbContext db, VerificationReader reader)
    : IQueryHandler<GetVerificationRequestQuery, Result<AdminVerificationRequestDto>>
{
    public async ValueTask<Result<AdminVerificationRequestDto>> Handle(GetVerificationRequestQuery query, CancellationToken cancellationToken)
    {
        var request = await db.VerificationRequests.AsNoTracking().FirstOrDefaultAsync(r => r.Id == query.RequestId, cancellationToken);
        if (request is null) return VerificationErrors.NotFound;

        var dto = (await reader.AdminAsync([request], cancellationToken)).FirstOrDefault();
        return dto is null ? VerificationErrors.NotFound : dto;
    }
}

internal sealed class GetVerificationProofQueryHandler(IAppDbContext db, IPrivateFileStorage storage)
    : IQueryHandler<GetVerificationProofQuery, Result<VerificationProofContent>>
{
    public async ValueTask<Result<VerificationProofContent>> Handle(GetVerificationProofQuery query, CancellationToken cancellationToken)
    {
        var request = await db.VerificationRequests.AsNoTracking()
            .Where(r => r.Id == query.RequestId)
            .Select(r => new { r.Id, r.ProofFilePath, r.ProofFileContentType })
            .FirstOrDefaultAsync(cancellationToken);
        if (request is null) return VerificationErrors.NotFound;
        if (request.ProofFilePath is null || request.ProofFileContentType is null) return VerificationErrors.ProofNotFound;

        try
        {
            var content = await storage.OpenReadAsync(request.ProofFilePath, cancellationToken);
            return new VerificationProofContent(content, request.ProofFileContentType,
                VerificationProofs.DownloadName(request.Id, request.ProofFileContentType));
        }
        catch (Exception ex) when (ex is FileNotFoundException or DirectoryNotFoundException)
        {
            // The row says there is a file, the disk doesn't (e.g. a restore without the private folder).
            return VerificationErrors.ProofNotFound;
        }
    }
}
