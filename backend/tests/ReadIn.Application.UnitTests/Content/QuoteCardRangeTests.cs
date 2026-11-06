using System.Text.Json;
using System.Text.Json.Nodes;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Features.Articles.QuoteCards;

namespace ReadIn.Application.UnitTests.Content;

/// <summary>
/// The quote card's range checks (SPEC F24, contract "Quote card (F24)") against the shared F30 fixtures in
/// <c>shared/rdoc/highlight-fixtures.json</c>: the same offsets, blocks and trimming as a highlight, the card's own codes
/// (<c>quote.*</c>) and its 3–400 limits. The documents go through the real save pipeline first, as the database stores them.
/// </summary>
public sealed class QuoteCardRangeTests
{
    private static readonly JsonObject Fixtures =
        JsonNode.Parse(File.ReadAllText(RepoPaths.Shared("rdoc", "highlight-fixtures.json")))!.AsObject();

    private static readonly Dictionary<string, IReadOnlyList<RDocTextBlock>> Stored = Fixtures["documents"]!.AsObject()
        .ToDictionary(d => d.Key, d => Store(d.Value!));

    private static IReadOnlyList<RDocTextBlock> Store(JsonNode document)
    {
        var processed = new RDocProcessor().Process(JsonDocument.Parse(document.ToJsonString()).RootElement);
        processed.IsSuccess.Should().BeTrue(processed.Error?.Code);
        return RDocBlockText.Blocks(processed.Value.Content.Json);
    }

    public static TheoryData<string> Selections() =>
        [.. Fixtures["selections"]!.AsArray().Where(s => s!["expected"] is not null).Select(s => s!["id"]!.GetValue<string>())];

    public static TheoryData<string> ServerChecks() => [.. Fixtures["serverChecks"]!["cases"]!.AsArray().Select(s => s!["id"]!.GetValue<string>())];

    [Theory]
    [MemberData(nameof(Selections))]
    public void Every_fixture_selection_is_a_quote_of_exactly_its_text(string id)
    {
        var selection = Fixtures["selections"]!.AsArray().Single(s => s!["id"]!.GetValue<string>() == id)!;
        var expected = selection["expected"]!;
        var block = Stored[selection["document"]!.GetValue<string>()].Single(b => b.Id == expected["blockId"]!.GetValue<string>());

        var quote = QuoteCardRange.Quote(block, expected["startOffset"]!.GetValue<int>(), expected["endOffset"]!.GetValue<int>(), expected["text"]!.GetValue<string>());

        quote.Value.Should().Be(expected["text"]!.GetValue<string>());
    }

    [Theory]
    [MemberData(nameof(ServerChecks))]
    public void Server_checks_give_the_trimmed_quote_or_the_same_error_as_a_highlight_under_its_quote_code(string id)
    {
        var check = Fixtures["serverChecks"]!["cases"]!.AsArray().Single(s => s!["id"]!.GetValue<string>() == id)!;
        var (start, end) = (check["startOffset"]!.GetValue<int>(), check["endOffset"]!.GetValue<int>());
        var block = Stored[check["document"]!.GetValue<string>()].SingleOrDefault(b => b.Id == check["blockId"]!.GetValue<string>());
        // No text: the slice of the plain text, which may hold half a surrogate pair (it can't travel as JSON).
        var text = check["text"]?.GetValue<string>() ?? block!.Text![Math.Min(start, block.Text!.Length)..Math.Min(end, block.Text.Length)];

        var quote = QuoteCardRange.Quote(block, start, end, text);

        if (check["error"]?.GetValue<string>() is { } error)
            quote.Error!.Code.Should().Be(error.Replace("highlight.", "quote.", StringComparison.Ordinal));
        else
            quote.Value.Should().Be(check["stored"]!["text"]!.GetValue<string>());
    }

    [Theory]
    [InlineData(3, null)]
    [InlineData(400, null)]
    [InlineData(401, "quote.too_long")]
    [InlineData(1000, "quote.too_long")]
    [InlineData(2, "quote.too_short")]
    public void A_quote_is_3_to_400_code_units_after_trimming(int length, string? error)
    {
        var text = "  " + new string('ق', length) + "\n ";
        var block = new RDocTextBlock("p1", "paragraph", text, [new RDocTextUnit(0, text.Length)]);

        var quote = QuoteCardRange.Quote(block, 0, text.Length, text);

        if (error is null) quote.Value.Should().Be(new string('ق', length), "whitespace at both ends is trimmed");
        else quote.Error!.Code.Should().Be(error);
    }

