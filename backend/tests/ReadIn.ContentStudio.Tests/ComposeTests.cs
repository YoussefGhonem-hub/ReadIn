using System.Text.Json.Nodes;
using ReadIn.ContentStudio.Authoring;

namespace ReadIn.ContentStudio.Tests;

/// <summary>Authoring drafts → RDoc (content/AUTHORING.md): positional ids, Arabic direction, nested marks, strict errors.</summary>
public sealed class ComposeTests
{
    private const string Draft = """
        :::summary
        `async` doesn't create **threads**.
        :::

        Hook with a [[dependency-injection|Dependency Injection]] term and a [link](https://learn.microsoft.com/dotnet/).

        ## The common misconception

        - First, with **`AddScoped`**
        - Second item that continues
          on the next line

        :::codetabs
        ```csharp label="❌ Wrong" filename="Program.cs"
        var x = 1;
        ```
        ```csharp label="✅ Right" compile=false
        int y = "no";
        ```
        :::

        | Myth | Reality |
        | --- | --- |
        | `a \| b` | fine |

        :::tip Pro tip
        Use `ConfigureAwait(false)` in libraries.
        :::

        :::steps
        ### Find them
        Search for `.Result`.
        ### Fix them
        Await instead.
        :::

        ## Key takeaways

        - one
        """;

    private static JsonArray Blocks(string draft, string language = "en")
    {
        var (document, errors) = RDocMarkdown.Convert(draft, language);
        errors.Should().BeEmpty();
        return document!["blocks"]!.AsArray();
    }

    [Fact]
    public void Blocks_get_positional_ids_and_the_right_types()
    {
        var blocks = Blocks(Draft);

        blocks.Select(b => (b!["id"]!.GetValue<string>(), b["type"]!.GetValue<string>())).Should().Equal(
            ("tldr", "summary"), ("b1", "paragraph"), ("b2", "heading"), ("b3", "bulletList"), ("b4", "codeTabs"),
            ("b5", "table"), ("b6", "callout"), ("b7", "steps"), ("b8", "heading"), ("b9", "bulletList"));
    }

    [Fact]
    public void Inline_marks_terms_links_and_escaped_pipes_are_converted()
    {
        var blocks = Blocks(Draft);

        var hook = blocks[1]!["content"]!.AsArray();
        hook[1]!["type"]!.GetValue<string>().Should().Be("term");
        hook[1]!["termId"]!.GetValue<string>().Should().Be("dependency-injection");
        hook[3]!["marks"]![0]!["href"]!.GetValue<string>().Should().Be("https://learn.microsoft.com/dotnet/");

        var boldCode = blocks[3]!["items"]![0]![1]!;
        boldCode["text"]!.GetValue<string>().Should().Be("AddScoped");
        boldCode["marks"]!.AsArray().Select(m => m!["type"]!.GetValue<string>()).Should().Equal("bold", "code");

        blocks[3]!["items"]![1]![0]!["text"]!.GetValue<string>().Should().Be("Second item that continues on the next line");
        blocks[5]!["rows"]![0]![0]![0]!["text"]!.GetValue<string>().Should().Be("a | b");
    }

    [Fact]
    public void Code_tabs_keep_labels_files_and_compile_flags()
    {
        var tabs = Blocks(Draft)[4]!["tabs"]!.AsArray();

        tabs[0]!["label"]!.GetValue<string>().Should().Be("❌ Wrong");
        tabs[0]!["filename"]!.GetValue<string>().Should().Be("Program.cs");
        tabs[0]!["code"]!.GetValue<string>().Should().Be("var x = 1;");
        tabs[1]!["compile"]!.GetValue<bool>().Should().BeFalse();
    }

    [Fact]
    public void Arabic_text_blocks_are_rtl_and_code_is_not()
    {
        var blocks = Blocks(Draft, "ar-EG");

        blocks.Where(b => b!["type"]!.GetValue<string>() != "codeTabs")
            .Should().OnlyContain(b => b!["dir"]!.GetValue<string>() == "rtl", "a paragraph starting with an English term must not flip to LTR");
        blocks[4]!.AsObject().ContainsKey("dir").Should().BeFalse();
    }

    [Theory]
    [InlineData("# Title", "H1 is the article title")]
    [InlineData("```csharp\nvar x = 1;", "Unclosed code fence")]
    [InlineData(":::note\ntext\n:::", "Unknown container")]
    [InlineData("A [[term-without-text]] here.", "Glossary terms are written")]
    [InlineData("Some **bold text.", "Unclosed ** emphasis")]
    [InlineData("| a | b |\n| --- | --- |\n| only one |", "This row has 1 cells")]
    public void Malformed_drafts_report_the_line_and_the_problem(string draft, string message)
    {
        var (document, errors) = RDocMarkdown.Convert(draft, "en");

        document.Should().BeNull();
        errors.Should().ContainSingle().Which.Message.Should().Contain(message);
    }

    [Fact]
    public void Formatted_json_has_one_block_per_line()
    {
        var (document, _) = RDocMarkdown.Convert(Draft, "en");

        var json = DraftComposer.Format(document!);

        json.Split('\n').Count(l => l.StartsWith("    {", StringComparison.Ordinal)).Should().Be(10);
        json.Should().Contain("❌ Wrong").And.NotContain("\\u", "Arabic, emoji and generics stay readable in the committed file");
    }
}
