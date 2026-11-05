using System.Text.Json;
using System.Text.Json.Nodes;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Features.Highlights;
using ReadIn.Domain.Engagement;

namespace ReadIn.Application.UnitTests.Content;

/// <summary>
/// F30 highlight offsets (SPEC F30): the backend's block plain text and range checks against the shared fixtures in
/// <c>shared/rdoc/highlight-fixtures.json</c>, which the web and mobile selection mapping are tested against too. The
/// documents go through the real save pipeline first (sanitize + schema), so the text is what the database stores.
/// </summary>
public sealed class RDocBlockTextTests
{
    private static readonly JsonObject Fixtures =
        JsonNode.Parse(File.ReadAllText(RepoPaths.Shared("rdoc", "highlight-fixtures.json")))!.AsObject();

    private static readonly Dictionary<string, IReadOnlyList<RDocTextBlock>> Stored = Fixtures["documents"]!.AsObject()
        .ToDictionary(d => d.Key, d => Store(d.Value!));

    /// <summary>What the editor would store for the document: sanitized and validated by <see cref="RDocProcessor"/>.</summary>
    private static IReadOnlyList<RDocTextBlock> Store(JsonNode document)
    {
        var processed = new RDocProcessor().Process(JsonDocument.Parse(document.ToJsonString()).RootElement);
        processed.IsSuccess.Should().BeTrue(processed.Error?.Details is { } d ? string.Join("; ", d.Select(e => $"{e.Key}: {string.Join(",", e.Value)}")) : processed.Error?.Code);
        return RDocBlockText.Blocks(processed.Value.Content.Json);
    }

    private static RDocTextBlock Block(string document, string blockId) => Stored[document].Single(b => b.Id == blockId);

    public static TheoryData<string> Documents() => [.. Fixtures["documents"]!.AsObject().Select(d => d.Key)];

    public static TheoryData<string> Selections() =>
        [.. Fixtures["selections"]!.AsArray().Where(s => s!["expected"] is not null).Select(s => s!["id"]!.GetValue<string>())];

    public static TheoryData<string> ServerChecks() => [.. Fixtures["serverChecks"]!["cases"]!.AsArray().Select(s => s!["id"]!.GetValue<string>())];

    [Theory]
    [MemberData(nameof(Documents))]
    public void Every_block_has_the_fixture_plain_text_and_list_items(string document)
    {
        var expected = Fixtures["blocks"]![document]!.AsArray();
        var blocks = Stored[document];

        blocks.Select(b => b.Id).Should().Equal(expected.Select(e => e!["blockId"]!.GetValue<string>()));
        foreach (var entry in expected)
        {
            var block = blocks.Single(b => b.Id == entry!["blockId"]!.GetValue<string>());
            block.IsHighlightable.Should().Be(entry!["highlightable"]!.GetValue<bool>(), block.Id);
            block.Text.Should().Be(entry["plainText"]?.GetValue<string>(), block.Id);
            if (entry["items"] is JsonArray items)
                block.Units.Select(u => (u.Start, u.End)).Should().Equal(
                    items.Select(i => (i!["startOffset"]!.GetValue<int>(), i["endOffset"]!.GetValue<int>())), block.Id);
            else if (block.Text is { } text)
                block.Units.Should().Equal([new RDocTextUnit(0, text.Length)], block.Id);
        }
    }

    [Theory]
    [MemberData(nameof(Selections))]
    public void Every_fixture_selection_is_a_range_the_server_accepts_as_it_is(string id)
    {
        var selection = Fixtures["selections"]!.AsArray().Single(s => s!["id"]!.GetValue<string>() == id)!;
        var expected = selection["expected"]!;
        var block = Block(selection["document"]!.GetValue<string>(), expected["blockId"]!.GetValue<string>());
        var (start, end, text) = (expected["startOffset"]!.GetValue<int>(), expected["endOffset"]!.GetValue<int>(), expected["text"]!.GetValue<string>());

        HighlightRanges.Matches(block, start, end, text).Should().BeTrue();
        HighlightRanges.Trim(block.Text!, start, end).Should().Be((start, end), "clients send ranges already trimmed");
        (end - start).Should().BeInRange(ArticleHighlight.MinLength, ArticleHighlight.MaxLength);
    }

