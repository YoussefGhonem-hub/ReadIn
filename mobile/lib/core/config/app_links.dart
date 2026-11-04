/// Public web links that open in the app via App Links / Universal Links
/// (`readin.app/a/{slug}`, SPEC §3.3 and the Android intent filter).
abstract final class AppLinks {
  static const webOrigin = 'https://readin.app';

  static String article(String slug) => '$webOrigin/a/${Uri.encodeComponent(slug)}';

  /// The public "Delete your account" page (`public/delete-account.html` on Firebase Hosting): what is deleted, and
  /// the email route. "Delete by email instead" opens it in [language] (`ar` | `en`).
  static String accountDeletion(String language) =>
      'https://readin-cca78.firebaseapp.com/delete-account?lang=${language == 'en' ? 'en' : 'ar'}';
}

/// Where "نسيت الـ PIN كمان؟" and suspended accounts are sent (SPEC §9.1): an Admin resets the password. Also the email
/// route to delete an account.
abstract final class SupportContact {
  static const email = 'youssef.fcaih@gmail.com';
}
