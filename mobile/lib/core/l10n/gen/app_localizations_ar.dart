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
  String get save => 'حفظ';

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
  String get onboardingWelcomeTitle => 'مقال كل يوم يفرق معاك';

  @override
  String get onboardingWelcomeBody =>
      'مقالات قصيرة ومراجَعة بالعربي والإنجليزي — واحدة بنختارهالك كل يوم في المجال اللي بتحبه.';

  @override
  String get getStarted => 'يلا نبدأ';

  @override
  String get haveAccount => 'عندي حساب';

  @override
  String get browseAsGuest => 'اتفرّج كضيف';

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
  String get notificationsHint => 'هنطلب الإذن لما الإشعارات تشتغل.';

  @override
  String get finishOnboarding => 'ابدأ القراءة';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get email => 'الإيميل';

  @override
  String get password => 'كلمة السر';

  @override
  String get displayName => 'الاسم';

  @override
  String get forgotPassword => 'نسيت كلمة السر؟';

  @override
  String get resetPassword => 'استرجاع كلمة السر';

  @override
  String get resetPasswordBody =>
      'اكتب الإيميل بتاعك وهنبعتلك لينك تغيّر بيه كلمة السر.';

  @override
  String get resetPasswordSent => 'بعتنالك لينك على الإيميل.';

  @override
  String get sendResetLink => 'ابعت اللينك';

  @override
  String get noAccount => 'معندكش حساب؟';

  @override
  String get alreadyHaveAccount => 'عندك حساب؟';

  @override
  String get continueWithGoogle => 'كمّل بـ Google';

  @override
  String get continueWithApple => 'كمّل بـ Apple';

  @override
  String get socialSignInSoon => 'الدخول بـ Google و Apple جاي قريب.';

  @override
  String verifyEmailSent(String email) {
    return 'بعتنا إيميل تأكيد على $email.';
  }

  @override
  String get signInTitle => 'أهلاً بيك تاني';

  @override
  String get signUpTitle => 'انضم لـ ReadIn';

  @override
  String get signInPromptTitle => 'سجّل دخول عشان تكمّل';

  @override
  String get signInPromptBody =>
      'اعمل حساب مجاني عشان تحفظ المقالات وتتابع الكتّاب وتحافظ على الـ streak.';

  @override
  String get fieldRequired => 'مطلوب';

  @override
  String get invalidEmail => 'اكتب إيميل صحيح';

  @override
  String get passwordTooShort => '8 حروف على الأقل';

  @override
  String get nameTooShort => 'حرفين على الأقل';

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
  String signedInAs(String email) {
    return 'داخل بـ $email';
  }

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
  String get errSuspended => 'حسابك موقوف.';

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
  String get errAuthUnavailable => 'تسجيل الدخول مش متاح دلوقتي.';

  @override
  String get errInvalidCredentials => 'الإيميل أو كلمة السر غلط.';

  @override
  String get errEmailInUse => 'الإيميل ده عليه حساب بالفعل.';

  @override
  String get errWeakPassword => 'اختار كلمة سر أقوى.';

  @override
  String get errInvalidEmail => 'الإيميل ده شكله مش صحيح.';

  @override
  String get errTooManyRequests => 'محاولات كتير. جرّب بعد شوية.';
}
