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
        ["upload.purpose_invalid"] = ("نوع الرفع لازم يكون avatar أو cover أو article-image.", "Purpose must be avatar, cover or article-image."),
        ["upload.empty"] = ("الملف فاضي.", "The file is empty."),
        ["upload.too_large"] = ("الصورة لازم تكون 5 ميجا أو أقل.", "Images must be 5 MB or smaller."),
        ["upload.unsupported_type"] = ("مسموح بصور JPEG وPNG وWebP بس.", "Only JPEG, PNG and WebP images are allowed."),
        ["upload.dimensions_too_large"] = ("أبعاد الصورة لازم تكون 8000 × 8000 بكسل أو أقل.", "Images must be at most 8000 × 8000 pixels."),
        ["upload.invalid_image"] = ("الملف ده مش صورة سليمة.", "The file is not a readable image."),
        ["request.too_large"] = ("الطلب أكبر من المسموح.", "The request is too large."),
        ["route.not_found"] = ("الصفحة مش موجودة.", "Not found."),
        ["rate_limited"] = ("طلبات كتير، استنى شوية وجرب تاني.", "Too many requests. Please try again shortly."),
        ["concurrency.conflict"] = ("حد عدّل البيانات دي، حدّث الصفحة وجرب تاني.", "Someone else changed this. Refresh and try again."),
        ["server.error"] = ("حصلت مشكلة عندنا، جرب تاني.", "Something went wrong on our side."),
    };

    public static string? Title(string code, string uiLanguage) =>
        Titles.TryGetValue(code, out var t) ? (uiLanguage == "en" ? t.En : t.Ar) : null;
}
