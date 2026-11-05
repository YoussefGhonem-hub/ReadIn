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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reading streak: $count days',
      one: 'Reading streak: 1 day',
    );
    return '$_temp0';
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
  String get langToggleArEg => 'مصري + EN';

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
  String get profilePathsEmptyTitle => 'No paths yet';

  @override
  String get profilePathsEmptyOwnBody =>
      'Join a learning path and your progress shows up here.';

  @override
  String get profilePathsEmptyBody =>
      'The learning paths they join show up here.';

  @override
  String get profilePathsPrivateTitle => 'Learning paths are private';

  @override
  String get profilePathsPrivateBody =>
      'This reader keeps their reading activity private.';

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
  String get profileWhoCanMention => 'Who can mention me';

  @override
  String get profileWhoCanMentionEveryone => 'Everyone';

  @override
  String get profileWhoCanMentionFollowing => 'People I follow';

  @override
  String get profileWhoCanMentionNobody => 'Nobody';

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
      'Your interests, reading progress and stats, reactions, comment likes and the reports you filed, saved articles and collections, your writer categories (your published articles stay, without a category), the people you follow and your followers';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reading streak: $count days. You haven\'t read today yet.',
      one: 'Reading streak: 1 day. You haven\'t read today yet.',
    );
    return '$_temp0';
  }

  @override
  String readingStreakFreezePendingSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Reading streak: $count days. You missed yesterday: read today and a freeze keeps your streak.',
      one:
          'Reading streak: 1 day. You missed yesterday: read today and a freeze keeps your streak.',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak!',
      one: '1-day streak!',
    );
    return '$_temp0';
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
  String get tagsHint => 'Type a tag, then Enter or a comma';

  @override
  String tagsLimit(int count) {
    return '$count of 5 tags';
  }

  @override
  String removeTag(String tag) {
    return 'Remove $tag';
  }

  @override
  String get tagsFull =>
      'That\'s 5 tags, the most an article can have. Remove one to add another.';

  @override
  String get tagsAdd => 'Add';

  @override
  String tagCreate(String name) {
    return 'Create new tag: $name';
  }

  @override
  String get tagSuggestionsLabel => 'Suggested tags';

  @override
  String get tagAlreadyAdded => 'The article already has this tag.';

  @override
  String get tagTooShort => 'A tag needs at least 2 characters.';

  @override
  String get tagTooLong => 'A tag can have at most 30 characters.';

  @override
  String get tagInvalidCharacters =>
      'Use letters, digits, spaces and - _ . + # only.';

  @override
  String get tagNoLetter => 'A tag needs at least one letter or digit.';

  @override
  String problemTagHidden(String name) {
    return 'The tag $name isn\'t available. Remove it or choose another one.';
  }

  @override
  String problemTagLimit(String name) {
    return 'You\'ve created a lot of new tags today, so $name can\'t be added now. Pick an existing tag, or try again later.';
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
  String get formatTerm => 'Glossary term';

  @override
  String get termPickerFor => 'Mark as a glossary term:';

  @override
  String get termPickerCurrent => 'Glossary term:';

  @override
  String get termSearchHint => 'Search the glossary (English term)';

  @override
  String get termSearching => 'Searching…';

  @override
  String get termNoMatches => 'No glossary term matches. Try the English term.';

  @override
  String get termTypeToSearch => 'Type a term to search the glossary.';

  @override
  String get termSearchError => 'Couldn\'t search the glossary.';

  @override
  String get termRemove => 'Remove term';

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

  @override
  String get continueReading => 'Continue reading';

  @override
  String continueReadingProgress(int percent) {
    return '$percent% read';
  }

  @override
  String get pathsTitle => 'Learning paths';

  @override
  String get pathsTabAll => 'All paths';

  @override
  String get pathsTabMine => 'My paths';

  @override
  String get pathsPrompt => 'Learn step by step with learning paths';

  @override
  String get pathsBrowse => 'Explore learning paths';

  @override
  String get pathsEmptyTitle => 'No learning paths here yet';

  @override
  String get pathsEmptyBody =>
      'We\'re putting the first ones together. Check back soon.';

  @override
  String get myPathsEmptyTitle => 'You haven\'t started a path yet';

  @override
  String get myPathsEmptyBody =>
      'Pick a path and learn a topic one article at a time.';

  @override
  String get myPathsGuestTitle => 'Keep track of your paths';

  @override
  String get myPathsGuestBody =>
      'Create a free account to join paths and pick up where you left off.';

  @override
  String pathArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String pathMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String pathProgressSemantics(int read, int total) {
    return '$read of $total articles read';
  }

  @override
  String get pathCompleted => 'Completed';

  @override
  String get pathCompletedCelebration => 'Path completed 🎉';

  @override
  String get pathStart => 'Start path';

  @override
  String pathContinue(String title) {
    return 'Continue: $title';
  }

  @override
  String get pathReadAgain => 'Read again';

  @override
  String pathNext(String title) {
    return 'Next: $title';
  }

  @override
  String get pathUpNext => 'Up next';

  @override
  String get pathItemRead => 'Read';

  @override
  String get pathMenu => 'Path options';

  @override
  String get pathLeave => 'Leave path';

  @override
  String get pathLeaveTitle => 'Leave this path?';

  @override
  String get pathLeaveBody =>
      'Your reading history stays. Join again any time and your progress comes back.';

  @override
  String get pathLeft => 'You left the path';

  @override
  String get pathJoin => 'Join path';

  @override
  String get pathJoined => 'You joined the path';

  @override
  String pathFrom(String title) {
    return 'From the path: $title';
  }

  @override
  String pathPosition(int position, int total) {
    return '$position of $total';
  }

  @override
  String get pathNextInPath => 'Next in path';

  @override
  String get pathLastArticle => 'This is the last article in the path';

  @override
  String get pathNotFoundTitle => 'This path isn\'t available';

  @override
  String get pathNotFoundBody =>
      'It may have been removed, or the link is wrong.';

  @override
  String get errPathNotFound => 'This path doesn\'t exist or was removed.';

  @override
  String get errPathSlugTaken => 'Another path already uses this link.';

  @override
  String get errPathEditorial =>
      'Editorial paths are managed in the content files.';

  @override
  String get errPathItemsInvalid =>
      'Check the path\'s articles: 1 to 100 published articles, each one once.';

  @override
  String get reportTitleArticle => 'Report article';

  @override
  String get reportTitleComment => 'Report comment';

  @override
  String get reportTitleUser => 'Report user';

  @override
  String get reportBody =>
      'Why are you reporting this? Our moderators will review it.';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonMisinformation => 'Misinformation';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonCopyright => 'Copyright';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportDetails => 'Details (optional)';

  @override
  String get reportSubmit => 'Send report';

  @override
  String get reportThanks => 'Thanks, we\'ll review it.';

  @override
  String errSuspendedUntil(String date) {
    return 'This account is suspended until $date. Contact support.';
  }

  @override
  String get errSuspendedPermanently =>
      'This account is permanently suspended. Contact support.';

  @override
  String get errReportOwnContent =>
      'You can\'t report yourself or your own content.';

  @override
  String get errReportReason => 'Choose a reason.';

  @override
  String get errReportTargetInvalid => 'This can\'t be reported.';

  @override
  String get errReportTargetNotFound =>
      'What you\'re reporting doesn\'t exist anymore.';

  @override
  String get errModerationActionInvalid => 'This action isn\'t available here.';

  @override
  String get errModerationSelf => 'You can\'t do this to your own account.';

  @override
  String get errModerationStaffTarget =>
      'You can\'t warn or suspend a member of the moderation team.';

  @override
  String get errModerationNoteRequired => 'Write a note first.';

  @override
  String get errModerationDurationInvalid => 'Choose between 1 and 365 days.';

  @override
  String get errModerationNoticeNotFound =>
      'This notice isn\'t available anymore.';

  @override
  String get articleMenu => 'Article options';

  @override
  String get articleMenuReport => 'Report article';

  @override
  String get articleMenuHide => 'Hide article';

  @override
  String get articleMenuUnhide => 'Unhide article';

  @override
  String get articleHiddenBannerTitle => 'Hidden by moderators';

  @override
  String get articleHiddenBannerBody =>
      'Only its author and moderators can see it.';

  @override
  String get profileMenu => 'More options';

  @override
  String get profileMenuReport => 'Report user';

  @override
  String get profileMenuWarn => 'Warn';

  @override
  String get profileMenuSuspend => 'Suspend account';

  @override
  String get moderationTitle => 'Moderation';

  @override
  String get moderationQueueEntry => 'Reports';

  @override
  String moderationWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items waiting for review',
      one: '1 item waiting for review',
      zero: 'Nothing waiting for review',
    );
    return '$_temp0';
  }

  @override
  String get moderationNoAccessTitle => 'This page is for moderators';

  @override
  String get moderationNoAccessBody =>
      'Your account doesn\'t have moderation access.';

  @override
  String get moderationTabOpen => 'Open';

  @override
  String get moderationTabResolved => 'Resolved';

  @override
  String get moderationTabDismissed => 'Dismissed';

  @override
  String get moderationTabLog => 'Log';

  @override
  String get moderationFilterAll => 'All';

  @override
  String get moderationFilterArticles => 'Articles';

  @override
  String get moderationFilterComments => 'Comments';

  @override
  String get moderationFilterUsers => 'Users';

  @override
  String get moderationEmptyOpenTitle => 'No open reports';

  @override
  String get moderationEmptyOpenBody => 'All clear for now.';

  @override
  String get moderationEmptyResolvedTitle => 'No resolved reports';

  @override
  String get moderationEmptyDismissedTitle => 'No dismissed reports';

  @override
  String get moderationEmptyLogTitle => 'No moderation actions yet';

  @override
  String get moderationLoadMoreFailed => 'Couldn\'t load more.';

  @override
  String get moderationTypeArticle => 'Article';

  @override
  String get moderationTypeComment => 'Comment';

  @override
  String get moderationTypeUser => 'User';

  @override
  String get moderationStateHidden => 'Hidden';

  @override
  String get moderationStateDeleted => 'Deleted';

  @override
  String get moderationStateSuspended => 'Suspended';

  @override
  String get moderationStatusOpen => 'Open';

  @override
  String get moderationStatusResolved => 'Resolved';

  @override
  String get moderationStatusDismissed => 'Dismissed';

  @override
  String moderationReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String moderationLastReport(String time) {
    return 'Last report: $time';
  }

  @override
  String moderationClosed(String time) {
    return 'Closed: $time';
  }

  @override
  String moderationCommentOn(String title) {
    return 'On “$title”';
  }

  @override
  String moderationWarningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warnings',
      one: '1 warning',
      zero: 'No warnings',
    );
    return '$_temp0';
  }

  @override
  String moderationSuspendedUntil(String date) {
    return 'Suspended until $date';
  }

  @override
  String get moderationSuspendedForever => 'Permanently suspended';

  @override
  String get moderationCaseArticle => 'Reported article';

  @override
  String get moderationCaseComment => 'Reported comment';

  @override
  String get moderationCaseUser => 'Reported user';

  @override
  String get moderationOpenArticle => 'Open article';

  @override
  String get moderationOpenProfile => 'Open profile';

  @override
  String get moderationActions => 'Actions';

  @override
  String moderationReportsTitle(int count) {
    return 'Reports ($count)';
  }

  @override
  String get moderationHistory => 'History';

  @override
  String get moderationHistoryEmpty => 'No actions yet.';

  @override
  String moderationClosedBy(String name) {
    return 'Closed by $name';
  }

  @override
  String get moderationHideComment => 'Hide comment';

  @override
  String get moderationUnhideComment => 'Unhide comment';

  @override
  String get moderationDeleteComment => 'Delete comment';

  @override
  String get moderationWarnAuthor => 'Warn author';

  @override
  String get moderationSuspendAuthor => 'Suspend author';

  @override
  String get moderationUnsuspend => 'Lift suspension';

  @override
  String get moderationDismiss => 'Dismiss reports';

  @override
  String get moderationHideArticleTitle => 'Hide this article?';

  @override
  String get moderationHideArticleBody =>
      'It disappears from feeds, lists and search, and only its author and moderators can open it. The author is notified.';

  @override
  String get moderationHideCommentTitle => 'Hide this comment?';

  @override
  String get moderationHideCommentBody =>
      'Readers see “Hidden by moderators” in its place.';

  @override
  String get moderationNoteOptional => 'Note (optional)';

  @override
  String get moderationNoteLabel => 'Note';

  @override
  String get moderationNoteForUser => 'They\'ll see this note.';

  @override
  String moderationWarnTitle(String name) {
    return 'Warn $name';
  }

  @override
  String get moderationWarnBody =>
      'They\'ll get a warning with your note and must acknowledge it.';

  @override
  String get moderationWarnConfirm => 'Send warning';

  @override
  String moderationSuspendTitle(String name) {
    return 'Suspend $name';
  }

  @override
  String get moderationSuspendBody =>
      'They can\'t sign in or use their account until the suspension ends.';

  @override
  String get moderationSuspendDuration => 'Duration';

  @override
  String moderationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get moderationPermanent => 'Permanently';

  @override
  String get moderationSuspendConfirm => 'Suspend';

  @override
  String moderationUnsuspendTitle(String name) {
    return 'Lift $name\'s suspension?';
  }

  @override
  String get moderationUnsuspendBody =>
      'They can sign in and use their account again right away.';

  @override
  String get moderationDismissTitle => 'Dismiss these reports?';

  @override
  String get moderationDismissBody =>
      'The open reports are closed as dismissed. The content stays as it is.';

  @override
  String get moderationArticleHidden => 'Article hidden';

  @override
  String get moderationArticleUnhidden => 'Article visible again';

  @override
  String get moderationWarned => 'Warning sent';

  @override
  String get moderationSuspended => 'Account suspended';

  @override
  String get moderationUnsuspended => 'Suspension lifted';

  @override
  String get moderationDismissed => 'Reports dismissed';

  @override
  String get moderationLogCommentHide => 'Hid a comment';

  @override
  String get moderationLogCommentUnhide => 'Unhid a comment';

  @override
  String get moderationLogCommentDelete => 'Deleted a comment';

  @override
  String get moderationLogArticleHide => 'Hid an article';

  @override
  String get moderationLogArticleUnhide => 'Unhid an article';

  @override
  String get moderationLogUserWarn => 'Warned a user';

  @override
  String get moderationLogUserSuspend => 'Suspended an account';

  @override
  String get moderationLogUserUnsuspend => 'Lifted a suspension';

  @override
  String get moderationLogReportsDismiss => 'Dismissed reports';

  @override
  String get moderationLogOther => 'Moderation action';

  @override
  String moderationLogReportsClosed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Closed $count reports',
      one: 'Closed 1 report',
    );
    return '$_temp0';
  }

  @override
  String moderationLogUntil(String date) {
    return 'Until $date';
  }

  @override
  String get noticeWarningTitle =>
      'You received a warning from the moderation team';

  @override
  String get noticeWarningBody =>
      'Please read the note and keep to ReadIn\'s community rules.';

  @override
  String noticeArticleHiddenTitle(String title) {
    return 'Your article “$title” was hidden';
  }

  @override
  String get noticeArticleHiddenBody =>
      'Readers can\'t see it anymore. Only you and the moderators can open it.';

  @override
  String get noticeNoteLabel => 'Moderator\'s note';

  @override
  String get noticeAcknowledge => 'Got it';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsNewItems => 'New notifications — show them';

  @override
  String get notificationsToday => 'Today';

  @override
  String get notificationsEarlier => 'Earlier';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyBody =>
      'Replies, mentions, new followers and today\'s article show up here.';

  @override
  String get notificationsUnreadDot => 'Unread';

  @override
  String notifNewFollower(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name and $others others started following you',
      one: '$name and 1 other started following you',
      zero: '$name started following you',
    );
    return '$_temp0';
  }

  @override
  String notifArticleComment(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name and $others others commented on your article',
      one: '$name and 1 other commented on your article',
      zero: '$name commented on your article',
    );
    return '$_temp0';
  }

  @override
  String notifCommentReply(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name and $others others replied to your comment',
      one: '$name and 1 other replied to your comment',
      zero: '$name replied to your comment',
    );
    return '$_temp0';
  }

  @override
  String notifMention(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name and $others others mentioned you in a comment',
      one: '$name and 1 other mentioned you in a comment',
      zero: '$name mentioned you in a comment',
    );
    return '$_temp0';
  }

  @override
  String notifMentionArticle(String name) {
    return '$name mentioned you in an article';
  }

  @override
  String notifFollowedWriterArticle(String name) {
    return '$name published a new article';
  }

  @override
  String notifReactionsMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your article reached $count reactions 🎉',
      one: 'Your article got its first reaction 🎉',
    );
    return '$_temp0';
  }

  @override
  String get notifReactionsMilestoneGeneric =>
      'Readers are reacting to your article 🎉';

  @override
  String get notifDailyArticle => 'Today\'s article is ready ☕';

  @override
  String notifStreakReminder(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Read an article today to keep your $days-day streak 🔥',
      one: 'Read an article today to keep your 1-day streak 🔥',
    );
    return '$_temp0';
  }

  @override
  String get notifStreakReminderGeneric =>
      'Read an article today to keep your streak 🔥';

  @override
  String get notifSecurityPasswordChanged => 'Your password was changed';

  @override
  String get notifSecurityPasswordReset => 'Your password was reset';

  @override
  String get notifSecurityRecoveryPinChanged => 'Your recovery PIN was changed';

  @override
  String get notifSecurityPhoneNumberChanged => 'Your phone number was changed';

  @override
  String get notifSecurityRecoveryLockedOut =>
      'Account recovery was locked after too many wrong PINs';

  @override
  String get notifSecurityExternalLoginLinked =>
      'A Google or Apple account was linked to your account';

  @override
  String get notifSecurityExternalLoginUnlinked =>
      'A Google or Apple account was unlinked from your account';

  @override
  String get notifSecurityPhoneSignInAdded =>
      'A phone number and password were added to your account';

  @override
  String get notifSecurityGeneric =>
      'There was a security change on your account';

  @override
  String get notifSecurityHint =>
      'If this wasn\'t you, change your password now.';

  @override
  String get notifVerificationResult =>
      'There\'s an update on your verification request';

  @override
  String get notifVerificationApproved => 'You\'re now a verified writer ✓';

  @override
  String get notifVerificationRejected =>
      'Your verification request wasn\'t approved';

  @override
  String get notifVerificationRejectedHint => 'Open it to see why';

  @override
  String get notifModerationWarning =>
      'You received a warning from the moderation team';

  @override
  String get notifModerationArticleHidden => 'The moderators hid your article';

  @override
  String get notifGeneric => 'You have a new notification';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get notificationSettingsEntryHint =>
      'Push, in app or off for each type, and quiet hours';

  @override
  String get notificationSettingsTypesTitle => 'What reaches you';

  @override
  String get notificationSettingsTypesHint =>
      'Push notifications show up in your notification center too.';

  @override
  String get notificationModeAll => 'Push + in app';

  @override
  String get notificationModeInApp => 'In app only';

  @override
  String get notificationModeOff => 'Off';

  @override
  String get notificationModeAllShort => 'Push';

  @override
  String get notificationModeInAppShort => 'In app';

  @override
  String get notificationTypeNewFollower => 'New followers';

  @override
  String get notificationTypeArticleComment => 'Comments on your articles';

  @override
  String get notificationTypeCommentReply => 'Replies to your comments';

  @override
  String get notificationTypeMention => 'Mentions';

  @override
  String get notificationTypeMentionHint =>
      'When someone mentions you in a comment or an article';

  @override
  String get notificationTypeReactionsMilestone =>
      'Reaction milestones (10, 50, 100)';

  @override
  String get notificationTypeFollowedWriterArticle =>
      'New articles from writers you follow';

  @override
  String get notificationTypeDailyArticle => 'Today\'s article';

  @override
  String get notificationTypeStreakReminder => 'Streak reminder (8 PM)';

  @override
  String get notificationSecurityAlerts => 'Security alerts';

  @override
  String get notificationSecurityAlertsHint =>
      'Always on, even in quiet hours.';

  @override
  String get quietHoursTitle => 'Quiet hours';

  @override
  String get quietHoursHint =>
      'Pushes wait until quiet hours end. Security alerts arrive right away.';

  @override
  String get quietHoursSwitch => 'Hold pushes during these hours';

  @override
  String get quietHoursFrom => 'From';

  @override
  String get quietHoursTo => 'To';

  @override
  String get errNotificationNotFound =>
      'This notification is no longer available.';

  @override
  String get errNotificationTypeInvalid =>
      'That notification type doesn\'t exist.';

  @override
  String get errNotificationModeInvalid => 'Pick push, in app or off.';

  @override
  String get errNotificationQuietHoursInvalid =>
      'Quiet hours need two different times.';

  @override
  String get settingsWriting => 'Writing';

  @override
  String get verificationTitle => 'Writer verification';

  @override
  String get verificationEntryHint => 'Get the verified writer badge';

  @override
  String get verificationStatusVerified => 'You\'re a verified writer';

  @override
  String get verificationStatusPending => 'Your request is under review';

  @override
  String get verificationStatusRejected => 'Not approved, open it to see why';

  @override
  String get verificationIntro =>
      'Verified writers get a badge next to their name on their articles, profile and comments. Tell us what you do and show us some proof.';

  @override
  String get verificationFieldLabel => 'Field';

  @override
  String get verificationFieldHint => 'Pick your field';

  @override
  String get verificationFieldsFailed => 'Couldn\'t load the fields.';

  @override
  String get verificationJobTitleLabel => 'Job title';

  @override
  String get verificationJobTitleHint => 'e.g. Senior Backend Engineer';

  @override
  String get verificationProofTitle => 'Proof';

  @override
  String get verificationProofHint => 'Add a link, a file, or both.';

  @override
  String get verificationProofUrlLabel => 'Link (LinkedIn, GitHub…)';

  @override
  String get verificationProofFileAdd => 'Attach a file';

  @override
  String get verificationProofFileHint =>
      'A certificate or syndicate card: PDF, JPEG, PNG or WebP, up to 10 MB.';

  @override
  String get verificationProofFileRemove => 'Remove the file';

  @override
  String get verificationProofPrivate =>
      'Only the reviewers see your file, and it\'s deleted once your request is decided.';

  @override
  String get verificationNoteLabel => 'Note (optional)';

  @override
  String get verificationNoteHint => 'Anything the reviewers should know';

  @override
  String get verificationSubmit => 'Send request';

  @override
  String get verificationSubmitting => 'Sending your request…';

  @override
  String get verificationPendingTitle => 'Your request is under review';

  @override
  String get verificationPendingBody =>
      'We\'ll notify you once it\'s reviewed.';

  @override
  String verificationSubmittedOn(String date) {
    return 'Sent on $date';
  }

  @override
  String get verificationLinkLabel => 'Link';

  @override
  String get verificationFileLabel => 'File';

  @override
  String get verificationNoteSummaryLabel => 'Note';

  @override
  String get verificationWithdraw => 'Withdraw request';

  @override
  String get verificationWithdrawTitle => 'Withdraw your request?';

  @override
  String get verificationWithdrawBody =>
      'It\'s deleted along with its file. You can send a new one any time.';

  @override
  String get verificationWithdrawConfirm => 'Withdraw';

  @override
  String get verificationWithdrawn => 'Request withdrawn';

  @override
  String get verificationApprovedTitle => 'You\'re a verified writer';

  @override
  String get verificationApprovedBody =>
      'The verified badge shows next to your name on your articles, profile and comments.';

  @override
  String verificationApprovedOn(String date) {
    return 'Verified on $date';
  }

  @override
  String get verificationRejectedTitle => 'Your request wasn\'t approved';

  @override
  String get verificationRejectedReason => 'Reviewer\'s reason';

  @override
  String verificationRejectedOn(String date) {
    return 'Reviewed on $date';
  }

  @override
  String get verificationRejectedBody =>
      'You can fix what\'s missing and request again.';

  @override
  String get verificationRequestAgain => 'Request again';

  @override
  String get verificationUnavailableTitle =>
      'You can\'t request verification right now';

  @override
  String get verificationUnavailableBody =>
      'A suspended account can\'t send verification requests.';

  @override
  String get errVerificationProofRequired => 'Add a link or a file as proof.';

  @override
  String get errVerificationProofInvalid =>
      'The proof file must be a PDF, JPEG, PNG or WebP of 10 MB or less.';

  @override
  String get errVerificationFieldInvalid => 'Pick a field from the list.';

  @override
  String get errVerificationAlreadyPending =>
      'You already have a request under review.';

  @override
  String get errVerificationAlreadyVerified =>
      'You\'re already a verified writer.';

  @override
  String get errVerificationNotFound =>
      'This request isn\'t waiting for review anymore.';

  @override
  String get healthDisclaimer =>
      'This information is for awareness only and is not a substitute for a doctor\'s advice.';

  @override
  String get articleToc => 'In this article';

  @override
  String get settingsSignInForSync =>
      'Sign in to save these settings to your account.';

  @override
  String get settingsSaved => 'Settings saved ✓';

  @override
  String get settingsInterests => 'Your interests';

  @override
  String get settingsInterestsHint => 'The fields and topics you follow';

  @override
  String get interestsPageIntro =>
      'Tap a field or topic to follow or unfollow it. Changes are saved right away and shape your For you feed.';

  @override
  String get interestsKeepThree => 'Keep at least 3 interests';

  @override
  String get imageDarkVersion => 'Dark mode version';

  @override
  String get imageDarkAdd => 'Add a dark mode version (for diagrams)';

  @override
  String get imageDarkRemove => 'Remove the dark mode version';

  @override
  String get postReadMore => 'Read more';

  @override
  String get postShowLess => 'Show less';

  @override
  String get postReadFullArticle => 'Read the full article';

  @override
  String get postReact => 'React';

  @override
  String get postComment => 'Comment';

  @override
  String get postOpenArticleHint => 'Opens the article';

  @override
  String get postCoverImage => 'Cover image, opens it full screen';

  @override
  String postMoreTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more tags',
      one: '1 more tag',
    );
    return '$_temp0';
  }

  @override
  String get tagOpenHint => 'Opens the tag page';

  @override
  String tagPageArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: 'No articles yet',
    );
    return '$_temp0';
  }

  @override
  String get tagPageEmptyTitle => 'No articles with this tag yet';

  @override
  String get tagPageEmptyBody =>
      'Once someone publishes an article with this tag, you\'ll find it here.';

  @override
  String get tagNotFoundTitle => 'This tag doesn\'t exist';

  @override
  String get tagNotFoundBody =>
      'It may have been removed or renamed. Try another tag.';

  @override
  String get searchHint => 'Search articles, writers, topics and tags';

  @override
  String get searchFieldHint => 'Search ReadIn';

  @override
  String get searchTabArticles => 'Articles';

  @override
  String get searchTabWriters => 'Writers';

  @override
  String get searchTabTopics => 'Topics';

  @override
  String get searchTabTags => 'Tags';

  @override
  String get searchRecentTitle => 'Recent searches';

  @override
  String get searchRecentClearAll => 'Clear all';

  @override
  String searchRecentRemove(String query) {
    return 'Remove “$query” from recent searches';
  }

  @override
  String get searchIdleTitle => 'What do you want to read about?';

  @override
  String get searchIdleBody =>
      'Search articles, writers, topics and tags, in Arabic or English.';

  @override
  String searchNoResultsTitle(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchNoResultsTip =>
      'Try another word or a shorter one, or look in another tab.';

  @override
  String get searchNoResultsFilteredTitle => 'No results with these filters';

  @override
  String searchNoResultsFiltersTip(String query) {
    return 'Clear the filters to see everything that matches “$query”.';
  }

  @override
  String get searchFoundInPdf => 'Found in the attached PDF';

  @override
  String get searchFilterField => 'Field';

  @override
  String get searchFilterLanguage => 'Article language';

  @override
  String get searchFilterReadingTime => 'Reading time';

  @override
  String searchFilterValue(String filter, String value) {
    return '$filter: $value';
  }

  @override
  String get searchFieldAll => 'All fields';

  @override
  String get searchLanguageAny => 'All languages';

  @override
  String get searchReadingTimeAny => 'Any length';

  @override
  String get searchReadingTimeUpTo5 => 'Up to 5 min';

  @override
  String get searchReadingTime5To10 => '5–10 min';

  @override
  String get searchReadingTimeOver10 => 'Over 10 min';

  @override
  String get searchClearFilters => 'Clear filters';

  @override
  String get searchKindField => 'Field';

  @override
  String get exploreFields => 'Fields';

  @override
  String get exploreTrending => 'Trending this week';

  @override
  String get exploreMostSaved => 'Most saved';

  @override
  String get exploreNewWriters => 'New writers';

  @override
  String get exploreFeaturedPaths => 'Featured paths';

  @override
  String get exploreSeeAll => 'See all';

  @override
  String exploreSeeAllSection(String section) {
    return 'See all: $section';
  }

  @override
  String get exploreEmptyTitle => 'Nothing to explore yet';

  @override
  String get exploreEmptyBody =>
      'Fields, articles, writers and paths show up here once people start publishing.';

  @override
  String get exploreTrendingEmptyTitle => 'Nothing is trending this week yet';

  @override
  String get exploreMostSavedEmptyTitle => 'No saved articles yet';

  @override
  String get exploreRankingEmptyBody =>
      'Check back soon, or browse the fields on Explore.';

  @override
  String fieldArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String fieldFollowerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count followers',
      one: '1 follower',
    );
    return '$_temp0';
  }

  @override
  String get fieldFollow => 'Follow field';

  @override
  String get fieldFollowTopic => 'Follow topic';

  @override
  String get fieldKeepThree =>
      'Keep at least 3 interests. Follow another field or topic first.';

  @override
  String get fieldTopics => 'Topics in this field';

  @override
  String get fieldTopWriters => 'Top writers in this field';

  @override
  String get fieldArticles => 'Latest articles';

  @override
  String get fieldEmptyTitle => 'No articles in this field yet';

  @override
  String get fieldEmptyBody =>
      'Follow it and you\'ll see new articles as soon as they\'re published.';

  @override
  String get fieldTopicEmptyTitle => 'No articles in this topic yet';

  @override
  String get fieldNotFoundTitle => 'This field doesn\'t exist';

  @override
  String get fieldNotFoundBody =>
      'It may have been removed, or the link is wrong.';

  @override
  String get fieldGoToExplore => 'Browse other fields';

  @override
  String get fieldTopicNotFoundTitle => 'This topic doesn\'t exist';

  @override
  String fieldTopicNotFoundBody(String field) {
    return 'It isn\'t one of the topics of $field, or it was removed.';
  }

  @override
  String get fieldShowAllArticles => 'All articles in this field';

  @override
  String get errInterestsUnknown => 'Some fields or topics don\'t exist.';

  @override
  String get errTopicNotFound => 'Topic not found.';

  @override
  String get errTopicNotInField => 'The topic doesn\'t belong to this field.';

  @override
  String get errArticleNotOwner => 'Only the author can change this article.';

  @override
  String get errArticleStatusInvalid => 'Status must be draft or published.';

  @override
  String get errArticleNoContent =>
      'The article is empty. Write something first.';

  @override
  String get errArticleInvalidTransition =>
      'You can\'t do that while the article is in this state.';

  @override
  String get errArticleSlugTaken =>
      'That link is already used by another article.';

  @override
  String get errArticleTagsMaxFive => 'An article can have at most 5 tags.';

  @override
  String get errArticleTooManyTags => 'An article can have at most 5 tags.';

  @override
  String get errTagNotFound => 'Tag not found.';

  @override
  String get errTagInvalid =>
      'A tag has 2–30 characters: letters, digits, spaces and - _ . + # only.';

  @override
  String get errTagLimit =>
      'You\'ve created a lot of new tags today. Pick existing tags, or try again later.';

  @override
  String get errTagHidden => 'This tag isn\'t available. Choose another one.';

  @override
  String get errArticleLanguageInvalid =>
      'That article language isn\'t supported.';

  @override
  String get errArticleContentLanguageMismatch =>
      'The content\'s language doesn\'t match the article\'s language.';

  @override
  String get errConcurrencyConflict =>
      'Someone else changed this. Refresh and try again.';

  @override
  String get errRequestInvalid => 'The request is invalid.';

  @override
  String get errRequestTooLarge => 'The request is too large.';

  @override
  String get errRequestUnsupportedMediaType =>
      'This content type is not supported.';

  @override
  String get errRouteNotFound => 'Not found.';

  @override
  String get errReportStatusInvalid =>
      'The report status must be open, resolved or dismissed.';

  @override
  String get errSearchQueryInvalid =>
      'Type 1–100 characters, with at least one letter or digit.';

  @override
  String get errSearchTypeInvalid =>
      'The search type must be articles, writers, topics or tags.';

  @override
  String get errSearchFilterInvalid => 'These search filters aren\'t valid.';

  @override
  String get profileTabCategories => 'Categories';

  @override
  String get categoriesOther => 'Other articles';

  @override
  String categoryArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: 'No articles yet',
    );
    return '$_temp0';
  }

  @override
  String get categoryOpenHint => 'Opens the category';

  @override
  String get categoriesEmptyTitle => 'No categories yet';

  @override
  String get categoriesEmptyBody =>
      'When this writer groups their articles into categories, you\'ll find them here.';

  @override
  String get categoriesOwnHint =>
      'Group your articles into categories. Your profile shows them in this order.';

  @override
  String get categoryNew => 'New category';

  @override
  String get categoriesFull =>
      'You have 50 categories, the most you can have. Delete one to add another.';

  @override
  String get categoriesEmptyOwnTitle => 'Organize your articles';

  @override
  String get categoriesEmptyOwnBody =>
      'Create categories like “Backend tips”, then put your articles in them from the editor. Readers see them on your profile.';

  @override
  String get categoryEmptyOwn => 'Empty: visitors don\'t see it';

  @override
  String get categoryRenameTitle => 'Rename category';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNameHint => 'e.g. Backend tips';

  @override
  String get categoryNameTooLong =>
      'A category name has at most 40 characters.';

  @override
  String get categoryNameNoLetter =>
      'A category name needs at least one letter or digit.';

  @override
  String get categoryMoveUp => 'Move up';

  @override
  String get categoryMoveDown => 'Move down';

  @override
  String get categoryDragHandle => 'Drag to reorder';

  @override
  String get categoryMenu => 'Category options';

  @override
  String categoryDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String categoryDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This category has $count articles. They stay published, without a category.',
      one:
          'This category has 1 article. It stays published, without a category.',
      zero: 'This category is empty.',
    );
    return '$_temp0';
  }

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get categoryPageEmptyTitle => 'No articles in this category yet';

  @override
  String get categoryPageEmptyBody =>
      'Once the writer adds articles to it, you\'ll find them here.';

  @override
  String get categoryOtherEmptyTitle => 'No articles without a category';

  @override
  String get categoryOtherEmptyBody =>
      'Every article of this writer is in a category.';

  @override
  String get categoryNotFoundTitle => 'This category doesn\'t exist';

  @override
  String get categoryNotFoundBody =>
      'It may have been deleted, or the link is wrong.';

  @override
  String get categoryWriterProfile => 'Go to the writer\'s profile';

  @override
  String articleInCategory(String name) {
    return 'In $name';
  }

  @override
  String get editorCategoryLabel => 'Category';

  @override
  String get editorCategoryNone => 'No category';

  @override
  String get editorCategoryHint =>
      'Optional: groups the article with others on your profile. A change applies right away.';

  @override
  String get editorCategoryLoadFailed => 'Couldn\'t load your categories.';

  @override
  String get moderationCategoriesTitle => 'Writer categories';

  @override
  String get moderationCategoriesEmpty => 'No categories.';

  @override
  String get moderationClearCategory => 'Clear name';

  @override
  String moderationClearCategoryTitle(String name) {
    return 'Clear the category name “$name”?';
  }

  @override
  String get moderationClearCategoryBody =>
      'The category gets a neutral name like “Category 1”, and its old link stops working. Its articles stay in it, and the writer isn\'t notified.';

  @override
  String get moderationCategoryCleared => 'Category name cleared';

  @override
  String get moderationLogUserClearCategory => 'Cleared a category name';

  @override
  String get errCategoryNotFound => 'Category not found.';

  @override
  String get errCategoryNotOwner => 'This category isn\'t yours.';

  @override
  String get errCategoryLimit => 'You can have at most 50 categories.';

  @override
  String get errCategoryNameTaken =>
      'You already have a category with this name.';

  @override
  String get errCategoryNameInvalid =>
      'A category name has 1–40 characters, with at least one letter or digit.';
}
