using ReadIn.Application.Common.Models;
using ReadIn.Application.Features.Search;

namespace ReadIn.Application.UnitTests.Search;

/// <summary>The search query (contract-v1 "Search"): cleaning, §22 normalization, words, and nothing as query syntax.</summary>
public sealed class SearchTermsTests
{
    private static SearchTerms Parse(string q)
    {
        var result = SearchTerms.Parse(q);
        result.IsSuccess.Should().BeTrue(q);
        return result.Value;
    }

    [Theory]
    [InlineData("مَكْتَبَةٌ", "مكتبه")]                  // diacritics, ة → ه
    [InlineData("أحمد إبراهيم آمال", "احمد ابراهيم امال")] // أ إ آ → ا
    [InlineData("مستشفى", "مستشفي")]                    // ى → ي
    [InlineData("مكتبــة", "مكتبه")]                     // tatweel
    [InlineData("  Docker   Compose ", "docker compose")] // case, spaces
    [InlineData("#AI", "ai")]                            // leading # (tag rule 1)
    [InlineData("@Mona_Ali", "mona_ali")]                // leading @
    [InlineData("بايثون ٣", "بايثون 3")]                   // Arabic-Indic digits
    [InlineData("‏Docker‎", "docker")]                   // RLM / LRM
    public void The_query_is_cleaned_and_normalized_like_search_text(string q, string phrase) =>
        Parse(q).Phrase.Should().Be(phrase);

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("#")]
    [InlineData("@")]
    [InlineData("!!! ???")]
    [InlineData("ـــ")]   // tatweel only
    [InlineData("ً ٌ")]   // diacritics only
    [InlineData(null)]
    public void A_query_without_a_letter_or_digit_is_invalid(string? q) =>
        SearchTerms.Parse(q).Error!.Code.Should().Be("search.query_invalid");

    [Fact]
    public void A_query_is_1_to_100_characters_after_cleaning()
    {
        SearchTerms.Parse(new string('a', 100)).IsSuccess.Should().BeTrue();
        SearchTerms.Parse(new string('a', 101)).Error!.Code.Should().Be("search.query_invalid");
        SearchTerms.Parse("#@" + new string('a', 100) + "   ").IsSuccess.Should().BeTrue("# @ and spaces are cleaned away first");
        SearchTerms.Parse("a").IsSuccess.Should().BeTrue();
        SearchTerms.Parse(new string(' ', 5000) + "a").Error!.Code.Should().Be("search.query_invalid", "a huge raw query isn't even cleaned");
    }

    [Fact]
    public void Words_are_the_parts_with_a_letter_or_digit_without_wrapping_punctuation_and_repeats()
    {
        Parse("\"Docker\", (compose) - docker 2024. ؟").Words.Should().Equal("docker", "compose", "2024");
        Parse("C# .NET C++").Words.Should().Equal("c#", ".net", "c++");
        Parse("a b c d e f g h i j").Words.Should().HaveCount(SearchLimits.MaxWords).And.EndWith("h");
    }

    [Fact]
    public void Every_word_is_a_quoted_prefix_term_and_arabic_words_also_match_after_al()
    {
        Parse("docker ذكاء الذكاء").FullTextCondition()
            .Should().Be("\"docker*\" AND (\"ذكاء*\" OR \"الذكاء*\") AND \"الذكاء*\"");
    }

    [Theory]
    [InlineData("docker\" OR \"a", "\"docker*\" AND \"or*\" AND \"a*\"")]
    [InlineData("NEAR(a,b) AND", "\"near(a,b*\" AND \"and*\"")]
    [InlineData("do\"ck*er", "\"docker*\"")]
    [InlineData("a* -b", "\"a*\" AND \"-b*\"")]
    public void Nothing_a_user_types_becomes_full_text_syntax(string q, string condition) =>
        Parse(q).FullTextCondition().Should().Be(condition);

    [Theory]
    [InlineData("100%", @"%100\%%")]
    [InlineData("a_b", @"%a\_b%")]
    [InlineData("[x]y", @"%\[x]y%")]
    [InlineData(@"c:\temp", @"%c:\\temp%")]
    public void Like_patterns_escape_the_wildcards(string text, string pattern) =>
        SearchTerms.ContainsPattern(text).Should().Be(pattern);

    [Fact]
    public void Word_start_patterns_follow_a_separator_and_also_al()
    {
        SearchTerms.WordStartPatterns("ذكاء").Should().Be(("% ذكاء%", "% الذكاء%"));
        SearchTerms.WordStartPatterns("c_d", '-').Should().Be((@"%-c\_d%", @"%-الc\_d%"));
        SearchTerms.WordStartPatterns("x", '_').Plain.Should().Be(@"%\_x%");
    }

    [Theory]
    [InlineData("تقييم الموديلات", "موديلات", true)]   // after ال
    [InlineData("machine learning", "learn", true)]
    [InlineData("machine learning", "earn", false)]     // not inside a word
    [InlineData("asp.net-core", "core", false)]         // "-" isn't a separator by default
    public void Word_starts_are_checked_in_memory_like_in_sql(string text, string q, bool expected) =>
        Parse(q).AllWordsStartWordsIn(text).Should().Be(expected);

    [Theory]
    [InlineData("internet basics", "net", false)]          // not inside a word
    [InlineData("networks for teams", "net", true)]
    [InlineData("asp.net core", "net core", true)]          // a word starts after any non-letter
    [InlineData("intro (docker) today", "docker", true)]
    [InlineData("docker compose", "docker swarm", false)]   // every word
    [InlineData("مقدمه عن الذكاء", "ذكاء", true)]           // after ال
    [InlineData("تعلم بالذكاء الاصطناعي", "ذكاء", true)]    // behind the prefixes the Arabic word breaker takes off
    [InlineData("والذكاء", "ذكاء", true)]
    [InlineData("للمبتدئين", "مبتدئين", true)]
    [InlineData("فالكتاب", "الكتاب", true)]
    [InlineData("كتعلم", "تعلم", true)]
    [InlineData("استعلم", "تعلم", false)]                   // not a prefix
    [InlineData("بdocker", "docker", false)]                // Arabic prefixes only before Arabic words
    public void Title_hits_on_the_full_text_engine_are_at_word_starts(string text, string q, bool expected) =>
        Parse(q).AllWordsAtWordStartsIn(text).Should().Be(expected);

    [Fact]
    public void The_handle_is_the_one_word_that_can_begin_a_username()
    {
        Parse("@Mona_99").Handle.Should().Be("mona_99");
        Parse("mo").Handle.Should().Be("mo");
        Parse("mona ali").Handle.Should().BeNull();
        Parse("منى").Handle.Should().BeNull();
        Parse("c#").Handle.Should().BeNull();
    }

    [Fact]
    public void The_slug_is_the_tag_slug_of_the_query() => Parse("C#").Slug.Should().Be("csharp");
}

