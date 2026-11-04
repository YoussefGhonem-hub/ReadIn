using System.Globalization;
using System.Text;
using Microsoft.Extensions.Logging;
using ReadIn.Application.Common.Interfaces;
using ReadIn.Application.Common.Uploads;
using ReadIn.Domain.Verification;

namespace ReadIn.Application.Features.Verification;

/// <summary>A proof file type: what its bytes say, never its name or the client's content type (SPEC §24).</summary>
public sealed record VerificationProofFormat(string ContentType, string Extension)
{
    public static readonly VerificationProofFormat Pdf = new("application/pdf", ".pdf");
    public static readonly VerificationProofFormat Jpeg = new("image/jpeg", ".jpg");
    public static readonly VerificationProofFormat Png = new("image/png", ".png");
    public static readonly VerificationProofFormat Webp = new("image/webp", ".webp");

    public static readonly IReadOnlyList<VerificationProofFormat> All = [Pdf, Jpeg, Png, Webp];

    public static VerificationProofFormat? FromContentType(string? contentType) => All.FirstOrDefault(f => f.ContentType == contentType);
}

/// <summary>
/// The rules of a verification proof file (SPEC F19): a PDF, JPEG, PNG or WebP of at most 10 MB, recognized by its magic
/// bytes; stored privately as <c>verification/{requestId}{.ext}</c>; shown to admins under a sanitized name.
/// </summary>
public static class VerificationProofs
{
    /// <summary>The folder of the private store that holds the proofs.</summary>
    public const string Folder = "verification";

    /// <summary>Bytes needed to recognize every accepted format.</summary>
    public const int HeaderLength = 12;

    /// <summary>Characters Windows refuses in file names (the same on every server, unlike <see cref="Path.GetInvalidFileNameChars"/>).</summary>
    private const string InvalidNameChars = "<>:\"/\\|?*";

    /// <summary>The format the bytes start with; null for anything else (HEIC, GIF, ZIP, text, an empty file…).</summary>
    public static VerificationProofFormat? Detect(ReadOnlySpan<byte> header)
    {
        if (header.StartsWith("%PDF-"u8)) return VerificationProofFormat.Pdf;
        return ImageSignatures.Detect(header) switch
        {
            ImageFormat.Jpeg => VerificationProofFormat.Jpeg,
            ImageFormat.Png => VerificationProofFormat.Png,
            ImageFormat.Webp => VerificationProofFormat.Webp,
            _ => null,
        };
    }

    public static string PathFor(Guid requestId, VerificationProofFormat format) => $"{Folder}/{requestId}{format.Extension}";

    /// <summary>The request a stored proof belongs to: <c>verification/{id}{.ext}</c> → id.</summary>
    public static Guid? RequestIdOf(string relativePath)
    {
        if (!relativePath.StartsWith(Folder + "/", StringComparison.Ordinal)) return null;
        var name = relativePath[(Folder.Length + 1)..];
        var dot = name.IndexOf('.', StringComparison.Ordinal);
        return Guid.TryParse(dot < 0 ? name : name[..dot], out var id) ? id : null;
    }

    /// <summary><c>verification-proof-{id}{.ext}</c>: the download name admins get, never the uploaded one.</summary>
    public static string DownloadName(Guid requestId, string contentType) =>
        $"verification-proof-{requestId}{VerificationProofFormat.FromContentType(contentType)?.Extension}";

    /// <summary>
    /// The uploaded file's name as admins see it: no folders, no control or direction-override characters, no characters
    /// file systems reject, whitespace collapsed, at most <see cref="VerificationRequest.MaxProofFileNameLength"/>
    /// characters (the extension kept). Empty → <c>proof{.ext}</c>.
    /// </summary>
    public static string DisplayName(string? fileName, VerificationProofFormat format)
    {
        var name = (fileName ?? string.Empty).Replace('\\', '/');
        name = name[(name.LastIndexOf('/') + 1)..];

        var cleaned = new StringBuilder(name.Length);
        foreach (var c in name)
        {
            if (char.IsWhiteSpace(c) || InvalidNameChars.Contains(c)) cleaned.Append(' ');
            else if (!char.IsControl(c) && !IsDirectionControl(c) && (char.GetUnicodeCategory(c) != UnicodeCategory.Format || c is '‌' or '‍'))
                cleaned.Append(c);
        }
        var result = string.Join(' ', cleaned.ToString().Split(' ', StringSplitOptions.RemoveEmptyEntries)).Trim('.', ' ');
        if (result.Length == 0) return "proof" + format.Extension;
        if (result.Length <= VerificationRequest.MaxProofFileNameLength) return result;

        var extension = Path.GetExtension(result);
        if (extension.Length is 0 or > 10) return Truncate(result, VerificationRequest.MaxProofFileNameLength);
        return Truncate(result[..^extension.Length], VerificationRequest.MaxProofFileNameLength - extension.Length).TrimEnd('.', ' ') + extension;
    }

    /// <summary>LRM/RLM, embeddings, overrides and isolates: they could make a name read as something else.</summary>
    private static bool IsDirectionControl(char c) => c is '‎' or '‏' or (>= '‪' and <= '‮') or (>= '⁦' and <= '⁩');

    /// <summary>Never splits a surrogate pair.</summary>
    private static string Truncate(string text, int length)
    {
        if (text.Length <= length) return text;
        var cut = char.IsHighSurrogate(text[length - 1]) ? length - 1 : length;
        return text[..cut];
    }
}

/// <summary>
/// Deletes proof files after the database change is saved. A failed delete is only logged: the file is then an orphan
/// (no request points at it) and the daily cleanup job removes it.
/// </summary>
public sealed partial class VerificationProofFiles(IPrivateFileStorage storage, ILogger<VerificationProofFiles> logger)
{
    public async Task DeleteAsync(IEnumerable<string?> paths, CancellationToken cancellationToken)
    {
        foreach (var path in paths)
        {
            if (path is null) continue;
            try
            {
                await storage.DeleteAsync(path, cancellationToken);
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or ArgumentException)
            {
                LogDeleteFailed(logger, ex, path);
            }
        }
    }

    [LoggerMessage(Level = LogLevel.Warning, Message = "Could not delete the private file {Path}; the verification proofs cleanup job will retry")]
    private static partial void LogDeleteFailed(ILogger logger, Exception exception, string path);
}
