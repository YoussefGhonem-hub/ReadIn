using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Text.RegularExpressions;

namespace ReadIn.Application.Common.Uploads;

/// <summary>
/// Storage layout of an uploaded PDF (ADR 0011): <c>/uploads/documents/{yyyy}/{MM}/{id}/original.pdf</c> and its
/// rendered pages <c>…/{id}/pages/{pageNo}_{400|1080}.webp</c>. <see cref="Id"/> is a random GUID ("N" format), so
/// page URLs of unpublished documents can't be guessed. The original PDF is never served from <c>/uploads</c>.
/// </summary>
public sealed partial record DocumentPath(int Year, int Month, string Id)
{
    public const string Folder = "documents";
    public const int ThumbSize = 400;
    public const int ViewSize = 1080;

    public string Directory => string.Create(CultureInfo.InvariantCulture, $"{UploadPath.Root}/{Folder}/{Year:D4}/{Month:D2}/{Id}");

    public string Original => Directory + "/original.pdf";

    public string Page(int pageNo, int size) => string.Create(CultureInfo.InvariantCulture, $"{Directory}/pages/{pageNo}_{size}.webp");

    public static DocumentPath Create(DateTime utcNow, Guid id) => new(utcNow.Year, utcNow.Month, id.ToString("N"));

    /// <summary>Parses the original or any page path of a document.</summary>
    public static bool TryParse([NotNullWhen(true)] string? value, [NotNullWhen(true)] out DocumentPath? path)
    {
        path = null;
        if (value is null) return false;

        var match = PathPattern().Match(value);
        if (!match.Success) return false;

        path = new DocumentPath(
            int.Parse(match.Groups["year"].ValueSpan, CultureInfo.InvariantCulture),
            int.Parse(match.Groups["month"].ValueSpan, CultureInfo.InvariantCulture),
            match.Groups["id"].Value);
        return true;
    }

    public override string ToString() => Directory;

    [GeneratedRegex(@"^/uploads/documents/(?<year>\d{4})/(?<month>0[1-9]|1[0-2])/(?<id>[0-9a-f]{32})/(original\.pdf|pages/[1-9]\d{0,2}_(400|1080)\.webp)\z")]
    private static partial Regex PathPattern();
}
