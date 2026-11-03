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
  String get confirmNumberAddYes => 'Yes, add this number';

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

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get externalNotLinkedTitle =>
      'No ReadIn account is linked to this account yet';

  @override
  String get externalNotLinkedBody =>
      'Create a new account, or link it to the account you already have with your phone number.';

  @override
  String get externalCreateAccount => 'Create a new account';

  @override
  String get externalLinkExisting => 'I have an account with a phone number';

  @override
  String get linkAccountTitle => 'Link your account';

  @override
  String linkAccountBody(String provider) {
    return 'Sign in with your number and password once. After that, $provider signs you in too.';
  }

  @override
  String get linkAccountButton => 'Link and sign in';

  @override
  String get linkedAccounts => 'Linked accounts';

  @override
  String get linkAction => 'Link';

  @override
  String get unlinkAction => 'Unlink';

  @override
  String get notLinked => 'Not linked';

  @override
  String unlinkTitle(String provider) {
    return 'Unlink $provider?';
  }

  @override
  String unlinkBody(String provider) {
    return 'You won\'t be able to sign in with $provider until you link it again.';
  }

  @override
  String providerLinked(String provider) {
    return '$provider linked';
  }

  @override
  String providerUnlinked(String provider) {
    return '$provider unlinked';
  }

  @override
  String get confirmItsYou => 'Confirm it\'s you';

  @override
  String linkWithPasswordBody(String provider) {
    return 'Enter your password to link $provider.';
  }

  @override
  String get confirmAction => 'Confirm';

  @override
  String get addPhoneSignIn => 'Add a phone number and password';

  @override
  String addPhoneSignInBody(String provider) {
    return 'You\'ll also be able to sign in with your number and password, and use a recovery PIN if you forget the password. You\'ll confirm with $provider at the end.';
  }

  @override
  String get phoneSignInAdded => 'Phone number and password added';

  @override
  String deleteAccountWithProvider(String provider) {
    return 'To delete your account, you\'ll confirm with $provider.';
  }

  @override
  String get errExternalNotLinked =>
      'No ReadIn account is linked to this account yet.';

  @override
  String get errExternalInvalid =>
      'We couldn\'t verify that account. Try again.';

  @override
  String get errProviderDisabled =>
      'This way of signing in isn\'t available right now.';

  @override
  String get errExternalConflict =>
      'Your ReadIn account already has another account of this kind linked.';

  @override
  String get errExternalInUse =>
      'This account is linked to another ReadIn account.';

  @override
  String get errExternalMismatch =>
      'Confirm with an account that\'s linked to your ReadIn account.';

  @override
  String get errExternalLoginNotFound => 'This account isn\'t linked.';

  @override
  String get errConfirmationRequired => 'Confirm it\'s you first.';

  @override
  String get errLastSignInMethod =>
      'This is your only way to sign in. Add another one first.';

  @override
  String get errPhoneSignInExists =>
      'Your account already has a phone number and password.';

  @override
  String get errProviderInvalid => 'This way of signing in isn\'t supported.';

  @override
  String get errExternalProviderFailed =>
      'Signing in with Google or Apple didn\'t finish. Try again.';

  @override
  String readingStreakNotReadTodaySemantics(int count) {
    return 'Reading streak: $count days. You haven\'t read today yet.';
  }

  @override
  String readingStreakFreezePendingSemantics(int count) {
    return 'Reading streak: $count days. You missed yesterday: read today and a freeze keeps your streak.';
  }

  @override
  String get readingStatsTitle => 'Reading stats';

  @override
  String get readingCurrentStreak => 'Current streak';

  @override
  String get readingLongestStreak => 'Longest';

  @override
  String readingDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get readingFreezeAvailable =>
      'Freeze ready: miss a day and your streak stays.';

  @override
  String get readingFreezePending =>
      'You missed yesterday. Read today and a freeze keeps your streak.';

  @override
  String get readingFreezeUsed =>
      'Freeze used. You get a new one within 7 days.';

  @override
  String get readingLast7Days => 'Last 7 days';

  @override
  String get readingLast30Days => 'Last 30 days';

  @override
  String get readingAllTime => 'All time';

  @override
  String readingArticlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String readingMinutesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get readingTopFields => 'Top fields';

  @override
  String readingTopFieldSemantics(String field, String articles) {
    return '$field: $articles';
  }

  @override
  String get readingStatsEmpty =>
      'Read an article to the end to start your streak.';

  @override
  String get readingActivity => 'Reading activity';

  @override
  String get readingLast12Months => 'Last 12 months';

  @override
  String get readingHeatmapLess => 'Less';

  @override
  String get readingHeatmapMore => 'More';

  @override
  String get readingHeatmapFreeze => 'Freeze';

  @override
  String readingHeatmapSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reading days',
      one: '1 reading day',
      zero: 'no reading days yet',
    );
    return 'Reading activity in the last 12 months: $_temp0';
  }

  @override
  String readingHeatmapDay(String date, String articles) {
    return '$date: $articles';
  }

  @override
  String readingHeatmapFrozenDay(String date) {
    return '$date: a freeze kept your streak';
  }

  @override
  String get readingHeatmapEmpty =>
      'Every day you finish an article shows up here.';

  @override
  String readingDaysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days in a row',
      one: 'day in a row',
    );
    return '$_temp0';
  }

  @override
  String get readingMilestoneWeekTitle => 'A full week!';

  @override
  String get readingMilestoneWeekBody =>
      '7 days of reading in a row. Keep it going.';

  @override
  String get readingMilestoneMonthTitle => 'A month of reading!';

  @override
  String get readingMilestoneMonthBody =>
      '30 days in a row. That\'s a real habit now.';

  @override
  String get readingMilestoneHundredTitle => '100 days!';

  @override
  String get readingMilestoneHundredBody =>
      '100 days in a row. Few readers get this far.';

  @override
  String get readingMilestoneYearTitle => 'A whole year!';

  @override
  String get readingMilestoneYearBody =>
      '365 days of reading in a row. Legendary.';

  @override
  String readingMilestoneTitle(int count) {
    return '$count-day streak!';
  }

  @override
  String get readingMilestoneBody => 'Keep it going.';

  @override
  String readingShareCardSemantics(int count) {
    return 'ReadIn card: $count days of reading in a row';
  }

  @override
  String get readingKeepReading => 'Keep reading';

  @override
  String get readingShareFailed => 'Couldn\'t share the card. Try again.';

  @override
  String get reactionInsightful => 'Insightful';

  @override
  String get reactionLove => 'Love';

  @override
  String get reactionFire => 'Fire';

  @override
  String get reactionMindBlown => 'Mind-blown';

  @override
  String get reactAction => 'React with 💡 Insightful';

  @override
  String removeReaction(String reaction) {
    return 'Remove your reaction ($reaction)';
  }

  @override
  String get chooseReaction => 'Choose a reaction';

  @override
  String reactionCountSemantics(String reaction, int count) {
    return '$reaction: $count';
  }

  @override
  String reactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reactions',
      one: '1 reaction',
      zero: 'No reactions yet',
    );
    return '$_temp0';
  }

  @override
  String get whoReacted => 'Reactions';

  @override
  String get showWhoReacted => 'See who reacted';

  @override
  String get reactorsEmpty => 'No reactions yet';

  @override
  String reactorsEmptyType(String reaction) {
    return 'No one reacted with $reaction yet';
  }

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'No comments yet',
    );
    return '$_temp0';
  }

  @override
  String get saveArticle => 'Save';

  @override
  String get unsaveArticle => 'Remove from saved';

  @override
  String get articleSaved => 'Saved. You can read it offline too.';

  @override
  String get articleUnsaved => 'Removed from saved';

  @override
  String get undo => 'Undo';

  @override
  String get moreActions => 'More actions';

  @override
  String get addToCollection => 'Add to collection';

  @override
  String get collections => 'Collections';

  @override
  String get newCollection => 'New collection';

  @override
  String get collectionName => 'Collection name';

  @override
  String get collectionNameHint => 'e.g. Interview prep';

  @override
  String get createAction => 'Create';

  @override
  String get renameAction => 'Rename';

  @override
  String get renameCollection => 'Rename collection';

  @override
  String get deleteAction => 'Delete';

  @override
  String deleteCollectionTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteCollectionBody =>
      'Only the collection goes. Its articles stay saved.';

  @override
  String collectionArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: 'No articles',
    );
    return '$_temp0';
  }

  @override
  String get collectionsEmptyTitle => 'No collections yet';

  @override
  String get collectionsEmptyBody =>
      'Group saved articles into lists, like “Interview prep”.';

  @override
  String addedToCollection(String name) {
    return 'Added to $name';
  }

  @override
  String removedFromCollection(String name) {
    return 'Removed from $name';
  }

  @override
  String get removeFromCollection => 'Remove from this collection';

  @override
  String inCollection(String name) {
    return 'In $name';
  }

  @override
  String collectionFilter(String name) {
    return 'Collection: $name';
  }

  @override
  String get clearFilter => 'Clear filter';

  @override
  String openCollection(String name) {
    return 'Show the articles in $name';
  }

  @override
  String get savedTabArticles => 'Articles';

  @override
  String get savedSearchHint => 'Search your saved articles';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get savedEmptyTitle => 'Nothing saved yet';

  @override
  String get savedEmptyBody =>
      'Tap the bookmark on any article to keep it here. Saved articles open even without internet.';

  @override
  String get savedNoResultsTitle => 'No saved articles match';

  @override
  String get savedNoResultsBody => 'Try another word or field.';

  @override
  String get savedCollectionEmptyTitle => 'This collection is empty';

  @override
  String get savedCollectionEmptyBody =>
      'Add articles to it from the reader or from your saved list.';

  @override
  String get savedOfflineBanner =>
      'You\'re offline. These are the articles saved on this device.';

  @override
  String get offlineCopy => 'Offline copy, saved on this device';

  @override
  String get savedGuestTitle => 'Your saved articles';

  @override
  String get savedGuestBody =>
      'Sign in to save articles and read them later, even offline.';

  @override
  String get follow => 'Follow';

  @override
  String get followingState => 'Following';

  @override
  String followName(String name) {
    return 'Follow $name';
  }

  @override
  String unfollowName(String name) {
    return 'Unfollow $name';
  }

  @override
  String get followsYou => 'Follows you';

  @override
  String get feedFollowing => 'Following';

  @override
  String get followingEmptyTitle => 'Follow writers to fill this tab';

  @override
  String get followingEmptyBody =>
      'New articles from the writers you follow show up here, newest first.';

  @override
  String get suggestedWriters => 'Writers you might like';

  @override
  String get suggestedWritersEmpty =>
      'No suggestions right now. Check back later.';

  @override
  String get showFollowingArticles => 'Show their articles';

  @override
  String get followingGuestTitle => 'Follow the writers you like';

  @override
  String get followingGuestBody =>
      'Sign in to follow writers and read their new articles here.';

  @override
  String get errReactionInvalid => 'This reaction isn\'t available.';

  @override
  String get errCollectionNameTaken =>
      'You already have a collection with this name.';

  @override
  String get errCollectionLimit => 'You can have up to 50 collections.';

  @override
  String get errCollectionNotFound => 'This collection doesn\'t exist anymore.';

  @override
  String get errFollowSelf => 'You can\'t follow yourself.';
}
