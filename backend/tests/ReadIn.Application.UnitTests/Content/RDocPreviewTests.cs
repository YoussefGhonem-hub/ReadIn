using System.Text.Json.Nodes;
using ReadIn.Application.Common.Content;

namespace ReadIn.Application.UnitTests.Content;

/// <summary>What a feed card's "Read more" shows (SPEC F34): the first whole blocks, about 300 words.</summary>
public sealed class RDocPreviewTests
{
    private static string Words(int count, string word = "word") => string.Join(' ', Enumerable.Repeat(word, count));

    private static JsonObject P(string id, int words) =>
        new() { ["id"] = id, ["type"] = "paragraph", ["content"] = new JsonArray(new JsonObject { ["type"] = "text", ["text"] = Words(words) }) };

    private static JsonObject Heading(string id) =>
        new() { ["id"] = id, ["type"] = "heading", ["level"] = 2, ["content"] = new JsonArray(new JsonObject { ["type"] = "text", ["text"] = "Next part" }) };

    private static string Doc(params JsonNode[] blocks) =>
        new JsonObject { ["version"] = 1, ["language"] = "en", ["blocks"] = new JsonArray(blocks) }.ToJsonString();

    private static JsonArray Blocks(RDocPreviewResult preview) => JsonNode.Parse(preview.Json)!["blocks"]!.AsArray();

    [Fact]
    public void Takes_whole_blocks_until_the_block_that_reaches_300_words()
    {
        var json = Doc([.. Enumerable.Range(1, 10).Select(i => (JsonNode)P($"p{i}", 50))]);
        var source = JsonNode.Parse(json)!["blocks"]!.AsArray();

        var preview = RDocPreview.Take(json);

        preview.IsComplete.Should().BeFalse();
        var taken = Blocks(preview);
        taken.Should().HaveCount(6, "50 words a block reach 300 with the sixth");
        for (var i = 0; i < taken.Count; i++)
            JsonNode.DeepEquals(taken[i], source[i]).Should().BeTrue("blocks are never cut or changed");
        JsonNode.Parse(preview.Json)!["language"]!.GetValue<string>().Should().Be("en");
    }

    [Fact]
    public void A_first_block_over_the_budget_is_kept_whole()
    {
        var preview = RDocPreview.Take(Doc(P("long", 800), P("next", 10)));

        Blocks(preview).Should().ContainSingle();
        Blocks(preview)[0]!["content"]![0]!["text"]!.GetValue<string>().Should().Be(Words(800));
        preview.IsComplete.Should().BeFalse();
    }

    [Fact]
    public void A_short_article_is_complete_and_unchanged()
    {
        var json = Doc(P("a", 100), P("b", 150), Heading("h"), P("c", 40));

        var preview = RDocPreview.Take(json);

        preview.IsComplete.Should().BeTrue();
        preview.Json.Should().Be(json);
    }

    [Fact]
    public void A_cut_preview_never_ends_on_a_heading_or_a_divider()
    {
        // 299 words, then the heading's two reach the budget: the preview would end on "divider, heading".
        var preview = RDocPreview.Take(Doc(P("a", 299), new JsonObject { ["id"] = "d", ["type"] = "divider" }, Heading("h"), P("b", 100)));

        Blocks(preview).Select(b => b!["id"]!.GetValue<string>()).Should().Equal("a");
        preview.IsComplete.Should().BeFalse();
    }

    [Fact]
    public void A_one_block_article_is_complete_however_long()
    {
        var preview = RDocPreview.Take(Doc(P("only", 1000)));

        preview.IsComplete.Should().BeTrue();
        Blocks(preview).Should().ContainSingle();
    }

    [Fact]
    public void Words_count_every_text_a_reader_reads_and_code_tabs_only_the_first_tab()
    {
        var steps = JsonNode.Parse("""
            { "id": "s", "type": "steps", "items": [{ "title": "Two words", "content": [{ "type": "term", "termId": "x", "text": "three more words" }] }] }
            """);
        var table = JsonNode.Parse("""
            { "id": "t", "type": "table", "header": [[{ "type": "text", "text": "a b" }]], "rows": [[[{ "type": "text", "text": "c", "marks": [{ "type": "link", "href": "https://x.io" }] }]]] }
            """);
        var image = JsonNode.Parse("""{ "id": "i", "type": "image", "src": "https://cdn.readin.app/a.png", "alt": "not counted", "caption": "one caption" }""");
        var tabs = JsonNode.Parse("""
            { "id": "ct", "type": "codeTabs", "tabs": [{ "label": "C#", "lang": "csharp", "code": "var x = 1;" }, { "label": "TS", "lang": "typescript", "code": "let x = 1; let y = 2;" }] }
            """);
        var quote = JsonNode.Parse("""{ "id": "q", "type": "quote", "content": [{ "type": "text", "text": "to be" }], "cite": "Hamlet" }""");

        RDocPreview.Words(steps).Should().Be(5);
        RDocPreview.Words(table).Should().Be(3);
        RDocPreview.Words(image).Should().Be(2);
        RDocPreview.Words(tabs).Should().Be(4);
        RDocPreview.Words(quote).Should().Be(3);
    }
}
