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
  String get tagline => 'مقال كل يوم يُحدث فرقًا';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get done => 'تم';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get skip => 'تخطي';

  @override
  String get close => 'إغلاق';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get comingSoonTitle => 'قريبًا';

  @override
  String get comingSoonBody =>
      'نعمل على هذه الميزة الآن، وستصدر على التطبيق والويب في الوقت نفسه.';

  @override
  String get errorTitle => 'حدث خطأ';

  @override
  String get emptyTitle => 'لا يوجد شيء هنا بعد';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navExplore => 'استكشاف';

  @override
  String get navWrite => 'كتابة';

  @override
  String get navSaved => 'المحفوظات';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get navMore => 'المزيد';

  @override
  String get moreDarkMode => 'الوضع الداكن';

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
  String get greetingGuest => 'مرحبًا بك في ReadIn 👋';

  @override
  String get greetingSubtitle => 'مستعد لجرعة صغيرة من المعرفة؟';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: 'ابدأ سلسلة القراءة',
    );
    return '$_temp0';
  }

  @override
  String streakSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سلسلة القراءة: $count يوم',
      many: 'سلسلة القراءة: $count يومًا',
      few: 'سلسلة القراءة: $count أيام',
      two: 'سلسلة القراءة: يومان',
      one: 'سلسلة القراءة: يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get todayArticle => 'مقال اليوم';

  @override
  String get todayArticleCta => 'اقرأ الآن';

  @override
  String get feedForYou => 'لك';

  @override
  String get filterAll => 'الكل';

  @override
  String get feedEmptyTitle => 'لا توجد مقالات هنا بعد';

  @override
  String get feedEmptyBody => 'جرّب مجالًا آخر أو عُد لاحقًا.';

  @override
  String get feedNewArticles => 'مقالات جديدة ↑';

  @override
  String get endOfFeed => 'اطّلعت على كل الجديد ✨';

  @override
  String readingTime(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة للقراءة',
      many: '$minutes دقيقة للقراءة',
      few: '$minutes دقائق للقراءة',
      two: 'دقيقتان للقراءة',
      one: 'دقيقة للقراءة',
    );
    return '$_temp0';
  }

  @override
  String byAuthor(String name) {
    return 'بقلم $name';
  }

  @override
  String get aiAssisted => 'بمساعدة الذكاء الاصطناعي';

  @override
  String get verifiedWriter => 'كاتب موثّق';

  @override
  String get deletedUser => 'مستخدم محذوف';

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
  String get fontSizeXl => 'كبير جدًا';

  @override
  String get readingModeToggle => 'وضع القراءة';

  @override
  String get readingModeExit => 'الخروج من وضع القراءة';

  @override
  String get readingModeOn => 'تم تفعيل وضع القراءة.';

  @override
  String get readingModeOff => 'تم إيقاف وضع القراءة.';

  @override
  String get langToggleArEg => 'العربية + EN';

  @override
  String get langToggleEn => 'EN';

  @override
  String get articleLangArEg => 'العربية + مصطلحات إنجليزية';

  @override
  String get articleLangEn => 'الإنجليزية فقط';

  @override
  String get copyCode => 'نسخ الشيفرة';

  @override
  String get copied => 'تم النسخ';

  @override
  String get share => 'مشاركة';

  @override
  String get glossary => 'قاموس المصطلحات';

  @override
  String get glossaryInEnglish => 'بالإنجليزية';

  @override
  String get glossaryInArabic => 'بالعربية';

  @override
  String get glossaryArticles => 'مقالات تستخدم هذا المصطلح';

  @override
  String get glossaryNotFound => 'لم يُضف هذا المصطلح إلى القاموس بعد';

  @override
  String get relatedArticles => 'مقالات ذات صلة';

  @override
  String get resumePickedUp => 'تم الاستئناف من حيث توقفت';

  @override
  String get resumeStartOver => 'البدء من جديد';

  @override
  String get readingProgress => 'تقدّم القراءة';

  @override
  String get openLink => 'فتح الرابط';

  @override
  String embedOpen(String provider) {
    return 'فتح في $provider';
  }

  @override
  String get imageUnavailable => 'الصورة غير متاحة';

  @override
  String get onboardingWelcomeBody =>
      'مقالات قصيرة بالعربية والإنجليزية — نختار لك واحدًا منها كل يوم في المجال الذي تحبه.';

  @override
  String get browseAsGuest => 'التصفح كزائر';

  @override
  String stepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get interestsTitle => 'ما المجالات التي تهمّك؟';

  @override
  String get interestsSubtitle => 'اختر 3 على الأقل لنخصّص لك مقالك اليومي.';

  @override
  String interestsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اخترت $count',
      many: 'اخترت $count',
      few: 'اخترت $count',
      two: 'اخترت اثنين',
      one: 'اخترت واحدًا',
      zero: 'لم تختر شيئًا بعد',
    );
    return '$_temp0';
  }

  @override
  String get preferencesTitle => 'تفضيلاتك';

  @override
  String get preferencesSubtitle => 'يمكنك تغييرها في أي وقت من الإعدادات.';

  @override
  String get articleLanguageLabel => 'لغة المقالات';

  @override
  String get reminderTimeLabel => 'موعد التذكير اليومي';

  @override
  String get notificationsLabel => 'إشعار مقال اليوم';

  @override
  String get notificationsHint => 'سنطلب الإذن عند التفعيل.';

  @override
  String get notificationsBlocked => 'إشعارات ReadIn مُعطّلة في إعدادات هاتفك.';

  @override
  String notificationsUnread(int count) {
    return 'الإشعارات، $count جديدة';
  }

  @override
  String get finishOnboarding => 'ابدأ القراءة';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get password => 'كلمة المرور';

  @override
  String get displayName => 'الاسم';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get signInTitle => 'مرحبًا بعودتك';

  @override
  String get signInPromptTitle => 'سجّل الدخول للمتابعة';

  @override
  String get signInPromptBody =>
      'أنشئ حسابًا مجانيًا لحفظ المقالات ومتابعة الكتّاب والحفاظ على سلسلة القراءة.';

  @override
  String get fieldRequired => 'مطلوب';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get settings => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

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
  String get guestMode => 'أنت تتصفح كزائر';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get profileGuestTitle => 'ملفك الشخصي على ReadIn';

  @override
  String get profileGuestBody =>
      'سجّل الدخول لتبني سلسلة القراءة وتشارك ما تعرفه.';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get profileSyncFailed => 'تعذّر تحميل ملفك الشخصي.';

  @override
  String get profileTabArticles => 'المقالات';

  @override
  String get profileTabSaved => 'المحفوظات';

  @override
  String get profileTabPaths => 'المسارات التعليمية';

  @override
  String get profileTabAbout => 'عن الحساب';

  @override
  String get profileStatArticles => 'مقالات';

  @override
  String get profileStatFollowers => 'متابِعون';

  @override
  String get profileStatFollowing => 'متابَعون';

  @override
  String get profileStatReads => 'قراءات';

  @override
  String profileStatSemantics(String label, String value) {
    return '$label: $value';
  }

  @override
  String get profileOpenHint => 'يفتح الملف الشخصي';

  @override
  String profileOpenLink(String name) {
    return 'فتح $name';
  }

  @override
  String get profileGithub => 'GitHub';

  @override
  String get profileLinkedin => 'LinkedIn';

  @override
  String get profileWebsite => 'الموقع';

  @override
  String get profileLinks => 'الروابط';

  @override
  String get profileExpertise => 'مجالات الخبرة';

  @override
  String get profileAboutBio => 'نبذة';

  @override
  String get profileAboutEmpty => 'لا توجد تفاصيل بعد.';

  @override
  String get profileAboutEmptyOwn =>
      'أضف نبذة وروابطك والمجالات التي تكتب فيها ليتعرّف عليك القرّاء.';

  @override
  String profileJoined(String date) {
    return 'انضم في $date';
  }

  @override
  String get profileArticlesEmptyTitle => 'لا توجد مقالات بعد';

  @override
  String get profileArticlesEmptyBody => 'ستظهر هنا المقالات التي ينشرها.';

  @override
  String get profileArticlesEmptyOwnTitle => 'لم تنشر أي مقالات بعد';

  @override
  String get profileArticlesEmptyOwnBody =>
      'شارك ما تعرفه: ستظهر مقالاتك المنشورة هنا.';

  @override
  String get profileWriteFirst => 'كتابة مقال';

  @override
  String get profilePathsEmptyTitle => 'لا توجد مسارات بعد';

  @override
  String get profilePathsEmptyOwnBody =>
      'انضم إلى مسار تعليمي وسيظهر تقدّمك هنا.';

  @override
  String get profilePathsEmptyBody =>
      'ستظهر هنا المسارات التعليمية التي ينضم إليها.';

  @override
  String get profilePathsPrivateTitle => 'المسارات التعليمية خاصة';

  @override
  String get profilePathsPrivateBody => 'جعل هذا القارئ نشاط قراءته خاصًا.';

  @override
  String get profileNotFoundTitle => 'هذا الملف الشخصي غير متاح';

  @override
  String get profileNotFoundBody => 'ربما حُذف الحساب، أو أن الرابط غير صحيح.';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get profilePrivacy => 'الخصوصية';

  @override
  String get profilePublicReadingStats =>
      'عرض إحصائيات القراءة في ملفي الشخصي العام';

  @override
  String get profilePublicReadingStatsOn =>
      'يمكن للجميع رؤية سلسلة القراءة وإجمالي قراءاتك ونشاطك.';

  @override
  String get profilePublicReadingStatsOff => 'أنت وحدك من يرى إحصائيات قراءتك.';

  @override
  String get profileWhoCanMention => 'من يمكنه الإشارة إليّ';

  @override
  String get profileWhoCanMentionEveryone => 'الجميع';

  @override
  String get profileWhoCanMentionFollowing => 'الأشخاص الذين أتابعهم';

  @override
  String get profileWhoCanMentionNobody => 'لا أحد';

  @override
  String get profileReadingStatsEmpty => 'لا توجد مقالات مكتملة بعد.';

  @override
  String get profileReadingHeatmapEmpty => 'لا توجد أيام قراءة بعد.';

  @override
  String get profileBioLabel => 'نبذة';

  @override
  String get profileBioHint => 'ما مجال عملك؟ وعمَّ تكتب؟';

  @override
  String get profilePhotoGallery => 'الاختيار من صورك';

  @override
  String get profilePhotoCamera => 'التقاط صورة';

  @override
  String get profilePhotoPreview => 'صورة الملف الشخصي';

  @override
  String get profileExpertiseHint => 'اختر ما يصل إلى 5 مجالات تُتقنها.';

  @override
  String get profileExpertiseFull => 'اخترت 5. أزل واحدًا لتختار غيره.';

  @override
  String profileExpertiseCountSemantics(int count, int max) {
    return 'اخترت $count من $max';
  }

  @override
  String get profileFollowSearchHint => 'ابحث بالاسم أو اسم المستخدم';

  @override
  String get profileFollowNoResultsTitle => 'لا يوجد أحد بهذا الاسم';

  @override
  String get profileFollowNoResultsBody => 'جرّب اسمًا آخر أو اسم مستخدم آخر.';

  @override
  String get profileFollowersEmptyTitle => 'لا يوجد متابِعون بعد';

  @override
  String get profileFollowersEmptyOwnBody =>
      'يمكن للقرّاء الذين تعجبهم مقالاتك متابعتك.';

  @override
  String get profileFollowingEmptyTitle => 'لا يتابع أحدًا بعد';

  @override
  String get profileFollowingEmptyOwnBody =>
      'تابع الكتّاب لتصلك مقالاتهم الجديدة في الصفحة الرئيسية.';

  @override
  String get profileErrStatsPrivate => 'إحصائيات القراءة هذه خاصة.';

  @override
  String get profileErrAvatarInvalid =>
      'لا يمكن استخدام هذه الصورة. ارفع صورة أخرى.';

  @override
  String get profileErrExpertiseInvalid =>
      'اختر ما يصل إلى 5 من المجالات المدرجة في القائمة.';

  @override
  String get profileErrUrl => 'أدخل رابطًا كاملًا يبدأ بـ https://';

  @override
  String get profileHeadlineLabel => 'المسمى';

  @override
  String get profileHeadlineHint =>
      'مثلًا: Senior Full Stack .NET Engineer | .NET';

  @override
  String get profileHeadlineHelper => 'اختياري: سطر واحد يظهر تحت اسمك.';

  @override
  String get profileLinksSection => 'روابط';

  @override
  String get profileLinksHint => 'أضف ما يصل إلى 8 روابط لحساباتك.';

  @override
  String get profileLinksFull => 'أضفت 8 روابط. أزل واحدًا لتضيف غيره.';

  @override
  String profileLinksCountSemantics(int count, int max) {
    return 'الروابط: $count من $max';
  }

  @override
  String get profileLinkAdd => 'إضافة رابط';

  @override
  String get profileLinkPickPlatform => 'اختر المنصة';

  @override
  String get profileLinkPlatformAdded => 'مضاف بالفعل';

  @override
  String get profileLinkChangePlatform => 'تغيير المنصة';

  @override
  String get profileLinkUrl => 'الرابط';

  @override
  String get profileLinkLabel => 'اسم الرابط';

  @override
  String get profileLinkLabelHint => 'مثلًا: البودكاست الخاص بي';

  @override
  String get profileLinkOther => 'أخرى';

  @override
  String profileLinkOptions(String name) {
    return 'خيارات رابط $name';
  }

  @override
  String get profileLinkMoveUp => 'نقل لأعلى';

  @override
  String get profileLinkMoveDown => 'نقل لأسفل';

  @override
  String get profileLinkRemove => 'إزالة الرابط';

  @override
  String get profileTabReposts => 'إعادة النشر';

  @override
  String get profileRepostsEmptyTitle => 'لا توجد إعادات نشر بعد';

  @override
  String get profileRepostsEmptyBody => 'ستظهر هنا المقالات التي يعيد نشرها.';

  @override
  String get profileRepostsEmptyOwnTitle => 'لم تُعِد نشر أي مقال بعد';

  @override
  String get profileRepostsEmptyOwnBody =>
      'عندما تعيد نشر مقال أعجبك، سيظهر هنا ولدى متابعيك.';

  @override
  String get profileErrHeadlineTooLong => 'يجب ألا يتجاوز المسمى 120 حرفًا.';

  @override
  String get profileErrHeadlineInvalid =>
      'يجب أن يكون المسمى سطرًا واحدًا دون رموز خاصة.';

  @override
  String get profileErrLinkTooMany => 'يمكنك إضافة 8 روابط كحد أقصى.';

  @override
  String get profileErrLinkPlatformInvalid => 'اختر المنصة من القائمة.';

  @override
  String get profileErrLinkDuplicatePlatform => 'لديك رابط لهذه المنصة بالفعل.';

  @override
  String get profileErrLinkTooLong => 'يجب ألا يتجاوز الرابط 500 حرف.';

  @override
  String get profileErrLinkHttpsRequired => 'يجب أن يبدأ الرابط بـ https.';

  @override
  String get profileErrLinkUrlInvalid => 'هذا الرابط غير صالح.';

  @override
  String get profileErrLinkHostMismatch =>
      'هذا الرابط لا ينتمي إلى المنصة التي اخترتها.';

  @override
  String get profileErrLinkLabelRequired => 'اكتب اسمًا للرابط.';

  @override
  String get profileErrLinkLabelInvalid =>
      'يجب أن يتكون اسم الرابط من 2 إلى 30 حرفًا في سطر واحد.';

  @override
  String get profileErrLinkLabelNotAllowed =>
      'الاسم متاح فقط للروابط من نوع «أخرى».';

  @override
  String get moderationUserLinks => 'روابط الملف الشخصي';

  @override
  String get moderationUserNoLinks => 'لا توجد روابط.';

  @override
  String get moderationUserHeadline => 'المسمى';

  @override
  String get moderationUserNoHeadline => 'لا يوجد مسمى.';

  @override
  String get moderationClearLinks => 'إزالة الروابط';

  @override
  String moderationClearLinksTitle(String name) {
    return 'هل تريد إزالة كل روابط $name؟';
  }

  @override
  String get moderationClearLinksBody =>
      'ستُزال كل الروابط من ملفه الشخصي. لن يتلقى إشعارًا، وسيُسجَّل الإجراء.';

  @override
  String get moderationLinksCleared => 'تمت إزالة الروابط';

  @override
  String get moderationClearHeadline => 'إزالة المسمى';

  @override
  String moderationClearHeadlineTitle(String name) {
    return 'هل تريد إزالة مسمى $name؟';
  }

  @override
  String get moderationClearHeadlineBody =>
      'سيُزال المسمى الذي يظهر تحت اسمه من الملف الشخصي والبطاقات والتعليقات. لن يتلقى إشعارًا، وسيُسجَّل الإجراء.';

  @override
  String get moderationHeadlineCleared => 'تمت إزالة المسمى';

  @override
  String get moderationLogUserClearLinks => 'إزالة الروابط';

  @override
  String get moderationLogUserClearHeadline => 'إزالة المسمى';

  @override
  String notifArticleReposted(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'أعاد $name و$others شخص آخر نشر مقالك',
      many: 'أعاد $name و$others شخصًا آخر نشر مقالك',
      few: 'أعاد $name و$others أشخاص آخرين نشر مقالك',
      two: 'أعاد $name وشخصان آخران نشر مقالك',
      one: 'أعاد $name وشخص آخر نشر مقالك',
      zero: 'أعاد $name نشر مقالك',
    );
    return '$_temp0';
  }

  @override
  String get notificationTypeArticleReposted => 'إعادة النشر';

  @override
  String get notificationTypeArticleRepostedHint => 'عندما يعيد أحد نشر مقالك';

  @override
  String get pdfStripDownload => 'تنزيل ملف PDF';

  @override
  String get errValidation => 'يُرجى مراجعة الحقول المعلَّمة.';

  @override
  String get errUnauthorized => 'يُرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errForbidden => 'ليست لديك صلاحية لتنفيذ هذا الإجراء.';

  @override
  String get errSuspended => 'هذا الحساب موقوف. تواصل مع الدعم.';

  @override
  String get errNotSynced => 'تعذّر تجهيز حسابك. حاول مرة أخرى.';

  @override
  String get errUserNotFound => 'المستخدم غير موجود.';

  @override
  String get errUsernameTaken => 'اسم المستخدم هذا محجوز.';

  @override
  String get errInterestsMinThree => 'اختر 3 اهتمامات على الأقل.';

  @override
  String get errFieldNotFound => 'هذا المجال غير موجود.';

  @override
  String get errArticleNotFound => 'هذا المقال غير موجود أو تمت إزالته.';

  @override
  String get errServer => 'حدث خطأ من جانبنا. حاول مرة أخرى.';

  @override
  String get errOffline => 'أنت غير متصل بالإنترنت. تحقّق من اتصالك.';

  @override
  String get errTimeout => 'انتهت مهلة الاتصال. حاول مرة أخرى.';

  @override
  String get errInvalidCredentials => 'رقم الهاتف أو كلمة المرور غير صحيحة.';

  @override
  String get errTooManyRequests =>
      'طلبات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String get errCancelled => 'تم الإلغاء.';

  @override
  String get errSourcesRequired => 'أضف مصدرًا واحدًا على الأقل قبل النشر.';

  @override
  String get errMediaPurposeInvalid => 'نوع الرفع هذا غير مدعوم.';

  @override
  String get errMediaFileRequired => 'اختر ملفًا أولًا.';

  @override
  String get errMediaTooLarge =>
      'حجم هذا الملف كبير جدًا (ملف PDF حتى 20 م.ب، والصور حتى 10 م.ب).';

  @override
  String get errMediaUnsupportedType =>
      'نوع هذا الملف غير مدعوم. استخدم JPEG أو PNG أو WebP أو HEIC أو PDF.';

  @override
  String get errMediaDimensionsTooLarge =>
      'أبعاد هذه الصورة كبيرة جدًا (حتى 8000 × 8000 بكسل).';

  @override
  String get errMediaImageCorrupted =>
      'تعذّرت قراءة هذه الصورة. جرّب صورة أخرى.';

  @override
  String get errMediaPdfEncrypted =>
      'هذا الملف محمي بكلمة مرور. ارفعه دون كلمة مرور.';

  @override
  String get errMediaPdfCorrupted =>
      'تعذّرت قراءة ملف PDF هذا، فقد يكون تالفًا.';

  @override
  String get errMediaPdfTooManyPages =>
      'يحتوي ملف PDF هذا على أكثر من 100 صفحة.';

  @override
  String get errMediaQuotaDaily =>
      'وصلت إلى حد الرفع اليومي (50 ملفًا). حاول مرة أخرى غدًا.';

  @override
  String get errMediaQuotaStorage =>
      'امتلأت مساحة التخزين (200 م.ب). احذف ملفات قديمة لرفع المزيد.';

  @override
  String get errMediaNotFound => 'هذا الملف لم يعد موجودًا.';

  @override
  String get errMediaInUse => 'هذا الملف مرفق بمنشور.';

  @override
  String get errMediaDownloadNotAllowed => 'لم يسمح الكاتب بتنزيل هذا الملف.';

  @override
  String get errMediaProcessingFailed =>
      'تعذّر تجهيز هذا الملف. أزِله أو حاول مرة أخرى.';

  @override
  String get errMediaProcessingTimeout =>
      'استغرق تجهيز الملف وقتًا طويلًا. حاول مرة أخرى.';

  @override
  String get errAttachmentsMixedKinds =>
      'يمكن أن يحتوي المنشور على صور أو ملف PDF واحد، لا كليهما.';

  @override
  String get errAttachmentsTooManyImages => 'يمكنك إرفاق 10 صور كحد أقصى.';

  @override
  String get errAttachmentsSingleDocument => 'يمكنك إرفاق ملف PDF واحد فقط.';

  @override
  String get errAttachmentsAltTextRequired =>
      'تحتاج كل صورة إلى وصف (Alt text).';

  @override
  String get errAttachmentsAltTextTooLong =>
      'يجب ألا يتجاوز وصف الصورة 5000 حرف.';

  @override
  String get errAttachmentsCaptionTooLong =>
      'يجب ألا يتجاوز التعليق على الصورة 5000 حرف.';

  @override
  String get errAttachmentsTitleTooLong =>
      'يجب ألا يتجاوز عنوان الملف 5000 حرف.';

  @override
  String get errAttachmentsTitleRequired => 'يحتاج الملف إلى عنوان.';

  @override
  String get errAttachmentsAssetNotFound =>
      'أحد المرفقات غير موجود. أزِله وارفعه مرة أخرى.';

  @override
  String get errAttachmentsAssetNotReady =>
      'لا يزال أحد المرفقات قيد التجهيز. انتظر قليلًا.';

  @override
  String get errAttachmentsDuplicateAsset => 'الملف نفسه مرفق مرتين.';

  @override
  String get composerField => 'المجال';

  @override
  String get composerFieldHint => 'اختر المجال';

  @override
  String get composerSourcesRequired =>
      'يتطلب هذا المجال مصدرًا واحدًا على الأقل.';

  @override
  String get composerSourcesOptional =>
      'اختياري، لكن القرّاء يثقون أكثر بالمنشورات التي تتضمن مصادر.';

  @override
  String get composerAddSource => 'إضافة مصدر';

  @override
  String get composerAttachments => 'المرفقات';

  @override
  String get composerSourceTitle => 'اسم المصدر';

  @override
  String get composerSourceUrl => 'الرابط (https://…)';

  @override
  String get composerRemoveSource => 'إزالة المصدر';

  @override
  String get composerInvalidUrl => 'أدخل رابطًا صحيحًا يبدأ بـ http';

  @override
  String get attachImages => 'صور';

  @override
  String get attachPdf => 'ملف PDF';

  @override
  String get attachMixHint =>
      'يمكن أن يحتوي المنشور على صور أو ملف PDF واحد، لا كليهما.';

  @override
  String attachImagesLimit(int count) {
    return '$count من 10 صور';
  }

  @override
  String get attachReorderHint =>
      'اضغط مطولًا واسحب لإعادة الترتيب. انقر على صورة لإضافة وصف لها.';

  @override
  String get attachNeedDocTitle => 'اكتب عنوانًا للملف.';

  @override
  String get altTextLabel => 'وصف الصورة (مطلوب)';

  @override
  String get altTextHint => 'صِف الصورة لمستخدمي قارئ الشاشة';

  @override
  String get altTextMissing => 'الوصف مطلوب';

  @override
  String get altTextAdded => 'وصف ✓';

  @override
  String get altTextBadgeMissing => 'أضف وصفًا';

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
  String get moveEarlier => 'تقديمها';

  @override
  String get moveLater => 'تأخيرها';

  @override
  String get removeAttachment => 'إزالة';

  @override
  String get cancelUpload => 'إلغاء الرفع';

  @override
  String get uploadPreparing => 'جارٍ التجهيز…';

  @override
  String uploadProgress(int percent) {
    return 'جارٍ الرفع… $percent%';
  }

  @override
  String get uploadCancelled => 'تم إلغاء الرفع';

  @override
  String get uploadFailed => 'تعذّر الرفع';

  @override
  String fileSizeMb(String size) {
    return '$size م.ب';
  }

  @override
  String fileSizeKb(String size) {
    return '$size ك.ب';
  }

  @override
  String get pdfTitleLabel => 'عنوان الملف (مطلوب)';

  @override
  String get pdfAllowDownload => 'السماح بتنزيل الملف';

  @override
  String get pdfAllowDownloadHint => 'سيتمكن القرّاء من تنزيل ملف PDF الأصلي.';

  @override
  String get pdfPreparingPages => 'جارٍ تجهيز الصفحات…';

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
      two: 'صفحتان',
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
      two: '+صفحتان، افتح الملف',
      one: '+صفحة، افتح الملف',
    );
    return '$_temp0';
  }

  @override
  String get openDocument => 'فتح الملف';

  @override
  String get viewerDownload => 'تنزيل';

  @override
  String get viewerDownloading => 'جارٍ تنزيل الملف…';

  @override
  String viewerImageOf(int index, int total) {
    return 'صورة $index من $total';
  }

  @override
  String viewerPageOf(int index, int total) {
    return 'صفحة $index من $total';
  }

  @override
  String get viewerZoomHint => 'انقر مرتين للتكبير';

  @override
  String get viewerPageLoading => 'جارٍ تحميل الصفحة…';

  @override
  String get viewerThumbnails => 'الصفحات';

  @override
  String get welcomeSignIn => 'لديّ حساب، تسجيل الدخول';

  @override
  String switchLanguageTo(String language) {
    return 'تغيير لغة التطبيق إلى $language';
  }

  @override
  String get continueAction => 'متابعة';

  @override
  String get edit => 'تعديل';

  @override
  String get optional => 'اختياري';

  @override
  String get contactSupport => 'التواصل مع الدعم';

  @override
  String get signInSubtitle => 'سجّل الدخول برقم هاتفك وكلمة المرور.';

  @override
  String get authShowcaseField => 'التقنية';

  @override
  String get authShowcaseMinutes => 'قراءة في 5 دقائق';

  @override
  String get authShowcaseArticle => 'كيف تتعلّم النماذج اللغوية فعلًا؟';

  @override
  String get authShowcaseAuthor => 'سلمى إبراهيم';

  @override
  String get authShowcaseStreak => 'يومًا متتاليًا';

  @override
  String get authShowcaseQuote => 'القليل من القراءة كل يوم يصنع فرقًا كبيرًا.';

  @override
  String get authShowcaseHighlighted => 'ظلّلتَ هذه العبارة';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get createAccountLink => 'إنشاء حساب';

  @override
  String get passwordResetBanner =>
      'تم تغيير كلمة المرور. سجّل الدخول بكلمة المرور الجديدة.';

  @override
  String get sessionExpired => 'انتهت الجلسة. سجّل الدخول مرة أخرى.';

  @override
  String get signUpHeading => 'أنشئ حسابك';

  @override
  String get signUpCredentialsBody =>
      'ستسجّل الدخول بهذا الرقم وكلمة المرور. لن نرسل إليك رموز SMS أبدًا.';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get currentPasswordLabel => 'كلمة المرور الحالية';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String ruleMinLength(int count) {
    return '$count أحرف أو أكثر';
  }

  @override
  String get ruleLetter => 'حرف';

  @override
  String get ruleDigit => 'رقم';

  @override
  String get ruleMet => 'تم';

  @override
  String get ruleNotMet => 'لم يتم بعد';

  @override
  String passwordStrength(String level) {
    return 'قوة كلمة المرور: $level';
  }

  @override
  String get strengthWeak => 'ضعيفة';

  @override
  String get strengthFair => 'مقبولة';

  @override
  String get strengthGood => 'جيدة';

  @override
  String get strengthStrong => 'قوية';

  @override
  String get pinStepTitle => 'إنشاء رمز الاسترداد (PIN)';

  @override
  String get pinStepBody =>
      'إذا نسيت كلمة المرور، يتيح لك رقمك ورمز PIN هذا اختيار كلمة مرور جديدة. احفظه في مكان آمن ولا تشاركه مع أحد.';

  @override
  String get pinLabel => 'رمز الاسترداد (PIN)';

  @override
  String get confirmPinLabel => 'تأكيد رمز PIN';

  @override
  String get newPinLabel => 'رمز PIN الجديد';

  @override
  String get showPin => 'إظهار رمز PIN';

  @override
  String get hidePin => 'إخفاء رمز PIN';

  @override
  String pinSemantics(String label, int filled, int total) {
    return '$label، تم إدخال $filled من $total أرقام';
  }

  @override
  String get confirmNumberTitle => 'هل هذا رقمك؟';

  @override
  String get confirmNumberWarning =>
      'ستستخدم هذا الرقم لتسجيل الدخول، ولن تتمكن من استرداد حسابك إذا كان الرقم خاطئًا.';

  @override
  String get confirmNumberYes => 'موافق';

  @override
  String get confirmNumberChangeYes => 'موافق';

  @override
  String get confirmNumberAddYes => 'موافق';

  @override
  String get completeProfileTitle => 'أكمل ملفك الشخصي';

  @override
  String get completeProfileBody => 'هكذا سيراك القرّاء والكتّاب.';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get usernameHint => 'من 3 إلى 30 حرفًا: a–z أو 0–9 أو _';

  @override
  String get usernameChecking => 'جارٍ التحقق…';

  @override
  String usernameAvailable(String username) {
    return '@$username متاح';
  }

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get photoUploading => 'جارٍ رفع الصورة…';

  @override
  String get saveAndContinue => 'حفظ ومتابعة';

  @override
  String get forgotTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotStep1Body =>
      'أدخل رقمك ورمز الاسترداد (PIN) الذي أنشأته عند التسجيل.';

  @override
  String get forgotPin => 'هل نسيت رمز PIN أيضًا؟';

  @override
  String get forgotStep2Title => 'اختر كلمة مرور جديدة';

  @override
  String get forgotStep2Body => 'سيتم تسجيل الخروج من حسابك على جميع الأجهزة.';

  @override
  String get supportTitle => 'التواصل مع الدعم';

  @override
  String get supportBody =>
      'بدون رمز PIN، لا يستطيع إعادة تعيين كلمة المرور إلا فريق الدعم، بعد التحقق من أن الحساب يخصك. راسلنا عبر البريد الإلكتروني واذكر رقم حسابك، وبعد إعادة التعيين ستختار كلمة مرور ورمز PIN جديدين عند تسجيل الدخول.';

  @override
  String get supportEmailAction => 'مراسلة الدعم';

  @override
  String get copyEmail => 'نسخ البريد الإلكتروني';

  @override
  String get setPinTitle => 'إنشاء رمز الاسترداد (PIN)';

  @override
  String get setPinBody =>
      'يحتاج حسابك إلى رمز استرداد (PIN). يتيح لك مع رقمك اختيار كلمة مرور جديدة إذا نسيت كلمة المرور.';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get mustChangePasswordBody =>
      'تمت إعادة تعيين كلمة المرور. اختر كلمة مرور جديدة للمتابعة.';

  @override
  String get changePasswordBody => 'سيتم تسجيل الخروج من أجهزتك الأخرى.';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور.';

  @override
  String get changePinTitle => 'تغيير رمز PIN';

  @override
  String get changePinBody => 'أكّد بكلمة المرور، ثم اختر رمز PIN الجديد.';

  @override
  String get pinChanged => 'تم تغيير رمز الاسترداد (PIN).';

  @override
  String get changePhoneTitle => 'تغيير الرقم';

  @override
  String get changePhoneBody =>
      'ستسجّل الدخول بالرقم الجديد، وسيتم تسجيل الخروج من أجهزتك الأخرى.';

  @override
  String get newPhoneLabel => 'رقم الهاتف الجديد';

  @override
  String get phoneChanged => 'تم تغيير الرقم.';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get phoneVisibleToYou => 'لا يراه أحد غيرك';

  @override
  String get changePhone => 'تغيير الرقم';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get changePin => 'تغيير رمز PIN';

  @override
  String get signOutEverywhere => 'تسجيل الخروج من جميع الأجهزة';

  @override
  String get signOutEverywhereTitle => 'هل تريد تسجيل الخروج من جميع الأجهزة؟';

  @override
  String get signOutEverywhereConfirm => 'موافق';

  @override
  String get signOutEverywhereBody =>
      'سيتم تسجيل الخروج من جميع أجهزتك الأخرى، وستبقى مسجّلًا الدخول على هذا الجهاز.';

  @override
  String get signedOutEverywhere => 'تم تسجيل الخروج من جميع الأجهزة الأخرى.';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountTitle => 'حذف حسابك';

  @override
  String get deleteAccountLead =>
      'سيؤدي هذا إلى حذف حسابك على ReadIn نهائيًا. لا يمكنك التراجع عن ذلك، ولن نتمكن من استعادته.';

  @override
  String get deleteAccountDeletedHeading => 'ما نحذفه فورًا';

  @override
  String get deleteAccountDeletedProfile =>
      'ملفك الشخصي: الاسم واسم المستخدم والصورة والمسمى والنبذة والروابط';

  @override
  String get deleteAccountDeletedContact =>
      'رقم هاتفك وبريدك الإلكتروني وكلمة المرور ورمز الاسترداد';

  @override
  String get deleteAccountDeletedSignIns =>
      'ربط حسابك بـ Google وApple، كما نُلغي صلاحية وصول ReadIn لدى Apple.';

  @override
  String get deleteAccountDeletedDrafts =>
      'المسودات وأي مقال غير منشور، بما فيها من صور وملفات PDF، وأي صورة أو ملف آخر رفعته';

  @override
  String get deleteAccountDeletedActivity =>
      'اهتماماتك وتقدّمك في القراءة وإحصائياتك، وتفاعلاتك وإعادات نشرك والمقاطع التي ميّزتها وإعجاباتك بالتعليقات والبلاغات التي أرسلتها، والمقالات المحفوظة والمجموعات، وفئات مقالاتك (تبقى مقالاتك المنشورة بلا فئة)، ومن تتابعهم ومن يتابعونك، والكتّاب والمجالات والمواضيع التي كتمتها (وكتم الآخرين لك)، واختياراتك «عرض أقل من هذا النوع»';

  @override
  String get deleteAccountDeletedDevices =>
      'أجهزتك ورموز الإشعارات، فلن يصلك أي إشعار';

  @override
  String get deleteAccountDeletedSecurityLog =>
      'سجل أمان حسابك: عمليات تسجيل الدخول وتغييرات الحساب';

  @override
  String get deleteAccountKeptHeading => 'ما نحتفظ به، ولماذا';

  @override
  String get deleteAccountKeptPublished =>
      'تبقى مقالاتك المنشورة وتعليقاتك ظاهرةً باسم «مستخدم محذوف»، بما فيها من صور وملفات PDF: دون اسمك أو اسم المستخدم أو صورتك، ودون أي شيء يربطها بك. يضمن ذلك استمرار عمل الروابط والنقاشات التي يعتمد عليها القرّاء الآخرون. إذا أردت إزالة مقال، فاحذفه قبل حذف حسابك.';

  @override
  String get deleteAccountKeptRecord =>
      'سجلّ بحذف هذا الحساب: معرّفه الداخلي ووقت الحذف فقط، دون أي شيء يكشف هويتك. وهو يُثبت أن الحذف قد تم.';

  @override
  String get deleteAccountKeptBackups =>
      'قد تبقى بياناتك في النسخ الاحتياطية لقاعدة البيانات لمدة تصل إلى 14 يومًا، إلى أن تُمحى.';

  @override
  String get deleteAccountKeptReviews =>
      'تبقى تعديلاتك على مقالات الكتّاب الآخرين ضمن تلك المقالات، دون اسمك.';

  @override
  String get deleteAccountAfter =>
      'بعد الحذف، يمكن استخدام رقم الهاتف أو البريد الإلكتروني أو حساب Google أو Apple نفسه لإنشاء حساب جديد على ReadIn، وسيبدأ فارغًا.';

  @override
  String get deleteAccountByEmail => 'الحذف عبر البريد الإلكتروني بدلًا من ذلك';

  @override
  String get deleteAccountPasswordBody => 'أدخل كلمة المرور لحذف حسابك.';

  @override
  String get deleteAccountProviderBody =>
      'سجّل الدخول مرة أخرى بالحساب المرتبط بـ ReadIn.';

  @override
  String get confirmWithGoogle => 'التأكيد عبر Google';

  @override
  String get confirmWithApple => 'التأكيد عبر Apple';

  @override
  String get confirmedWithGoogle => 'تم التأكيد عبر Google';

  @override
  String get confirmedWithApple => 'تم التأكيد عبر Apple';

  @override
  String get deleteAccountAppleUnavailable =>
      'هذا الحساب مرتبط بـ Apple. أكّد هويتك عبر Apple من تطبيق ReadIn على iPhone، أو راسلنا عبر البريد الإلكتروني لحذفه.';

  @override
  String get deleteAccountConfirm => 'أفهم ذلك، احذف حسابي';

  @override
  String get deleteAccountButton => 'حذف حسابي';

  @override
  String get deletingAccount => 'جارٍ حذف حسابك…';

  @override
  String get deleteAccountDialogTitle => 'هل تريد حذف حسابك نهائيًا؟';

  @override
  String get deleteAccountDialogBody => 'لا يمكن التراجع عن هذه الخطوة.';

  @override
  String get deleteAccountDialogConfirm => 'موافق';

  @override
  String get deleteAccountOffline =>
      'أنت غير متصل بالإنترنت. اتصل بالإنترنت أولًا لحذف حسابك.';

  @override
  String get accountDeleted => 'تم حذف حسابك.';

  @override
  String get countryPickerTitle => 'اختر الدولة';

  @override
  String get countrySearchHint => 'ابحث بالاسم أو الرمز أو مفتاح الاتصال';

  @override
  String get countryNoResults => 'لا توجد دولة تطابق بحثك';

  @override
  String countryButtonSemantics(String country, String dialCode) {
    return 'الدولة: $country، +$dialCode. اضغط مرتين للتغيير';
  }

  @override
  String get selected => 'مختارة';

  @override
  String get devLoginOpen => 'حسابات تجريبية';

  @override
  String get devLoginTitle => 'حسابات تجريبية (dev فقط)';

  @override
  String get devLoginBody =>
      'مستخدمو seed المحليون. إذا كان DEV_DEMO_PASSWORD محددًا، تسجّل الضغطة الدخول مباشرةً؛ وإلا فإنها تُدخل الرقم فقط.';

  @override
  String get devLoginHasPin => 'لديه رمز PIN';

  @override
  String get devLoginNoPin => 'ليس لديه رمز PIN';

  @override
  String get devLoginSuspended => 'موقوف';

  @override
  String get errPhoneInvalid => 'رقم الهاتف هذا غير صحيح.';

  @override
  String get errPhoneTaken => 'يوجد حساب مسجّل بهذا الرقم بالفعل.';

  @override
  String get errPhoneUnchanged => 'هذا هو رقمك الحالي بالفعل.';

  @override
  String get errLockedOut => 'محاولات كثيرة جدًا. حاول مرة أخرى بعد 15 دقيقة.';

  @override
  String get errWrongPassword => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get errRecoveryInvalid => 'رقم الهاتف أو رمز PIN غير صحيح.';

  @override
  String get errRecoveryLocked => 'محاولات كثيرة جدًا. حاول مرة أخرى بعد ساعة.';

  @override
  String get errRecoveryDisabled =>
      'الاسترداد معطّل لهذا الحساب. تواصل مع الدعم.';

  @override
  String get errResetTokenInvalid => 'انتهت المهلة. ابدأ من جديد.';

  @override
  String get errPinAlreadySet =>
      'لديك رمز PIN بالفعل. يمكنك تغييره من الإعدادات.';

  @override
  String get errUsernameInvalid => 'استخدم من 3 إلى 30 حرفًا: a–z أو 0–9 أو _.';

  @override
  String get errPasswordTooShort => 'كلمة المرور قصيرة جدًا.';

  @override
  String get errPasswordTooLong => 'كلمة المرور طويلة جدًا.';

  @override
  String get errPasswordLetterRequired => 'أضف حرفًا واحدًا على الأقل.';

  @override
  String get errPasswordDigitRequired => 'أضف رقمًا واحدًا على الأقل.';

  @override
  String get errPasswordTooCommon =>
      'كلمة المرور هذه شائعة جدًا. اختر كلمة مرور أخرى.';

  @override
  String get errPasswordContainsPhone =>
      'لا يمكن أن تحتوي كلمة المرور على رقم هاتفك.';

  @override
  String get errPasswordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get errPinLength => 'أدخل جميع الأرقام.';

  @override
  String get errPinDigitsOnly => 'أرقام فقط.';

  @override
  String get errPinMismatch => 'رمزا PIN غير متطابقين.';

  @override
  String get errTooShort => 'قصير جدًا.';

  @override
  String get errTooLong => 'طويل جدًا.';

  @override
  String get errInvalidValue => 'راجع هذا الحقل.';

  @override
  String get orDivider => 'أو';

  @override
  String get continueWithGoogle => 'المتابعة عبر Google';

  @override
  String get continueWithApple => 'المتابعة عبر Apple';

  @override
  String get externalNotLinkedTitle =>
      'لا يوجد حساب ReadIn مرتبط بهذا الحساب حتى الآن';

  @override
  String get externalNotLinkedBody =>
      'أنشئ حسابًا جديدًا، أو اربطه بحسابك الحالي المسجّل برقم هاتفك.';

  @override
  String get externalCreateAccount => 'إنشاء حساب جديد';

  @override
  String get externalLinkExisting => 'لديّ حساب برقم هاتف';

  @override
  String get linkAccountTitle => 'ربط حسابك';

  @override
  String linkAccountBody(String provider) {
    return 'سجّل الدخول برقمك وكلمة المرور مرة واحدة، وبعدها يمكنك تسجيل الدخول عبر $provider أيضًا.';
  }

  @override
  String get linkAccountButton => 'الربط وتسجيل الدخول';

  @override
  String get linkedAccounts => 'الحسابات المرتبطة';

  @override
  String get linkAction => 'ربط';

  @override
  String get unlinkAction => 'إلغاء الربط';

  @override
  String get unlinkConfirm => 'موافق';

  @override
  String get notLinked => 'غير مرتبط';

  @override
  String unlinkTitle(String provider) {
    return 'هل تريد إلغاء ربط $provider؟';
  }

  @override
  String unlinkBody(String provider) {
    return 'لن تتمكن من تسجيل الدخول بـ $provider حتى تربطه مرة أخرى.';
  }

  @override
  String providerLinked(String provider) {
    return 'تم ربط $provider';
  }

  @override
  String providerUnlinked(String provider) {
    return 'تم إلغاء ربط $provider';
  }

  @override
  String get confirmItsYou => 'تأكيد هويتك';

  @override
  String linkWithPasswordBody(String provider) {
    return 'أدخل كلمة المرور لربط $provider.';
  }

  @override
  String get confirmAction => 'تأكيد';

  @override
  String get addPhoneSignIn => 'إضافة رقم هاتف وكلمة مرور';

  @override
  String addPhoneSignInBody(String provider) {
    return 'ستتمكن أيضًا من تسجيل الدخول برقمك وكلمة المرور، واستخدام رمز الاسترداد (PIN) إذا نسيت كلمة المرور. ستؤكّد هويتك عبر $provider في النهاية.';
  }

  @override
  String get phoneSignInAdded => 'تمت إضافة رقم الهاتف وكلمة المرور';

  @override
  String get errExternalNotLinked =>
      'لا يوجد حساب ReadIn مرتبط بهذا الحساب حتى الآن.';

  @override
  String get errExternalInvalid => 'تعذّر التحقق من هذا الحساب. حاول مرة أخرى.';

  @override
  String get errProviderDisabled => 'طريقة تسجيل الدخول هذه غير متاحة حاليًا.';

  @override
  String get errExternalConflict => 'يوجد حساب آخر من النوع نفسه مرتبط بالفعل.';

  @override
  String get errExternalInUse =>
      'حساب Google أو Apple هذا مرتبط بحساب ReadIn آخر.';

  @override
  String get errExternalMismatch => 'أكّد هويتك بحساب مرتبط بحسابك على ReadIn.';

  @override
  String get errExternalLoginNotFound => 'هذا الحساب غير مرتبط.';

  @override
  String get errConfirmationRequired => 'أكّد هويتك أولًا.';

  @override
  String get errLastSignInMethod =>
      'هذه هي طريقة تسجيل الدخول الوحيدة لديك. أضف طريقة أخرى أولًا.';

  @override
  String get errPhoneSignInExists => 'حسابك مرتبط برقم هاتف وكلمة مرور بالفعل.';

  @override
  String get errProviderInvalid => 'طريقة تسجيل الدخول هذه غير مدعومة.';

  @override
  String get errExternalProviderFailed =>
      'لم يكتمل تسجيل الدخول عبر Google أو Apple. حاول مرة أخرى.';

  @override
  String readingStreakNotReadTodaySemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سلسلة القراءة: $count يوم. لم تقرأ اليوم بعد.',
      many: 'سلسلة القراءة: $count يومًا. لم تقرأ اليوم بعد.',
      few: 'سلسلة القراءة: $count أيام. لم تقرأ اليوم بعد.',
      two: 'سلسلة القراءة: يومان. لم تقرأ اليوم بعد.',
      one: 'سلسلة القراءة: يوم واحد. لم تقرأ اليوم بعد.',
    );
    return '$_temp0';
  }

  @override
  String readingStreakFreezePendingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'سلسلة القراءة: $count يوم. فاتك يوم أمس: اقرأ اليوم وسيحافظ التجميد على سلسلتك.',
      many:
          'سلسلة القراءة: $count يومًا. فاتك يوم أمس: اقرأ اليوم وسيحافظ التجميد على سلسلتك.',
      few:
          'سلسلة القراءة: $count أيام. فاتك يوم أمس: اقرأ اليوم وسيحافظ التجميد على سلسلتك.',
      two:
          'سلسلة القراءة: يومان. فاتك يوم أمس: اقرأ اليوم وسيحافظ التجميد على سلسلتك.',
      one:
          'سلسلة القراءة: يوم واحد. فاتك يوم أمس: اقرأ اليوم وسيحافظ التجميد على سلسلتك.',
    );
    return '$_temp0';
  }

  @override
  String get readingStatsTitle => 'إحصائيات القراءة';

  @override
  String get readingCurrentStreak => 'السلسلة الحالية';

  @override
  String get readingLongestStreak => 'أطول سلسلة';

  @override
  String readingDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '0 يوم',
    );
    return '$_temp0';
  }

  @override
  String get readingFreezeAvailable =>
      'لديك تجميد جاهز: إذا فاتك يوم، فلن تنقطع سلسلتك.';

  @override
  String get readingFreezePending =>
      'فاتك يوم أمس. اقرأ اليوم وسيحافظ التجميد على سلسلتك.';

  @override
  String get readingFreezeUsed =>
      'تم استخدام التجميد. ستحصل على تجميد جديد خلال 7 أيام.';

  @override
  String get readingLast7Days => 'آخر 7 أيام';

  @override
  String get readingLast30Days => 'آخر 30 يومًا';

  @override
  String get readingAllTime => 'منذ البداية';

  @override
  String readingArticlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقالًا',
      few: '$count مقالات',
      two: 'مقالان',
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
      few: '$count دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get readingTopFields => 'المجالات الأكثر قراءة';

  @override
  String readingTopFieldSemantics(String field, String articles) {
    return '$field: $articles';
  }

  @override
  String get readingStatsEmpty =>
      'أكمل قراءة مقال حتى نهايته لتبدأ سلسلة قراءتك.';

  @override
  String get readingActivity => 'نشاط القراءة';

  @override
  String get readingLast12Months => 'آخر 12 شهرًا';

  @override
  String get readingHeatmapLess => 'أقل';

  @override
  String get readingHeatmapMore => 'أكثر';

  @override
  String get readingHeatmapFreeze => 'تجميد';

  @override
  String readingHeatmapSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم من القراءة',
      many: '$count يومًا من القراءة',
      few: '$count أيام من القراءة',
      two: 'يومان من القراءة',
      one: 'يوم قراءة واحد',
      zero: 'لا توجد أيام قراءة بعد',
    );
    return 'نشاط القراءة في آخر 12 شهرًا: $_temp0';
  }

  @override
  String readingHeatmapDay(String date, String articles) {
    return '$date: $articles';
  }

  @override
  String readingHeatmapFrozenDay(String date) {
    return '$date: حافظ التجميد على سلسلتك';
  }

  @override
  String get readingHeatmapEmpty => 'سيظهر هنا كل يوم تُنهي فيه قراءة مقال.';

  @override
  String readingDaysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم على التوالي',
      many: 'يومًا على التوالي',
      few: 'أيام على التوالي',
      two: 'يومان على التوالي',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get readingMilestoneWeekTitle => 'أسبوع كامل!';

  @override
  String get readingMilestoneWeekBody =>
      '7 أيام من القراءة على التوالي. واصل التقدّم!';

  @override
  String get readingMilestoneMonthTitle => 'شهر كامل من القراءة!';

  @override
  String get readingMilestoneMonthBody =>
      '30 يومًا على التوالي. أصبحت القراءة عادة حقيقية الآن.';

  @override
  String get readingMilestoneHundredTitle => '100 يوم!';

  @override
  String get readingMilestoneHundredBody =>
      '100 يوم على التوالي. لا يصل إلى هنا إلا قلّة من القرّاء.';

  @override
  String get readingMilestoneYearTitle => 'سنة كاملة!';

  @override
  String get readingMilestoneYearBody =>
      '365 يومًا من القراءة على التوالي. إنجاز أسطوري.';

  @override
  String readingMilestoneTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم على التوالي!',
      many: '$count يومًا على التوالي!',
      few: '$count أيام على التوالي!',
      two: 'يومان على التوالي!',
      one: 'يوم واحد!',
    );
    return '$_temp0';
  }

  @override
  String get readingMilestoneBody => 'واصل التقدّم!';

  @override
  String readingShareCardSemantics(int count) {
    return 'بطاقة ReadIn، أيام القراءة المتتالية: $count';
  }

  @override
  String get readingKeepReading => 'متابعة القراءة';

  @override
  String get readingShareFailed => 'تعذّرت مشاركة البطاقة. حاول مرة أخرى.';

  @override
  String get reactionInsightful => 'مفيد';

  @override
  String get reactionLove => 'أحببته';

  @override
  String get reactionFire => 'نار';

  @override
  String get reactionMindBlown => 'مبهر';

  @override
  String get reactAction => 'التفاعل بـ 💡 مفيد';

  @override
  String removeReaction(String reaction) {
    return 'إزالة تفاعلك ($reaction)';
  }

  @override
  String get chooseReaction => 'اختر تفاعلًا';

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
      many: '$count تفاعلًا',
      few: '$count تفاعلات',
      two: 'تفاعلان',
      one: 'تفاعل واحد',
      zero: 'لا توجد تفاعلات بعد',
    );
    return '$_temp0';
  }

  @override
  String get whoReacted => 'التفاعلات';

  @override
  String get showWhoReacted => 'عرض من تفاعل';

  @override
  String get reactorsEmpty => 'لا توجد تفاعلات بعد';

  @override
  String reactorsEmptyType(String reaction) {
    return 'لم يتفاعل أحد بـ $reaction بعد';
  }

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعليق',
      many: '$count تعليقًا',
      few: '$count تعليقات',
      two: 'تعليقان',
      one: 'تعليق واحد',
      zero: 'لا توجد تعليقات بعد',
    );
    return '$_temp0';
  }

  @override
  String get saveArticle => 'حفظ';

  @override
  String get unsaveArticle => 'إزالة من المحفوظات';

  @override
  String get articleSaved =>
      'تم الحفظ، ويمكنك قراءته دون اتصال بالإنترنت أيضًا.';

  @override
  String get articleUnsaved => 'تمت الإزالة من المحفوظات';

  @override
  String get undo => 'تراجع';

  @override
  String get redo => 'إعادة';

  @override
  String get moreActions => 'إجراءات أخرى';

  @override
  String get addToCollection => 'إضافة إلى مجموعة';

  @override
  String get collections => 'المجموعات';

  @override
  String get newCollection => 'مجموعة جديدة';

  @override
  String get collectionName => 'اسم المجموعة';

  @override
  String get collectionNameHint => 'مثلًا: التحضير لمقابلات العمل';

  @override
  String get createAction => 'إنشاء';

  @override
  String get renameAction => 'إعادة التسمية';

  @override
  String get renameCollection => 'إعادة تسمية المجموعة';

  @override
  String get deleteAction => 'حذف';

  @override
  String get deleteConfirm => 'موافق';

  @override
  String deleteCollectionTitle(String name) {
    return 'هل تريد حذف «$name»؟';
  }

  @override
  String get deleteCollectionBody =>
      'ستُحذف المجموعة، لكن مقالاتها ستبقى في المحفوظات.';

  @override
  String collectionArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقالًا',
      few: '$count مقالات',
      two: 'مقالان',
      one: 'مقال واحد',
      zero: 'لا توجد مقالات',
    );
    return '$_temp0';
  }

  @override
  String get collectionsEmptyTitle => 'لا توجد مجموعات بعد';

  @override
  String get collectionsEmptyBody =>
      'نظّم محفوظاتك في قوائم، مثل «التحضير لمقابلات العمل».';

  @override
  String addedToCollection(String name) {
    return 'تمت الإضافة إلى $name';
  }

  @override
  String removedFromCollection(String name) {
    return 'تمت الإزالة من $name';
  }

  @override
  String get removeFromCollection => 'إزالة من هذه المجموعة';

  @override
  String inCollection(String name) {
    return 'في $name';
  }

  @override
  String collectionFilter(String name) {
    return 'المجموعة: $name';
  }

  @override
  String get clearFilter => 'إلغاء التصفية';

  @override
  String openCollection(String name) {
    return 'عرض مقالات $name';
  }

  @override
  String get savedTabArticles => 'المقالات';

  @override
  String get savedSearchHint => 'ابحث في محفوظاتك';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get savedEmptyTitle => 'لم تحفظ شيئًا بعد';

  @override
  String get savedEmptyBody =>
      'اضغط على علامة الحفظ في أي مقال لحفظه هنا. تُفتح المقالات المحفوظة حتى دون اتصال بالإنترنت.';

  @override
  String get savedNoResultsTitle => 'لا توجد محفوظات مطابقة';

  @override
  String get savedNoResultsBody => 'جرّب كلمة أو مجالًا آخر.';

  @override
  String get savedCollectionEmptyTitle => 'هذه المجموعة فارغة';

  @override
  String get savedCollectionEmptyBody =>
      'أضف إليها مقالات من صفحة المقال أو من محفوظاتك.';

  @override
  String get savedOfflineBanner =>
      'أنت غير متصل بالإنترنت. هذه هي المقالات المحفوظة على هذا الجهاز.';

  @override
  String get offlineCopy => 'نسخة للقراءة دون اتصال، محفوظة على هذا الجهاز';

  @override
  String get savedGuestTitle => 'محفوظاتك';

  @override
  String get savedGuestBody =>
      'سجّل الدخول لحفظ المقالات وقراءتها لاحقًا، حتى دون اتصال بالإنترنت.';

  @override
  String get follow => 'متابعة';

  @override
  String get followingState => 'تتابعه';

  @override
  String followName(String name) {
    return 'متابعة $name';
  }

  @override
  String unfollowName(String name) {
    return 'إلغاء متابعة $name';
  }

  @override
  String get followsYou => 'يتابعك';

  @override
  String get feedFollowing => 'المتابَعون';

  @override
  String get followingEmptyTitle => 'تابع كتّابًا لتمتلئ هذه الصفحة';

  @override
  String get followingEmptyBody =>
      'ستظهر هنا المقالات الجديدة للكتّاب الذين تتابعهم، الأحدث أولًا.';

  @override
  String get suggestedWriters => 'كتّاب قد يعجبونك';

  @override
  String get suggestedWritersEmpty => 'لا توجد اقتراحات حاليًا. عُد لاحقًا.';

  @override
  String get showFollowingArticles => 'عرض مقالاتهم';

  @override
  String get followingGuestTitle => 'تابع الكتّاب الذين تحبهم';

  @override
  String get followingGuestBody =>
      'سجّل الدخول لمتابعة الكتّاب وقراءة مقالاتهم الجديدة هنا.';

  @override
  String get errReactionInvalid => 'هذا التفاعل غير متاح.';

  @override
  String get errCollectionNameTaken => 'لديك مجموعة بالاسم نفسه بالفعل.';

  @override
  String get errCollectionLimit => 'يمكنك إنشاء 50 مجموعة كحد أقصى.';

  @override
  String get errCollectionNotFound => 'هذه المجموعة لم تعد موجودة.';

  @override
  String get errFollowSelf => 'لا يمكنك متابعة نفسك.';

  @override
  String get commentsOpen => 'فتح التعليقات';

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
  String get commentsEmptyTitle => 'لا توجد تعليقات بعد';

  @override
  String get commentsEmptyBody => 'كن أول من يشارك رأيه.';

  @override
  String get commentsAuthorBadge => 'الكاتب';

  @override
  String get commentsPinned => 'مثبّت';

  @override
  String get commentsEdited => 'معدّل';

  @override
  String get commentsDeletedPlaceholder => 'تم حذف هذا التعليق';

  @override
  String get commentsHiddenPlaceholder => 'أخفى المشرفون هذا التعليق';

  @override
  String get commentsHiddenNotice =>
      'أخفى المشرفون هذا التعليق، ولا يراه إلا أنت والمشرفون.';

  @override
  String get commentsDeletedUser => 'مستخدم محذوف';

  @override
  String get commentsLike => 'إعجاب';

  @override
  String get commentsUnlike => 'إلغاء الإعجاب';

  @override
  String commentsLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إعجاب',
      many: '$count إعجابًا',
      few: '$count إعجابات',
      two: 'إعجابان',
      one: 'إعجاب واحد',
      zero: 'لا توجد إعجابات',
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
      other: 'عرض $count رد إضافي',
      many: 'عرض $count ردًا إضافيًا',
      few: 'عرض $count ردود إضافية',
      two: 'عرض ردّين إضافيين',
      one: 'عرض رد إضافي',
    );
    return '$_temp0';
  }

  @override
  String get commentsMoreRepliesAny => 'عرض المزيد من الردود';

  @override
  String get commentsHideReplies => 'إخفاء الردود';

  @override
  String get commentsRepliesFailed => 'تعذّر تحميل الردود.';

  @override
  String get commentsShowMore => 'عرض مزيد من التعليقات';

  @override
  String commentsNewPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعليق جديد',
      many: '$count تعليقًا جديدًا',
      few: '$count تعليقات جديدة',
      two: 'تعليقان جديدان',
      one: 'تعليق جديد',
    );
    return '$_temp0';
  }

  @override
  String get commentsSending => 'جارٍ الإرسال…';

  @override
  String get commentsTimeNow => 'الآن';

  @override
  String commentsTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String commentsTimeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String commentsTimeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'أمس',
    );
    return '$_temp0';
  }

  @override
  String get commentsComposerHint => 'اكتب تعليقًا…';

  @override
  String get commentsReplyHint => 'اكتب ردّك…';

  @override
  String get commentsSend => 'إرسال';

  @override
  String commentsReplyingTo(String name) {
    return 'ردًا على $name';
  }

  @override
  String get commentsEditing => 'تعديل تعليقك';

  @override
  String get commentsMentionSuggestions => 'أشخاص يمكنك الإشارة إليهم';

  @override
  String get commentsGuestPrompt => 'سجّل الدخول للمشاركة في النقاش.';

  @override
  String get commentsMenu => 'خيارات التعليق';

  @override
  String get commentsDeleteTitle => 'هل تريد حذف هذا التعليق؟';

  @override
  String get commentsDeleteBody =>
      'لا يمكن التراجع عن ذلك، وستبقى الردود عليه.';

  @override
  String get commentsDeleted => 'تم حذف التعليق';

  @override
  String get commentsPin => 'تثبيت';

  @override
  String get commentsUnpin => 'إلغاء التثبيت';

  @override
  String get commentsReport => 'إبلاغ';

  @override
  String get commentsModHide => 'إخفاء (مشرف)';

  @override
  String get commentsModUnhide => 'إظهار (مشرف)';

  @override
  String get commentsModDelete => 'حذف (مشرف)';

  @override
  String get commentsModDeleteTitle => 'هل تريد حذف هذا التعليق لدى الجميع؟';

  @override
  String get commentsModDeleteBody =>
      'سيُحذف لدى جميع القرّاء ويُسجَّل في سجل الإشراف.';

  @override
  String get commentsHidden => 'تم إخفاء التعليق';

  @override
  String get commentsUnhidden => 'تمت إعادة إظهار التعليق';

  @override
  String get commentsErrRateLimited =>
      'أنت تعلّق بسرعة كبيرة. انتظر دقيقة ثم حاول مرة أخرى.';

  @override
  String get commentsErrNotFound => 'هذا التعليق لم يعد موجودًا.';

  @override
  String get commentsErrNotOwner => 'يقتصر تعديل هذا التعليق على كاتبه.';

  @override
  String get commentsErrNotAvailable => 'تم حذف هذا التعليق أو إخفاؤه.';

  @override
  String get commentsErrPinReply =>
      'يمكن تثبيت التعليقات الرئيسية فقط، لا الردود.';

  @override
  String get commentsErrPinNotAuthor =>
      'يمكن لكاتب المقال وحده تثبيت التعليقات.';

  @override
  String get commentsErrPinConflict =>
      'تم تثبيت تعليق آخر في اللحظة نفسها. حاول مرة أخرى.';

  @override
  String get commentsErrArticleLimit =>
      'علّقت كثيرًا على هذا المقال. حاول مرة أخرى لاحقًا.';

  @override
  String get commentsErrDuplicate => 'نشرت التعليق نفسه للتو.';

  @override
  String get commentsErrEmpty => 'اكتب شيئًا أولًا.';

  @override
  String get commentsErrTooLong => 'الحد الأقصى للتعليق 2000 حرف.';

  @override
  String get commentsErrReportOwnContent => 'لا يمكنك الإبلاغ عن تعليقك.';

  @override
  String get commentsErrReportNotSupported =>
      'لا يمكن الإبلاغ عن هذا المحتوى بعد.';

  @override
  String get commentsErrReportReason => 'اختر سببًا.';

  @override
  String get myArticlesTitle => 'مقالاتي';

  @override
  String get myArticlesDrafts => 'المسودات';

  @override
  String get myArticlesPublished => 'المنشورة';

  @override
  String get myArticlesNew => 'مقال جديد';

  @override
  String get myArticlesEmptyDrafts => 'لا توجد مسودات بعد';

  @override
  String get myArticlesEmptyDraftsBody =>
      'ابدأ مقالًا جديدًا، وسيُحفظ تلقائيًا أثناء الكتابة.';

  @override
  String get myArticlesEmptyPublished => 'لم تنشر شيئًا بعد';

  @override
  String get myArticlesEmptyPublishedBody => 'ستظهر هنا المقالات التي تنشرها.';

  @override
  String get untitledArticle => 'بدون عنوان';

  @override
  String get unpublishedChanges => 'تعديلات غير منشورة';

  @override
  String myArticleEdited(String date) {
    return 'عُدّل $date';
  }

  @override
  String myArticlePublishedOn(String date) {
    return 'نُشر $date';
  }

  @override
  String get pdfDownload => 'تنزيل PDF';

  @override
  String get pdfPreparing => 'جارٍ تجهيز ملف PDF…';

  @override
  String get pdfRetry => 'إعادة المحاولة';

  @override
  String get pdfLanguageTitle => 'أي نسخة تريد؟';

  @override
  String get pdfLanguageBody =>
      'هذا المقال منشور بلغتين. اختر النسخة التي تريد تنزيلها بصيغة PDF.';

  @override
  String get errArticlePdfNotFound => 'المقال غير موجود.';

  @override
  String get errArticlePdfHidden =>
      'أخفى المشرفون هذا المقال، لذا لا يمكن تنزيله بصيغة PDF.';

  @override
  String get errArticlePdfLimit =>
      'نزّلت ملفات PDF كثيرة خلال هذه الساعة. حاول مرة أخرى لاحقًا.';

  @override
  String get errArticlePdfBusy =>
      'يجري الآن تجهيز ملفات PDF كثيرة. حاول مرة أخرى بعد قليل.';

  @override
  String get errArticlePdfFailed => 'تعذّر تجهيز ملف PDF. حاول مرة أخرى.';

  @override
  String get errArticlePdfOffline =>
      'تحتاج إلى اتصال بالإنترنت لتنزيل ملف PDF.';

  @override
  String get deleteArticleTitle => 'هل تريد حذف هذا المقال؟';

  @override
  String get deleteDraftBody => 'ستُحذف المسودة نهائيًا.';

  @override
  String get deletePublishedBody =>
      'لن يتمكن القرّاء من رؤيته بعد الآن، وسيتوقف رابطه عن العمل.';

  @override
  String get articleDeleted => 'تم حذف المقال';

  @override
  String get editorNewTitle => 'مقال جديد';

  @override
  String get editorEditTitle => 'تعديل المقال';

  @override
  String get editorTitleHint => 'العنوان';

  @override
  String get editorSubtitleHint => 'عنوان فرعي (اختياري)';

  @override
  String get editorStartWriting => 'اكتب هنا، أو اكتب / لإضافة عنصر';

  @override
  String get saveStatusSaving => 'جارٍ الحفظ…';

  @override
  String get saveStatusSaved => 'تم الحفظ';

  @override
  String get saveStatusOffline => 'غير متصل، تم الحفظ على هذا الجهاز';

  @override
  String get saveStatusFailed => 'تعذّر الحفظ';

  @override
  String get saveStatusUnsaved => 'لم يُحفظ بعد';

  @override
  String get editorPublish => 'نشر';

  @override
  String get editorUpdate => 'تحديث';

  @override
  String get editorPublishing => 'جارٍ النشر…';

  @override
  String get editorPublishedMessage => 'تم النشر';

  @override
  String get editorUpdatedMessage => 'تم التحديث';

  @override
  String get editorPreview => 'معاينة';

  @override
  String get editorSettings => 'إعدادات المقال';

  @override
  String get editorRevisions => 'النسخ السابقة';

  @override
  String get editorDiscardChanges => 'إلغاء التعديلات';

  @override
  String get editorDelete => 'حذف المقال';

  @override
  String get editorMore => 'المزيد';

  @override
  String get discardChangesTitle => 'هل تريد إلغاء التعديلات غير المنشورة؟';

  @override
  String get discardChangesBody =>
      'سيعود المقال إلى النسخة التي يراها القراء الآن.';

  @override
  String get discardAction => 'موافق';

  @override
  String get changesDiscarded => 'تم إلغاء التعديلات';

  @override
  String get conflictTitle => 'عُدّل هذا المقال من مكان آخر';

  @override
  String get conflictBody =>
      'تغيّر هذا المقال من جهاز أو علامة تبويب أخرى. على أي نسخة تريد متابعة العمل؟';

  @override
  String get conflictReload => 'تحميل النسخة المحفوظة';

  @override
  String get conflictKeepMine => 'الاحتفاظ بنسختي';

  @override
  String get restoreBackupTitle => 'هل تريد استعادة التعديلات غير المحفوظة؟';

  @override
  String restoreBackupBody(String time) {
    return 'يحتفظ هذا الجهاز بتعديلات غير محفوظة من $time.';
  }

  @override
  String get restoreAction => 'استعادة';

  @override
  String get discardBackupAction => 'عدم الاستعادة';

  @override
  String get checksTitle => 'قبل النشر';

  @override
  String get checksReady => 'جاهز للنشر';

  @override
  String checksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مشكلة تحتاج إلى إصلاح',
      few: '$count مشكلات تحتاج إلى إصلاح',
      two: 'مشكلتان تحتاجان إلى إصلاح',
      one: 'مشكلة واحدة تحتاج إلى إصلاح',
    );
    return '$_temp0';
  }

  @override
  String get checksUploading => 'انتظر حتى يكتمل الرفع.';

  @override
  String get problemFieldRequired => 'اختر المجال.';

  @override
  String get problemTitleLength => 'يجب أن يتكون العنوان من 5 إلى 150 حرفًا.';

  @override
  String get problemContentEmpty => 'اكتب محتوى للمقال.';

  @override
  String get problemContentInvalid =>
      'بعض العناصر غير مكتملة، مثل خطوة بلا عنوان.';

  @override
  String get problemImageAlt => 'إحدى الصور تحتاج إلى وصف (alt text).';

  @override
  String get problemSourcesRequired =>
      'يتطلب هذا المجال مصدرًا واحدًا على الأقل.';

  @override
  String get problemAttachmentAlt =>
      'إحدى الصور المرفقة تحتاج إلى وصف (alt text).';

  @override
  String get problemAttachmentTitle => 'يحتاج ملف PDF إلى عنوان.';

  @override
  String get problemAttachmentNotReady =>
      'أحد المرفقات لا يزال قيد الرفع، أو تعذّر رفعه.';

  @override
  String get errDraftConflict => 'تم تعديل هذا المقال من مكان آخر.';

  @override
  String get errNotPublished => 'لم يُنشر هذا المقال بعد.';

  @override
  String get errRevisionNotFound => 'هذه النسخة لم تعد موجودة.';

  @override
  String get articleVersionArabic => 'العربية';

  @override
  String get articleVersionEnglish => 'الإنجليزية';

  @override
  String get languageVersions => 'نسخ اللغات';

  @override
  String get sourceLanguageTag => 'الأصل';

  @override
  String get sourceLanguageHint =>
      'اللغة التي تكتب بها أولًا. غيّرها قبل إضافة ترجمة.';

  @override
  String addTranslation(String language) {
    return 'إضافة النسخة $language';
  }

  @override
  String removeTranslation(String language) {
    return 'إزالة النسخة $language';
  }

  @override
  String removeTranslationTitle(String language) {
    return 'هل تريد حذف النسخة $language؟';
  }

  @override
  String get removeTranslationBody => 'سيُحذف عنوانها ونصها.';

  @override
  String get removeAction => 'موافق';

  @override
  String get topicLabel => 'الموضوع';

  @override
  String get topicNone => 'دون موضوع';

  @override
  String get tagsLabel => 'الوسوم';

  @override
  String get tagsHint => 'اكتب وسمًا ثم اضغط Enter أو فاصلة';

  @override
  String tagsLimit(int count) {
    return '$count من 5';
  }

  @override
  String removeTag(String tag) {
    return 'إزالة $tag';
  }

  @override
  String get tagsFull =>
      'هذه 5 وسوم، وهو الحد الأقصى للمقال. أزل وسمًا لإضافة غيره.';

  @override
  String get tagsAdd => 'إضافة';

  @override
  String tagCreate(String name) {
    return 'إنشاء وسم جديد: $name';
  }

  @override
  String get tagSuggestionsLabel => 'وسوم مقترحة';

  @override
  String get tagAlreadyAdded => 'هذا الوسم مضاف إلى المقال بالفعل.';

  @override
  String get tagTooShort => 'يجب أن يتكون الوسم من حرفين على الأقل.';

  @override
  String get tagTooLong => 'يجب ألا يتجاوز الوسم 30 حرفًا.';

  @override
  String get tagInvalidCharacters =>
      'استخدم الحروف والأرقام والمسافات و ⁦- _ . + #⁩ فقط.';

  @override
  String get tagNoLetter => 'يجب أن يحتوي الوسم على حرف أو رقم واحد على الأقل.';

  @override
  String problemTagHidden(String name) {
    return 'الوسم $name غير متاح. أزله أو اختر وسمًا آخر.';
  }

  @override
  String problemTagLimit(String name) {
    return 'أنشأت وسومًا جديدة كثيرة اليوم، لذا لا يمكن إضافة الوسم $name الآن. اختر وسمًا موجودًا، أو حاول مرة أخرى لاحقًا.';
  }

  @override
  String get coverLabel => 'صورة الغلاف';

  @override
  String get coverAdd => 'إضافة غلاف';

  @override
  String get coverChange => 'تغيير';

  @override
  String get coverRemove => 'إزالة';

  @override
  String get coverHint => 'تظهر على بطاقة المقال في الصفحة الرئيسية.';

  @override
  String get uploadingLabel => 'جارٍ الرفع…';

  @override
  String get versionBadgeLabel => 'شارة الإصدار';

  @override
  String get versionBadgeHint => 'مثلًا .NET 10';

  @override
  String get aiAssistedSwitch => 'كُتب بمساعدة الذكاء الاصطناعي';

  @override
  String get aiAssistedSwitchHint =>
      'سيرى القرّاء علامة «بمساعدة الذكاء الاصطناعي» على المقال.';

  @override
  String get blockParagraph => 'نص';

  @override
  String get blockHeading2 => 'عنوان';

  @override
  String get blockHeading3 => 'عنوان فرعي';

  @override
  String get blockBulletList => 'قائمة نقطية';

  @override
  String get blockOrderedList => 'قائمة مرقّمة';

  @override
  String get blockSteps => 'خطوات';

  @override
  String get blockQuote => 'اقتباس';

  @override
  String get blockCallout => 'ملاحظة (Callout)';

  @override
  String get blockCode => 'شيفرة برمجية';

  @override
  String get blockCodeTabs => 'تبويبات الشيفرة';

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
  String get addBlock => 'إضافة عنصر';

  @override
  String get blockOptions => 'خيارات العنصر';

  @override
  String get blockDirection => 'الاتجاه';

  @override
  String get dirAuto => 'تلقائي';

  @override
  String get dirRtl => 'من اليمين إلى اليسار';

  @override
  String get dirLtr => 'من اليسار إلى اليمين';

  @override
  String get moveUp => 'نقل لأعلى';

  @override
  String get moveDown => 'نقل لأسفل';

  @override
  String get deleteBlock => 'حذف العنصر';

  @override
  String get turnInto => 'تحويل إلى';

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
  String get quoteCiteHint => 'اسم القائل (اختياري)';

  @override
  String get codeFilenameHint => 'اسم الملف (اختياري)';

  @override
  String get codeHint => 'الشيفرة';

  @override
  String get codeTabLabelHint => 'اسم التبويب';

  @override
  String get addCodeTab => 'إضافة تبويب';

  @override
  String get removeCodeTab => 'إزالة التبويب';

  @override
  String get tableAddRow => 'إضافة صف';

  @override
  String get tableAddColumn => 'إضافة عمود';

  @override
  String get tableDeleteRow => 'حذف الصف';

  @override
  String get tableDeleteColumn => 'حذف العمود';

  @override
  String get tableDelete => 'حذف الجدول';

  @override
  String get tableTools => 'الجدول';

  @override
  String get stepTitleHint => 'عنوان الخطوة';

  @override
  String get stepContentHint => 'التفاصيل';

  @override
  String get addStep => 'إضافة خطوة';

  @override
  String get removeStep => 'إزالة الخطوة';

  @override
  String get listItemHint => 'عنصر';

  @override
  String get imageChoose => 'اختيار صورة';

  @override
  String get imageAltLabel => 'وصف الصورة (alt text) — مطلوب';

  @override
  String get imageAltHelp => 'صِف الصورة لمن لا يستطيع رؤيتها.';

  @override
  String get imageCaptionLabel => 'تعليق (اختياري)';

  @override
  String get imageReplace => 'تغيير الصورة';

  @override
  String get embedUrlLabel => 'الرابط';

  @override
  String get embedInvalid => 'الصق رابط YouTube أو GitHub Gist.';

  @override
  String get formatBold => 'عريض';

  @override
  String get formatItalic => 'مائل';

  @override
  String get formatCode => 'شيفرة ضمن السطر';

  @override
  String get formatHighlight => 'تظليل';

  @override
  String get formatStrike => 'شطب';

  @override
  String get formatLink => 'رابط';

  @override
  String get formatLineBreak => 'سطر جديد داخل العنصر';

  @override
  String get formatMention => 'الإشارة إلى شخص';

  @override
  String get formatTerm => 'مصطلح من القاموس';

  @override
  String get termPickerFor => 'تعيينه مصطلحًا من القاموس:';

  @override
  String get termPickerCurrent => 'مصطلح من القاموس:';

  @override
  String get termSearchHint => 'ابحث في القاموس (المصطلح بالإنجليزية)';

  @override
  String get termSearching => 'جارٍ البحث…';

  @override
  String get termNoMatches =>
      'لا يوجد مصطلح مطابق في القاموس. جرّب المصطلح بالإنجليزية.';

  @override
  String get termTypeToSearch => 'اكتب مصطلحًا للبحث في القاموس.';

  @override
  String get termSearchError => 'تعذّر البحث في القاموس.';

  @override
  String get termRemove => 'إزالة المصطلح';

  @override
  String get linkDialogTitle => 'رابط';

  @override
  String get linkUrlLabel => 'الرابط (http أو https)';

  @override
  String get linkRemove => 'إزالة الرابط';

  @override
  String get linkInvalid => 'استخدم رابط http أو https.';

  @override
  String get slashNoMatches => 'لا يوجد عنصر بهذا الاسم';

  @override
  String get previewTitle => 'معاينة';

  @override
  String get previewInFeed => 'في الصفحة الرئيسية';

  @override
  String get previewLight => 'فاتح';

  @override
  String get previewDark => 'داكن';

  @override
  String get revisionsEmpty =>
      'لا توجد نسخ بعد. تُضاف نسخة مع كل نشر أو تحديث.';

  @override
  String revisionLabel(int number) {
    return 'النسخة $number';
  }

  @override
  String get revisionFirst => 'أول نشر';

  @override
  String get revisionRestore => 'استعادة هذه النسخة';

  @override
  String revisionRestoreTitle(int number) {
    return 'هل تريد استعادة النسخة $number؟';
  }

  @override
  String get revisionRestoreBody =>
      'ستحل محل ما في المحرر الآن، ولن يراها القرّاء إلا بعد الضغط على «تحديث».';

  @override
  String get revisionRestored => 'تمت استعادة النسخة. اضغط «تحديث» لنشرها.';

  @override
  String get errAppleConfirmationRequired =>
      'هذا الحساب مرتبط بـ Apple. أكّد هويتك عبر Apple لحذفه.';

  @override
  String get errDeletionUnavailable =>
      'تعذّر إكمال حذف حسابك، ولم يُحذف أي شيء. حاول مرة أخرى بعد بضع دقائق.';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String continueReadingProgress(int percent) {
    return 'تمت قراءة $percent%';
  }

  @override
  String get pathsTitle => 'المسارات التعليمية';

  @override
  String get pathsTabAll => 'كل المسارات';

  @override
  String get pathsTabMine => 'مساراتي';

  @override
  String get pathsPrompt => 'تعلّم خطوة بخطوة مع المسارات التعليمية';

  @override
  String get pathsBrowse => 'استكشاف المسارات';

  @override
  String get pathsEmptyTitle => 'لا توجد مسارات هنا بعد';

  @override
  String get pathsEmptyBody => 'نعمل على تجهيز أول المسارات. عُد قريبًا.';

  @override
  String get myPathsEmptyTitle => 'لم تبدأ أي مسار بعد';

  @override
  String get myPathsEmptyBody => 'اختر مسارًا وتعلّم موضوعًا مقالًا تلو الآخر.';

  @override
  String get myPathsGuestTitle => 'تابع مساراتك';

  @override
  String get myPathsGuestBody =>
      'أنشئ حسابًا مجانيًا لتنضم إلى المسارات وتتابع من حيث توقفت.';

  @override
  String pathArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقالًا',
      few: '$count مقالات',
      two: 'مقالان',
      one: 'مقال واحد',
    );
    return '$_temp0';
  }

  @override
  String pathMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String pathProgressSemantics(int read, int total) {
    return 'تمت قراءة $read من $total';
  }

  @override
  String get pathCompleted => 'مكتمل';

  @override
  String get pathCompletedCelebration => 'اكتمل المسار 🎉';

  @override
  String get pathStart => 'بدء المسار';

  @override
  String pathContinue(String title) {
    return 'متابعة: $title';
  }

  @override
  String get pathReadAgain => 'إعادة القراءة';

  @override
  String pathNext(String title) {
    return 'التالي: $title';
  }

  @override
  String get pathUpNext => 'التالي';

  @override
  String get pathItemRead => 'مقروء';

  @override
  String get pathMenu => 'خيارات المسار';

  @override
  String get pathLeave => 'مغادرة المسار';

  @override
  String get pathLeaveConfirm => 'موافق';

  @override
  String get pathLeaveTitle => 'هل تريد مغادرة هذا المسار؟';

  @override
  String get pathLeaveBody =>
      'سيبقى سجل قراءتك كما هو، وإذا انضممت إلى المسار مرة أخرى فستجد تقدمك محفوظًا.';

  @override
  String get pathLeft => 'غادرت المسار';

  @override
  String get pathJoin => 'الانضمام إلى المسار';

  @override
  String get pathJoined => 'انضممت إلى المسار';

  @override
  String pathFrom(String title) {
    return 'من مسار: $title';
  }

  @override
  String pathPosition(int position, int total) {
    return '$position من $total';
  }

  @override
  String get pathNextInPath => 'التالي في المسار';

  @override
  String get pathLastArticle => 'هذا آخر مقال في المسار';

  @override
  String get pathNotFoundTitle => 'هذا المسار غير متاح';

  @override
  String get pathNotFoundBody => 'ربما أُزيل، أو أن الرابط غير صحيح.';

  @override
  String get errPathNotFound => 'هذا المسار غير موجود أو أُزيل.';

  @override
  String get errPathSlugTaken => 'يستخدم مسار آخر هذا الرابط بالفعل.';

  @override
  String get errPathEditorial => 'تُدار المسارات التحريرية من ملفات المحتوى.';

  @override
  String get errPathItemsInvalid =>
      'راجع مقالات المسار: من 1 إلى 100 مقال منشور، وكل مقال مرة واحدة.';

  @override
  String get reportTitleArticle => 'الإبلاغ عن المقال';

  @override
  String get reportTitleComment => 'الإبلاغ عن التعليق';

  @override
  String get reportTitleUser => 'الإبلاغ عن المستخدم';

  @override
  String get reportBody => 'لماذا تُبلغ عن هذا؟ سيراجع فريق الإشراف البلاغ.';

  @override
  String get reportReasonSpam => 'محتوى غير مرغوب فيه';

  @override
  String get reportReasonMisinformation => 'معلومات خاطئة';

  @override
  String get reportReasonHarassment => 'إساءة أو تنمّر';

  @override
  String get reportReasonCopyright => 'حقوق النشر';

  @override
  String get reportReasonOther => 'سبب آخر';

  @override
  String get reportDetails => 'تفاصيل (اختياري)';

  @override
  String get reportSubmit => 'إرسال البلاغ';

  @override
  String get reportThanks => 'شكرًا، سنراجع البلاغ';

  @override
  String errSuspendedUntil(String date) {
    return 'هذا الحساب موقوف حتى $date. تواصل مع الدعم.';
  }

  @override
  String get errSuspendedPermanently =>
      'هذا الحساب موقوف نهائيًا. تواصل مع الدعم.';

  @override
  String get errReportOwnContent =>
      'لا يمكنك الإبلاغ عن نفسك أو عن محتوى كتبته.';

  @override
  String get errReportReason => 'اختر سببًا.';

  @override
  String get errReportTargetInvalid => 'لا يمكن الإبلاغ عن هذا.';

  @override
  String get errReportTargetNotFound => 'ما تُبلغ عنه لم يعد موجودًا.';

  @override
  String get errModerationActionInvalid => 'هذا الإجراء غير متاح هنا.';

  @override
  String get errModerationSelf => 'لا يمكنك تنفيذ هذا الإجراء على حسابك.';

  @override
  String get errModerationStaffTarget =>
      'لا يمكنك تحذير أحد أعضاء فريق الإشراف أو إيقافه.';

  @override
  String get errModerationNoteRequired => 'اكتب ملاحظة أولًا.';

  @override
  String get errModerationDurationInvalid =>
      'اختر مدة من يوم واحد إلى 365 يومًا.';

  @override
  String get errModerationNoticeNotFound => 'هذا التنبيه لم يعد موجودًا.';

  @override
  String get articleMenu => 'خيارات المقال';

  @override
  String get articleMenuReport => 'الإبلاغ عن المقال';

  @override
  String get articleMenuHide => 'إخفاء المقال';

  @override
  String get articleMenuUnhide => 'إظهار المقال';

  @override
  String get articleHiddenBannerTitle => 'أخفى المشرفون هذا المقال';

  @override
  String get articleHiddenBannerBody => 'لا يراه إلا كاتبه والمشرفون.';

  @override
  String get articleMenuShowLess => 'عرض أقل من هذا النوع';

  @override
  String get articleMenuFollow => 'متابعة الكاتب';

  @override
  String get articleMenuUnfollow => 'إلغاء متابعة الكاتب';

  @override
  String get articleMenuMuteAuthor => 'كتم الكاتب';

  @override
  String get articleMenuUnmuteAuthor => 'إلغاء كتم الكاتب';

  @override
  String get articleMenuMuteTopics => 'كتم المواضيع';

  @override
  String get showLessDone => 'حسنًا، سترى مقالات أقل من هذا النوع.';

  @override
  String muteDone(String name) {
    return 'تم كتم $name. لن ترى مقالاته أو تعليقاته.';
  }

  @override
  String muteUnmuted(String name) {
    return 'تم إلغاء كتم $name.';
  }

  @override
  String get muteBannerTitle => 'لقد كتمت هذا الكاتب';

  @override
  String get muteBannerBody =>
      'لا تظهر لك مقالاته وتعليقاته، ولا يعلم أحد غيرك أنك كتمته.';

  @override
  String get muteUnmute => 'إلغاء الكتم';

  @override
  String muteUnmuteName(String name) {
    return 'إلغاء كتم $name';
  }

  @override
  String get muteTopicsTitle => 'كتم المواضيع';

  @override
  String get muteTopicsBody =>
      'لن يظهر لك ما تكتمه في الصفحة الرئيسية أو الاستكشاف أو البحث. يمكنك إلغاء الكتم من هنا أو من الإعدادات.';

  @override
  String get muteTopicsField => 'المجال كله بجميع مواضيعه';

  @override
  String get muteTopicsTopic => 'هذا الموضوع فقط';

  @override
  String muteTopicsToggle(String name) {
    return 'كتم $name';
  }

  @override
  String get muteCommentCollapsed => 'تعليق من شخص كتمته';

  @override
  String get muteCommentShow => 'عرض';

  @override
  String get muteSettingsEntry => 'ما كتمته';

  @override
  String get muteSettingsEntryHint => 'الكتّاب والمجالات والمواضيع التي كتمتها';

  @override
  String get mutePageTitle => 'ما كتمته';

  @override
  String get mutePageWriters => 'الكتّاب';

  @override
  String get mutePageFields => 'المجالات';

  @override
  String get mutePageTopics => 'المواضيع';

  @override
  String mutePageTopicIn(String field) {
    return 'في $field';
  }

  @override
  String get mutePageEmptyTitle => 'لم تكتم شيئًا بعد';

  @override
  String get mutePageEmptyBody =>
      'اكتم كاتبًا أو مجالًا أو موضوعًا من خيارات أي مقال، وسيظهر هنا.';

  @override
  String get mutePageSubtitle =>
      'لا تظهر لك في الصفحة الرئيسية أو الاستكشاف أو البحث، ولا يعلم أحد أنك كتمتها.';

  @override
  String get muteMenuUser => 'كتم المستخدم';

  @override
  String get muteMenuUnmuteUser => 'إلغاء كتم المستخدم';

  @override
  String get muteMenuCommenter => 'كتم صاحب التعليق';

  @override
  String get muteMenuUnmuteCommenter => 'إلغاء كتم صاحب التعليق';

  @override
  String get errMuteSelf => 'لا يمكنك كتم نفسك.';

  @override
  String get errMuteSystemAccount => 'لا يمكن كتم حساب ReadIn الرسمي.';

  @override
  String get errMuteLimit =>
      'وصلت إلى الحد الأقصى لعدد الكتّاب المكتومين (500).';

  @override
  String get errMuteOwnArticle => 'لا يمكنك تنفيذ هذا الإجراء على مقالك.';

  @override
  String get errRepostOwnArticle => 'لا يمكنك إعادة نشر مقالك.';

  @override
  String get errRepostCaptionTooLong => 'يجب ألا يتجاوز رأيك 500 حرف.';

  @override
  String get profileMenu => 'خيارات أخرى';

  @override
  String get profileMenuReport => 'الإبلاغ عن المستخدم';

  @override
  String get profileMenuWarn => 'تحذير';

  @override
  String get profileMenuSuspend => 'إيقاف الحساب';

  @override
  String get moderationTitle => 'الإشراف';

  @override
  String get moderationQueueEntry => 'البلاغات';

  @override
  String moderationWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر بانتظار المراجعة',
      many: '$count عنصرًا بانتظار المراجعة',
      few: '$count عناصر بانتظار المراجعة',
      two: 'عنصران بانتظار المراجعة',
      one: 'عنصر واحد بانتظار المراجعة',
      zero: 'لا يوجد ما ينتظر المراجعة',
    );
    return '$_temp0';
  }

  @override
  String get moderationNoAccessTitle => 'هذه الصفحة للمشرفين فقط';

  @override
  String get moderationNoAccessBody => 'ليس لدى حسابك صلاحية الإشراف.';

  @override
  String get moderationTabOpen => 'مفتوحة';

  @override
  String get moderationTabResolved => 'محلولة';

  @override
  String get moderationTabDismissed => 'مرفوضة';

  @override
  String get moderationTabLog => 'السجل';

  @override
  String get moderationFilterAll => 'الكل';

  @override
  String get moderationFilterArticles => 'مقالات';

  @override
  String get moderationFilterComments => 'تعليقات';

  @override
  String get moderationFilterUsers => 'مستخدمون';

  @override
  String get moderationEmptyOpenTitle => 'لا توجد بلاغات مفتوحة';

  @override
  String get moderationEmptyOpenBody => 'كل شيء على ما يرام حاليًا.';

  @override
  String get moderationEmptyResolvedTitle => 'لا توجد بلاغات محلولة بعد';

  @override
  String get moderationEmptyDismissedTitle => 'لا توجد بلاغات مرفوضة بعد';

  @override
  String get moderationEmptyLogTitle => 'لا توجد إجراءات إشراف بعد';

  @override
  String get moderationLoadMoreFailed => 'تعذّر تحميل المزيد.';

  @override
  String get moderationTypeArticle => 'مقال';

  @override
  String get moderationTypeComment => 'تعليق';

  @override
  String get moderationTypeUser => 'مستخدم';

  @override
  String get moderationStateHidden => 'مخفي';

  @override
  String get moderationStateDeleted => 'محذوف';

  @override
  String get moderationStateSuspended => 'موقوف';

  @override
  String get moderationStatusOpen => 'مفتوح';

  @override
  String get moderationStatusResolved => 'محلول';

  @override
  String get moderationStatusDismissed => 'مرفوض';

  @override
  String moderationReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بلاغ',
      many: '$count بلاغًا',
      few: '$count بلاغات',
      two: 'بلاغان',
      one: 'بلاغ واحد',
    );
    return '$_temp0';
  }

  @override
  String moderationLastReport(String time) {
    return 'آخر بلاغ $time';
  }

  @override
  String moderationClosed(String time) {
    return 'أُغلق $time';
  }

  @override
  String moderationCommentOn(String title) {
    return 'على «$title»';
  }

  @override
  String moderationWarningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تحذير',
      many: '$count تحذيرًا',
      few: '$count تحذيرات',
      two: 'تحذيران',
      one: 'تحذير واحد',
      zero: 'لا توجد تحذيرات',
    );
    return '$_temp0';
  }

  @override
  String moderationSuspendedUntil(String date) {
    return 'موقوف حتى $date';
  }

  @override
  String get moderationSuspendedForever => 'موقوف نهائيًا';

  @override
  String get moderationCaseArticle => 'مقال مُبلَّغ عنه';

  @override
  String get moderationCaseComment => 'تعليق مُبلَّغ عنه';

  @override
  String get moderationCaseUser => 'مستخدم مُبلَّغ عنه';

  @override
  String get moderationOpenArticle => 'فتح المقال';

  @override
  String get moderationOpenProfile => 'فتح الملف الشخصي';

  @override
  String get moderationActions => 'الإجراءات';

  @override
  String moderationReportsTitle(int count) {
    return 'البلاغات ($count)';
  }

  @override
  String get moderationHistory => 'السجل';

  @override
  String get moderationHistoryEmpty => 'لا توجد إجراءات بعد.';

  @override
  String moderationClosedBy(String name) {
    return 'أغلقه $name';
  }

  @override
  String get moderationHideComment => 'إخفاء التعليق';

  @override
  String get moderationUnhideComment => 'إظهار التعليق';

  @override
  String get moderationDeleteComment => 'حذف التعليق';

  @override
  String get moderationWarnAuthor => 'تحذير الكاتب';

  @override
  String get moderationSuspendAuthor => 'إيقاف حساب الكاتب';

  @override
  String get moderationUnsuspend => 'رفع الإيقاف';

  @override
  String get moderationDismiss => 'رفض البلاغات';

  @override
  String get moderationHideArticleTitle => 'هل تريد إخفاء هذا المقال؟';

  @override
  String get moderationHideArticleBody =>
      'سيختفي من الصفحة الرئيسية والقوائم والبحث، ولن يتمكن من فتحه إلا كاتبه والمشرفون. وسيصل إلى كاتبه تنبيه.';

  @override
  String get moderationHideCommentTitle => 'هل تريد إخفاء هذا التعليق؟';

  @override
  String get moderationHideCommentBody =>
      'سيرى القرّاء مكانه «أخفى المشرفون هذا التعليق».';

  @override
  String get moderationNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get moderationNoteLabel => 'ملاحظة';

  @override
  String get moderationNoteForUser => 'ستصل الملاحظة إلى صاحب الحساب.';

  @override
  String moderationWarnTitle(String name) {
    return 'تحذير $name';
  }

  @override
  String get moderationWarnBody =>
      'سيصله تحذير يتضمن ملاحظتك، وعليه أن يؤكد أنه اطّلع عليه.';

  @override
  String get moderationWarnConfirm => 'إرسال التحذير';

  @override
  String moderationSuspendTitle(String name) {
    return 'إيقاف حساب $name';
  }

  @override
  String get moderationSuspendBody =>
      'لن يتمكن من تسجيل الدخول أو استخدام حسابه حتى انتهاء الإيقاف.';

  @override
  String get moderationSuspendDuration => 'المدة';

  @override
  String moderationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get moderationPermanent => 'نهائيًا';

  @override
  String get moderationSuspendConfirm => 'إيقاف الحساب';

  @override
  String moderationUnsuspendTitle(String name) {
    return 'هل تريد رفع الإيقاف عن $name؟';
  }

  @override
  String get moderationUnsuspendBody =>
      'سيتمكن من تسجيل الدخول واستخدام حسابه مجددًا على الفور.';

  @override
  String get moderationDismissTitle => 'هل تريد رفض هذه البلاغات؟';

  @override
  String get moderationDismissBody =>
      'ستُغلق البلاغات المفتوحة بوصفها مرفوضة، ويبقى المحتوى كما هو.';

  @override
  String get moderationArticleHidden => 'تم إخفاء المقال';

  @override
  String get moderationArticleUnhidden => 'أصبح المقال ظاهرًا مجددًا';

  @override
  String get moderationWarned => 'تم إرسال التحذير';

  @override
  String get moderationSuspended => 'تم إيقاف الحساب';

  @override
  String get moderationUnsuspended => 'تم رفع الإيقاف';

  @override
  String get moderationDismissed => 'تم رفض البلاغات';

  @override
  String get moderationLogCommentHide => 'أخفى تعليقًا';

  @override
  String get moderationLogCommentUnhide => 'أظهر تعليقًا';

  @override
  String get moderationLogCommentDelete => 'حذف تعليقًا';

  @override
  String get moderationLogArticleHide => 'أخفى مقالًا';

  @override
  String get moderationLogArticleUnhide => 'أظهر مقالًا';

  @override
  String get moderationLogUserWarn => 'حذّر مستخدمًا';

  @override
  String get moderationLogUserSuspend => 'أوقف حسابًا';

  @override
  String get moderationLogUserUnsuspend => 'رفع الإيقاف عن حساب';

  @override
  String get moderationLogReportsDismiss => 'رفض بلاغات';

  @override
  String get moderationLogOther => 'إجراء إشراف';

  @override
  String moderationLogReportsClosed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أغلق $count بلاغ',
      many: 'أغلق $count بلاغًا',
      few: 'أغلق $count بلاغات',
      two: 'أغلق بلاغين',
      one: 'أغلق بلاغًا واحدًا',
    );
    return '$_temp0';
  }

  @override
  String moderationLogUntil(String date) {
    return 'حتى $date';
  }

  @override
  String get noticeWarningTitle => 'تلقّيت تحذيرًا من فريق الإشراف';

  @override
  String get noticeWarningBody =>
      'يُرجى قراءة الملاحظة والالتزام بقواعد مجتمع ReadIn.';

  @override
  String noticeArticleHiddenTitle(String title) {
    return 'تم إخفاء مقالك «$title»';
  }

  @override
  String get noticeArticleHiddenBody =>
      'لم يعد القرّاء يرونه. لا يمكن فتحه إلا لك وللمشرفين.';

  @override
  String get noticeNoteLabel => 'ملاحظة المشرف';

  @override
  String get noticeAcknowledge => 'فهمت';

  @override
  String get notificationsMarkAllRead => 'تحديد الكل كمقروء';

  @override
  String get notificationsNewItems => 'عرض الإشعارات الجديدة';

  @override
  String get notificationsToday => 'اليوم';

  @override
  String get notificationsEarlier => 'سابقًا';

  @override
  String get notificationsEmptyTitle => 'لا توجد إشعارات بعد';

  @override
  String get notificationsEmptyBody =>
      'ستظهر هنا الردود والإشارات والمتابِعون الجدد ومقال اليوم.';

  @override
  String get notificationsUnreadDot => 'جديد';

  @override
  String notifNewFollower(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'بدأ $name و$others شخص آخر متابعتك',
      many: 'بدأ $name و$others شخصًا آخر متابعتك',
      few: 'بدأ $name و$others أشخاص آخرين متابعتك',
      two: 'بدأ $name وشخصان آخران متابعتك',
      one: 'بدأ $name وشخص آخر متابعتك',
      zero: 'بدأ $name متابعتك',
    );
    return '$_temp0';
  }

  @override
  String notifArticleComment(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'علّق $name و$others شخص آخر على مقالك',
      many: 'علّق $name و$others شخصًا آخر على مقالك',
      few: 'علّق $name و$others أشخاص آخرين على مقالك',
      two: 'علّق $name وشخصان آخران على مقالك',
      one: 'علّق $name وشخص آخر على مقالك',
      zero: 'علّق $name على مقالك',
    );
    return '$_temp0';
  }

  @override
  String notifCommentReply(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'ردّ $name و$others شخص آخر على تعليقك',
      many: 'ردّ $name و$others شخصًا آخر على تعليقك',
      few: 'ردّ $name و$others أشخاص آخرين على تعليقك',
      two: 'ردّ $name وشخصان آخران على تعليقك',
      one: 'ردّ $name وشخص آخر على تعليقك',
      zero: 'ردّ $name على تعليقك',
    );
    return '$_temp0';
  }

  @override
  String notifMention(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'أشار إليك $name و$others شخص آخر في تعليق',
      many: 'أشار إليك $name و$others شخصًا آخر في تعليق',
      few: 'أشار إليك $name و$others أشخاص آخرين في تعليق',
      two: 'أشار إليك $name وشخصان آخران في تعليق',
      one: 'أشار إليك $name وشخص آخر في تعليق',
      zero: 'أشار إليك $name في تعليق',
    );
    return '$_temp0';
  }

  @override
  String notifMentionArticle(String name) {
    return 'أشار إليك $name في مقال';
  }

  @override
  String notifFollowedWriterArticle(String name) {
    return 'نشر $name مقالًا جديدًا';
  }

  @override
  String notifFollowedWriterArticles(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نشر $name $count مقال جديد',
      many: 'نشر $name $count مقالًا جديدًا',
      few: 'نشر $name $count مقالات جديدة',
      two: 'نشر $name مقالين جديدين',
      one: 'نشر $name مقالًا جديدًا',
    );
    return '$_temp0';
  }

  @override
  String notifReactionsMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'وصل مقالك إلى $count تفاعل 🎉',
      many: 'وصل مقالك إلى $count تفاعلًا 🎉',
      few: 'وصل مقالك إلى $count تفاعلات 🎉',
      two: 'وصل مقالك إلى تفاعلين 🎉',
      one: 'أول تفاعل على مقالك 🎉',
    );
    return '$_temp0';
  }

  @override
  String get notifReactionsMilestoneGeneric => 'يتفاعل القرّاء مع مقالك 🎉';

  @override
  String get notifDailyArticle => 'مقال اليوم جاهز ☕';

  @override
  String notifStreakReminder(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'اقرأ مقالًا اليوم لتحافظ على سلسلة القراءة ($days يوم) 🔥',
      many: 'اقرأ مقالًا اليوم لتحافظ على سلسلة القراءة ($days يومًا) 🔥',
      few: 'اقرأ مقالًا اليوم لتحافظ على سلسلة القراءة ($days أيام) 🔥',
      two: 'اقرأ مقالًا اليوم لتحافظ على سلسلة القراءة (يومان) 🔥',
      one: 'اقرأ مقالًا اليوم لتحافظ على سلسلة القراءة (يوم واحد) 🔥',
    );
    return '$_temp0';
  }

  @override
  String get notifStreakReminderGeneric =>
      'اقرأ مقالًا اليوم لتحافظ على سلسلة القراءة 🔥';

  @override
  String get notifSecurityPasswordChanged => 'تم تغيير كلمة مرورك';

  @override
  String get notifSecurityPasswordReset => 'تمت إعادة تعيين كلمة مرورك';

  @override
  String get notifSecurityRecoveryPinChanged => 'تم تغيير رمز الاسترداد (PIN)';

  @override
  String get notifSecurityPhoneNumberChanged => 'تم تغيير رقم هاتفك';

  @override
  String get notifSecurityRecoveryLockedOut =>
      'تم قفل استرداد الحساب بعد محاولات خاطئة كثيرة لإدخال رمز PIN';

  @override
  String get notifSecurityExternalLoginLinked =>
      'تم ربط حساب Google أو Apple بحسابك';

  @override
  String get notifSecurityExternalLoginUnlinked =>
      'تم إلغاء ربط حساب Google أو Apple بحسابك';

  @override
  String get notifSecurityPhoneSignInAdded =>
      'تمت إضافة رقم هاتف وكلمة مرور إلى حسابك';

  @override
  String get notifSecurityGeneric => 'حدث تغيير أمني في حسابك';

  @override
  String get notifSecurityHint =>
      'إذا لم تكن أنت من قام بذلك، فغيّر كلمة المرور الآن.';

  @override
  String get notifVerificationResult => 'هناك تحديث بشأن طلب توثيقك';

  @override
  String get notifVerificationApproved => 'أصبحت الآن كاتبًا موثّقًا ✓';

  @override
  String get notifVerificationRejected => 'لم تتم الموافقة على طلب توثيقك';

  @override
  String get notifVerificationRejectedHint => 'افتحه لمعرفة السبب';

  @override
  String get notifModerationWarning => 'تلقّيت تحذيرًا من فريق الإشراف';

  @override
  String get notifModerationArticleHidden => 'أخفى المشرفون مقالك';

  @override
  String get notifGeneric => 'لديك إشعار جديد';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get notificationSettingsEntryHint =>
      'Push أو داخل التطبيق أو إيقاف لكل نوع، وساعات الهدوء';

  @override
  String get notificationSettingsTypesTitle => 'ما يصلك من إشعارات';

  @override
  String get notificationSettingsTypesHint =>
      'تظهر إشعارات Push أيضًا في قائمة الإشعارات داخل التطبيق.';

  @override
  String get notificationModeAll => 'Push + داخل التطبيق';

  @override
  String get notificationModeInApp => 'داخل التطبيق فقط';

  @override
  String get notificationModeOff => 'إيقاف';

  @override
  String get notificationModeAllShort => 'Push';

  @override
  String get notificationModeInAppShort => 'داخل التطبيق';

  @override
  String get notificationTypeNewFollower => 'متابِعون جدد';

  @override
  String get notificationTypeArticleComment => 'تعليقات على مقالاتك';

  @override
  String get notificationTypeCommentReply => 'ردود على تعليقاتك';

  @override
  String get notificationTypeMention => 'الإشارات';

  @override
  String get notificationTypeMentionHint =>
      'عندما يشير إليك أحد في تعليق أو مقال';

  @override
  String get notificationTypeReactionsMilestone =>
      'أرقام التفاعل (10 و50 و100)';

  @override
  String get notificationTypeFollowedWriterArticle =>
      'مقالات جديدة من كتّاب تتابعهم';

  @override
  String get notificationTypeDailyArticle => 'مقال اليوم';

  @override
  String get notificationTypeStreakReminder => 'تذكير سلسلة القراءة (8 مساءً)';

  @override
  String get notificationSecurityAlerts => 'تنبيهات الأمان';

  @override
  String get notificationSecurityAlertsHint =>
      'مفعّلة دائمًا، حتى في ساعات الهدوء.';

  @override
  String get quietHoursTitle => 'ساعات الهدوء';

  @override
  String get quietHoursHint =>
      'تُؤجَّل إشعارات Push حتى تنتهي ساعات الهدوء. أما تنبيهات الأمان فتصل فورًا.';

  @override
  String get quietHoursSwitch => 'تأجيل إشعارات Push خلال هذه الساعات';

  @override
  String get quietHoursFrom => 'من';

  @override
  String get quietHoursTo => 'إلى';

  @override
  String get errNotificationNotFound => 'هذا الإشعار لم يعد موجودًا.';

  @override
  String get errNotificationTypeInvalid => 'نوع الإشعار هذا غير موجود.';

  @override
  String get errNotificationModeInvalid =>
      'اختر «Push» أو «داخل التطبيق» أو «إيقاف».';

  @override
  String get errNotificationQuietHoursInvalid =>
      'تتطلب ساعات الهدوء وقتين مختلفين.';

  @override
  String get settingsWriting => 'الكتابة';

  @override
  String get verificationTitle => 'توثيق الكاتب';

  @override
  String get verificationEntryHint => 'احصل على شارة الكاتب الموثّق';

  @override
  String get verificationStatusVerified => 'أنت كاتب موثّق';

  @override
  String get verificationStatusPending => 'طلبك قيد المراجعة';

  @override
  String get verificationStatusRejected =>
      'لم تتم الموافقة، افتحه لمعرفة السبب';

  @override
  String get verificationIntro =>
      'يحصل الكتّاب الموثّقون على شارة بجوار أسمائهم في مقالاتهم وملفاتهم الشخصية وتعليقاتهم. أخبرنا بطبيعة عملك وقدّم دليلًا على ذلك.';

  @override
  String get verificationFieldLabel => 'المجال';

  @override
  String get verificationFieldHint => 'اختر مجالك';

  @override
  String get verificationFieldsFailed => 'تعذّر تحميل المجالات.';

  @override
  String get verificationJobTitleLabel => 'المسمّى الوظيفي';

  @override
  String get verificationJobTitleHint => 'مثلًا: Senior Backend Engineer';

  @override
  String get verificationProofTitle => 'الدليل';

  @override
  String get verificationProofHint => 'أضف رابطًا أو ملفًا أو كليهما.';

  @override
  String get verificationProofUrlLabel => 'رابط (LinkedIn أو GitHub…)';

  @override
  String get verificationProofFileAdd => 'إرفاق ملف';

  @override
  String get verificationProofFileHint =>
      'شهادة أو بطاقة النقابة: PDF أو JPEG أو PNG أو WebP، حتى 10 م.ب.';

  @override
  String get verificationProofFileRemove => 'إزالة الملف';

  @override
  String get verificationProofPrivate =>
      'لا يرى ملفك إلا المراجعون، ويُحذف فور البتّ في طلبك.';

  @override
  String get verificationNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get verificationNoteHint => 'أي شيء ينبغي أن يعرفه المراجعون';

  @override
  String get verificationSubmit => 'إرسال الطلب';

  @override
  String get verificationSubmitting => 'جارٍ إرسال طلبك…';

  @override
  String get verificationPendingTitle => 'طلبك قيد المراجعة';

  @override
  String get verificationPendingBody => 'سنرسل إليك إشعارًا فور مراجعته.';

  @override
  String verificationSubmittedOn(String date) {
    return 'أُرسل في $date';
  }

  @override
  String get verificationLinkLabel => 'الرابط';

  @override
  String get verificationFileLabel => 'الملف';

  @override
  String get verificationNoteSummaryLabel => 'الملاحظة';

  @override
  String get verificationWithdraw => 'سحب الطلب';

  @override
  String get verificationWithdrawTitle => 'هل تريد سحب طلبك؟';

  @override
  String get verificationWithdrawBody =>
      'سيُحذف الطلب مع ملفه. يمكنك إرسال طلب جديد في أي وقت.';

  @override
  String get verificationWithdrawConfirm => 'موافق';

  @override
  String get verificationWithdrawn => 'تم سحب الطلب';

  @override
  String get verificationApprovedTitle => 'أنت كاتب موثّق';

  @override
  String get verificationApprovedBody =>
      'تظهر شارة التوثيق بجوار اسمك في مقالاتك وملفك الشخصي وتعليقاتك.';

  @override
  String verificationApprovedOn(String date) {
    return 'تم التوثيق في $date';
  }

  @override
  String get verificationRejectedTitle => 'لم تتم الموافقة على طلبك';

  @override
  String get verificationRejectedReason => 'سبب المراجع';

  @override
  String verificationRejectedOn(String date) {
    return 'تمت المراجعة في $date';
  }

  @override
  String get verificationRejectedBody =>
      'يمكنك استكمال ما ينقص ثم إعادة الطلب.';

  @override
  String get verificationRequestAgain => 'إعادة الطلب';

  @override
  String get verificationUnavailableTitle => 'لا يمكنك طلب التوثيق حاليًا';

  @override
  String get verificationUnavailableBody =>
      'لا يمكن للحساب الموقوف إرسال طلبات توثيق.';

  @override
  String get errVerificationProofRequired => 'أضف رابطًا أو ملفًا كدليل.';

  @override
  String get errVerificationProofInvalid =>
      'يجب أن يكون ملف الدليل بصيغة PDF أو JPEG أو PNG أو WebP، وألا يتجاوز 10 م.ب.';

  @override
  String get errVerificationFieldInvalid => 'اختر مجالًا من القائمة.';

  @override
  String get errVerificationAlreadyPending => 'لديك طلب قيد المراجعة بالفعل.';

  @override
  String get errVerificationAlreadyVerified => 'أنت كاتب موثّق بالفعل.';

  @override
  String get errVerificationNotFound => 'لم يعد هذا الطلب بانتظار المراجعة.';

  @override
  String get errVerificationNotVerified => 'هذا المستخدم غير موثّق.';

  @override
  String get errVerificationSystemAccount =>
      'هذا هو حساب ReadIn الرسمي، وشارة توثيقه ثابتة.';

  @override
  String get healthDisclaimer =>
      'هذه المعلومات للتوعية فقط، ولا تُغني عن استشارة الطبيب.';

  @override
  String get articleToc => 'محتويات المقال';

  @override
  String get settingsSignInForSync =>
      'سجّل الدخول لحفظ هذه الإعدادات في حسابك.';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات ✓';

  @override
  String get settingsInterests => 'اهتماماتك';

  @override
  String get settingsInterestsHint => 'المجالات والمواضيع التي تتابعها';

  @override
  String get interestsPageIntro =>
      'اضغط على أي مجال أو موضوع لمتابعته أو إلغاء متابعته. تُحفظ التغييرات فورًا، وعلى أساسها نختار المقالات في «لك».';

  @override
  String get interestsKeepThree => 'احتفظ بـ 3 اهتمامات على الأقل';

  @override
  String get imageDarkVersion => 'نسخة الوضع الداكن';

  @override
  String get imageDarkAdd => 'إضافة نسخة للوضع الداكن (للرسومات)';

  @override
  String get imageDarkRemove => 'إزالة نسخة الوضع الداكن';

  @override
  String get postReadMore => 'قراءة المزيد';

  @override
  String get postShowLess => 'عرض أقل';

  @override
  String get postReadFullArticle => 'قراءة المقال كاملًا';

  @override
  String get postReact => 'تفاعل';

  @override
  String get postComment => 'تعليق';

  @override
  String postBarReact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تفاعل، $count',
      zero: 'تفاعل',
    );
    return '$_temp0';
  }

  @override
  String postBarReacted(String reaction, int count) {
    return 'تفاعلت: $reaction، $count';
  }

  @override
  String postBarComment(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعليق، $count',
      zero: 'تعليق',
    );
    return '$_temp0';
  }

  @override
  String postBarRepost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إعادة نشر، $count',
      zero: 'إعادة نشر',
    );
    return '$_temp0';
  }

  @override
  String get repostOwnHint => 'لا يمكنك إعادة نشر مقالك';

  @override
  String repostLabelOne(String name) {
    return 'أعاد نشره $name';
  }

  @override
  String repostLabelMany(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أعاد نشره $name و$count آخرون',
      one: 'أعاد نشره $name وشخص آخر',
    );
    return '$_temp0';
  }

  @override
  String get repostMenuRepost => 'إعادة النشر';

  @override
  String get repostMenuWithThoughts => 'إعادة النشر مع رأيك';

  @override
  String get repostMenuEdit => 'تعديل رأيك';

  @override
  String get repostMenuUndo => 'إلغاء إعادة النشر';

  @override
  String get repostCaptionTitle => 'إعادة نشر المقال';

  @override
  String get repostCaptionHint => 'اكتب رأيك في المقال… (اختياري)';

  @override
  String get repostCaptionSubmit => 'نشر';

  @override
  String get repostCaptionReposted => 'تمت إعادة نشر المقال.';

  @override
  String get repostCaptionSaved => 'تم حفظ رأيك.';

  @override
  String get commentBoxHint => 'اكتب تعليقًا…';

  @override
  String get commentBoxReplyHint => 'اكتب ردك…';

  @override
  String get commentBoxEmoji => 'الرموز التعبيرية';

  @override
  String get commentBoxKeyboard => 'الرجوع إلى لوحة المفاتيح';

  @override
  String get commentBoxCancelReply => 'إلغاء الرد';

  @override
  String get commentBoxCancelEdit => 'إلغاء التعديل';

  @override
  String get commentBoxEmojiSearch => 'ابحث عن رمز تعبيري';

  @override
  String get commentBoxEmojiNoRecents =>
      'ستظهر هنا الرموز التعبيرية التي تستخدمها';

  @override
  String get commentRowFollow => 'متابعة';

  @override
  String get postOpenArticleHint => 'يفتح المقال';

  @override
  String get postCoverImage => 'صورة الغلاف، تُفتح بملء الشاشة';

  @override
  String postMoreTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وسم آخر',
      many: '$count وسمًا آخر',
      few: '$count وسوم أخرى',
      two: 'وسمان آخران',
      one: 'وسم آخر',
    );
    return '$_temp0';
  }

  @override
  String get tagOpenHint => 'يفتح صفحة الوسم';

  @override
  String tagPageArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقالًا',
      few: '$count مقالات',
      two: 'مقالان',
      one: 'مقال واحد',
      zero: 'لا توجد مقالات بعد',
    );
    return '$_temp0';
  }

  @override
  String get tagPageEmptyTitle => 'لا توجد مقالات تحمل هذا الوسم بعد';

  @override
  String get tagPageEmptyBody => 'عندما ينشر أحد مقالًا بهذا الوسم، ستجده هنا.';

  @override
  String get tagNotFoundTitle => 'هذا الوسم غير موجود';

  @override
  String get tagNotFoundBody => 'ربما أُزيل أو تغيّر اسمه. جرّب وسمًا آخر.';

  @override
  String get searchHint => 'ابحث عن مقالات وكتّاب ومواضيع ووسوم';

  @override
  String get searchFieldHint => 'ابحث في ReadIn';

  @override
  String get searchTabArticles => 'المقالات';

  @override
  String get searchTabWriters => 'الكتّاب';

  @override
  String get searchTabTopics => 'المواضيع';

  @override
  String get searchTabTags => 'الوسوم';

  @override
  String get searchRecentTitle => 'عمليات البحث الأخيرة';

  @override
  String get searchRecentClearAll => 'مسح الكل';

  @override
  String searchRecentRemove(String query) {
    return 'إزالة «$query» من عمليات البحث الأخيرة';
  }

  @override
  String get searchIdleTitle => 'عمّ تريد أن تقرأ؟';

  @override
  String get searchIdleBody =>
      'ابحث عن مقالات وكتّاب ومواضيع ووسوم، بالعربية أو بالإنجليزية.';

  @override
  String searchNoResultsTitle(String query) {
    return 'لا توجد نتائج لـ «$query»';
  }

  @override
  String get searchNoResultsTip =>
      'جرّب كلمة أخرى أو كلمة أقصر، أو ابحث في تبويب آخر.';

  @override
  String get searchNoResultsFilteredTitle =>
      'لا توجد نتائج تطابق عوامل التصفية هذه';

  @override
  String searchNoResultsFiltersTip(String query) {
    return 'أزل عوامل التصفية لعرض كل ما يطابق «$query».';
  }

  @override
  String get searchFoundInPdf => 'وُجدت في ملف PDF المرفق';

  @override
  String get searchFilterField => 'المجال';

  @override
  String get searchFilterLanguage => 'لغة المقال';

  @override
  String get searchFilterReadingTime => 'مدة القراءة';

  @override
  String searchFilterValue(String filter, String value) {
    return '$filter: $value';
  }

  @override
  String get searchFieldAll => 'كل المجالات';

  @override
  String get searchLanguageAny => 'كل اللغات';

  @override
  String get searchReadingTimeAny => 'أي مدة';

  @override
  String get searchReadingTimeUpTo5 => 'حتى 5 دقائق';

  @override
  String get searchReadingTime5To10 => 'من 5 إلى 10 دقائق';

  @override
  String get searchReadingTimeOver10 => 'أكثر من 10 دقائق';

  @override
  String get searchClearFilters => 'مسح عوامل التصفية';

  @override
  String get searchKindField => 'مجال';

  @override
  String get exploreFields => 'المجالات';

  @override
  String get exploreTrending => 'الأكثر رواجًا هذا الأسبوع';

  @override
  String get exploreMostSaved => 'الأكثر حفظًا';

  @override
  String get exploreNewWriters => 'كتّاب جدد';

  @override
  String get exploreFeaturedPaths => 'مسارات مختارة';

  @override
  String get exploreSeeAll => 'عرض الكل';

  @override
  String exploreSeeAllSection(String section) {
    return 'عرض الكل: $section';
  }

  @override
  String get exploreEmptyTitle => 'لا يوجد ما تستكشفه بعد';

  @override
  String get exploreEmptyBody =>
      'ستظهر هنا المجالات والمقالات والكتّاب والمسارات بمجرد أن يبدأ الناس في النشر.';

  @override
  String get exploreTrendingEmptyTitle =>
      'لا توجد مقالات رائجة هذا الأسبوع بعد';

  @override
  String get exploreMostSavedEmptyTitle => 'لا توجد مقالات محفوظة بعد';

  @override
  String get exploreRankingEmptyBody =>
      'عُد بعد قليل، أو تصفّح المجالات في صفحة الاستكشاف.';

  @override
  String fieldArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقالًا',
      few: '$count مقالات',
      two: 'مقالان',
      one: 'مقال واحد',
      zero: '0 مقال',
    );
    return '$_temp0';
  }

  @override
  String fieldFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count متابع',
      many: '$count متابعًا',
      few: '$count متابعين',
      two: 'متابعان',
      one: 'متابع واحد',
      zero: '0 متابع',
    );
    return '$_temp0';
  }

  @override
  String get fieldFollow => 'متابعة المجال';

  @override
  String get fieldFollowTopic => 'متابعة الموضوع';

  @override
  String get fieldKeepThree =>
      'يجب أن تتابع 3 اهتمامات على الأقل. تابع مجالًا أو موضوعًا آخر أولًا.';

  @override
  String get fieldTopics => 'مواضيع المجال';

  @override
  String get fieldTopWriters => 'أبرز الكتّاب في هذا المجال';

  @override
  String get fieldArticles => 'أحدث المقالات';

  @override
  String get fieldEmptyTitle => 'لا توجد مقالات في هذا المجال بعد';

  @override
  String get fieldEmptyBody => 'تابعه لتظهر لك مقالاته الجديدة فور نشرها.';

  @override
  String get fieldTopicEmptyTitle => 'لا توجد مقالات في هذا الموضوع بعد';

  @override
  String get fieldNotFoundTitle => 'هذا المجال غير موجود';

  @override
  String get fieldNotFoundBody => 'ربما أُزيل، أو أن الرابط غير صحيح.';

  @override
  String get fieldGoToExplore => 'تصفّح مجالات أخرى';

  @override
  String get fieldTopicNotFoundTitle => 'هذا الموضوع غير موجود';

  @override
  String fieldTopicNotFoundBody(String field) {
    return 'هذا الموضوع ليس من مواضيع $field، أو ربما أُزيل.';
  }

  @override
  String get fieldShowAllArticles => 'كل مقالات المجال';

  @override
  String get errInterestsUnknown => 'بعض المجالات أو المواضيع غير موجودة.';

  @override
  String get errTopicNotFound => 'الموضوع غير موجود.';

  @override
  String get errTopicNotInField => 'الموضوع لا ينتمي إلى هذا المجال.';

  @override
  String get errArticleNotOwner => 'يقتصر تعديل هذا المقال على كاتبه.';

  @override
  String get errArticleStatusInvalid =>
      'يجب أن تكون الحالة «مسودة» أو «منشور».';

  @override
  String get errArticleNoContent => 'المقال فارغ. اكتب شيئًا أولًا.';

  @override
  String get errArticleInvalidTransition =>
      'لا يمكن تنفيذ هذا الإجراء والمقال في حالته الحالية.';

  @override
  String get errArticleSlugTaken => 'هذا الرابط مستخدم لمقال آخر.';

  @override
  String get errArticleTagsMaxFive => 'الحد الأقصى 5 وسوم للمقال الواحد.';

  @override
  String get errArticleTooManyTags => 'الحد الأقصى 5 وسوم للمقال الواحد.';

  @override
  String get errTagNotFound => 'هذا الوسم غير موجود.';

  @override
  String get errTagInvalid =>
      'يجب أن يتكون الوسم من 2 إلى 30 حرفًا: حروف وأرقام ومسافات و ⁦- _ . + #⁩ فقط.';

  @override
  String get errTagLimit =>
      'أنشأت وسومًا جديدة كثيرة اليوم. اختر من الوسوم الموجودة، أو حاول مرة أخرى لاحقًا.';

  @override
  String get errTagHidden => 'هذا الوسم غير متاح. اختر وسمًا آخر.';

  @override
  String get errArticleLanguageInvalid => 'لغة المقال هذه غير مدعومة.';

  @override
  String get errArticleContentLanguageMismatch =>
      'لغة المحتوى لا تطابق لغة المقال.';

  @override
  String get errConcurrencyConflict =>
      'عدّل شخص آخر هذه البيانات. حدّث الصفحة وحاول مرة أخرى.';

  @override
  String get errRequestInvalid => 'الطلب غير صالح.';

  @override
  String get errRequestTooLarge => 'حجم الطلب أكبر من المسموح به.';

  @override
  String get errRequestUnsupportedMediaType => 'نوع المحتوى هذا غير مدعوم.';

  @override
  String get errRouteNotFound => 'الصفحة غير موجودة.';

  @override
  String get errReportStatusInvalid =>
      'يجب أن تكون حالة البلاغ «مفتوح» أو «تمت معالجته» أو «مرفوض».';

  @override
  String get errSearchQueryInvalid =>
      'اكتب من 1 إلى 100 حرف، منها حرف أو رقم واحد على الأقل.';

  @override
  String get errSearchTypeInvalid =>
      'يجب أن يكون نوع البحث: مقالات أو كتّاب أو مواضيع أو وسوم.';

  @override
  String get errSearchFilterInvalid => 'عوامل تصفية البحث هذه غير صالحة.';

  @override
  String get profileTabCategories => 'الفئات';

  @override
  String get categoriesOther => 'مقالات أخرى';

  @override
  String categoryArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقالًا',
      few: '$count مقالات',
      two: 'مقالان',
      one: 'مقال واحد',
      zero: 'لا توجد مقالات بعد',
    );
    return '$_temp0';
  }

  @override
  String get categoryOpenHint => 'يفتح الفئة';

  @override
  String get categoriesEmptyTitle => 'لا توجد فئات بعد';

  @override
  String get categoriesEmptyBody =>
      'عندما ينظّم هذا الكاتب مقالاته في فئات، ستجدها هنا.';

  @override
  String get categoriesOwnHint =>
      'نظّم مقالاتك في فئات. سيعرضها ملفك الشخصي بهذا الترتيب.';

  @override
  String get categoryNew => 'فئة جديدة';

  @override
  String get categoriesFull =>
      'لديك 50 فئة، وهو الحد الأقصى. احذف فئة لإضافة أخرى.';

  @override
  String get categoriesEmptyOwnTitle => 'نظّم مقالاتك';

  @override
  String get categoriesEmptyOwnBody =>
      'أنشئ فئات مثل «نصائح Backend»، ثم أضف مقالاتك إليها من المحرر. سيراها القرّاء في ملفك الشخصي.';

  @override
  String get categoryEmptyOwn => 'فارغة، ولا تظهر للزوار';

  @override
  String get categoryRenameTitle => 'إعادة تسمية الفئة';

  @override
  String get categoryNameLabel => 'اسم الفئة';

  @override
  String get categoryNameHint => 'مثلًا: نصائح Backend';

  @override
  String get categoryNameTooLong => 'يجب ألا يتجاوز اسم الفئة 40 حرفًا.';

  @override
  String get categoryNameNoLetter =>
      'يجب أن يحتوي اسم الفئة على حرف أو رقم واحد على الأقل.';

  @override
  String get categoryMoveUp => 'نقل لأعلى';

  @override
  String get categoryMoveDown => 'نقل لأسفل';

  @override
  String get categoryDragHandle => 'اسحب لإعادة الترتيب';

  @override
  String get categoryMenu => 'خيارات الفئة';

  @override
  String categoryDeleteTitle(String name) {
    return 'هل تريد حذف «$name»؟';
  }

  @override
  String categoryDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تحتوي هذه الفئة على $count مقال، وستبقى منشورة دون فئة.',
      many: 'تحتوي هذه الفئة على $count مقالًا، وستبقى منشورة دون فئة.',
      few: 'تحتوي هذه الفئة على $count مقالات، وستبقى منشورة دون فئة.',
      two: 'تحتوي هذه الفئة على مقالين، وسيبقيان منشورَين دون فئة.',
      one: 'تحتوي هذه الفئة على مقال واحد، وسيبقى منشورًا دون فئة.',
      zero: 'هذه الفئة فارغة.',
    );
    return '$_temp0';
  }

  @override
  String get categoryDeleted => 'تم حذف الفئة';

  @override
  String get categoryPageEmptyTitle => 'لا توجد مقالات في هذه الفئة بعد';

  @override
  String get categoryPageEmptyBody =>
      'عندما يضيف الكاتب مقالات إلى هذه الفئة، ستجدها هنا.';

  @override
  String get categoryOtherEmptyTitle => 'لا توجد مقالات دون فئة';

  @override
  String get categoryOtherEmptyBody => 'كل مقالات هذا الكاتب مصنّفة في فئات.';

  @override
  String get categoryNotFoundTitle => 'هذه الفئة غير موجودة';

  @override
  String get categoryNotFoundBody => 'ربما حُذفت، أو أن الرابط غير صحيح.';

  @override
  String get categoryWriterProfile => 'عرض الملف الشخصي للكاتب';

  @override
  String articleInCategory(String name) {
    return 'في فئة $name';
  }

  @override
  String get editorCategoryLabel => 'الفئة';

  @override
  String get editorCategoryNone => 'دون فئة';

  @override
  String get editorCategoryHint =>
      'اختياري: تجمع المقال مع مقالات مشابهة في ملفك الشخصي. يُطبَّق أي تغيير فورًا.';

  @override
  String get editorCategoryLoadFailed => 'تعذّر تحميل فئاتك.';

  @override
  String get moderationCategoriesTitle => 'فئات الكاتب';

  @override
  String get moderationCategoriesEmpty => 'لا توجد فئات.';

  @override
  String get moderationClearCategory => 'إزالة الاسم';

  @override
  String moderationClearCategoryTitle(String name) {
    return 'هل تريد إزالة اسم الفئة «$name»؟';
  }

  @override
  String get moderationClearCategoryBody =>
      'ستحمل الفئة اسمًا محايدًا مثل «قسم 1»، وسيتوقف رابطها القديم عن العمل. وستبقى مقالاتها فيها، ولن يتلقى الكاتب إشعارًا.';

  @override
  String get moderationCategoryCleared => 'تمت إزالة اسم الفئة';

  @override
  String get moderationLogUserClearCategory => 'أزال اسم فئة';

  @override
  String get errCategoryNotFound => 'هذه الفئة غير موجودة.';

  @override
  String get errCategoryNotOwner => 'هذه الفئة ليست لك.';

  @override
  String get errCategoryLimit => 'وصلت إلى الحد الأقصى لعدد الفئات (50).';

  @override
  String get errCategoryNameTaken => 'لديك فئة بالاسم نفسه بالفعل.';

  @override
  String get errCategoryNameInvalid =>
      'يجب أن يتكون اسم الفئة من 1 إلى 40 حرفًا، وأن يتضمن حرفًا أو رقمًا واحدًا على الأقل.';

  @override
  String get meMenu => 'أنا';

  @override
  String get meViewProfile => 'عرض الملف الشخصي';

  @override
  String get meArticlesThisWeek => 'مقالات هذا الأسبوع';

  @override
  String get meMinutesThisWeek => 'دقائق هذا الأسبوع';

  @override
  String get themeSwitchToDark => 'التبديل إلى الوضع الداكن';

  @override
  String get themeSwitchToLight => 'التبديل إلى الوضع الفاتح';

  @override
  String get searchPillHint => 'ابحث عن مقالات، كتّاب…';

  @override
  String get startPostHint => 'ابدأ منشورًا جديدًا…';

  @override
  String get startPostPhoto => 'صورة';

  @override
  String get startPostPdf => 'PDF';

  @override
  String get startPostArticle => 'مقال';

  @override
  String get suggestedWritersFeedTitle => 'أضف إلى صفحتك الرئيسية';

  @override
  String get suggestedPathTitle => 'مسار مقترح';

  @override
  String get highlightAction => 'تمييز';

  @override
  String get highlightRemove => 'إزالة التمييز';

  @override
  String highlightCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ميّز $count قارئ هذه الجملة',
      many: 'ميّز $count قارئًا هذه الجملة',
      few: 'ميّز $count قرّاء هذه الجملة',
      two: 'ميّز قارئان هذه الجملة',
      one: 'ميّز قارئ واحد هذه الجملة',
    );
    return '$_temp0';
  }

  @override
  String get highlightAdded => 'تم التمييز';

  @override
  String get highlightRemoved => 'تمت إزالة التمييز';

  @override
  String get highlightMenuHide => 'إخفاء التمييزات';

  @override
  String get highlightMenuShow => 'إظهار التمييزات';

  @override
  String get highlightSettingTitle => 'إظهار التمييزات';

  @override
  String get highlightSettingHint =>
      'تمييزاتك والجمل التي ميّزها كثير من القرّاء في المقالات.';

  @override
  String get highlightSavedTab => 'التمييزات';

  @override
  String get highlightSavedEmptyTitle => 'لا توجد تمييزات بعد';

  @override
  String get highlightSavedEmptyBody =>
      'حدّد جملة في أي مقال واضغط «تمييز» لتجدها هنا.';

  @override
  String get highlightSavedOpen => 'فتح المقال عند هذا التمييز';

  @override
  String get highlightSavedVersionAr => 'النسخة العربية';

  @override
  String get highlightSavedVersionEn => 'النسخة الإنجليزية';

  @override
  String get errHighlightTextMismatch =>
      'تغيّر هذا النص في المقال. حدّث الصفحة وحاول مرة أخرى.';

  @override
  String get errHighlightBlockNotAllowed => 'لا يمكن تمييز هذا الجزء.';

  @override
  String get errHighlightTooShort => 'حدّد 3 أحرف على الأقل.';

  @override
  String get errHighlightTooLong => 'يجب ألا يتجاوز التمييز 1000 حرف.';

  @override
  String get errHighlightLimit =>
      'وصلت إلى الحد الأقصى للتمييزات في هذا المقال (100).';

  @override
  String get errHighlightNotFound => 'هذا التمييز غير موجود.';

  @override
  String get quoteCardAction => 'مشاركة اقتباس';

  @override
  String get quoteCardTitle => 'مشاركة اقتباس';

  @override
  String get quoteCardHint =>
      'صورة للنص الذي حددته لمشاركتها على مواقع التواصل، مع رابط المقال.';

  @override
  String get quoteCardThemeLabel => 'ألوان البطاقة';

  @override
  String get quoteCardFormatLabel => 'حجم البطاقة';

  @override
  String get quoteCardSquare => 'مربع';

  @override
  String get quoteCardLandscape => 'أفقي';

  @override
  String get quoteCardShare => 'مشاركة';

  @override
  String get quoteCardSave => 'حفظ';

  @override
  String get quoteCardCopyLink => 'نسخ الرابط';

  @override
  String get quoteCardLinkCopied => 'تم نسخ الرابط';

  @override
  String get quoteCardCopyFailed => 'تعذّر نسخ الرابط.';

  @override
  String get quoteCardSaved => 'تم حفظ البطاقة.';

  @override
  String get quoteCardSaveFailed => 'تعذّر حفظ البطاقة. حاول مرة أخرى.';

  @override
  String get quoteCardShareFailed => 'تعذّر فتح المشاركة. حاول مرة أخرى.';

  @override
  String get quoteCardPreparing => 'جارٍ تجهيز البطاقة…';

  @override
  String quoteCardPreview(String quote) {
    return 'بطاقة اقتباس: $quote';
  }

  @override
  String get quoteCardRetry => 'إعادة المحاولة';

  @override
  String get errQuoteCardNotFound => 'المقال غير موجود.';

  @override
  String get errQuoteCardHidden =>
      'أخفى المشرفون هذا المقال، لذا لا يمكن مشاركة اقتباسات منه.';

  @override
  String get errQuoteCardTextMismatch =>
      'تغيّر هذا النص في المقال. حدّث الصفحة وحاول مرة أخرى.';

  @override
  String get errQuoteCardBlockNotAllowed => 'لا يمكن مشاركة هذا الجزء كاقتباس.';

  @override
  String get errQuoteCardTooShort => 'حدّد 3 أحرف على الأقل.';

  @override
  String get errQuoteCardTooLong =>
      'يجب ألا يتجاوز الاقتباس 400 حرف. حدّد جزءًا أقصر.';

  @override
  String get errQuoteCardLimit =>
      'أنشأت بطاقات اقتباس كثيرة خلال هذه الساعة. حاول مرة أخرى لاحقًا.';

  @override
  String get errQuoteCardBusy =>
      'يجري تجهيز بطاقات كثيرة حاليًا. حاول مرة أخرى بعد قليل.';

  @override
  String get errQuoteCardFailed => 'تعذّر تجهيز بطاقة الاقتباس. حاول مرة أخرى.';

  @override
  String get errQuoteCardOffline =>
      'يلزمك اتصال بالإنترنت لإنشاء بطاقة اقتباس.';

  @override
  String get updateRequiredTitle => 'حدِّث ReadIn';

  @override
  String get updateRequiredBody =>
      'لم يعد هذا الإصدار مدعومًا. حدِّث التطبيق إلى أحدث إصدار لمتابعة القراءة.';

  @override
  String get updateRequiredAction => 'حدِّث الآن';
}
