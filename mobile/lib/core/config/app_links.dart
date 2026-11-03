/// Public web links that open in the app via App Links / Universal Links
/// (`readin.app/a/{slug}`, SPEC §3.3 and the Android intent filter).
abstract final class AppLinks {
  static const webOrigin = 'https://readin.app';

  static String article(String slug) => '$webOrigin/a/${Uri.encodeComponent(slug)}';
}
