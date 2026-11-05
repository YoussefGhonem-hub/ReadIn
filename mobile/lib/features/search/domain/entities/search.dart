import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// The tabs of the search screen, and `type` of `GET /search` (F16): its wire value is the [name].
enum SearchType {
  articles,
  users,
  topics,
  tags;

  /// `?type=` of a `/search` link; null for anything else.
  static SearchType? fromWire(String? value) => values.asNameMap()[value];
}

/// Where an article matched (`SearchArticleDto.matchedIn`), best first: the served version's title, its title + text,
/// or only the attached PDF's text (F26).
enum SearchMatch {
  title,
  text,
  attachment;

  /// A value this app doesn't know yet reads as [text]: no hint on the row.
  static SearchMatch fromWire(String? value) => values.asNameMap()[value] ?? text;
}

/// An article result (`SearchArticleDto`): a card in the version that matched, shown as the compact row (F34).
class SearchArticle extends Equatable {
  const SearchArticle({required this.article, this.matchedIn = SearchMatch.text});

  final ArticleCard article;
  final SearchMatch matchedIn;

  /// Only the attached PDF holds the query: the row says "Found in the attached PDF".
  bool get foundInAttachment => matchedIn == SearchMatch.attachment;

  @override
  List<Object?> get props => [article, matchedIn];
}

enum SearchTopicKind {
  field,
  topic;

  static SearchTopicKind fromWire(String? value) => values.asNameMap()[value] ?? topic;
}

/// A field or a topic result (`SearchTopicDto`). It opens the field page (F15).
class SearchTopic extends Equatable {
  const SearchTopic({
    required this.kind,
    required this.id,
    required this.name,
    required this.nameAr,
    required this.nameEn,
    required this.fieldSlug,
    this.topicSlug,
    required this.fieldName,
    this.icon = 'book-open',
    this.color = 'primary',
    this.articleCount = 0,
  });

  final SearchTopicKind kind;
  final String id;

  /// In the UI language (`Accept-Language`).
  final String name;
  final String nameAr;
  final String nameEn;
  final String fieldSlug;

  /// Null for a field.
  final String? topicSlug;

  /// The field's name in the UI language (= [name] for a field): a topic's subtitle.
  final String fieldName;

  /// The field's Lucide icon name and color token.
  final String icon;
  final String color;

  /// Published articles readers can see in it.
  final int articleCount;

  bool get isField => kind == SearchTopicKind.field;

  /// The field page: `/f/{fieldSlug}`, and `?topic={topicSlug}` for a topic.
  String get location {
    final field = '/f/${Uri.encodeComponent(fieldSlug)}';
    final topic = topicSlug;
    return topic == null ? field : '$field?topic=${Uri.encodeQueryComponent(topic)}';
  }

  @override
  List<Object?> get props => [kind, id, name, nameAr, nameEn, fieldSlug, topicSlug, fieldName, icon, color, articleCount];
}

/// The reading-time chips of the Articles tab and the `minMinutes` / `maxMinutes` each sends (inclusive).
enum ReadingTimeFilter {
  any(null, null),

  /// "≤ 5 min".
  upTo5(null, 5),

  /// "5–10 min".
  from5To10(6, 10),

  /// "> 10 min".
  over10(11, null);

  const ReadingTimeFilter(this.minMinutes, this.maxMinutes);

  final int? minMinutes;
  final int? maxMinutes;
}

/// The article languages `lang` filters by.
abstract final class SearchLanguages {
  static const arabic = 'ar-EG';
  static const english = 'en';
  static const all = [arabic, english];
}

/// The Articles tab's filters: a field, an article language and a reading time. The other tabs have none.
class ArticleSearchFilters extends Equatable {
  const ArticleSearchFilters({this.fieldSlug, this.language, this.readingTime = ReadingTimeFilter.any});

  /// A field's slug; null = every field.
  final String? fieldSlug;

  /// `ar-EG` or `en`; null = both.
  final String? language;
  final ReadingTimeFilter readingTime;

  bool get isEmpty => fieldSlug == null && language == null && readingTime == ReadingTimeFilter.any;

  ArticleSearchFilters copyWith({String? Function()? fieldSlug, String? Function()? language, ReadingTimeFilter? readingTime}) =>
      ArticleSearchFilters(
        fieldSlug: fieldSlug != null ? fieldSlug() : this.fieldSlug,
        language: language != null ? language() : this.language,
        readingTime: readingTime ?? this.readingTime,
      );

  @override
  List<Object?> get props => [fieldSlug, language, readingTime];
}
