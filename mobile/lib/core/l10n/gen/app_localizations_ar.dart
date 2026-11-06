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
  String get navHome => 'الرئيسية';

  @override
  String get navExplore => 'استكشف';

  @override
  String get navWrite => 'اكتب';

  @override
  String get navSaved => 'المحفوظات';

  @override
  String get navProfile => 'حسابي';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الـ streak بتاعك: $count يوم',
      many: 'الـ streak بتاعك: $count يوم',
      few: 'الـ streak بتاعك: $count أيام',
      two: 'الـ streak بتاعك: يومين',
      one: 'الـ streak بتاعك: يوم واحد',
    );
    return '$_temp0';
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
  String get fontSizeXl => 'كبير جداً';

  @override
  String get langToggleArEg => 'مصري + EN';

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
  String get glossaryInEnglish => 'بالإنجليزي';

  @override
  String get glossaryInArabic => 'بالعربي';

  @override
  String get glossaryArticles => 'مقالات فيها المصطلح ده';

  @override
  String get glossaryNotFound => 'المصطلح ده لسه مش في القاموس';

  @override
  String get relatedArticles => 'مقالات ذات صلة';

  @override
  String get resumePickedUp => 'كمّلنا من مكان ما وقفت';

  @override
  String get resumeStartOver => 'من الأول';

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
  String get profilePathsEmptyTitle => 'مفيش مسارات لسه';

  @override
  String get profilePathsEmptyOwnBody => 'انضم لمسار وتقدّمك هيظهر هنا.';

  @override
  String get profilePathsEmptyBody => 'المسارات اللي هينضم لها هتظهر هنا.';

  @override
  String get profilePathsPrivateTitle => 'المسارات خاصة';

  @override
  String get profilePathsPrivateBody =>
      'صاحب الحساب مخلّي نشاط القراءة بتاعه خاص.';

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
  String get profileWhoCanMention => 'مين يقدر يعمل لك منشن';

  @override
  String get profileWhoCanMentionEveryone => 'أي حد';

  @override
  String get profileWhoCanMentionFollowing => 'الناس اللي بتابعهم';

  @override
  String get profileWhoCanMentionNobody => 'محدش';

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
  String get profileHeadlineLabel => 'المسمى';

  @override
  String get profileHeadlineHint =>
      'مثلاً: Senior Full Stack .NET Engineer | .NET';

  @override
  String get profileHeadlineHelper => 'اختياري: سطر واحد بيظهر تحت اسمك.';

  @override
  String get profileLinksSection => 'روابط';

  @override
  String get profileLinksHint => 'ضيف لحد 8 روابط لحساباتك.';

  @override
  String get profileLinksFull => 'دول 8 روابط. شيل واحد عشان تضيف غيره.';

  @override
  String profileLinksCountSemantics(int count, int max) {
    return 'الروابط: $count من $max';
  }

  @override
  String get profileLinkAdd => 'إضافة رابط';

  @override
  String get profileLinkPickPlatform => 'اختار المنصة';

  @override
  String get profileLinkPlatformAdded => 'مضاف بالفعل';

  @override
  String get profileLinkChangePlatform => 'غيّر المنصة';

  @override
  String get profileLinkUrl => 'الرابط';

  @override
  String get profileLinkLabel => 'اسم الرابط';

  @override
  String get profileLinkLabelHint => 'مثلاً: البودكاست بتاعي';

  @override
  String get profileLinkOther => 'تاني';

  @override
  String profileLinkOptions(String name) {
    return 'خيارات رابط $name';
  }

  @override
  String get profileLinkMoveUp => 'حرّكه لفوق';

  @override
  String get profileLinkMoveDown => 'حرّكه لتحت';

  @override
  String get profileLinkRemove => 'شيل الرابط';

  @override
  String get profileTabReposts => 'إعادة النشر';

  @override
  String get profileRepostsEmptyTitle => 'مفيش إعادة نشر لسه';

  @override
  String get profileRepostsEmptyBody => 'المقالات اللي بيعيد نشرها هتظهر هنا.';

  @override
  String get profileRepostsEmptyOwnTitle => 'لسه معدتش نشر أي مقال';

  @override
  String get profileRepostsEmptyOwnBody =>
      'لما تعيد نشر مقال عجبك، هيظهر هنا وعند متابعينك.';

  @override
  String get profileErrHeadlineTooLong => 'المسمى لازم يكون 120 حرف أو أقل.';

  @override
  String get profileErrHeadlineInvalid =>
      'المسمى لازم يكون سطر واحد من غير رموز خاصة.';

  @override
  String get profileErrLinkTooMany => 'تقدر تضيف 8 روابط بس.';

  @override
  String get profileErrLinkPlatformInvalid => 'اختار المنصة من القايمة.';

  @override
  String get profileErrLinkDuplicatePlatform => 'عندك رابط للمنصة دي بالفعل.';

  @override
  String get profileErrLinkTooLong => 'الرابط لازم يكون 500 حرف أو أقل.';

  @override
  String get profileErrLinkHttpsRequired => 'الرابط لازم يبدأ بـ https.';

  @override
  String get profileErrLinkUrlInvalid => 'الرابط ده مش صحيح.';

  @override
  String get profileErrLinkHostMismatch =>
      'الرابط ده مش على موقع المنصة اللي اخترتها.';

  @override
  String get profileErrLinkLabelRequired => 'اكتب اسم للرابط.';

  @override
  String get profileErrLinkLabelInvalid =>
      'اسم الرابط لازم يكون من 2 لـ 30 حرف في سطر واحد.';

  @override
  String get profileErrLinkLabelNotAllowed => 'الاسم للروابط من نوع «تاني» بس.';

  @override
  String get moderationUserLinks => 'روابط البروفايل';

  @override
  String get moderationUserNoLinks => 'مفيش روابط.';

  @override
  String get moderationUserHeadline => 'المسمى';

  @override
  String get moderationUserNoHeadline => 'مفيش مسمى.';

  @override
  String get moderationClearLinks => 'امسح الروابط';

  @override
  String moderationClearLinksTitle(String name) {
    return 'تمسح كل روابط $name؟';
  }

  @override
  String get moderationClearLinksBody =>
      'كل الروابط اللي في بروفايله هتتمسح. مش هيوصله إشعار، والإجراء هيتسجل.';

  @override
  String get moderationLinksCleared => 'الروابط اتمسحت';

  @override
  String get moderationClearHeadline => 'امسح المسمى';

  @override
  String moderationClearHeadlineTitle(String name) {
    return 'تمسح مسمى $name؟';
  }

  @override
  String get moderationClearHeadlineBody =>
      'المسمى اللي تحت اسمه هيتمسح من البروفايل والكروت والتعليقات. مش هيوصله إشعار، والإجراء هيتسجل.';

  @override
  String get moderationHeadlineCleared => 'المسمى اتمسح';

  @override
  String get moderationLogUserClearLinks => 'مسح الروابط';

  @override
  String get moderationLogUserClearHeadline => 'مسح المسمى';

  @override
  String notifArticleReposted(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name و$others غيره أعادوا نشر مقالك',
      many: '$name و$others غيره أعادوا نشر مقالك',
      few: '$name و$others غيره أعادوا نشر مقالك',
      two: '$name واتنين غيره أعادوا نشر مقالك',
      one: '$name وشخص تاني أعادوا نشر مقالك',
      zero: '$name أعاد نشر مقالك',
    );
    return '$_temp0';
  }

  @override
  String get notificationTypeArticleReposted => 'إعادة النشر';

  @override
  String get notificationTypeArticleRepostedHint => 'لما حد يعيد نشر مقالك';

  @override
  String get pdfStripDownload => 'حمّل ملف الـ PDF';

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
  String get deleteAccountTitle => 'احذف حسابك';

  @override
  String get deleteAccountLead =>
      'ده بيحذف حسابك على ReadIn نهائيًا. مينفعش ترجع فيه، ومش هنقدر نرجّعه.';

  @override
  String get deleteAccountDeletedHeading => 'هنحذف فورًا';

  @override
  String get deleteAccountDeletedProfile =>
      'بروفايلك: الاسم واسم المستخدم والصورة والمسمى والنبذة والروابط';

  @override
  String get deleteAccountDeletedContact =>
      'رقم تليفونك وإيميلك وكلمة السر ورمز الاسترداد';

  @override
  String get deleteAccountDeletedSignIns =>
      'ربط حسابك بجوجل وأبل، وبنلغي صلاحية ReadIn عند أبل كمان.';

  @override
  String get deleteAccountDeletedDrafts =>
      'المسودات وأي مقال مش منشور، بالصور وملفات الـ PDF اللي فيها، وأي صورة أو ملف تاني رفعته';

  @override
  String get deleteAccountDeletedActivity =>
      'اهتماماتك وتقدّمك في القراية وإحصائياتك، وتفاعلاتك وإعادات نشرك والجمل اللي علّمتها (الـ Highlights) وإعجاباتك بالتعليقات والبلاغات اللي بعتّها، والمقالات المحفوظة والمجموعات، وأقسام مقالاتك (مقالاتك المنشورة بتفضل من غير قسم)، واللي بتتابعهم واللي بيتابعوك، والكتّاب والمجالات والمواضيع اللي كتمتها (وكتم الناس ليك)، واختياراتك \"قلّل من النوع ده\"';

  @override
  String get deleteAccountDeletedDevices =>
      'أجهزتك ورموز الإشعارات، فمش هيوصلك أي إشعار';

  @override
  String get deleteAccountDeletedSecurityLog =>
      'سجل الأمان بتاع حسابك: تسجيلات الدخول وتغييرات الحساب';

  @override
  String get deleteAccountKeptHeading => 'اللي بنحتفظ بيه وليه';

  @override
  String get deleteAccountKeptPublished =>
      'مقالاتك المنشورة وتعليقاتك بتفضل موجودة باسم «مستخدم محذوف»، بالصور وملفات الـ PDF اللي فيها: من غير اسمك أو اسم المستخدم أو صورتك، ومن غير أي حاجة تربطها بيك. ده عشان الروابط والنقاشات اللي غيرك معتمد عليها تفضل شغالة. لو عايز تشيل مقال، احذفه قبل ما تحذف حسابك.';

  @override
  String get deleteAccountKeptRecord =>
      'سجل إن الحساب ده اتحذف: الـ ID الداخلي ووقت الحذف بس، من غير أي حاجة تعرّف بيك. بيثبت إن الحذف حصل.';

  @override
  String get deleteAccountKeptBackups =>
      'النسخ الاحتياطية من قاعدة البيانات ممكن يفضل فيها بياناتك لحد 14 يوم، لحد ما تتمسح.';

  @override
  String get deleteAccountKeptReviews =>
      'تعديلاتك على مقالات كتّاب تانيين بتفضل مع المقالات دي، من غير اسمك.';

  @override
  String get deleteAccountAfter =>
      'بعد الحذف، رقم التليفون أو الإيميل أو حساب جوجل أو أبل ده يقدر يعمل حساب جديد على ReadIn، وهيبدأ فاضي.';

  @override
  String get deleteAccountByEmail => 'احذفه بالإيميل بدل كده';

  @override
  String get deleteAccountPasswordBody => 'اكتب كلمة السر عشان تحذف حسابك.';

  @override
  String get deleteAccountProviderBody =>
      'سجّل دخول تاني بالحساب المربوط بـ ReadIn.';

  @override
  String get confirmWithGoogle => 'أكّد بجوجل';

  @override
  String get confirmWithApple => 'أكّد بأبل';

  @override
  String get confirmedWithGoogle => 'اتأكدنا إنه انت بجوجل';

  @override
  String get confirmedWithApple => 'اتأكدنا إنه انت بأبل';

  @override
  String get deleteAccountAppleUnavailable =>
      'حسابك مربوط بأبل. أكّد بأبل من تطبيق ReadIn على الآيفون، أو ابعتلنا إيميل نحذفه.';

  @override
  String get deleteAccountConfirm => 'فاهم، احذف حسابي';

  @override
  String get deleteAccountButton => 'احذف حسابي';

  @override
  String get deletingAccount => 'بنحذف حسابك…';

  @override
  String get deleteAccountDialogTitle => 'تحذف حسابك نهائيًا؟';

  @override
  String get deleteAccountDialogBody => 'مينفعش ترجع في الخطوة دي.';

  @override
  String get deleteAccountDialogConfirm => 'احذف نهائيًا';

  @override
  String get deleteAccountOffline =>
      'انت مش متصل بالإنترنت. اتصل الأول عشان تحذف حسابك.';

  @override
  String get accountDeleted => 'تم حذف حسابك.';

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
  String get devLoginSuspended => 'موقوف';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الـ streak بتاعك: $count يوم. لسه مقرتش النهارده.',
      many: 'الـ streak بتاعك: $count يوم. لسه مقرتش النهارده.',
      few: 'الـ streak بتاعك: $count أيام. لسه مقرتش النهارده.',
      two: 'الـ streak بتاعك: يومين. لسه مقرتش النهارده.',
      one: 'الـ streak بتاعك: يوم واحد. لسه مقرتش النهارده.',
    );
    return '$_temp0';
  }

  @override
  String readingStreakFreezePendingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'الـ streak بتاعك: $count يوم. فاتك امبارح: اقرا النهارده والـ freeze هيحافظ على الـ streak.',
      many:
          'الـ streak بتاعك: $count يوم. فاتك امبارح: اقرا النهارده والـ freeze هيحافظ على الـ streak.',
      few:
          'الـ streak بتاعك: $count أيام. فاتك امبارح: اقرا النهارده والـ freeze هيحافظ على الـ streak.',
      two:
          'الـ streak بتاعك: يومين. فاتك امبارح: اقرا النهارده والـ freeze هيحافظ على الـ streak.',
      one:
          'الـ streak بتاعك: يوم واحد. فاتك امبارح: اقرا النهارده والـ freeze هيحافظ على الـ streak.',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم ورا بعض!',
      many: '$count يوم ورا بعض!',
      few: '$count أيام ورا بعض!',
      two: 'يومين ورا بعض!',
      one: 'يوم واحد!',
    );
    return '$_temp0';
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
  String get redo => 'إعادة';

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
  String get commentsHideReplies => 'إخفاء الردود';

  @override
  String get commentsRepliesFailed => 'مقدرناش نحمّل الردود.';

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
  String get pdfDownload => 'تحميل PDF';

  @override
  String get pdfPreparing => 'بنجهز الـ PDF…';

  @override
  String get pdfRetry => 'حاول تاني';

  @override
  String get pdfLanguageTitle => 'أنهي نسخة؟';

  @override
  String get pdfLanguageBody =>
      'المقال ده منشور بلغتين. اختار النسخة اللي عايز تحمّلها PDF.';

  @override
  String get errArticlePdfNotFound => 'المقال مش موجود.';

  @override
  String get errArticlePdfHidden =>
      'المشرفين خفّوا المقال ده، فمينفعش يتحمّل PDF.';

  @override
  String get errArticlePdfLimit =>
      'حمّلت PDFs كتير الساعة دي. حاول تاني بعد شوية.';

  @override
  String get errArticlePdfBusy =>
      'فيه PDFs كتير بتتجهز دلوقتي. حاول تاني كمان شوية.';

  @override
  String get errArticlePdfFailed => 'معرفناش نجهّز الـ PDF. حاول تاني.';

  @override
  String get errArticlePdfOffline => 'محتاج إنترنت عشان تحمّل الـ PDF.';

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
  String get tagsLabel => 'التاجات';

  @override
  String get tagsHint => 'اكتب تاج ودوس Enter أو فاصلة';

  @override
  String tagsLimit(int count) {
    return '$count من 5';
  }

  @override
  String removeTag(String tag) {
    return 'شيل $tag';
  }

  @override
  String get tagsFull =>
      'دول 5 تاجات، أقصى عدد للمقال. شيل واحد عشان تضيف غيره.';

  @override
  String get tagsAdd => 'ضيف';

  @override
  String tagCreate(String name) {
    return 'إنشاء تاج جديد: $name';
  }

  @override
  String get tagSuggestionsLabel => 'تاجات مقترحة';

  @override
  String get tagAlreadyAdded => 'التاج ده موجود على المقال بالفعل.';

  @override
  String get tagTooShort => 'التاج لازم يكون حرفين على الأقل.';

  @override
  String get tagTooLong => 'التاج ميزيدش عن 30 حرف.';

  @override
  String get tagInvalidCharacters =>
      'استخدم حروف وأرقام ومسافات و ⁦- _ . + #⁩ بس.';

  @override
  String get tagNoLetter => 'التاج لازم يكون فيه حرف أو رقم على الأقل.';

  @override
  String problemTagHidden(String name) {
    return 'التاج $name مش متاح، شيله أو اختار تاج تاني.';
  }

  @override
  String problemTagLimit(String name) {
    return 'عملت تاجات جديدة كتير النهارده، فالتاج $name مش هيتضاف دلوقتي. اختار تاج موجود أو جرّب بعدين.';
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
  String get tableDeleteRow => 'امسح الصف';

  @override
  String get tableDeleteColumn => 'امسح العمود';

  @override
  String get tableDelete => 'امسح الجدول';

  @override
  String get tableTools => 'الجدول';

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
  String get formatTerm => 'مصطلح من القاموس';

  @override
  String get termPickerFor => 'اعمله مصطلح من القاموس:';

  @override
  String get termPickerCurrent => 'مصطلح من القاموس:';

  @override
  String get termSearchHint => 'دوّر في القاموس (المصطلح بالإنجليزي)';

  @override
  String get termSearching => 'بندوّر…';

  @override
  String get termNoMatches =>
      'مفيش مصطلح زي كده في القاموس. جرّب المصطلح بالإنجليزي.';

  @override
  String get termTypeToSearch => 'اكتب مصطلح عشان تدوّر في القاموس.';

  @override
  String get termSearchError => 'معرفناش ندوّر في القاموس.';

  @override
  String get termRemove => 'شيل المصطلح';

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

  @override
  String get errAppleConfirmationRequired =>
      'حسابك مربوط بأبل. أكّد بأبل عشان تحذفه.';

  @override
  String get errDeletionUnavailable =>
      'معرفناش نكمّل حذف حسابك، فمفيش حاجة اتحذفت. جرّب تاني بعد شوية.';

  @override
  String get continueReading => 'كمّل القراءة';

  @override
  String continueReadingProgress(int percent) {
    return 'قريت $percent%';
  }

  @override
  String get pathsTitle => 'المسارات';

  @override
  String get pathsTabAll => 'كل المسارات';

  @override
  String get pathsTabMine => 'مساراتي';

  @override
  String get pathsPrompt => 'اتعلم خطوة بخطوة مع المسارات';

  @override
  String get pathsBrowse => 'استكشف المسارات';

  @override
  String get pathsEmptyTitle => 'مفيش مسارات هنا لسه';

  @override
  String get pathsEmptyBody => 'بنجهّز أول المسارات. ارجع قريب.';

  @override
  String get myPathsEmptyTitle => 'لسه مبدأتش أي مسار';

  @override
  String get myPathsEmptyBody => 'اختار مسار واتعلم موضوع مقال ورا مقال.';

  @override
  String get myPathsGuestTitle => 'تابع مساراتك';

  @override
  String get myPathsGuestBody =>
      'اعمل حساب مجاني عشان تنضم للمسارات وتكمّل من مكان ما وقفت.';

  @override
  String pathArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقال',
      few: '$count مقالات',
      two: 'مقالين',
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
      few: '$minutes دقايق',
      two: 'دقيقتين',
      one: 'دقيقة',
    );
    return '$_temp0';
  }

  @override
  String pathProgressSemantics(int read, int total) {
    return 'قريت $read من $total';
  }

  @override
  String get pathCompleted => 'خلصت المسار';

  @override
  String get pathCompletedCelebration => 'خلصت المسار 🎉';

  @override
  String get pathStart => 'ابدأ المسار';

  @override
  String pathContinue(String title) {
    return 'كمّل: $title';
  }

  @override
  String get pathReadAgain => 'اقرأ من الأول';

  @override
  String pathNext(String title) {
    return 'التالي: $title';
  }

  @override
  String get pathUpNext => 'التالي';

  @override
  String get pathItemRead => 'اتقرا';

  @override
  String get pathMenu => 'اختيارات المسار';

  @override
  String get pathLeave => 'سيب المسار';

  @override
  String get pathLeaveTitle => 'تسيب المسار ده؟';

  @override
  String get pathLeaveBody =>
      'تاريخ قراءتك هيفضل زي ما هو، ولو رجعت للمسار تاني هتلاقي تقدّمك مكانه.';

  @override
  String get pathLeft => 'سيبت المسار';

  @override
  String get pathJoin => 'انضم للمسار';

  @override
  String get pathJoined => 'انضميت للمسار';

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
  String get pathLastArticle => 'ده آخر مقال في المسار';

  @override
  String get pathNotFoundTitle => 'المسار ده مش متاح';

  @override
  String get pathNotFoundBody => 'ممكن يكون اتشال، أو اللينك غلط.';

  @override
  String get errPathNotFound => 'المسار ده مش موجود أو اتشال.';

  @override
  String get errPathSlugTaken => 'فيه مسار تاني بيستخدم اللينك ده.';

  @override
  String get errPathEditorial => 'مسارات التحرير بتتعدّل من ملفات المحتوى.';

  @override
  String get errPathItemsInvalid =>
      'راجع مقالات المسار: من 1 لـ 100 مقال منشور، كل مقال مرة واحدة.';

  @override
  String get reportTitleArticle => 'الإبلاغ عن المقال';

  @override
  String get reportTitleComment => 'الإبلاغ عن التعليق';

  @override
  String get reportTitleUser => 'الإبلاغ عن المستخدم';

  @override
  String get reportBody => 'بتبلّغ ليه؟ فريق الإشراف هيراجع البلاغ.';

  @override
  String get reportReasonSpam => 'سبام';

  @override
  String get reportReasonMisinformation => 'معلومات غلط';

  @override
  String get reportReasonHarassment => 'إساءة أو تنمّر';

  @override
  String get reportReasonCopyright => 'حقوق ملكية';

  @override
  String get reportReasonOther => 'حاجة تانية';

  @override
  String get reportDetails => 'تفاصيل (اختياري)';

  @override
  String get reportSubmit => 'ابعت البلاغ';

  @override
  String get reportThanks => 'شكرًا، هنراجع البلاغ';

  @override
  String errSuspendedUntil(String date) {
    return 'الحساب ده موقوف لحد $date. تواصل مع الدعم';
  }

  @override
  String get errSuspendedPermanently =>
      'الحساب ده موقوف نهائيًا. تواصل مع الدعم';

  @override
  String get errReportOwnContent =>
      'مينفعش تبلّغ عن نفسك أو عن حاجة انت كاتبها.';

  @override
  String get errReportReason => 'اختار سبب.';

  @override
  String get errReportTargetInvalid => 'مينفعش تبلّغ عن ده.';

  @override
  String get errReportTargetNotFound => 'اللي بتبلّغ عنه مبقاش موجود.';

  @override
  String get errModerationActionInvalid => 'الإجراء ده مش متاح هنا.';

  @override
  String get errModerationSelf => 'مينفعش تعمل كده في حسابك.';

  @override
  String get errModerationStaffTarget =>
      'مينفعش تحذّر أو توقف حد من فريق الإشراف.';

  @override
  String get errModerationNoteRequired => 'اكتب ملاحظة الأول.';

  @override
  String get errModerationDurationInvalid => 'اختار مدة من يوم لـ 365 يوم.';

  @override
  String get errModerationNoticeNotFound => 'التنبيه ده مبقاش موجود.';

  @override
  String get articleMenu => 'اختيارات المقال';

  @override
  String get articleMenuReport => 'الإبلاغ عن المقال';

  @override
  String get articleMenuHide => 'إخفاء المقال';

  @override
  String get articleMenuUnhide => 'إظهار المقال';

  @override
  String get articleHiddenBannerTitle => 'المشرفين خبّوا المقال ده';

  @override
  String get articleHiddenBannerBody => 'مش ظاهر غير لكاتبه وللمشرفين.';

  @override
  String get articleMenuShowLess => 'قلّل من النوع ده';

  @override
  String get articleMenuFollow => 'تابع الكاتب';

  @override
  String get articleMenuUnfollow => 'إلغاء متابعة الكاتب';

  @override
  String get articleMenuMuteAuthor => 'كتم الكاتب';

  @override
  String get articleMenuUnmuteAuthor => 'إلغاء كتم الكاتب';

  @override
  String get articleMenuMuteTopics => 'كتم المواضيع';

  @override
  String get showLessDone => 'تمام، هتشوف مقالات أقل من النوع ده.';

  @override
  String muteDone(String name) {
    return 'كتمت $name. مش هتشوف مقالاته ولا تعليقاته.';
  }

  @override
  String muteUnmuted(String name) {
    return 'لغيت كتم $name.';
  }

  @override
  String get muteBannerTitle => 'انت كاتم الكاتب ده';

  @override
  String get muteBannerBody =>
      'مقالاته وتعليقاته مش بتظهرلك، ومحدش غيرك يعرف إنك كاتمه.';

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
      'اللي تكتمه مش هيظهرلك في الفيد والاستكشاف والبحث. تقدر تلغيه من هنا أو من الإعدادات.';

  @override
  String get muteTopicsField => 'المجال كله، بكل مواضيعه';

  @override
  String get muteTopicsTopic => 'الموضوع ده بس';

  @override
  String muteTopicsToggle(String name) {
    return 'كتم $name';
  }

  @override
  String get muteCommentCollapsed => 'تعليق من شخص كتمته';

  @override
  String get muteCommentShow => 'عرض';

  @override
  String get muteSettingsEntry => 'اللي كتمته';

  @override
  String get muteSettingsEntryHint => 'الكتّاب والمجالات والمواضيع اللي كتمتها';

  @override
  String get mutePageTitle => 'اللي كتمته';

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
  String get mutePageEmptyTitle => 'مكتمتش حاجة لسه';

  @override
  String get mutePageEmptyBody =>
      'اكتم كاتب أو مجال أو موضوع من اختيارات أي مقال، وهيظهر هنا.';

  @override
  String get mutePageSubtitle =>
      'مش هيظهرولك في الفيد والاستكشاف والبحث، ومحدش بيعرف إنك كتمتهم.';

  @override
  String get muteMenuUser => 'كتم المستخدم';

  @override
  String get muteMenuUnmuteUser => 'إلغاء كتم المستخدم';

  @override
  String get muteMenuCommenter => 'كتم صاحب التعليق';

  @override
  String get muteMenuUnmuteCommenter => 'إلغاء كتم صاحب التعليق';

  @override
  String get errMuteSelf => 'مينفعش تكتم نفسك.';

  @override
  String get errMuteSystemAccount => 'مينفعش تكتم حساب ReadIn الرسمي.';

  @override
  String get errMuteLimit => 'وصلت لأقصى عدد كتّاب تكتمهم (500).';

  @override
  String get errMuteOwnArticle => 'مينفعش تعمل كده على مقالك.';

  @override
  String get errRepostOwnArticle => 'مينفعش تعيد نشر مقالك.';

  @override
  String get errRepostCaptionTooLong => 'رأيك لازم يكون 500 حرف أو أقل.';

  @override
  String get profileMenu => 'اختيارات تانية';

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
      other: '$count حاجة مستنية مراجعة',
      many: '$count حاجة مستنية مراجعة',
      few: '$count حاجات مستنية مراجعة',
      two: 'حاجتين مستنيين مراجعة',
      one: 'حاجة واحدة مستنية مراجعة',
      zero: 'مفيش حاجة مستنية مراجعة',
    );
    return '$_temp0';
  }

  @override
  String get moderationNoAccessTitle => 'الصفحة دي للمشرفين بس';

  @override
  String get moderationNoAccessBody => 'حسابك مالوش صلاحية الإشراف.';

  @override
  String get moderationTabOpen => 'مفتوحة';

  @override
  String get moderationTabResolved => 'اتحلّت';

  @override
  String get moderationTabDismissed => 'اترفضت';

  @override
  String get moderationTabLog => 'السجل';

  @override
  String get moderationFilterAll => 'الكل';

  @override
  String get moderationFilterArticles => 'مقالات';

  @override
  String get moderationFilterComments => 'تعليقات';

  @override
  String get moderationFilterUsers => 'مستخدمين';

  @override
  String get moderationEmptyOpenTitle => 'مفيش بلاغات مفتوحة';

  @override
  String get moderationEmptyOpenBody => 'كله تمام دلوقتي.';

  @override
  String get moderationEmptyResolvedTitle => 'مفيش بلاغات اتحلّت';

  @override
  String get moderationEmptyDismissedTitle => 'مفيش بلاغات اترفضت';

  @override
  String get moderationEmptyLogTitle => 'لسه مفيش إجراءات';

  @override
  String get moderationLoadMoreFailed => 'مقدرناش نحمّل أكتر.';

  @override
  String get moderationTypeArticle => 'مقال';

  @override
  String get moderationTypeComment => 'تعليق';

  @override
  String get moderationTypeUser => 'مستخدم';

  @override
  String get moderationStateHidden => 'متخبّي';

  @override
  String get moderationStateDeleted => 'اتمسح';

  @override
  String get moderationStateSuspended => 'موقوف';

  @override
  String get moderationStatusOpen => 'مفتوح';

  @override
  String get moderationStatusResolved => 'اتحل';

  @override
  String get moderationStatusDismissed => 'اترفض';

  @override
  String moderationReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بلاغ',
      many: '$count بلاغ',
      few: '$count بلاغات',
      two: 'بلاغين',
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
    return 'اتقفل $time';
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
      many: '$count تحذير',
      few: '$count تحذيرات',
      two: 'تحذيرين',
      one: 'تحذير واحد',
      zero: 'مفيش تحذيرات',
    );
    return '$_temp0';
  }

  @override
  String moderationSuspendedUntil(String date) {
    return 'موقوف لحد $date';
  }

  @override
  String get moderationSuspendedForever => 'موقوف نهائيًا';

  @override
  String get moderationCaseArticle => 'مقال عليه بلاغات';

  @override
  String get moderationCaseComment => 'تعليق عليه بلاغات';

  @override
  String get moderationCaseUser => 'مستخدم عليه بلاغات';

  @override
  String get moderationOpenArticle => 'افتح المقال';

  @override
  String get moderationOpenProfile => 'افتح البروفايل';

  @override
  String get moderationActions => 'الإجراءات';

  @override
  String moderationReportsTitle(int count) {
    return 'البلاغات ($count)';
  }

  @override
  String get moderationHistory => 'السجل';

  @override
  String get moderationHistoryEmpty => 'لسه مفيش إجراءات.';

  @override
  String moderationClosedBy(String name) {
    return 'قفله $name';
  }

  @override
  String get moderationHideComment => 'إخفاء التعليق';

  @override
  String get moderationUnhideComment => 'إظهار التعليق';

  @override
  String get moderationDeleteComment => 'مسح التعليق';

  @override
  String get moderationWarnAuthor => 'تحذير الكاتب';

  @override
  String get moderationSuspendAuthor => 'إيقاف حساب الكاتب';

  @override
  String get moderationUnsuspend => 'رجّع الحساب';

  @override
  String get moderationDismiss => 'ارفض البلاغات';

  @override
  String get moderationHideArticleTitle => 'تخفي المقال ده؟';

  @override
  String get moderationHideArticleBody =>
      'هيختفي من الفيد والقوايم والبحث، ومحدش هيقدر يفتحه غير كاتبه والمشرفين. كاتبه هيوصله تنبيه.';

  @override
  String get moderationHideCommentTitle => 'تخفي التعليق ده؟';

  @override
  String get moderationHideCommentBody =>
      'القرّاء هيشوفوا مكانه «المشرفين خبّوا التعليق ده».';

  @override
  String get moderationNoteOptional => 'ملاحظة (اختياري)';

  @override
  String get moderationNoteLabel => 'ملاحظة';

  @override
  String get moderationNoteForUser => 'الملاحظة دي هتوصله.';

  @override
  String moderationWarnTitle(String name) {
    return 'تحذير $name';
  }

  @override
  String get moderationWarnBody =>
      'هيوصله تحذير فيه ملاحظتك، ولازم يأكد إنه شافه.';

  @override
  String get moderationWarnConfirm => 'ابعت التحذير';

  @override
  String moderationSuspendTitle(String name) {
    return 'إيقاف حساب $name';
  }

  @override
  String get moderationSuspendBody =>
      'مش هيقدر يدخل على حسابه ولا يستخدمه لحد ما الإيقاف يخلص.';

  @override
  String get moderationSuspendDuration => 'المدة';

  @override
  String moderationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يوم',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get moderationPermanent => 'نهائي';

  @override
  String get moderationSuspendConfirm => 'أوقف الحساب';

  @override
  String moderationUnsuspendTitle(String name) {
    return 'ترجّع حساب $name؟';
  }

  @override
  String get moderationUnsuspendBody =>
      'هيقدر يدخل ويستخدم حسابه تاني على طول.';

  @override
  String get moderationDismissTitle => 'ترفض البلاغات دي؟';

  @override
  String get moderationDismissBody =>
      'البلاغات المفتوحة هتتقفل على إنها اترفضت، والمحتوى هيفضل زي ما هو.';

  @override
  String get moderationArticleHidden => 'المقال اتخبّى';

  @override
  String get moderationArticleUnhidden => 'المقال ظهر تاني';

  @override
  String get moderationWarned => 'التحذير اتبعت';

  @override
  String get moderationSuspended => 'الحساب اتوقف';

  @override
  String get moderationUnsuspended => 'الحساب رجع';

  @override
  String get moderationDismissed => 'البلاغات اترفضت';

  @override
  String get moderationLogCommentHide => 'خبّى تعليق';

  @override
  String get moderationLogCommentUnhide => 'ظهّر تعليق';

  @override
  String get moderationLogCommentDelete => 'مسح تعليق';

  @override
  String get moderationLogArticleHide => 'خبّى مقال';

  @override
  String get moderationLogArticleUnhide => 'ظهّر مقال';

  @override
  String get moderationLogUserWarn => 'حذّر مستخدم';

  @override
  String get moderationLogUserSuspend => 'وقّف حساب';

  @override
  String get moderationLogUserUnsuspend => 'رجّع حساب';

  @override
  String get moderationLogReportsDismiss => 'رفض بلاغات';

  @override
  String get moderationLogOther => 'إجراء إشراف';

  @override
  String moderationLogReportsClosed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قفل $count بلاغ',
      many: 'قفل $count بلاغ',
      few: 'قفل $count بلاغات',
      two: 'قفل بلاغين',
      one: 'قفل بلاغ واحد',
    );
    return '$_temp0';
  }

  @override
  String moderationLogUntil(String date) {
    return 'لحد $date';
  }

  @override
  String get noticeWarningTitle => 'وصلك تحذير من فريق الإشراف';

  @override
  String get noticeWarningBody =>
      'اقرا الملاحظة وخليك ماشي على قواعد مجتمع ReadIn.';

  @override
  String noticeArticleHiddenTitle(String title) {
    return 'مقالك «$title» اتخفى';
  }

  @override
  String get noticeArticleHiddenBody =>
      'القرّاء مبقوش شايفينه. انت والمشرفين بس اللي تقدروا تفتحوه.';

  @override
  String get noticeNoteLabel => 'ملاحظة المشرف';

  @override
  String get noticeAcknowledge => 'فهمت';

  @override
  String get notificationsMarkAllRead => 'علّم الكل مقروء';

  @override
  String get notificationsNewItems => 'فيه إشعارات جديدة، اعرضها';

  @override
  String get notificationsToday => 'النهارده';

  @override
  String get notificationsEarlier => 'قبل كده';

  @override
  String get notificationsEmptyTitle => 'مفيش إشعارات لسه';

  @override
  String get notificationsEmptyBody =>
      'الردود والمنشن والمتابعين الجداد ومقال النهارده هيظهروا هنا.';

  @override
  String get notificationsUnreadDot => 'جديد';

  @override
  String notifNewFollower(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name و$others غيره بدأوا يتابعوك',
      many: '$name و$others غيره بدأوا يتابعوك',
      few: '$name و$others غيره بدأوا يتابعوك',
      two: '$name واتنين غيره بدأوا يتابعوك',
      one: '$name وواحد غيره بدأوا يتابعوك',
      zero: '$name بدأ يتابعك',
    );
    return '$_temp0';
  }

  @override
  String notifArticleComment(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name و$others غيره علّقوا على مقالك',
      many: '$name و$others غيره علّقوا على مقالك',
      few: '$name و$others غيره علّقوا على مقالك',
      two: '$name واتنين غيره علّقوا على مقالك',
      one: '$name وواحد غيره علّقوا على مقالك',
      zero: '$name علّق على مقالك',
    );
    return '$_temp0';
  }

  @override
  String notifCommentReply(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name و$others غيره ردّوا على تعليقك',
      many: '$name و$others غيره ردّوا على تعليقك',
      few: '$name و$others غيره ردّوا على تعليقك',
      two: '$name واتنين غيره ردّوا على تعليقك',
      one: '$name وواحد غيره ردّوا على تعليقك',
      zero: '$name ردّ على تعليقك',
    );
    return '$_temp0';
  }

  @override
  String notifMention(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name و$others غيره عملوا لك منشن في تعليق',
      many: '$name و$others غيره عملوا لك منشن في تعليق',
      few: '$name و$others غيره عملوا لك منشن في تعليق',
      two: '$name واتنين غيره عملوا لك منشن في تعليق',
      one: '$name وواحد غيره عملوا لك منشن في تعليق',
      zero: '$name عمل لك منشن في تعليق',
    );
    return '$_temp0';
  }

  @override
  String notifMentionArticle(String name) {
    return '$name عمل لك منشن في مقال';
  }

  @override
  String notifFollowedWriterArticle(String name) {
    return '$name نشر مقال جديد';
  }

  @override
  String notifReactionsMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مقالك وصل لـ $count تفاعل 🎉',
      many: 'مقالك وصل لـ $count تفاعل 🎉',
      few: 'مقالك وصل لـ $count تفاعلات 🎉',
      two: 'مقالك وصل لتفاعلين 🎉',
      one: 'أول تفاعل على مقالك 🎉',
    );
    return '$_temp0';
  }

  @override
  String get notifReactionsMilestoneGeneric => 'القرّاء بيتفاعلوا مع مقالك 🎉';

  @override
  String get notifDailyArticle => 'مقال النهارده جاهز ☕';

  @override
  String notifStreakReminder(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'اقرا مقال النهارده عشان الـ streak بتاعك ($days يوم) ميضيعش 🔥',
      many: 'اقرا مقال النهارده عشان الـ streak بتاعك ($days يوم) ميضيعش 🔥',
      few: 'اقرا مقال النهارده عشان الـ streak بتاعك ($days أيام) ميضيعش 🔥',
      two: 'اقرا مقال النهارده عشان الـ streak بتاعك (يومين) ميضيعش 🔥',
      one: 'اقرا مقال النهارده عشان الـ streak بتاعك (يوم واحد) ميضيعش 🔥',
    );
    return '$_temp0';
  }

  @override
  String get notifStreakReminderGeneric =>
      'اقرا مقال النهارده عشان الـ streak بتاعك ميضيعش 🔥';

  @override
  String get notifSecurityPasswordChanged => 'كلمة السر بتاعتك اتغيّرت';

  @override
  String get notifSecurityPasswordReset => 'اتعمل reset لكلمة السر بتاعتك';

  @override
  String get notifSecurityRecoveryPinChanged =>
      'الـ PIN بتاع استرجاع الحساب اتغيّر';

  @override
  String get notifSecurityPhoneNumberChanged => 'رقم تليفونك اتغيّر';

  @override
  String get notifSecurityRecoveryLockedOut =>
      'استرجاع الحساب اتقفل بعد محاولات PIN غلط كتير';

  @override
  String get notifSecurityExternalLoginLinked =>
      'اتربط حساب Google أو Apple بحسابك';

  @override
  String get notifSecurityExternalLoginUnlinked =>
      'اتشال ربط حساب Google أو Apple من حسابك';

  @override
  String get notifSecurityPhoneSignInAdded =>
      'اتضاف رقم تليفون وكلمة سر لحسابك';

  @override
  String get notifSecurityGeneric => 'حصل تغيير أمني في حسابك';

  @override
  String get notifSecurityHint =>
      'لو مش انت اللي عملت كده، غيّر كلمة السر دلوقتي.';

  @override
  String get notifVerificationResult => 'فيه جديد في طلب التوثيق بتاعك';

  @override
  String get notifVerificationApproved => 'بقيت كاتب موثّق ✓';

  @override
  String get notifVerificationRejected => 'طلب التوثيق بتاعك ماتقبلش';

  @override
  String get notifVerificationRejectedHint => 'افتحه عشان تعرف السبب';

  @override
  String get notifModerationWarning => 'وصلك تحذير من فريق الإشراف';

  @override
  String get notifModerationArticleHidden => 'المشرفين خبّوا مقالك';

  @override
  String get notifGeneric => 'عندك إشعار جديد';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get notificationSettingsEntryHint =>
      'Push أو جوه التطبيق أو مقفول لكل نوع، وساعات الهدوء';

  @override
  String get notificationSettingsTypesTitle => 'إيه اللي يوصلك';

  @override
  String get notificationSettingsTypesHint =>
      'الـ push بيظهر كمان في الإشعارات جوه التطبيق.';

  @override
  String get notificationModeAll => 'Push + جوه التطبيق';

  @override
  String get notificationModeInApp => 'جوه التطبيق بس';

  @override
  String get notificationModeOff => 'مقفول';

  @override
  String get notificationModeAllShort => 'Push';

  @override
  String get notificationModeInAppShort => 'جوه التطبيق';

  @override
  String get notificationTypeNewFollower => 'متابعين جداد';

  @override
  String get notificationTypeArticleComment => 'تعليقات على مقالاتك';

  @override
  String get notificationTypeCommentReply => 'ردود على تعليقاتك';

  @override
  String get notificationTypeMention => 'المنشن';

  @override
  String get notificationTypeMentionHint =>
      'لما حد يعمل لك منشن في تعليق أو مقال';

  @override
  String get notificationTypeReactionsMilestone =>
      'أرقام التفاعل (10 و50 و100)';

  @override
  String get notificationTypeFollowedWriterArticle =>
      'مقالات جديدة من كتّاب بتتابعهم';

  @override
  String get notificationTypeDailyArticle => 'مقال النهارده';

  @override
  String get notificationTypeStreakReminder => 'تذكير الـ streak (8 بالليل)';

  @override
  String get notificationSecurityAlerts => 'تنبيهات الأمان';

  @override
  String get notificationSecurityAlertsHint =>
      'شغالة دايماً، حتى في ساعات الهدوء.';

  @override
  String get quietHoursTitle => 'ساعات الهدوء';

  @override
  String get quietHoursHint =>
      'الـ push بيستنى لحد ما ساعات الهدوء تخلص. تنبيهات الأمان بتوصل على طول.';

  @override
  String get quietHoursSwitch => 'أجّل الـ push في الساعات دي';

  @override
  String get quietHoursFrom => 'من';

  @override
  String get quietHoursTo => 'لحد';

  @override
  String get errNotificationNotFound => 'الإشعار ده مبقاش موجود.';

  @override
  String get errNotificationTypeInvalid => 'نوع الإشعار ده مش موجود.';

  @override
  String get errNotificationModeInvalid =>
      'اختار push أو جوه التطبيق أو مقفول.';

  @override
  String get errNotificationQuietHoursInvalid =>
      'ساعات الهدوء محتاجة وقتين مختلفين.';

  @override
  String get settingsWriting => 'الكتابة';

  @override
  String get verificationTitle => 'توثيق الكاتب';

  @override
  String get verificationEntryHint => 'خُد علامة الكاتب الموثّق';

  @override
  String get verificationStatusVerified => 'انت كاتب موثّق';

  @override
  String get verificationStatusPending => 'طلبك تحت المراجعة';

  @override
  String get verificationStatusRejected => 'ماتقبلش، افتحه عشان تعرف السبب';

  @override
  String get verificationIntro =>
      'الكتّاب الموثّقين بياخدوا علامة جنب اسمهم على مقالاتهم وبروفايلهم وتعليقاتهم. قولّنا بتشتغل إيه ووريّنا دليل.';

  @override
  String get verificationFieldLabel => 'المجال';

  @override
  String get verificationFieldHint => 'اختار مجالك';

  @override
  String get verificationFieldsFailed => 'مقدرناش نحمّل المجالات.';

  @override
  String get verificationJobTitleLabel => 'المسمّى الوظيفي';

  @override
  String get verificationJobTitleHint => 'مثلاً Senior Backend Engineer';

  @override
  String get verificationProofTitle => 'الدليل';

  @override
  String get verificationProofHint => 'ضيف لينك أو ملف أو الاتنين.';

  @override
  String get verificationProofUrlLabel => 'لينك (LinkedIn أو GitHub…)';

  @override
  String get verificationProofFileAdd => 'ارفع ملف';

  @override
  String get verificationProofFileHint =>
      'شهادة أو كارنيه النقابة: PDF أو JPEG أو PNG أو WebP، لحد 10 ميجا.';

  @override
  String get verificationProofFileRemove => 'شيل الملف';

  @override
  String get verificationProofPrivate =>
      'الملف بيشوفه المراجعين بس، وبيتمسح أول ما طلبك يتحسم.';

  @override
  String get verificationNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get verificationNoteHint => 'أي حاجة عايز المراجعين يعرفوها';

  @override
  String get verificationSubmit => 'ابعت الطلب';

  @override
  String get verificationSubmitting => 'بنبعت طلبك…';

  @override
  String get verificationPendingTitle => 'طلبك تحت المراجعة';

  @override
  String get verificationPendingBody => 'هنبعتلك إشعار أول ما نراجعه.';

  @override
  String verificationSubmittedOn(String date) {
    return 'اتبعت يوم $date';
  }

  @override
  String get verificationLinkLabel => 'اللينك';

  @override
  String get verificationFileLabel => 'الملف';

  @override
  String get verificationNoteSummaryLabel => 'الملاحظة';

  @override
  String get verificationWithdraw => 'اسحب الطلب';

  @override
  String get verificationWithdrawTitle => 'تسحب طلبك؟';

  @override
  String get verificationWithdrawBody =>
      'هيتمسح هو والملف بتاعه. تقدر تبعت طلب جديد في أي وقت.';

  @override
  String get verificationWithdrawConfirm => 'اسحبه';

  @override
  String get verificationWithdrawn => 'الطلب اتسحب';

  @override
  String get verificationApprovedTitle => 'انت كاتب موثّق';

  @override
  String get verificationApprovedBody =>
      'علامة التوثيق بتظهر جنب اسمك على مقالاتك وبروفايلك وتعليقاتك.';

  @override
  String verificationApprovedOn(String date) {
    return 'اتوثّقت يوم $date';
  }

  @override
  String get verificationRejectedTitle => 'طلبك ماتقبلش';

  @override
  String get verificationRejectedReason => 'سبب المراجع';

  @override
  String verificationRejectedOn(String date) {
    return 'اتراجع يوم $date';
  }

  @override
  String get verificationRejectedBody => 'تقدر تكمّل اللي ناقص وتطلب تاني.';

  @override
  String get verificationRequestAgain => 'اطلب تاني';

  @override
  String get verificationUnavailableTitle => 'مش هتقدر تطلب توثيق دلوقتي';

  @override
  String get verificationUnavailableBody =>
      'الحساب الموقوف مش بيقدر يبعت طلبات توثيق.';

  @override
  String get errVerificationProofRequired => 'ضيف لينك أو ملف كدليل.';

  @override
  String get errVerificationProofInvalid =>
      'ملف الدليل لازم يكون PDF أو JPEG أو PNG أو WebP ومايزيدش عن 10 ميجا.';

  @override
  String get errVerificationFieldInvalid => 'اختار مجال من القايمة.';

  @override
  String get errVerificationAlreadyPending => 'عندك طلب تحت المراجعة بالفعل.';

  @override
  String get errVerificationAlreadyVerified => 'انت كاتب موثّق بالفعل.';

  @override
  String get errVerificationNotFound => 'الطلب ده مبقاش مستني مراجعة.';

  @override
  String get errVerificationNotVerified => 'المستخدم ده مش موثّق.';

  @override
  String get errVerificationSystemAccount =>
      'ده حساب ReadIn الرسمي، والتوثيق بتاعه ثابت.';

  @override
  String get healthDisclaimer =>
      'المعلومات دي للتوعية ولا تغني عن استشارة الطبيب.';

  @override
  String get articleToc => 'محتويات المقال';

  @override
  String get settingsSignInForSync =>
      'سجل دخولك عشان تحفظ الإعدادات دي على حسابك.';

  @override
  String get settingsSaved => 'اتحفظت الإعدادات ✓';

  @override
  String get settingsInterests => 'اهتماماتك';

  @override
  String get settingsInterestsHint => 'المجالات والمواضيع اللي بتتابعها';

  @override
  String get interestsPageIntro =>
      'دوس على أي مجال أو موضوع عشان تتابعه أو تلغي متابعته. التغيير بيتحفظ على طول، وعلى أساسه بنختارلك مقالات «ليك».';

  @override
  String get interestsKeepThree => 'خليك متابع 3 اهتمامات على الأقل';

  @override
  String get imageDarkVersion => 'نسخة الوضع الغامق';

  @override
  String get imageDarkAdd => 'ضيف نسخة للوضع الغامق (للرسومات)';

  @override
  String get imageDarkRemove => 'شيل نسخة الوضع الغامق';

  @override
  String get postReadMore => 'اقرأ المزيد';

  @override
  String get postShowLess => 'عرض أقل';

  @override
  String get postReadFullArticle => 'اقرأ المقال كله';

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
  String get repostOwnHint => 'مينفعش تعيد نشر مقالك';

  @override
  String repostLabelOne(String name) {
    return 'أعاد نشره $name';
  }

  @override
  String repostLabelMany(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$name و$count غيره أعادوا نشره',
      one: '$name وشخص تاني أعادوا نشره',
    );
    return '$_temp0';
  }

  @override
  String get repostMenuRepost => 'أعد النشر';

  @override
  String get repostMenuWithThoughts => 'أعد النشر مع رأيك';

  @override
  String get repostMenuEdit => 'عدّل رأيك';

  @override
  String get repostMenuUndo => 'إلغاء إعادة النشر';

  @override
  String get repostCaptionTitle => 'أعد نشر المقال';

  @override
  String get repostCaptionHint => 'قول رأيك في المقال… (اختياري)';

  @override
  String get repostCaptionSubmit => 'انشر';

  @override
  String get repostCaptionReposted => 'أعدت نشر المقال.';

  @override
  String get repostCaptionSaved => 'اتحفظ رأيك.';

  @override
  String get commentBoxHint => 'اكتب تعليق…';

  @override
  String get commentBoxReplyHint => 'اكتب ردك…';

  @override
  String get commentBoxEmoji => 'إيموجي';

  @override
  String get commentBoxKeyboard => 'ارجع للكيبورد';

  @override
  String get commentBoxCancelReply => 'إلغاء الرد';

  @override
  String get commentBoxCancelEdit => 'إلغاء التعديل';

  @override
  String get commentBoxEmojiSearch => 'دوّر على إيموجي';

  @override
  String get commentBoxEmojiNoRecents => 'الإيموجي اللي بتستخدمه هيظهر هنا';

  @override
  String get commentRowFollow => 'متابعة';

  @override
  String get postOpenArticleHint => 'بيفتح المقال';

  @override
  String get postCoverImage => 'صورة الغلاف، بتفتحها بالحجم الكامل';

  @override
  String postMoreTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تاج كمان',
      many: '$count تاج كمان',
      few: '$count تاجات كمان',
      two: 'تاجين كمان',
      one: 'تاج كمان',
    );
    return '$_temp0';
  }

  @override
  String get tagOpenHint => 'بيفتح صفحة التاج';

  @override
  String tagPageArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقال',
      few: '$count مقالات',
      two: 'مقالين',
      one: 'مقال واحد',
      zero: 'لسه مفيش مقالات',
    );
    return '$_temp0';
  }

  @override
  String get tagPageEmptyTitle => 'لسه مفيش مقالات بالتاج ده';

  @override
  String get tagPageEmptyBody => 'أول ما حد ينشر مقال بالتاج ده، هتلاقيه هنا.';

  @override
  String get tagNotFoundTitle => 'التاج ده مش موجود';

  @override
  String get tagNotFoundBody =>
      'ممكن يكون اتشال أو اتغيّر اسمه. جرّب تاج تاني.';

  @override
  String get searchHint => 'دوّر على مقالات وكتّاب ومواضيع وتاجات';

  @override
  String get searchFieldHint => 'دوّر في ReadIn';

  @override
  String get searchTabArticles => 'المقالات';

  @override
  String get searchTabWriters => 'الكتّاب';

  @override
  String get searchTabTopics => 'المواضيع';

  @override
  String get searchTabTags => 'التاجات';

  @override
  String get searchRecentTitle => 'آخر حاجات دوّرت عليها';

  @override
  String get searchRecentClearAll => 'امسح الكل';

  @override
  String searchRecentRemove(String query) {
    return 'شيل «$query» من آخر حاجات دوّرت عليها';
  }

  @override
  String get searchIdleTitle => 'عايز تقرا عن إيه؟';

  @override
  String get searchIdleBody =>
      'دوّر على مقالات وكتّاب ومواضيع وتاجات، بالعربي أو بالإنجليزي.';

  @override
  String searchNoResultsTitle(String query) {
    return 'مفيش نتايج لـ «$query»';
  }

  @override
  String get searchNoResultsTip =>
      'جرّب كلمة تانية أو أقصر، أو دوّر في تاب تاني.';

  @override
  String get searchNoResultsFilteredTitle => 'مفيش نتايج بالفلاتر دي';

  @override
  String searchNoResultsFiltersTip(String query) {
    return 'امسح الفلاتر عشان تشوف كل اللي فيه «$query».';
  }

  @override
  String get searchFoundInPdf => 'لقيناها في ملف الـ PDF المرفق';

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
  String get searchReadingTimeUpTo5 => 'لحد 5 دقايق';

  @override
  String get searchReadingTime5To10 => 'من 5 لـ 10 دقايق';

  @override
  String get searchReadingTimeOver10 => 'أكتر من 10 دقايق';

  @override
  String get searchClearFilters => 'امسح الفلاتر';

  @override
  String get searchKindField => 'مجال';

  @override
  String get exploreFields => 'المجالات';

  @override
  String get exploreTrending => 'الترند الأسبوع ده';

  @override
  String get exploreMostSaved => 'الأكتر حفظًا';

  @override
  String get exploreNewWriters => 'كتّاب جداد';

  @override
  String get exploreFeaturedPaths => 'مسارات مختارة';

  @override
  String get exploreSeeAll => 'عرض الكل';

  @override
  String exploreSeeAllSection(String section) {
    return 'عرض الكل: $section';
  }

  @override
  String get exploreEmptyTitle => 'لسه مفيش حاجة تستكشفها';

  @override
  String get exploreEmptyBody =>
      'المجالات والمقالات والكتّاب والمسارات هتظهر هنا أول ما الناس تبدأ تنشر.';

  @override
  String get exploreTrendingEmptyTitle =>
      'لسه مفيش مقالات عليها تفاعل الأسبوع ده';

  @override
  String get exploreMostSavedEmptyTitle => 'لسه محدش حفظ مقالات';

  @override
  String get exploreRankingEmptyBody =>
      'ارجع بعد شوية، أو اتفرج على المجالات في صفحة الاستكشاف.';

  @override
  String fieldArticleCount(int count) {
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
  String fieldFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count متابع',
      many: '$count متابع',
      few: '$count متابعين',
      two: 'متابعين اتنين',
      one: 'متابع واحد',
      zero: '0 متابع',
    );
    return '$_temp0';
  }

  @override
  String get fieldFollow => 'تابع المجال';

  @override
  String get fieldFollowTopic => 'تابع الموضوع';

  @override
  String get fieldKeepThree =>
      'لازم تفضل متابع 3 اهتمامات على الأقل. تابع مجال أو موضوع تاني الأول.';

  @override
  String get fieldTopics => 'مواضيع المجال';

  @override
  String get fieldTopWriters => 'أبرز الكتّاب في المجال ده';

  @override
  String get fieldArticles => 'أحدث المقالات';

  @override
  String get fieldEmptyTitle => 'لسه مفيش مقالات في المجال ده';

  @override
  String get fieldEmptyBody => 'تابعه، وأول ما حد ينشر فيه هيظهرلك.';

  @override
  String get fieldTopicEmptyTitle => 'لسه مفيش مقالات في الموضوع ده';

  @override
  String get fieldNotFoundTitle => 'المجال ده مش موجود';

  @override
  String get fieldNotFoundBody => 'يمكن اتشال، أو اللينك غلط.';

  @override
  String get fieldGoToExplore => 'اتفرج على مجالات تانية';

  @override
  String get fieldTopicNotFoundTitle => 'الموضوع ده مش موجود';

  @override
  String fieldTopicNotFoundBody(String field) {
    return 'الموضوع ده مش من مواضيع $field، أو اتشال.';
  }

  @override
  String get fieldShowAllArticles => 'كل مقالات المجال';

  @override
  String get errInterestsUnknown => 'فيه مجالات أو مواضيع مش موجودة.';

  @override
  String get errTopicNotFound => 'الموضوع مش موجود.';

  @override
  String get errTopicNotInField => 'الموضوع مش تابع للمجال ده.';

  @override
  String get errArticleNotOwner => 'التعديل للكاتب بس.';

  @override
  String get errArticleStatusInvalid => 'الحالة لازم تكون مسودة أو منشور.';

  @override
  String get errArticleNoContent => 'المقال فاضي، اكتب حاجة الأول.';

  @override
  String get errArticleInvalidTransition =>
      'مينفعش تعمل كده والمقال في حالته دي.';

  @override
  String get errArticleSlugTaken => 'الرابط ده مستخدم لمقال تاني.';

  @override
  String get errArticleTagsMaxFive => 'أقصى حاجة 5 تاجات للمقال.';

  @override
  String get errArticleTooManyTags => 'أقصى حاجة 5 تاجات للمقال.';

  @override
  String get errTagNotFound => 'التاج ده مش موجود.';

  @override
  String get errTagInvalid =>
      'التاج لازم يكون من 2 لـ 30 حرف: حروف وأرقام ومسافات و ⁦- _ . + #⁩ بس.';

  @override
  String get errTagLimit =>
      'عملت تاجات جديدة كتير النهارده. اختار من التاجات الموجودة، أو جرّب تاني بعدين.';

  @override
  String get errTagHidden => 'التاج ده مش متاح، اختار تاج تاني.';

  @override
  String get errArticleLanguageInvalid => 'لغة المقال دي مش مدعومة.';

  @override
  String get errArticleContentLanguageMismatch =>
      'لغة المحتوى مش زي لغة المقال.';

  @override
  String get errConcurrencyConflict =>
      'حد عدّل البيانات دي، حدّث الصفحة وجرب تاني.';

  @override
  String get errRequestInvalid => 'الطلب غير صالح.';

  @override
  String get errRequestTooLarge => 'الطلب أكبر من المسموح.';

  @override
  String get errRequestUnsupportedMediaType =>
      'نوع البيانات المبعوتة مش مدعوم.';

  @override
  String get errRouteNotFound => 'الصفحة مش موجودة.';

  @override
  String get errReportStatusInvalid =>
      'حالة البلاغ لازم تكون مفتوح أو اتحل أو اترفض.';

  @override
  String get errSearchQueryInvalid =>
      'اكتب من حرف لـ 100 حرف، وفيهم حرف أو رقم على الأقل.';

  @override
  String get errSearchTypeInvalid =>
      'نوع البحث لازم يكون مقالات أو كتّاب أو مواضيع أو تاجات.';

  @override
  String get errSearchFilterInvalid => 'فلاتر البحث دي مش صحيحة.';

  @override
  String get profileTabCategories => 'الأقسام';

  @override
  String get categoriesOther => 'مقالات تانية';

  @override
  String categoryArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقال',
      many: '$count مقال',
      few: '$count مقالات',
      two: 'مقالين',
      one: 'مقال واحد',
      zero: 'لسه مفيش مقالات',
    );
    return '$_temp0';
  }

  @override
  String get categoryOpenHint => 'بيفتح القسم';

  @override
  String get categoriesEmptyTitle => 'لسه مفيش أقسام';

  @override
  String get categoriesEmptyBody =>
      'لما الكاتب ده يرتّب مقالاته في أقسام، هتلاقيها هنا.';

  @override
  String get categoriesOwnHint =>
      'رتّب مقالاتك في أقسام. بروفايلك هيعرضها بالترتيب ده.';

  @override
  String get categoryNew => 'قسم جديد';

  @override
  String get categoriesFull =>
      'عندك 50 قسم، وده أقصى عدد. امسح قسم عشان تضيف واحد جديد.';

  @override
  String get categoriesEmptyOwnTitle => 'رتّب مقالاتك';

  @override
  String get categoriesEmptyOwnBody =>
      'اعمل أقسام زي «نصايح Backend»، وبعدين حط مقالاتك فيها من المحرر. القرّاء هيشوفوها في بروفايلك.';

  @override
  String get categoryEmptyOwn => 'فاضي، والزوار مش شايفينه';

  @override
  String get categoryRenameTitle => 'غيّر اسم القسم';

  @override
  String get categoryNameLabel => 'اسم القسم';

  @override
  String get categoryNameHint => 'مثلًا: نصايح Backend';

  @override
  String get categoryNameTooLong => 'اسم القسم أقصاه 40 حرف.';

  @override
  String get categoryNameNoLetter =>
      'اسم القسم لازم يكون فيه حرف أو رقم على الأقل.';

  @override
  String get categoryMoveUp => 'طلّعه لفوق';

  @override
  String get categoryMoveDown => 'نزّله لتحت';

  @override
  String get categoryDragHandle => 'اسحب عشان ترتّب';

  @override
  String get categoryMenu => 'اختيارات القسم';

  @override
  String categoryDeleteTitle(String name) {
    return 'تمسح «$name»؟';
  }

  @override
  String categoryDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'القسم ده فيه $count مقال، وهيفضلوا منشورين من غير قسم.',
      many: 'القسم ده فيه $count مقال، وهيفضلوا منشورين من غير قسم.',
      few: 'القسم ده فيه $count مقالات، وهيفضلوا منشورين من غير قسم.',
      two: 'القسم ده فيه مقالين، وهيفضلوا منشورين من غير قسم.',
      one: 'القسم ده فيه مقال واحد، وهيفضل منشور من غير قسم.',
      zero: 'القسم ده فاضي.',
    );
    return '$_temp0';
  }

  @override
  String get categoryDeleted => 'القسم اتمسح';

  @override
  String get categoryPageEmptyTitle => 'لسه مفيش مقالات في القسم ده';

  @override
  String get categoryPageEmptyBody =>
      'أول ما الكاتب يحط فيه مقالات، هتلاقيها هنا.';

  @override
  String get categoryOtherEmptyTitle => 'مفيش مقالات من غير قسم';

  @override
  String get categoryOtherEmptyBody => 'كل مقالات الكاتب ده في أقسام.';

  @override
  String get categoryNotFoundTitle => 'القسم ده مش موجود';

  @override
  String get categoryNotFoundBody => 'ممكن يكون اتمسح، أو اللينك غلط.';

  @override
  String get categoryWriterProfile => 'روح لبروفايل الكاتب';

  @override
  String articleInCategory(String name) {
    return 'في قسم $name';
  }

  @override
  String get editorCategoryLabel => 'القسم';

  @override
  String get editorCategoryNone => 'من غير قسم';

  @override
  String get editorCategoryHint =>
      'اختياري: بيجمّع المقال مع مقالات زيه في بروفايلك. أي تغيير بيتطبق على طول.';

  @override
  String get editorCategoryLoadFailed => 'معرفناش نجيب أقسامك.';

  @override
  String get moderationCategoriesTitle => 'أقسام الكاتب';

  @override
  String get moderationCategoriesEmpty => 'مفيش أقسام.';

  @override
  String get moderationClearCategory => 'امسح الاسم';

  @override
  String moderationClearCategoryTitle(String name) {
    return 'تمسح اسم القسم «$name»؟';
  }

  @override
  String get moderationClearCategoryBody =>
      'القسم هياخد اسم محايد زي «قسم 1»، ولينكه القديم هيبطل يشتغل. المقالات اللي فيه هتفضل فيه، والكاتب مش هيوصله إشعار.';

  @override
  String get moderationCategoryCleared => 'اسم القسم اتمسح';

  @override
  String get moderationLogUserClearCategory => 'مسح اسم قسم';

  @override
  String get errCategoryNotFound => 'القسم ده مش موجود.';

  @override
  String get errCategoryNotOwner => 'القسم ده مش بتاعك.';

  @override
  String get errCategoryLimit => 'وصلت لأقصى عدد أقسام (50).';

  @override
  String get errCategoryNameTaken => 'عندك قسم بنفس الاسم بالفعل.';

  @override
  String get errCategoryNameInvalid =>
      'اسم القسم لازم يكون من 1 لـ 40 حرف، وفيه حرف أو رقم على الأقل.';

  @override
  String get meMenu => 'أنا';

  @override
  String get meViewProfile => 'عرض البروفايل';

  @override
  String get meArticlesThisWeek => 'مقالات الأسبوع ده';

  @override
  String get meMinutesThisWeek => 'دقايق الأسبوع ده';

  @override
  String get themeSwitchToDark => 'حوّل للوضع الداكن';

  @override
  String get themeSwitchToLight => 'حوّل للوضع الفاتح';

  @override
  String get searchPillHint => 'دوّر على مقالات، كتّاب…';

  @override
  String get startPostHint => 'ابدأ مقال جديد…';

  @override
  String get startPostPhoto => 'صورة';

  @override
  String get startPostPdf => 'PDF';

  @override
  String get startPostArticle => 'مقال';

  @override
  String get suggestedWritersFeedTitle => 'أضف لفيدك';

  @override
  String get suggestedPathTitle => 'مسار مقترح';

  @override
  String get highlightAction => 'علّم';

  @override
  String get highlightRemove => 'شيل العلامة';

  @override
  String highlightCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قارئ علّموا الجملة دي',
    );
    return '$_temp0';
  }

  @override
  String get highlightAdded => 'اتعلّمت';

  @override
  String get highlightRemoved => 'اتشالت العلامة';

  @override
  String get highlightMenuHide => 'إخفاء الـ Highlights';

  @override
  String get highlightMenuShow => 'إظهار الـ Highlights';

  @override
  String get highlightSettingTitle => 'إظهار الـ Highlights';

  @override
  String get highlightSettingHint =>
      'علاماتك والجمل اللي قرّاء كتير علّموها جوه المقالات.';

  @override
  String get highlightSavedTab => 'الـ Highlights';

  @override
  String get highlightSavedEmptyTitle => 'لسه معلّمتش على أي جملة';

  @override
  String get highlightSavedEmptyBody =>
      'اختار جملة في أي مقال ودوس «علّم»، وهتلاقيها هنا.';

  @override
  String get highlightSavedOpen => 'افتح المقال عند الجملة دي';

  @override
  String get highlightSavedVersionAr => 'النسخة العربي';

  @override
  String get highlightSavedVersionEn => 'النسخة الإنجليزي';

  @override
  String get errHighlightTextMismatch =>
      'النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني.';

  @override
  String get errHighlightBlockNotAllowed => 'مينفعش تعمل Highlight للجزء ده.';

  @override
  String get errHighlightTooShort => 'اختار 3 حروف على الأقل.';

  @override
  String get errHighlightTooLong => 'الـ Highlight لازم يكون 1000 حرف أو أقل.';

  @override
  String get errHighlightLimit =>
      'وصلت لأقصى عدد Highlights في المقال ده (100).';

  @override
  String get errHighlightNotFound => 'الـ Highlight ده مش موجود.';

  @override
  String get quoteCardAction => 'شارك اقتباس';

  @override
  String get quoteCardTitle => 'شارك اقتباس';

  @override
  String get quoteCardHint =>
      'صورة للجزء اللي اخترته للسوشيال ميديا، ومعاها لينك المقال.';

  @override
  String get quoteCardThemeLabel => 'ألوان الكارت';

  @override
  String get quoteCardFormatLabel => 'مقاس الكارت';

  @override
  String get quoteCardSquare => 'مربع';

  @override
  String get quoteCardLandscape => 'بالعرض';

  @override
  String get quoteCardShare => 'شارك';

  @override
  String get quoteCardSave => 'احفظ';

  @override
  String get quoteCardCopyLink => 'انسخ اللينك';

  @override
  String get quoteCardLinkCopied => 'اتنسخ اللينك';

  @override
  String get quoteCardCopyFailed => 'معرفناش ننسخ اللينك.';

  @override
  String get quoteCardSaved => 'اتحفظ الكارت.';

  @override
  String get quoteCardSaveFailed => 'معرفناش نحفظ الكارت. جرّب تاني.';

  @override
  String get quoteCardShareFailed => 'معرفناش نفتح المشاركة. جرّب تاني.';

  @override
  String get quoteCardPreparing => 'بنجهز الكارت…';

  @override
  String quoteCardPreview(String quote) {
    return 'كارت اقتباس: $quote';
  }

  @override
  String get quoteCardRetry => 'حاول تاني';

  @override
  String get errQuoteCardNotFound => 'المقال مش موجود.';

  @override
  String get errQuoteCardHidden =>
      'المشرفين خفّوا المقال ده، فمينفعش تشارك منه اقتباس.';

  @override
  String get errQuoteCardTextMismatch =>
      'النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني.';

  @override
  String get errQuoteCardBlockNotAllowed => 'مينفعش تشارك الجزء ده كاقتباس.';

  @override
  String get errQuoteCardTooShort => 'اختار 3 حروف على الأقل.';

  @override
  String get errQuoteCardTooLong =>
      'الاقتباس لازم يكون 400 حرف أو أقل. اختار جزء أصغر.';

  @override
  String get errQuoteCardLimit =>
      'عملت كروت اقتباس كتير الساعة دي. حاول تاني بعد شوية.';

  @override
  String get errQuoteCardBusy =>
      'فيه كروت كتير بتتجهز دلوقتي. حاول تاني كمان شوية.';

  @override
  String get errQuoteCardFailed => 'معرفناش نجهّز كارت الاقتباس. حاول تاني.';

  @override
  String get errQuoteCardOffline => 'محتاج إنترنت عشان تعمل كارت اقتباس.';
}
