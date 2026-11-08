using ReadIn.Application.Features.ContentFilter;
using ReadIn.Domain.Moderation;

namespace ReadIn.Application.UnitTests.ContentFilter;

/// <summary>
/// The content filter's matcher against contract F37 decision 8. The word list is neutral placeholders (never real slurs):
/// كلمة (word, the contract's own example) with its Franco spelling kalma, سلحفاة (turtle) and قلم (pen) stand for blocked
/// Arabic words, قط (cat) for a 2-letter one, sel7efa for a Franco spelling,
/// batata for a Franco term with leet-like letters, wombat and "spoon fork" for blocked English, pen and kumquat for flagged ones.
/// </summary>
public sealed class ContentFilterMatcherTests
{
    private static readonly ContentFilterMatcher Matcher = new([
        Term("كلمة", "ar", ContentFilterLevel.Block),
        Term("kalma", "ar", ContentFilterLevel.Block),
        Term("سلحفاة", "ar", ContentFilterLevel.Block),
        Term("قلم", "ar", ContentFilterLevel.Block),
        Term("قط", "ar", ContentFilterLevel.Block),
        Term("sel7efa", "ar", ContentFilterLevel.Block),
        Term("batata", "ar", ContentFilterLevel.Block),
        Term("بطيخ", "ar", ContentFilterLevel.Flag),
        Term("wombat", "en", ContentFilterLevel.Block),
        Term("spoon fork", "en", ContentFilterLevel.Block),
        Term("pen", "en", ContentFilterLevel.Flag),
        Term("kumquat", "en", ContentFilterLevel.Flag),
    ]);

    private static FilterTerm Term(string text, string language, ContentFilterLevel level) =>
        new(ContentFilterText.NormalizeTerm(text), language, level);

    private static void Blocked(string text, string term)
    {
        var check = Matcher.Check(text);
        check.IsBlocked.Should().BeTrue($"\"{text}\" holds {term}");
        check.Matches.Should().Contain(ContentFilterText.NormalizeTerm(term));
    }

    private static void Clean(string text) =>
        Matcher.Check(text).Should().Be(ContentCheck.Clean, $"\"{text}\" holds no listed word");

    [Theory]
    [InlineData("والكلمة", "كلمة")]
    [InlineData("فبالكلمة", "كلمة")]
    [InlineData("للكلمة", "كلمة")]
    [InlineData("كلمتك", "كلمة")]
    [InlineData("بكلمتهم", "كلمة")]
    [InlineData("وكلمتها", "كلمة")]
    [InlineData("ك.ل.م.ة", "كلمة")]
    [InlineData("ك ل م ة", "كلمة")]
    [InlineData("كلمممة", "كلمة")]
    [InlineData("كل​مة", "كلمة")]
    [InlineData("k.a.l.m.a", "kalma")]
    [InlineData("k-a-l-m-a", "kalma")]
    [InlineData("k a l m a", "kalma")]
    [InlineData("kaaalmaaa", "kalma")]
    public void The_contract_examples_match(string text, string term) =>
        Blocked($"قال {text} أمس", term);

    [Theory]
    [InlineData("السلحفاة")]
    [InlineData("والسلحفاة")]
    [InlineData("فبالسلحفاة")]
    [InlineData("للسلحفاة")]
    [InlineData("وللسلحفاة")]
    [InlineData("فللسلحفاة")]
    [InlineData("وبالسلحفاة")]
    [InlineData("كالسلحفاة")]
    [InlineData("فالسلحفاة")]
    [InlineData("بسلحفاة")]
    public void Stacked_arabic_prefixes_are_stripped(string word) =>
        Blocked($"هذه {word} هنا", "سلحفاة");

    [Theory]
    [InlineData("سلحفاتك")]
    [InlineData("سلحفاتكم")]
    [InlineData("سلحفاتكما")]
    [InlineData("سلحفاتكن")]
    [InlineData("سلحفاته")]
    [InlineData("سلحفاتها")]
    [InlineData("سلحفاتهم")]
    [InlineData("سلحفاتهما")]
    [InlineData("سلحفاتهن")]
    [InlineData("سلحفاتي")]
    [InlineData("سلحفاتنا")]
    public void Pronoun_suffixes_are_stripped_and_a_ta_marbuta_written_ta_still_matches(string word) =>
        Blocked(word, "سلحفاة");

    [Theory]
    [InlineData("بسلحفاتهم")]
    [InlineData("وسلحفاتها")]
    [InlineData("فبسلحفاتك")]
    [InlineData("ولسلحفاتنا")]
    public void A_prefix_and_a_suffix_together_are_stripped(string word) =>
        Blocked(word, "سلحفاة");

    [Theory]
    [InlineData("بالقلم")]
    [InlineData("قلمك")]
    [InlineData("وقلمها")]
    public void A_three_letter_term_matches_after_stripping(string word) =>
        Blocked(word, "قلم");

