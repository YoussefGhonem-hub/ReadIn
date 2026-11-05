using ReadIn.Api.Errors;

namespace ReadIn.Api.IntegrationTests;

/// <summary>ProblemDetails titles (SPEC §17.1), the clients' fallback for a code they don't translate (no server needed).</summary>
public sealed class ErrorMessagesTests
{
    [Theory]
    [InlineData("article.no_content", "المقال فاضي، اكتب حاجة الأول.", "The article is empty. Write something first.")]
    [InlineData("article.invalid_transition", "مينفعش تعمل كده والمقال في حالته دي.", "You can't do that while the article is in this state.")]
    [InlineData("article.slug_taken", "الرابط ده مستخدم لمقال تاني.", "That link is already used by another article.")]
    [InlineData("article.too_many_tags", "أقصى حاجة 5 تاجات للمقال.", "An article can have at most 5 tags.")]
    [InlineData("article.language_invalid", "لغة المقال دي مش مدعومة.", "That article language isn't supported.")]
    [InlineData("article.content_language_mismatch", "لغة المحتوى مش زي لغة المقال.", "The content's language doesn't match the article's language.")]
    public void Article_codes_have_titles_in_arabic_and_english(string code, string arabic, string english)
    {
        ErrorMessages.Title(code, "ar").Should().Be(arabic);
        ErrorMessages.Title(code, "en").Should().Be(english);
    }

    [Theory]
    [InlineData("concurrency.conflict")]
    [InlineData("topic.not_in_field")]
    [InlineData("topic.not_found")]
    [InlineData("user.interests.unknown")]
    [InlineData("user.interests.min_three")]
    [InlineData("article.not_owner")]
    [InlineData("article.status_invalid")]
    [InlineData("report.status_invalid")]
    [InlineData("request.too_large")]
    [InlineData("request.unsupported_media_type")]
    [InlineData("request.invalid")]
    [InlineData("route.not_found")]
    [InlineData("tag.not_found")]
    [InlineData("tag.invalid")]
    [InlineData("tag.limit")]
    [InlineData("tag.hidden")]
    [InlineData("search.query_invalid")]
    [InlineData("search.type_invalid")]
    [InlineData("search.filter_invalid")]
    [InlineData("mute.self")]
    [InlineData("mute.system_account")]
    [InlineData("mute.limit")]
    [InlineData("mute.own_article")]
    [InlineData("category.not_found")]
    [InlineData("category.not_owner")]
    [InlineData("category.limit")]
    [InlineData("category.name_taken")]
    [InlineData("category.name_invalid")]
    [InlineData("article.pdf_hidden")]
    [InlineData("article.pdf_busy")]
    [InlineData("article.pdf_failed")]
    [InlineData("article.pdf_limit")]
    [InlineData("verification.not_verified")]
    [InlineData("verification.system_account")]
    public void Codes_the_clients_translate_have_titles_in_both_languages(string code)
    {
        ErrorMessages.Title(code, "ar").Should().NotBeNullOrWhiteSpace();
        ErrorMessages.Title(code, "en").Should().NotBeNullOrWhiteSpace().And.NotBe(ErrorMessages.Title(code, "ar"));
    }

    [Fact]
    public void An_unknown_code_has_no_title() => ErrorMessages.Title("nope.unknown", "en").Should().BeNull();
}
