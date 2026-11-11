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

    /// <summary>The seven codes that had no server title before the leftovers step (PROGRESS 6.6), in Modern Standard Arabic.</summary>
    [Theory]
    [InlineData("article.translation_exists", "هذه النسخة اللغوية موجودة بالفعل.", "This language version already exists.")]
    [InlineData("article.translation_not_found", "هذه النسخة اللغوية غير موجودة.", "This language version does not exist.")]
    [InlineData("reading.conflict", "حُفظ تحديث آخر للقراءة في الوقت نفسه. حاول مرة أخرى.", "Another reading update was saved at the same time. Try again.")]
    [InlineData("user.username_invalid", "يجب أن يتكوّن اسم المستخدم من 3 إلى 30 حرفًا: a–z أو 0–9 أو _.", "Username must be 3–30 characters: a–z, 0–9 or _.")]
    [InlineData("user.language_invalid", "هذه اللغة غير مدعومة.", "This language isn't supported.")]
    [InlineData("user.timezone_invalid", "المنطقة الزمنية غير معروفة.", "Unknown time zone.")]
    [InlineData("user.reminder_time_invalid", "وقت التذكير غير صالح، استخدم الصيغة HH:mm.", "The reminder time isn't valid. Use HH:mm.")]
    public void Codes_that_had_no_title_have_one_in_arabic_and_english(string code, string arabic, string english)
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

    /// <summary>The admin console's codes (SPEC F23), in Modern Standard Arabic.</summary>
    [Theory]
    [InlineData("announcement.limit", "أُرسل إعلان اليوم بالفعل. يمكن إرسال إعلان واحد في اليوم.", "An announcement was already sent today. You can send one a day.")]
    [InlineData("announcement.no_recipients", "لا يوجد مستلمون لهذا الإعلان.", "This announcement has no recipients.")]
    [InlineData("announcement.link_invalid", "يجب أن يشير الرابط إلى مقال منشور أو مسار منشور.", "The link must point to a published article or path.")]
    [InlineData("field.slug_taken", "يوجد مجال آخر بهذا المعرّف.", "Another field uses this slug.")]
    [InlineData("topic.slug_taken", "يوجد موضوع آخر في هذا المجال بهذا المعرّف.", "Another topic in this field uses this slug.")]
    [InlineData("field.icon_invalid", "اختر أيقونة من القائمة.", "Choose an icon from the list.")]
    [InlineData("field.color_invalid", "اختر لونًا من القائمة.", "Choose a color from the list.")]
    [InlineData("admin.order_invalid", "يجب أن تضم القائمة كل العناصر مرة واحدة.", "The list must hold every item exactly once.")]
    [InlineData("tag.name_taken", "يوجد وسم آخر بهذا الاسم. إن كانا الوسم نفسه فادمجهما.", "Another tag already has this name. If they're the same, merge them.")]
    [InlineData("tag.merge_self", "لا يمكن دمج الوسم في نفسه.", "A tag can't be merged into itself.")]
    [InlineData("path.featured_invalid", "اختر 20 مسارًا على الأكثر، موجودة ومن دون تكرار.", "Choose up to 20 different existing paths.")]
    public void Admin_console_codes_have_titles_in_arabic_and_english(string code, string arabic, string english)
    {
        ErrorMessages.Title(code, "ar").Should().Be(arabic);
        ErrorMessages.Title(code, "en").Should().Be(english);
    }

    /// <summary>Help & support (SPEC F35), in Modern Standard Arabic.</summary>
    [Theory]
    [InlineData("support.limit", "وصلت إلى حد التذاكر: 5 تذاكر جديدة في اليوم و10 تذاكر مفتوحة على الأكثر.", "You've reached the ticket limit: 5 new tickets a day and 10 open at once.")]
    [InlineData("support.ticket_not_found", "التذكرة غير موجودة.", "Ticket not found.")]
    [InlineData("support.attachment_not_found", "المرفق غير موجود.", "Attachment not found.")]
    [InlineData("support.ticket_closed", "هذه التذكرة مغلقة. أعد فتحها أولًا.", "This ticket is closed. Reopen it first.")]
    [InlineData("support.reopen_expired", "مضى أكثر من 30 يومًا على إغلاق التذكرة. أرسل تذكرة جديدة.", "This ticket was closed more than 30 days ago. Send a new one.")]
    [InlineData("support.attachment_invalid", "يجب أن تكون الصورة بصيغة JPEG أو PNG أو WebP، وألا يزيد حجمها على 5 م.ب.", "Screenshots must be JPEG, PNG or WebP, up to 5 MB each.")]
    [InlineData("support.too_many_attachments", "يمكن إرفاق 3 صور على الأكثر.", "You can attach up to 3 images.")]
    [InlineData("support.category_invalid", "اختر تصنيفًا من القائمة.", "Choose a category from the list.")]
    public void Support_codes_have_titles_in_arabic_and_english(string code, string arabic, string english)
    {
        ErrorMessages.Title(code, "ar").Should().Be(arabic);
        ErrorMessages.Title(code, "en").Should().Be(english);
    }

    /// <summary>The store requirements' codes (SPEC F22, F36, F37), in Modern Standard Arabic.</summary>
    [Theory]
    [InlineData("block.self", "لا يمكنك حظر نفسك.", "You can't block yourself.")]
    [InlineData("block.limit", "وصلت إلى الحد الأقصى للحسابات المحظورة (1000 حساب).", "You've reached the limit of 1,000 blocked accounts.")]
    [InlineData("block.blocked", "هذا الحساب محظور لديك. ألغِ الحظر أولًا.", "You blocked this account. Unblock it first.")]
    [InlineData("auth.terms_required", "يجب الموافقة على شروط الاستخدام وقواعد المجتمع لإنشاء حساب.", "You must agree to the Terms of Use and Community Guidelines to create an account.")]
    [InlineData("content.objectionable", "هذا النص يخالف قواعد المجتمع. عدّله وحاول مرة أخرى.", "This text breaks our Community Guidelines. Edit it and try again.")]
    [InlineData("content.too_many", "وصلت إلى الحد المسموح به: 5 مقالات في اليوم و60 تعليقًا في الساعة.", "You've reached the limit: 5 articles a day and 60 comments an hour.")]
    [InlineData("content_filter.term_invalid", "أدخل كلمة صالحة من حرفين على الأقل.", "Enter a valid term of at least 2 characters.")]
    [InlineData("repost.not_found", "إعادة النشر هذه غير موجودة.", "This repost no longer exists.")]
    public void Store_requirement_codes_have_titles_in_arabic_and_english(string code, string arabic, string english)
    {
        ErrorMessages.Title(code, "ar").Should().Be(arabic);
        ErrorMessages.Title(code, "en").Should().Be(english);
    }

    /// <summary>Private devotions (SPEC F38), in Modern Standard Arabic.</summary>
    [Theory]
    [InlineData("dua.not_found", "هذا الدعاء غير موجود.", "Du'a not found.")]
    [InlineData("dua.limit", "وصلت إلى الحد الأقصى للأدعية (200 دعاء).", "You can have at most 200 du'as.")]
    public void Devotion_codes_have_titles_in_arabic_and_english(string code, string arabic, string english)
    {
        ErrorMessages.Title(code, "ar").Should().Be(arabic);
        ErrorMessages.Title(code, "en").Should().Be(english);
    }

    [Fact]
    public void An_unknown_code_has_no_title() => ErrorMessages.Title("nope.unknown", "en").Should().BeNull();
}