/// <summary>The article ranking formula of contract-v1 ("Search").</summary>
public sealed class SearchRankingTests
{
    private static readonly DateTime Now = new(2026, 11, 5, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void Score_is_place_times_rank_times_quality_times_freshness()
    {
        SearchRanking.Score(SearchMatch.Title, 1, 0.5, Now, Now).Should().BeApproximately(1.0 * 1.0 * 1.0 * 1.0, 1e-9);
        SearchRanking.Score(SearchMatch.Text, 0, 0, Now, Now).Should().BeApproximately(0.6 * 0.5 * 0.5, 1e-9);
        SearchRanking.Score(SearchMatch.Attachment, 1, 1, Now.AddDays(-365), Now).Should().BeApproximately(0.4 * 1.0 * 1.5 * 0.5, 1e-9);
        SearchRanking.Score(SearchMatch.Title, 1, 0.5, Now.AddDays(-730), Now).Should().BeApproximately(1.0 / 3, 1e-9);
    }

    [Fact]
    public void A_title_beats_the_text_beats_the_pdf_when_all_else_is_equal()
    {
        var title = SearchRanking.Score(SearchMatch.Title, 0.8, 0.4, Now.AddDays(-3), Now);
        var text = SearchRanking.Score(SearchMatch.Text, 0.8, 0.4, Now.AddDays(-3), Now);
        var pdf = SearchRanking.Score(SearchMatch.Attachment, 0.8, 0.4, Now.AddDays(-3), Now);
        title.Should().BeGreaterThan(text);
        text.Should().BeGreaterThan(pdf);
    }

    [Fact]
    public void Quality_and_freshness_move_an_article_up()
    {
        SearchRanking.Score(SearchMatch.Text, 1, 0.9, Now, Now).Should().BeGreaterThan(SearchRanking.Score(SearchMatch.Text, 1, 0.1, Now, Now));
        SearchRanking.Score(SearchMatch.Text, 1, 0.5, Now.AddDays(-1), Now)
            .Should().BeGreaterThan(SearchRanking.Score(SearchMatch.Text, 1, 0.5, Now.AddDays(-100), Now));
    }

    [Fact]
    public void Out_of_range_inputs_are_clamped() =>
        SearchRanking.Score(SearchMatch.Title, 5, 9, Now.AddDays(1), Now).Should().BeApproximately(1.0 * 1.0 * 1.5 * 1.0, 1e-9);
}

/// <summary>Offset paging over a ranked list (at most 200 results).</summary>
public sealed class SearchPagingTests
{
    [Fact]
    public void The_offset_cursor_round_trips_and_garbage_is_the_first_page()
    {
        OffsetCursor.Decode(new OffsetCursor(40).Encode()).Should().Be(40);
        OffsetCursor.Decode(null).Should().Be(0);
        OffsetCursor.Decode("not a cursor").Should().Be(0);
        OffsetCursor.Decode(new TimeCursor(DateTime.UtcNow, Guid.NewGuid()).Encode()).Should().Be(0);
    }

