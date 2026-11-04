using System.Text.Json;
using ReadIn.Application.Common.Content;

namespace ReadIn.Application.UnitTests.Content;

/// <summary>The feed card's excerpt (SPEC F34, §13.5).</summary>
public sealed class RDocExcerptTests
{
    private static JsonElement Doc(string language, params string[] blocks) =>
        JsonDocument.Parse($$"""{ "version": 1, "language": "{{language}}", "blocks": [{{string.Join(',', blocks)}}] }""").RootElement;

    private static string P(string text, string id = "p") =>
        $$"""{ "id": "{{id}}", "type": "paragraph", "content": [{ "type": "text", "text": "{{text}}" }] }""";

    [Fact]
    public void Takes_the_text_blocks_in_order_one_line_each_and_skips_the_rest()
    {
        var document = Doc("en",
            """{ "id": "s", "type": "summary", "content": [{ "type": "text", "text": "TL;DR first." }] }""",
            """{ "id": "h", "type": "heading", "level": 2, "content": [{ "type": "text", "text": "A heading" }] }""",
            P("A paragraph."),
            """{ "id": "c", "type": "code", "lang": "csharp", "code": "var x = 1;" }""",
            """{ "id": "l", "type": "bulletList", "items": [[{ "type": "text", "text": "One" }], [{ "type": "text", "text": "Two" }]] }""",
            """{ "id": "t", "type": "table", "header": [[{ "type": "text", "text": "Col" }]], "rows": [[[{ "type": "text", "text": "Cell" }]]] }""",
            """{ "id": "st", "type": "steps", "items": [{ "title": "Install", "content": [{ "type": "text", "text": "Run it." }] }] }""",
            """{ "id": "i", "type": "image", "src": "https://cdn.readin.app/a.png", "alt": "Alt", "caption": "Caption" }""",
            """{ "id": "q", "type": "quote", "content": [{ "type": "text", "text": "Quoted." }] }""",
            """{ "id": "e", "type": "embed", "provider": "youtube", "url": "https://www.youtube.com/watch?v=abc" }""",
            """{ "id": "co", "type": "callout", "variant": "tip", "title": "Tip", "content": [{ "type": "text", "text": "Use it." }] }""",
            """{ "id": "o", "type": "orderedList", "items": [[{ "type": "text", "text": "Last" }]] }""");

        var excerpt = RDocExcerpt.From(document);

        excerpt.Text.Should().Be("TL;DR first.\nA paragraph.\nOne\nTwo\nInstall\nRun it.\nQuoted.\nTip\nUse it.\nLast");
        excerpt.HasMore.Should().BeTrue("headings, code, tables, images and embeds are only in the article");
    }

    [Fact]
    public void Terms_and_mentions_give_their_text_and_hard_breaks_a_line()
    {
        var document = Doc("ar-EG", """
            { "id": "p", "type": "paragraph", "content": [
              { "type": "text", "text": "لو انت شغال بـ " },
              { "type": "text", "text": "ASP.NET Core", "marks": [{ "type": "bold" }] },
              { "type": "text", "text": "، أكيد شفت الـ " },
              { "type": "term", "termId": "dependency-injection", "text": "Dependency Injection" },
              { "type": "text", "text": " مع " },
              { "type": "mention", "userId": "00000000-0000-0000-0000-000000000001", "text": "@sara" },
              { "type": "hardBreak" },
              { "type": "text", "text": "سطر   تاني" }
            ]}
            """);

        var excerpt = RDocExcerpt.From(document);

        excerpt.Text.Should().Be("لو انت شغال بـ ASP.NET Core، أكيد شفت الـ Dependency Injection مع @sara\nسطر تاني");
        excerpt.HasMore.Should().BeFalse("the excerpt is the whole article");
    }

    [Fact]
    public void A_short_text_only_article_is_complete_and_a_divider_adds_nothing()
    {
        var excerpt = RDocExcerpt.From(Doc("en", P("First.", "a"), """{ "id": "d", "type": "divider" }""", P("Second.", "b")));

        excerpt.Text.Should().Be("First.\nSecond.");
        excerpt.HasMore.Should().BeFalse();
    }

    [Fact]
    public void A_quote_cite_is_more_than_the_excerpt_shows()
    {
        var excerpt = RDocExcerpt.From(Doc("en", """{ "id": "q", "type": "quote", "content": [{ "type": "text", "text": "Quoted." }], "cite": "Someone" }"""));

        excerpt.Text.Should().Be("Quoted.");
        excerpt.HasMore.Should().BeTrue();
    }

    [Theory]
    [InlineData("word")]
    [InlineData("كلمة")]
    public void Long_text_is_cut_at_a_word_within_400_characters_without_an_ellipsis(string word)
    {
        var text = string.Join(' ', Enumerable.Repeat(word, 150));

        var excerpt = RDocExcerpt.From(Doc("en", P(text)));

        excerpt.Text.Length.Should().BeLessThanOrEqualTo(400).And.BeGreaterThan(390);
        excerpt.Text.Should().EndWith(word).And.NotContain("…");
        text.Should().StartWith(excerpt.Text + " ", "the cut falls between two words");
        excerpt.HasMore.Should().BeTrue();
    }

    [Fact]
    public void Text_of_exactly_400_characters_is_whole()
    {
        var text = new string('a', 199) + " " + new string('b', 200);

        var excerpt = RDocExcerpt.From(Doc("en", P(text)));

        excerpt.Text.Should().Be(text);
        excerpt.HasMore.Should().BeFalse();
    }

    [Fact]
    public void One_word_longer_than_the_excerpt_is_cut_inside_but_never_inside_a_surrogate_pair()
    {
        RDocExcerpt.CutAtWord(new string('x', 500), 400).Should().HaveLength(400);
        RDocExcerpt.CutAtWord(new string('x', 399) + "😀😀", 400).Should().Be(new string('x', 399));
        RDocExcerpt.CutAtWord("one two", 5).Should().Be("one");
        RDocExcerpt.CutAtWord("one two", 3).Should().Be("one");
    }

    [Fact]
    public void An_article_without_text_blocks_has_an_empty_excerpt_and_more()
    {
        var excerpt = RDocExcerpt.From(Doc("en", """{ "id": "c", "type": "code", "lang": "csharp", "code": "var x = 1;" }"""));

        excerpt.Text.Should().BeEmpty();
        excerpt.HasMore.Should().BeTrue();
    }

    [Fact]
    public void A_document_it_cannot_read_gives_an_empty_excerpt_with_more()
    {
        RDocExcerpt.From(JsonDocument.Parse("""{ "version": 1 }""").RootElement).Should().Be(new RDocExcerptResult("", true));
        RDocExcerpt.From(JsonDocument.Parse("[]").RootElement).Should().Be(new RDocExcerptResult("", true));
    }

    [Fact]
    public void The_processor_stores_the_excerpt_with_the_content()
    {
        var content = new RDocProcessor().Process(Doc("en", P("Hello world."),
            """{ "id": "h", "type": "heading", "level": 2, "content": [{ "type": "text", "text": "More" }] }""")).Value.Content;

        content.Excerpt.Should().Be("Hello world.");
        content.ExcerptHasMore.Should().BeTrue();
    }
}
