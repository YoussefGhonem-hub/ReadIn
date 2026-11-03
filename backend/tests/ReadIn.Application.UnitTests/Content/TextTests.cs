using System.Text.Json;
using ReadIn.Application.Common.Content;
using ReadIn.Application.Common.Models;

namespace ReadIn.Application.UnitTests.Content;

public sealed class ArabicNormalizerTests
{
    public static TheoryData<string, string> SharedFixtures()
    {
        // shared/bidi/fixtures.json is the cross-platform source of tricky mixed-text samples (SPEC §14.2.7).
        using var doc = JsonDocument.Parse(File.ReadAllText(RepoPaths.Shared("bidi", "fixtures.json")));
        var data = new TheoryData<string, string>();
        foreach (var fixture in doc.RootElement.GetProperty("fixtures").EnumerateArray())
        {
            if (fixture.TryGetProperty("normalized", out var normalized))
                data.Add(fixture.GetProperty("text").GetString()!, normalized.GetString()!);
        }
        return data;
    }

    [Theory]
    [MemberData(nameof(SharedFixtures))]
    public void Matches_the_shared_fixtures(string text, string expected) =>
        ArabicNormalizer.Normalize(text).Should().Be(expected);

    [Theory]
    [InlineData("ٱلْحَمْدُ", "الحمد")]
    [InlineData("  ASP.NET   Core  ", "asp.net core")]
    [InlineData("مستشفى", "مستشفي")]
    [InlineData("", "")]
    public void Normalizes(string text, string expected) => ArabicNormalizer.Normalize(text).Should().Be(expected);
}

public sealed class SlugGeneratorTests
{
    [Theory]
    [InlineData("Dependency Injection in ASP.NET Core", "dependency-injection-in-asp-net-core")]
    [InlineData("What's new in C# 14?", "what-s-new-in-csharp-14")]
    [InlineData("يعني إيه Dependency Injection؟", "dependency-injection")]
    [InlineData("مقال عربي بالكامل", "")]
    public void Builds_ascii_slugs(string title, string expected) => SlugGenerator.FromTitle(title).Should().Be(expected);

    [Fact]
    public void Long_titles_are_cut_at_a_word_boundary()
    {
        var slug = SlugGenerator.FromTitle(string.Join(' ', Enumerable.Repeat("architecture", 12)));

        slug.Length.Should().BeLessThanOrEqualTo(SlugGenerator.MaxLength);
        slug.Should().NotEndWith("-");
    }
}

public sealed class TimeCursorTests
{
    [Fact]
    public void Round_trips()
    {
        var cursor = new TimeCursor(new DateTime(2026, 11, 2, 8, 30, 15, DateTimeKind.Utc), Guid.CreateVersion7());

        TimeCursor.Decode(cursor.Encode()).Should().Be(cursor);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("not-a-cursor")]
    [InlineData("bm90OmE6Y3Vyc29y")]
    public void Invalid_cursors_decode_to_null(string? value) => TimeCursor.Decode(value).Should().BeNull();
}
