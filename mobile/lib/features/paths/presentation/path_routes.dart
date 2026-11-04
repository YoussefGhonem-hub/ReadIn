/// The two tabs of `/paths`.
enum PathsTab { all, mine }

/// Where learning paths live in the app (F09): `/paths` (All paths · My paths) and `/paths/{slug}`.
abstract final class PathRoutes {
  static const list = '/paths';

  /// The list opened on "My paths".
  static const mine = '/paths?tab=mine';

  static String of(String slug) => '/paths/${Uri.encodeComponent(slug)}';

  /// The tab a `/paths` link asks for.
  static PathsTab tabOf(Uri uri) => uri.queryParameters['tab'] == 'mine' ? PathsTab.mine : PathsTab.all;
}