    [Theory]
    [InlineData("سُلَحْفَاةٌ")]
    [InlineData("سلـــحفاة")]
    [InlineData("سلحفاه")]
    public void Diacritics_tatweel_and_the_ta_marbuta_follow_section_22(string word) =>
        Blocked(word, "سلحفاة");

    [Theory]
    [InlineData("س.ل.ح.ف.ا.ة")]
    [InlineData("س-ل-ح-ف-ا-ة")]
    [InlineData("سل_حف*اة")]
    [InlineData("سل|حف~اة")]
    [InlineData("سل​حف‌اة")]
    [InlineData("سل‍حفا⁠ة")]
    public void Separators_and_zero_width_characters_inside_a_word_are_removed(string word) =>
        Blocked($"قال {word} اليوم", "سلحفاة");

    [Theory]
    [InlineData("س ل ح ف ا ة", "سلحفاة")]
    [InlineData("س، ل، ح، ف، ا، ة", "سلحفاة")]
    [InlineData("w o m b a t", "wombat")]
    [InlineData("w, o, m, b, a, t", "wombat")]
    public void A_run_of_single_letters_is_joined(string run, string term) =>
        Blocked($"هو {run} فعلا", term);

    [Fact]
    public void A_joined_run_of_single_letters_is_also_stripped() =>
        Blocked("و ا ل س ل ح ف ا ة", "سلحفاة");

    [Theory]
    [InlineData("w-o-m-b-a-t")]
    [InlineData("w.o.m.b.a.t")]
    [InlineData("w_o_m_b_a_t")]
    [InlineData("w*o|m~bat")]
    [InlineData("wom​bat")]
    public void Latin_words_lose_their_inner_separators(string word) =>
        Blocked($"a {word} here", "wombat");

    [Theory]
    [InlineData("سلحففففاة", "سلحفاة")]
    [InlineData("سسسلحفاااة", "سلحفاة")]
    [InlineData("قلمممم", "قلم")]
    [InlineData("wommmbaaaat", "wombat")]
    [InlineData("WOMBAAAAT", "wombat")]
    public void Repeated_letters_collapse(string word, string term) =>
        Blocked(word, term);

    [Fact]
    public void Collapsed_forms_are_also_stripped() =>
        Blocked("بسلحففففاتهم", "سلحفاة");

    [Fact]
    public void Franco_digits_are_kept_as_written()
    {
        Blocked("ya sel7efa", "sel7efa");
        Blocked("SEL7EFA!", "sel7efa");
        Blocked("sel-7-efa", "sel7efa");
        // 7 is a letter in Franco: the leet form (seltefa) and the letters without it are other words.
        Clean("seltefa selefa");
    }

    [Theory]
    [InlineData("w0mb4t")]
    [InlineData("w0mbat")]
    [InlineData("womb@t")]
    [InlineData("W0MB47")]
    public void English_leetspeak_matches_english_terms(string word) =>
        Blocked(word, "wombat");

    [Fact]
    public void Leetspeak_with_one_as_i_or_l_and_dollar_and_five_as_s()
    {
        var matcher = new ContentFilterMatcher([Term("lisp", "en", ContentFilterLevel.Block), Term("bliss", "en", ContentFilterLevel.Block)]);

        matcher.Check("1isp").IsBlocked.Should().BeTrue("1 is read as l");
        matcher.Check("bl1$5").IsBlocked.Should().BeTrue("1 is read as i, $ and 5 as s");
        matcher.Check("b11ss").IsBlocked.Should().BeFalse("one reading per word: every 1 as i, or every 1 as l");
    }

    [Fact]
    public void Leetspeak_is_never_compared_with_arabic_terms()
    {
        // b4t4t4 reads batata in leet, but batata is on the Arabic (Franco) list.
        Clean("b4t4t4 b@t@t@");
        Blocked("batata", "batata");
    }

    [Theory]
    [InlineData("قطار")]
    [InlineData("مقطع")]
    [InlineData("قطن")]
    [InlineData("مقلمة")]
    [InlineData("قلما")]
    [InlineData("أقلام")]
    [InlineData("استقلال")]
    public void An_ordinary_arabic_word_holding_a_term_inside_it_is_clean(string word) =>
        Clean($"هذا {word} جميل");

    [Theory]
    [InlineData("فقط")]
    [InlineData("بقط")]
    [InlineData("والقط")]
    [InlineData("قطك")]
    [InlineData("قطها")]
    [InlineData("لقطه")]
    public void A_two_letter_term_matches_only_a_bare_word(string word) =>
        Clean($"لا {word} شيء");

    [Fact]
    public void A_two_letter_term_matches_as_a_bare_word() =>
        Blocked("هذا قط صغير", "قط");

