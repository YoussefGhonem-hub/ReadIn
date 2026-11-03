using System.Text.Json;
using ReadIn.Application.Common.Content;
using ReadIn.Domain.Articles;

namespace ReadIn.Application.UnitTests.Content;

public sealed class RDocProcessorTests
{
    private readonly RDocProcessor _processor = new();

    private static JsonElement Parse(string json) => JsonDocument.Parse(json).RootElement;

    private static JsonElement Doc(string language, string blocks) =>
        Parse($$"""{ "version": 1, "language": "{{language}}", "blocks": [{{blocks}}] }""");

    [Fact]
    public void Kitchen_sink_example_with_every_block_type_is_valid()
    {
        var json = File.ReadAllText(RepoPaths.Shared("rdoc", "examples", "kitchen-sink.ar-EG.json"));

        var result = _processor.Process(Parse(json), "ar-EG", "عنوان");

        result.IsSuccess.Should().BeTrue(result.Error?.Details is { } d ? string.Join("; ", d.Select(e => $"{e.Key}: {string.Join(",", e.Value)}")) : result.Error?.Code);
        result.Value.Headings.Should().HaveCount(2);
        result.Value.TermIds.Should().Contain("dependency-injection");
        result.Value.CodeLanguages.Should().Contain(["csharp", "typescript", "dart"]);
        result.Value.Content.Summary.Should().StartWith("الخلاصة");
    }

    /// <summary>The seeded articles (content/articles) and the integration-test fixtures (backend/tests/fixtures/content).</summary>
    public static TheoryData<string, string> ContentArticles()
    {
        var data = new TheoryData<string, string>();
        string[] roots = [RepoPaths.Content("articles"), Path.Combine(RepoPaths.Root, "backend", "tests", "fixtures", "content", "articles")];
        foreach (var file in roots.Where(Directory.Exists).SelectMany(r => Directory.EnumerateFiles(r, "*.json", SearchOption.AllDirectories))
                     .Where(f => Path.GetFileName(f) != "meta.json"))
            data.Add(Path.GetRelativePath(RepoPaths.Root, file).Replace('\\', '/'), Path.GetFileNameWithoutExtension(file));
        return data;
    }

    [Theory]
    [MemberData(nameof(ContentArticles))]
    public void Every_content_article_is_valid_RDoc(string relativePath, string language)
    {
        var json = File.ReadAllText(Path.Combine(RepoPaths.Root, relativePath));

        var result = _processor.Process(Parse(json), language);

        result.IsSuccess.Should().BeTrue($"{relativePath}: {result.Error?.Code}");
    }

    [Theory]
    [InlineData("""{ "id": "x", "type": "marquee", "content": [] }""")]
    [InlineData("""{ "id": "x", "type": "paragraph", "content": [], "style": "color:red" }""")]
    [InlineData("""{ "id": "x", "type": "image", "src": "https://cdn.readin.app/a.png" }""")]
    [InlineData("""{ "id": "x", "type": "image", "src": "http://insecure.example/a.png", "alt": "a" }""")]
    [InlineData("""{ "id": "x", "type": "paragraph", "content": [{ "type": "text", "text": "x", "marks": [{ "type": "link", "href": "javascript:alert(1)" }] }] }""")]
    [InlineData("""{ "id": "x", "type": "paragraph", "content": [{ "type": "html", "text": "<b>x</b>" }] }""")]
    [InlineData("""{ "id": "x", "type": "heading", "level": 1, "content": [{ "type": "text", "text": "H1 is the title" }] }""")]
    public void Unknown_types_attributes_and_unsafe_values_are_rejected(string block)
    {
        var result = _processor.Process(Doc("en", block));

        result.Error!.Code.Should().Be(ArticleErrors.InvalidContent.Code);
        result.Error.Details.Should().NotBeEmpty();
    }

    [Theory]
    [InlineData("youtube", "https://www.youtube.com/watch?v=abc", true)]
    [InlineData("github-gist", "https://gist.github.com/u/123", true)]
    [InlineData("youtube", "https://evil.example.com/watch?v=abc", false)]
    [InlineData("github-gist", "https://github.com.evil.io/x", false)]
    public void Embeds_are_restricted_to_the_allow_list(string provider, string url, bool allowed)
    {
        var result = _processor.Process(Doc("en", $$"""{ "id": "e", "type": "embed", "provider": "{{provider}}", "url": "{{url}}" }"""));

        result.IsSuccess.Should().Be(allowed);
    }

    [Fact]
    public void Bidi_override_and_control_characters_are_stripped_even_in_code()
    {
        RDocProcessor.CleanText("abc\u202Edef\u2066x\u2069", isCode: false).Should().Be("abcdefx");
        RDocProcessor.CleanText("if (isAdmin\u202E) {\u2066\t}", isCode: true).Should().Be("if (isAdmin) {\t}");
        RDocProcessor.CleanText("line1\nline2\u0007", isCode: false).Should().Be("line1\nline2");
    }

    [Fact]
    public void Stored_json_is_sanitized_and_keeps_arabic_unescaped()
    {
        var result = _processor.Process(Doc("ar-EG", """{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "مرحبا \u202Ebad" }] }"""));

        result.Value.Content.Json.Should().Contain("مرحبا bad").And.NotContain("\\u0645").And.NotContain("\u202E");
    }

    [Fact]
    public void Language_must_match_the_requested_version()
    {
        _processor.Process(Doc("en", ""), expectedLanguage: "ar-EG").Error.Should().Be(RDocErrors.LanguageMismatch);
    }

    [Fact]
    public void Reading_time_uses_180_wpm_for_arabic_and_230_for_english_plus_code()
    {
        var words = string.Join(' ', Enumerable.Repeat("كلمة", 360));
        var arabic = _processor.Process(Doc("ar-EG", $$"""{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "{{words}}" }] }"""));
        var english = _processor.Process(Doc("en", $$"""{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "{{words}}" }] }"""));
        var code = string.Join("\\n", Enumerable.Repeat("var x = 1;", 30));
        var withCode = _processor.Process(Doc("en", $$"""{ "id": "c", "type": "code", "lang": "csharp", "code": "{{code}}" }"""));

        arabic.Value.Content.ReadingTimeMinutes.Should().Be(2);   // 360 / 180
        english.Value.Content.ReadingTimeMinutes.Should().Be(2);  // ceil(360 / 230)
        withCode.Value.Content.ReadingTimeMinutes.Should().Be(2); // 30 lines × 4 s
        arabic.Value.Content.WordCount.Should().Be(360);
    }

    [Fact]
    public void Search_text_includes_the_title_and_is_normalized()
    {
        var result = _processor.Process(
            Doc("ar-EG", """{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "مُقدّمة" }] }"""),
            title: "أساسيات الـبرمجة");

        result.Value.Content.SearchText.Should().Be("اساسيات البرمجه مقدمه");
    }
}
