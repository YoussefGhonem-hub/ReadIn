using ReadIn.Domain.Common;
using ReadIn.Domain.Devotions;

namespace ReadIn.Domain.UnitTests.Devotions;

/// <summary>F38: how a du'a's text and title are cleaned, and the entity's own guards.</summary>
public sealed class PersonalDuaTests
{
    private static readonly string LineSeparator = ((char)0x2028).ToString();
    private static readonly string ParagraphSeparator = ((char)0x2029).ToString();
    private static readonly string Delete = ((char)0x7F).ToString();
    private static readonly string NextLine = ((char)0x85).ToString();
    private static readonly string RightToLeftMark = ((char)0x200F).ToString();
    private static readonly string NonBreakingSpace = ((char)0xA0).ToString();

    [Fact]
    public void Text_is_trimmed_at_both_ends_and_keeps_inner_spaces_and_line_breaks()
    {
        PersonalDuaText.Text("  \n اللهم   اغفر لي\n\n\n  وارحمني  \t\n ").Should().Be("اللهم   اغفر لي\n\n\n  وارحمني");
        PersonalDuaText.Text($"{NonBreakingSpace}text{NonBreakingSpace}").Should().Be("text", "every kind of whitespace is trimmed at the ends");
    }

    [Fact]
    public void Windows_and_old_mac_line_breaks_become_one_line_feed()
    {
        PersonalDuaText.Text("one\r\ntwo\rthree\n\r\nfour").Should().Be("one\ntwo\nthree\n\nfour");
    }

    [Fact]
    public void Control_characters_other_than_line_breaks_are_removed()
    {
        PersonalDuaText.Text($"a\a\0b\tc\fd\ve{Delete}f{NextLine}g\bh").Should().Be("abcdefgh");
        PersonalDuaText.Text($"\a  text  {Delete}").Should().Be("text", "removed before trimming");
    }

    [Fact]
    public void Invisible_format_marks_and_unicode_separators_stay_in_the_text()
    {
        PersonalDuaText.Text($"{RightToLeftMark}دعاء{LineSeparator}ثاني{ParagraphSeparator}ثالث")
            .Should().Be($"{RightToLeftMark}دعاء{LineSeparator}ثاني{ParagraphSeparator}ثالث");
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" \n\r\n\t ")]
    [InlineData("\a\0\f")]
    public void Nothing_left_is_an_empty_text_and_a_null_title(string? raw)
    {
        PersonalDuaText.Text(raw).Should().BeEmpty();
        PersonalDuaText.Title(raw).Should().BeNull();
    }

    [Fact]
    public void A_title_is_one_line()
    {
        PersonalDuaText.Title("  دعاء\r\nالسفر\nوالعودة\rمعًا  ").Should().Be("دعاء السفر والعودة معًا");
        PersonalDuaText.Title($"one{LineSeparator}two{ParagraphSeparator}three").Should().Be("one two three");
        PersonalDuaText.Title("a\n\nb").Should().Be("a  b", "each line break becomes a space; inner spaces are not collapsed");
        PersonalDuaText.Title("title\twith\atabs").Should().Be("titlewithtabs");
    }

    [Fact]
    public void Lengths_are_utf16_code_units_after_cleaning()
    {
        var emoji = "🤲"; // two UTF-16 code units
        PersonalDuaText.Text(string.Concat(Enumerable.Repeat(emoji, PersonalDua.MaxTextLength / 2))).Should().HaveLength(PersonalDua.MaxTextLength);
        PersonalDuaText.Text($"   {new string('د', PersonalDua.MaxTextLength)}\n\n").Should().HaveLength(PersonalDua.MaxTextLength);
    }

    [Fact]
    public void A_new_dua_was_updated_when_it_was_created_and_an_edit_replaces_every_field()
    {
        var created = new DateTime(2026, 11, 11, 8, 0, 0, DateTimeKind.Utc);
        var userId = Guid.NewGuid();
        var dua = new PersonalDua(userId, "Title", "Text", 3, created);
        dua.UserId.Should().Be(userId);
        dua.CreatedAt.Should().Be(created);
        dua.UpdatedAt.Should().Be(created);
        dua.Repeat.Should().Be(3);

        var edited = created.AddHours(1);
        dua.Edit(null, "New text", 1, edited);
        dua.Title.Should().BeNull();
        dua.Text.Should().Be("New text");
        dua.Repeat.Should().Be(1);
        dua.CreatedAt.Should().Be(created);
        dua.UpdatedAt.Should().Be(edited);
    }

    [Fact]
    public void The_entity_refuses_text_titles_and_counts_its_rules_never_let_through()
    {
        var now = DateTime.UtcNow;
        var user = Guid.NewGuid();
        FluentActions.Invoking(() => new PersonalDua(user, null, " ", 1, now)).Should().Throw<ArgumentException>();
        FluentActions.Invoking(() => new PersonalDua(user, null, new string('a', PersonalDua.MaxTextLength + 1), 1, now))
            .Should().Throw<ArgumentOutOfRangeException>();
        FluentActions.Invoking(() => new PersonalDua(user, "", "Text", 1, now)).Should().Throw<ArgumentException>();
        FluentActions.Invoking(() => new PersonalDua(user, new string('t', PersonalDua.MaxTitleLength + 1), "Text", 1, now))
            .Should().Throw<ArgumentOutOfRangeException>();
        FluentActions.Invoking(() => new PersonalDua(user, null, "Text", 0, now)).Should().Throw<ArgumentOutOfRangeException>();
        FluentActions.Invoking(() => new PersonalDua(user, null, "Text", PersonalDua.MaxRepeat + 1, now))
            .Should().Throw<ArgumentOutOfRangeException>();
        var dua = new PersonalDua(user, null, "Text", 1, now);
        FluentActions.Invoking(() => dua.Edit(null, "", 1, now)).Should().Throw<ArgumentException>();
    }

    [Fact]
    public void The_errors_have_the_contract_codes()
    {
        PersonalDuaErrors.NotFound.Code.Should().Be("dua.not_found");
        PersonalDuaErrors.NotFound.Type.Should().Be(ErrorType.NotFound);
        PersonalDuaErrors.Limit.Code.Should().Be("dua.limit");
        PersonalDuaErrors.Limit.Type.Should().Be(ErrorType.Conflict, "the contract answers 409");
    }
}
