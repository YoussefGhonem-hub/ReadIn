namespace ReadIn.Api.Errors;

/// <summary>
/// Human-readable titles for ProblemDetails in ar/en (SPEC §17.1). Clients should translate <c>code</c> with their
/// own strings and use these only as a fallback.
/// </summary>
public static class ErrorMessages
{
    private static readonly Dictionary<string, (string Ar, string En)> Titles = new(StringComparer.Ordinal)
    {
        ["validation.failed"] = ("البيانات المدخلة فيها أخطاء.", "Validation failed."),
        ["request.invalid"] = ("الطلب غير صالح.", "The request is invalid."),
        ["auth.unauthorized"] = ("سجّل دخولك الأول.", "Sign in to continue."),
        ["auth.forbidden"] = ("معندكش صلاحية تعمل ده.", "You don't have permission to do this."),
        ["auth.email_required"] = ("لازم يكون فيه إيميل للحساب.", "An email address is required."),
        ["user.suspended"] = ("الحساب ده موقوف.", "This account is suspended."),
        ["user.not_synced"] = ("الحساب لسه متسجلش على ReadIn.", "Your account hasn't been set up on ReadIn yet."),
        ["user.not_found"] = ("المستخدم مش موجود.", "User not found."),
        ["user.username_taken"] = ("اسم المستخدم ده محجوز.", "This username is already taken."),
        ["user.interests.min_three"] = ("اختار 3 اهتمامات على الأقل.", "Choose at least 3 interests."),
        ["user.interests.unknown"] = ("فيه مجالات أو مواضيع مش موجودة.", "Some fields or topics don't exist."),
        ["field.not_found"] = ("المجال مش موجود.", "Field not found."),
        ["topic.not_in_field"] = ("الموضوع مش تابع للمجال ده.", "The topic doesn't belong to this field."),
        ["article.not_found"] = ("المقال مش موجود.", "Article not found."),
        ["article.not_owner"] = ("التعديل للكاتب بس.", "Only the author can change this article."),
        ["article.content_invalid"] = ("محتوى المقال مش مظبوط.", "The article content is not valid."),
        ["article.sources_required"] = ("لازم تضيف مصدر واحد على الأقل.", "Add at least one source."),
        ["article.review_required"] = ("المقال لازم يتراجع قبل النشر.", "This article must be reviewed before publishing."),
        // Media (ADR 0010, ADR 0011)
        ["media.purpose_invalid"] = ("نوع الرفع لازم يكون image أو avatar أو cover.", "Purpose must be image, avatar or cover."),
        ["media.file_required"] = ("اختار ملف ترفعه.", "Choose a file to upload."),
        ["media.too_large"] = ("الملف أكبر من المسموح (الصور 10 ميجا، والـ PDF 20 ميجا).", "The file is too large (images 10 MB, PDFs 20 MB)."),
        ["media.unsupported_type"] = ("نوع الملف ده مش مدعوم.", "This file type is not supported."),
        ["media.dimensions_too_large"] = ("أبعاد الصورة لازم تكون 8000 × 8000 بكسل أو أقل.", "Images must be at most 8000 × 8000 pixels."),
        ["media.image_corrupted"] = ("الملف ده مش صورة سليمة.", "The file is not a readable image."),
        ["media.pdf_encrypted"] = ("الملف ده عليه باسورد، ارفعه من غير باسورد.", "This file is password-protected. Upload it without a password."),
        ["media.pdf_corrupted"] = ("ملف الـ PDF ده بايظ ومش بيتقري.", "The PDF file is damaged and could not be read."),
        ["media.pdf_too_many_pages"] = ("الـ PDF لازم يكون 100 صفحة أو أقل.", "A PDF can have at most 100 pages."),
        ["media.quota_daily"] = ("وصلت لحد الرفع النهارده، جرّب بكرة.", "You reached today's upload limit. Try again tomorrow."),
        ["media.quota_storage"] = ("المساحة بتاعتك خلصت، امسح شوية ملفات الأول.", "You used all your storage space. Delete some uploads first."),
        ["media.not_found"] = ("الملف مش موجود.", "File not found."),
        ["media.in_use"] = ("شيل الملف من البوست الأول قبل ما تمسحه.", "Remove this file from its post before deleting it."),
        ["media.download_not_allowed"] = ("الكاتب مش سامح بتحميل الملف ده.", "The author did not allow downloading this file."),
        ["attachments.mixed_kinds"] = ("البوست يا صور يا ملف PDF واحد، مش الاتنين.", "A post can have images or one PDF, not both."),
        ["attachments.too_many_images"] = ("أقصى حاجة 10 صور في البوست.", "A post can have at most 10 images."),
        ["attachments.single_document"] = ("البوست ينفع فيه ملف PDF واحد بس.", "A post can have only one PDF."),
        ["attachments.alt_text_required"] = ("كل صورة محتاجة وصف (alt text).", "Every image needs alt text."),
        ["attachments.alt_text_too_long"] = ("الوصف أقصى حاجة 5000 حرف.", "Alt text can be at most 5000 characters."),
        ["attachments.caption_too_long"] = ("التعليق أقصى حاجة 5000 حرف.", "A caption can be at most 5000 characters."),
        ["attachments.title_required"] = ("الملف محتاج عنوان.", "The document needs a title."),
        ["attachments.title_too_long"] = ("عنوان الملف أقصى حاجة 5000 حرف.", "The document title can be at most 5000 characters."),
        ["attachments.asset_not_found"] = ("في ملف من الملفات مش موجود.", "One of the files was not found."),
        ["attachments.asset_not_ready"] = ("استنى لحد ما كل الملفات تخلص تجهيز.", "Wait until every file has finished processing."),
        ["attachments.duplicate_asset"] = ("نفس الملف اتضاف مرتين.", "The same file was added twice."),
        ["request.too_large"] = ("الطلب أكبر من المسموح.", "The request is too large."),
        ["route.not_found"] = ("الصفحة مش موجودة.", "Not found."),
        ["rate_limited"] = ("طلبات كتير، استنى شوية وجرب تاني.", "Too many requests. Please try again shortly."),
        ["concurrency.conflict"] = ("حد عدّل البيانات دي، حدّث الصفحة وجرب تاني.", "Someone else changed this. Refresh and try again."),
        ["server.error"] = ("حصلت مشكلة عندنا، جرب تاني.", "Something went wrong on our side."),
    };

    public static string? Title(string code, string uiLanguage) =>
        Titles.TryGetValue(code, out var t) ? (uiLanguage == "en" ? t.En : t.Ar) : null;
}