    [Fact]
    public void Pages_walk_the_list_and_the_last_has_no_cursor()
    {
        var ranked = Enumerable.Range(1, 5).ToList();
        var (first, next) = SearchPaging.Page(ranked, null, 2);
        first.Should().Equal(1, 2);
        var (second, last) = SearchPaging.Page(ranked, next, 2);
        second.Should().Equal(3, 4);
        var (third, none) = SearchPaging.Page(ranked, last, 2);
        third.Should().Equal(5);
        none.Should().BeNull();
        SearchPaging.Page(ranked, null, 0).Page.Should().HaveCount(1, "limit is at least 1");
        SearchPaging.Page(Enumerable.Range(1, 80).ToList(), null, 500).Page.Should().HaveCount(SearchLimits.MaxLimit);
    }

    [Fact]
    public void Sql_windows_stop_at_200_results()
    {
        SearchPaging.Window(null, 20).Should().Be((0, 21, 20));
        SearchPaging.Window(new OffsetCursor(180).Encode(), 20).Should().Be((180, 20, 20));
        SearchPaging.Window(new OffsetCursor(190).Encode(), 20).Should().Be((190, 10, 20));
        SearchPaging.Window(new OffsetCursor(5000).Encode(), 20).Should().Be((200, 0, 20));

        var (page, next) = SearchPaging.Cut(Enumerable.Range(0, 21).ToList(), 0, 20);
        page.Should().HaveCount(20);
        OffsetCursor.Decode(next).Should().Be(20);
        SearchPaging.Cut(Enumerable.Range(0, 20).ToList(), 180, 20).Next.Should().BeNull("200 results at most");
        SearchPaging.Cut(Enumerable.Range(0, 7).ToList(), 0, 20).Next.Should().BeNull();
    }
}
