using System.Text.Json;
using System.Text.Json.Nodes;
using ReadIn.Application.Common.Content;

namespace ReadIn.Application.UnitTests.Content;

/// <summary>What goes live checks each @mention (SPEC F05, F18): allowed ones keep the link with the current @username.</summary>
public sealed class RDocMentionsTests
{
    private static readonly Guid Mona = Guid.Parse("0a6f1c62-3c55-4a43-9a43-2bd0a7e6c101");
    private static readonly Guid Omar = Guid.Parse("0a6f1c62-3c55-4a43-9a43-2bd0a7e6c102");
    private static readonly Guid Sara = Guid.Parse("0a6f1c62-3c55-4a43-9a43-2bd0a7e6c103");

    private static string Mention(Guid id, string text) => $$"""{ "type": "mention", "userId": "{{id}}", "text": "{{text}}" }""";

    /// <summary>Mentions in a paragraph, a list item, a table cell and a step: every place inline nodes live.</summary>
    private static JsonElement Doc() => JsonDocument.Parse($$"""
        { "version": 1, "language": "en", "blocks": [
          { "id": "p1", "type": "paragraph", "content": [
            { "type": "text", "text": "Thanks " }, {{Mention(Mona, "@mona_old")}}, { "type": "text", "text": " and " }, {{Mention(Omar, "@omar")}} ] },
          { "id": "l1", "type": "bulletList", "items": [[ {{Mention(Sara, "@sara")}} ]] },
          { "id": "t1", "type": "table", "header": [[ { "type": "text", "text": "Who" } ]], "rows": [[[ {{Mention(Mona, "@mona_old")}} ]]] },
          { "id": "s1", "type": "steps", "items": [{ "title": "Ask", "content": [ { "type": "mention", "userId": "not-a-guid", "text": "@ghost" } ] }] }
        ] }
        """).RootElement;

    private static JsonObject InlineAt(JsonElement document, string path)
    {
        JsonNode node = JsonNode.Parse(document.GetRawText())!;
        foreach (var part in path.Split('/'))
            node = int.TryParse(part, out var index) ? node[index]! : node[part]!;
        return node.AsObject();
    }

    [Fact]
    public void The_mentioned_ids_are_distinct_in_document_order_and_bad_ids_are_skipped() =>
        RDocMentions.UserIds(Doc()).Should().Equal(Mona, Omar, Sara);

    [Fact]
    public void Allowed_mentions_keep_the_link_with_the_current_username_and_the_rest_become_plain_text()
    {
        var applied = RDocMentions.Apply(Doc(), new Dictionary<Guid, string> { [Mona] = "mona", [Sara] = "sara_new" });

        InlineAt(applied, "blocks/0/content/1").ToJsonString().Should().Be($$"""{"type":"mention","userId":"{{Mona}}","text":"@mona"}""");
        InlineAt(applied, "blocks/0/content/3").ToJsonString().Should().Be("""{"type":"text","text":"@omar"}""", "Omar doesn't allow the author");
        InlineAt(applied, "blocks/1/items/0/0")["text"]!.GetValue<string>().Should().Be("@sara_new");
        InlineAt(applied, "blocks/2/rows/0/0/0")["text"]!.GetValue<string>().Should().Be("@mona", "every place is checked");
        InlineAt(applied, "blocks/3/items/0/content/0").ToJsonString().Should().Be("""{"type":"text","text":"@ghost"}""", "an unknown id links nobody");
        InlineAt(applied, "blocks/0/content/0")["text"]!.GetValue<string>().Should().Be("Thanks ", "other nodes are untouched");
    }

    [Fact]
    public void Nobody_allowed_turns_every_mention_into_text_and_the_result_is_valid_RDoc()
    {
        var applied = RDocMentions.Apply(Doc(), new Dictionary<Guid, string>());

        RDocMentions.UserIds(applied).Should().BeEmpty();
        applied.GetRawText().Should().NotContain("\"mention\"");
        new RDocProcessor().Process(applied, "en").IsSuccess.Should().BeTrue();
    }

    [Fact]
    public void A_document_without_mentions_comes_back_unchanged()
    {
        var plain = JsonDocument.Parse("""{ "version": 1, "language": "en", "blocks": [{ "id": "p1", "type": "paragraph", "content": [{ "type": "text", "text": "@mona in plain text" }] }] }""").RootElement;

        RDocMentions.UserIds(plain).Should().BeEmpty();
        RDocMentions.Apply(plain, new Dictionary<Guid, string> { [Mona] = "mona" }).GetRawText().Should().Be(plain.GetRawText());
    }
}
