import '../../profile/presentation/profile_routes.dart';

/// Where a writer's category page lives (F31): `/u/{username}/c/{slug}`, under the profile. A slug may hold Arabic
/// letters: links percent-encode it, and go_router hands the page the decoded slug.
abstract final class CategoryRoutes {
  /// The sub-route of `/u/:username`.
  static const subPattern = 'c/:slug';

  /// The reserved slug of "مقالات تانية", the writer's articles without a category. A category's slug never starts with
  /// `_`, so the two never clash.
  static const otherSlug = '_other';

  /// `/u/{username}/c/{slug}`.
  static String of(String username, String slug) => '${ProfileRoutes.of(username)}/c/${Uri.encodeComponent(slug)}';

  /// `/u/{username}/c/_other`.
  static String other(String username) => of(username, otherSlug);
}
