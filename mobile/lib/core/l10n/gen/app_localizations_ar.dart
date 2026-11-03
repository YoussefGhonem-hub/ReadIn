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
  String get badgeReviewed => 'مراجَع';

  @override
  String reviewedBy(String name) {
    return 'اتراجع بواسطة $name';
  }

  @override
  String lastReviewed(String date) {
    return 'آخر مراجعة: $date';
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
  String get articleLanguage => 'لغة المقال';

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
      'مقالات قصيرة ومراجَعة بالعربي والإنجليزي — واحدة بنختارهالك كل يوم في المجال اللي بتحبه.';

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
  String get composerTitle => 'منشور جديد';

  @override
  String get composerField => 'المجال';

  @override
  String get composerFieldHint => 'اختار المجال';

  @override
  String get composerTitleLabel => 'العنوان';

  @override
  String get composerTitleHint => 'عنوان واضح، من 5 لـ 150 حرف';

  @override
  String get composerBodyLabel => 'المنشور';

  @override
  String get composerBodyHint => 'سيب سطر فاضي بين كل فقرة والتانية.';

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
  String get composerPublish => 'انشر';

  @override
  String get composerPublishing => 'بننشر…';

  @override
  String get composerPublished => 'اتنشر ✨';

  @override
  String get composerNeedField => 'اختار المجال.';

  @override
  String get composerNeedTitle => 'اكتب عنوان (من 5 لـ 150 حرف).';

  @override
  String get composerNeedBody => 'اكتب حاجة أو ضيف مرفق.';

  @override
  String get composerNeedSources => 'ضيف مصدر واحد على الأقل.';

  @override
  String get composerFixSources => 'كمّل أو امسح المصادر الناقصة.';

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
  String get attachNeedAlt => 'اكتب وصف (Alt text) لكل صورة.';

  @override
  String get attachBusy => 'استنى لحد ما الرفع والتجهيز يخلصوا.';

  @override
  String get attachFailed => 'امسح المرفقات اللي فشلت أو جرّبها تاني.';

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
}
