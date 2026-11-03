using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Text.RegularExpressions;

namespace ReadIn.Application.Common.Uploads;

/// <summary>
/// The relative path of one stored upload variant: <c>/uploads/{folder}/{yyyy}/{MM}/{id}_{size}.webp</c> (ADR 0010).
/// <see cref="Id"/> is a random GUID ("N" format); the user's file name never reaches the path.
/// </summary>
public sealed partial record UploadPath(UploadPurpose Purpose, int Year, int Month, string Id, int Size)
{
    public const string Root = "/uploads";

    public string Value => string.Create(CultureInfo.InvariantCulture, $"{Root}/{Purpose.Folder}/{Year:D4}/{Month:D2}/{Id}_{Size}.webp");

    /// <summary>Every size of the same upload. They share the folder and the id.</summary>
    public IEnumerable<UploadPath> Variants => Purpose.Sizes.Select(size => this with { Size = size });

    public static UploadPath Create(UploadPurpose purpose, DateTime utcNow, Guid id, int size) =>
        new(purpose, utcNow.Year, utcNow.Month, id.ToString("N"), size);

    public static bool TryParse([NotNullWhen(true)] string? value, [NotNullWhen(true)] out UploadPath? path)
    {
        path = null;
        if (value is null) return false;

        var match = PathPattern().Match(value);
        if (!match.Success || UploadPurpose.FromFolder(match.Groups["folder"].Value) is not { } purpose) return false;

        path = new UploadPath(
            purpose,
            int.Parse(match.Groups["year"].ValueSpan, CultureInfo.InvariantCulture),
            int.Parse(match.Groups["month"].ValueSpan, CultureInfo.InvariantCulture),
            match.Groups["id"].Value,
            int.Parse(match.Groups["size"].ValueSpan, CultureInfo.InvariantCulture));
        return true;
    }

    /// <summary>
    /// Ids of all uploads mentioned in <paramref name="text"/>: relative paths, absolute URLs or <c>rdoc-asset://</c>
    /// sources inside RDoc JSON.
    /// </summary>
    public static IEnumerable<string> FindIds(string text) =>
        IdPattern().Matches(text).Select(m => m.Groups["id"].Value);

    /// <summary>The upload id in a stored file name (<c>{id}_{size}.webp</c>), or null for any other file.</summary>
    public static string? IdFromFileName(string fileName) =>
        FileNamePattern().Match(fileName) is { Success: true } match ? match.Groups["id"].Value : null;

    public override string ToString() => Value;

    // \z, not $: "$" would also match before a trailing newline.
    [GeneratedRegex(@"^/uploads/(?<folder>[a-z-]+)/(?<year>\d{4})/(?<month>0[1-9]|1[0-2])/(?<id>[0-9a-f]{32})_(?<size>[1-9]\d{0,4})\.webp\z")]
    private static partial Regex PathPattern();

    [GeneratedRegex(@"uploads/[a-z-]+/\d{4}/\d{2}/(?<id>[0-9a-f]{32})_\d{1,5}\.webp")]
    private static partial Regex IdPattern();

    [GeneratedRegex(@"^(?<id>[0-9a-f]{32})_[1-9]\d{0,4}\.webp\z")]
    private static partial Regex FileNamePattern();
}
