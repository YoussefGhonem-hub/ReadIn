using ReadIn.Application.Features.WriterCategories;

namespace ReadIn.Application.UnitTests.Content;

/// <summary>The writer-category name rules (SPEC F31), as docs/api/contract-v1.md ("Writer categories") states them.</summary>
public sealed class WriterCategoryNamesTests
{
    [Theory]
    [InlineData("  Clean Code  ", "Clean Code")]
    [InlineData("#1 Tips", "#1 Tips")]                    // unlike tags, a leading # stays
    [InlineData("Clean\t\tCode\n", "Clean Code")]
    [InlineData("‏نصايح‎ برمجة", "نصايح برمجة")]          // RLM / LRM
    [InlineData("⁧Angular⁩", "Angular")]                  // bidi isolates
    [InlineData("Bell\aName", "BellName")]                // control characters
    [InlineData("دروس ٣", "دروس 3")]                      // Arabic-Indic digits
    [InlineData("   ", "")]
    [InlineData(null, "")]
    public void Clean_drops_invisible_and_control_characters_and_collapses_spaces(string? raw, string expected) =>
        WriterCategoryNames.Clean(raw).Should().Be(expected);

    [Fact]
    public void A_raw_name_far_over_the_limit_is_not_looked_at() =>
        WriterCategoryNames.Clean(new string('a', WriterCategoryNames.MaxRawLength + 1)).Should().BeEmpty();

    [Theory]
    [InlineData("a")]
    [InlineData("7")]
    [InlineData("C#")]
    [InlineData("نصايح البرمجة 🚀")]                       // symbols and emoji are allowed
    [InlineData("Interview prep: part 2!")]
    [InlineData("abcdefghijklmnopqrstuvwxyz0123456789abcd")] // 40
    public void Valid_names(string name) => WriterCategoryNames.IsValid(name).Should().BeTrue();

    [Theory]
    [InlineData("")]
    [InlineData("!!!")]
    [InlineData("🚀🚀")]
    [InlineData("ـــ")]                                     // tatweel isn't a letter here
    [InlineData("abcdefghijklmnopqrstuvwxyz0123456789abcde")] // 41
    public void Invalid_names(string name) => WriterCategoryNames.IsValid(name).Should().BeFalse();

    [Theory]
    [InlineData("CLEAN code", "clean code")]
    [InlineData("البرمجة", "البرمجه")]
    [InlineData("إدارة", "اداره")]
    public void Names_that_differ_only_in_case_or_letter_forms_are_the_same(string a, string b) =>
        WriterCategoryNames.Normalize(a).Should().Be(WriterCategoryNames.Normalize(b));

    [Fact]
    public void Different_names_stay_different() =>
        WriterCategoryNames.Normalize("Clean Code").Should().NotBe(WriterCategoryNames.Normalize("Clean Architecture"));

    [Theory]
    [InlineData("Clean Code", "clean-code")]
    [InlineData("C#", "csharp")]
    [InlineData("نصايح البرمجة", "نصايح-البرمجة")]
    [InlineData("_Drafts_", "drafts")]
    [InlineData("🚀", "category")]
    public void Slugs_follow_the_tag_rule_and_never_start_with_an_underscore(string name, string slug)
    {
        WriterCategoryNames.SlugBase(name).Should().Be(slug);
        WriterCategoryNames.SlugBase(name).Should().NotStartWith("_");
    }

    [Theory]
    [InlineData("ar", 1, "قسم 1")]
    [InlineData("en", 3, "Category 3")]
    [InlineData(null, 2, "قسم 2")]
    public void Placeholders_follow_the_writer_ui_language(string? language, int number, string expected)
    {
        var placeholder = WriterCategoryNames.Placeholder(language, number);
        placeholder.Should().Be(expected);
        WriterCategoryNames.IsPlaceholder(placeholder).Should().BeTrue();
        WriterCategoryNames.IsValid(placeholder).Should().BeTrue();
    }

    [Theory]
    [InlineData("Category")]
    [InlineData("Category 1 bad")]
    [InlineData("قسم السياسة")]
    public void Other_names_are_not_placeholders(string name) => WriterCategoryNames.IsPlaceholder(name).Should().BeFalse();
}