    [Fact]
    public void Stripping_never_leaves_fewer_than_three_letters()
    {
        foreach (var word in new[] { "فقط", "بقط", "والقط", "قطك", "لنا", "بها", "وله" })
            ContentFilterText.StrippedCandidates(ContentFilterText.Normalize(word))
                .Should().OnlyContain(c => ContentFilterText.LetterCount(c) >= ContentFilterText.MinStrippedLength, word);

        ContentFilterText.StrippedCandidates("والقلم").Should().Contain("قلم");
        ContentFilterText.StrippedCandidates("قلم").Should().BeEmpty("a bare word is not its own stripped candidate");
    }

    [Theory]
    [InlineData("happen")]
    [InlineData("open pending penny")]
    [InlineData("wombatology")]
    [InlineData("pencil")]
    [InlineData("spoonful forklift")]
    public void An_ordinary_english_word_holding_a_term_inside_it_is_clean(string text) =>
        Clean(text);

    [Fact]
    public void A_flag_term_flags_and_a_block_term_wins()
    {
        var flag = Matcher.Check("a kumquat and a pen");
        flag.IsFlagged.Should().BeTrue();
        flag.Matches.Should().Equal("kumquat", "pen");

        Matcher.Check("والبطيخ").IsFlagged.Should().BeTrue();

        var both = Matcher.Check("a kumquat and a wombat");
        both.IsBlocked.Should().BeTrue();
        both.Matches.Should().Equal("kumquat", "wombat");
    }

    [Theory]
    [InlineData("a spoon fork")]
    [InlineData("SPOON   FORK")]
    [InlineData("spoon, fork")]
    [InlineData("spoooon fork")]
    public void A_multi_word_term_matches_the_same_words_in_a_row(string text) =>
        Blocked(text, "spoon fork");

    [Fact]
    public void A_multi_word_term_does_not_match_its_words_apart() =>
        Clean("a spoon and a fork");

    [Fact]
    public void A_mention_or_hashtag_of_a_term_still_matches()
    {
        Blocked("hi @wombat", "wombat");
        Blocked("#سلحفاة", "سلحفاة");
    }

    [Fact]
    public void Empty_text_and_an_empty_list_are_clean()
    {
        Matcher.Check(null).Should().Be(ContentCheck.Clean);
        Matcher.Check("   ").Should().Be(ContentCheck.Clean);
        ContentFilterMatcher.Empty.Check("wombat").Should().Be(ContentCheck.Clean);
    }

    [Fact]
    public void A_term_is_normalized_like_the_text()
    {
        ContentFilterText.NormalizeTerm("  Spoon   FORK ").Should().Be("spoon fork");
        ContentFilterText.NormalizeTerm("سُلَحْفَاة").Should().Be("سلحفاه");
        ContentFilterText.NormalizeTerm("w-o-m-b-a-t").Should().Be("wombat");
        ContentFilterText.NormalizeTerm("إلى").Should().Be("الي");
        ContentFilterText.Normalize("رقم ٠١٢٣").Should().Be("رقم 0123");
    }

    [Fact]
    public void Arabic_prefixes_cover_the_stacked_forms_longest_first()
    {
        ContentFilterText.ArabicPrefixes.Should().Contain(["و", "ف", "ب", "ل", "ك", "ال", "وال", "بال", "فال", "كال", "لل", "وبال", "ولل", "فلل", "فبال", "وكال"]);
        ContentFilterText.ArabicPrefixes.Select(p => p.Length).Should().BeInDescendingOrder();
        ContentFilterText.ArabicSuffixes.Should().BeEquivalentTo(["ك", "كم", "كما", "كن", "ه", "ها", "هم", "هما", "هن", "ي", "ني", "نا"]);
    }
}

public sealed class SpamSignalsTests
{
    [Fact]
    public void Three_links_are_a_sign_of_spam() =>
        SpamSignals.Check("see https://a.example https://b.example and www.c.example").Should().Equal(SpamSignals.Links);

    [Fact]
    public void Two_different_links_are_fine() =>
        SpamSignals.Check("see https://a.example and https://b.example").Should().BeEmpty();

    [Fact]
    public void The_same_link_twice_is_a_sign_of_spam() =>
        SpamSignals.Check("https://a.example/x, again https://A.example/x.").Should().Equal(SpamSignals.RepeatedLink);

    [Theory]
    [InlineData("call +20 122 939 1155 now")]
    [InlineData("call (012) 2939-1155")]
    [InlineData("اتصل ٠١٢٢٩٣٩١١٥٥")]
    [InlineData("01229391155")]
    public void A_phone_number_is_a_sign_of_spam(string text) =>
        SpamSignals.Check(text).Should().Equal(SpamSignals.PhoneNumber);

    [Theory]
    [InlineData("in 2026 we read 300 articles")]
    [InlineData("chapter 12-14, pages 100-120")]
    [InlineData("")]
    [InlineData(null)]
    public void Ordinary_numbers_are_fine(string? text) =>
        SpamSignals.Check(text).Should().BeEmpty();
}
