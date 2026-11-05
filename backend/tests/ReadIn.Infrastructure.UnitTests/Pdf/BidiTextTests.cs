using System.Text.Json;
using ReadIn.Infrastructure.Pdf;

namespace ReadIn.Infrastructure.UnitTests.Pdf;

/// <summary>
/// The PDF's BiDi rules are the web reader's (SPEC §14.2; web/src/app/shared/directives/auto-dir.directive.spec.ts):
/// the same expectations on the same shared fixtures (No-bug rule 1).
/// </summary>
public sealed class BidiTextTests
{
    private static IReadOnlyList<string> Isolated(string text, string baseDir) =>
        [.. BidiText.Segment(text, baseDir).Where(s => s.Isolate).Select(s => s.Text)];

    public static TheoryData<string, string, string> Samples()
    {
        var data = new TheoryData<string, string, string>();
        foreach (var (id, text, dir) in ArticlePdfFixtures.BidiSamples()) data.Add(id, text, dir);
        return data;
    }

    [Theory]
    [MemberData(nameof(Samples))]
    public void A_block_takes_the_direction_of_its_first_strong_character(string id, string text, string expectedDir)
    {
        BidiText.DetectDir(text).Should().Be(expectedDir, id);
        using var block = JsonDocument.Parse(JsonSerializer.Serialize(new
        {
            id = "p", type = "paragraph", content = new[] { new { type = "text", text } },
        }));
        BidiText.ResolveBlockDir(block.RootElement, fallback: "ltr").Should().Be(expectedDir, id);
    }

    [Theory]
    [MemberData(nameof(Samples))]
    public void Segmenting_never_changes_the_text(string id, string text, string expectedDir) =>
        string.Concat(BidiText.Segment(text, expectedDir).Select(s => s.Text)).Should().Be(text, id);

    [Fact]
    public void Seeded_sentences_isolate_exactly_the_runs_the_web_and_mobile_isolate()
    {
        using var file = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "fixtures", "bidi", "fixtures.json")));
        var pinned = file.RootElement.GetProperty("fixtures").EnumerateArray().Where(f => f.TryGetProperty("isolated", out _)).ToList();

        pinned.Should().NotBeEmpty();
        foreach (var fixture in pinned)
        {
            Isolated(fixture.GetProperty("text").GetString()!, fixture.GetProperty("expectedDir").GetString()!)
                .Should().Equal(fixture.GetProperty("isolated").EnumerateArray().Select(r => r.GetString()), fixture.GetProperty("id").GetString());
        }
    }

    [Fact]
    public void English_terms_are_isolated_and_trailing_arabic_punctuation_stays_outside() =>
        Isolated("يعني إيه Dependency Injection؟", "rtl").Should().Equal("Dependency Injection");

    [Fact]
    public void A_leading_dot_stays_with_dotnet_and_a_trailing_period_stays_outside() =>
        Isolated("اتعمل upgrade لـ .NET 10 و Angular 21.", "rtl").Should().Equal("upgrade", ".NET 10", "Angular 21");

    [Fact]
    public void Balanced_brackets_and_generics_stay_inside_code_like_runs() =>
        Isolated("استخدم services.AddScoped<IFoo, Foo>() هنا.", "rtl").Should().Equal("services.AddScoped<IFoo, Foo>()");

    [Fact]
    public void Unbalanced_closing_brackets_are_dropped() =>
        Isolated("الـ lifetime (Scoped) مهم جداً.", "rtl").Should().Equal("lifetime (Scoped)");

    [Fact]
    public void A_bracket_the_run_opens_but_never_closes_goes_back_to_the_arabic_text()
    {
        Isolated("أثناء الـ render (", "rtl").Should().Equal("render");
        Isolated("الـ render (Math.random()، Date.now())، وبس", "rtl").Should().Equal("render", "Math.random()", "Date.now()");
    }

    [Fact]
    public void Mentions_and_urls_are_isolated()
    {
        Isolated("شكراً @youssef_dev على الشرح!", "rtl").Should().Equal("@youssef_dev");
        Isolated("شوف https://learn.microsoft.com/dotnet/ للتفاصيل.", "rtl").Should().Equal("https://learn.microsoft.com/dotnet/");
    }

    [Fact]
    public void Arabic_runs_inside_english_text_are_isolated() =>
        Isolated("Use DI (الحقن) everywhere.", "ltr").Should().Equal("الحقن");

    [Fact]
    public void Inline_code_doesnt_decide_a_blocks_direction()
    {
        using var block = JsonDocument.Parse("""
            { "id": "p", "type": "paragraph", "content": [
              { "type": "text", "text": "AddScoped", "marks": [{ "type": "code" }] },
              { "type": "text", "text": " بيعمل service لكل request." } ] }
            """);
        BidiText.ResolveBlockDir(block.RootElement, "ltr").Should().Be("rtl");
    }

    [Fact]
    public void An_explicit_direction_wins_and_no_strong_character_falls_back_to_the_article()
    {
        using var explicitDir = JsonDocument.Parse("""{ "id": "p", "type": "paragraph", "dir": "ltr", "content": [{ "type": "text", "text": "عربي" }] }""");
        using var neutral = JsonDocument.Parse("""{ "id": "p", "type": "paragraph", "content": [{ "type": "text", "text": "12 — 30 ☕" }] }""");

        BidiText.ResolveBlockDir(explicitDir.RootElement, "rtl").Should().Be("ltr");
        BidiText.ResolveBlockDir(neutral.RootElement, "rtl").Should().Be("rtl");
        BidiText.ResolveBlockDir(neutral.RootElement, "ltr").Should().Be("ltr");
    }
}
