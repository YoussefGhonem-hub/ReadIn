import '../domain/entities/explore.dart';

/// Where Explore's pages live (F15): a field page, `/f/{slug}` (`?topic={topicSlug}` selects a chip, the link Search
/// gives topics; its web link https://{domain}/f/{slug} opens it too), and the rankings in full above the tabs,
/// `/explore/trending` and `/explore/most-saved`.
abstract final class ExploreRoutes {
  static const fieldPattern = '/f/:slug';

  /// `/f/{slug}`, or `/f/{slug}?topic={topic}`.
  static String field(String slug, {String? topic}) {
    final path = '/f/${Uri.encodeComponent(slug)}';
    return topic == null || topic.isEmpty ? path : '$path?topic=${Uri.encodeQueryComponent(topic)}';
  }

  /// "See all" of a ranking.
  static String ranking(ExploreRanking ranking) => '/explore/${ranking.path}';

  /// The topic a field page link asks for: `?topic=`, or null.
  static String? topicOf(Uri uri) {
    final topic = uri.queryParameters['topic']?.trim();
    return topic == null || topic.isEmpty ? null : topic;
  }
}
