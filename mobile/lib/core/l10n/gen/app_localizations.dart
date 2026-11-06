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
  /// **'Home'**
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

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @moreDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get moreDarkMode;

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
  /// **'{count, plural, =1{Reading streak: 1 day} other{Reading streak: {count} days}}'**
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

  /// No description provided for @feedNewArticles.
  ///
  /// In en, this message translates to:
  /// **'New articles ↑'**
  String get feedNewArticles;

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

  /// No description provided for @deletedUser.
  ///
  /// In en, this message translates to:
  /// **'Deleted user'**
  String get deletedUser;

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

  /// No description provided for @langToggleArEg.
  ///
  /// In en, this message translates to:
  /// **'العربية + EN'**
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

  /// No description provided for @glossaryInEnglish.
  ///
  /// In en, this message translates to:
  /// **'In English'**
  String get glossaryInEnglish;

  /// No description provided for @glossaryInArabic.
  ///
  /// In en, this message translates to:
  /// **'In Arabic'**
  String get glossaryInArabic;

  /// No description provided for @glossaryArticles.
  ///
  /// In en, this message translates to:
  /// **'Articles that use this term'**
  String get glossaryArticles;

  /// No description provided for @glossaryNotFound.
  ///
  /// In en, this message translates to:
  /// **'This term isn\'t in the glossary yet'**
  String get glossaryNotFound;

  /// No description provided for @relatedArticles.
  ///
  /// In en, this message translates to:
  /// **'Related articles'**
  String get relatedArticles;

  /// No description provided for @resumePickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up where you left off'**
  String get resumePickedUp;

  /// No description provided for @resumeStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get resumeStartOver;

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

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Short articles in Arabic and English — one picked for you every day, in the field you love.'**
  String get onboardingWelcomeBody;

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
  /// **'We\'ll ask for permission when you turn it on.'**
  String get notificationsHint;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for ReadIn in your phone\'s settings.'**
  String get notificationsBlocked;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} new'**
  String notificationsUnread(int count);

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

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInTitle;

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

  /// No description provided for @profileTabArticles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get profileTabArticles;

  /// No description provided for @profileTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileTabSaved;

  /// No description provided for @profileTabPaths.
  ///
  /// In en, this message translates to:
  /// **'Paths'**
  String get profileTabPaths;

  /// No description provided for @profileTabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileTabAbout;

  /// No description provided for @profileStatArticles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get profileStatArticles;

  /// No description provided for @profileStatFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileStatFollowers;

  /// No description provided for @profileStatFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileStatFollowing;

  /// No description provided for @profileStatReads.
  ///
  /// In en, this message translates to:
  /// **'Reads'**
  String get profileStatReads;

  /// No description provided for @profileStatSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String profileStatSemantics(String label, String value);

  /// No description provided for @profileOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the profile'**
  String get profileOpenHint;

  /// No description provided for @profileOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String profileOpenLink(String name);

  /// No description provided for @profileGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get profileGithub;

  /// No description provided for @profileLinkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get profileLinkedin;

  /// No description provided for @profileWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get profileWebsite;

  /// No description provided for @profileLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get profileLinks;

  /// No description provided for @profileExpertise.
  ///
  /// In en, this message translates to:
  /// **'Fields of expertise'**
  String get profileExpertise;

  /// No description provided for @profileAboutBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileAboutBio;

  /// No description provided for @profileAboutEmpty.
  ///
  /// In en, this message translates to:
  /// **'No details yet.'**
  String get profileAboutEmpty;

  /// No description provided for @profileAboutEmptyOwn.
  ///
  /// In en, this message translates to:
  /// **'Add a bio, your links and the fields you write about so readers get to know you.'**
  String get profileAboutEmptyOwn;

  /// No description provided for @profileJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String profileJoined(String date);

  /// No description provided for @profileArticlesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles yet'**
  String get profileArticlesEmptyTitle;

  /// No description provided for @profileArticlesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The articles they publish show up here.'**
  String get profileArticlesEmptyBody;

  /// No description provided for @profileArticlesEmptyOwnTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t published yet'**
  String get profileArticlesEmptyOwnTitle;

  /// No description provided for @profileArticlesEmptyOwnBody.
  ///
  /// In en, this message translates to:
  /// **'Share what you know: your published articles show up here.'**
  String get profileArticlesEmptyOwnBody;

  /// No description provided for @profileWriteFirst.
  ///
  /// In en, this message translates to:
  /// **'Write an article'**
  String get profileWriteFirst;

  /// No description provided for @profilePathsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No paths yet'**
  String get profilePathsEmptyTitle;

  /// No description provided for @profilePathsEmptyOwnBody.
  ///
  /// In en, this message translates to:
  /// **'Join a learning path and your progress shows up here.'**
  String get profilePathsEmptyOwnBody;

  /// No description provided for @profilePathsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The learning paths they join show up here.'**
  String get profilePathsEmptyBody;

  /// No description provided for @profilePathsPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning paths are private'**
  String get profilePathsPrivateTitle;

  /// No description provided for @profilePathsPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'This reader keeps their reading activity private.'**
  String get profilePathsPrivateBody;

  /// No description provided for @profileNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This profile isn\'t available'**
  String get profileNotFoundTitle;

  /// No description provided for @profileNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The account may have been deleted, or the link is wrong.'**
  String get profileNotFoundBody;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get profilePrivacy;

  /// No description provided for @profilePublicReadingStats.
  ///
  /// In en, this message translates to:
  /// **'Show reading stats on my public profile'**
  String get profilePublicReadingStats;

  /// No description provided for @profilePublicReadingStatsOn.
  ///
  /// In en, this message translates to:
  /// **'Everyone can see your streak, your totals and your reading activity.'**
  String get profilePublicReadingStatsOn;

  /// No description provided for @profilePublicReadingStatsOff.
  ///
  /// In en, this message translates to:
  /// **'Only you can see your reading stats.'**
  String get profilePublicReadingStatsOff;

  /// No description provided for @profileWhoCanMention.
  ///
  /// In en, this message translates to:
  /// **'Who can mention me'**
  String get profileWhoCanMention;

  /// No description provided for @profileWhoCanMentionEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get profileWhoCanMentionEveryone;

  /// No description provided for @profileWhoCanMentionFollowing.
  ///
  /// In en, this message translates to:
  /// **'People I follow'**
  String get profileWhoCanMentionFollowing;

  /// No description provided for @profileWhoCanMentionNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get profileWhoCanMentionNobody;

  /// No description provided for @profileReadingStatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No finished articles yet.'**
  String get profileReadingStatsEmpty;

  /// No description provided for @profileReadingHeatmapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reading days yet.'**
  String get profileReadingHeatmapEmpty;

  /// No description provided for @profileBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBioLabel;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'What do you work on? What do you write about?'**
  String get profileBioHint;

  /// No description provided for @profilePhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from your photos'**
  String get profilePhotoGallery;

  /// No description provided for @profilePhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profilePhotoCamera;

  /// No description provided for @profilePhotoPreview.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhotoPreview;

  /// No description provided for @profileExpertiseHint.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 5 fields you know well.'**
  String get profileExpertiseHint;

  /// No description provided for @profileExpertiseFull.
  ///
  /// In en, this message translates to:
  /// **'That\'s 5. Remove one to pick another.'**
  String get profileExpertiseFull;

  /// No description provided for @profileExpertiseCountSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} fields picked'**
  String profileExpertiseCountSemantics(int count, int max);

  /// No description provided for @profileFollowSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or username'**
  String get profileFollowSearchHint;

  /// No description provided for @profileFollowNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No one matches'**
  String get profileFollowNoResultsTitle;

  /// No description provided for @profileFollowNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try another name or username.'**
  String get profileFollowNoResultsBody;

  /// No description provided for @profileFollowersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get profileFollowersEmptyTitle;

  /// No description provided for @profileFollowersEmptyOwnBody.
  ///
  /// In en, this message translates to:
  /// **'Readers who like your articles can follow you.'**
  String get profileFollowersEmptyOwnBody;

  /// No description provided for @profileFollowingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Not following anyone yet'**
  String get profileFollowingEmptyTitle;

  /// No description provided for @profileFollowingEmptyOwnBody.
  ///
  /// In en, this message translates to:
  /// **'Follow writers to get their new articles on Today.'**
  String get profileFollowingEmptyOwnBody;

  /// No description provided for @profileErrStatsPrivate.
  ///
  /// In en, this message translates to:
  /// **'These reading stats are private.'**
  String get profileErrStatsPrivate;

  /// No description provided for @profileErrAvatarInvalid.
  ///
  /// In en, this message translates to:
  /// **'This photo can\'t be used. Upload another one.'**
  String get profileErrAvatarInvalid;

  /// No description provided for @profileErrExpertiseInvalid.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 5 of the listed fields.'**
  String get profileErrExpertiseInvalid;

  /// No description provided for @profileErrUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a full link that starts with https://'**
  String get profileErrUrl;

  /// No description provided for @profileHeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get profileHeadlineLabel;

  /// No description provided for @profileHeadlineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Senior Full Stack .NET Engineer | .NET'**
  String get profileHeadlineHint;

  /// No description provided for @profileHeadlineHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. One line that shows under your name.'**
  String get profileHeadlineHelper;

  /// No description provided for @profileLinksSection.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get profileLinksSection;

  /// No description provided for @profileLinksHint.
  ///
  /// In en, this message translates to:
  /// **'Add up to 8 links to your accounts.'**
  String get profileLinksHint;

  /// No description provided for @profileLinksFull.
  ///
  /// In en, this message translates to:
  /// **'That\'s 8 links. Remove one to add another.'**
  String get profileLinksFull;

  /// No description provided for @profileLinksCountSemantics.
  ///
  /// In en, this message translates to:
  /// **'Links: {count} of {max}'**
  String profileLinksCountSemantics(int count, int max);

  /// No description provided for @profileLinkAdd.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get profileLinkAdd;

  /// No description provided for @profileLinkPickPlatform.
  ///
  /// In en, this message translates to:
  /// **'Choose a platform'**
  String get profileLinkPickPlatform;

  /// No description provided for @profileLinkPlatformAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get profileLinkPlatformAdded;

  /// No description provided for @profileLinkChangePlatform.
  ///
  /// In en, this message translates to:
  /// **'Change platform'**
  String get profileLinkChangePlatform;

  /// No description provided for @profileLinkUrl.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get profileLinkUrl;

  /// No description provided for @profileLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link name'**
  String get profileLinkLabel;

  /// No description provided for @profileLinkLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My podcast'**
  String get profileLinkLabelHint;

  /// No description provided for @profileLinkOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileLinkOther;

  /// No description provided for @profileLinkOptions.
  ///
  /// In en, this message translates to:
  /// **'{name} link options'**
  String profileLinkOptions(String name);

  /// No description provided for @profileLinkMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get profileLinkMoveUp;

  /// No description provided for @profileLinkMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get profileLinkMoveDown;

  /// No description provided for @profileLinkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get profileLinkRemove;

  /// No description provided for @profileTabReposts.
  ///
  /// In en, this message translates to:
  /// **'Reposts'**
  String get profileTabReposts;

  /// No description provided for @profileRepostsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reposts yet'**
  String get profileRepostsEmptyTitle;

  /// No description provided for @profileRepostsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The articles they repost show up here.'**
  String get profileRepostsEmptyBody;

  /// No description provided for @profileRepostsEmptyOwnTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t reposted anything yet'**
  String get profileRepostsEmptyOwnTitle;

  /// No description provided for @profileRepostsEmptyOwnBody.
  ///
  /// In en, this message translates to:
  /// **'When you repost an article you like, it shows up here and for your followers.'**
  String get profileRepostsEmptyOwnBody;

  /// No description provided for @profileErrHeadlineTooLong.
  ///
  /// In en, this message translates to:
  /// **'A title has at most 120 characters.'**
  String get profileErrHeadlineTooLong;

  /// No description provided for @profileErrHeadlineInvalid.
  ///
  /// In en, this message translates to:
  /// **'A title must be one line, without special characters.'**
  String get profileErrHeadlineInvalid;

  /// No description provided for @profileErrLinkTooMany.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 8 links.'**
  String get profileErrLinkTooMany;

  /// No description provided for @profileErrLinkPlatformInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a platform from the list.'**
  String get profileErrLinkPlatformInvalid;

  /// No description provided for @profileErrLinkDuplicatePlatform.
  ///
  /// In en, this message translates to:
  /// **'You already have a link for this platform.'**
  String get profileErrLinkDuplicatePlatform;

  /// No description provided for @profileErrLinkTooLong.
  ///
  /// In en, this message translates to:
  /// **'A link has at most 500 characters.'**
  String get profileErrLinkTooLong;

  /// No description provided for @profileErrLinkHttpsRequired.
  ///
  /// In en, this message translates to:
  /// **'The link must start with https.'**
  String get profileErrLinkHttpsRequired;

  /// No description provided for @profileErrLinkUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'This link isn\'t valid.'**
  String get profileErrLinkUrlInvalid;

  /// No description provided for @profileErrLinkHostMismatch.
  ///
  /// In en, this message translates to:
  /// **'This link isn\'t on the platform you chose.'**
  String get profileErrLinkHostMismatch;

  /// No description provided for @profileErrLinkLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Give this link a name.'**
  String get profileErrLinkLabelRequired;

  /// No description provided for @profileErrLinkLabelInvalid.
  ///
  /// In en, this message translates to:
  /// **'A link name has 2–30 characters on one line.'**
  String get profileErrLinkLabelInvalid;

  /// No description provided for @profileErrLinkLabelNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only \"Other\" links have a name.'**
  String get profileErrLinkLabelNotAllowed;

  /// No description provided for @moderationUserLinks.
  ///
  /// In en, this message translates to:
  /// **'Profile links'**
  String get moderationUserLinks;

  /// No description provided for @moderationUserNoLinks.
  ///
  /// In en, this message translates to:
  /// **'No links.'**
  String get moderationUserNoLinks;

  /// No description provided for @moderationUserHeadline.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get moderationUserHeadline;

  /// No description provided for @moderationUserNoHeadline.
  ///
  /// In en, this message translates to:
  /// **'No title.'**
  String get moderationUserNoHeadline;

  /// No description provided for @moderationClearLinks.
  ///
  /// In en, this message translates to:
  /// **'Clear links'**
  String get moderationClearLinks;

  /// No description provided for @moderationClearLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all of {name}\'s links?'**
  String moderationClearLinksTitle(String name);

  /// No description provided for @moderationClearLinksBody.
  ///
  /// In en, this message translates to:
  /// **'Every link on their profile is removed. They aren\'t notified, and the action is logged.'**
  String get moderationClearLinksBody;

  /// No description provided for @moderationLinksCleared.
  ///
  /// In en, this message translates to:
  /// **'Links cleared'**
  String get moderationLinksCleared;

  /// No description provided for @moderationClearHeadline.
  ///
  /// In en, this message translates to:
  /// **'Clear title'**
  String get moderationClearHeadline;

  /// No description provided for @moderationClearHeadlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear {name}\'s title?'**
  String moderationClearHeadlineTitle(String name);

  /// No description provided for @moderationClearHeadlineBody.
  ///
  /// In en, this message translates to:
  /// **'The title under their name is removed from the profile, cards and comments. They aren\'t notified, and the action is logged.'**
  String get moderationClearHeadlineBody;

  /// No description provided for @moderationHeadlineCleared.
  ///
  /// In en, this message translates to:
  /// **'Title cleared'**
  String get moderationHeadlineCleared;

  /// No description provided for @moderationLogUserClearLinks.
  ///
  /// In en, this message translates to:
  /// **'Cleared links'**
  String get moderationLogUserClearLinks;

  /// No description provided for @moderationLogUserClearHeadline.
  ///
  /// In en, this message translates to:
  /// **'Cleared a title'**
  String get moderationLogUserClearHeadline;

  /// No description provided for @notifArticleReposted.
  ///
  /// In en, this message translates to:
  /// **'{others, plural, =0{{name} reposted your article} =1{{name} and 1 other reposted your article} other{{name} and {others} others reposted your article}}'**
  String notifArticleReposted(String name, int others);

  /// No description provided for @notificationTypeArticleReposted.
  ///
  /// In en, this message translates to:
  /// **'Reposts'**
  String get notificationTypeArticleReposted;

  /// No description provided for @notificationTypeArticleRepostedHint.
  ///
  /// In en, this message translates to:
  /// **'When someone reposts your article'**
  String get notificationTypeArticleRepostedHint;

  /// No description provided for @pdfStripDownload.
  ///
  /// In en, this message translates to:
  /// **'Download the PDF'**
  String get pdfStripDownload;

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
  /// **'This account is suspended. Contact support.'**
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

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The phone number or password is incorrect.'**
  String get errInvalidCredentials;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again shortly.'**
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

  /// No description provided for @welcomeSignIn.
  ///
  /// In en, this message translates to:
  /// **'I have an account, sign in'**
  String get welcomeSignIn;

  /// No description provided for @switchLanguageTo.
  ///
  /// In en, this message translates to:
  /// **'Switch the app language to {language}'**
  String switchLanguageTo(String language);

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your mobile number and password.'**
  String get signInSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// No description provided for @createAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createAccountLink;

  /// No description provided for @passwordResetBanner.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Sign in with your new password.'**
  String get passwordResetBanner;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Sign in again.'**
  String get sessionExpired;

  /// No description provided for @signUpHeading.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpHeading;

  /// No description provided for @signUpCredentialsBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll sign in with this number and password. We never send SMS codes.'**
  String get signUpCredentialsBody;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @ruleMinLength.
  ///
  /// In en, this message translates to:
  /// **'{count}+ characters'**
  String ruleMinLength(int count);

  /// No description provided for @ruleLetter.
  ///
  /// In en, this message translates to:
  /// **'A letter'**
  String get ruleLetter;

  /// No description provided for @ruleDigit.
  ///
  /// In en, this message translates to:
  /// **'A digit'**
  String get ruleDigit;

  /// No description provided for @ruleMet.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get ruleMet;

  /// No description provided for @ruleNotMet.
  ///
  /// In en, this message translates to:
  /// **'not yet'**
  String get ruleNotMet;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength: {level}'**
  String passwordStrength(String level);

  /// No description provided for @strengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get strengthWeak;

  /// No description provided for @strengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get strengthFair;

  /// No description provided for @strengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get strengthGood;

  /// No description provided for @strengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strengthStrong;

  /// No description provided for @pinStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an emergency PIN'**
  String get pinStepTitle;

  /// No description provided for @pinStepBody.
  ///
  /// In en, this message translates to:
  /// **'If you ever forget your password, your number and this PIN let you choose a new one. Keep it somewhere safe and don\'t share it.'**
  String get pinStepBody;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery PIN'**
  String get pinLabel;

  /// No description provided for @confirmPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPinLabel;

  /// No description provided for @newPinLabel.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPinLabel;

  /// No description provided for @showPin.
  ///
  /// In en, this message translates to:
  /// **'Show PIN'**
  String get showPin;

  /// No description provided for @hidePin.
  ///
  /// In en, this message translates to:
  /// **'Hide PIN'**
  String get hidePin;

  /// No description provided for @pinSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}, {filled} of {total} digits entered'**
  String pinSemantics(String label, int filled, int total);

  /// No description provided for @confirmNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Is this your number?'**
  String get confirmNumberTitle;

  /// No description provided for @confirmNumberWarning.
  ///
  /// In en, this message translates to:
  /// **'You\'ll use this number to sign in, and you can\'t recover your account if the number is wrong.'**
  String get confirmNumberWarning;

  /// No description provided for @confirmNumberYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, create my account'**
  String get confirmNumberYes;

  /// No description provided for @confirmNumberChangeYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, change my number'**
  String get confirmNumberChangeYes;

  /// No description provided for @confirmNumberAddYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, add this number'**
  String get confirmNumberAddYes;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileBody.
  ///
  /// In en, this message translates to:
  /// **'This is how readers and writers will see you.'**
  String get completeProfileBody;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'3–30 characters: a–z, 0–9 or _'**
  String get usernameHint;

  /// No description provided for @usernameChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get usernameChecking;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'@{username} is available'**
  String usernameAvailable(String username);

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @photoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get photoUploading;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get saveAndContinue;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// No description provided for @forgotStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Enter your number and the recovery PIN you created when you signed up.'**
  String get forgotStep1Body;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot the PIN too?'**
  String get forgotPin;

  /// No description provided for @forgotStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get forgotStep2Title;

  /// No description provided for @forgotStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Every device signed in to your account will be signed out.'**
  String get forgotStep2Body;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get supportTitle;

  /// No description provided for @supportBody.
  ///
  /// In en, this message translates to:
  /// **'Without your PIN, only our support team can reset your password, after checking that the account is really yours. Email us from your account\'s number details; after the reset you\'ll choose a new password and a new PIN when you sign in.'**
  String get supportBody;

  /// No description provided for @supportEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get supportEmailAction;

  /// No description provided for @copyEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy email address'**
  String get copyEmail;

  /// No description provided for @setPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your recovery PIN'**
  String get setPinTitle;

  /// No description provided for @setPinBody.
  ///
  /// In en, this message translates to:
  /// **'Your account needs a recovery PIN. With your number, it lets you choose a new password if you ever forget yours.'**
  String get setPinBody;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @mustChangePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Your password was reset. Choose a new one to continue.'**
  String get mustChangePasswordBody;

  /// No description provided for @changePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Your other devices will be signed out.'**
  String get changePasswordBody;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordChanged;

  /// No description provided for @changePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePinTitle;

  /// No description provided for @changePinBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your password, then choose the new PIN.'**
  String get changePinBody;

  /// No description provided for @pinChanged.
  ///
  /// In en, this message translates to:
  /// **'Recovery PIN changed.'**
  String get pinChanged;

  /// No description provided for @changePhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changePhoneTitle;

  /// No description provided for @changePhoneBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll sign in with the new number. Your other devices will be signed out.'**
  String get changePhoneBody;

  /// No description provided for @newPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'New mobile number'**
  String get newPhoneLabel;

  /// No description provided for @phoneChanged.
  ///
  /// In en, this message translates to:
  /// **'Number changed.'**
  String get phoneChanged;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneVisibleToYou.
  ///
  /// In en, this message translates to:
  /// **'Only you can see it'**
  String get phoneVisibleToYou;

  /// No description provided for @changePhone.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changePhone;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @signOutEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices'**
  String get signOutEverywhere;

  /// No description provided for @signOutEverywhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices?'**
  String get signOutEverywhereTitle;

  /// No description provided for @signOutEverywhereConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices'**
  String get signOutEverywhereConfirm;

  /// No description provided for @signOutEverywhereBody.
  ///
  /// In en, this message translates to:
  /// **'Every other device will be signed out. You stay signed in on this one.'**
  String get signOutEverywhereBody;

  /// No description provided for @signedOutEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Signed out of all other devices.'**
  String get signedOutEverywhere;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountLead.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your ReadIn account. You can\'t undo it, and we can\'t restore it.'**
  String get deleteAccountLead;

  /// No description provided for @deleteAccountDeletedHeading.
  ///
  /// In en, this message translates to:
  /// **'We delete right away'**
  String get deleteAccountDeletedHeading;

  /// No description provided for @deleteAccountDeletedProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile: name, @username, photo, title, bio and links'**
  String get deleteAccountDeletedProfile;

  /// No description provided for @deleteAccountDeletedContact.
  ///
  /// In en, this message translates to:
  /// **'Your phone number, email, password and recovery PIN'**
  String get deleteAccountDeletedContact;

  /// No description provided for @deleteAccountDeletedSignIns.
  ///
  /// In en, this message translates to:
  /// **'Your Google and Apple sign-in links. We also revoke ReadIn\'s access at Apple.'**
  String get deleteAccountDeletedSignIns;

  /// No description provided for @deleteAccountDeletedDrafts.
  ///
  /// In en, this message translates to:
  /// **'Your drafts and any article that isn\'t published, with their images and PDFs, and every other photo or file you uploaded'**
  String get deleteAccountDeletedDrafts;

  /// No description provided for @deleteAccountDeletedActivity.
  ///
  /// In en, this message translates to:
  /// **'Your interests, reading progress and stats, reactions, reposts, highlights, comment likes and the reports you filed, saved articles and collections, your writer categories (your published articles stay, without a category), the people you follow and your followers, the writers, fields and topics you muted (and other people\'s mutes of you), and your \"Show less like this\" marks'**
  String get deleteAccountDeletedActivity;

  /// No description provided for @deleteAccountDeletedDevices.
  ///
  /// In en, this message translates to:
  /// **'Your devices and notification tokens, so no notification reaches you'**
  String get deleteAccountDeletedDevices;

  /// No description provided for @deleteAccountDeletedSecurityLog.
  ///
  /// In en, this message translates to:
  /// **'Your security log: sign-ins and account changes'**
  String get deleteAccountDeletedSecurityLog;

  /// No description provided for @deleteAccountKeptHeading.
  ///
  /// In en, this message translates to:
  /// **'What we keep, and why'**
  String get deleteAccountKeptHeading;

  /// No description provided for @deleteAccountKeptPublished.
  ///
  /// In en, this message translates to:
  /// **'Your published articles and comments stay up under “Deleted user”, with the images and PDFs they show: no name, @username or photo, and nothing that links them to you. That keeps links and discussions other readers rely on working. To take an article down, delete it before you delete your account.'**
  String get deleteAccountKeptPublished;

  /// No description provided for @deleteAccountKeptRecord.
  ///
  /// In en, this message translates to:
  /// **'A record that this account was deleted: its internal ID and the time, nothing that identifies you. It proves the deletion happened.'**
  String get deleteAccountKeptRecord;

  /// No description provided for @deleteAccountKeptBackups.
  ///
  /// In en, this message translates to:
  /// **'Database backups may still hold your data for up to 14 days, until they\'re overwritten.'**
  String get deleteAccountKeptBackups;

  /// No description provided for @deleteAccountKeptReviews.
  ///
  /// In en, this message translates to:
  /// **'Edits you made on other writers\' articles stay with those articles, without your name.'**
  String get deleteAccountKeptReviews;

  /// No description provided for @deleteAccountAfter.
  ///
  /// In en, this message translates to:
  /// **'Afterwards, this phone number, email, Google or Apple account can create a new ReadIn account, which starts empty.'**
  String get deleteAccountAfter;

  /// No description provided for @deleteAccountByEmail.
  ///
  /// In en, this message translates to:
  /// **'Delete by email instead'**
  String get deleteAccountByEmail;

  /// No description provided for @deleteAccountPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to delete your account.'**
  String get deleteAccountPasswordBody;

  /// No description provided for @deleteAccountProviderBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in again with the account that\'s linked to ReadIn.'**
  String get deleteAccountProviderBody;

  /// No description provided for @confirmWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Confirm with Google'**
  String get confirmWithGoogle;

  /// No description provided for @confirmWithApple.
  ///
  /// In en, this message translates to:
  /// **'Confirm with Apple'**
  String get confirmWithApple;

  /// No description provided for @confirmedWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Confirmed with Google'**
  String get confirmedWithGoogle;

  /// No description provided for @confirmedWithApple.
  ///
  /// In en, this message translates to:
  /// **'Confirmed with Apple'**
  String get confirmedWithApple;

  /// No description provided for @deleteAccountAppleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This account is linked to Apple. Confirm with Apple from the ReadIn iPhone app, or email us to delete it.'**
  String get deleteAccountAppleUnavailable;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'I understand, delete my account'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountButton;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get deletingAccount;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account forever?'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get deleteAccountDialogBody;

  /// No description provided for @deleteAccountDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteAccountDialogConfirm;

  /// No description provided for @deleteAccountOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet to delete your account.'**
  String get deleteAccountOffline;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get accountDeleted;

  /// No description provided for @countryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a country'**
  String get countryPickerTitle;

  /// No description provided for @countrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, code or +dial code'**
  String get countrySearchHint;

  /// No description provided for @countryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No country matches your search'**
  String get countryNoResults;

  /// No description provided for @countryButtonSemantics.
  ///
  /// In en, this message translates to:
  /// **'Country: {country}, +{dialCode}. Double-tap to change'**
  String countryButtonSemantics(String country, String dialCode);

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @devLoginOpen.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts'**
  String get devLoginOpen;

  /// No description provided for @devLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts (dev only)'**
  String get devLoginTitle;

  /// No description provided for @devLoginBody.
  ///
  /// In en, this message translates to:
  /// **'Local seed users (SPEC §18.3). With DEV_DEMO_PASSWORD set, a tap signs in; otherwise it fills the number.'**
  String get devLoginBody;

  /// No description provided for @devLoginHasPin.
  ///
  /// In en, this message translates to:
  /// **'Has a recovery PIN'**
  String get devLoginHasPin;

  /// No description provided for @devLoginNoPin.
  ///
  /// In en, this message translates to:
  /// **'No recovery PIN'**
  String get devLoginNoPin;

  /// No description provided for @devLoginSuspended.
  ///
  /// In en, this message translates to:
  /// **'suspended'**
  String get devLoginSuspended;

  /// No description provided for @errPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number.'**
  String get errPhoneInvalid;

  /// No description provided for @errPhoneTaken.
  ///
  /// In en, this message translates to:
  /// **'This number already has an account.'**
  String get errPhoneTaken;

  /// No description provided for @errPhoneUnchanged.
  ///
  /// In en, this message translates to:
  /// **'This is already your number.'**
  String get errPhoneUnchanged;

  /// No description provided for @errLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in 15 minutes.'**
  String get errLockedOut;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'The current password is incorrect.'**
  String get errWrongPassword;

  /// No description provided for @errRecoveryInvalid.
  ///
  /// In en, this message translates to:
  /// **'The phone number or PIN is incorrect.'**
  String get errRecoveryInvalid;

  /// No description provided for @errRecoveryLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in an hour.'**
  String get errRecoveryLocked;

  /// No description provided for @errRecoveryDisabled.
  ///
  /// In en, this message translates to:
  /// **'Recovery is disabled for this account. Contact support.'**
  String get errRecoveryDisabled;

  /// No description provided for @errResetTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'Time ran out. Start again.'**
  String get errResetTokenInvalid;

  /// No description provided for @errPinAlreadySet.
  ///
  /// In en, this message translates to:
  /// **'A recovery PIN is already set. Change it from Settings.'**
  String get errPinAlreadySet;

  /// No description provided for @errUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 3–30 characters: a–z, 0–9 or _.'**
  String get errUsernameInvalid;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'The password is too short.'**
  String get errPasswordTooShort;

  /// No description provided for @errPasswordTooLong.
  ///
  /// In en, this message translates to:
  /// **'The password is too long.'**
  String get errPasswordTooLong;

  /// No description provided for @errPasswordLetterRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one letter.'**
  String get errPasswordLetterRequired;

  /// No description provided for @errPasswordDigitRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one digit.'**
  String get errPasswordDigitRequired;

  /// No description provided for @errPasswordTooCommon.
  ///
  /// In en, this message translates to:
  /// **'This password is too common. Choose another one.'**
  String get errPasswordTooCommon;

  /// No description provided for @errPasswordContainsPhone.
  ///
  /// In en, this message translates to:
  /// **'The password can\'t contain your phone number.'**
  String get errPasswordContainsPhone;

  /// No description provided for @errPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match.'**
  String get errPasswordMismatch;

  /// No description provided for @errPinLength.
  ///
  /// In en, this message translates to:
  /// **'Enter all the digits.'**
  String get errPinLength;

  /// No description provided for @errPinDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Digits only.'**
  String get errPinDigitsOnly;

  /// No description provided for @errPinWeak.
  ///
  /// In en, this message translates to:
  /// **'This PIN is easy to guess. Avoid repeated or consecutive digits, years and digits from your number or password.'**
  String get errPinWeak;

  /// No description provided for @errPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs don\'t match.'**
  String get errPinMismatch;

  /// No description provided for @errTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short.'**
  String get errTooShort;

  /// No description provided for @errTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long.'**
  String get errTooLong;

  /// No description provided for @errInvalidValue.
  ///
  /// In en, this message translates to:
  /// **'Check this field.'**
  String get errInvalidValue;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

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

  /// No description provided for @externalNotLinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'No ReadIn account is linked to this account yet'**
  String get externalNotLinkedTitle;

  /// No description provided for @externalNotLinkedBody.
  ///
  /// In en, this message translates to:
  /// **'Create a new account, or link it to the account you already have with your phone number.'**
  String get externalNotLinkedBody;

  /// No description provided for @externalCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get externalCreateAccount;

  /// No description provided for @externalLinkExisting.
  ///
  /// In en, this message translates to:
  /// **'I have an account with a phone number'**
  String get externalLinkExisting;

  /// No description provided for @linkAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Link your account'**
  String get linkAccountTitle;

  /// No description provided for @linkAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your number and password once. After that, {provider} signs you in too.'**
  String linkAccountBody(String provider);

  /// No description provided for @linkAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Link and sign in'**
  String get linkAccountButton;

  /// No description provided for @linkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked accounts'**
  String get linkedAccounts;

  /// No description provided for @linkAction.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkAction;

  /// No description provided for @unlinkAction.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlinkAction;

  /// No description provided for @unlinkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlinkConfirm;

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get notLinked;

  /// No description provided for @unlinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink {provider}?'**
  String unlinkTitle(String provider);

  /// No description provided for @unlinkBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t be able to sign in with {provider} until you link it again.'**
  String unlinkBody(String provider);

  /// No description provided for @providerLinked.
  ///
  /// In en, this message translates to:
  /// **'{provider} linked'**
  String providerLinked(String provider);

  /// No description provided for @providerUnlinked.
  ///
  /// In en, this message translates to:
  /// **'{provider} unlinked'**
  String providerUnlinked(String provider);

  /// No description provided for @confirmItsYou.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get confirmItsYou;

  /// No description provided for @linkWithPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to link {provider}.'**
  String linkWithPasswordBody(String provider);

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @addPhoneSignIn.
  ///
  /// In en, this message translates to:
  /// **'Add a phone number and password'**
  String get addPhoneSignIn;

  /// No description provided for @addPhoneSignInBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll also be able to sign in with your number and password, and use a recovery PIN if you forget the password. You\'ll confirm with {provider} at the end.'**
  String addPhoneSignInBody(String provider);

  /// No description provided for @phoneSignInAdded.
  ///
  /// In en, this message translates to:
  /// **'Phone number and password added'**
  String get phoneSignInAdded;

  /// No description provided for @errExternalNotLinked.
  ///
  /// In en, this message translates to:
  /// **'No ReadIn account is linked to this account yet.'**
  String get errExternalNotLinked;

  /// No description provided for @errExternalInvalid.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t verify that account. Try again.'**
  String get errExternalInvalid;

  /// No description provided for @errProviderDisabled.
  ///
  /// In en, this message translates to:
  /// **'This way of signing in isn\'t available right now.'**
  String get errProviderDisabled;

  /// No description provided for @errExternalConflict.
  ///
  /// In en, this message translates to:
  /// **'Your ReadIn account already has another account of this kind linked.'**
  String get errExternalConflict;

  /// No description provided for @errExternalInUse.
  ///
  /// In en, this message translates to:
  /// **'This account is linked to another ReadIn account.'**
  String get errExternalInUse;

  /// No description provided for @errExternalMismatch.
  ///
  /// In en, this message translates to:
  /// **'Confirm with an account that\'s linked to your ReadIn account.'**
  String get errExternalMismatch;

  /// No description provided for @errExternalLoginNotFound.
  ///
  /// In en, this message translates to:
  /// **'This account isn\'t linked.'**
  String get errExternalLoginNotFound;

  /// No description provided for @errConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you first.'**
  String get errConfirmationRequired;

  /// No description provided for @errLastSignInMethod.
  ///
  /// In en, this message translates to:
  /// **'This is your only way to sign in. Add another one first.'**
  String get errLastSignInMethod;

  /// No description provided for @errPhoneSignInExists.
  ///
  /// In en, this message translates to:
  /// **'Your account already has a phone number and password.'**
  String get errPhoneSignInExists;

  /// No description provided for @errProviderInvalid.
  ///
  /// In en, this message translates to:
  /// **'This way of signing in isn\'t supported.'**
  String get errProviderInvalid;

  /// No description provided for @errExternalProviderFailed.
  ///
  /// In en, this message translates to:
  /// **'Signing in with Google or Apple didn\'t finish. Try again.'**
  String get errExternalProviderFailed;

  /// No description provided for @readingStreakNotReadTodaySemantics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Reading streak: 1 day. You haven\'t read today yet.} other{Reading streak: {count} days. You haven\'t read today yet.}}'**
  String readingStreakNotReadTodaySemantics(int count);

  /// No description provided for @readingStreakFreezePendingSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Reading streak: 1 day. You missed yesterday: read today and a freeze keeps your streak.} other{Reading streak: {count} days. You missed yesterday: read today and a freeze keeps your streak.}}'**
  String readingStreakFreezePendingSemantics(int count);

  /// No description provided for @readingStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading stats'**
  String get readingStatsTitle;

  /// No description provided for @readingCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get readingCurrentStreak;

  /// No description provided for @readingLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get readingLongestStreak;

  /// No description provided for @readingDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String readingDaysCount(int count);

  /// No description provided for @readingFreezeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Freeze ready: miss a day and your streak stays.'**
  String get readingFreezeAvailable;

  /// No description provided for @readingFreezePending.
  ///
  /// In en, this message translates to:
  /// **'You missed yesterday. Read today and a freeze keeps your streak.'**
  String get readingFreezePending;

  /// No description provided for @readingFreezeUsed.
  ///
  /// In en, this message translates to:
  /// **'Freeze used. You get a new one within 7 days.'**
  String get readingFreezeUsed;

  /// No description provided for @readingLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get readingLast7Days;

  /// No description provided for @readingLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get readingLast30Days;

  /// No description provided for @readingAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get readingAllTime;

  /// No description provided for @readingArticlesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String readingArticlesCount(int count);

  /// No description provided for @readingMinutesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String readingMinutesCount(int count);

  /// No description provided for @readingTopFields.
  ///
  /// In en, this message translates to:
  /// **'Top fields'**
  String get readingTopFields;

  /// No description provided for @readingTopFieldSemantics.
  ///
  /// In en, this message translates to:
  /// **'{field}: {articles}'**
  String readingTopFieldSemantics(String field, String articles);

  /// No description provided for @readingStatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Read an article to the end to start your streak.'**
  String get readingStatsEmpty;

  /// No description provided for @readingActivity.
  ///
  /// In en, this message translates to:
  /// **'Reading activity'**
  String get readingActivity;

  /// No description provided for @readingLast12Months.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get readingLast12Months;

  /// No description provided for @readingHeatmapLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get readingHeatmapLess;

  /// No description provided for @readingHeatmapMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get readingHeatmapMore;

  /// No description provided for @readingHeatmapFreeze.
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get readingHeatmapFreeze;

  /// No description provided for @readingHeatmapSemantics.
  ///
  /// In en, this message translates to:
  /// **'Reading activity in the last 12 months: {count, plural, =0{no reading days yet} =1{1 reading day} other{{count} reading days}}'**
  String readingHeatmapSemantics(int count);

  /// No description provided for @readingHeatmapDay.
  ///
  /// In en, this message translates to:
  /// **'{date}: {articles}'**
  String readingHeatmapDay(String date, String articles);

  /// No description provided for @readingHeatmapFrozenDay.
  ///
  /// In en, this message translates to:
  /// **'{date}: a freeze kept your streak'**
  String readingHeatmapFrozenDay(String date);

  /// No description provided for @readingHeatmapEmpty.
  ///
  /// In en, this message translates to:
  /// **'Every day you finish an article shows up here.'**
  String get readingHeatmapEmpty;

  /// No description provided for @readingDaysInARow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day in a row} other{days in a row}}'**
  String readingDaysInARow(int count);

  /// No description provided for @readingMilestoneWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'A full week!'**
  String get readingMilestoneWeekTitle;

  /// No description provided for @readingMilestoneWeekBody.
  ///
  /// In en, this message translates to:
  /// **'7 days of reading in a row. Keep it going.'**
  String get readingMilestoneWeekBody;

  /// No description provided for @readingMilestoneMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'A month of reading!'**
  String get readingMilestoneMonthTitle;

  /// No description provided for @readingMilestoneMonthBody.
  ///
  /// In en, this message translates to:
  /// **'30 days in a row. That\'s a real habit now.'**
  String get readingMilestoneMonthBody;

  /// No description provided for @readingMilestoneHundredTitle.
  ///
  /// In en, this message translates to:
  /// **'100 days!'**
  String get readingMilestoneHundredTitle;

  /// No description provided for @readingMilestoneHundredBody.
  ///
  /// In en, this message translates to:
  /// **'100 days in a row. Few readers get this far.'**
  String get readingMilestoneHundredBody;

  /// No description provided for @readingMilestoneYearTitle.
  ///
  /// In en, this message translates to:
  /// **'A whole year!'**
  String get readingMilestoneYearTitle;

  /// No description provided for @readingMilestoneYearBody.
  ///
  /// In en, this message translates to:
  /// **'365 days of reading in a row. Legendary.'**
  String get readingMilestoneYearBody;

  /// No description provided for @readingMilestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-day streak!} other{{count}-day streak!}}'**
  String readingMilestoneTitle(int count);

  /// No description provided for @readingMilestoneBody.
  ///
  /// In en, this message translates to:
  /// **'Keep it going.'**
  String get readingMilestoneBody;

  /// No description provided for @readingShareCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'ReadIn card: {count} days of reading in a row'**
  String readingShareCardSemantics(int count);

  /// No description provided for @readingKeepReading.
  ///
  /// In en, this message translates to:
  /// **'Keep reading'**
  String get readingKeepReading;

  /// No description provided for @readingShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the card. Try again.'**
  String get readingShareFailed;

  /// No description provided for @reactionInsightful.
  ///
  /// In en, this message translates to:
  /// **'Insightful'**
  String get reactionInsightful;

  /// No description provided for @reactionLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get reactionLove;

  /// No description provided for @reactionFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get reactionFire;

  /// No description provided for @reactionMindBlown.
  ///
  /// In en, this message translates to:
  /// **'Mind-blown'**
  String get reactionMindBlown;

  /// No description provided for @reactAction.
  ///
  /// In en, this message translates to:
  /// **'React with 💡 Insightful'**
  String get reactAction;

  /// No description provided for @removeReaction.
  ///
  /// In en, this message translates to:
  /// **'Remove your reaction ({reaction})'**
  String removeReaction(String reaction);

  /// No description provided for @chooseReaction.
  ///
  /// In en, this message translates to:
  /// **'Choose a reaction'**
  String get chooseReaction;

  /// No description provided for @reactionCountSemantics.
  ///
  /// In en, this message translates to:
  /// **'{reaction}: {count}'**
  String reactionCountSemantics(String reaction, int count);

  /// No description provided for @reactionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reactions yet} =1{1 reaction} other{{count} reactions}}'**
  String reactionsCount(int count);

  /// No description provided for @whoReacted.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get whoReacted;

  /// No description provided for @showWhoReacted.
  ///
  /// In en, this message translates to:
  /// **'See who reacted'**
  String get showWhoReacted;

  /// No description provided for @reactorsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reactions yet'**
  String get reactorsEmpty;

  /// No description provided for @reactorsEmptyType.
  ///
  /// In en, this message translates to:
  /// **'No one reacted with {reaction} yet'**
  String reactorsEmptyType(String reaction);

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No comments yet} =1{1 comment} other{{count} comments}}'**
  String commentsCount(int count);

  /// No description provided for @saveArticle.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveArticle;

  /// No description provided for @unsaveArticle.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get unsaveArticle;

  /// No description provided for @articleSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. You can read it offline too.'**
  String get articleSaved;

  /// No description provided for @articleUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get articleUnsaved;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get addToCollection;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get newCollection;

  /// No description provided for @collectionName.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get collectionName;

  /// No description provided for @collectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Interview prep'**
  String get collectionNameHint;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @renameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameAction;

  /// No description provided for @renameCollection.
  ///
  /// In en, this message translates to:
  /// **'Rename collection'**
  String get renameCollection;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirm;

  /// No description provided for @deleteCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteCollectionTitle(String name);

  /// No description provided for @deleteCollectionBody.
  ///
  /// In en, this message translates to:
  /// **'Only the collection goes. Its articles stay saved.'**
  String get deleteCollectionBody;

  /// No description provided for @collectionArticles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No articles} =1{1 article} other{{count} articles}}'**
  String collectionArticles(int count);

  /// No description provided for @collectionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No collections yet'**
  String get collectionsEmptyTitle;

  /// No description provided for @collectionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Group saved articles into lists, like “Interview prep”.'**
  String get collectionsEmptyBody;

  /// No description provided for @addedToCollection.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String addedToCollection(String name);

  /// No description provided for @removedFromCollection.
  ///
  /// In en, this message translates to:
  /// **'Removed from {name}'**
  String removedFromCollection(String name);

  /// No description provided for @removeFromCollection.
  ///
  /// In en, this message translates to:
  /// **'Remove from this collection'**
  String get removeFromCollection;

  /// No description provided for @inCollection.
  ///
  /// In en, this message translates to:
  /// **'In {name}'**
  String inCollection(String name);

  /// No description provided for @collectionFilter.
  ///
  /// In en, this message translates to:
  /// **'Collection: {name}'**
  String collectionFilter(String name);

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @openCollection.
  ///
  /// In en, this message translates to:
  /// **'Show the articles in {name}'**
  String openCollection(String name);

  /// No description provided for @savedTabArticles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get savedTabArticles;

  /// No description provided for @savedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your saved articles'**
  String get savedSearchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @savedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get savedEmptyTitle;

  /// No description provided for @savedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on any article to keep it here. Saved articles open even without internet.'**
  String get savedEmptyBody;

  /// No description provided for @savedNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved articles match'**
  String get savedNoResultsTitle;

  /// No description provided for @savedNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try another word or field.'**
  String get savedNoResultsBody;

  /// No description provided for @savedCollectionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'This collection is empty'**
  String get savedCollectionEmptyTitle;

  /// No description provided for @savedCollectionEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add articles to it from the reader or from your saved list.'**
  String get savedCollectionEmptyBody;

  /// No description provided for @savedOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. These are the articles saved on this device.'**
  String get savedOfflineBanner;

  /// No description provided for @offlineCopy.
  ///
  /// In en, this message translates to:
  /// **'Offline copy, saved on this device'**
  String get offlineCopy;

  /// No description provided for @savedGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your saved articles'**
  String get savedGuestTitle;

  /// No description provided for @savedGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save articles and read them later, even offline.'**
  String get savedGuestBody;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @followingState.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingState;

  /// No description provided for @followName.
  ///
  /// In en, this message translates to:
  /// **'Follow {name}'**
  String followName(String name);

  /// No description provided for @unfollowName.
  ///
  /// In en, this message translates to:
  /// **'Unfollow {name}'**
  String unfollowName(String name);

  /// No description provided for @followsYou.
  ///
  /// In en, this message translates to:
  /// **'Follows you'**
  String get followsYou;

  /// No description provided for @feedFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedFollowing;

  /// No description provided for @followingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow writers to fill this tab'**
  String get followingEmptyTitle;

  /// No description provided for @followingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New articles from the writers you follow show up here, newest first.'**
  String get followingEmptyBody;

  /// No description provided for @suggestedWriters.
  ///
  /// In en, this message translates to:
  /// **'Writers you might like'**
  String get suggestedWriters;

  /// No description provided for @suggestedWritersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No suggestions right now. Check back later.'**
  String get suggestedWritersEmpty;

  /// No description provided for @showFollowingArticles.
  ///
  /// In en, this message translates to:
  /// **'Show their articles'**
  String get showFollowingArticles;

  /// No description provided for @followingGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow the writers you like'**
  String get followingGuestTitle;

  /// No description provided for @followingGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow writers and read their new articles here.'**
  String get followingGuestBody;

  /// No description provided for @errReactionInvalid.
  ///
  /// In en, this message translates to:
  /// **'This reaction isn\'t available.'**
  String get errReactionInvalid;

  /// No description provided for @errCollectionNameTaken.
  ///
  /// In en, this message translates to:
  /// **'You already have a collection with this name.'**
  String get errCollectionNameTaken;

  /// No description provided for @errCollectionLimit.
  ///
  /// In en, this message translates to:
  /// **'You can have up to 50 collections.'**
  String get errCollectionLimit;

  /// No description provided for @errCollectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This collection doesn\'t exist anymore.'**
  String get errCollectionNotFound;

  /// No description provided for @errFollowSelf.
  ///
  /// In en, this message translates to:
  /// **'You can\'t follow yourself.'**
  String get errFollowSelf;

  /// No description provided for @commentsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the comments'**
  String get commentsOpen;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @commentsTitleCount.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String commentsTitleCount(int count);

  /// No description provided for @commentsSortTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get commentsSortTop;

  /// No description provided for @commentsSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get commentsSortNewest;

  /// No description provided for @commentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get commentsEmptyTitle;

  /// No description provided for @commentsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share what you think.'**
  String get commentsEmptyBody;

  /// No description provided for @commentsAuthorBadge.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get commentsAuthorBadge;

  /// No description provided for @commentsPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get commentsPinned;

  /// No description provided for @commentsEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get commentsEdited;

  /// No description provided for @commentsDeletedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This comment was deleted'**
  String get commentsDeletedPlaceholder;

  /// No description provided for @commentsHiddenPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Hidden by moderators'**
  String get commentsHiddenPlaceholder;

  /// No description provided for @commentsHiddenNotice.
  ///
  /// In en, this message translates to:
  /// **'Hidden by moderators. Only you and the moderators can see it.'**
  String get commentsHiddenNotice;

  /// No description provided for @commentsDeletedUser.
  ///
  /// In en, this message translates to:
  /// **'Deleted user'**
  String get commentsDeletedUser;

  /// No description provided for @commentsLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get commentsLike;

  /// No description provided for @commentsUnlike.
  ///
  /// In en, this message translates to:
  /// **'Remove your like'**
  String get commentsUnlike;

  /// No description provided for @commentsLikesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No likes} =1{1 like} other{{count} likes}}'**
  String commentsLikesCount(int count);

  /// No description provided for @commentsReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get commentsReply;

  /// No description provided for @commentsMoreReplies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 more reply} other{Show {count} more replies}}'**
  String commentsMoreReplies(int count);

  /// No description provided for @commentsMoreRepliesAny.
  ///
  /// In en, this message translates to:
  /// **'Show more replies'**
  String get commentsMoreRepliesAny;

  /// No description provided for @commentsHideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide replies'**
  String get commentsHideReplies;

  /// No description provided for @commentsRepliesFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the replies.'**
  String get commentsRepliesFailed;

  /// No description provided for @commentsShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more comments'**
  String get commentsShowMore;

  /// No description provided for @commentsNewPill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new comment} other{{count} new comments}}'**
  String commentsNewPill(int count);

  /// No description provided for @commentsSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get commentsSending;

  /// No description provided for @commentsTimeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get commentsTimeNow;

  /// No description provided for @commentsTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String commentsTimeMinutes(int count);

  /// No description provided for @commentsTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hr ago} other{{count} hrs ago}}'**
  String commentsTimeHours(int count);

  /// No description provided for @commentsTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{yesterday} other{{count} days ago}}'**
  String commentsTimeDays(int count);

  /// No description provided for @commentsComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get commentsComposerHint;

  /// No description provided for @commentsReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get commentsReplyHint;

  /// No description provided for @commentsSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commentsSend;

  /// No description provided for @commentsReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String commentsReplyingTo(String name);

  /// No description provided for @commentsEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing your comment'**
  String get commentsEditing;

  /// No description provided for @commentsMentionSuggestions.
  ///
  /// In en, this message translates to:
  /// **'People to mention'**
  String get commentsMentionSuggestions;

  /// No description provided for @commentsGuestPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join the conversation.'**
  String get commentsGuestPrompt;

  /// No description provided for @commentsMenu.
  ///
  /// In en, this message translates to:
  /// **'Comment options'**
  String get commentsMenu;

  /// No description provided for @commentsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get commentsDeleteTitle;

  /// No description provided for @commentsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. Replies to it stay.'**
  String get commentsDeleteBody;

  /// No description provided for @commentsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted'**
  String get commentsDeleted;

  /// No description provided for @commentsPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get commentsPin;

  /// No description provided for @commentsUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get commentsUnpin;

  /// No description provided for @commentsReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commentsReport;

  /// No description provided for @commentsModHide.
  ///
  /// In en, this message translates to:
  /// **'Hide (moderator)'**
  String get commentsModHide;

  /// No description provided for @commentsModUnhide.
  ///
  /// In en, this message translates to:
  /// **'Unhide (moderator)'**
  String get commentsModUnhide;

  /// No description provided for @commentsModDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete (moderator)'**
  String get commentsModDelete;

  /// No description provided for @commentsModDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment for everyone?'**
  String get commentsModDeleteTitle;

  /// No description provided for @commentsModDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s removed for every reader and recorded in the audit log.'**
  String get commentsModDeleteBody;

  /// No description provided for @commentsHidden.
  ///
  /// In en, this message translates to:
  /// **'Comment hidden'**
  String get commentsHidden;

  /// No description provided for @commentsUnhidden.
  ///
  /// In en, this message translates to:
  /// **'Comment visible again'**
  String get commentsUnhidden;

  /// No description provided for @commentsErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You\'re commenting too fast. Wait a minute and try again.'**
  String get commentsErrRateLimited;

  /// No description provided for @commentsErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'This comment doesn\'t exist anymore.'**
  String get commentsErrNotFound;

  /// No description provided for @commentsErrNotOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the comment\'s author can change it.'**
  String get commentsErrNotOwner;

  /// No description provided for @commentsErrNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This comment was deleted or hidden.'**
  String get commentsErrNotAvailable;

  /// No description provided for @commentsErrPinReply.
  ///
  /// In en, this message translates to:
  /// **'Only top-level comments can be pinned.'**
  String get commentsErrPinReply;

  /// No description provided for @commentsErrPinNotAuthor.
  ///
  /// In en, this message translates to:
  /// **'Only the article\'s author can pin comments.'**
  String get commentsErrPinNotAuthor;

  /// No description provided for @commentsErrPinConflict.
  ///
  /// In en, this message translates to:
  /// **'Another comment was pinned at the same time. Try again.'**
  String get commentsErrPinConflict;

  /// No description provided for @commentsErrArticleLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve commented a lot on this article. Try again later.'**
  String get commentsErrArticleLimit;

  /// No description provided for @commentsErrDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You just posted the same comment.'**
  String get commentsErrDuplicate;

  /// No description provided for @commentsErrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write something first.'**
  String get commentsErrEmpty;

  /// No description provided for @commentsErrTooLong.
  ///
  /// In en, this message translates to:
  /// **'A comment can have at most 2000 characters.'**
  String get commentsErrTooLong;

  /// No description provided for @commentsErrReportOwnContent.
  ///
  /// In en, this message translates to:
  /// **'You can\'t report your own comment.'**
  String get commentsErrReportOwnContent;

  /// No description provided for @commentsErrReportNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be reported yet.'**
  String get commentsErrReportNotSupported;

  /// No description provided for @commentsErrReportReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason.'**
  String get commentsErrReportReason;

  /// No description provided for @myArticlesTitle.
  ///
  /// In en, this message translates to:
  /// **'My articles'**
  String get myArticlesTitle;

  /// No description provided for @myArticlesDrafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get myArticlesDrafts;

  /// No description provided for @myArticlesPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get myArticlesPublished;

  /// No description provided for @myArticlesNew.
  ///
  /// In en, this message translates to:
  /// **'New article'**
  String get myArticlesNew;

  /// No description provided for @myArticlesEmptyDrafts.
  ///
  /// In en, this message translates to:
  /// **'No drafts yet'**
  String get myArticlesEmptyDrafts;

  /// No description provided for @myArticlesEmptyDraftsBody.
  ///
  /// In en, this message translates to:
  /// **'Start a new article. It saves itself while you write.'**
  String get myArticlesEmptyDraftsBody;

  /// No description provided for @myArticlesEmptyPublished.
  ///
  /// In en, this message translates to:
  /// **'Nothing published yet'**
  String get myArticlesEmptyPublished;

  /// No description provided for @myArticlesEmptyPublishedBody.
  ///
  /// In en, this message translates to:
  /// **'The articles you publish show up here.'**
  String get myArticlesEmptyPublishedBody;

  /// No description provided for @untitledArticle.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitledArticle;

  /// No description provided for @unpublishedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unpublished changes'**
  String get unpublishedChanges;

  /// No description provided for @myArticleEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited {date}'**
  String myArticleEdited(String date);

  /// No description provided for @myArticlePublishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String myArticlePublishedOn(String date);

  /// No description provided for @pdfDownload.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get pdfDownload;

  /// No description provided for @pdfPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the PDF…'**
  String get pdfPreparing;

  /// No description provided for @pdfRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get pdfRetry;

  /// No description provided for @pdfLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Which version?'**
  String get pdfLanguageTitle;

  /// No description provided for @pdfLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'This article is published in two languages. Choose the version to download as a PDF.'**
  String get pdfLanguageBody;

  /// No description provided for @errArticlePdfNotFound.
  ///
  /// In en, this message translates to:
  /// **'Article not found.'**
  String get errArticlePdfNotFound;

  /// No description provided for @errArticlePdfHidden.
  ///
  /// In en, this message translates to:
  /// **'Moderators hid this article, so it can\'t be downloaded as a PDF.'**
  String get errArticlePdfHidden;

  /// No description provided for @errArticlePdfLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve downloaded many PDFs this hour. Try again later.'**
  String get errArticlePdfLimit;

  /// No description provided for @errArticlePdfBusy.
  ///
  /// In en, this message translates to:
  /// **'Many PDFs are being prepared right now. Try again in a moment.'**
  String get errArticlePdfBusy;

  /// No description provided for @errArticlePdfFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t prepare the PDF. Try again.'**
  String get errArticlePdfFailed;

  /// No description provided for @errArticlePdfOffline.
  ///
  /// In en, this message translates to:
  /// **'You need an internet connection to download the PDF.'**
  String get errArticlePdfOffline;

  /// No description provided for @deleteArticleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this article?'**
  String get deleteArticleTitle;

  /// No description provided for @deleteDraftBody.
  ///
  /// In en, this message translates to:
  /// **'The draft will be deleted for good.'**
  String get deleteDraftBody;

  /// No description provided for @deletePublishedBody.
  ///
  /// In en, this message translates to:
  /// **'Readers won\'t see it anymore, and its link will stop working.'**
  String get deletePublishedBody;

  /// No description provided for @articleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Article deleted'**
  String get articleDeleted;

  /// No description provided for @editorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New article'**
  String get editorNewTitle;

  /// No description provided for @editorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit article'**
  String get editorEditTitle;

  /// No description provided for @editorTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get editorTitleHint;

  /// No description provided for @editorSubtitleHint.
  ///
  /// In en, this message translates to:
  /// **'Subtitle (optional)'**
  String get editorSubtitleHint;

  /// No description provided for @editorStartWriting.
  ///
  /// In en, this message translates to:
  /// **'Write here, or type / to add a block'**
  String get editorStartWriting;

  /// No description provided for @saveStatusSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saveStatusSaving;

  /// No description provided for @saveStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saveStatusSaved;

  /// No description provided for @saveStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline, saved on this device'**
  String get saveStatusOffline;

  /// No description provided for @saveStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save'**
  String get saveStatusFailed;

  /// No description provided for @saveStatusUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet'**
  String get saveStatusUnsaved;

  /// No description provided for @editorPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get editorPublish;

  /// No description provided for @editorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get editorUpdate;

  /// No description provided for @editorPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get editorPublishing;

  /// No description provided for @editorPublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get editorPublishedMessage;

  /// No description provided for @editorUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get editorUpdatedMessage;

  /// No description provided for @editorPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get editorPreview;

  /// No description provided for @editorSettings.
  ///
  /// In en, this message translates to:
  /// **'Article settings'**
  String get editorSettings;

  /// No description provided for @editorRevisions.
  ///
  /// In en, this message translates to:
  /// **'Revision history'**
  String get editorRevisions;

  /// No description provided for @editorDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get editorDiscardChanges;

  /// No description provided for @editorDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete article'**
  String get editorDelete;

  /// No description provided for @editorMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get editorMore;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard the unpublished changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'The article goes back to what readers see now.'**
  String get discardChangesBody;

  /// No description provided for @discardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardAction;

  /// No description provided for @changesDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Changes discarded'**
  String get changesDiscarded;

  /// No description provided for @conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Edited somewhere else'**
  String get conflictTitle;

  /// No description provided for @conflictBody.
  ///
  /// In en, this message translates to:
  /// **'This article changed on another device or tab. Which version do you want to keep?'**
  String get conflictBody;

  /// No description provided for @conflictReload.
  ///
  /// In en, this message translates to:
  /// **'Load the saved version'**
  String get conflictReload;

  /// No description provided for @conflictKeepMine.
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get conflictKeepMine;

  /// No description provided for @restoreBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore unsaved changes?'**
  String get restoreBackupTitle;

  /// No description provided for @restoreBackupBody.
  ///
  /// In en, this message translates to:
  /// **'This device kept changes from {time} that weren\'t saved.'**
  String restoreBackupBody(String time);

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// No description provided for @discardBackupAction.
  ///
  /// In en, this message translates to:
  /// **'Don\'t restore'**
  String get discardBackupAction;

  /// No description provided for @checksTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you publish'**
  String get checksTitle;

  /// No description provided for @checksReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to publish'**
  String get checksReady;

  /// No description provided for @checksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing to fix} other{{count} things to fix}}'**
  String checksCount(int count);

  /// No description provided for @checksUploading.
  ///
  /// In en, this message translates to:
  /// **'Wait for the uploads to finish.'**
  String get checksUploading;

  /// No description provided for @problemFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a field.'**
  String get problemFieldRequired;

  /// No description provided for @problemTitleLength.
  ///
  /// In en, this message translates to:
  /// **'The title needs 5 to 150 characters.'**
  String get problemTitleLength;

  /// No description provided for @problemContentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write something in the article.'**
  String get problemContentEmpty;

  /// No description provided for @problemContentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Some blocks aren\'t complete, like a step without a title.'**
  String get problemContentInvalid;

  /// No description provided for @problemImageAlt.
  ///
  /// In en, this message translates to:
  /// **'An image needs alt text.'**
  String get problemImageAlt;

  /// No description provided for @problemSourcesRequired.
  ///
  /// In en, this message translates to:
  /// **'This field needs at least one source.'**
  String get problemSourcesRequired;

  /// No description provided for @problemAttachmentAlt.
  ///
  /// In en, this message translates to:
  /// **'An attached image needs alt text.'**
  String get problemAttachmentAlt;

  /// No description provided for @problemAttachmentTitle.
  ///
  /// In en, this message translates to:
  /// **'The PDF needs a title.'**
  String get problemAttachmentTitle;

  /// No description provided for @problemAttachmentNotReady.
  ///
  /// In en, this message translates to:
  /// **'An attachment is still uploading, or it failed.'**
  String get problemAttachmentNotReady;

  /// No description provided for @errDraftConflict.
  ///
  /// In en, this message translates to:
  /// **'This article was changed somewhere else.'**
  String get errDraftConflict;

  /// No description provided for @errNotPublished.
  ///
  /// In en, this message translates to:
  /// **'This article isn\'t published yet.'**
  String get errNotPublished;

  /// No description provided for @errRevisionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This version doesn\'t exist anymore.'**
  String get errRevisionNotFound;

  /// No description provided for @articleVersionArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get articleVersionArabic;

  /// No description provided for @articleVersionEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get articleVersionEnglish;

  /// No description provided for @languageVersions.
  ///
  /// In en, this message translates to:
  /// **'Language versions'**
  String get languageVersions;

  /// No description provided for @sourceLanguageTag.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLanguageTag;

  /// No description provided for @sourceLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'The language you write first. Change it before adding a translation.'**
  String get sourceLanguageHint;

  /// No description provided for @addTranslation.
  ///
  /// In en, this message translates to:
  /// **'Add the {language} version'**
  String addTranslation(String language);

  /// No description provided for @removeTranslation.
  ///
  /// In en, this message translates to:
  /// **'Remove the {language} version'**
  String removeTranslation(String language);

  /// No description provided for @removeTranslationTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the {language} version?'**
  String removeTranslationTitle(String language);

  /// No description provided for @removeTranslationBody.
  ///
  /// In en, this message translates to:
  /// **'Its title and text will be deleted.'**
  String get removeTranslationBody;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @topicLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topicLabel;

  /// No description provided for @topicNone.
  ///
  /// In en, this message translates to:
  /// **'No topic'**
  String get topicNone;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Type a tag, then Enter or a comma'**
  String get tagsHint;

  /// No description provided for @tagsLimit.
  ///
  /// In en, this message translates to:
  /// **'{count} of 5 tags'**
  String tagsLimit(int count);

  /// No description provided for @removeTag.
  ///
  /// In en, this message translates to:
  /// **'Remove {tag}'**
  String removeTag(String tag);

  /// No description provided for @tagsFull.
  ///
  /// In en, this message translates to:
  /// **'That\'s 5 tags, the most an article can have. Remove one to add another.'**
  String get tagsFull;

  /// No description provided for @tagsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tagsAdd;

  /// No description provided for @tagCreate.
  ///
  /// In en, this message translates to:
  /// **'Create new tag: {name}'**
  String tagCreate(String name);

  /// No description provided for @tagSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggested tags'**
  String get tagSuggestionsLabel;

  /// No description provided for @tagAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'The article already has this tag.'**
  String get tagAlreadyAdded;

  /// No description provided for @tagTooShort.
  ///
  /// In en, this message translates to:
  /// **'A tag needs at least 2 characters.'**
  String get tagTooShort;

  /// No description provided for @tagTooLong.
  ///
  /// In en, this message translates to:
  /// **'A tag can have at most 30 characters.'**
  String get tagTooLong;

  /// No description provided for @tagInvalidCharacters.
  ///
  /// In en, this message translates to:
  /// **'Use letters, digits, spaces and - _ . + # only.'**
  String get tagInvalidCharacters;

  /// No description provided for @tagNoLetter.
  ///
  /// In en, this message translates to:
  /// **'A tag needs at least one letter or digit.'**
  String get tagNoLetter;

  /// No description provided for @problemTagHidden.
  ///
  /// In en, this message translates to:
  /// **'The tag {name} isn\'t available. Remove it or choose another one.'**
  String problemTagHidden(String name);

  /// No description provided for @problemTagLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve created a lot of new tags today, so {name} can\'t be added now. Pick an existing tag, or try again later.'**
  String problemTagLimit(String name);

  /// No description provided for @coverLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover image'**
  String get coverLabel;

  /// No description provided for @coverAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a cover'**
  String get coverAdd;

  /// No description provided for @coverChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get coverChange;

  /// No description provided for @coverRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get coverRemove;

  /// No description provided for @coverHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on the article\'s card in the feed.'**
  String get coverHint;

  /// No description provided for @uploadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploadingLabel;

  /// No description provided for @versionBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Version badge'**
  String get versionBadgeLabel;

  /// No description provided for @versionBadgeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. .NET 10'**
  String get versionBadgeHint;

  /// No description provided for @aiAssistedSwitch.
  ///
  /// In en, this message translates to:
  /// **'Written with AI help'**
  String get aiAssistedSwitch;

  /// No description provided for @aiAssistedSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Readers see an “AI-assisted” label on the article.'**
  String get aiAssistedSwitchHint;

  /// No description provided for @blockParagraph.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get blockParagraph;

  /// No description provided for @blockHeading2.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get blockHeading2;

  /// No description provided for @blockHeading3.
  ///
  /// In en, this message translates to:
  /// **'Subheading'**
  String get blockHeading3;

  /// No description provided for @blockBulletList.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get blockBulletList;

  /// No description provided for @blockOrderedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get blockOrderedList;

  /// No description provided for @blockSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get blockSteps;

  /// No description provided for @blockQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get blockQuote;

  /// No description provided for @blockCallout.
  ///
  /// In en, this message translates to:
  /// **'Callout'**
  String get blockCallout;

  /// No description provided for @blockCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get blockCode;

  /// No description provided for @blockCodeTabs.
  ///
  /// In en, this message translates to:
  /// **'Code tabs'**
  String get blockCodeTabs;

  /// No description provided for @blockTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get blockTable;

  /// No description provided for @blockImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get blockImage;

  /// No description provided for @blockDivider.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get blockDivider;

  /// No description provided for @blockEmbed.
  ///
  /// In en, this message translates to:
  /// **'YouTube or Gist'**
  String get blockEmbed;

  /// No description provided for @blockSummary.
  ///
  /// In en, this message translates to:
  /// **'TL;DR summary'**
  String get blockSummary;

  /// No description provided for @addBlock.
  ///
  /// In en, this message translates to:
  /// **'Add a block'**
  String get addBlock;

  /// No description provided for @blockOptions.
  ///
  /// In en, this message translates to:
  /// **'Block options'**
  String get blockOptions;

  /// No description provided for @blockDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get blockDirection;

  /// No description provided for @dirAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get dirAuto;

  /// No description provided for @dirRtl.
  ///
  /// In en, this message translates to:
  /// **'Right to left'**
  String get dirRtl;

  /// No description provided for @dirLtr.
  ///
  /// In en, this message translates to:
  /// **'Left to right'**
  String get dirLtr;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @deleteBlock.
  ///
  /// In en, this message translates to:
  /// **'Delete block'**
  String get deleteBlock;

  /// No description provided for @turnInto.
  ///
  /// In en, this message translates to:
  /// **'Turn into'**
  String get turnInto;

  /// No description provided for @calloutTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get calloutTip;

  /// No description provided for @calloutInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get calloutInfo;

  /// No description provided for @calloutWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get calloutWarning;

  /// No description provided for @calloutDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get calloutDanger;

  /// No description provided for @calloutTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get calloutTitleHint;

  /// No description provided for @quoteCiteHint.
  ///
  /// In en, this message translates to:
  /// **'Who said it (optional)'**
  String get quoteCiteHint;

  /// No description provided for @codeFilenameHint.
  ///
  /// In en, this message translates to:
  /// **'File name (optional)'**
  String get codeFilenameHint;

  /// No description provided for @codeHint.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeHint;

  /// No description provided for @codeTabLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Tab name'**
  String get codeTabLabelHint;

  /// No description provided for @addCodeTab.
  ///
  /// In en, this message translates to:
  /// **'Add tab'**
  String get addCodeTab;

  /// No description provided for @removeCodeTab.
  ///
  /// In en, this message translates to:
  /// **'Remove tab'**
  String get removeCodeTab;

  /// No description provided for @tableAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get tableAddRow;

  /// No description provided for @tableAddColumn.
  ///
  /// In en, this message translates to:
  /// **'Add column'**
  String get tableAddColumn;

  /// No description provided for @tableDeleteRow.
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get tableDeleteRow;

  /// No description provided for @tableDeleteColumn.
  ///
  /// In en, this message translates to:
  /// **'Delete column'**
  String get tableDeleteColumn;

  /// No description provided for @tableDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get tableDelete;

  /// No description provided for @tableTools.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get tableTools;

  /// No description provided for @stepTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Step title'**
  String get stepTitleHint;

  /// No description provided for @stepContentHint.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get stepContentHint;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @removeStep.
  ///
  /// In en, this message translates to:
  /// **'Remove step'**
  String get removeStep;

  /// No description provided for @listItemHint.
  ///
  /// In en, this message translates to:
  /// **'List item'**
  String get listItemHint;

  /// No description provided for @imageChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get imageChoose;

  /// No description provided for @imageAltLabel.
  ///
  /// In en, this message translates to:
  /// **'Alt text (required)'**
  String get imageAltLabel;

  /// No description provided for @imageAltHelp.
  ///
  /// In en, this message translates to:
  /// **'Describe the image for people who can\'t see it.'**
  String get imageAltHelp;

  /// No description provided for @imageCaptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Caption (optional)'**
  String get imageCaptionLabel;

  /// No description provided for @imageReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get imageReplace;

  /// No description provided for @embedUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get embedUrlLabel;

  /// No description provided for @embedInvalid.
  ///
  /// In en, this message translates to:
  /// **'Paste a YouTube or GitHub Gist link.'**
  String get embedInvalid;

  /// No description provided for @formatBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get formatBold;

  /// No description provided for @formatItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get formatItalic;

  /// No description provided for @formatCode.
  ///
  /// In en, this message translates to:
  /// **'Inline code'**
  String get formatCode;

  /// No description provided for @formatHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get formatHighlight;

  /// No description provided for @formatStrike.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get formatStrike;

  /// No description provided for @formatLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get formatLink;

  /// No description provided for @formatLineBreak.
  ///
  /// In en, this message translates to:
  /// **'Line break'**
  String get formatLineBreak;

  /// No description provided for @formatMention.
  ///
  /// In en, this message translates to:
  /// **'Mention someone'**
  String get formatMention;

  /// No description provided for @formatTerm.
  ///
  /// In en, this message translates to:
  /// **'Glossary term'**
  String get formatTerm;

  /// No description provided for @termPickerFor.
  ///
  /// In en, this message translates to:
  /// **'Mark as a glossary term:'**
  String get termPickerFor;

  /// No description provided for @termPickerCurrent.
  ///
  /// In en, this message translates to:
  /// **'Glossary term:'**
  String get termPickerCurrent;

  /// No description provided for @termSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the glossary (English term)'**
  String get termSearchHint;

  /// No description provided for @termSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get termSearching;

  /// No description provided for @termNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No glossary term matches. Try the English term.'**
  String get termNoMatches;

  /// No description provided for @termTypeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type a term to search the glossary.'**
  String get termTypeToSearch;

  /// No description provided for @termSearchError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search the glossary.'**
  String get termSearchError;

  /// No description provided for @termRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove term'**
  String get termRemove;

  /// No description provided for @linkDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkDialogTitle;

  /// No description provided for @linkUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL (http or https)'**
  String get linkUrlLabel;

  /// No description provided for @linkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get linkRemove;

  /// No description provided for @linkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use an http or https link.'**
  String get linkInvalid;

  /// No description provided for @slashNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No block with that name'**
  String get slashNoMatches;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// No description provided for @previewInFeed.
  ///
  /// In en, this message translates to:
  /// **'In the feed'**
  String get previewInFeed;

  /// No description provided for @previewLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get previewLight;

  /// No description provided for @previewDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get previewDark;

  /// No description provided for @revisionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No versions yet. Every publish and update adds one.'**
  String get revisionsEmpty;

  /// No description provided for @revisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {number}'**
  String revisionLabel(int number);

  /// No description provided for @revisionFirst.
  ///
  /// In en, this message translates to:
  /// **'First publish'**
  String get revisionFirst;

  /// No description provided for @revisionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore this version'**
  String get revisionRestore;

  /// No description provided for @revisionRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore version {number}?'**
  String revisionRestoreTitle(int number);

  /// No description provided for @revisionRestoreBody.
  ///
  /// In en, this message translates to:
  /// **'It replaces what\'s in the editor now. Readers see it only after you press Update.'**
  String get revisionRestoreBody;

  /// No description provided for @revisionRestored.
  ///
  /// In en, this message translates to:
  /// **'Version restored. Press Update to publish it.'**
  String get revisionRestored;

  /// No description provided for @errAppleConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'This account is linked to Apple. Confirm with Apple to delete it.'**
  String get errAppleConfirmationRequired;

  /// No description provided for @errDeletionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t finish deleting your account, so nothing was deleted. Try again in a few minutes.'**
  String get errDeletionUnavailable;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @continueReadingProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% read'**
  String continueReadingProgress(int percent);

  /// No description provided for @pathsTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning paths'**
  String get pathsTitle;

  /// No description provided for @pathsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All paths'**
  String get pathsTabAll;

  /// No description provided for @pathsTabMine.
  ///
  /// In en, this message translates to:
  /// **'My paths'**
  String get pathsTabMine;

  /// No description provided for @pathsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Learn step by step with learning paths'**
  String get pathsPrompt;

  /// No description provided for @pathsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Explore learning paths'**
  String get pathsBrowse;

  /// No description provided for @pathsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No learning paths here yet'**
  String get pathsEmptyTitle;

  /// No description provided for @pathsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re putting the first ones together. Check back soon.'**
  String get pathsEmptyBody;

  /// No description provided for @myPathsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t started a path yet'**
  String get myPathsEmptyTitle;

  /// No description provided for @myPathsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a path and learn a topic one article at a time.'**
  String get myPathsEmptyBody;

  /// No description provided for @myPathsGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your paths'**
  String get myPathsGuestTitle;

  /// No description provided for @myPathsGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to join paths and pick up where you left off.'**
  String get myPathsGuestBody;

  /// No description provided for @pathArticleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String pathArticleCount(int count);

  /// No description provided for @pathMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 min} other{{minutes} min}}'**
  String pathMinutes(int minutes);

  /// No description provided for @pathProgressSemantics.
  ///
  /// In en, this message translates to:
  /// **'{read} of {total} articles read'**
  String pathProgressSemantics(int read, int total);

  /// No description provided for @pathCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get pathCompleted;

  /// No description provided for @pathCompletedCelebration.
  ///
  /// In en, this message translates to:
  /// **'Path completed 🎉'**
  String get pathCompletedCelebration;

  /// No description provided for @pathStart.
  ///
  /// In en, this message translates to:
  /// **'Start path'**
  String get pathStart;

  /// No description provided for @pathContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue: {title}'**
  String pathContinue(String title);

  /// No description provided for @pathReadAgain.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get pathReadAgain;

  /// No description provided for @pathNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String pathNext(String title);

  /// No description provided for @pathUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get pathUpNext;

  /// No description provided for @pathItemRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get pathItemRead;

  /// No description provided for @pathMenu.
  ///
  /// In en, this message translates to:
  /// **'Path options'**
  String get pathMenu;

  /// No description provided for @pathLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave path'**
  String get pathLeave;

  /// No description provided for @pathLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave path'**
  String get pathLeaveConfirm;

  /// No description provided for @pathLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this path?'**
  String get pathLeaveTitle;

  /// No description provided for @pathLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your reading history stays. Join again any time and your progress comes back.'**
  String get pathLeaveBody;

  /// No description provided for @pathLeft.
  ///
  /// In en, this message translates to:
  /// **'You left the path'**
  String get pathLeft;

  /// No description provided for @pathJoin.
  ///
  /// In en, this message translates to:
  /// **'Join path'**
  String get pathJoin;

  /// No description provided for @pathJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined the path'**
  String get pathJoined;

  /// No description provided for @pathFrom.
  ///
  /// In en, this message translates to:
  /// **'From the path: {title}'**
  String pathFrom(String title);

  /// No description provided for @pathPosition.
  ///
  /// In en, this message translates to:
  /// **'{position} of {total}'**
  String pathPosition(int position, int total);

  /// No description provided for @pathNextInPath.
  ///
  /// In en, this message translates to:
  /// **'Next in path'**
  String get pathNextInPath;

  /// No description provided for @pathLastArticle.
  ///
  /// In en, this message translates to:
  /// **'This is the last article in the path'**
  String get pathLastArticle;

  /// No description provided for @pathNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This path isn\'t available'**
  String get pathNotFoundTitle;

  /// No description provided for @pathNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed, or the link is wrong.'**
  String get pathNotFoundBody;

  /// No description provided for @errPathNotFound.
  ///
  /// In en, this message translates to:
  /// **'This path doesn\'t exist or was removed.'**
  String get errPathNotFound;

  /// No description provided for @errPathSlugTaken.
  ///
  /// In en, this message translates to:
  /// **'Another path already uses this link.'**
  String get errPathSlugTaken;

  /// No description provided for @errPathEditorial.
  ///
  /// In en, this message translates to:
  /// **'Editorial paths are managed in the content files.'**
  String get errPathEditorial;

  /// No description provided for @errPathItemsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the path\'s articles: 1 to 100 published articles, each one once.'**
  String get errPathItemsInvalid;

  /// No description provided for @reportTitleArticle.
  ///
  /// In en, this message translates to:
  /// **'Report article'**
  String get reportTitleArticle;

  /// No description provided for @reportTitleComment.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get reportTitleComment;

  /// No description provided for @reportTitleUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportTitleUser;

  /// No description provided for @reportBody.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this? Our moderators will review it.'**
  String get reportBody;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonMisinformation.
  ///
  /// In en, this message translates to:
  /// **'Misinformation'**
  String get reportReasonMisinformation;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get reportReasonCopyright;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReasonOther;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetails;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSubmit;

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we\'ll review it.'**
  String get reportThanks;

  /// No description provided for @errSuspendedUntil.
  ///
  /// In en, this message translates to:
  /// **'This account is suspended until {date}. Contact support.'**
  String errSuspendedUntil(String date);

  /// No description provided for @errSuspendedPermanently.
  ///
  /// In en, this message translates to:
  /// **'This account is permanently suspended. Contact support.'**
  String get errSuspendedPermanently;

  /// No description provided for @errReportOwnContent.
  ///
  /// In en, this message translates to:
  /// **'You can\'t report yourself or your own content.'**
  String get errReportOwnContent;

  /// No description provided for @errReportReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason.'**
  String get errReportReason;

  /// No description provided for @errReportTargetInvalid.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be reported.'**
  String get errReportTargetInvalid;

  /// No description provided for @errReportTargetNotFound.
  ///
  /// In en, this message translates to:
  /// **'What you\'re reporting doesn\'t exist anymore.'**
  String get errReportTargetNotFound;

  /// No description provided for @errModerationActionInvalid.
  ///
  /// In en, this message translates to:
  /// **'This action isn\'t available here.'**
  String get errModerationActionInvalid;

  /// No description provided for @errModerationSelf.
  ///
  /// In en, this message translates to:
  /// **'You can\'t do this to your own account.'**
  String get errModerationSelf;

  /// No description provided for @errModerationStaffTarget.
  ///
  /// In en, this message translates to:
  /// **'You can\'t warn or suspend a member of the moderation team.'**
  String get errModerationStaffTarget;

  /// No description provided for @errModerationNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Write a note first.'**
  String get errModerationNoteRequired;

  /// No description provided for @errModerationDurationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose between 1 and 365 days.'**
  String get errModerationDurationInvalid;

  /// No description provided for @errModerationNoticeNotFound.
  ///
  /// In en, this message translates to:
  /// **'This notice isn\'t available anymore.'**
  String get errModerationNoticeNotFound;

  /// No description provided for @articleMenu.
  ///
  /// In en, this message translates to:
  /// **'Article options'**
  String get articleMenu;

  /// No description provided for @articleMenuReport.
  ///
  /// In en, this message translates to:
  /// **'Report article'**
  String get articleMenuReport;

  /// No description provided for @articleMenuHide.
  ///
  /// In en, this message translates to:
  /// **'Hide article'**
  String get articleMenuHide;

  /// No description provided for @articleMenuUnhide.
  ///
  /// In en, this message translates to:
  /// **'Unhide article'**
  String get articleMenuUnhide;

  /// No description provided for @articleHiddenBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden by moderators'**
  String get articleHiddenBannerTitle;

  /// No description provided for @articleHiddenBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Only its author and moderators can see it.'**
  String get articleHiddenBannerBody;

  /// No description provided for @articleMenuShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less like this'**
  String get articleMenuShowLess;

  /// No description provided for @articleMenuFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow author'**
  String get articleMenuFollow;

  /// No description provided for @articleMenuUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow author'**
  String get articleMenuUnfollow;

  /// No description provided for @articleMenuMuteAuthor.
  ///
  /// In en, this message translates to:
  /// **'Mute author'**
  String get articleMenuMuteAuthor;

  /// No description provided for @articleMenuUnmuteAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unmute author'**
  String get articleMenuUnmuteAuthor;

  /// No description provided for @articleMenuMuteTopics.
  ///
  /// In en, this message translates to:
  /// **'Mute topics'**
  String get articleMenuMuteTopics;

  /// No description provided for @showLessDone.
  ///
  /// In en, this message translates to:
  /// **'Got it. You\'ll see fewer articles like this.'**
  String get showLessDone;

  /// No description provided for @muteDone.
  ///
  /// In en, this message translates to:
  /// **'You muted {name}. You won\'t see their articles or comments.'**
  String muteDone(String name);

  /// No description provided for @muteUnmuted.
  ///
  /// In en, this message translates to:
  /// **'You unmuted {name}.'**
  String muteUnmuted(String name);

  /// No description provided for @muteBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You muted this writer'**
  String get muteBannerTitle;

  /// No description provided for @muteBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Their articles and comments don\'t show up for you, and nobody else knows you muted them.'**
  String get muteBannerBody;

  /// No description provided for @muteUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get muteUnmute;

  /// No description provided for @muteUnmuteName.
  ///
  /// In en, this message translates to:
  /// **'Unmute {name}'**
  String muteUnmuteName(String name);

  /// No description provided for @muteTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mute topics'**
  String get muteTopicsTitle;

  /// No description provided for @muteTopicsBody.
  ///
  /// In en, this message translates to:
  /// **'What you mute won\'t show up in your feeds, Explore or Search. Unmute it here or in Settings.'**
  String get muteTopicsBody;

  /// No description provided for @muteTopicsField.
  ///
  /// In en, this message translates to:
  /// **'The whole field, with all its topics'**
  String get muteTopicsField;

  /// No description provided for @muteTopicsTopic.
  ///
  /// In en, this message translates to:
  /// **'Just this topic'**
  String get muteTopicsTopic;

  /// No description provided for @muteTopicsToggle.
  ///
  /// In en, this message translates to:
  /// **'Mute {name}'**
  String muteTopicsToggle(String name);

  /// No description provided for @muteCommentCollapsed.
  ///
  /// In en, this message translates to:
  /// **'Comment from someone you muted'**
  String get muteCommentCollapsed;

  /// No description provided for @muteCommentShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get muteCommentShow;

  /// No description provided for @muteSettingsEntry.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get muteSettingsEntry;

  /// No description provided for @muteSettingsEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Writers, fields and topics you muted'**
  String get muteSettingsEntryHint;

  /// No description provided for @mutePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get mutePageTitle;

  /// No description provided for @mutePageWriters.
  ///
  /// In en, this message translates to:
  /// **'Writers'**
  String get mutePageWriters;

  /// No description provided for @mutePageFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get mutePageFields;

  /// No description provided for @mutePageTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get mutePageTopics;

  /// No description provided for @mutePageTopicIn.
  ///
  /// In en, this message translates to:
  /// **'In {field}'**
  String mutePageTopicIn(String field);

  /// No description provided for @mutePageEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t muted anything'**
  String get mutePageEmptyTitle;

  /// No description provided for @mutePageEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Mute a writer, field or topic from any article\'s options and it shows up here.'**
  String get mutePageEmptyBody;

  /// No description provided for @mutePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'They don\'t show up in your feeds, Explore or Search, and nobody knows you muted them.'**
  String get mutePageSubtitle;

  /// No description provided for @muteMenuUser.
  ///
  /// In en, this message translates to:
  /// **'Mute user'**
  String get muteMenuUser;

  /// No description provided for @muteMenuUnmuteUser.
  ///
  /// In en, this message translates to:
  /// **'Unmute user'**
  String get muteMenuUnmuteUser;

  /// No description provided for @muteMenuCommenter.
  ///
  /// In en, this message translates to:
  /// **'Mute commenter'**
  String get muteMenuCommenter;

  /// No description provided for @muteMenuUnmuteCommenter.
  ///
  /// In en, this message translates to:
  /// **'Unmute commenter'**
  String get muteMenuUnmuteCommenter;

  /// No description provided for @errMuteSelf.
  ///
  /// In en, this message translates to:
  /// **'You can\'t mute yourself.'**
  String get errMuteSelf;

  /// No description provided for @errMuteSystemAccount.
  ///
  /// In en, this message translates to:
  /// **'The official ReadIn account can\'t be muted.'**
  String get errMuteSystemAccount;

  /// No description provided for @errMuteLimit.
  ///
  /// In en, this message translates to:
  /// **'You can mute at most 500 writers.'**
  String get errMuteLimit;

  /// No description provided for @errMuteOwnArticle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t do this on your own article.'**
  String get errMuteOwnArticle;

  /// No description provided for @errRepostOwnArticle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t repost your own article.'**
  String get errRepostOwnArticle;

  /// No description provided for @errRepostCaptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Your thoughts must be 500 characters or fewer.'**
  String get errRepostCaptionTooLong;

  /// No description provided for @profileMenu.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get profileMenu;

  /// No description provided for @profileMenuReport.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get profileMenuReport;

  /// No description provided for @profileMenuWarn.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get profileMenuWarn;

  /// No description provided for @profileMenuSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend account'**
  String get profileMenuSuspend;

  /// No description provided for @moderationTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get moderationTitle;

  /// No description provided for @moderationQueueEntry.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get moderationQueueEntry;

  /// No description provided for @moderationWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing waiting for review} =1{1 item waiting for review} other{{count} items waiting for review}}'**
  String moderationWaiting(int count);

  /// No description provided for @moderationNoAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'This page is for moderators'**
  String get moderationNoAccessTitle;

  /// No description provided for @moderationNoAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your account doesn\'t have moderation access.'**
  String get moderationNoAccessBody;

  /// No description provided for @moderationTabOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get moderationTabOpen;

  /// No description provided for @moderationTabResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get moderationTabResolved;

  /// No description provided for @moderationTabDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get moderationTabDismissed;

  /// No description provided for @moderationTabLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get moderationTabLog;

  /// No description provided for @moderationFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get moderationFilterAll;

  /// No description provided for @moderationFilterArticles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get moderationFilterArticles;

  /// No description provided for @moderationFilterComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get moderationFilterComments;

  /// No description provided for @moderationFilterUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get moderationFilterUsers;

  /// No description provided for @moderationEmptyOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'No open reports'**
  String get moderationEmptyOpenTitle;

  /// No description provided for @moderationEmptyOpenBody.
  ///
  /// In en, this message translates to:
  /// **'All clear for now.'**
  String get moderationEmptyOpenBody;

  /// No description provided for @moderationEmptyResolvedTitle.
  ///
  /// In en, this message translates to:
  /// **'No resolved reports'**
  String get moderationEmptyResolvedTitle;

  /// No description provided for @moderationEmptyDismissedTitle.
  ///
  /// In en, this message translates to:
  /// **'No dismissed reports'**
  String get moderationEmptyDismissedTitle;

  /// No description provided for @moderationEmptyLogTitle.
  ///
  /// In en, this message translates to:
  /// **'No moderation actions yet'**
  String get moderationEmptyLogTitle;

  /// No description provided for @moderationLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more.'**
  String get moderationLoadMoreFailed;

  /// No description provided for @moderationTypeArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get moderationTypeArticle;

  /// No description provided for @moderationTypeComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get moderationTypeComment;

  /// No description provided for @moderationTypeUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get moderationTypeUser;

  /// No description provided for @moderationStateHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get moderationStateHidden;

  /// No description provided for @moderationStateDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get moderationStateDeleted;

  /// No description provided for @moderationStateSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get moderationStateSuspended;

  /// No description provided for @moderationStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get moderationStatusOpen;

  /// No description provided for @moderationStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get moderationStatusResolved;

  /// No description provided for @moderationStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get moderationStatusDismissed;

  /// No description provided for @moderationReportCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report} other{{count} reports}}'**
  String moderationReportCount(int count);

  /// No description provided for @moderationLastReport.
  ///
  /// In en, this message translates to:
  /// **'Last report: {time}'**
  String moderationLastReport(String time);

  /// No description provided for @moderationClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed: {time}'**
  String moderationClosed(String time);

  /// No description provided for @moderationCommentOn.
  ///
  /// In en, this message translates to:
  /// **'On “{title}”'**
  String moderationCommentOn(String title);

  /// No description provided for @moderationWarningCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No warnings} =1{1 warning} other{{count} warnings}}'**
  String moderationWarningCount(int count);

  /// No description provided for @moderationSuspendedUntil.
  ///
  /// In en, this message translates to:
  /// **'Suspended until {date}'**
  String moderationSuspendedUntil(String date);

  /// No description provided for @moderationSuspendedForever.
  ///
  /// In en, this message translates to:
  /// **'Permanently suspended'**
  String get moderationSuspendedForever;

  /// No description provided for @moderationCaseArticle.
  ///
  /// In en, this message translates to:
  /// **'Reported article'**
  String get moderationCaseArticle;

  /// No description provided for @moderationCaseComment.
  ///
  /// In en, this message translates to:
  /// **'Reported comment'**
  String get moderationCaseComment;

  /// No description provided for @moderationCaseUser.
  ///
  /// In en, this message translates to:
  /// **'Reported user'**
  String get moderationCaseUser;

  /// No description provided for @moderationOpenArticle.
  ///
  /// In en, this message translates to:
  /// **'Open article'**
  String get moderationOpenArticle;

  /// No description provided for @moderationOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get moderationOpenProfile;

  /// No description provided for @moderationActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get moderationActions;

  /// No description provided for @moderationReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports ({count})'**
  String moderationReportsTitle(int count);

  /// No description provided for @moderationHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get moderationHistory;

  /// No description provided for @moderationHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No actions yet.'**
  String get moderationHistoryEmpty;

  /// No description provided for @moderationClosedBy.
  ///
  /// In en, this message translates to:
  /// **'Closed by {name}'**
  String moderationClosedBy(String name);

  /// No description provided for @moderationHideComment.
  ///
  /// In en, this message translates to:
  /// **'Hide comment'**
  String get moderationHideComment;

  /// No description provided for @moderationUnhideComment.
  ///
  /// In en, this message translates to:
  /// **'Unhide comment'**
  String get moderationUnhideComment;

  /// No description provided for @moderationDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get moderationDeleteComment;

  /// No description provided for @moderationWarnAuthor.
  ///
  /// In en, this message translates to:
  /// **'Warn author'**
  String get moderationWarnAuthor;

  /// No description provided for @moderationSuspendAuthor.
  ///
  /// In en, this message translates to:
  /// **'Suspend author'**
  String get moderationSuspendAuthor;

  /// No description provided for @moderationUnsuspend.
  ///
  /// In en, this message translates to:
  /// **'Lift suspension'**
  String get moderationUnsuspend;

  /// No description provided for @moderationDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss reports'**
  String get moderationDismiss;

  /// No description provided for @moderationHideArticleTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide this article?'**
  String get moderationHideArticleTitle;

  /// No description provided for @moderationHideArticleBody.
  ///
  /// In en, this message translates to:
  /// **'It disappears from feeds, lists and search, and only its author and moderators can open it. The author is notified.'**
  String get moderationHideArticleBody;

  /// No description provided for @moderationHideCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide this comment?'**
  String get moderationHideCommentTitle;

  /// No description provided for @moderationHideCommentBody.
  ///
  /// In en, this message translates to:
  /// **'Readers see “Hidden by moderators” in its place.'**
  String get moderationHideCommentBody;

  /// No description provided for @moderationNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get moderationNoteOptional;

  /// No description provided for @moderationNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get moderationNoteLabel;

  /// No description provided for @moderationNoteForUser.
  ///
  /// In en, this message translates to:
  /// **'They\'ll see this note.'**
  String get moderationNoteForUser;

  /// No description provided for @moderationWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Warn {name}'**
  String moderationWarnTitle(String name);

  /// No description provided for @moderationWarnBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll get a warning with your note and must acknowledge it.'**
  String get moderationWarnBody;

  /// No description provided for @moderationWarnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send warning'**
  String get moderationWarnConfirm;

  /// No description provided for @moderationSuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend {name}'**
  String moderationSuspendTitle(String name);

  /// No description provided for @moderationSuspendBody.
  ///
  /// In en, this message translates to:
  /// **'They can\'t sign in or use their account until the suspension ends.'**
  String get moderationSuspendBody;

  /// No description provided for @moderationSuspendDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get moderationSuspendDuration;

  /// No description provided for @moderationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String moderationDays(int count);

  /// No description provided for @moderationPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanently'**
  String get moderationPermanent;

  /// No description provided for @moderationSuspendConfirm.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get moderationSuspendConfirm;

  /// No description provided for @moderationUnsuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Lift {name}\'s suspension?'**
  String moderationUnsuspendTitle(String name);

  /// No description provided for @moderationUnsuspendBody.
  ///
  /// In en, this message translates to:
  /// **'They can sign in and use their account again right away.'**
  String get moderationUnsuspendBody;

  /// No description provided for @moderationDismissTitle.
  ///
  /// In en, this message translates to:
  /// **'Dismiss these reports?'**
  String get moderationDismissTitle;

  /// No description provided for @moderationDismissBody.
  ///
  /// In en, this message translates to:
  /// **'The open reports are closed as dismissed. The content stays as it is.'**
  String get moderationDismissBody;

  /// No description provided for @moderationArticleHidden.
  ///
  /// In en, this message translates to:
  /// **'Article hidden'**
  String get moderationArticleHidden;

  /// No description provided for @moderationArticleUnhidden.
  ///
  /// In en, this message translates to:
  /// **'Article visible again'**
  String get moderationArticleUnhidden;

  /// No description provided for @moderationWarned.
  ///
  /// In en, this message translates to:
  /// **'Warning sent'**
  String get moderationWarned;

  /// No description provided for @moderationSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get moderationSuspended;

  /// No description provided for @moderationUnsuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspension lifted'**
  String get moderationUnsuspended;

  /// No description provided for @moderationDismissed.
  ///
  /// In en, this message translates to:
  /// **'Reports dismissed'**
  String get moderationDismissed;

  /// No description provided for @moderationLogCommentHide.
  ///
  /// In en, this message translates to:
  /// **'Hid a comment'**
  String get moderationLogCommentHide;

  /// No description provided for @moderationLogCommentUnhide.
  ///
  /// In en, this message translates to:
  /// **'Unhid a comment'**
  String get moderationLogCommentUnhide;

  /// No description provided for @moderationLogCommentDelete.
  ///
  /// In en, this message translates to:
  /// **'Deleted a comment'**
  String get moderationLogCommentDelete;

  /// No description provided for @moderationLogArticleHide.
  ///
  /// In en, this message translates to:
  /// **'Hid an article'**
  String get moderationLogArticleHide;

  /// No description provided for @moderationLogArticleUnhide.
  ///
  /// In en, this message translates to:
  /// **'Unhid an article'**
  String get moderationLogArticleUnhide;

  /// No description provided for @moderationLogUserWarn.
  ///
  /// In en, this message translates to:
  /// **'Warned a user'**
  String get moderationLogUserWarn;

  /// No description provided for @moderationLogUserSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspended an account'**
  String get moderationLogUserSuspend;

  /// No description provided for @moderationLogUserUnsuspend.
  ///
  /// In en, this message translates to:
  /// **'Lifted a suspension'**
  String get moderationLogUserUnsuspend;

  /// No description provided for @moderationLogReportsDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismissed reports'**
  String get moderationLogReportsDismiss;

  /// No description provided for @moderationLogOther.
  ///
  /// In en, this message translates to:
  /// **'Moderation action'**
  String get moderationLogOther;

  /// No description provided for @moderationLogReportsClosed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Closed 1 report} other{Closed {count} reports}}'**
  String moderationLogReportsClosed(int count);

  /// No description provided for @moderationLogUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String moderationLogUntil(String date);

  /// No description provided for @noticeWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'You received a warning from the moderation team'**
  String get noticeWarningTitle;

  /// No description provided for @noticeWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Please read the note and keep to ReadIn\'s community rules.'**
  String get noticeWarningBody;

  /// No description provided for @noticeArticleHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Your article “{title}” was hidden'**
  String noticeArticleHiddenTitle(String title);

  /// No description provided for @noticeArticleHiddenBody.
  ///
  /// In en, this message translates to:
  /// **'Readers can\'t see it anymore. Only you and the moderators can open it.'**
  String get noticeArticleHiddenBody;

  /// No description provided for @noticeNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Moderator\'s note'**
  String get noticeNoteLabel;

  /// No description provided for @noticeAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get noticeAcknowledge;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsNewItems.
  ///
  /// In en, this message translates to:
  /// **'New notifications — show them'**
  String get notificationsNewItems;

  /// No description provided for @notificationsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsToday;

  /// No description provided for @notificationsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notificationsEarlier;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Replies, mentions, new followers and today\'s article show up here.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationsUnreadDot.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsUnreadDot;

  /// No description provided for @notifNewFollower.
  ///
  /// In en, this message translates to:
  /// **'{others, plural, =0{{name} started following you} =1{{name} and 1 other started following you} other{{name} and {others} others started following you}}'**
  String notifNewFollower(String name, int others);

  /// No description provided for @notifArticleComment.
  ///
  /// In en, this message translates to:
  /// **'{others, plural, =0{{name} commented on your article} =1{{name} and 1 other commented on your article} other{{name} and {others} others commented on your article}}'**
  String notifArticleComment(String name, int others);

  /// No description provided for @notifCommentReply.
  ///
  /// In en, this message translates to:
  /// **'{others, plural, =0{{name} replied to your comment} =1{{name} and 1 other replied to your comment} other{{name} and {others} others replied to your comment}}'**
  String notifCommentReply(String name, int others);

  /// No description provided for @notifMention.
  ///
  /// In en, this message translates to:
  /// **'{others, plural, =0{{name} mentioned you in a comment} =1{{name} and 1 other mentioned you in a comment} other{{name} and {others} others mentioned you in a comment}}'**
  String notifMention(String name, int others);

  /// No description provided for @notifMentionArticle.
  ///
  /// In en, this message translates to:
  /// **'{name} mentioned you in an article'**
  String notifMentionArticle(String name);

  /// No description provided for @notifFollowedWriterArticle.
  ///
  /// In en, this message translates to:
  /// **'{name} published a new article'**
  String notifFollowedWriterArticle(String name);

  /// No description provided for @notifReactionsMilestone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your article got its first reaction 🎉} other{Your article reached {count} reactions 🎉}}'**
  String notifReactionsMilestone(int count);

  /// No description provided for @notifReactionsMilestoneGeneric.
  ///
  /// In en, this message translates to:
  /// **'Readers are reacting to your article 🎉'**
  String get notifReactionsMilestoneGeneric;

  /// No description provided for @notifDailyArticle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s article is ready ☕'**
  String get notifDailyArticle;

  /// No description provided for @notifStreakReminder.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Read an article today to keep your 1-day streak 🔥} other{Read an article today to keep your {days}-day streak 🔥}}'**
  String notifStreakReminder(int days);

  /// No description provided for @notifStreakReminderGeneric.
  ///
  /// In en, this message translates to:
  /// **'Read an article today to keep your streak 🔥'**
  String get notifStreakReminderGeneric;

  /// No description provided for @notifSecurityPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password was changed'**
  String get notifSecurityPasswordChanged;

  /// No description provided for @notifSecurityPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Your password was reset'**
  String get notifSecurityPasswordReset;

  /// No description provided for @notifSecurityRecoveryPinChanged.
  ///
  /// In en, this message translates to:
  /// **'Your recovery PIN was changed'**
  String get notifSecurityRecoveryPinChanged;

  /// No description provided for @notifSecurityPhoneNumberChanged.
  ///
  /// In en, this message translates to:
  /// **'Your phone number was changed'**
  String get notifSecurityPhoneNumberChanged;

  /// No description provided for @notifSecurityRecoveryLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Account recovery was locked after too many wrong PINs'**
  String get notifSecurityRecoveryLockedOut;

  /// No description provided for @notifSecurityExternalLoginLinked.
  ///
  /// In en, this message translates to:
  /// **'A Google or Apple account was linked to your account'**
  String get notifSecurityExternalLoginLinked;

  /// No description provided for @notifSecurityExternalLoginUnlinked.
  ///
  /// In en, this message translates to:
  /// **'A Google or Apple account was unlinked from your account'**
  String get notifSecurityExternalLoginUnlinked;

  /// No description provided for @notifSecurityPhoneSignInAdded.
  ///
  /// In en, this message translates to:
  /// **'A phone number and password were added to your account'**
  String get notifSecurityPhoneSignInAdded;

  /// No description provided for @notifSecurityGeneric.
  ///
  /// In en, this message translates to:
  /// **'There was a security change on your account'**
  String get notifSecurityGeneric;

  /// No description provided for @notifSecurityHint.
  ///
  /// In en, this message translates to:
  /// **'If this wasn\'t you, change your password now.'**
  String get notifSecurityHint;

  /// No description provided for @notifVerificationResult.
  ///
  /// In en, this message translates to:
  /// **'There\'s an update on your verification request'**
  String get notifVerificationResult;

  /// No description provided for @notifVerificationApproved.
  ///
  /// In en, this message translates to:
  /// **'You\'re now a verified writer ✓'**
  String get notifVerificationApproved;

  /// No description provided for @notifVerificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Your verification request wasn\'t approved'**
  String get notifVerificationRejected;

  /// No description provided for @notifVerificationRejectedHint.
  ///
  /// In en, this message translates to:
  /// **'Open it to see why'**
  String get notifVerificationRejectedHint;

  /// No description provided for @notifModerationWarning.
  ///
  /// In en, this message translates to:
  /// **'You received a warning from the moderation team'**
  String get notifModerationWarning;

  /// No description provided for @notifModerationArticleHidden.
  ///
  /// In en, this message translates to:
  /// **'The moderators hid your article'**
  String get notifModerationArticleHidden;

  /// No description provided for @notifGeneric.
  ///
  /// In en, this message translates to:
  /// **'You have a new notification'**
  String get notifGeneric;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Push, in app or off for each type, and quiet hours'**
  String get notificationSettingsEntryHint;

  /// No description provided for @notificationSettingsTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'What reaches you'**
  String get notificationSettingsTypesTitle;

  /// No description provided for @notificationSettingsTypesHint.
  ///
  /// In en, this message translates to:
  /// **'Push notifications show up in your notification center too.'**
  String get notificationSettingsTypesHint;

  /// No description provided for @notificationModeAll.
  ///
  /// In en, this message translates to:
  /// **'Push + in app'**
  String get notificationModeAll;

  /// No description provided for @notificationModeInApp.
  ///
  /// In en, this message translates to:
  /// **'In app only'**
  String get notificationModeInApp;

  /// No description provided for @notificationModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notificationModeOff;

  /// No description provided for @notificationModeAllShort.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get notificationModeAllShort;

  /// No description provided for @notificationModeInAppShort.
  ///
  /// In en, this message translates to:
  /// **'In app'**
  String get notificationModeInAppShort;

  /// No description provided for @notificationTypeNewFollower.
  ///
  /// In en, this message translates to:
  /// **'New followers'**
  String get notificationTypeNewFollower;

  /// No description provided for @notificationTypeArticleComment.
  ///
  /// In en, this message translates to:
  /// **'Comments on your articles'**
  String get notificationTypeArticleComment;

  /// No description provided for @notificationTypeCommentReply.
  ///
  /// In en, this message translates to:
  /// **'Replies to your comments'**
  String get notificationTypeCommentReply;

  /// No description provided for @notificationTypeMention.
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get notificationTypeMention;

  /// No description provided for @notificationTypeMentionHint.
  ///
  /// In en, this message translates to:
  /// **'When someone mentions you in a comment or an article'**
  String get notificationTypeMentionHint;

  /// No description provided for @notificationTypeReactionsMilestone.
  ///
  /// In en, this message translates to:
  /// **'Reaction milestones (10, 50, 100)'**
  String get notificationTypeReactionsMilestone;

  /// No description provided for @notificationTypeFollowedWriterArticle.
  ///
  /// In en, this message translates to:
  /// **'New articles from writers you follow'**
  String get notificationTypeFollowedWriterArticle;

  /// No description provided for @notificationTypeDailyArticle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s article'**
  String get notificationTypeDailyArticle;

  /// No description provided for @notificationTypeStreakReminder.
  ///
  /// In en, this message translates to:
  /// **'Streak reminder (8 PM)'**
  String get notificationTypeStreakReminder;

  /// No description provided for @notificationSecurityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Security alerts'**
  String get notificationSecurityAlerts;

  /// No description provided for @notificationSecurityAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'Always on, even in quiet hours.'**
  String get notificationSecurityAlertsHint;

  /// No description provided for @quietHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHoursTitle;

  /// No description provided for @quietHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Pushes wait until quiet hours end. Security alerts arrive right away.'**
  String get quietHoursHint;

  /// No description provided for @quietHoursSwitch.
  ///
  /// In en, this message translates to:
  /// **'Hold pushes during these hours'**
  String get quietHoursSwitch;

  /// No description provided for @quietHoursFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get quietHoursFrom;

  /// No description provided for @quietHoursTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get quietHoursTo;

  /// No description provided for @errNotificationNotFound.
  ///
  /// In en, this message translates to:
  /// **'This notification is no longer available.'**
  String get errNotificationNotFound;

  /// No description provided for @errNotificationTypeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That notification type doesn\'t exist.'**
  String get errNotificationTypeInvalid;

  /// No description provided for @errNotificationModeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Pick push, in app or off.'**
  String get errNotificationModeInvalid;

  /// No description provided for @errNotificationQuietHoursInvalid.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours need two different times.'**
  String get errNotificationQuietHoursInvalid;

  /// No description provided for @settingsWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get settingsWriting;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Writer verification'**
  String get verificationTitle;

  /// No description provided for @verificationEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Get the verified writer badge'**
  String get verificationEntryHint;

  /// No description provided for @verificationStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'You\'re a verified writer'**
  String get verificationStatusVerified;

  /// No description provided for @verificationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Your request is under review'**
  String get verificationStatusPending;

  /// No description provided for @verificationStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved, open it to see why'**
  String get verificationStatusRejected;

  /// No description provided for @verificationIntro.
  ///
  /// In en, this message translates to:
  /// **'Verified writers get a badge next to their name on their articles, profile and comments. Tell us what you do and show us some proof.'**
  String get verificationIntro;

  /// No description provided for @verificationFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get verificationFieldLabel;

  /// No description provided for @verificationFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Pick your field'**
  String get verificationFieldHint;

  /// No description provided for @verificationFieldsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the fields.'**
  String get verificationFieldsFailed;

  /// No description provided for @verificationJobTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get verificationJobTitleLabel;

  /// No description provided for @verificationJobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Senior Backend Engineer'**
  String get verificationJobTitleHint;

  /// No description provided for @verificationProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof'**
  String get verificationProofTitle;

  /// No description provided for @verificationProofHint.
  ///
  /// In en, this message translates to:
  /// **'Add a link, a file, or both.'**
  String get verificationProofHint;

  /// No description provided for @verificationProofUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Link (LinkedIn, GitHub…)'**
  String get verificationProofUrlLabel;

  /// No description provided for @verificationProofFileAdd.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get verificationProofFileAdd;

  /// No description provided for @verificationProofFileHint.
  ///
  /// In en, this message translates to:
  /// **'A certificate or syndicate card: PDF, JPEG, PNG or WebP, up to 10 MB.'**
  String get verificationProofFileHint;

  /// No description provided for @verificationProofFileRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the file'**
  String get verificationProofFileRemove;

  /// No description provided for @verificationProofPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only the reviewers see your file, and it\'s deleted once your request is decided.'**
  String get verificationProofPrivate;

  /// No description provided for @verificationNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get verificationNoteLabel;

  /// No description provided for @verificationNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Anything the reviewers should know'**
  String get verificationNoteHint;

  /// No description provided for @verificationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get verificationSubmit;

  /// No description provided for @verificationSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Sending your request…'**
  String get verificationSubmitting;

  /// No description provided for @verificationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your request is under review'**
  String get verificationPendingTitle;

  /// No description provided for @verificationPendingBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you once it\'s reviewed.'**
  String get verificationPendingBody;

  /// No description provided for @verificationSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Sent on {date}'**
  String verificationSubmittedOn(String date);

  /// No description provided for @verificationLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get verificationLinkLabel;

  /// No description provided for @verificationFileLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get verificationFileLabel;

  /// No description provided for @verificationNoteSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get verificationNoteSummaryLabel;

  /// No description provided for @verificationWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request'**
  String get verificationWithdraw;

  /// No description provided for @verificationWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your request?'**
  String get verificationWithdrawTitle;

  /// No description provided for @verificationWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s deleted along with its file. You can send a new one any time.'**
  String get verificationWithdrawBody;

  /// No description provided for @verificationWithdrawConfirm.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get verificationWithdrawConfirm;

  /// No description provided for @verificationWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Request withdrawn'**
  String get verificationWithdrawn;

  /// No description provided for @verificationApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re a verified writer'**
  String get verificationApprovedTitle;

  /// No description provided for @verificationApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'The verified badge shows next to your name on your articles, profile and comments.'**
  String get verificationApprovedBody;

  /// No description provided for @verificationApprovedOn.
  ///
  /// In en, this message translates to:
  /// **'Verified on {date}'**
  String verificationApprovedOn(String date);

  /// No description provided for @verificationRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your request wasn\'t approved'**
  String get verificationRejectedTitle;

  /// No description provided for @verificationRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Reviewer\'s reason'**
  String get verificationRejectedReason;

  /// No description provided for @verificationRejectedOn.
  ///
  /// In en, this message translates to:
  /// **'Reviewed on {date}'**
  String verificationRejectedOn(String date);

  /// No description provided for @verificationRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'You can fix what\'s missing and request again.'**
  String get verificationRejectedBody;

  /// No description provided for @verificationRequestAgain.
  ///
  /// In en, this message translates to:
  /// **'Request again'**
  String get verificationRequestAgain;

  /// No description provided for @verificationUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t request verification right now'**
  String get verificationUnavailableTitle;

  /// No description provided for @verificationUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'A suspended account can\'t send verification requests.'**
  String get verificationUnavailableBody;

  /// No description provided for @errVerificationProofRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a link or a file as proof.'**
  String get errVerificationProofRequired;

  /// No description provided for @errVerificationProofInvalid.
  ///
  /// In en, this message translates to:
  /// **'The proof file must be a PDF, JPEG, PNG or WebP of 10 MB or less.'**
  String get errVerificationProofInvalid;

  /// No description provided for @errVerificationFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Pick a field from the list.'**
  String get errVerificationFieldInvalid;

  /// No description provided for @errVerificationAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'You already have a request under review.'**
  String get errVerificationAlreadyPending;

  /// No description provided for @errVerificationAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'You\'re already a verified writer.'**
  String get errVerificationAlreadyVerified;

  /// No description provided for @errVerificationNotFound.
  ///
  /// In en, this message translates to:
  /// **'This request isn\'t waiting for review anymore.'**
  String get errVerificationNotFound;

  /// No description provided for @errVerificationNotVerified.
  ///
  /// In en, this message translates to:
  /// **'This user isn\'t verified.'**
  String get errVerificationNotVerified;

  /// No description provided for @errVerificationSystemAccount.
  ///
  /// In en, this message translates to:
  /// **'This is ReadIn\'s official account; its badge stays.'**
  String get errVerificationSystemAccount;

  /// No description provided for @healthDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This information is for awareness only and is not a substitute for a doctor\'s advice.'**
  String get healthDisclaimer;

  /// No description provided for @articleToc.
  ///
  /// In en, this message translates to:
  /// **'In this article'**
  String get articleToc;

  /// No description provided for @settingsSignInForSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save these settings to your account.'**
  String get settingsSignInForSync;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved ✓'**
  String get settingsSaved;

  /// No description provided for @settingsInterests.
  ///
  /// In en, this message translates to:
  /// **'Your interests'**
  String get settingsInterests;

  /// No description provided for @settingsInterestsHint.
  ///
  /// In en, this message translates to:
  /// **'The fields and topics you follow'**
  String get settingsInterestsHint;

  /// No description provided for @interestsPageIntro.
  ///
  /// In en, this message translates to:
  /// **'Tap a field or topic to follow or unfollow it. Changes are saved right away and shape your For you feed.'**
  String get interestsPageIntro;

  /// No description provided for @interestsKeepThree.
  ///
  /// In en, this message translates to:
  /// **'Keep at least 3 interests'**
  String get interestsKeepThree;

  /// No description provided for @imageDarkVersion.
  ///
  /// In en, this message translates to:
  /// **'Dark mode version'**
  String get imageDarkVersion;

  /// No description provided for @imageDarkAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a dark mode version (for diagrams)'**
  String get imageDarkAdd;

  /// No description provided for @imageDarkRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the dark mode version'**
  String get imageDarkRemove;

  /// No description provided for @postReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get postReadMore;

  /// No description provided for @postShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get postShowLess;

  /// No description provided for @postReadFullArticle.
  ///
  /// In en, this message translates to:
  /// **'Read the full article'**
  String get postReadFullArticle;

  /// No description provided for @postReact.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get postReact;

  /// No description provided for @postComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get postComment;

  /// No description provided for @postBarReact.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{React} other{React, {count}}}'**
  String postBarReact(int count);

  /// No description provided for @postBarReacted.
  ///
  /// In en, this message translates to:
  /// **'Reacted: {reaction}, {count}'**
  String postBarReacted(String reaction, int count);

  /// No description provided for @postBarComment.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Comment} other{Comment, {count}}}'**
  String postBarComment(int count);

  /// No description provided for @postBarRepost.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Repost} other{Repost, {count}}}'**
  String postBarRepost(int count);

  /// No description provided for @repostOwnHint.
  ///
  /// In en, this message translates to:
  /// **'You can\'t repost your own article'**
  String get repostOwnHint;

  /// No description provided for @repostLabelOne.
  ///
  /// In en, this message translates to:
  /// **'{name} reposted this'**
  String repostLabelOne(String name);

  /// No description provided for @repostLabelMany.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{name} and 1 other reposted this} other{{name} and {count} others reposted this}}'**
  String repostLabelMany(String name, int count);

  /// No description provided for @repostMenuRepost.
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get repostMenuRepost;

  /// No description provided for @repostMenuWithThoughts.
  ///
  /// In en, this message translates to:
  /// **'Repost with your thoughts'**
  String get repostMenuWithThoughts;

  /// No description provided for @repostMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit your thoughts'**
  String get repostMenuEdit;

  /// No description provided for @repostMenuUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo repost'**
  String get repostMenuUndo;

  /// No description provided for @repostCaptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Repost this article'**
  String get repostCaptionTitle;

  /// No description provided for @repostCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add your thoughts… (optional)'**
  String get repostCaptionHint;

  /// No description provided for @repostCaptionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get repostCaptionSubmit;

  /// No description provided for @repostCaptionReposted.
  ///
  /// In en, this message translates to:
  /// **'You reposted this article.'**
  String get repostCaptionReposted;

  /// No description provided for @repostCaptionSaved.
  ///
  /// In en, this message translates to:
  /// **'Your thoughts were saved.'**
  String get repostCaptionSaved;

  /// No description provided for @commentBoxHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get commentBoxHint;

  /// No description provided for @commentBoxReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a reply…'**
  String get commentBoxReplyHint;

  /// No description provided for @commentBoxEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get commentBoxEmoji;

  /// No description provided for @commentBoxKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Back to the keyboard'**
  String get commentBoxKeyboard;

  /// No description provided for @commentBoxCancelReply.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get commentBoxCancelReply;

  /// No description provided for @commentBoxCancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel editing'**
  String get commentBoxCancelEdit;

  /// No description provided for @commentBoxEmojiSearch.
  ///
  /// In en, this message translates to:
  /// **'Search emoji'**
  String get commentBoxEmojiSearch;

  /// No description provided for @commentBoxEmojiNoRecents.
  ///
  /// In en, this message translates to:
  /// **'Emoji you use show up here'**
  String get commentBoxEmojiNoRecents;

  /// No description provided for @commentRowFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get commentRowFollow;

  /// No description provided for @postOpenArticleHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the article'**
  String get postOpenArticleHint;

  /// No description provided for @postCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover image, opens it full screen'**
  String get postCoverImage;

  /// No description provided for @postMoreTags.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more tag} other{{count} more tags}}'**
  String postMoreTags(int count);

  /// No description provided for @tagOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the tag page'**
  String get tagOpenHint;

  /// No description provided for @tagPageArticleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No articles yet} =1{1 article} other{{count} articles}}'**
  String tagPageArticleCount(int count);

  /// No description provided for @tagPageEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles with this tag yet'**
  String get tagPageEmptyTitle;

  /// No description provided for @tagPageEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Once someone publishes an article with this tag, you\'ll find it here.'**
  String get tagPageEmptyBody;

  /// No description provided for @tagNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This tag doesn\'t exist'**
  String get tagNotFoundTitle;

  /// No description provided for @tagNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed or renamed. Try another tag.'**
  String get tagNotFoundBody;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles, writers, topics and tags'**
  String get searchHint;

  /// No description provided for @searchFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Search ReadIn'**
  String get searchFieldHint;

  /// No description provided for @searchTabArticles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get searchTabArticles;

  /// No description provided for @searchTabWriters.
  ///
  /// In en, this message translates to:
  /// **'Writers'**
  String get searchTabWriters;

  /// No description provided for @searchTabTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get searchTabTopics;

  /// No description provided for @searchTabTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get searchTabTags;

  /// No description provided for @searchRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentTitle;

  /// No description provided for @searchRecentClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchRecentClearAll;

  /// No description provided for @searchRecentRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove “{query}” from recent searches'**
  String searchRecentRemove(String query);

  /// No description provided for @searchIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to read about?'**
  String get searchIdleTitle;

  /// No description provided for @searchIdleBody.
  ///
  /// In en, this message translates to:
  /// **'Search articles, writers, topics and tags, in Arabic or English.'**
  String get searchIdleBody;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”'**
  String searchNoResultsTitle(String query);

  /// No description provided for @searchNoResultsTip.
  ///
  /// In en, this message translates to:
  /// **'Try another word or a shorter one, or look in another tab.'**
  String get searchNoResultsTip;

  /// No description provided for @searchNoResultsFilteredTitle.
  ///
  /// In en, this message translates to:
  /// **'No results with these filters'**
  String get searchNoResultsFilteredTitle;

  /// No description provided for @searchNoResultsFiltersTip.
  ///
  /// In en, this message translates to:
  /// **'Clear the filters to see everything that matches “{query}”.'**
  String searchNoResultsFiltersTip(String query);

  /// No description provided for @searchFoundInPdf.
  ///
  /// In en, this message translates to:
  /// **'Found in the attached PDF'**
  String get searchFoundInPdf;

  /// No description provided for @searchFilterField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get searchFilterField;

  /// No description provided for @searchFilterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Article language'**
  String get searchFilterLanguage;

  /// No description provided for @searchFilterReadingTime.
  ///
  /// In en, this message translates to:
  /// **'Reading time'**
  String get searchFilterReadingTime;

  /// No description provided for @searchFilterValue.
  ///
  /// In en, this message translates to:
  /// **'{filter}: {value}'**
  String searchFilterValue(String filter, String value);

  /// No description provided for @searchFieldAll.
  ///
  /// In en, this message translates to:
  /// **'All fields'**
  String get searchFieldAll;

  /// No description provided for @searchLanguageAny.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get searchLanguageAny;

  /// No description provided for @searchReadingTimeAny.
  ///
  /// In en, this message translates to:
  /// **'Any length'**
  String get searchReadingTimeAny;

  /// No description provided for @searchReadingTimeUpTo5.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 min'**
  String get searchReadingTimeUpTo5;

  /// No description provided for @searchReadingTime5To10.
  ///
  /// In en, this message translates to:
  /// **'5–10 min'**
  String get searchReadingTime5To10;

  /// No description provided for @searchReadingTimeOver10.
  ///
  /// In en, this message translates to:
  /// **'Over 10 min'**
  String get searchReadingTimeOver10;

  /// No description provided for @searchClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get searchClearFilters;

  /// No description provided for @searchKindField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get searchKindField;

  /// No description provided for @exploreFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get exploreFields;

  /// No description provided for @exploreTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending this week'**
  String get exploreTrending;

  /// No description provided for @exploreMostSaved.
  ///
  /// In en, this message translates to:
  /// **'Most saved'**
  String get exploreMostSaved;

  /// No description provided for @exploreNewWriters.
  ///
  /// In en, this message translates to:
  /// **'New writers'**
  String get exploreNewWriters;

  /// No description provided for @exploreFeaturedPaths.
  ///
  /// In en, this message translates to:
  /// **'Featured paths'**
  String get exploreFeaturedPaths;

  /// No description provided for @exploreSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get exploreSeeAll;

  /// No description provided for @exploreSeeAllSection.
  ///
  /// In en, this message translates to:
  /// **'See all: {section}'**
  String exploreSeeAllSection(String section);

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to explore yet'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Fields, articles, writers and paths show up here once people start publishing.'**
  String get exploreEmptyBody;

  /// No description provided for @exploreTrendingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing is trending this week yet'**
  String get exploreTrendingEmptyTitle;

  /// No description provided for @exploreMostSavedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved articles yet'**
  String get exploreMostSavedEmptyTitle;

  /// No description provided for @exploreRankingEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Check back soon, or browse the fields on Explore.'**
  String get exploreRankingEmptyBody;

  /// No description provided for @fieldArticleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String fieldArticleCount(int count);

  /// No description provided for @fieldFollowerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 follower} other{{count} followers}}'**
  String fieldFollowerCount(int count);

  /// No description provided for @fieldFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow field'**
  String get fieldFollow;

  /// No description provided for @fieldFollowTopic.
  ///
  /// In en, this message translates to:
  /// **'Follow topic'**
  String get fieldFollowTopic;

  /// No description provided for @fieldKeepThree.
  ///
  /// In en, this message translates to:
  /// **'Keep at least 3 interests. Follow another field or topic first.'**
  String get fieldKeepThree;

  /// No description provided for @fieldTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics in this field'**
  String get fieldTopics;

  /// No description provided for @fieldTopWriters.
  ///
  /// In en, this message translates to:
  /// **'Top writers in this field'**
  String get fieldTopWriters;

  /// No description provided for @fieldArticles.
  ///
  /// In en, this message translates to:
  /// **'Latest articles'**
  String get fieldArticles;

  /// No description provided for @fieldEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles in this field yet'**
  String get fieldEmptyTitle;

  /// No description provided for @fieldEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Follow it and you\'ll see new articles as soon as they\'re published.'**
  String get fieldEmptyBody;

  /// No description provided for @fieldTopicEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles in this topic yet'**
  String get fieldTopicEmptyTitle;

  /// No description provided for @fieldNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This field doesn\'t exist'**
  String get fieldNotFoundTitle;

  /// No description provided for @fieldNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed, or the link is wrong.'**
  String get fieldNotFoundBody;

  /// No description provided for @fieldGoToExplore.
  ///
  /// In en, this message translates to:
  /// **'Browse other fields'**
  String get fieldGoToExplore;

  /// No description provided for @fieldTopicNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This topic doesn\'t exist'**
  String get fieldTopicNotFoundTitle;

  /// No description provided for @fieldTopicNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It isn\'t one of the topics of {field}, or it was removed.'**
  String fieldTopicNotFoundBody(String field);

  /// No description provided for @fieldShowAllArticles.
  ///
  /// In en, this message translates to:
  /// **'All articles in this field'**
  String get fieldShowAllArticles;

  /// No description provided for @errInterestsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Some fields or topics don\'t exist.'**
  String get errInterestsUnknown;

  /// No description provided for @errTopicNotFound.
  ///
  /// In en, this message translates to:
  /// **'Topic not found.'**
  String get errTopicNotFound;

  /// No description provided for @errTopicNotInField.
  ///
  /// In en, this message translates to:
  /// **'The topic doesn\'t belong to this field.'**
  String get errTopicNotInField;

  /// No description provided for @errArticleNotOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the author can change this article.'**
  String get errArticleNotOwner;

  /// No description provided for @errArticleStatusInvalid.
  ///
  /// In en, this message translates to:
  /// **'Status must be draft or published.'**
  String get errArticleStatusInvalid;

  /// No description provided for @errArticleNoContent.
  ///
  /// In en, this message translates to:
  /// **'The article is empty. Write something first.'**
  String get errArticleNoContent;

  /// No description provided for @errArticleInvalidTransition.
  ///
  /// In en, this message translates to:
  /// **'You can\'t do that while the article is in this state.'**
  String get errArticleInvalidTransition;

  /// No description provided for @errArticleSlugTaken.
  ///
  /// In en, this message translates to:
  /// **'That link is already used by another article.'**
  String get errArticleSlugTaken;

  /// No description provided for @errArticleTagsMaxFive.
  ///
  /// In en, this message translates to:
  /// **'An article can have at most 5 tags.'**
  String get errArticleTagsMaxFive;

  /// No description provided for @errArticleTooManyTags.
  ///
  /// In en, this message translates to:
  /// **'An article can have at most 5 tags.'**
  String get errArticleTooManyTags;

  /// No description provided for @errTagNotFound.
  ///
  /// In en, this message translates to:
  /// **'Tag not found.'**
  String get errTagNotFound;

  /// No description provided for @errTagInvalid.
  ///
  /// In en, this message translates to:
  /// **'A tag has 2–30 characters: letters, digits, spaces and - _ . + # only.'**
  String get errTagInvalid;

  /// No description provided for @errTagLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve created a lot of new tags today. Pick existing tags, or try again later.'**
  String get errTagLimit;

  /// No description provided for @errTagHidden.
  ///
  /// In en, this message translates to:
  /// **'This tag isn\'t available. Choose another one.'**
  String get errTagHidden;

  /// No description provided for @errArticleLanguageInvalid.
  ///
  /// In en, this message translates to:
  /// **'That article language isn\'t supported.'**
  String get errArticleLanguageInvalid;

  /// No description provided for @errArticleContentLanguageMismatch.
  ///
  /// In en, this message translates to:
  /// **'The content\'s language doesn\'t match the article\'s language.'**
  String get errArticleContentLanguageMismatch;

  /// No description provided for @errConcurrencyConflict.
  ///
  /// In en, this message translates to:
  /// **'Someone else changed this. Refresh and try again.'**
  String get errConcurrencyConflict;

  /// No description provided for @errRequestInvalid.
  ///
  /// In en, this message translates to:
  /// **'The request is invalid.'**
  String get errRequestInvalid;

  /// No description provided for @errRequestTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The request is too large.'**
  String get errRequestTooLarge;

  /// No description provided for @errRequestUnsupportedMediaType.
  ///
  /// In en, this message translates to:
  /// **'This content type is not supported.'**
  String get errRequestUnsupportedMediaType;

  /// No description provided for @errRouteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errRouteNotFound;

  /// No description provided for @errReportStatusInvalid.
  ///
  /// In en, this message translates to:
  /// **'The report status must be open, resolved or dismissed.'**
  String get errReportStatusInvalid;

  /// No description provided for @errSearchQueryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Type 1–100 characters, with at least one letter or digit.'**
  String get errSearchQueryInvalid;

  /// No description provided for @errSearchTypeInvalid.
  ///
  /// In en, this message translates to:
  /// **'The search type must be articles, writers, topics or tags.'**
  String get errSearchTypeInvalid;

  /// No description provided for @errSearchFilterInvalid.
  ///
  /// In en, this message translates to:
  /// **'These search filters aren\'t valid.'**
  String get errSearchFilterInvalid;

  /// No description provided for @profileTabCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get profileTabCategories;

  /// No description provided for @categoriesOther.
  ///
  /// In en, this message translates to:
  /// **'Other articles'**
  String get categoriesOther;

  /// No description provided for @categoryArticleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No articles yet} =1{1 article} other{{count} articles}}'**
  String categoryArticleCount(int count);

  /// No description provided for @categoryOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the category'**
  String get categoryOpenHint;

  /// No description provided for @categoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoriesEmptyTitle;

  /// No description provided for @categoriesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When this writer groups their articles into categories, you\'ll find them here.'**
  String get categoriesEmptyBody;

  /// No description provided for @categoriesOwnHint.
  ///
  /// In en, this message translates to:
  /// **'Group your articles into categories. Your profile shows them in this order.'**
  String get categoriesOwnHint;

  /// No description provided for @categoryNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryNew;

  /// No description provided for @categoriesFull.
  ///
  /// In en, this message translates to:
  /// **'You have 50 categories, the most you can have. Delete one to add another.'**
  String get categoriesFull;

  /// No description provided for @categoriesEmptyOwnTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your articles'**
  String get categoriesEmptyOwnTitle;

  /// No description provided for @categoriesEmptyOwnBody.
  ///
  /// In en, this message translates to:
  /// **'Create categories like “Backend tips”, then put your articles in them from the editor. Readers see them on your profile.'**
  String get categoriesEmptyOwnBody;

  /// No description provided for @categoryEmptyOwn.
  ///
  /// In en, this message translates to:
  /// **'Empty: visitors don\'t see it'**
  String get categoryEmptyOwn;

  /// No description provided for @categoryRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename category'**
  String get categoryRenameTitle;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Backend tips'**
  String get categoryNameHint;

  /// No description provided for @categoryNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'A category name has at most 40 characters.'**
  String get categoryNameTooLong;

  /// No description provided for @categoryNameNoLetter.
  ///
  /// In en, this message translates to:
  /// **'A category name needs at least one letter or digit.'**
  String get categoryNameNoLetter;

  /// No description provided for @categoryMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get categoryMoveUp;

  /// No description provided for @categoryMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get categoryMoveDown;

  /// No description provided for @categoryDragHandle.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get categoryDragHandle;

  /// No description provided for @categoryMenu.
  ///
  /// In en, this message translates to:
  /// **'Category options'**
  String get categoryMenu;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String categoryDeleteTitle(String name);

  /// No description provided for @categoryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{This category is empty.} =1{This category has 1 article. It stays published, without a category.} other{This category has {count} articles. They stay published, without a category.}}'**
  String categoryDeleteBody(int count);

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// No description provided for @categoryPageEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles in this category yet'**
  String get categoryPageEmptyTitle;

  /// No description provided for @categoryPageEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Once the writer adds articles to it, you\'ll find them here.'**
  String get categoryPageEmptyBody;

  /// No description provided for @categoryOtherEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No articles without a category'**
  String get categoryOtherEmptyTitle;

  /// No description provided for @categoryOtherEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Every article of this writer is in a category.'**
  String get categoryOtherEmptyBody;

  /// No description provided for @categoryNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This category doesn\'t exist'**
  String get categoryNotFoundTitle;

  /// No description provided for @categoryNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted, or the link is wrong.'**
  String get categoryNotFoundBody;

  /// No description provided for @categoryWriterProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to the writer\'s profile'**
  String get categoryWriterProfile;

  /// No description provided for @articleInCategory.
  ///
  /// In en, this message translates to:
  /// **'In {name}'**
  String articleInCategory(String name);

  /// No description provided for @editorCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get editorCategoryLabel;

  /// No description provided for @editorCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get editorCategoryNone;

  /// No description provided for @editorCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: groups the article with others on your profile. A change applies right away.'**
  String get editorCategoryHint;

  /// No description provided for @editorCategoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your categories.'**
  String get editorCategoryLoadFailed;

  /// No description provided for @moderationCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Writer categories'**
  String get moderationCategoriesTitle;

  /// No description provided for @moderationCategoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories.'**
  String get moderationCategoriesEmpty;

  /// No description provided for @moderationClearCategory.
  ///
  /// In en, this message translates to:
  /// **'Clear name'**
  String get moderationClearCategory;

  /// No description provided for @moderationClearCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the category name “{name}”?'**
  String moderationClearCategoryTitle(String name);

  /// No description provided for @moderationClearCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'The category gets a neutral name like “Category 1”, and its old link stops working. Its articles stay in it, and the writer isn\'t notified.'**
  String get moderationClearCategoryBody;

  /// No description provided for @moderationCategoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Category name cleared'**
  String get moderationCategoryCleared;

  /// No description provided for @moderationLogUserClearCategory.
  ///
  /// In en, this message translates to:
  /// **'Cleared a category name'**
  String get moderationLogUserClearCategory;

  /// No description provided for @errCategoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Category not found.'**
  String get errCategoryNotFound;

  /// No description provided for @errCategoryNotOwner.
  ///
  /// In en, this message translates to:
  /// **'This category isn\'t yours.'**
  String get errCategoryNotOwner;

  /// No description provided for @errCategoryLimit.
  ///
  /// In en, this message translates to:
  /// **'You can have at most 50 categories.'**
  String get errCategoryLimit;

  /// No description provided for @errCategoryNameTaken.
  ///
  /// In en, this message translates to:
  /// **'You already have a category with this name.'**
  String get errCategoryNameTaken;

  /// No description provided for @errCategoryNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'A category name has 1–40 characters, with at least one letter or digit.'**
  String get errCategoryNameInvalid;

  /// No description provided for @meMenu.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get meMenu;

  /// No description provided for @meViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get meViewProfile;

  /// No description provided for @meArticlesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Articles this week'**
  String get meArticlesThisWeek;

  /// No description provided for @meMinutesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Minutes this week'**
  String get meMinutesThisWeek;

  /// No description provided for @themeSwitchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get themeSwitchToDark;

  /// No description provided for @themeSwitchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get themeSwitchToLight;

  /// No description provided for @searchPillHint.
  ///
  /// In en, this message translates to:
  /// **'Search articles, writers…'**
  String get searchPillHint;

  /// No description provided for @startPostHint.
  ///
  /// In en, this message translates to:
  /// **'Start a post…'**
  String get startPostHint;

  /// No description provided for @startPostPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get startPostPhoto;

  /// No description provided for @startPostPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get startPostPdf;

  /// No description provided for @startPostArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get startPostArticle;

  /// No description provided for @suggestedWritersFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to your feed'**
  String get suggestedWritersFeedTitle;

  /// No description provided for @suggestedPathTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested path'**
  String get suggestedPathTitle;

  /// No description provided for @highlightAction.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get highlightAction;

  /// No description provided for @highlightRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove highlight'**
  String get highlightRemove;

  /// No description provided for @highlightCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reader highlighted this} other{{count} readers highlighted this}}'**
  String highlightCount(int count);

  /// No description provided for @highlightAdded.
  ///
  /// In en, this message translates to:
  /// **'Highlighted'**
  String get highlightAdded;

  /// No description provided for @highlightRemoved.
  ///
  /// In en, this message translates to:
  /// **'Highlight removed'**
  String get highlightRemoved;

  /// No description provided for @highlightMenuHide.
  ///
  /// In en, this message translates to:
  /// **'Hide highlights'**
  String get highlightMenuHide;

  /// No description provided for @highlightMenuShow.
  ///
  /// In en, this message translates to:
  /// **'Show highlights'**
  String get highlightMenuShow;

  /// No description provided for @highlightSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Show highlights'**
  String get highlightSettingTitle;

  /// No description provided for @highlightSettingHint.
  ///
  /// In en, this message translates to:
  /// **'Your highlights and the sentences many readers marked, in articles.'**
  String get highlightSettingHint;

  /// No description provided for @highlightSavedTab.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlightSavedTab;

  /// No description provided for @highlightSavedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No highlights yet'**
  String get highlightSavedEmptyTitle;

  /// No description provided for @highlightSavedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Select a sentence in an article and tap Highlight to keep it here.'**
  String get highlightSavedEmptyBody;

  /// No description provided for @highlightSavedOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the article at this highlight'**
  String get highlightSavedOpen;

  /// No description provided for @highlightSavedVersionAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic version'**
  String get highlightSavedVersionAr;

  /// No description provided for @highlightSavedVersionEn.
  ///
  /// In en, this message translates to:
  /// **'English version'**
  String get highlightSavedVersionEn;

  /// No description provided for @errHighlightTextMismatch.
  ///
  /// In en, this message translates to:
  /// **'This text has changed in the article. Reload and try again.'**
  String get errHighlightTextMismatch;

  /// No description provided for @errHighlightBlockNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This part can\'t be highlighted.'**
  String get errHighlightBlockNotAllowed;

  /// No description provided for @errHighlightTooShort.
  ///
  /// In en, this message translates to:
  /// **'Select at least 3 characters.'**
  String get errHighlightTooShort;

  /// No description provided for @errHighlightTooLong.
  ///
  /// In en, this message translates to:
  /// **'A highlight can be at most 1,000 characters.'**
  String get errHighlightTooLong;

  /// No description provided for @errHighlightLimit.
  ///
  /// In en, this message translates to:
  /// **'You can have at most 100 highlights in one article.'**
  String get errHighlightLimit;

  /// No description provided for @errHighlightNotFound.
  ///
  /// In en, this message translates to:
  /// **'Highlight not found.'**
  String get errHighlightNotFound;

  /// No description provided for @quoteCardAction.
  ///
  /// In en, this message translates to:
  /// **'Share quote'**
  String get quoteCardAction;

  /// No description provided for @quoteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Share quote'**
  String get quoteCardTitle;

  /// No description provided for @quoteCardHint.
  ///
  /// In en, this message translates to:
  /// **'A picture of your selection for social media, with the article link.'**
  String get quoteCardHint;

  /// No description provided for @quoteCardThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Card colors'**
  String get quoteCardThemeLabel;

  /// No description provided for @quoteCardFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Card size'**
  String get quoteCardFormatLabel;

  /// No description provided for @quoteCardSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get quoteCardSquare;

  /// No description provided for @quoteCardLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get quoteCardLandscape;

  /// No description provided for @quoteCardShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get quoteCardShare;

  /// No description provided for @quoteCardSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get quoteCardSave;

  /// No description provided for @quoteCardCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get quoteCardCopyLink;

  /// No description provided for @quoteCardLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get quoteCardLinkCopied;

  /// No description provided for @quoteCardCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t copy the link.'**
  String get quoteCardCopyFailed;

  /// No description provided for @quoteCardSaved.
  ///
  /// In en, this message translates to:
  /// **'Card saved.'**
  String get quoteCardSaved;

  /// No description provided for @quoteCardSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save the card. Try again.'**
  String get quoteCardSaveFailed;

  /// No description provided for @quoteCardShareFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open sharing. Try again.'**
  String get quoteCardShareFailed;

  /// No description provided for @quoteCardPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the card…'**
  String get quoteCardPreparing;

  /// No description provided for @quoteCardPreview.
  ///
  /// In en, this message translates to:
  /// **'Quote card: {quote}'**
  String quoteCardPreview(String quote);

  /// No description provided for @quoteCardRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get quoteCardRetry;

  /// No description provided for @errQuoteCardNotFound.
  ///
  /// In en, this message translates to:
  /// **'Article not found.'**
  String get errQuoteCardNotFound;

  /// No description provided for @errQuoteCardHidden.
  ///
  /// In en, this message translates to:
  /// **'Moderators hid this article, so its quotes can\'t be shared.'**
  String get errQuoteCardHidden;

  /// No description provided for @errQuoteCardTextMismatch.
  ///
  /// In en, this message translates to:
  /// **'This text has changed in the article. Reload and try again.'**
  String get errQuoteCardTextMismatch;

  /// No description provided for @errQuoteCardBlockNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This part can\'t be shared as a quote.'**
  String get errQuoteCardBlockNotAllowed;

  /// No description provided for @errQuoteCardTooShort.
  ///
  /// In en, this message translates to:
  /// **'Select at least 3 characters.'**
  String get errQuoteCardTooShort;

  /// No description provided for @errQuoteCardTooLong.
  ///
  /// In en, this message translates to:
  /// **'A quote can be at most 400 characters. Select less text.'**
  String get errQuoteCardTooLong;

  /// No description provided for @errQuoteCardLimit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve made many quote cards this hour. Try again later.'**
  String get errQuoteCardLimit;

  /// No description provided for @errQuoteCardBusy.
  ///
  /// In en, this message translates to:
  /// **'Many cards are being prepared right now. Try again in a moment.'**
  String get errQuoteCardBusy;

  /// No description provided for @errQuoteCardFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t prepare the quote card. Try again.'**
  String get errQuoteCardFailed;

  /// No description provided for @errQuoteCardOffline.
  ///
  /// In en, this message translates to:
  /// **'You need an internet connection to make a quote card.'**
  String get errQuoteCardOffline;
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
