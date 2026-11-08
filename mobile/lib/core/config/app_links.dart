/// Public web links, which open in the app where it is installed (Android App Links, iOS Universal Links; SPEC F24,
/// docs/setup/app-links.md).
///
/// The domain is configuration: the `WEB_ORIGIN` dart-define (`config/prod.json`). `android/app/build.gradle.kts` reads
/// the same value for the App Links intent filter, so the links the app shares and the links it opens always match.
abstract final class AppLinks {
  static const _defaultOrigin = 'https://readin.app';
  static const _configuredOrigin = String.fromEnvironment('WEB_ORIGIN', defaultValue: _defaultOrigin);

  /// `https://{domain}`, without a trailing slash. A value that isn't an https origin falls back to the default (the
  /// Android build refuses one, so a release can't ship with it).
  static final String webOrigin = originOf(_configuredOrigin) ?? _defaultOrigin;

  /// The domain alone, lower case: the only web host whose links the app opens (push_links.dart).
  static final String webHost = Uri.parse(webOrigin).host;

  /// [value] as `https://{host}[:port]`, or null when it isn't an https origin (a path, query or fragment counts as not).
  static String? originOf(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    if (uri.path.replaceAll('/', '').isNotEmpty || uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) return null;
    return uri.hasPort ? 'https://${uri.host}:${uri.port}' : 'https://${uri.host}';
  }

  /// The web's address of an article in the version [language] (`ar-EG` | `en`): `https://{domain}/{ar|en}/a/{slug}`,
  /// the web's canonical URL (SPEC §23). Shared from the reader and the attachment viewer (F24).
  static String article(String slug, {required String language}) =>
      '$webOrigin/${language == 'en' ? 'en' : 'ar'}/a/${Uri.encodeComponent(slug)}';

  /// A legal page of the web (F37: `/terms`, `/community-guidelines`, `/privacy`, bilingual), in [language]
  /// (`ar` | `en`).
  static String legalPage(String path, {required String language}) =>
      '$webOrigin${path.startsWith('/') ? path : '/$path'}?lang=${language == 'en' ? 'en' : 'ar'}';

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
