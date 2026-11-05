using ReadIn.Application.Features.Tags;

namespace ReadIn.Application.UnitTests.Content;

/// <summary>The tag-name rules (SPEC F32), as docs/api/contract-v1.md states them for the clients.</summary>
public sealed class TagNamesTests
{
    [Theory]
    [InlineData("  AI  ", "AI")]
    [InlineData("#AI", "AI")]
    [InlineData("##ai", "ai")]
    [InlineData("# Machine   Learning", "Machine Learning")]
    [InlineData("Machine\tLearning\n", "Machine Learning")]
    [InlineData("C#", "C#")]
    [InlineData("‏AI‎", "AI")]                     // RLM / LRM
    [InlineData("⁧تعلم الآلة⁩", "تعلم الآلة")]     // bidi isolates
    [InlineData("Web‍3", "Web3")]                         // zero-width joiner
    [InlineData("بايثون ٣", "بايثون 3")]                      // Arabic-Indic digits
    [InlineData("Python ۳", "Python 3")]                       // Extended Arabic-Indic digits
    [InlineData("   ", "")]
    [InlineData(null, "")]
    public void Clean_trims_drops_the_hash_and_invisible_characters_and_collapses_spaces(string? raw, string expected) =>
        TagNames.Clean(raw).Should().Be(expected);

    [Theory]
    [InlineData("C#")]
    [InlineData(".NET")]
    [InlineData("C++")]
    [InlineData("ASP.NET Core")]
    [InlineData("pg_stat_statements")]
    [InlineData("Chain-of-Thought")]
    [InlineData("الذكاء الاصطناعي")]
    [InlineData("تَعَلُّم")]          // marks are allowed
    [InlineData("42")]
    [InlineData("ab")]
    [InlineData("abcdefghijklmnopqrstuvwxyz1234")] // 30
    public void Valid_new_names(string name) => TagNames.IsValidNew(name).Should().BeTrue();

    [Theory]
    [InlineData("a")]                                  // too short
    [InlineData("abcdefghijklmnopqrstuvwxyz12345")]    // 31
    [InlineData("CI/CD")]
    [InlineData("Span<T>")]
    [InlineData("@defer")]
    [InlineData("R²")]
    [InlineData("AI 🤖")]
    [InlineData("++")]                                 // no letter or digit
    [InlineData("-_.")]
    [InlineData("ــ")]                                 // tatweel only
    public void Invalid_new_names(string name) => TagNames.IsValidNew(name).Should().BeFalse();

    [Theory]
    [InlineData("AI", "ai")]
    [InlineData("Machine Learning", "machine learning")]
    [InlineData("البرمجة", "البرمجه")]
    [InlineData("أساسيات", "اساسيات")]
    [InlineData("إدارة", "اداره")]
    [InlineData("مستوى", "مستوي")]
    [InlineData("تَعَلُّم", "تعلم")]
    [InlineData("تـــعلم", "تعلم")]
    public void Normalize_ignores_case_and_arabic_letter_forms(string name, string expected) =>
        TagNames.Normalize(name).Should().Be(expected);

    [Fact]
    public void Distinct_keeps_the_first_spelling_of_each_tag()
    {
        TagNames.Distinct(["AI", " ai", "#AI", "البرمجة", "البرمجه", "", "  ", "ML"])
            .Should().Equal("AI", "البرمجة", "ML");
    }

    [Theory]
    [InlineData("C#", "csharp")]
    [InlineData("F#", "fsharp")]
    [InlineData(".NET", "dotnet")]
    [InlineData("C++", "cplusplus")]
    [InlineData("N+1", "nplus1")]
    [InlineData("ASP.NET Core", "asp-net-core")]
    [InlineData("Node.js", "node-js")]
    [InlineData("pg_stat_statements", "pg-stat-statements")]
    [InlineData("Machine Learning", "machine-learning")]
    [InlineData("الذكاء الاصطناعي", "الذكاء-الاصطناعي")]
    [InlineData("تَعَلُّم الآلة", "تعلم-الآلة")]
    [InlineData("CI/CD", "ci-cd")]
    [InlineData("Span<T>", "span-t")]
    [InlineData("@defer", "defer")]
    public void Slugs_are_url_safe(string name, string expected) => TagNames.SlugBase(name).Should().Be(expected);

    [Fact]
    public void A_name_without_slug_characters_gets_a_fallback_slug()
    {
        TagNames.SlugText("--").Should().BeEmpty();
        TagNames.SlugBase("--").Should().Be("tag");
    }

    [Fact]
    public void A_taken_slug_gets_a_number()
    {
        TagNames.UniqueSlug("csharp", new HashSet<string>()).Should().Be("csharp");
        TagNames.UniqueSlug("csharp", new HashSet<string> { "csharp", "csharp-2" }).Should().Be("csharp-3");
    }
}
