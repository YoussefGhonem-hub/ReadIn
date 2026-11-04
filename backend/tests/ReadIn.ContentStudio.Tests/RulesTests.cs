using System.Text.Json;
using ReadIn.Application.Common.Content;
using ReadIn.ContentStudio.Authoring;
using ReadIn.ContentStudio.Validation;
using ReadIn.Domain.Articles;
using ReadIn.Infrastructure.Content;

namespace ReadIn.ContentStudio.Tests;

/// <summary>Editorial rules (SPEC §19.3): parity, Arabic text lint, trust fields and the cover size.</summary>
public sealed class RulesTests
{
    private const string En = """
        :::summary
        Summary.
        :::

        Hook.

        ```csharp
        var x = 1;
        ```
        """;

    private static JsonElement Doc(string draft, string language) =>
        JsonSerializer.SerializeToElement(RDocMarkdown.Convert(draft, language).Document);

    private static ArticleUnderTest Article(string en, string ar, ArticleMeta? meta = null)
    {
        var docs = new Dictionary<string, JsonElement> { ["en"] = Doc(en, "en"), ["ar-EG"] = Doc(ar, "ar-EG") };
        var processed = docs.ToDictionary(d => d.Key, _ =>
            new ProcessedRDoc(new ArticleContent("{}", "", "", null, 6, 1200), "en", [], [], [], 0));
        return new ArticleUnderTest("content/articles/dotnet/csharp/sample", meta ?? new ArticleMeta { Slug = "sample", Field = "dotnet", Topic = "csharp" },
            Plan: null, docs, processed);
    }

    private static List<string> Messages(ArticleUnderTest article, string check) =>
        [.. ArticleRules.Check(article, new HashSet<string>()).Where(f => f.Check == check).Select(f => f.Message)];

    [Fact]
    public void Code_must_be_identical_in_both_languages()
    {
        var ar = En.Replace("Summary.", "ملخص.").Replace("Hook.", "مقدمة.").Replace("var x = 1;", "var x = 2;");

        Messages(Article(En, ar), "parity").Should().ContainSingle().Which.Should().Contain("code must be identical");
    }

    [Fact]
    public void A_different_block_structure_is_reported()
    {
        var ar = ":::summary\nملخص.\n:::\n\nمقدمة.";

        Messages(Article(En, ar), "parity").Should().ContainSingle().Which.Should().Contain("Block count differs");
    }

    [Theory]
    [InlineData("مقدمة فيها سؤال?", "Latin punctuation")]
    [InlineData("قريت ١٢ مقال.", "Arabic-Indic digits")]
    [InlineData("مقال جميل 🙂.", "Emoji")]
    [InlineData("استخدم <div> هنا.", "Raw HTML")]
    public void Arabic_text_follows_the_writing_rules(string hook, string message)
    {
        var ar = En.Replace("Summary.", "ملخص.").Replace("Hook.", hook);

        Messages(Article(En, ar), "text").Should().Contain(m => m.Contains(message));
    }

    [Fact]
    public void Inline_code_and_question_marks_inside_it_are_not_prose()
    {
        var ar = En.Replace("Summary.", "ملخص.").Replace("Hook.", "استخدم `x?.Length ?? 0` هنا، وخلاص.");

        Messages(Article(En, ar), "text").Should().BeEmpty();
    }

    [Fact]
    public void Seeded_articles_never_claim_a_human_review()
    {
        var meta = new ArticleMeta
        {
            Slug = "sample", Field = "dotnet", Topic = "csharp", Status = "published", ReviewStatus = "approved",
            Reviewer = "someone@readin.test", IsAiAssisted = false,
        };

        var trust = Messages(Article(En, En.Replace("Summary.", "ملخص.").Replace("Hook.", "مقدمة."), meta), "trust");

        trust.Should().Contain(m => m.Contains("leave reviewStatus out"))
            .And.Contain(m => m.Contains("never faked"))
            .And.Contain(m => m.Contains("isAiAssisted"));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("pending")] // what the older files carry; the importer ignores it
    public void ReviewStatus_can_be_left_out_since_there_is_no_review(string? reviewStatus)
    {
        var meta = new ArticleMeta
        {
            Slug = "sample", Field = "dotnet", Topic = "csharp", Status = "published", ReviewStatus = reviewStatus,
            LastReviewedAt = new DateTime(2026, 11, 3, 0, 0, 0, DateTimeKind.Utc),
        };

        var trust = Messages(Article(En, En.Replace("Summary.", "ملخص.").Replace("Hook.", "مقدمة."), meta), "trust");

        trust.Should().BeEmpty();
    }

    [Fact]
    public void Webp_size_is_read_from_the_header()
    {
        var cover = Path.Combine(AppContext.BaseDirectory, "fixtures", "cover.webp");

        ArticleRules.WebpSize(File.ReadAllBytes(cover)).Should().Be((1200, 630));
        ArticleRules.WebpSize([1, 2, 3]).Should().BeNull();
    }
}
