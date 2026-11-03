// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ReadIn';

  @override
  String get tagline => 'Read daily. Grow daily.';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading…';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonBody =>
      'We\'re building this right now. It will arrive on the app and the web at the same time.';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get navHome => 'Today';

  @override
  String get navExplore => 'Explore';

  @override
  String get navWrite => 'Write';

  @override
  String get navSaved => 'Saved';

  @override
  String get navProfile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name 👋';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name 👋';
  }

  @override
  String get greetingGuest => 'Welcome to ReadIn 👋';

  @override
  String get greetingSubtitle => 'Ready for a small dose of knowledge?';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'Start your streak',
    );
    return '$_temp0';
  }

  @override
  String streakSemantics(int count) {
    return 'Reading streak: $count days';
  }

  @override
  String get todayArticle => 'Today\'s article';

  @override
  String get todayArticleCta => 'Read now';

  @override
  String get feedForYou => 'For you';

  @override
  String get filterAll => 'All';

  @override
  String get feedEmptyTitle => 'No articles here yet';

  @override
  String get feedEmptyBody => 'Try another field or check back later.';

  @override
  String get endOfFeed => 'You\'re all caught up ✨';

  @override
  String readingTime(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min read',
      one: '1 min read',
    );
    return '$_temp0';
  }

  @override
  String byAuthor(String name) {
    return 'By $name';
  }

  @override
  String get badgeReviewed => 'Reviewed';

  @override
  String reviewedBy(String name) {
    return 'Reviewed by $name';
  }

  @override
  String lastReviewed(String date) {
    return 'Last reviewed: $date';
  }

  @override
  String get aiAssisted => 'AI-assisted';

  @override
  String get verifiedWriter => 'Verified writer';

  @override
  String get tldr => 'TL;DR';

  @override
  String get sources => 'Sources';

  @override
  String get fontSize => 'Font size';

  @override
  String get fontSizeS => 'Small';

  @override
  String get fontSizeM => 'Medium';

  @override
  String get fontSizeL => 'Large';

  @override
  String get fontSizeXl => 'Extra large';

  @override
  String get articleLanguage => 'Article language';

  @override
  String get langToggleArEg => 'Arabic+EN';

  @override
  String get langToggleEn => 'EN';

  @override
  String get articleLangArEg => 'Egyptian Arabic + English terms';

  @override
  String get articleLangEn => 'English only';

  @override
  String get copyCode => 'Copy code';

  @override
  String get copied => 'Copied';

  @override
  String get share => 'Share';

  @override
  String get glossary => 'Glossary';

  @override
  String glossaryComingSoon(String term) {
    return 'Full definitions for “$term” are coming soon to the glossary.';
  }

  @override
  String get readingProgress => 'Reading progress';

  @override
  String get openLink => 'Open link';

  @override
  String embedOpen(String provider) {
    return 'Open $provider';
  }

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get onboardingWelcomeTitle =>
      'One article a day that makes a difference';

  @override
  String get onboardingWelcomeBody =>
      'Short, reviewed articles in Arabic and English — one picked for you every day, in the field you love.';

  @override
  String get getStarted => 'Get started';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get browseAsGuest => 'Browse as a guest';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get interestsTitle => 'Which fields do you love?';

  @override
  String get interestsSubtitle =>
      'Pick at least 3 so we can tailor your daily article.';

  @override
  String interestsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'Nothing selected yet',
    );
    return '$_temp0';
  }

  @override
  String get preferencesTitle => 'Your preferences';

  @override
  String get preferencesSubtitle =>
      'You can change these anytime from settings.';

  @override
  String get articleLanguageLabel => 'Article language';

  @override
  String get reminderTimeLabel => 'Daily reminder';

  @override
  String get notificationsLabel => 'Daily article notification';

  @override
  String get notificationsHint =>
      'We\'ll ask for permission when notifications launch.';

  @override
  String get finishOnboarding => 'Start reading';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get displayName => 'Name';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetPasswordBody =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get resetPasswordSent => 'Check your inbox for a reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get socialSignInSoon => 'Google and Apple sign-in are coming soon.';

  @override
  String verifyEmailSent(String email) {
    return 'We sent a verification email to $email.';
  }

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signUpTitle => 'Join ReadIn';

  @override
  String get signInPromptTitle => 'Sign in to continue';

  @override
  String get signInPromptBody =>
      'Create a free account to save articles, follow writers and keep your streak.';

  @override
  String get fieldRequired => 'Required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'At least 8 characters';

  @override
  String get nameTooShort => 'At least 2 characters';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get uiLanguage => 'App language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get reading => 'Reading';

  @override
  String get account => 'Account';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get guestMode => 'You\'re browsing as a guest';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileGuestTitle => 'Your ReadIn profile';

  @override
  String get profileGuestBody =>
      'Sign in to build your reading streak and share what you know.';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profileSyncFailed => 'We couldn\'t load your profile.';

  @override
  String get errValidation => 'Please check the highlighted fields.';

  @override
  String get errUnauthorized => 'Please sign in again.';

  @override
  String get errForbidden => 'You don\'t have permission to do this.';

  @override
  String get errSuspended => 'Your account is suspended.';

  @override
  String get errNotSynced => 'We couldn\'t set up your account. Try again.';

  @override
  String get errUserNotFound => 'User not found.';

  @override
  String get errUsernameTaken => 'This username is taken.';

  @override
  String get errInterestsMinThree => 'Pick at least 3 interests.';

  @override
  String get errFieldNotFound => 'This field doesn\'t exist.';

  @override
  String get errArticleNotFound =>
      'This article doesn\'t exist or was removed.';

  @override
  String get errServer => 'Something went wrong on our side. Try again.';

  @override
  String get errOffline => 'You\'re offline. Check your connection.';

  @override
  String get errTimeout => 'The connection timed out. Try again.';

  @override
  String get errAuthUnavailable => 'Sign-in isn\'t available right now.';

  @override
  String get errInvalidCredentials => 'Wrong email or password.';

  @override
  String get errEmailInUse => 'This email already has an account.';

  @override
  String get errWeakPassword => 'Choose a stronger password.';

  @override
  String get errInvalidEmail => 'This email looks invalid.';

  @override
  String get errTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get errCancelled => 'Cancelled.';

  @override
  String get errSourcesRequired => 'Add at least one source before publishing.';

  @override
  String get errMediaPurposeInvalid => 'This kind of upload isn\'t supported.';

  @override
  String get errMediaFileRequired => 'Choose a file first.';

  @override
  String get errMediaTooLarge =>
      'This file is too large (PDF up to 20 MB, images up to 10 MB).';

  @override
  String get errMediaUnsupportedType =>
      'This file type isn\'t supported. Use JPEG, PNG, WebP, HEIC or PDF.';

  @override
  String get errMediaDimensionsTooLarge =>
      'This image is too big (up to 8000 × 8000 pixels).';

  @override
  String get errMediaImageCorrupted =>
      'We couldn\'t read this image. Try another one.';

  @override
  String get errMediaPdfEncrypted =>
      'This PDF is password-protected. Upload it without a password.';

  @override
  String get errMediaPdfCorrupted =>
      'We couldn\'t read this PDF. It may be damaged.';

  @override
  String get errMediaPdfTooManyPages => 'This PDF has more than 100 pages.';

  @override
  String get errMediaQuotaDaily =>
      'You\'ve reached today\'s upload limit (50 files). Try again tomorrow.';

  @override
  String get errMediaQuotaStorage =>
      'Your storage is full (200 MB). Remove old files to upload more.';

  @override
  String get errMediaNotFound => 'This file doesn\'t exist anymore.';

  @override
  String get errMediaInUse => 'This file is attached to a post.';

  @override
  String get errMediaDownloadNotAllowed =>
      'The author didn\'t allow downloading this file.';

  @override
  String get errMediaProcessingFailed =>
      'We couldn\'t prepare this file. Remove it or try again.';

  @override
  String get errMediaProcessingTimeout =>
      'Preparing this file took too long. Try again.';

  @override
  String get errAttachmentsMixedKinds =>
      'A post can have images or one PDF, not both.';

  @override
  String get errAttachmentsTooManyImages => 'You can attach up to 10 images.';

  @override
  String get errAttachmentsSingleDocument => 'You can attach only one PDF.';

  @override
  String get errAttachmentsAltTextRequired => 'Every image needs alt text.';

  @override
  String get errAttachmentsAltTextTooLong =>
      'Alt text can be up to 5000 characters.';

  @override
  String get errAttachmentsCaptionTooLong =>
      'Captions can be up to 5000 characters.';

  @override
  String get errAttachmentsTitleTooLong =>
      'The document title can be up to 5000 characters.';

  @override
  String get errAttachmentsTitleRequired => 'The document needs a title.';

  @override
  String get errAttachmentsAssetNotFound =>
      'An attachment is missing. Remove it and upload it again.';

  @override
  String get errAttachmentsAssetNotReady =>
      'An attachment is still being prepared. Wait a moment.';

  @override
  String get errAttachmentsDuplicateAsset => 'The same file is attached twice.';

  @override
  String get composerTitle => 'New post';

  @override
  String get composerField => 'Field';

  @override
  String get composerFieldHint => 'Pick a field';

  @override
  String get composerTitleLabel => 'Title';

  @override
  String get composerTitleHint => 'A clear title, 5 to 150 characters';

  @override
  String get composerBodyLabel => 'Your post';

  @override
  String get composerBodyHint => 'Leave an empty line between paragraphs.';

  @override
  String get composerSourcesRequired => 'This field needs at least one source.';

  @override
  String get composerSourcesOptional =>
      'Optional, but readers trust posts with sources.';

  @override
  String get composerAddSource => 'Add source';

  @override
  String get composerAttachments => 'Attachments';

  @override
  String get composerSourceTitle => 'Source title';

  @override
  String get composerSourceUrl => 'Link (https://…)';

  @override
  String get composerRemoveSource => 'Remove source';

  @override
  String get composerInvalidUrl => 'Enter a valid http(s) link';

  @override
  String get composerPublish => 'Publish';

  @override
  String get composerPublishing => 'Publishing…';

  @override
  String get composerPublished => 'Published ✨';

  @override
  String get composerNeedField => 'Pick a field.';

  @override
  String get composerNeedTitle => 'Write a title (5 to 150 characters).';

  @override
  String get composerNeedBody => 'Write something or add an attachment.';

  @override
  String get composerNeedSources => 'Add at least one source.';

  @override
  String get composerFixSources => 'Complete or remove the unfinished sources.';

  @override
  String get attachImages => 'Images';

  @override
  String get attachPdf => 'PDF document';

  @override
  String get attachMixHint => 'A post can have images or one PDF, not both.';

  @override
  String attachImagesLimit(int count) {
    return '$count of 10 images';
  }

  @override
  String get attachReorderHint =>
      'Long-press and drag to reorder. Tap an image to add alt text.';

  @override
  String get attachNeedAlt => 'Add alt text to every image.';

  @override
  String get attachBusy => 'Wait until uploads and processing finish.';

  @override
  String get attachFailed => 'Remove or retry the failed attachments.';

  @override
  String get attachNeedDocTitle => 'Give the document a title.';

  @override
  String get altTextLabel => 'Alt text (required)';

  @override
  String get altTextHint =>
      'Describe the image for people using a screen reader';

  @override
  String get altTextMissing => 'Alt text needed';

  @override
  String get altTextAdded => 'ALT ✓';

  @override
  String get altTextBadgeMissing => 'Add ALT';

  @override
  String get listSeparator => ', ';

  @override
  String get captionLabel => 'Caption (optional)';

  @override
  String imageDetailsTitle(int index, int total) {
    return 'Image $index of $total';
  }

  @override
  String get editImageDetails => 'Edit alt text and caption';

  @override
  String get moveEarlier => 'Move earlier';

  @override
  String get moveLater => 'Move later';

  @override
  String get removeAttachment => 'Remove';

  @override
  String get cancelUpload => 'Cancel upload';

  @override
  String get uploadPreparing => 'Preparing…';

  @override
  String uploadProgress(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get uploadCancelled => 'Upload cancelled';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String fileSizeMb(String size) {
    return '$size MB';
  }

  @override
  String fileSizeKb(String size) {
    return '$size KB';
  }

  @override
  String get pdfTitleLabel => 'Document title (required)';

  @override
  String get pdfAllowDownload => 'Allow download';

  @override
  String get pdfAllowDownloadHint => 'Readers can download the original PDF.';

  @override
  String get pdfPreparingPages => 'Preparing pages…';

  @override
  String pdfPagesReady(int ready, int total) {
    return '$ready of $total pages ready';
  }

  @override
  String pdfPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String pdfMorePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count pages, open document',
      one: '+1 page, open document',
    );
    return '$_temp0';
  }

  @override
  String get openDocument => 'Open document';

  @override
  String get viewerDownload => 'Download';

  @override
  String get viewerDownloading => 'Downloading…';

  @override
  String viewerImageOf(int index, int total) {
    return 'Image $index of $total';
  }

  @override
  String viewerPageOf(int index, int total) {
    return 'Page $index of $total';
  }

  @override
  String get viewerZoomHint => 'Double-tap to zoom';

  @override
  String get viewerPageLoading => 'Loading page…';

  @override
  String get viewerThumbnails => 'Pages';
}
