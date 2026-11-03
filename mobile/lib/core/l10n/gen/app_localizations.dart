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

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Short, reviewed articles in Arabic and English — one picked for you every day, in the field you love.'**
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

  /// No description provided for @profilePathsTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning paths are coming'**
  String get profilePathsTitle;

  /// No description provided for @profilePathsBody.
  ///
  /// In en, this message translates to:
  /// **'Hand-picked series of articles to learn a topic step by step. We\'re building them now.'**
  String get profilePathsBody;

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
  /// **'Your profile: name, @username, photo, bio and links'**
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
  /// **'Your interests, reading progress, stats, reactions, saved articles and follows'**
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
  /// **'Reviews and edits you made on other writers\' articles stay with those articles, without your name.'**
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
  /// **'Reading streak: {count} days. You haven\'t read today yet.'**
  String readingStreakNotReadTodaySemantics(int count);

  /// No description provided for @readingStreakFreezePendingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Reading streak: {count} days. You missed yesterday: read today and a freeze keeps your streak.'**
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
  /// **'{count}-day streak!'**
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

  /// No description provided for @commentsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get commentsReportTitle;

  /// No description provided for @commentsReportBody.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting it? Our moderators will review it.'**
  String get commentsReportBody;

  /// No description provided for @commentsReportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get commentsReportSpam;

  /// No description provided for @commentsReportMisinformation.
  ///
  /// In en, this message translates to:
  /// **'Misinformation'**
  String get commentsReportMisinformation;

  /// No description provided for @commentsReportHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get commentsReportHarassment;

  /// No description provided for @commentsReportCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get commentsReportCopyright;

  /// No description provided for @commentsReportOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get commentsReportOther;

  /// No description provided for @commentsReportDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get commentsReportDetails;

  /// No description provided for @commentsReportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get commentsReportSubmit;

  /// No description provided for @commentsReportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we\'ll review it.'**
  String get commentsReportThanks;

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
