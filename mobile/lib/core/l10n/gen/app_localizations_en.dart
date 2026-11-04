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
  String get aiAssisted => 'AI-assisted';

  @override
  String get verifiedWriter => 'Verified writer';

  @override
  String get deletedUser => 'Deleted user';

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
  String get glossaryInEnglish => 'In English';

  @override
  String get glossaryInArabic => 'In Arabic';

  @override
  String get glossaryArticles => 'Articles that use this term';

  @override
  String get glossaryNotFound => 'This term isn\'t in the glossary yet';

  @override
  String get relatedArticles => 'Related articles';

  @override
  String get resumePickedUp => 'Picked up where you left off';

  @override
  String get resumeStartOver => 'Start over';

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
      'Short articles in Arabic and English — one picked for you every day, in the field you love.';

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
  String get profileTabArticles => 'Articles';

  @override
  String get profileTabSaved => 'Saved';

  @override
  String get profileTabPaths => 'Paths';

  @override
  String get profileTabAbout => 'About';

  @override
  String get profileStatArticles => 'Articles';

  @override
  String get profileStatFollowers => 'Followers';

  @override
  String get profileStatFollowing => 'Following';

  @override
  String get profileStatReads => 'Reads';

  @override
  String profileStatSemantics(String label, String value) {
    return '$label: $value';
  }

  @override
  String get profileOpenHint => 'Opens the profile';

  @override
  String profileOpenLink(String name) {
    return 'Open $name';
  }

  @override
  String get profileGithub => 'GitHub';

  @override
  String get profileLinkedin => 'LinkedIn';

  @override
  String get profileWebsite => 'Website';

  @override
  String get profileLinks => 'Links';

  @override
  String get profileExpertise => 'Fields of expertise';

  @override
  String get profileAboutBio => 'Bio';

  @override
  String get profileAboutEmpty => 'No details yet.';

  @override
  String get profileAboutEmptyOwn =>
      'Add a bio, your links and the fields you write about so readers get to know you.';

  @override
  String profileJoined(String date) {
    return 'Joined $date';
  }

  @override
  String get profileArticlesEmptyTitle => 'No articles yet';

  @override
  String get profileArticlesEmptyBody =>
      'The articles they publish show up here.';

  @override
  String get profileArticlesEmptyOwnTitle => 'You haven\'t published yet';

  @override
  String get profileArticlesEmptyOwnBody =>
      'Share what you know: your published articles show up here.';

  @override
  String get profileWriteFirst => 'Write an article';

  @override
  String get profilePathsTitle => 'Learning paths are coming';

  @override
  String get profilePathsBody =>
      'Hand-picked series of articles to learn a topic step by step. We\'re building them now.';

  @override
  String get profileNotFoundTitle => 'This profile isn\'t available';

  @override
  String get profileNotFoundBody =>
      'The account may have been deleted, or the link is wrong.';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profilePrivacy => 'Privacy';

  @override
  String get profilePublicReadingStats =>
      'Show reading stats on my public profile';

  @override
  String get profilePublicReadingStatsOn =>
      'Everyone can see your streak, your totals and your reading activity.';

  @override
  String get profilePublicReadingStatsOff =>
      'Only you can see your reading stats.';

  @override
  String get profileReadingStatsEmpty => 'No finished articles yet.';

  @override
  String get profileReadingHeatmapEmpty => 'No reading days yet.';

  @override
  String get profileBioLabel => 'Bio';

  @override
  String get profileBioHint => 'What do you work on? What do you write about?';

  @override
  String get profilePhotoGallery => 'Choose from your photos';

  @override
  String get profilePhotoCamera => 'Take a photo';

  @override
  String get profilePhotoPreview => 'Profile photo';

  @override
  String get profileExpertiseHint => 'Pick up to 5 fields you know well.';

  @override
  String get profileExpertiseFull => 'That\'s 5. Remove one to pick another.';

  @override
  String profileExpertiseCountSemantics(int count, int max) {
    return '$count of $max fields picked';
  }

  @override
  String get profileFollowSearchHint => 'Search by name or username';

  @override
  String get profileFollowNoResultsTitle => 'No one matches';

  @override
  String get profileFollowNoResultsBody => 'Try another name or username.';

  @override
  String get profileFollowersEmptyTitle => 'No followers yet';

  @override
  String get profileFollowersEmptyOwnBody =>
      'Readers who like your articles can follow you.';

  @override
  String get profileFollowingEmptyTitle => 'Not following anyone yet';

  @override
  String get profileFollowingEmptyOwnBody =>
      'Follow writers to get their new articles on Today.';

  @override
  String get profileErrStatsPrivate => 'These reading stats are private.';

  @override
  String get profileErrAvatarInvalid =>
      'This photo can\'t be used. Upload another one.';

  @override
  String get profileErrExpertiseInvalid => 'Pick up to 5 of the listed fields.';

  @override
  String get profileErrUrl => 'Enter a full link that starts with https://';

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
  String get composerField => 'Field';

  @override
  String get composerFieldHint => 'Pick a field';

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
  String get deleteAccountTitle => 'Delete your account';

  @override
  String get deleteAccountLead =>
      'This permanently deletes your ReadIn account. You can\'t undo it, and we can\'t restore it.';

  @override
  String get deleteAccountDeletedHeading => 'We delete right away';

  @override
  String get deleteAccountDeletedProfile =>
      'Your profile: name, @username, photo, bio and links';

  @override
  String get deleteAccountDeletedContact =>
      'Your phone number, email, password and recovery PIN';

  @override
  String get deleteAccountDeletedSignIns =>
      'Your Google and Apple sign-in links. We also revoke ReadIn\'s access at Apple.';

  @override
  String get deleteAccountDeletedDrafts =>
      'Your drafts and any article that isn\'t published, with their images and PDFs, and every other photo or file you uploaded';

  @override
  String get deleteAccountDeletedActivity =>
      'Your interests, reading progress, stats, reactions, saved articles and follows';

  @override
  String get deleteAccountDeletedDevices =>
      'Your devices and notification tokens, so no notification reaches you';

  @override
  String get deleteAccountDeletedSecurityLog =>
      'Your security log: sign-ins and account changes';

  @override
  String get deleteAccountKeptHeading => 'What we keep, and why';

  @override
  String get deleteAccountKeptPublished =>
      'Your published articles and comments stay up under “Deleted user”, with the images and PDFs they show: no name, @username or photo, and nothing that links them to you. That keeps links and discussions other readers rely on working. To take an article down, delete it before you delete your account.';

  @override
  String get deleteAccountKeptRecord =>
      'A record that this account was deleted: its internal ID and the time, nothing that identifies you. It proves the deletion happened.';

  @override
  String get deleteAccountKeptBackups =>
      'Database backups may still hold your data for up to 14 days, until they\'re overwritten.';

  @override
  String get deleteAccountKeptReviews =>
      'Edits you made on other writers\' articles stay with those articles, without your name.';

  @override
  String get deleteAccountAfter =>
      'Afterwards, this phone number, email, Google or Apple account can create a new ReadIn account, which starts empty.';

  @override
  String get deleteAccountByEmail => 'Delete by email instead';

  @override
  String get deleteAccountPasswordBody =>
      'Enter your password to delete your account.';

  @override
  String get deleteAccountProviderBody =>
      'Sign in again with the account that\'s linked to ReadIn.';

  @override
  String get confirmWithGoogle => 'Confirm with Google';

  @override
  String get confirmWithApple => 'Confirm with Apple';

  @override
  String get confirmedWithGoogle => 'Confirmed with Google';

  @override
  String get confirmedWithApple => 'Confirmed with Apple';

  @override
  String get deleteAccountAppleUnavailable =>
      'This account is linked to Apple. Confirm with Apple from the ReadIn iPhone app, or email us to delete it.';

  @override
  String get deleteAccountConfirm => 'I understand, delete my account';

  @override
  String get deleteAccountButton => 'Delete my account';

  @override
  String get deletingAccount => 'Deleting your account…';

  @override
  String get deleteAccountDialogTitle => 'Delete your account forever?';

  @override
  String get deleteAccountDialogBody => 'This can\'t be undone.';

  @override
  String get deleteAccountDialogConfirm => 'Delete forever';

  @override
  String get deleteAccountOffline =>
      'You\'re offline. Connect to the internet to delete your account.';

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
  String get redo => 'Redo';

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

  @override
  String get commentsOpen => 'Open the comments';

  @override
  String get commentsTitle => 'Comments';

  @override
  String commentsTitleCount(int count) {
    return 'Comments ($count)';
  }

  @override
  String get commentsSortTop => 'Top';

  @override
  String get commentsSortNewest => 'Newest';

  @override
  String get commentsEmptyTitle => 'No comments yet';

  @override
  String get commentsEmptyBody => 'Be the first to share what you think.';

  @override
  String get commentsAuthorBadge => 'Author';

  @override
  String get commentsPinned => 'Pinned';

  @override
  String get commentsEdited => 'edited';

  @override
  String get commentsDeletedPlaceholder => 'This comment was deleted';

  @override
  String get commentsHiddenPlaceholder => 'Hidden by moderators';

  @override
  String get commentsHiddenNotice =>
      'Hidden by moderators. Only you and the moderators can see it.';

  @override
  String get commentsDeletedUser => 'Deleted user';

  @override
  String get commentsLike => 'Like';

  @override
  String get commentsUnlike => 'Remove your like';

  @override
  String commentsLikesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
      zero: 'No likes',
    );
    return '$_temp0';
  }

  @override
  String get commentsReply => 'Reply';

  @override
  String commentsMoreReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count more replies',
      one: 'Show 1 more reply',
    );
    return '$_temp0';
  }

  @override
  String get commentsMoreRepliesAny => 'Show more replies';

  @override
  String commentsNewPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new comments',
      one: '1 new comment',
    );
    return '$_temp0';
  }

  @override
  String get commentsSending => 'Sending…';

  @override
  String get commentsTimeNow => 'now';

  @override
  String commentsTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String commentsTimeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hrs ago',
      one: '1 hr ago',
    );
    return '$_temp0';
  }

  @override
  String commentsTimeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get commentsComposerHint => 'Write a comment…';

  @override
  String get commentsReplyHint => 'Write a reply…';

  @override
  String get commentsSend => 'Send';

  @override
  String commentsReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get commentsEditing => 'Editing your comment';

  @override
  String get commentsMentionSuggestions => 'People to mention';

  @override
  String get commentsGuestPrompt => 'Sign in to join the conversation.';

  @override
  String get commentsMenu => 'Comment options';

  @override
  String get commentsDeleteTitle => 'Delete this comment?';

  @override
  String get commentsDeleteBody => 'This can\'t be undone. Replies to it stay.';

  @override
  String get commentsDeleted => 'Comment deleted';

  @override
  String get commentsPin => 'Pin';

  @override
  String get commentsUnpin => 'Unpin';

  @override
  String get commentsReport => 'Report';

  @override
  String get commentsModHide => 'Hide (moderator)';

  @override
  String get commentsModUnhide => 'Unhide (moderator)';

  @override
  String get commentsModDelete => 'Delete (moderator)';

  @override
  String get commentsModDeleteTitle => 'Delete this comment for everyone?';

  @override
  String get commentsModDeleteBody =>
      'It\'s removed for every reader and recorded in the audit log.';

  @override
  String get commentsHidden => 'Comment hidden';

  @override
  String get commentsUnhidden => 'Comment visible again';

  @override
  String get commentsReportTitle => 'Report comment';

  @override
  String get commentsReportBody =>
      'Why are you reporting it? Our moderators will review it.';

  @override
  String get commentsReportSpam => 'Spam';

  @override
  String get commentsReportMisinformation => 'Misinformation';

  @override
  String get commentsReportHarassment => 'Harassment';

  @override
  String get commentsReportCopyright => 'Copyright';

  @override
  String get commentsReportOther => 'Something else';

  @override
  String get commentsReportDetails => 'Details (optional)';

  @override
  String get commentsReportSubmit => 'Send report';

  @override
  String get commentsReportThanks => 'Thanks, we\'ll review it.';

  @override
  String get commentsErrRateLimited =>
      'You\'re commenting too fast. Wait a minute and try again.';

  @override
  String get commentsErrNotFound => 'This comment doesn\'t exist anymore.';

  @override
  String get commentsErrNotOwner => 'Only the comment\'s author can change it.';

  @override
  String get commentsErrNotAvailable => 'This comment was deleted or hidden.';

  @override
  String get commentsErrPinReply => 'Only top-level comments can be pinned.';

  @override
  String get commentsErrPinNotAuthor =>
      'Only the article\'s author can pin comments.';

  @override
  String get commentsErrPinConflict =>
      'Another comment was pinned at the same time. Try again.';

  @override
  String get commentsErrArticleLimit =>
      'You\'ve commented a lot on this article. Try again later.';

  @override
  String get commentsErrDuplicate => 'You just posted the same comment.';

  @override
  String get commentsErrEmpty => 'Write something first.';

  @override
  String get commentsErrTooLong =>
      'A comment can have at most 2000 characters.';

  @override
  String get commentsErrReportOwnContent =>
      'You can\'t report your own comment.';

  @override
  String get commentsErrReportNotSupported => 'This can\'t be reported yet.';

  @override
  String get commentsErrReportReason => 'Choose a reason.';

  @override
  String get myArticlesTitle => 'My articles';

  @override
  String get myArticlesDrafts => 'Drafts';

  @override
  String get myArticlesPublished => 'Published';

  @override
  String get myArticlesNew => 'New article';

  @override
  String get myArticlesEmptyDrafts => 'No drafts yet';

  @override
  String get myArticlesEmptyDraftsBody =>
      'Start a new article. It saves itself while you write.';

  @override
  String get myArticlesEmptyPublished => 'Nothing published yet';

  @override
  String get myArticlesEmptyPublishedBody =>
      'The articles you publish show up here.';

  @override
  String get untitledArticle => 'Untitled';

  @override
  String get unpublishedChanges => 'Unpublished changes';

  @override
  String myArticleEdited(String date) {
    return 'Edited $date';
  }

  @override
  String myArticlePublishedOn(String date) {
    return 'Published $date';
  }

  @override
  String get deleteArticleTitle => 'Delete this article?';

  @override
  String get deleteDraftBody => 'The draft will be deleted for good.';

  @override
  String get deletePublishedBody =>
      'Readers won\'t see it anymore, and its link will stop working.';

  @override
  String get articleDeleted => 'Article deleted';

  @override
  String get editorNewTitle => 'New article';

  @override
  String get editorEditTitle => 'Edit article';

  @override
  String get editorTitleHint => 'Title';

  @override
  String get editorSubtitleHint => 'Subtitle (optional)';

  @override
  String get editorStartWriting => 'Write here, or type / to add a block';

  @override
  String get saveStatusSaving => 'Saving…';

  @override
  String get saveStatusSaved => 'Saved';

  @override
  String get saveStatusOffline => 'Offline, saved on this device';

  @override
  String get saveStatusFailed => 'Couldn\'t save';

  @override
  String get saveStatusUnsaved => 'Not saved yet';

  @override
  String get editorPublish => 'Publish';

  @override
  String get editorUpdate => 'Update';

  @override
  String get editorPublishing => 'Publishing…';

  @override
  String get editorPublishedMessage => 'Published';

  @override
  String get editorUpdatedMessage => 'Updated';

  @override
  String get editorPreview => 'Preview';

  @override
  String get editorSettings => 'Article settings';

  @override
  String get editorRevisions => 'Revision history';

  @override
  String get editorDiscardChanges => 'Discard changes';

  @override
  String get editorDelete => 'Delete article';

  @override
  String get editorMore => 'More';

  @override
  String get discardChangesTitle => 'Discard the unpublished changes?';

  @override
  String get discardChangesBody =>
      'The article goes back to what readers see now.';

  @override
  String get discardAction => 'Discard';

  @override
  String get changesDiscarded => 'Changes discarded';

  @override
  String get conflictTitle => 'Edited somewhere else';

  @override
  String get conflictBody =>
      'This article changed on another device or tab. Which version do you want to keep?';

  @override
  String get conflictReload => 'Load the saved version';

  @override
  String get conflictKeepMine => 'Keep mine';

  @override
  String get restoreBackupTitle => 'Restore unsaved changes?';

  @override
  String restoreBackupBody(String time) {
    return 'This device kept changes from $time that weren\'t saved.';
  }

  @override
  String get restoreAction => 'Restore';

  @override
  String get discardBackupAction => 'Don\'t restore';

  @override
  String get checksTitle => 'Before you publish';

  @override
  String get checksReady => 'Ready to publish';

  @override
  String checksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things to fix',
      one: '1 thing to fix',
    );
    return '$_temp0';
  }

  @override
  String get checksUploading => 'Wait for the uploads to finish.';

  @override
  String get problemFieldRequired => 'Choose a field.';

  @override
  String get problemTitleLength => 'The title needs 5 to 150 characters.';

  @override
  String get problemContentEmpty => 'Write something in the article.';

  @override
  String get problemContentInvalid =>
      'Some blocks aren\'t complete, like a step without a title.';

  @override
  String get problemImageAlt => 'An image needs alt text.';

  @override
  String get problemSourcesRequired => 'This field needs at least one source.';

  @override
  String get problemAttachmentAlt => 'An attached image needs alt text.';

  @override
  String get problemAttachmentTitle => 'The PDF needs a title.';

  @override
  String get problemAttachmentNotReady =>
      'An attachment is still uploading, or it failed.';

  @override
  String get errDraftConflict => 'This article was changed somewhere else.';

  @override
  String get errNotPublished => 'This article isn\'t published yet.';

  @override
  String get errRevisionNotFound => 'This version doesn\'t exist anymore.';

  @override
  String get articleVersionArabic => 'Arabic';

  @override
  String get articleVersionEnglish => 'English';

  @override
  String get languageVersions => 'Language versions';

  @override
  String get sourceLanguageTag => 'Source';

  @override
  String get sourceLanguageHint =>
      'The language you write first. Change it before adding a translation.';

  @override
  String addTranslation(String language) {
    return 'Add the $language version';
  }

  @override
  String removeTranslation(String language) {
    return 'Remove the $language version';
  }

  @override
  String get removeTranslationBody => 'Its title and text will be deleted.';

  @override
  String get removeAction => 'Remove';

  @override
  String get topicLabel => 'Topic';

  @override
  String get topicNone => 'No topic';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get tagsHint => 'Type a tag and press enter';

  @override
  String tagsLimit(int count) {
    return '$count of 5 tags';
  }

  @override
  String removeTag(String tag) {
    return 'Remove $tag';
  }

  @override
  String get coverLabel => 'Cover image';

  @override
  String get coverAdd => 'Add a cover';

  @override
  String get coverChange => 'Change';

  @override
  String get coverRemove => 'Remove';

  @override
  String get coverHint => 'Shown on the article\'s card in the feed.';

  @override
  String get uploadingLabel => 'Uploading…';

  @override
  String get versionBadgeLabel => 'Version badge';

  @override
  String get versionBadgeHint => 'e.g. .NET 10';

  @override
  String get aiAssistedSwitch => 'Written with AI help';

  @override
  String get aiAssistedSwitchHint =>
      'Readers see an “AI-assisted” label on the article.';

  @override
  String get blockParagraph => 'Text';

  @override
  String get blockHeading2 => 'Heading';

  @override
  String get blockHeading3 => 'Subheading';

  @override
  String get blockBulletList => 'Bulleted list';

  @override
  String get blockOrderedList => 'Numbered list';

  @override
  String get blockSteps => 'Steps';

  @override
  String get blockQuote => 'Quote';

  @override
  String get blockCallout => 'Callout';

  @override
  String get blockCode => 'Code';

  @override
  String get blockCodeTabs => 'Code tabs';

  @override
  String get blockTable => 'Table';

  @override
  String get blockImage => 'Image';

  @override
  String get blockDivider => 'Divider';

  @override
  String get blockEmbed => 'YouTube or Gist';

  @override
  String get blockSummary => 'TL;DR summary';

  @override
  String get addBlock => 'Add a block';

  @override
  String get blockOptions => 'Block options';

  @override
  String get blockDirection => 'Direction';

  @override
  String get dirAuto => 'Automatic';

  @override
  String get dirRtl => 'Right to left';

  @override
  String get dirLtr => 'Left to right';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get deleteBlock => 'Delete block';

  @override
  String get turnInto => 'Turn into';

  @override
  String get calloutTip => 'Tip';

  @override
  String get calloutInfo => 'Info';

  @override
  String get calloutWarning => 'Warning';

  @override
  String get calloutDanger => 'Danger';

  @override
  String get calloutTitleHint => 'Title (optional)';

  @override
  String get quoteCiteHint => 'Who said it (optional)';

  @override
  String get codeFilenameHint => 'File name (optional)';

  @override
  String get codeHint => 'Code';

  @override
  String get codeTabLabelHint => 'Tab name';

  @override
  String get addCodeTab => 'Add tab';

  @override
  String get removeCodeTab => 'Remove tab';

  @override
  String get tableAddRow => 'Add row';

  @override
  String get tableAddColumn => 'Add column';

  @override
  String get tableDeleteRow => 'Delete row';

  @override
  String get tableDeleteColumn => 'Delete column';

  @override
  String get tableDelete => 'Delete table';

  @override
  String get tableTools => 'Table';

  @override
  String get stepTitleHint => 'Step title';

  @override
  String get stepContentHint => 'Details';

  @override
  String get addStep => 'Add step';

  @override
  String get removeStep => 'Remove step';

  @override
  String get listItemHint => 'List item';

  @override
  String get imageChoose => 'Choose an image';

  @override
  String get imageAltLabel => 'Alt text (required)';

  @override
  String get imageAltHelp => 'Describe the image for people who can\'t see it.';

  @override
  String get imageCaptionLabel => 'Caption (optional)';

  @override
  String get imageReplace => 'Replace image';

  @override
  String get embedUrlLabel => 'Link';

  @override
  String get embedInvalid => 'Paste a YouTube or GitHub Gist link.';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatItalic => 'Italic';

  @override
  String get formatCode => 'Inline code';

  @override
  String get formatHighlight => 'Highlight';

  @override
  String get formatStrike => 'Strikethrough';

  @override
  String get formatLink => 'Link';

  @override
  String get formatLineBreak => 'Line break';

  @override
  String get formatMention => 'Mention someone';

  @override
  String get linkDialogTitle => 'Link';

  @override
  String get linkUrlLabel => 'URL (http or https)';

  @override
  String get linkRemove => 'Remove link';

  @override
  String get linkInvalid => 'Use an http or https link.';

  @override
  String get slashNoMatches => 'No block with that name';

  @override
  String get previewTitle => 'Preview';

  @override
  String get previewInFeed => 'In the feed';

  @override
  String get previewLight => 'Light';

  @override
  String get previewDark => 'Dark';

  @override
  String get revisionsEmpty =>
      'No versions yet. Every publish and update adds one.';

  @override
  String revisionLabel(int number) {
    return 'Version $number';
  }

  @override
  String get revisionFirst => 'First publish';

  @override
  String get revisionRestore => 'Restore this version';

  @override
  String revisionRestoreTitle(int number) {
    return 'Restore version $number?';
  }

  @override
  String get revisionRestoreBody =>
      'It replaces what\'s in the editor now. Readers see it only after you press Update.';

  @override
  String get revisionRestored =>
      'Version restored. Press Update to publish it.';

  @override
  String get errAppleConfirmationRequired =>
      'This account is linked to Apple. Confirm with Apple to delete it.';

  @override
  String get errDeletionUnavailable =>
      'We couldn\'t finish deleting your account, so nothing was deleted. Try again in a few minutes.';
}
