// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ReadIn';

  @override
  String get tagline => 'مقال كل يوم يفرق معاك';

  @override
  String get retry => 'جرّب تاني';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'احفظ';

  @override
  String get done => 'تمام';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get skip => 'تخطي';

  @override
  String get close => 'إغلاق';

  @override
  String get loading => 'بنحمّل…';

  @override
  String get comingSoonTitle => 'قريب جداً';

  @override
  String get comingSoonBody =>
      'بنشتغل على الميزة دي دلوقتي، وهتنزل على التطبيق والويب في نفس الوقت.';

  @override
  String get errorTitle => 'حصلت مشكلة';

  @override
  String get emptyTitle => 'مفيش حاجة هنا لسه';

  @override
  String get navHome => 'النهارده';

  @override
  String get navExplore => 'استكشف';

  @override
  String get navWrite => 'اكتب';

  @override
  String get navSaved => 'المحفوظات';

  @override
  String get navProfile => 'حسابي';

  @override
  String get notifications => 'الإشعارات';

  @override
  String greetingMorning(String name) {
    return 'صباح الخير يا $name 👋';
  }

  @override
  String greetingEvening(String name) {
    return 'مساء الخير يا $name 👋';
  }

  @override
  String get greetingGuest => 'أهلاً بيك في ReadIn 👋';

  @override
  String get greetingSubtitle => 'جاهز لجرعة معرفة صغيرة؟';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يوم',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: 'ابدأ الـ streak',
    );
    return '$_temp0';
  }

  @override
  String streakSemantics(int count) {
    return 'الـ streak بتاعك: $count يوم';
  }

  @override
  String get todayArticle => 'مقال النهارده';

  @override
  String get todayArticleCta => 'اقرا دلوقتي';

  @override
  String get feedForYou => 'ليك';

  @override
  String get filterAll => 'الكل';

  @override
  String get feedEmptyTitle => 'مفيش مقالات هنا لسه';

  @override
  String get feedEmptyBody => 'جرّب مجال تاني أو ارجع بعدين.';

  @override
  String get feedNewArticles => 'مقالات جديدة ↑';

  @override
  String get endOfFeed => 'خلّصت كل الجديد ✨';

  @override
  String readingTime(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة قراءة',
      many: '$minutes دقيقة قراءة',
      few: '$minutes دقايق قراءة',
      two: 'دقيقتين قراءة',
      one: 'دقيقة قراءة',
    );
    return '$_temp0';
  }

  @override
  String byAuthor(String name) {
    return 'بقلم $name';
  }

  @override
  String get aiAssisted => 'بمساعدة AI';

  @override
  String get verifiedWriter => 'كاتب موثّق';

  @override
  String get tldr => 'الخلاصة';

  @override
  String get sources => 'المصادر';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get fontSizeS => 'صغير';

  @override
  String get fontSizeM => 'متوسط';

  @override
  String get fontSizeL => 'كبير';

  @override
  String get fontSizeXl => 'كبير جداً';

  @override
  String get langToggleArEg => 'مصري+EN';

  @override
  String get langToggleEn => 'EN';

  @override
  String get articleLangArEg => 'مصري + مصطلحات English';

  @override
  String get articleLangEn => 'English بس';

  @override
  String get copyCode => 'انسخ الكود';

  @override
  String get copied => 'اتنسخ';

  @override
  String get share => 'مشاركة';

  @override
  String get glossary => 'قاموس المصطلحات';

  @override
  String glossaryComingSoon(String term) {
    return 'التعريف الكامل لـ «$term» جاي قريب في القاموس.';
  }

  @override
  String get readingProgress => 'تقدّم القراءة';

  @override
  String get openLink => 'افتح اللينك';

  @override
  String embedOpen(String provider) {
    return 'افتح على $provider';
  }

  @override
  String get imageUnavailable => 'الصورة مش متاحة';

  @override
  String get onboardingWelcomeBody =>
      'مقالات قصيرة بالعربي والإنجليزي — واحدة بنختارهالك كل يوم في المجال اللي بتحبه.';

  @override
  String get browseAsGuest => 'تصفح كزائر';

  @override
  String stepOf(int current, int total) {
    return 'خطوة $current من $total';
  }

  @override
  String get interestsTitle => 'إيه المجالات اللي بتحبها؟';

  @override
  String get interestsSubtitle => 'اختار 3 على الأقل عشان نظبطلك مقال كل يوم.';

  @override
  String interestsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اخترت $count',
      many: 'اخترت $count',
      few: 'اخترت $count',
      two: 'اخترت اتنين',
      one: 'اخترت واحد',
      zero: 'لسه مختارتش حاجة',
    );
    return '$_temp0';
  }

  @override
  String get preferencesTitle => 'تفضيلاتك';

  @override
  String get preferencesSubtitle => 'تقدر تغيّرها في أي وقت من الإعدادات.';

  @override
  String get articleLanguageLabel => 'لغة المقالات';

  @override
  String get reminderTimeLabel => 'معاد التذكير اليومي';

  @override
  String get notificationsLabel => 'إشعار مقال النهارده';

  @override
  String get notificationsHint => 'هنطلب الإذن لما تفعّلها.';

  @override
  String get notificationsBlocked =>
      'إشعارات ReadIn مقفولة من إعدادات الموبايل.';

  @override
  String notificationsUnread(int count) {
    return 'الإشعارات، $count جديدة';
  }

  @override
  String get finishOnboarding => 'ابدأ القراءة';

  @override
  String get signIn => 'سجل دخول';

  @override
  String get signUp => 'اعمل حساب جديد';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get password => 'كلمة السر';

  @override
  String get displayName => 'الاسم';

  @override
  String get forgotPassword => 'نسيت كلمة السر؟';

  @override
  String get noAccount => 'معندكش حساب؟';

  @override
  String get signInTitle => 'أهلاً بيك تاني';

  @override
  String get signInPromptTitle => 'سجّل دخول عشان تكمّل';

  @override
  String get signInPromptBody =>
      'اعمل حساب مجاني عشان تحفظ المقالات وتتابع الكتّاب وتحافظ على الـ streak.';

  @override
  String get fieldRequired => 'مطلوب';

  @override
  String get showPassword => 'اظهر كلمة السر';

  @override
  String get hidePassword => 'اخفي كلمة السر';

  @override
  String get settings => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'الثيم';

  @override
  String get themeSystem => 'حسب الجهاز';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get uiLanguage => 'لغة التطبيق';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get reading => 'القراءة';

  @override
  String get account => 'الحساب';

  @override
  String get guestMode => 'انت بتتصفح كضيف';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get profileGuestTitle => 'حسابك على ReadIn';

  @override
  String get profileGuestBody =>
      'سجّل دخول عشان تبني الـ streak بتاعك وتشارك اللي تعرفه.';

  @override
  String get editProfile => 'تعديل الحساب';

  @override
  String get profileSyncFailed => 'معرفناش نحمّل حسابك.';

  @override
  String get profileTabArticles => 'المقالات';

  @override
  String get profileTabSaved => 'المحفوظات';

  @override
  String get profileTabPaths => 'المسارات';

  @override
  String get profileTabAbout => 'عن الحساب';

  @override
  String get profileStatArticles => 'مقالات';

  @override
  String get profileStatFollowers => 'متابعين';

  @override
  String get profileStatFollowing => 'بيتابع';

  @override
  String get profileStatReads => 'قراءات';

  @override
  String profileStatSemantics(String label, String value) {
    return '$label: $value';
  }

  @override
  String get profileOpenHint => 'بيفتح الحساب';

  @override
  String profileOpenLink(String name) {
    return 'افتح $name';
  }

  @override
  String get profileGithub => 'GitHub';

  @override
  String get profileLinkedin => 'LinkedIn';

  @override
  String get profileWebsite => 'الموقع';

  @override
  String get profileLinks => 'اللينكات';

  @override
  String get profileExpertise => 'مجالات الخبرة';

  @override
  String get profileAboutBio => 'نبذة';

  @override
  String get profileAboutEmpty => 'مفيش تفاصيل لسه.';

  @override
  String get profileAboutEmptyOwn =>
      'ضيف نبذة ولينكاتك والمجالات اللي بتكتب فيها عشان القرّاء يعرفوك.';

  @override
  String profileJoined(String date) {
    return 'انضم في $date';
  }

  @override
  String get profileArticlesEmptyTitle => 'مفيش مقالات لسه';

  @override
  String get profileArticlesEmptyBody => 'المقالات اللي هينشرها هتظهر هنا.';

  @override
  String get profileArticlesEmptyOwnTitle => 'لسه منشرتش مقالات';

  @override
  String get profileArticlesEmptyOwnBody =>
      'شارك اللي تعرفه: مقالاتك المنشورة هتظهر هنا.';

  @override
  String get profileWriteFirst => 'اكتب مقال';

  @override
  String get profilePathsTitle => 'المسارات جاية قريب';

  @override
  String get profilePathsBody =>
      'سلاسل مقالات متنقية تتعلم بيها موضوع خطوة بخطوة. بنجهزها دلوقتي.';

  @override
  String get profileNotFoundTitle => 'الحساب ده مش متاح';

  @override
  String get profileNotFoundBody => 'ممكن يكون اتمسح، أو اللينك غلط.';

  @override
  String get profileSaved => 'اتحفظت التعديلات';

  @override
  String get profilePrivacy => 'الخصوصية';

  @override
  String get profilePublicReadingStats =>
      'اعرض إحصائيات القراءة في حسابي العام';

  @override
  String get profilePublicReadingStatsOn =>
      'أي حد يقدر يشوف الـ streak بتاعك وإجمالي قرايتك ونشاطك.';

  @override
  String get profilePublicReadingStatsOff =>
      'إنت بس اللي بتشوف إحصائيات قرايتك.';

  @override
  String get profileReadingStatsEmpty => 'لسه مخلّصش مقالات.';

  @override
  String get profileReadingHeatmapEmpty => 'مفيش أيام قراية لسه.';

  @override
  String get profileBioLabel => 'نبذة';

  @override
  String get profileBioHint => 'بتشتغل في إيه؟ وبتكتب عن إيه؟';

  @override
  String get profilePhotoGallery => 'اختار من صورك';

  @override
  String get profilePhotoCamera => 'صوّر صورة';

  @override
  String get profilePhotoPreview => 'صورة الحساب';

  @override
  String get profileExpertiseHint => 'اختار لحد 5 مجالات انت فاهم فيها كويس.';

  @override
  String get profileExpertiseFull => 'كده 5. شيل واحد عشان تختار غيره.';

  @override
  String profileExpertiseCountSemantics(int count, int max) {
    return 'اخترت $count من $max';
  }

  @override
  String get profileFollowSearchHint => 'دوّر بالاسم أو الـ username';

  @override
  String get profileFollowNoResultsTitle => 'مفيش حد بالاسم ده';

  @override
  String get profileFollowNoResultsBody => 'جرّب اسم أو username تاني.';

  @override
  String get profileFollowersEmptyTitle => 'مفيش متابعين لسه';

  @override
  String get profileFollowersEmptyOwnBody =>
      'القرّاء اللي تعجبهم مقالاتك يقدروا يتابعوك.';

  @override
  String get profileFollowingEmptyTitle => 'مش بيتابع حد لسه';

  @override
  String get profileFollowingEmptyOwnBody =>
      'تابع كتّاب عشان مقالاتهم الجديدة توصلك في النهارده.';

  @override
  String get profileErrStatsPrivate => 'إحصائيات القراءة دي خاصة.';

  @override
  String get profileErrAvatarInvalid =>
      'الصورة دي مينفعش تتستخدم. ارفع صورة تانية.';

  @override
  String get profileErrExpertiseInvalid =>
      'اختار لحد 5 من المجالات اللي في القايمة.';

  @override
  String get profileErrUrl => 'اكتب لينك كامل بيبدأ بـ https://';

  @override
  String get errValidation => 'راجع الخانات المعلّمة.';

  @override
  String get errUnauthorized => 'سجّل دخول تاني لو سمحت.';

  @override
  String get errForbidden => 'معندكش صلاحية تعمل ده.';

  @override
  String get errSuspended => 'الحساب ده موقوف. تواصل مع الدعم';

  @override
  String get errNotSynced => 'معرفناش نجهّز حسابك. جرّب تاني.';

  @override
  String get errUserNotFound => 'المستخدم مش موجود.';

  @override
  String get errUsernameTaken => 'اسم المستخدم ده محجوز.';

  @override
  String get errInterestsMinThree => 'اختار 3 اهتمامات على الأقل.';

  @override
  String get errFieldNotFound => 'المجال ده مش موجود.';

  @override
  String get errArticleNotFound => 'المقال ده مش موجود أو اتشال.';

  @override
  String get errServer => 'حصلت مشكلة عندنا. جرّب تاني.';

  @override
  String get errOffline => 'انت أوفلاين. اتأكد من النت.';

  @override
  String get errTimeout => 'الاتصال أخد وقت كتير. جرّب تاني.';

  @override
  String get errInvalidCredentials => 'رقم التليفون أو كلمة السر غلط';

  @override
  String get errTooManyRequests => 'طلبات كتير، استنى شوية وجرب تاني.';

  @override
  String get errCancelled => 'اتلغى.';

  @override
  String get errSourcesRequired => 'ضيف مصدر واحد على الأقل قبل النشر.';

  @override
  String get errMediaPurposeInvalid => 'نوع الرفع ده مش مدعوم.';

  @override
  String get errMediaFileRequired => 'اختار ملف الأول.';

  @override
  String get errMediaTooLarge =>
      'الملف ده حجمه كبير (الـ PDF لحد 20 ميجا، والصور لحد 10 ميجا).';

  @override
  String get errMediaUnsupportedType =>
      'نوع الملف ده مش مدعوم. استخدم JPEG أو PNG أو WebP أو HEIC أو PDF.';

  @override
  String get errMediaDimensionsTooLarge =>
      'أبعاد الصورة دي كبيرة (لحد 8000 × 8000 بكسل).';

  @override
  String get errMediaImageCorrupted =>
      'معرفناش نقرا الصورة دي. جرّب صورة تانية.';

  @override
  String get errMediaPdfEncrypted =>
      'الملف ده عليه باسورد، ارفعه من غير باسورد.';

  @override
  String get errMediaPdfCorrupted => 'معرفناش نقرا الـ PDF ده، ممكن يكون بايظ.';

  @override
  String get errMediaPdfTooManyPages => 'الـ PDF ده أكتر من 100 صفحة.';

  @override
  String get errMediaQuotaDaily =>
      'وصلت لحد الرفع بتاع النهارده (50 ملف). جرّب بكره.';

  @override
  String get errMediaQuotaStorage =>
      'المساحة بتاعتك خلصت (200 ميجا). امسح ملفات قديمة عشان ترفع تاني.';

  @override
  String get errMediaNotFound => 'الملف ده مبقاش موجود.';

  @override
  String get errMediaInUse => 'الملف ده مرفق في منشور.';

  @override
  String get errMediaDownloadNotAllowed => 'الكاتب مسمحش بتحميل الملف ده.';

  @override
  String get errMediaProcessingFailed =>
      'معرفناش نجهّز الملف ده. امسحه أو جرّب تاني.';

  @override
  String get errMediaProcessingTimeout =>
      'تجهيز الملف أخد وقت كتير. جرّب تاني.';

  @override
  String get errAttachmentsMixedKinds =>
      'المنشور يا صور يا ملف PDF واحد، مش الاتنين.';

  @override
  String get errAttachmentsTooManyImages => 'تقدر ترفق لحد 10 صور بس.';

  @override
  String get errAttachmentsSingleDocument => 'تقدر ترفق ملف PDF واحد بس.';

  @override
  String get errAttachmentsAltTextRequired => 'كل صورة محتاجة وصف (Alt text).';

  @override
  String get errAttachmentsAltTextTooLong => 'وصف الصورة لحد 5000 حرف بس.';

  @override
  String get errAttachmentsCaptionTooLong =>
      'التعليق على الصورة لحد 5000 حرف بس.';

  @override
  String get errAttachmentsTitleTooLong => 'عنوان الملف لحد 5000 حرف بس.';

  @override
  String get errAttachmentsTitleRequired => 'الملف محتاج عنوان.';

  @override
  String get errAttachmentsAssetNotFound =>
      'فيه مرفق مش موجود. امسحه وارفعه تاني.';

  @override
  String get errAttachmentsAssetNotReady => 'فيه مرفق لسه بيتجهّز. استنى شوية.';

  @override
  String get errAttachmentsDuplicateAsset => 'نفس الملف مرفق مرتين.';

  @override
  String get composerField => 'المجال';

  @override
  String get composerFieldHint => 'اختار المجال';

  @override
  String get composerSourcesRequired => 'المجال ده محتاج مصدر واحد على الأقل.';

  @override
  String get composerSourcesOptional =>
      'اختياري، بس القراء بيثقوا أكتر في المنشورات اللي ليها مصادر.';

  @override
  String get composerAddSource => 'ضيف مصدر';

  @override
  String get composerAttachments => 'المرفقات';

  @override
  String get composerSourceTitle => 'اسم المصدر';

  @override
  String get composerSourceUrl => 'اللينك (https://…)';

  @override
  String get composerRemoveSource => 'شيل المصدر';

  @override
  String get composerInvalidUrl => 'اكتب لينك صحيح بيبدأ بـ http';

  @override
  String get attachImages => 'صور';

  @override
  String get attachPdf => 'ملف PDF';

  @override
  String get attachMixHint => 'المنشور يا صور يا ملف PDF واحد، مش الاتنين.';

  @override
  String attachImagesLimit(int count) {
    return '$count من 10 صور';
  }

  @override
  String get attachReorderHint =>
      'اضغط مطوّل واسحب عشان ترتّب. دوس على الصورة عشان تكتب وصفها.';

  @override
  String get attachNeedDocTitle => 'اكتب عنوان للملف.';

  @override
  String get altTextLabel => 'وصف الصورة (مطلوب)';

  @override
  String get altTextHint => 'اوصف الصورة للي بيستخدموا قارئ الشاشة';

  @override
  String get altTextMissing => 'محتاجة وصف';

  @override
  String get altTextAdded => 'وصف ✓';

  @override
  String get altTextBadgeMissing => 'ضيف وصف';

  @override
  String get listSeparator => '، ';

  @override
  String get captionLabel => 'تعليق (اختياري)';

  @override
  String imageDetailsTitle(int index, int total) {
    return 'صورة $index من $total';
  }

  @override
  String get editImageDetails => 'تعديل الوصف والتعليق';

  @override
  String get moveEarlier => 'قدّمها';

  @override
  String get moveLater => 'أخّرها';

  @override
  String get removeAttachment => 'امسح';

  @override
  String get cancelUpload => 'إلغاء الرفع';

  @override
  String get uploadPreparing => 'بنجهّز…';

  @override
  String uploadProgress(int percent) {
    return 'بنرفع… $percent%';
  }

  @override
  String get uploadCancelled => 'الرفع اتلغى';

  @override
  String get uploadFailed => 'الرفع فشل';

  @override
  String fileSizeMb(String size) {
    return '$size ميجا';
  }

  @override
  String fileSizeKb(String size) {
    return '$size كيلو';
  }

  @override
  String get pdfTitleLabel => 'عنوان الملف (مطلوب)';

  @override
  String get pdfAllowDownload => 'السماح بتحميل الملف';

  @override
  String get pdfAllowDownloadHint =>
      'القراء هيقدروا ينزّلوا ملف الـ PDF الأصلي.';

  @override
  String get pdfPreparingPages => 'بنجهز الصفحات…';

  @override
  String pdfPagesReady(int ready, int total) {
    return '$ready من $total صفحة جاهزة';
  }

  @override
  String pdfPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحة',
      many: '$count صفحة',
      few: '$count صفحات',
      two: 'صفحتين',
      one: 'صفحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String pdfMorePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count صفحة، افتح الملف',
      many: '+$count صفحة، افتح الملف',
      few: '+$count صفحات، افتح الملف',
      two: '+صفحتين، افتح الملف',
      one: '+صفحة، افتح الملف',
    );
    return '$_temp0';
  }

  @override
  String get openDocument => 'افتح الملف';

  @override
  String get viewerDownload => 'تحميل';

  @override
  String get viewerDownloading => 'بننزّل الملف…';

  @override
  String viewerImageOf(int index, int total) {
    return 'صورة $index من $total';
  }

  @override
  String viewerPageOf(int index, int total) {
    return 'صفحة $index من $total';
  }

  @override
  String get viewerZoomHint => 'دوس مرتين للتكبير';

  @override
  String get viewerPageLoading => 'بنحمّل الصفحة…';

  @override
  String get viewerThumbnails => 'الصفحات';

  @override
  String get welcomeSignIn => 'عندي حساب، سجل دخول';

  @override
  String switchLanguageTo(String language) {
    return 'غيّر لغة التطبيق لـ $language';
  }

  @override
  String get continueAction => 'كمّل';

  @override
  String get edit => 'تعديل';

  @override
  String get optional => 'اختياري';

  @override
  String get contactSupport => 'تواصل مع الدعم';

  @override
  String get signInSubtitle => 'سجل دخول برقم موبايلك وكلمة السر.';

  @override
  String get phoneLabel => 'رقم الموبايل';

  @override
  String get createAccountLink => 'اعمل حساب';

  @override
  String get passwordResetBanner =>
      'تم تغيير كلمة السر. سجل دخول بكلمة السر الجديدة';

  @override
  String get sessionExpired => 'الجلسة انتهت، سجّل دخولك تاني.';

  @override
  String get signUpHeading => 'اعمل حسابك';

  @override
  String get signUpCredentialsBody =>
      'هتسجل دخول بالرقم ده وكلمة السر. مش هنبعتلك أكواد SMS.';

  @override
  String get confirmPasswordLabel => 'أكد كلمة السر';

  @override
  String get currentPasswordLabel => 'كلمة السر الحالية';

  @override
  String get newPasswordLabel => 'كلمة السر الجديدة';

  @override
  String ruleMinLength(int count) {
    return '$count حروف أو أكتر';
  }

  @override
  String get ruleLetter => 'حرف';

  @override
  String get ruleDigit => 'رقم';

  @override
  String get ruleMet => 'تمام';

  @override
  String get ruleNotMet => 'لسه';

  @override
  String passwordStrength(String level) {
    return 'قوة كلمة السر: $level';
  }

  @override
  String get strengthWeak => 'ضعيفة';

  @override
  String get strengthFair => 'مقبولة';

  @override
  String get strengthGood => 'كويسة';

  @override
  String get strengthStrong => 'قوية';

  @override
  String get pinStepTitle => 'اعمل PIN للطوارئ';

  @override
  String get pinStepBody =>
      'لو نسيت كلمة السر، رقمك والـ PIN ده هيخلوك تختار كلمة سر جديدة. احفظه في مكان أمان ومتقولوش لحد.';

  @override
  String get pinLabel => 'الـ PIN';

  @override
  String get confirmPinLabel => 'أكد الـ PIN';

  @override
  String get newPinLabel => 'الـ PIN الجديد';

  @override
  String get showPin => 'اظهر الـ PIN';

  @override
  String get hidePin => 'اخفي الـ PIN';

  @override
  String pinSemantics(String label, int filled, int total) {
    return '$label، اتكتب $filled من $total أرقام';
  }

  @override
  String get confirmNumberTitle => 'ده رقمك؟';

  @override
  String get confirmNumberWarning =>
      'هتستخدم الرقم ده في تسجيل الدخول، ومش هتقدر تسترجع حسابك لو الرقم غلط.';

  @override
  String get confirmNumberYes => 'صح، اعمل الحساب';

  @override
  String get confirmNumberChangeYes => 'صح، غيّر الرقم';

  @override
  String get confirmNumberAddYes => 'صح، ضيف الرقم';

  @override
  String get completeProfileTitle => 'كمّل بروفايلك';

  @override
  String get completeProfileBody => 'كده القرّاء والكتّاب هيشوفوك.';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get usernameHint => 'من 3 لـ 30: a–z أو 0–9 أو _';

  @override
  String get usernameChecking => 'بنشوف…';

  @override
  String usernameAvailable(String username) {
    return '@$username متاح';
  }

  @override
  String get addPhoto => 'ضيف صورة';

  @override
  String get changePhoto => 'غيّر الصورة';

  @override
  String get removePhoto => 'شيل الصورة';

  @override
  String get photoUploading => 'بنرفع الصورة…';

  @override
  String get saveAndContinue => 'احفظ وكمّل';

  @override
  String get forgotTitle => 'استرجع كلمة السر';

  @override
  String get forgotStep1Body =>
      'اكتب رقمك والـ PIN اللي عملته وانت بتعمل الحساب.';

  @override
  String get forgotPin => 'نسيت الـ PIN كمان؟';

  @override
  String get forgotStep2Title => 'اختار كلمة سر جديدة';

  @override
  String get forgotStep2Body => 'كل الأجهزة اللي داخلة على حسابك هتخرج منه.';

  @override
  String get supportTitle => 'تواصل مع الدعم';

  @override
  String get supportBody =>
      'من غير الـ PIN، فريق الدعم بس اللي يقدر يعمل reset لكلمة السر، بعد ما نتأكد إن الحساب بتاعك. ابعتلنا إيميل فيه رقم حسابك، وبعد الـ reset هتختار كلمة سر و PIN جداد أول ما تسجل دخول.';

  @override
  String get supportEmailAction => 'ابعت إيميل للدعم';

  @override
  String get copyEmail => 'انسخ الإيميل';

  @override
  String get setPinTitle => 'اعمل PIN للطوارئ';

  @override
  String get setPinBody =>
      'حسابك محتاج PIN للطوارئ. مع رقمك، هيخليك تختار كلمة سر جديدة لو نسيت كلمة السر.';

  @override
  String get changePasswordTitle => 'تغيير كلمة السر';

  @override
  String get mustChangePasswordBody =>
      'كلمة السر بتاعتك اتعملها reset. اختار واحدة جديدة عشان تكمّل.';

  @override
  String get changePasswordBody => 'الأجهزة التانية هتخرج من حسابك.';

  @override
  String get passwordChanged => 'تم تغيير كلمة السر.';

  @override
  String get changePinTitle => 'تغيير الـ PIN';

  @override
  String get changePinBody => 'أكد بكلمة السر، وبعدين اختار الـ PIN الجديد.';

  @override
  String get pinChanged => 'تم تغيير الـ PIN.';

  @override
  String get changePhoneTitle => 'تغيير الرقم';

  @override
  String get changePhoneBody =>
      'هتسجل دخول بالرقم الجديد، والأجهزة التانية هتخرج من حسابك.';

  @override
  String get newPhoneLabel => 'رقم الموبايل الجديد';

  @override
  String get phoneChanged => 'تم تغيير الرقم.';

  @override
  String get phoneNumberLabel => 'رقم التليفون';

  @override
  String get phoneVisibleToYou => 'محدش يقدر يشوفه غيرك';

  @override
  String get changePhone => 'تغيير الرقم';

  @override
  String get changePassword => 'تغيير كلمة السر';

  @override
  String get changePin => 'تغيير الـ PIN';

  @override
  String get signOutEverywhere => 'تسجيل الخروج من كل الأجهزة';

  @override
  String get signOutEverywhereBody =>
      'كل الأجهزة التانية هتخرج من حسابك، وانت هتفضل داخل على الجهاز ده.';

  @override
  String get signedOutEverywhere => 'خرّجناك من كل الأجهزة التانية.';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountBody =>
      'هنمسح بروفايلك وبياناتك الشخصية بعد 30 يوم. مقالاتك وتعليقاتك هتفضل باسم \"مستخدم محذوف\". مينفعش ترجع في القرار ده.';

  @override
  String get deleteAccountConfirm => 'فاهم، امسح حسابي';

  @override
  String get deleteAccountButton => 'امسح حسابي';

  @override
  String get accountDeleted => 'تم حذف الحساب.';

  @override
  String get countryPickerTitle => 'اختار الدولة';

  @override
  String get countrySearchHint => 'دوّر بالاسم أو الكود أو مفتاح الدولة';

  @override
  String get countryNoResults => 'مفيش دولة بالاسم ده';

  @override
  String countryButtonSemantics(String country, String dialCode) {
    return 'الدولة: $country، +$dialCode. اضغط مرتين عشان تغيّر';
  }

  @override
  String get selected => 'مختارة';

  @override
  String get devLoginOpen => 'حسابات تجريبية';

  @override
  String get devLoginTitle => 'حسابات تجريبية (dev بس)';

  @override
  String get devLoginBody =>
      'مستخدمين الـ seed المحليين. لو DEV_DEMO_PASSWORD متحدد، الضغطة بتدخلك على طول؛ غير كده بتكتب الرقم بس.';

  @override
  String get devLoginHasPin => 'عنده PIN';

  @override
  String get devLoginNoPin => 'معندوش PIN';

  @override
  String get errPhoneInvalid => 'رقم الموبايل ده مش صحيح.';

  @override
  String get errPhoneTaken => 'الرقم ده عليه حساب بالفعل';

  @override
  String get errPhoneUnchanged => 'ده رقمك الحالي بالفعل.';

  @override
  String get errLockedOut => 'محاولات كتير. جرّب تاني بعد 15 دقيقة';

  @override
  String get errWrongPassword => 'كلمة السر الحالية غلط.';

  @override
  String get errRecoveryInvalid => 'رقم التليفون أو الـ PIN غلط';

  @override
  String get errRecoveryLocked => 'محاولات كتير. جرّب تاني بعد ساعة.';

  @override
  String get errRecoveryDisabled =>
      'الاسترجاع متوقف للحساب ده. تواصل مع الدعم.';

  @override
  String get errResetTokenInvalid => 'انتهت المهلة، ابدأ من الأول';

  @override
  String get errPinAlreadySet => 'عندك PIN بالفعل، غيّره من الإعدادات.';

  @override
  String get errUsernameInvalid => 'استخدم من 3 لـ 30 حرف: a–z أو 0–9 أو _.';

  @override
  String get errPasswordTooShort => 'كلمة السر قصيرة.';

  @override
  String get errPasswordTooLong => 'كلمة السر طويلة أوي.';

  @override
  String get errPasswordLetterRequired => 'ضيف حرف واحد على الأقل.';

  @override
  String get errPasswordDigitRequired => 'ضيف رقم واحد على الأقل.';

  @override
  String get errPasswordTooCommon => 'كلمة السر دي مشهورة أوي. اختار غيرها.';

  @override
  String get errPasswordContainsPhone =>
      'كلمة السر مينفعش يكون فيها رقم موبايلك.';

  @override
  String get errPasswordMismatch => 'كلمتين السر مش زي بعض.';

  @override
  String get errPinLength => 'اكتب كل الأرقام.';

  @override
  String get errPinDigitsOnly => 'أرقام بس.';

  @override
  String get errPinWeak =>
      'الـ PIN ده سهل يتخمّن. ابعد عن الأرقام المكررة أو المتسلسلة والسنين والأرقام اللي في موبايلك أو كلمة السر.';

  @override
  String get errPinMismatch => 'الـ PIN مش زي بعضه.';

  @override
  String get errTooShort => 'قصير أوي.';

  @override
  String get errTooLong => 'طويل أوي.';

  @override
  String get errInvalidValue => 'راجع الخانة دي.';

  @override
  String get orDivider => 'أو';

  @override
  String get continueWithGoogle => 'كمّل بـ Google';

  @override
  String get continueWithApple => 'كمّل بـ Apple';

  @override
  String get externalNotLinkedTitle => 'مفيش حساب ReadIn مربوط بالحساب ده لسه';

  @override
  String get externalNotLinkedBody =>
      'اعمل حساب جديد، أو اربطه بحسابك اللي عامله برقم تليفونك.';

  @override
  String get externalCreateAccount => 'اعمل حساب جديد';

  @override
  String get externalLinkExisting => 'عندي حساب برقم تليفون';

  @override
  String get linkAccountTitle => 'اربط حسابك';

  @override
  String linkAccountBody(String provider) {
    return 'سجل دخول برقمك وكلمة السر مرة واحدة، وبعد كده تقدر تدخل بـ $provider كمان.';
  }

  @override
  String get linkAccountButton => 'اربط وسجل دخول';

  @override
  String get linkedAccounts => 'الحسابات المربوطة';

  @override
  String get linkAction => 'اربط';

  @override
  String get unlinkAction => 'فك الربط';

  @override
  String get notLinked => 'مش مربوط';

  @override
  String unlinkTitle(String provider) {
    return 'تفك ربط $provider؟';
  }

  @override
  String unlinkBody(String provider) {
    return 'مش هتقدر تدخل بـ $provider لحد ما تربطه تاني.';
  }

  @override
  String providerLinked(String provider) {
    return 'اتربط $provider';
  }

  @override
  String providerUnlinked(String provider) {
    return 'اتفك ربط $provider';
  }

  @override
  String get confirmItsYou => 'أكد إنه انت';

  @override
  String linkWithPasswordBody(String provider) {
    return 'اكتب كلمة السر عشان تربط $provider.';
  }

  @override
  String get confirmAction => 'أكد';

  @override
  String get addPhoneSignIn => 'ضيف رقم تليفون وكلمة سر';

  @override
  String addPhoneSignInBody(String provider) {
    return 'هتقدر تدخل برقمك وكلمة السر كمان، وتستخدم PIN الطوارئ لو نسيت كلمة السر. هتأكد بـ $provider في الآخر.';
  }

  @override
  String get phoneSignInAdded => 'اتضاف رقم التليفون وكلمة السر';

  @override
  String deleteAccountWithProvider(String provider) {
    return 'عشان تمسح حسابك، هتأكد بـ $provider.';
  }

  @override
  String get errExternalNotLinked => 'مفيش حساب ReadIn مربوط بالحساب ده لسه.';

  @override
  String get errExternalInvalid => 'معرفناش نتأكد من الحساب ده. جرّب تاني.';

  @override
  String get errProviderDisabled => 'الطريقة دي مش متاحة دلوقتي.';

  @override
  String get errExternalConflict => 'في حساب تاني من نفس النوع مربوط بالفعل.';

  @override
  String get errExternalInUse => 'الحساب ده مربوط بحساب ReadIn تاني.';

  @override
  String get errExternalMismatch => 'أكد بحساب مربوط بحسابك على ReadIn.';

  @override
  String get errExternalLoginNotFound => 'الحساب ده مش مربوط.';

  @override
  String get errConfirmationRequired => 'أكد إنه انت الأول.';

  @override
  String get errLastSignInMethod =>
      'دي الطريقة الوحيدة اللي بتدخل بيها. ضيف طريقة تانية الأول.';

  @override
  String get errPhoneSignInExists => 'حسابك عليه رقم تليفون وكلمة سر بالفعل.';

  @override
  String get errProviderInvalid => 'الطريقة دي مش مدعومة.';

  @override
  String get errExternalProviderFailed =>
      'الدخول بـ Google أو Apple مكملش. جرّب تاني.';

  @override
  String readingStreakNotReadTodaySemantics(int count) {
    return 'الـ streak بتاعك: $count يوم. لسه مقرتش النهارده.';
  }

  @override
  String readingStreakFreezePendingSemantics(int count) {
    return 'الـ streak بتاعك: $count يوم. فاتك امبارح: اقرا النهارده والـ freeze هيحافظ على الـ streak.';
  }

  @override
  String get readingStatsTitle => 'إحصائيات القراءة';

  @override
  String get readingCurrentStreak => 'الـ streak الحالي';

  @override
  String get readingLongestStreak => 'أطول streak';

  @override
  String readingDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يوم',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: '0 يوم',
    );
    return '$_temp0';
  }

  @override
  String get readingFreezeAvailable =>
      'عندك freeze جاهز: لو فاتك يوم، الـ streak هيفضل زي ما هو.';

  @override
  String get readingFreezePending =>
      'فاتك امبارح. اقرا النهارده والـ freeze هيحافظ على الـ streak بتاعك.';

  @override
  String get readingFreezeUsed =>
      'استخدمت الـ freeze. هيجيلك واحد جديد خلال 7 أيام.';

  @override
  String get readingLast7Days => 'آخر 7 أيام';

  @override
  String get readingLast30Days => 'آخر 30 يوم';

  @override
  String get readingAllTime => 'من الأول';

  @override
  String readingArticlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقال',
      few: '$count مقالات',
      two: 'مقالين',
      one: 'مقال واحد',
      zero: '0 مقال',
    );
    return '$_temp0';
  }

  @override
  String readingMinutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة',
      many: '$count دقيقة',
      few: '$count دقايق',
      two: 'دقيقتين',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get readingTopFields => 'أكتر مجالات بتقراها';

  @override
  String readingTopFieldSemantics(String field, String articles) {
    return '$field: $articles';
  }

  @override
  String get readingStatsEmpty => 'خلّص أول مقال للآخر عشان تبدأ الـ streak.';

  @override
  String get readingActivity => 'نشاط القراءة';

  @override
  String get readingLast12Months => 'آخر 12 شهر';

  @override
  String get readingHeatmapLess => 'أقل';

  @override
  String get readingHeatmapMore => 'أكتر';

  @override
  String get readingHeatmapFreeze => 'يوم بـ freeze';

  @override
  String readingHeatmapSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم قراءة',
      many: '$count يوم قراءة',
      few: '$count أيام قراءة',
      two: 'يومين قراءة',
      one: 'يوم قراءة واحد',
      zero: 'مفيش أيام قراءة لسه',
    );
    return 'نشاط القراءة في آخر 12 شهر: $_temp0';
  }

  @override
  String readingHeatmapDay(String date, String articles) {
    return '$date: $articles';
  }

  @override
  String readingHeatmapFrozenDay(String date) {
    return '$date: الـ freeze حافظ على الـ streak';
  }

  @override
  String get readingHeatmapEmpty => 'كل يوم تخلّص فيه مقال هيظهر هنا.';

  @override
  String readingDaysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم ورا بعض',
      few: 'أيام ورا بعض',
      two: 'يومين ورا بعض',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get readingMilestoneWeekTitle => 'أسبوع كامل!';

  @override
  String get readingMilestoneWeekBody => '7 أيام قراءة ورا بعض. كمّل كده!';

  @override
  String get readingMilestoneMonthTitle => 'شهر كامل من القراءة!';

  @override
  String get readingMilestoneMonthBody => '30 يوم ورا بعض. كده بقت عادة بجد.';

  @override
  String get readingMilestoneHundredTitle => '100 يوم!';

  @override
  String get readingMilestoneHundredBody =>
      '100 يوم ورا بعض. قليلين اللي بيوصلوا لهنا.';

  @override
  String get readingMilestoneYearTitle => 'سنة كاملة!';

  @override
  String get readingMilestoneYearBody => '365 يوم قراءة ورا بعض. إنجاز أسطوري.';

  @override
  String readingMilestoneTitle(int count) {
    return '$count يوم ورا بعض!';
  }

  @override
  String get readingMilestoneBody => 'كمّل كده!';

  @override
  String readingShareCardSemantics(int count) {
    return 'كارت ReadIn: $count يوم قراءة ورا بعض';
  }

  @override
  String get readingKeepReading => 'كمّل قراءة';

  @override
  String get readingShareFailed => 'معرفناش نشارك الكارت. جرّب تاني.';

  @override
  String get reactionInsightful => 'مفيد';

  @override
  String get reactionLove => 'حبيته';

  @override
  String get reactionFire => 'نار';

  @override
  String get reactionMindBlown => 'مبهر';

  @override
  String get reactAction => 'اتفاعل بـ 💡 مفيد';

  @override
  String removeReaction(String reaction) {
    return 'شيل تفاعلك ($reaction)';
  }

  @override
  String get chooseReaction => 'اختار تفاعل';

  @override
  String reactionCountSemantics(String reaction, int count) {
    return '$reaction: $count';
  }

  @override
  String reactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تفاعل',
      many: '$count تفاعل',
      few: '$count تفاعلات',
      two: 'تفاعلين',
      one: 'تفاعل واحد',
      zero: 'لسه مفيش تفاعلات',
    );
    return '$_temp0';
  }

  @override
  String get whoReacted => 'التفاعلات';

  @override
  String get showWhoReacted => 'شوف مين اتفاعل';

  @override
  String get reactorsEmpty => 'لسه محدش اتفاعل';

  @override
  String reactorsEmptyType(String reaction) {
    return 'لسه محدش اختار $reaction';
  }

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعليق',
      many: '$count تعليق',
      few: '$count تعليقات',
      two: 'تعليقين',
      one: 'تعليق واحد',
      zero: 'لسه مفيش تعليقات',
    );
    return '$_temp0';
  }

  @override
  String get saveArticle => 'احفظ';

  @override
  String get unsaveArticle => 'شيله من المحفوظات';

  @override
  String get articleSaved => 'اتحفظ، وتقدر تقراه من غير نت كمان.';

  @override
  String get articleUnsaved => 'اتشال من المحفوظات';

  @override
  String get undo => 'تراجع';

  @override
  String get moreActions => 'اختيارات تانية';

  @override
  String get addToCollection => 'ضيفه لمجموعة';

  @override
  String get collections => 'المجموعات';

  @override
  String get newCollection => 'مجموعة جديدة';

  @override
  String get collectionName => 'اسم المجموعة';

  @override
  String get collectionNameHint => 'مثلاً: تحضير الإنترفيو';

  @override
  String get createAction => 'اعملها';

  @override
  String get renameAction => 'غيّر الاسم';

  @override
  String get renameCollection => 'غيّر اسم المجموعة';

  @override
  String get deleteAction => 'امسح';

  @override
  String deleteCollectionTitle(String name) {
    return 'تمسح «$name»؟';
  }

  @override
  String get deleteCollectionBody =>
      'المجموعة بس هي اللي هتتمسح، والمقالات اللي فيها هتفضل محفوظة.';

  @override
  String collectionArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقال',
      few: '$count مقالات',
      two: 'مقالين',
      one: 'مقال واحد',
      zero: 'مفيش مقالات',
    );
    return '$_temp0';
  }

  @override
  String get collectionsEmptyTitle => 'مفيش مجموعات لسه';

  @override
  String get collectionsEmptyBody =>
      'قسّم محفوظاتك لقوايم، زي «تحضير الإنترفيو».';

  @override
  String addedToCollection(String name) {
    return 'اتضاف لـ $name';
  }

  @override
  String removedFromCollection(String name) {
    return 'اتشال من $name';
  }

  @override
  String get removeFromCollection => 'شيله من المجموعة دي';

  @override
  String inCollection(String name) {
    return 'في $name';
  }

  @override
  String collectionFilter(String name) {
    return 'المجموعة: $name';
  }

  @override
  String get clearFilter => 'شيل الفلتر';

  @override
  String openCollection(String name) {
    return 'اعرض مقالات $name';
  }

  @override
  String get savedTabArticles => 'المقالات';

  @override
  String get savedSearchHint => 'دوّر في محفوظاتك';

  @override
  String get clearSearch => 'امسح البحث';

  @override
  String get savedEmptyTitle => 'لسه مفيش محفوظات';

  @override
  String get savedEmptyBody =>
      'دوس على علامة الحفظ في أي مقال عشان يتحفظ هنا. المقالات المحفوظة بتفتح حتى من غير نت.';

  @override
  String get savedNoResultsTitle => 'مفيش محفوظات بالشكل ده';

  @override
  String get savedNoResultsBody => 'جرّب كلمة أو مجال تاني.';

  @override
  String get savedCollectionEmptyTitle => 'المجموعة دي فاضية';

  @override
  String get savedCollectionEmptyBody =>
      'ضيف لها مقالات من صفحة المقال أو من محفوظاتك.';

  @override
  String get savedOfflineBanner =>
      'انت أوفلاين. دي المقالات المحفوظة على الموبايل ده.';

  @override
  String get offlineCopy => 'نسخة أوفلاين محفوظة على الموبايل ده';

  @override
  String get savedGuestTitle => 'محفوظاتك';

  @override
  String get savedGuestBody =>
      'سجّل دخول عشان تحفظ مقالات وتقراها بعدين، حتى من غير نت.';

  @override
  String get follow => 'تابع';

  @override
  String get followingState => 'بتتابعه';

  @override
  String followName(String name) {
    return 'تابع $name';
  }

  @override
  String unfollowName(String name) {
    return 'الغي متابعة $name';
  }

  @override
  String get followsYou => 'بيتابعك';

  @override
  String get feedFollowing => 'بتتابعهم';

  @override
  String get followingEmptyTitle => 'تابع كتّاب عشان الصفحة دي تتملي';

  @override
  String get followingEmptyBody =>
      'المقالات الجديدة للكتّاب اللي بتتابعهم هتظهر هنا، الأحدث الأول.';

  @override
  String get suggestedWriters => 'كتّاب ممكن يعجبوك';

  @override
  String get suggestedWritersEmpty => 'مفيش اقتراحات دلوقتي. ارجع بعدين.';

  @override
  String get showFollowingArticles => 'اعرض مقالاتهم';

  @override
  String get followingGuestTitle => 'تابع الكتّاب اللي بتحبهم';

  @override
  String get followingGuestBody =>
      'سجّل دخول عشان تتابع كتّاب وتقرا مقالاتهم الجديدة هنا.';

  @override
  String get errReactionInvalid => 'التفاعل ده مش متاح.';

  @override
  String get errCollectionNameTaken => 'عندك مجموعة بنفس الاسم.';

  @override
  String get errCollectionLimit => 'آخرك 50 مجموعة.';

  @override
  String get errCollectionNotFound => 'المجموعة دي مبقتش موجودة.';

  @override
  String get errFollowSelf => 'مينفعش تتابع نفسك.';

  @override
  String get commentsOpen => 'افتح التعليقات';

  @override
  String get commentsTitle => 'التعليقات';

  @override
  String commentsTitleCount(int count) {
    return 'التعليقات ($count)';
  }

  @override
  String get commentsSortTop => 'الأهم';

  @override
  String get commentsSortNewest => 'الأحدث';

  @override
  String get commentsEmptyTitle => 'لسه مفيش تعليقات';

  @override
  String get commentsEmptyBody => 'خليك أول واحد يقول رأيه.';

  @override
  String get commentsAuthorBadge => 'الكاتب';

  @override
  String get commentsPinned => 'متثبّت';

  @override
  String get commentsEdited => 'متعدّل';

  @override
  String get commentsDeletedPlaceholder => 'التعليق ده اتمسح';

  @override
  String get commentsHiddenPlaceholder => 'المشرفين خبّوا التعليق ده';

  @override
  String get commentsHiddenNotice =>
      'المشرفين خبّوا التعليق ده. انت والمشرفين بس اللي شايفينه.';

  @override
  String get commentsDeletedUser => 'مستخدم محذوف';

  @override
  String get commentsLike => 'عجبني';

  @override
  String get commentsUnlike => 'شيل الإعجاب';

  @override
  String commentsLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إعجاب',
      many: '$count إعجاب',
      few: '$count إعجابات',
      two: 'إعجابين',
      one: 'إعجاب واحد',
      zero: 'مفيش إعجابات',
    );
    return '$_temp0';
  }

  @override
  String get commentsReply => 'رد';

  @override
  String commentsMoreReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اعرض $count رد كمان',
      many: 'اعرض $count رد كمان',
      few: 'اعرض $count ردود كمان',
      two: 'اعرض ردين كمان',
      one: 'اعرض رد كمان',
    );
    return '$_temp0';
  }

  @override
  String get commentsMoreRepliesAny => 'اعرض ردود أكتر';

  @override
  String commentsNewPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعليق جديد',
      many: '$count تعليق جديد',
      few: '$count تعليقات جديدة',
      two: 'تعليقين جداد',
      one: 'تعليق جديد',
    );
    return '$_temp0';
  }

  @override
  String get commentsSending => 'بيتبعت…';

  @override
  String get commentsTimeNow => 'دلوقتي';

  @override
  String commentsTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count دقيقة',
      many: 'من $count دقيقة',
      few: 'من $count دقايق',
      two: 'من دقيقتين',
      one: 'من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String commentsTimeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count ساعة',
      many: 'من $count ساعة',
      few: 'من $count ساعات',
      two: 'من ساعتين',
      one: 'من ساعة',
    );
    return '$_temp0';
  }

  @override
  String commentsTimeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count يوم',
      many: 'من $count يوم',
      few: 'من $count أيام',
      two: 'من يومين',
      one: 'امبارح',
    );
    return '$_temp0';
  }

  @override
  String get commentsComposerHint => 'اكتب تعليق…';

  @override
  String get commentsReplyHint => 'اكتب ردك…';

  @override
  String get commentsSend => 'ابعت';

  @override
  String commentsReplyingTo(String name) {
    return 'بترد على $name';
  }

  @override
  String get commentsEditing => 'بتعدّل تعليقك';

  @override
  String get commentsMentionSuggestions => 'ناس تقدر تعمل لهم منشن';

  @override
  String get commentsGuestPrompt => 'سجّل دخول عشان تشارك في النقاش.';

  @override
  String get commentsMenu => 'اختيارات التعليق';

  @override
  String get commentsDeleteTitle => 'تمسح التعليق ده؟';

  @override
  String get commentsDeleteBody =>
      'مش هتقدر ترجّعه، والردود عليه هتفضل موجودة.';

  @override
  String get commentsDeleted => 'التعليق اتمسح';

  @override
  String get commentsPin => 'ثبّته';

  @override
  String get commentsUnpin => 'شيل التثبيت';

  @override
  String get commentsReport => 'بلّغ عنه';

  @override
  String get commentsModHide => 'خبّيه (مشرف)';

  @override
  String get commentsModUnhide => 'ظهّره (مشرف)';

  @override
  String get commentsModDelete => 'امسحه (مشرف)';

  @override
  String get commentsModDeleteTitle => 'تمسح التعليق ده عند الكل؟';

  @override
  String get commentsModDeleteBody =>
      'هيتشال عند كل القرّاء وهيتسجّل في سجل المراجعة.';

  @override
  String get commentsHidden => 'التعليق اتخبّى';

  @override
  String get commentsUnhidden => 'التعليق ظهر تاني';

  @override
  String get commentsReportTitle => 'بلّغ عن تعليق';

  @override
  String get commentsReportBody => 'بتبلّغ عنه ليه؟ المشرفين هيراجعوه.';

  @override
  String get commentsReportSpam => 'سبام';

  @override
  String get commentsReportMisinformation => 'معلومات غلط';

  @override
  String get commentsReportHarassment => 'إساءة أو تنمّر';

  @override
  String get commentsReportCopyright => 'حقوق ملكية';

  @override
  String get commentsReportOther => 'حاجة تانية';

  @override
  String get commentsReportDetails => 'تفاصيل (اختياري)';

  @override
  String get commentsReportSubmit => 'ابعت البلاغ';

  @override
  String get commentsReportThanks => 'شكراً، هنراجعه.';

  @override
  String get commentsErrRateLimited =>
      'انت بتعلّق بسرعة. استنى دقيقة وجرّب تاني.';

  @override
  String get commentsErrNotFound => 'التعليق ده مبقاش موجود.';

  @override
  String get commentsErrNotOwner => 'صاحب التعليق بس اللي يقدر يغيّره.';

  @override
  String get commentsErrNotAvailable => 'التعليق ده اتمسح أو اتخبّى.';

  @override
  String get commentsErrPinReply => 'التثبيت للتعليقات الأساسية بس، مش الردود.';

  @override
  String get commentsErrPinNotAuthor =>
      'كاتب المقال بس اللي يقدر يثبّت تعليقات.';

  @override
  String get commentsErrPinConflict =>
      'اتثبّت تعليق تاني في نفس الوقت. جرّب تاني.';

  @override
  String get commentsErrArticleLimit =>
      'علّقت كتير على المقال ده. جرّب تاني بعدين.';

  @override
  String get commentsErrDuplicate => 'انت لسه باعت نفس التعليق.';

  @override
  String get commentsErrEmpty => 'اكتب حاجة الأول.';

  @override
  String get commentsErrTooLong => 'التعليق آخره 2000 حرف.';

  @override
  String get commentsErrReportOwnContent => 'مينفعش تبلّغ عن تعليقك.';

  @override
  String get commentsErrReportNotSupported => 'مينفعش تبلّغ عن ده لسه.';

  @override
  String get commentsErrReportReason => 'اختار سبب.';

  @override
  String get myArticlesTitle => 'مقالاتي';

  @override
  String get myArticlesDrafts => 'المسودات';

  @override
  String get myArticlesPublished => 'المنشورة';

  @override
  String get myArticlesNew => 'مقال جديد';

  @override
  String get myArticlesEmptyDrafts => 'مفيش مسودات لسه';

  @override
  String get myArticlesEmptyDraftsBody =>
      'ابدأ مقال جديد، وهو بيتحفظ لوحده وانت بتكتب.';

  @override
  String get myArticlesEmptyPublished => 'لسه منشرتش حاجة';

  @override
  String get myArticlesEmptyPublishedBody => 'المقالات اللي هتنشرها هتظهر هنا.';

  @override
  String get untitledArticle => 'بدون عنوان';

  @override
  String get unpublishedChanges => 'تعديلات متنشرتش';

  @override
  String myArticleEdited(String date) {
    return 'اتعدّل $date';
  }

  @override
  String myArticlePublishedOn(String date) {
    return 'اتنشر $date';
  }

  @override
  String get deleteArticleTitle => 'تمسح المقال ده؟';

  @override
  String get deleteDraftBody => 'المسودة هتتمسح خالص.';

  @override
  String get deletePublishedBody =>
      'القرّاء مش هيشوفوه تاني، واللينك بتاعه هيبطل يفتح.';

  @override
  String get articleDeleted => 'المقال اتمسح';

  @override
  String get editorNewTitle => 'مقال جديد';

  @override
  String get editorEditTitle => 'تعديل المقال';

  @override
  String get editorTitleHint => 'العنوان';

  @override
  String get editorSubtitleHint => 'عنوان فرعي (اختياري)';

  @override
  String get editorStartWriting => 'اكتب هنا، أو اكتب / عشان تضيف بلوك';

  @override
  String get saveStatusSaving => 'جاري الحفظ…';

  @override
  String get saveStatusSaved => 'اتحفظ';

  @override
  String get saveStatusOffline => 'مفيش نت، اتحفظ على الجهاز';

  @override
  String get saveStatusFailed => 'معرفناش نحفظ';

  @override
  String get saveStatusUnsaved => 'لسه متحفظش';

  @override
  String get editorPublish => 'انشر';

  @override
  String get editorUpdate => 'حدّث';

  @override
  String get editorPublishing => 'بننشر…';

  @override
  String get editorPublishedMessage => 'اتنشر';

  @override
  String get editorUpdatedMessage => 'اتحدّث';

  @override
  String get editorPreview => 'معاينة';

  @override
  String get editorSettings => 'إعدادات المقال';

  @override
  String get editorRevisions => 'النسخ السابقة';

  @override
  String get editorDiscardChanges => 'الغي التعديلات';

  @override
  String get editorDelete => 'امسح المقال';

  @override
  String get editorMore => 'المزيد';

  @override
  String get discardChangesTitle => 'تلغي التعديلات اللي متنشرتش؟';

  @override
  String get discardChangesBody => 'المقال هيرجع زي ما القرّاء شايفينه دلوقتي.';

  @override
  String get discardAction => 'الغيها';

  @override
  String get changesDiscarded => 'التعديلات اتلغت';

  @override
  String get conflictTitle => 'المقال اتعدّل من مكان تاني';

  @override
  String get conflictBody =>
      'المقال ده اتغيّر من جهاز أو تاب تاني. عايز تكمّل بأنهي نسخة؟';

  @override
  String get conflictReload => 'حمّل النسخة المحفوظة';

  @override
  String get conflictKeepMine => 'خلّي نسختي';

  @override
  String get restoreBackupTitle => 'ترجّع التعديلات اللي متحفظتش؟';

  @override
  String restoreBackupBody(String time) {
    return 'الجهاز ده محتفظ بتعديلات من $time متحفظتش.';
  }

  @override
  String get restoreAction => 'رجّعها';

  @override
  String get discardBackupAction => 'مترجّعهاش';

  @override
  String get checksTitle => 'قبل ما تنشر';

  @override
  String get checksReady => 'جاهز للنشر';

  @override
  String checksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حاجة محتاجة تتظبط',
      few: '$count حاجات محتاجة تتظبط',
      two: 'حاجتين محتاجين يتظبطوا',
      one: 'حاجة واحدة محتاجة تتظبط',
    );
    return '$_temp0';
  }

  @override
  String get checksUploading => 'استنى لما الرفع يخلص.';

  @override
  String get problemFieldRequired => 'اختار المجال.';

  @override
  String get problemTitleLength => 'العنوان لازم يكون من 5 لـ 150 حرف.';

  @override
  String get problemContentEmpty => 'اكتب محتوى للمقال.';

  @override
  String get problemContentInvalid =>
      'في بلوكات مش مكتملة، زي خطوة من غير عنوان.';

  @override
  String get problemImageAlt => 'في صورة محتاجة وصف (alt text).';

  @override
  String get problemSourcesRequired => 'المجال ده محتاج مصدر واحد على الأقل.';

  @override
  String get problemAttachmentAlt => 'في صورة مرفقة محتاجة وصف (alt text).';

  @override
  String get problemAttachmentTitle => 'ملف الـ PDF محتاج عنوان.';

  @override
  String get problemAttachmentNotReady => 'في مرفق لسه بيترفع، أو رفعه فشل.';

  @override
  String get errDraftConflict => 'المقال ده اتعدّل من مكان تاني.';

  @override
  String get errNotPublished => 'المقال ده لسه متنشرش.';

  @override
  String get errRevisionNotFound => 'النسخة دي مبقتش موجودة.';

  @override
  String get articleVersionArabic => 'العربي';

  @override
  String get articleVersionEnglish => 'الإنجليزي';

  @override
  String get languageVersions => 'نسخ اللغات';

  @override
  String get sourceLanguageTag => 'الأصل';

  @override
  String get sourceLanguageHint =>
      'اللغة اللي هتكتب بيها الأول. غيّرها قبل ما تضيف ترجمة.';

  @override
  String addTranslation(String language) {
    return 'ضيف النسخة بـ$language';
  }

  @override
  String removeTranslation(String language) {
    return 'شيل النسخة بـ$language';
  }

  @override
  String get removeTranslationBody => 'العنوان والكلام بتوعها هيتمسحوا.';

  @override
  String get removeAction => 'شيل';

  @override
  String get topicLabel => 'الموضوع';

  @override
  String get topicNone => 'من غير موضوع';

  @override
  String get tagsLabel => 'الـ Tags';

  @override
  String get tagsHint => 'اكتب tag ودوس Enter';

  @override
  String tagsLimit(int count) {
    return '$count من 5';
  }

  @override
  String removeTag(String tag) {
    return 'شيل $tag';
  }

  @override
  String get coverLabel => 'صورة الغلاف';

  @override
  String get coverAdd => 'ضيف غلاف';

  @override
  String get coverChange => 'غيّر';

  @override
  String get coverRemove => 'شيل';

  @override
  String get coverHint => 'بتظهر على كارت المقال في الصفحة الرئيسية.';

  @override
  String get uploadingLabel => 'بنرفع…';

  @override
  String get versionBadgeLabel => 'شارة الإصدار';

  @override
  String get versionBadgeHint => 'مثلاً .NET 10';

  @override
  String get aiAssistedSwitch => 'اتكتب بمساعدة AI';

  @override
  String get aiAssistedSwitchHint =>
      'القرّاء هيشوفوا علامة «AI-assisted» على المقال.';

  @override
  String get blockParagraph => 'نص';

  @override
  String get blockHeading2 => 'عنوان';

  @override
  String get blockHeading3 => 'عنوان فرعي';

  @override
  String get blockBulletList => 'قايمة نقط';

  @override
  String get blockOrderedList => 'قايمة مرقّمة';

  @override
  String get blockSteps => 'خطوات';

  @override
  String get blockQuote => 'اقتباس';

  @override
  String get blockCallout => 'ملاحظة (Callout)';

  @override
  String get blockCode => 'كود';

  @override
  String get blockCodeTabs => 'كود بأكتر من لغة';

  @override
  String get blockTable => 'جدول';

  @override
  String get blockImage => 'صورة';

  @override
  String get blockDivider => 'فاصل';

  @override
  String get blockEmbed => 'YouTube أو Gist';

  @override
  String get blockSummary => 'الخلاصة (TL;DR)';

  @override
  String get addBlock => 'ضيف بلوك';

  @override
  String get blockOptions => 'خيارات البلوك';

  @override
  String get blockDirection => 'الاتجاه';

  @override
  String get dirAuto => 'تلقائي';

  @override
  String get dirRtl => 'من اليمين للشمال';

  @override
  String get dirLtr => 'من الشمال لليمين';

  @override
  String get moveUp => 'لفوق';

  @override
  String get moveDown => 'لتحت';

  @override
  String get deleteBlock => 'امسح البلوك';

  @override
  String get turnInto => 'حوّله لـ';

  @override
  String get calloutTip => 'نصيحة';

  @override
  String get calloutInfo => 'معلومة';

  @override
  String get calloutWarning => 'تحذير';

  @override
  String get calloutDanger => 'خطر';

  @override
  String get calloutTitleHint => 'عنوان (اختياري)';

  @override
  String get quoteCiteHint => 'مين قالها (اختياري)';

  @override
  String get codeFilenameHint => 'اسم الملف (اختياري)';

  @override
  String get codeHint => 'الكود';

  @override
  String get codeTabLabelHint => 'اسم التاب';

  @override
  String get addCodeTab => 'ضيف تاب';

  @override
  String get removeCodeTab => 'شيل التاب';

  @override
  String get tableAddRow => 'ضيف صف';

  @override
  String get tableAddColumn => 'ضيف عمود';

  @override
  String get tableRemoveRow => 'شيل آخر صف';

  @override
  String get tableRemoveColumn => 'شيل آخر عمود';

  @override
  String get stepTitleHint => 'عنوان الخطوة';

  @override
  String get stepContentHint => 'التفاصيل';

  @override
  String get addStep => 'ضيف خطوة';

  @override
  String get removeStep => 'شيل الخطوة';

  @override
  String get listItemHint => 'عنصر';

  @override
  String get imageChoose => 'اختار صورة';

  @override
  String get imageAltLabel => 'وصف الصورة (alt text) — مطلوب';

  @override
  String get imageAltHelp => 'اوصف الصورة للي مش قادر يشوفها.';

  @override
  String get imageCaptionLabel => 'تعليق (اختياري)';

  @override
  String get imageReplace => 'غيّر الصورة';

  @override
  String get embedUrlLabel => 'اللينك';

  @override
  String get embedInvalid => 'حط لينك YouTube أو GitHub Gist.';

  @override
  String get formatBold => 'عريض';

  @override
  String get formatItalic => 'مايل';

  @override
  String get formatCode => 'كود في السطر';

  @override
  String get formatHighlight => 'تظليل';

  @override
  String get formatStrike => 'شطب';

  @override
  String get formatLink => 'لينك';

  @override
  String get formatLineBreak => 'سطر جديد في نفس البلوك';

  @override
  String get formatMention => 'منشن لحد';

  @override
  String get linkDialogTitle => 'لينك';

  @override
  String get linkUrlLabel => 'اللينك (http أو https)';

  @override
  String get linkRemove => 'شيل اللينك';

  @override
  String get linkInvalid => 'استخدم لينك http أو https.';

  @override
  String get slashNoMatches => 'مفيش بلوك بالاسم ده';

  @override
  String get previewTitle => 'معاينة';

  @override
  String get previewInFeed => 'في الصفحة الرئيسية';

  @override
  String get previewLight => 'فاتح';

  @override
  String get previewDark => 'غامق';

  @override
  String get revisionsEmpty => 'لسه مفيش نسخ. كل نشر أو تحديث بيعمل نسخة.';

  @override
  String revisionLabel(int number) {
    return 'النسخة $number';
  }

  @override
  String get revisionFirst => 'أول نشر';

  @override
  String get revisionRestore => 'رجّع النسخة دي';

  @override
  String revisionRestoreTitle(int number) {
    return 'ترجّع النسخة $number؟';
  }

  @override
  String get revisionRestoreBody =>
      'هتحل محل اللي في المحرر دلوقتي. القرّاء مش هيشوفوها غير لما تدوس «حدّث».';

  @override
  String get revisionRestored => 'النسخة رجعت. دوس «حدّث» عشان تتنشر.';
}
