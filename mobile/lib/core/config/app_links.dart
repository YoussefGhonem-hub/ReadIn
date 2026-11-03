/// Public web links that open in the app via App Links / Universal Links
/// (`readin.app/a/{slug}`, SPEC §3.3 and the Android intent filter).
abstract final class AppLinks {
  static const webOrigin = 'https://readin.app';

  static String article(String slug) => '$webOrigin/a/${Uri.encodeComponent(slug)}';
}

/// Where "نسيت الـ PIN كمان؟" and suspended accounts are sent (SPEC §9.1): an Admin resets the password.
abstract final class SupportContact {
  static const email = 'youssef.fcaih@gmail.com';
}
