using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Unicode;

namespace ReadIn.Application.Features.Articles.Editor;

/// <summary>How an <see cref="ArticleDraftDocument"/> is stored in working copies and revisions (F05).</summary>
public static class ArticleDraftJson
{
    private static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web)
    {
        Encoder = JavaScriptEncoder.Create(UnicodeRanges.All), // Arabic stays readable and ~6× smaller than \uXXXX
    };

    public static string Serialize(ArticleDraftDocument document) => JsonSerializer.Serialize(document, Options);

    public static ArticleDraftDocument Deserialize(string json) => JsonSerializer.Deserialize<ArticleDraftDocument>(json, Options)!;
}
