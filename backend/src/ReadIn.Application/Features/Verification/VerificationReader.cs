using System.Globalization;
using System.Text;
using Microsoft.EntityFrameworkCore;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Security;
using ReadIn.Application.Common.Uploads;
using ReadIn.Application.Features.Articles;
using ReadIn.Domain.Common;
using ReadIn.Domain.Verification;

namespace ReadIn.Application.Features.Verification;

/// <summary>Builds what the user's page and the admin queue show (SPEC F19), a fixed number of queries per page.</summary>
public sealed class VerificationReader(IAppDbContext db, IFileStorage storage, ICurrentUser currentUser)
{
    public async Task<MyVerificationRequestDto> MineAsync(VerificationRequest request, CancellationToken ct)
    {
        var fields = await FieldsAsync([request.FieldId], ct);
        return Mine(request, fields[request.FieldId]);
    }

    public static MyVerificationRequestDto Mine(VerificationRequest request, VerificationFieldDto field) => new(
        request.Id,
        request.Status,
        field,
        request.JobTitle,
        request.ProofUrl,
        request.ProofFileName,
        request.Note,
        request.SubmittedAt,
        request.DecidedAt,
        request.RejectionReason);

    public async Task<List<AdminVerificationRequestDto>> AdminAsync(IReadOnlyList<VerificationRequest> rows, CancellationToken ct)
    {
        if (rows.Count == 0) return [];

        var userIds = rows.Select(r => r.UserId).Distinct().ToList();
        var users = await db.Users.IgnoreQueryFilters().AsNoTracking()
            .Where(u => userIds.Contains(u.Id))
            .Select(u => new AuthorDto(u.Id, u.DisplayName, u.Username, u.AvatarUrl, u.Roles.Any(r => r.RoleId == RoleIds.VerifiedWriter)))
            .ToDictionaryAsync(u => u.Id, ct);

        var deciderIds = rows.Where(r => r.DecidedById != null).Select(r => r.DecidedById!.Value).Distinct().ToList();
        var deciders = deciderIds.Count == 0
            ? []
            : await db.Users.AsNoTracking()
                .Where(u => deciderIds.Contains(u.Id))
                .Select(u => new VerificationDeciderDto(u.Id, u.Username))
                .ToDictionaryAsync(u => u.Id, ct);

        var fields = await FieldsAsync(rows.Select(r => r.FieldId), ct);
        return
        [
            .. rows.Where(r => users.ContainsKey(r.UserId)).Select(r => new AdminVerificationRequestDto(
                r.Id,
                r.Status,
                users[r.UserId] with { AvatarUrl = storage.ToPublicUrl(users[r.UserId].AvatarUrl) },
                fields[r.FieldId],
                r.JobTitle,
                r.ProofUrl,
                r.HasProofFile ? new VerificationProofDto(r.ProofFileName!, r.ProofFileContentType!, r.ProofFileSizeBytes ?? 0) : null,
                r.Note,
                r.SubmittedAt,
                r.DecidedAt,
                r.DecidedById is { } deciderId ? deciders.GetValueOrDefault(deciderId) : null,
                r.RejectionReason)),
        ];
    }

    /// <summary>
    /// Fields by id, named in the request's UI language. Disabled fields too unless <paramref name="enabledOnly"/>: an old
    /// request keeps its field.
    /// </summary>
    public async Task<IReadOnlyDictionary<Guid, VerificationFieldDto>> FieldsAsync(IEnumerable<Guid> ids, CancellationToken ct, bool enabledOnly = false)
    {
        var wanted = ids.Distinct().ToList();
        var english = currentUser.UiLanguage == UiLanguages.English;
        return await db.Fields.AsNoTracking()
            .Where(f => wanted.Contains(f.Id) && (!enabledOnly || f.IsEnabled))
            .Select(f => new VerificationFieldDto(f.Id, f.Slug, english ? f.NameEn : f.NameAr))
            .ToDictionaryAsync(f => f.Id, ct);
    }
}

/// <summary>Parses <c>status</c> of the admin queue: a name in any case, never a number.</summary>
internal static class VerificationValues
{
    public static bool TryParseStatus(string? value, out VerificationStatus status) =>
        Enum.TryParse(value, ignoreCase: true, out status) && !int.TryParse(value, out _) && Enum.IsDefined(status);
}

/// <summary>
/// Opaque keyset cursor of the admin queue: pending pages by (submitted ASC, id ASC), approved and rejected by
/// (decided DESC, id DESC).
/// </summary>
internal readonly record struct VerificationCursor(DateTime At, Guid Id)
{
    public string Encode() =>
        Convert.ToBase64String(Encoding.UTF8.GetBytes($"{At.Ticks.ToString(CultureInfo.InvariantCulture)}:{Id:N}"))
            .TrimEnd('=').Replace('+', '-').Replace('/', '_');

    public static VerificationCursor? Decode(string? cursor)
    {
        if (string.IsNullOrWhiteSpace(cursor)) return null;
        try
        {
            var base64 = cursor.Replace('-', '+').Replace('_', '/');
            base64 = base64.PadRight(base64.Length + (4 - base64.Length % 4) % 4, '=');
            var parts = Encoding.UTF8.GetString(Convert.FromBase64String(base64)).Split(':');
            if (parts.Length != 2) return null;
            return new VerificationCursor(
                new DateTime(long.Parse(parts[0], CultureInfo.InvariantCulture), DateTimeKind.Utc),
                Guid.ParseExact(parts[1], "N"));
        }
        catch (Exception ex) when (ex is FormatException or OverflowException or ArgumentOutOfRangeException)
        {
            return null;
        }
    }
}
