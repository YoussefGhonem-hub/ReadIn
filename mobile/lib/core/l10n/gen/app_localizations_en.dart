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
  String get feedNewArticles => 'New articles ↑';

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
  String get onboardingWelcomeBody =>
      'Short, reviewed articles in Arabic and English — one picked for you every day, in the field you love.';

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
      'We\'ll ask for permission when you turn it on.';

  @override
  String get notificationsBlocked =>
      'Notifications are off for ReadIn in your phone\'s settings.';

  @override
  String notificationsUnread(int count) {
    return 'Notifications, $count new';
  }

  @override
  String get finishOnboarding => 'Start reading';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get password => 'Password';

  @override
  String get displayName => 'Name';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signInTitle => 'Welcome back';

  @override
  String get signInPromptTitle => 'Sign in to continue';

  @override
  String get signInPromptBody =>
      'Create a free account to save articles, follow writers and keep your streak.';

  @override
  String get fieldRequired => 'Required';

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
  String get errSuspended => 'This account is suspended. Contact support.';

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
  String get errInvalidCredentials =>
      'The phone number or password is incorrect.';

  @override
  String get errTooManyRequests =>
      'Too many requests. Please try again shortly.';

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

  @override
  String get welcomeSignIn => 'I have an account, sign in';

  @override
  String switchLanguageTo(String language) {
    return 'Switch the app language to $language';
  }

  @override
  String get continueAction => 'Continue';

  @override
  String get edit => 'Edit';

  @override
  String get optional => 'Optional';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get signInSubtitle => 'Sign in with your mobile number and password.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get createAccountLink => 'Create one';

  @override
  String get passwordResetBanner =>
      'Password changed. Sign in with your new password.';

  @override
  String get sessionExpired => 'Your session has ended. Sign in again.';

  @override
  String get signUpHeading => 'Create your account';

  @override
  String get signUpCredentialsBody =>
      'You\'ll sign in with this number and password. We never send SMS codes.';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String ruleMinLength(int count) {
    return '$count+ characters';
  }

  @override
  String get ruleLetter => 'A letter';

  @override
  String get ruleDigit => 'A digit';

  @override
  String get ruleMet => 'done';

  @override
  String get ruleNotMet => 'not yet';

  @override
  String passwordStrength(String level) {
    return 'Password strength: $level';
  }

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthFair => 'Fair';

  @override
  String get strengthGood => 'Good';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get pinStepTitle => 'Create an emergency PIN';

  @override
  String get pinStepBody =>
      'If you ever forget your password, your number and this PIN let you choose a new one. Keep it somewhere safe and don\'t share it.';

  @override
  String get pinLabel => 'Recovery PIN';

  @override
  String get confirmPinLabel => 'Confirm PIN';

  @override
  String get newPinLabel => 'New PIN';

  @override
  String get showPin => 'Show PIN';

  @override
  String get hidePin => 'Hide PIN';

  @override
  String pinSemantics(String label, int filled, int total) {
    return '$label, $filled of $total digits entered';
  }

  @override
  String get confirmNumberTitle => 'Is this your number?';

  @override
  String get confirmNumberWarning =>
      'You\'ll use this number to sign in, and you can\'t recover your account if the number is wrong.';

  @override
  String get confirmNumberYes => 'Yes, create my account';

  @override
  String get confirmNumberChangeYes => 'Yes, change my number';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileBody =>
      'This is how readers and writers will see you.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => '3–30 characters: a–z, 0–9 or _';

  @override
  String get usernameChecking => 'Checking…';

  @override
  String usernameAvailable(String username) {
    return '@$username is available';
  }

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get photoUploading => 'Uploading photo…';

  @override
  String get saveAndContinue => 'Save and continue';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotStep1Body =>
      'Enter your number and the recovery PIN you created when you signed up.';

  @override
  String get forgotPin => 'Forgot the PIN too?';

  @override
  String get forgotStep2Title => 'Choose a new password';

  @override
  String get forgotStep2Body =>
      'Every device signed in to your account will be signed out.';

  @override
  String get supportTitle => 'Contact support';

  @override
  String get supportBody =>
      'Without your PIN, only our support team can reset your password, after checking that the account is really yours. Email us from your account\'s number details; after the reset you\'ll choose a new password and a new PIN when you sign in.';

  @override
  String get supportEmailAction => 'Email support';

  @override
  String get copyEmail => 'Copy email address';

  @override
  String get setPinTitle => 'Set your recovery PIN';

  @override
  String get setPinBody =>
      'Your account needs a recovery PIN. With your number, it lets you choose a new password if you ever forget yours.';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get mustChangePasswordBody =>
      'Your password was reset. Choose a new one to continue.';

  @override
  String get changePasswordBody => 'Your other devices will be signed out.';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get changePinTitle => 'Change PIN';

  @override
  String get changePinBody =>
      'Confirm with your password, then choose the new PIN.';

  @override
  String get pinChanged => 'Recovery PIN changed.';

  @override
  String get changePhoneTitle => 'Change number';

  @override
  String get changePhoneBody =>
      'You\'ll sign in with the new number. Your other devices will be signed out.';

  @override
  String get newPhoneLabel => 'New mobile number';

  @override
  String get phoneChanged => 'Number changed.';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneVisibleToYou => 'Only you can see it';

  @override
  String get changePhone => 'Change number';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePin => 'Change PIN';

  @override
  String get signOutEverywhere => 'Sign out of all devices';

  @override
  String get signOutEverywhereBody =>
      'Every other device will be signed out. You stay signed in on this one.';

  @override
  String get signedOutEverywhere => 'Signed out of all other devices.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'Your profile and personal data are removed after 30 days. Your articles and comments stay, shown as \"Deleted user\". This can\'t be undone.';

  @override
  String get deleteAccountConfirm => 'I understand, delete my account';

  @override
  String get deleteAccountButton => 'Delete my account';

  @override
  String get accountDeleted => 'Your account was deleted.';

  @override
  String get countryPickerTitle => 'Choose a country';

  @override
  String get countrySearchHint => 'Search by name, code or +dial code';

  @override
  String get countryNoResults => 'No country matches your search';

  @override
  String countryButtonSemantics(String country, String dialCode) {
    return 'Country: $country, +$dialCode. Double-tap to change';
  }

  @override
  String get selected => 'Selected';

  @override
  String get devLoginOpen => 'Demo accounts';

  @override
  String get devLoginTitle => 'Demo accounts (dev only)';

  @override
  String get devLoginBody =>
      'Local seed users (SPEC §18.3). With DEV_DEMO_PASSWORD set, a tap signs in; otherwise it fills the number.';

  @override
  String get devLoginHasPin => 'Has a recovery PIN';

  @override
  String get devLoginNoPin => 'No recovery PIN';

  @override
  String get errPhoneInvalid => 'Enter a valid mobile number.';

  @override
  String get errPhoneTaken => 'This number already has an account.';

  @override
  String get errPhoneUnchanged => 'This is already your number.';

  @override
  String get errLockedOut => 'Too many attempts. Try again in 15 minutes.';

  @override
  String get errWrongPassword => 'The current password is incorrect.';

  @override
  String get errRecoveryInvalid => 'The phone number or PIN is incorrect.';

  @override
  String get errRecoveryLocked => 'Too many attempts. Try again in an hour.';

  @override
  String get errRecoveryDisabled =>
      'Recovery is disabled for this account. Contact support.';

  @override
  String get errResetTokenInvalid => 'Time ran out. Start again.';

  @override
  String get errPinAlreadySet =>
      'A recovery PIN is already set. Change it from Settings.';

  @override
  String get errUsernameInvalid => 'Use 3–30 characters: a–z, 0–9 or _.';

  @override
  String get errPasswordTooShort => 'The password is too short.';

  @override
  String get errPasswordTooLong => 'The password is too long.';

  @override
  String get errPasswordLetterRequired => 'Add at least one letter.';

  @override
  String get errPasswordDigitRequired => 'Add at least one digit.';

  @override
  String get errPasswordTooCommon =>
      'This password is too common. Choose another one.';

  @override
  String get errPasswordContainsPhone =>
      'The password can\'t contain your phone number.';

  @override
  String get errPasswordMismatch => 'The passwords don\'t match.';

  @override
  String get errPinLength => 'Enter all the digits.';

  @override
  String get errPinDigitsOnly => 'Digits only.';

  @override
  String get errPinWeak =>
      'This PIN is easy to guess. Avoid repeated or consecutive digits, years and digits from your number or password.';

  @override
  String get errPinMismatch => 'The PINs don\'t match.';

  @override
  String get errTooShort => 'Too short.';

  @override
  String get errTooLong => 'Too long.';

  @override
  String get errInvalidValue => 'Check this field.';

  @override
  String get orDivider => 'or';
}