    [Fact]
    public void A_quote_stays_inside_one_list_item()
    {
        var list = Stored["ar"].Single(b => b.Id == "l1");
        var first = list.Units[0];
        var item = list.Text![first.Start..first.End];

        QuoteCardRange.Quote(list, first.Start, first.End, item).Value.Should().Be(item);
        QuoteCardRange.Quote(list, first.Start, first.End + 2, list.Text![first.Start..(first.End + 2)]).Error!.Code.Should().Be("quote.text_mismatch");
    }

    [Theory]
    [InlineData("light", "square", true)]
    [InlineData("dark", "landscape", true)]
    [InlineData("Dark", "square", false)]
    [InlineData("sepia", "square", false)]
    [InlineData("light", "story", false)]
    public void Theme_and_format_take_only_the_values_the_contract_lists(string theme, string format, bool valid)
    {
        var validator = new RenderQuoteCardQueryValidator();

        var result = validator.Validate(new RenderQuoteCardQuery(Guid.NewGuid(), "ar-EG", "p1", 0, 5, "abcde", theme, format));

        result.IsValid.Should().Be(valid);
        if (!valid) result.Errors.Should().OnlyContain(e => e.ErrorCode == "validation.invalid");
    }

    [Fact]
    public void Every_member_is_required()
    {
        var result = new RenderQuoteCardQueryValidator().Validate(new RenderQuoteCardQuery(Guid.NewGuid(), null, null, null, null, null, null, null));

        result.Errors.Select(e => e.PropertyName).Should().BeEquivalentTo(
            ["Language", "BlockId", "StartOffset", "EndOffset", "Text", "Theme", "Format"]);
    }

    [Theory]
    [InlineData("ar", 0, 5, "article.language_invalid")]
    [InlineData("ar-EG", -1, 5, "validation.invalid")]
    [InlineData("ar-EG", 5, 5, "validation.invalid")]
    public void Offsets_and_language_are_checked_like_a_highlight(string language, int start, int end, string code)
    {
        var result = new RenderQuoteCardQueryValidator().Validate(new RenderQuoteCardQuery(Guid.NewGuid(), language, "p1", start, end, "abcde", "light", "square"));

        result.IsValid.Should().BeFalse();
        result.Errors.Single().ErrorCode.Should().Be(code);
    }

    [Theory]
    [InlineData("ar", "p1", "rtl")] // "لو انت شغال بـ ASP.NET Core، …": a quote from its English term on is still right to left
    [InlineData("ar", "c1", "rtl")] // the callout's title "نصيحة سريعة" first
    [InlineData("ar", "l1", "rtl")]
    [InlineData("ar", "o1", "ltr")] // an English list ("First step: …") in the Arabic version
    [InlineData("en", "e1", "ltr")]
    public void A_stored_block_has_the_direction_the_reader_gives_it(string document, string blockId, string dir) =>
        Stored[document].Single(b => b.Id == blockId).Dir.Should().Be(dir);

    [Fact]
    public void An_explicit_direction_wins_inline_code_is_skipped_and_a_block_without_strong_characters_has_none()
    {
        static RDocTextBlock Only(string block) => RDocBlockText.Blocks($$"""{ "blocks": [{{block}}] }""").Single();

        Only("""{ "id": "p", "type": "paragraph", "dir": "ltr", "content": [{ "type": "text", "text": "عربي" }] }""").Dir.Should().Be("ltr");
        Only("""{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "AddScoped", "marks": [{ "type": "code" }] }, { "type": "text", "text": " بيعمل service." }] }""")
            .Dir.Should().Be("rtl");
        Only("""{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "12 — 30 ☕" }] }""").Dir.Should().BeNull("the article's language decides");
        Only("""{ "id": "k", "type": "code", "lang": "csharp", "code": "var x = 1;" }""").Dir.Should().BeNull("a code block is never a quote");
    }
}
