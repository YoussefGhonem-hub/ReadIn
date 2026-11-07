using ReadIn.Application.Features.Search;

namespace ReadIn.Application.UnitTests.Admin;

/// <summary>
/// F23 searches with no results (contract decision 8): search runs as you type, so a miss waits 30 seconds per searcher and
/// is dropped when that searcher's next search extends it; otherwise it is counted.
/// </summary>
public sealed class SearchMissBufferTests
{
    private static readonly DateOnly Day = new(2026, 11, 7);
    private static readonly DateTime T0 = new(2026, 11, 7, 10, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void A_miss_extended_by_the_next_keystrokes_is_dropped()
    {
        var buffer = new SearchMissBuffer();
        buffer.Observe("u:1", "dock", Day, T0, missed: true);
        buffer.Observe("u:1", "docke", Day, T0.AddSeconds(1), missed: true);
        buffer.Observe("u:1", "dockerz", Day, T0.AddSeconds(2), missed: true);

        buffer.TakeAll().Select(m => m.Query).Should().Equal("dockerz");
    }

    [Fact]
    public void The_same_query_again_counts_once()
    {
        var buffer = new SearchMissBuffer();
        buffer.Observe("u:1", "kubernetes operators", Day, T0, missed: true);
        buffer.Observe("u:1", "kubernetes operators", Day, T0.AddSeconds(3), missed: true); // Enter after typing

        buffer.TakeAll().Should().ContainSingle();
    }

    [Fact]
    public void A_miss_extended_into_a_search_that_finds_something_is_dropped()
    {
        var buffer = new SearchMissBuffer();
        buffer.Observe("u:1", "dock", Day, T0, missed: true);
        buffer.Observe("u:1", "docker", Day, T0.AddSeconds(1), missed: false);

        buffer.TakeAll().Should().BeEmpty();
    }

    [Fact]
    public void Another_query_lets_the_held_miss_be_counted_at_once()
    {
        var buffer = new SearchMissBuffer();
        buffer.Observe("u:1", "rust lifetimes", Day, T0, missed: true);
        buffer.Observe("u:1", "angular", Day, T0.AddSeconds(5), missed: false);

        buffer.TakeDue(T0.AddSeconds(6)).Select(m => m.Query).Should().Equal("rust lifetimes");
        buffer.TakeAll().Should().BeEmpty();
    }

    [Fact]
    public void A_held_miss_is_due_after_30_seconds()
    {
        var buffer = new SearchMissBuffer();
        buffer.Observe("ip:1.2.3.4", "elixir", Day, T0, missed: true);

        buffer.TakeDue(T0.AddSeconds(29)).Should().BeEmpty();
        buffer.TakeDue(T0.AddSeconds(30)).Should().ContainSingle().Which.Should().Be(new SearchMissEntry("elixir", "en", Day, T0));
        buffer.TakeAll().Should().BeEmpty();
    }

    [Fact]
    public void Searchers_are_held_apart()
    {
        var buffer = new SearchMissBuffer();
        buffer.Observe("u:1", "dock", Day, T0, missed: true);
        buffer.Observe("u:2", "docker swarm", Day, T0.AddSeconds(1), missed: true);

        buffer.TakeAll().Select(m => m.Query).Should().BeEquivalentTo("dock", "docker swarm");
    }

    [Theory]
    [InlineData("docker", "en")]
    [InlineData("c# 12", "en")]
    [InlineData("2026", "en")]
    [InlineData("الذكاء الاصطناعي", "ar")]
    [InlineData("rag في الذكاء", "ar")]
    [InlineData("؟؟", "en")] // Arabic punctuation, no Arabic letter
    public void The_language_is_arabic_when_the_query_holds_an_arabic_letter(string query, string language) =>
        SearchMissBuffer.LanguageOf(query).Should().Be(language);
}
