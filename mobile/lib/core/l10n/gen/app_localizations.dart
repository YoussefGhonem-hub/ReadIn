import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ReadIn'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Read daily. Grow daily.'**
  String get tagline;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re building this right now. It will arrive on the app and the web at the same time.'**
  String get comingSoonBody;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get navWrite;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name} 👋'**
  String greetingMorning(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name} 👋'**
  String greetingEvening(String name);

  /// No description provided for @greetingGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ReadIn 👋'**
  String get greetingGuest;

  /// No description provided for @greetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for a small dose of knowledge?'**
  String get greetingSubtitle;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Start your streak} =1{1 day} other{{count} days}}'**
  String streakDays(int count);

  /// No description provided for @streakSemantics.
  ///
  /// In en, this message translates to:
  /// **'Reading streak: {count} days'**
  String streakSemantics(int count);

  /// No description provided for @todayArticle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s article'**
  String get todayArticle;

  /// No description provided for @todayArticleCta.
  ///
  /// In en, this message translates to:
  /// **'Read now'**
  String get todayArticleCta;

  /// No description provided for @feedForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get feedForYou;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles here yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try another field or check back later.'**
  String get feedEmptyBody;

  /// No description provided for @endOfFeed.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up ✨'**
  String get endOfFeed;

  /// No description provided for @readingTime.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 min read} other{{minutes} min read}}'**
  String readingTime(int minutes);

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String byAuthor(String name);

  /// No description provided for @badgeReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get badgeReviewed;

  /// No description provided for @reviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by {name}'**
  String reviewedBy(String name);

  /// No description provided for @lastReviewed.
  ///
  /// In en, this message translates to:
  /// **'Last reviewed: {date}'**
  String lastReviewed(String date);

  /// No description provided for @aiAssisted.
  ///
  /// In en, this message translates to:
  /// **'AI-assisted'**
  String get aiAssisted;

  /// No description provided for @verifiedWriter.
  ///
  /// In en, this message translates to:
  /// **'Verified writer'**
  String get verifiedWriter;

  /// No description provided for @tldr.
  ///
  /// In en, this message translates to:
  /// **'TL;DR'**
  String get tldr;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @fontSizeS.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSizeS;

  /// No description provided for @fontSizeM.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontSizeM;

  /// No description provided for @fontSizeL.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeL;

  /// No description provided for @fontSizeXl.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get fontSizeXl;

  /// No description provided for @articleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Article language'**
  String get articleLanguage;

  /// No description provided for @langToggleArEg.
  ///
  /// In en, this message translates to:
  /// **'Arabic+EN'**
  String get langToggleArEg;

  /// No description provided for @langToggleEn.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get langToggleEn;

  /// No description provided for @articleLangArEg.
  ///
  /// In en, this message translates to:
  /// **'Egyptian Arabic + English terms'**
  String get articleLangArEg;

  /// No description provided for @articleLangEn.
  ///
  /// In en, this message translates to:
  /// **'English only'**
  String get articleLangEn;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @glossary.
  ///
  /// In en, this message translates to:
  /// **'Glossary'**
  String get glossary;

  /// No description provided for @glossaryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Full definitions for “{term}” are coming soon to the glossary.'**
  String glossaryComingSoon(String term);

  /// No description provided for @readingProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading progress'**
  String get readingProgress;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// No description provided for @embedOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {provider}'**
  String embedOpen(String provider);

  /// No description provided for @imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get imageUnavailable;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'One article a day that makes a difference'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Short, reviewed articles in Arabic and English — one picked for you every day, in the field you love.'**
  String get onboardingWelcomeBody;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @browseAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browse as a guest'**
  String get browseAsGuest;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @interestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Which fields do you love?'**
  String get interestsTitle;

  /// No description provided for @interestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick at least 3 so we can tailor your daily article.'**
  String get interestsSubtitle;

  /// No description provided for @interestsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing selected yet} =1{1 selected} other{{count} selected}}'**
  String interestsSelected(int count);

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your preferences'**
  String get preferencesTitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change these anytime from settings.'**
  String get preferencesSubtitle;

  /// No description provided for @articleLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Article language'**
  String get articleLanguageLabel;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get reminderTimeLabel;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily article notification'**
  String get notificationsLabel;

  /// No description provided for @notificationsHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll ask for permission when notifications launch.'**
  String get notificationsHint;

  /// No description provided for @finishOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get finishOnboarding;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get displayName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get resetPasswordBody;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox for a reset link.'**
  String get resetPasswordSent;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @socialSignInSoon.
  ///
  /// In en, this message translates to:
  /// **'Google and Apple sign-in are coming soon.'**
  String get socialSignInSoon;

  /// No description provided for @verifyEmailSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification email to {email}.'**
  String verifyEmailSent(String email);

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Join ReadIn'**
  String get signUpTitle;

  /// No description provided for @signInPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInPromptTitle;

  /// No description provided for @signInPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to save articles, follow writers and keep your streak.'**
  String get signInPromptBody;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 2 characters'**
  String get nameTooShort;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @uiLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get uiLanguage;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @guestMode.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing as a guest'**
  String get guestMode;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @profileGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your ReadIn profile'**
  String get profileGuestTitle;

  /// No description provided for @profileGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to build your reading streak and share what you know.'**
  String get profileGuestBody;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @profileSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your profile.'**
  String get profileSyncFailed;

  /// No description provided for @errValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get errValidation;

  /// No description provided for @errUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errUnauthorized;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get errForbidden;

  /// No description provided for @errSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended.'**
  String get errSuspended;

  /// No description provided for @errNotSynced.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t set up your account. Try again.'**
  String get errNotSynced;

  /// No description provided for @errUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get errUserNotFound;

  /// No description provided for @errUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is taken.'**
  String get errUsernameTaken;

  /// No description provided for @errInterestsMinThree.
  ///
  /// In en, this message translates to:
  /// **'Pick at least 3 interests.'**
  String get errInterestsMinThree;

  /// No description provided for @errFieldNotFound.
  ///
  /// In en, this message translates to:
  /// **'This field doesn\'t exist.'**
  String get errFieldNotFound;

  /// No description provided for @errArticleNotFound.
  ///
  /// In en, this message translates to:
  /// **'This article doesn\'t exist or was removed.'**
  String get errArticleNotFound;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Try again.'**
  String get errServer;

  /// No description provided for @errOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection.'**
  String get errOffline;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection timed out. Try again.'**
  String get errTimeout;

  /// No description provided for @errAuthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in isn\'t available right now.'**
  String get errAuthUnavailable;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account.'**
  String get errEmailInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get errWeakPassword;

  /// No description provided for @errInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'This email looks invalid.'**
  String get errInvalidEmail;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get errTooManyRequests;

  /// No description provided for @errCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get errCancelled;

  /// No description provided for @errSourcesRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one source before publishing.'**
  String get errSourcesRequired;

  /// No description provided for @errMediaPurposeInvalid.
  ///
  /// In en, this message translates to:
  /// **'This kind of upload isn\'t supported.'**
  String get errMediaPurposeInvalid;

  /// No description provided for @errMediaFileRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a file first.'**
  String get errMediaFileRequired;

  /// No description provided for @errMediaTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large (PDF up to 20 MB, images up to 10 MB).'**
  String get errMediaTooLarge;

  /// No description provided for @errMediaUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'This file type isn\'t supported. Use JPEG, PNG, WebP, HEIC or PDF.'**
  String get errMediaUnsupportedType;

  /// No description provided for @errMediaDimensionsTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This image is too big (up to 8000 × 8000 pixels).'**
  String get errMediaDimensionsTooLarge;

  /// No description provided for @errMediaImageCorrupted.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read this image. Try another one.'**
  String get errMediaImageCorrupted;

  /// No description provided for @errMediaPdfEncrypted.
  ///
  /// In en, this message translates to:
  /// **'This PDF is password-protected. Upload it without a password.'**
  String get errMediaPdfEncrypted;

  /// No description provided for @errMediaPdfCorrupted.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read this PDF. It may be damaged.'**
  String get errMediaPdfCorrupted;

  /// No description provided for @errMediaPdfTooManyPages.
  ///
  /// In en, this message translates to:
  /// **'This PDF has more than 100 pages.'**
  String get errMediaPdfTooManyPages;

  /// No description provided for @errMediaQuotaDaily.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s upload limit (50 files). Try again tomorrow.'**
  String get errMediaQuotaDaily;

  /// No description provided for @errMediaQuotaStorage.
  ///
  /// In en, this message translates to:
  /// **'Your storage is full (200 MB). Remove old files to upload more.'**
  String get errMediaQuotaStorage;

  /// No description provided for @errMediaNotFound.
  ///
  /// In en, this message translates to:
  /// **'This file doesn\'t exist anymore.'**
  String get errMediaNotFound;

  /// No description provided for @errMediaInUse.
  ///
  /// In en, this message translates to:
  /// **'This file is attached to a post.'**
  String get errMediaInUse;

  /// No description provided for @errMediaDownloadNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'The author didn\'t allow downloading this file.'**
  String get errMediaDownloadNotAllowed;

  /// No description provided for @errMediaProcessingFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t prepare this file. Remove it or try again.'**
  String get errMediaProcessingFailed;

  /// No description provided for @errMediaProcessingTimeout.
  ///
  /// In en, this message translates to:
  /// **'Preparing this file took too long. Try again.'**
  String get errMediaProcessingTimeout;

  /// No description provided for @errAttachmentsMixedKinds.
  ///
  /// In en, this message translates to:
  /// **'A post can have images or one PDF, not both.'**
  String get errAttachmentsMixedKinds;

  /// No description provided for @errAttachmentsTooManyImages.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to 10 images.'**
  String get errAttachmentsTooManyImages;

  /// No description provided for @errAttachmentsSingleDocument.
  ///
  /// In en, this message translates to:
  /// **'You can attach only one PDF.'**
  String get errAttachmentsSingleDocument;

  /// No description provided for @errAttachmentsAltTextRequired.
  ///
  /// In en, this message translates to:
  /// **'Every image needs alt text.'**
  String get errAttachmentsAltTextRequired;

  /// No description provided for @errAttachmentsAltTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'Alt text can be up to 5000 characters.'**
  String get errAttachmentsAltTextTooLong;

  /// No description provided for @errAttachmentsCaptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Captions can be up to 5000 characters.'**
  String get errAttachmentsCaptionTooLong;

  /// No description provided for @errAttachmentsTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'The document title can be up to 5000 characters.'**
  String get errAttachmentsTitleTooLong;

  /// No description provided for @errAttachmentsTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'The document needs a title.'**
  String get errAttachmentsTitleRequired;

  /// No description provided for @errAttachmentsAssetNotFound.
  ///
  /// In en, this message translates to:
  /// **'An attachment is missing. Remove it and upload it again.'**
  String get errAttachmentsAssetNotFound;

  /// No description provided for @errAttachmentsAssetNotReady.
  ///
  /// In en, this message translates to:
  /// **'An attachment is still being prepared. Wait a moment.'**
  String get errAttachmentsAssetNotReady;

  /// No description provided for @errAttachmentsDuplicateAsset.
  ///
  /// In en, this message translates to:
  /// **'The same file is attached twice.'**
  String get errAttachmentsDuplicateAsset;

  /// No description provided for @composerTitle.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get composerTitle;

  /// No description provided for @composerField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get composerField;

  /// No description provided for @composerFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a field'**
  String get composerFieldHint;

  /// No description provided for @composerTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get composerTitleLabel;

  /// No description provided for @composerTitleHint.
  ///
  /// In en, this message translates to:
  /// **'A clear title, 5 to 150 characters'**
  String get composerTitleHint;

  /// No description provided for @composerBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Your post'**
  String get composerBodyLabel;

  /// No description provided for @composerBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Leave an empty line between paragraphs.'**
  String get composerBodyHint;

  /// No description provided for @composerSourcesRequired.
  ///
  /// In en, this message translates to:
  /// **'This field needs at least one source.'**
  String get composerSourcesRequired;

  /// No description provided for @composerSourcesOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional, but readers trust posts with sources.'**
  String get composerSourcesOptional;

  /// No description provided for @composerAddSource.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get composerAddSource;

  /// No description provided for @composerAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get composerAttachments;

  /// No description provided for @composerSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Source title'**
  String get composerSourceTitle;

  /// No description provided for @composerSourceUrl.
  ///
  /// In en, this message translates to:
  /// **'Link (https://…)'**
  String get composerSourceUrl;

  /// No description provided for @composerRemoveSource.
  ///
  /// In en, this message translates to:
  /// **'Remove source'**
  String get composerRemoveSource;

  /// No description provided for @composerInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http(s) link'**
  String get composerInvalidUrl;

  /// No description provided for @composerPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get composerPublish;

  /// No description provided for @composerPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get composerPublishing;

  /// No description provided for @composerPublished.
  ///
  /// In en, this message translates to:
  /// **'Published ✨'**
  String get composerPublished;

  /// No description provided for @composerNeedField.
  ///
  /// In en, this message translates to:
  /// **'Pick a field.'**
  String get composerNeedField;

  /// No description provided for @composerNeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Write a title (5 to 150 characters).'**
  String get composerNeedTitle;

  /// No description provided for @composerNeedBody.
  ///
  /// In en, this message translates to:
  /// **'Write something or add an attachment.'**
  String get composerNeedBody;

  /// No description provided for @composerNeedSources.
  ///
  /// In en, this message translates to:
  /// **'Add at least one source.'**
  String get composerNeedSources;

  /// No description provided for @composerFixSources.
  ///
  /// In en, this message translates to:
  /// **'Complete or remove the unfinished sources.'**
  String get composerFixSources;

  /// No description provided for @attachImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get attachImages;

  /// No description provided for @attachPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF document'**
  String get attachPdf;

  /// No description provided for @attachMixHint.
  ///
  /// In en, this message translates to:
  /// **'A post can have images or one PDF, not both.'**
  String get attachMixHint;

  /// No description provided for @attachImagesLimit.
  ///
  /// In en, this message translates to:
  /// **'{count} of 10 images'**
  String attachImagesLimit(int count);

  /// No description provided for @attachReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press and drag to reorder. Tap an image to add alt text.'**
  String get attachReorderHint;

  /// No description provided for @attachNeedAlt.
  ///
  /// In en, this message translates to:
  /// **'Add alt text to every image.'**
  String get attachNeedAlt;

  /// No description provided for @attachBusy.
  ///
  /// In en, this message translates to:
  /// **'Wait until uploads and processing finish.'**
  String get attachBusy;

  /// No description provided for @attachFailed.
  ///
  /// In en, this message translates to:
  /// **'Remove or retry the failed attachments.'**
  String get attachFailed;

  /// No description provided for @attachNeedDocTitle.
  ///
  /// In en, this message translates to:
  /// **'Give the document a title.'**
  String get attachNeedDocTitle;

  /// No description provided for @altTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Alt text (required)'**
  String get altTextLabel;

  /// No description provided for @altTextHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the image for people using a screen reader'**
  String get altTextHint;

  /// No description provided for @altTextMissing.
  ///
  /// In en, this message translates to:
  /// **'Alt text needed'**
  String get altTextMissing;

  /// No description provided for @altTextAdded.
  ///
  /// In en, this message translates to:
  /// **'ALT ✓'**
  String get altTextAdded;

  /// No description provided for @altTextBadgeMissing.
  ///
  /// In en, this message translates to:
  /// **'Add ALT'**
  String get altTextBadgeMissing;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @captionLabel.
  ///
  /// In en, this message translates to:
  /// **'Caption (optional)'**
  String get captionLabel;

  /// No description provided for @imageDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Image {index} of {total}'**
  String imageDetailsTitle(int index, int total);

  /// No description provided for @editImageDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit alt text and caption'**
  String get editImageDetails;

  /// No description provided for @moveEarlier.
  ///
  /// In en, this message translates to:
  /// **'Move earlier'**
  String get moveEarlier;

  /// No description provided for @moveLater.
  ///
  /// In en, this message translates to:
  /// **'Move later'**
  String get moveLater;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAttachment;

  /// No description provided for @cancelUpload.
  ///
  /// In en, this message translates to:
  /// **'Cancel upload'**
  String get cancelUpload;

  /// No description provided for @uploadPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get uploadPreparing;

  /// No description provided for @uploadProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String uploadProgress(int percent);

  /// No description provided for @uploadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Upload cancelled'**
  String get uploadCancelled;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @fileSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String fileSizeMb(String size);

  /// No description provided for @fileSizeKb.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String fileSizeKb(String size);

  /// No description provided for @pdfTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Document title (required)'**
  String get pdfTitleLabel;

  /// No description provided for @pdfAllowDownload.
  ///
  /// In en, this message translates to:
  /// **'Allow download'**
  String get pdfAllowDownload;

  /// No description provided for @pdfAllowDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'Readers can download the original PDF.'**
  String get pdfAllowDownloadHint;

  /// No description provided for @pdfPreparingPages.
  ///
  /// In en, this message translates to:
  /// **'Preparing pages…'**
  String get pdfPreparingPages;

  /// No description provided for @pdfPagesReady.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total} pages ready'**
  String pdfPagesReady(int ready, int total);

  /// No description provided for @pdfPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pdfPageCount(int count);

  /// No description provided for @pdfMorePages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+1 page, open document} other{+{count} pages, open document}}'**
  String pdfMorePages(int count);

  /// No description provided for @openDocument.
  ///
  /// In en, this message translates to:
  /// **'Open document'**
  String get openDocument;

  /// No description provided for @viewerDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get viewerDownload;

  /// No description provided for @viewerDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get viewerDownloading;

  /// No description provided for @viewerImageOf.
  ///
  /// In en, this message translates to:
  /// **'Image {index} of {total}'**
  String viewerImageOf(int index, int total);

  /// No description provided for @viewerPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {index} of {total}'**
  String viewerPageOf(int index, int total);

  /// No description provided for @viewerZoomHint.
  ///
  /// In en, this message translates to:
  /// **'Double-tap to zoom'**
  String get viewerZoomHint;

  /// No description provided for @viewerPageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading page…'**
  String get viewerPageLoading;

  /// No description provided for @viewerThumbnails.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get viewerThumbnails;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
