import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../../paths/domain/entities/learning_path.dart';

/// [ar] or [en] for the app's language (`ar` | `en`), as the rest of the app shows fields (`FieldRef.nameFor`): a name
/// keeps up when the language changes in Settings. [loaded] (the API's `name`) when that one is missing.
String _localized(String languageCode, String ar, String en, String loaded) {
  final name = languageCode == 'ar' ? ar : en;
  return name.isNotEmpty ? name : loaded;
}

/// A field tile on Explore (`FieldSummaryDto`, F15): it opens the field page.
class FieldSummary extends Equatable {
  const FieldSummary({
    required this.id,
    required this.slug,
    required this.name,
    this.nameAr = '',
    this.nameEn = '',
    this.icon = 'book-open',
    this.color = 'primary',
    this.articleCount = 0,
  });

  final String id;
  final String slug;

  /// In the UI language (`Accept-Language`).
  final String name;
  final String nameAr;
  final String nameEn;

  /// The Lucide icon name and the color token (mapped by `FieldStyle`).
  final String icon;
  final String color;

  /// Articles readers can see in it, the same for everyone.
  final int articleCount;

  /// The name in the app's current language ([name] is in the language it was loaded in).
  String nameFor(String languageCode) => _localized(languageCode, nameAr, nameEn, name);

  @override
  List<Object?> get props => [id, slug, name, nameAr, nameEn, icon, color, articleCount];
}

/// Every section of Explore in one answer (`ExploreDto`, `GET /explore`). An empty section is hidden.
class ExploreSections extends Equatable {
  const ExploreSections({
    this.fields = const [],
    this.trending = const [],
    this.mostSaved = const [],
    this.newWriters = const [],
    this.featuredPaths = const [],
  });

  /// Every enabled field, in display order.
  final List<FieldSummary> fields;

  /// The first of "Trending this week" (≤ 6).
  final List<ArticleCard> trending;

  /// The first of "Most saved" (≤ 6).
  final List<ArticleCard> mostSaved;

  /// People whose first article came out in the last 30 days (≤ 10), latest first.
  final List<UserSummary> newWriters;

  /// Learning paths flagged featured (≤ 6), in featured order.
  final List<LearningPath> featuredPaths;

  bool get isEmpty =>
      fields.isEmpty && trending.isEmpty && mostSaved.isEmpty && newWriters.isEmpty && featuredPaths.isEmpty;

  @override
  List<Object?> get props => [fields, trending, mostSaved, newWriters, featuredPaths];
}

/// The two article rankings of Explore, each with a full list ("See all").
enum ExploreRanking {
  /// `GET /explore/trending`: the most engagement in the last 7 days, then the quality score.
  trending('trending'),

  /// `GET /explore/most-saved`: the most saves in the last 30 days, then all-time saves.
  mostSaved('most-saved');

  const ExploreRanking(this.path);

  /// The segment of `/explore/{path}`, in the API and in the app's route.
  final String path;

  static ExploreRanking? fromPath(String? value) => values.where((r) => r.path == value).firstOrNull;
}

/// A topic chip of a field page (`FieldPageTopicDto`): it filters the articles, and can be followed.
class FieldTopic extends Equatable {
  const FieldTopic({
    required this.id,
    required this.slug,
    required this.name,
    this.nameAr = '',
    this.nameEn = '',
    this.articleCount = 0,
    this.isFollowing = false,
  });

  /// For `PUT` / `DELETE /me/interests/topics/{id}`.
  final String id;
  final String slug;

  /// In the UI language.
  final String name;
  final String nameAr;
  final String nameEn;
  final int articleCount;

  /// The viewer follows it (false for guests).
  final bool isFollowing;

  /// The name in the app's current language.
  String nameFor(String languageCode) => _localized(languageCode, nameAr, nameEn, name);

  FieldTopic withFollowing(bool following) => FieldTopic(
        id: id,
        slug: slug,
        name: name,
        nameAr: nameAr,
        nameEn: nameEn,
        articleCount: articleCount,
        isFollowing: following,
      );

  @override
  List<Object?> get props => [id, slug, name, nameAr, nameEn, articleCount, isFollowing];
}

/// A field page's header and topic chips (`FieldPageDto`, `GET /fields/{slug}`).
class FieldDetails extends Equatable {
  const FieldDetails({
    required this.id,
    required this.slug,
    required this.name,
    this.nameAr = '',
    this.nameEn = '',
    this.icon = 'book-open',
    this.color = 'primary',
    this.isSensitive = false,
    this.articleCount = 0,
    this.followerCount = 0,
    this.isFollowing = false,
    this.topics = const [],
  });

  /// For `PUT` / `DELETE /me/interests/fields/{id}`.
  final String id;
  final String slug;

  /// In the UI language.
  final String name;
  final String nameAr;
  final String nameEn;
  final String icon;
  final String color;

  /// Medicine, public health: the page shows the health disclaimer.
  final bool isSensitive;

  /// Articles readers can see in it; 0 → the empty state.
  final int articleCount;

  /// People who follow the field itself (a followed topic doesn't count).
  final int followerCount;

  /// The viewer follows the field (false for guests).
  final bool isFollowing;

  /// Every topic, in editorial order, empty ones included.
  final List<FieldTopic> topics;

  /// The name in the app's current language.
  String nameFor(String languageCode) => _localized(languageCode, nameAr, nameEn, name);

  /// The topic of [slug], ignoring case like the API; null for none.
  FieldTopic? topicOf(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    final key = slug.toLowerCase();
    return topics.where((t) => t.slug.toLowerCase() == key).firstOrNull;
  }

  FieldDetails copyWith({bool? isFollowing, int? followerCount, List<FieldTopic>? topics}) => FieldDetails(
        id: id,
        slug: slug,
        name: name,
        nameAr: nameAr,
        nameEn: nameEn,
        icon: icon,
        color: color,
        isSensitive: isSensitive,
        articleCount: articleCount,
        followerCount: followerCount ?? this.followerCount,
        isFollowing: isFollowing ?? this.isFollowing,
        topics: topics ?? this.topics,
      );

  @override
  List<Object?> get props =>
      [id, slug, name, nameAr, nameEn, icon, color, isSensitive, articleCount, followerCount, isFollowing, topics];
}
