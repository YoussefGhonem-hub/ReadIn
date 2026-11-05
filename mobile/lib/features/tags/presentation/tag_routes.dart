/// Where a tag's page lives (F32). A slug may hold Arabic letters: links percent-encode it, and go_router hands the page
/// the decoded slug.
abstract final class TagRoutes {
  static const pattern = '/tags/:slug';

  /// `/tags/{slug}`.
  static String of(String slug) => '/tags/${Uri.encodeComponent(slug)}';
}