    [Fact]
    public void Selections_without_a_range_are_code_tables_steps_or_too_short()
    {
        foreach (var selection in Fixtures["selections"]!.AsArray().Where(s => s!["expected"] is null))
        {
            var reason = selection!["reason"]!.GetValue<string>();
            reason.Should().BeOneOf("block_not_allowed", "too_short");
            if (reason == "block_not_allowed")
            {
                // The block where the selection starts can't be highlighted.
                var start = selection["anchor"]!["block"]!.GetValue<string>();
                Block(selection["document"]!.GetValue<string>(), start).IsHighlightable.Should().BeFalse(selection["id"]!.GetValue<string>());
            }
        }
    }

    [Theory]
    [MemberData(nameof(ServerChecks))]
    public void Server_checks_give_the_stored_range_or_the_error(string id)
    {
        var check = Fixtures["serverChecks"]!["cases"]!.AsArray().Single(s => s!["id"]!.GetValue<string>() == id)!;
        var (start, end) = (check["startOffset"]!.GetValue<int>(), check["endOffset"]!.GetValue<int>());
        var blocks = Stored[check["document"]!.GetValue<string>()];
        var block = blocks.SingleOrDefault(b => b.Id == check["blockId"]!.GetValue<string>());
        // No text: the slice of the plain text, which may hold half a surrogate pair (it can't travel as JSON).
        var text = check["text"]?.GetValue<string>() ?? block!.Text![Math.Min(start, block.Text!.Length)..Math.Min(end, block.Text.Length)];

        Outcome(block, start, end, text).Should().Be(check["error"]?.GetValue<string>() ?? StoredOutcome(check["stored"]!));
    }

    [Fact]
    public void The_whitespace_set_is_unicode_white_space()
    {
        int[] white = [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20, 0x85, 0xA0, 0x1680, .. Enumerable.Range(0x2000, 11), 0x2028, 0x2029, 0x202F, 0x205F, 0x3000];
        Enumerable.Range(0, 0x10000).Where(c => HighlightRanges.IsWhiteSpace((char)c)).Should().Equal(white);
        HighlightRanges.IsWhiteSpace((char)0x200B).Should().BeFalse("a zero-width space is not white space");
        HighlightRanges.IsWhiteSpace((char)0xFEFF).Should().BeFalse();
    }

    [Fact]
    public void Isolates_never_reach_the_stored_text()
    {
        var withIsolates = new JsonObject
        {
            ["version"] = 1,
            ["language"] = "ar-EG",
            ["blocks"] = new JsonArray(new JsonObject
            {
                ["id"] = "p1",
                ["type"] = "paragraph",
                ["content"] = new JsonArray(new JsonObject { ["type"] = "text", ["text"] = "لو انت شغال بـ " + (char)0x2068 + "ASP.NET Core" + (char)0x2069 + " " + (char)0x202B + "تمام" + (char)0x202C + "." }),
            }),
        };

        Store(withIsolates).Single().Text.Should().Be("لو انت شغال بـ ASP.NET Core تمام.");
    }

    /// <summary>The order of POST /articles/{id}/highlights' checks (contract "Highlights (F30)") on one block.</summary>
    private static string Outcome(RDocTextBlock? block, int start, int end, string text)
    {
        if (block is null) return HighlightErrors.TextMismatch.Code;
        if (!block.IsHighlightable) return HighlightErrors.BlockNotAllowed.Code;
        if (!HighlightRanges.Matches(block, start, end, text)) return HighlightErrors.TextMismatch.Code;
        var (s, e) = HighlightRanges.Trim(block.Text!, start, end);
        if (e - s < ArticleHighlight.MinLength) return HighlightErrors.TooShort.Code;
        if (e - s > ArticleHighlight.MaxLength) return HighlightErrors.TooLong.Code;
        return $"{block.Id}:{s}:{e}:{block.Text![s..e]}";
    }

    private static string StoredOutcome(JsonNode stored) =>
        $"{stored["blockId"]!.GetValue<string>()}:{stored["startOffset"]!.GetValue<int>()}:{stored["endOffset"]!.GetValue<int>()}:{stored["text"]!.GetValue<string>()}";
}
