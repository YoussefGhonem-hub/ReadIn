import 'dart:async';

import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/search/data/datasources/recent_searches_store.dart';
import 'package:readin/features/search/domain/entities/search.dart';
import 'package:readin/features/search/domain/repositories/search_repository.dart';
import 'package:readin/features/search/domain/usecases/search_usecases.dart';
import 'package:readin/features/search/presentation/cubit/search_cubit.dart';
import 'package:readin/features/tags/domain/entities/tag.dart';
import 'package:readin/features/taxonomy/domain/entities/field.dart';
import 'package:readin/features/taxonomy/domain/repositories/taxonomy_repository.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';

import 'fixtures.dart';
import 'media_fixtures.dart';
import 'social_fakes.dart';
import 'tag_fixtures.dart';

/// Search (F16) results the way the API sends them, in Arabic and in English: articles that matched in the title, in
/// the text and only in the attached PDF; writers; a field and topics; tags.

/// The query of the screens in each UI language.
String searchQueryFor(String language) => language == 'en' ? 'agents' : 'ذكاء';

const _arTitles = [
  'إزاي تبني AI Agent بسيط بـ .NET في ساعة',
  'الذكاء الاصطناعي في الشغل: هيغيّر إيه في يومك؟',
  'ملخص كورس Machine Learning (ملف PDF)',
  'يعني إيه RAG؟ شرح بالعربي',
];
const _enTitles = [
  'Building your first AI agent in .NET',
  'How agents plan their next step',
  'Course notes: Machine Learning basics (PDF)',
  'What is RAG? A plain explanation',
];

/// Article result [i] (0-based titles repeat), in [language], matched in [matchedIn]. A hit in the attached PDF has
/// one, as the API sends it (no cover: the row's thumbnail is the PDF's first page).
SearchArticle searchArticle(int i, {String language = 'ar-EG', SearchMatch matchedIn = SearchMatch.title}) {
  final base = sampleCard(i, language: language);
  final titles = language == 'en' ? _enTitles : _arTitles;
  return SearchArticle(
    article: ArticleCard(
      id: 'art-$i',
      slug: 'article-$i',
      language: language,
      title: titles[i % titles.length],
      field: base.field,
      author: base.author,
      readingTimeMinutes: base.readingTimeMinutes,
      publishedAt: DateTime.utc(2026, 10, 30, 12),
      reactionCount: 40 - i * 3,
      commentCount: 9 - i,
      attachments: matchedIn == SearchMatch.attachment
          ? ArticleAttachments(kind: AttachmentsKind.document, document: sampleDocument())
          : null,
    ),
    matchedIn: matchedIn,
  );
}

/// Three results: a title match, a text match, and one found only in the attached PDF.
List<SearchArticle> searchArticles({String language = 'ar-EG', int first = 0}) => [
      searchArticle(first, language: language),
      searchArticle(first + 1, language: language, matchedIn: SearchMatch.text),
      searchArticle(first + 2, language: language, matchedIn: SearchMatch.attachment),
    ];

/// Writers: a verified one who follows the viewer, one the viewer follows, the viewer themself (no Follow button).
List<UserSummary> searchWriters() => [
      ...sampleWriters.take(2),
      UserSummary(id: sampleMe.id, displayName: sampleMe.displayName, username: sampleMe.username),
    ];

/// A field, a topic in it with an English name, and one with an Arabic name.
List<SearchTopic> searchTopics({String language = 'ar-EG'}) {
  final en = language == 'en';
  return [
    SearchTopic(
      kind: SearchTopicKind.field,
      id: 'f-ai',
      name: en ? 'AI' : 'الذكاء الاصطناعي',
      nameAr: 'الذكاء الاصطناعي',
      nameEn: 'AI',
      fieldSlug: 'ai',
      fieldName: en ? 'AI' : 'الذكاء الاصطناعي',
      icon: 'sparkles',
      color: 'accent',
      articleCount: 57,
    ),
    SearchTopic(
      kind: SearchTopicKind.topic,
      id: 't-agents',
      name: 'AI Agents',
      nameAr: 'AI Agents',
      nameEn: 'AI Agents',
      fieldSlug: 'ai',
      topicSlug: 'ai-agents',
      fieldName: en ? 'AI' : 'الذكاء الاصطناعي',
      icon: 'sparkles',
      color: 'accent',
      articleCount: 12,
    ),
    SearchTopic(
      kind: SearchTopicKind.topic,
      id: 't-ml',
      name: en ? 'Machine learning' : 'تعلم الآلة',
      nameAr: 'تعلم الآلة',
      nameEn: 'Machine learning',
      fieldSlug: 'ai',
      topicSlug: 'machine-learning',
      fieldName: en ? 'AI' : 'الذكاء الاصطناعي',
      icon: 'brain-circuit',
      color: 'primary',
      articleCount: 1,
    ),
  ];
}

const agentsTag = ArticleTag(slug: 'ai-agents', name: 'AI Agents', articleCount: 12);

/// Tags: an Arabic one, then English ones.
List<ArticleTag> searchTags() => const [aiArTag, aiEnTag, agentsTag];

/// Scriptable [SearchRepository]: each type answers the pages listed for a query (cursors `c1`, `c2`, …), and an empty
/// page for any other query. Every call is recorded, e.g. `articles docker field=ai lang=en time=upTo5 c1`.
class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({
    this.articlePages = const {},
    this.userPages = const {},
    this.topicPages = const {},
    this.tagPages = const {},
  });

  final Map<String, List<List<SearchArticle>>> articlePages;
  final Map<String, List<List<UserSummary>>> userPages;
  final Map<String, List<List<SearchTopic>>> topicPages;
  final Map<String, List<List<ArticleTag>>> tagPages;
  final calls = <String>[];

  /// Set to answer with a failure instead (e.g. offline).
  Failure? failure;

  /// Holds the answers until completed, to see the loading states.
  Completer<void>? gate;

  static String describe(ArticleSearchFilters f) => [
        if (f.fieldSlug != null) ' field=${f.fieldSlug}',
        if (f.language != null) ' lang=${f.language}',
        if (f.readingTime != ReadingTimeFilter.any) ' time=${f.readingTime.name}',
      ].join();

  Future<Result<CursorPage<T>>> _answer<T>(Map<String, List<List<T>>> pages, String query, String? cursor) async {
    await gate?.future;
    if (failure case final f?) return Err(f);
    final list = pages[query] ?? const [];
    final index = cursor == null ? 0 : int.parse(cursor.substring(1));
    if (index >= list.length) return Ok(CursorPage<T>(items: const []));
    return Ok(CursorPage(items: list[index], nextCursor: index + 1 < list.length ? 'c${index + 1}' : null));
  }

  String _cursor(String? cursor) => cursor == null ? '' : ' $cursor';

  @override
  Future<Result<CursorPage<SearchArticle>>> articles(
    String query, {
    ArticleSearchFilters filters = const ArticleSearchFilters(),
    String? cursor,
    int limit = 20,
  }) {
    calls.add('articles $query${describe(filters)}${_cursor(cursor)}');
    return _answer(articlePages, query, cursor);
  }

  @override
  Future<Result<CursorPage<UserSummary>>> users(String query, {String? cursor, int limit = 20}) {
    calls.add('users $query${_cursor(cursor)}');
    return _answer(userPages, query, cursor);
  }

  @override
  Future<Result<CursorPage<SearchTopic>>> topics(String query, {String? cursor, int limit = 20}) {
    calls.add('topics $query${_cursor(cursor)}');
    return _answer(topicPages, query, cursor);
  }

  @override
  Future<Result<CursorPage<ArticleTag>>> tags(String query, {String? cursor, int limit = 20}) {
    calls.add('tags $query${_cursor(cursor)}');
    return _answer(tagPages, query, cursor);
  }
}

/// The fields of the field filter ([sampleFields]).
class SampleFieldsRepository implements TaxonomyRepository {
  @override
  Future<Result<List<Field>>> getFields({bool refresh = false}) async => const Ok(sampleFields);

  @override
  Future<Result<List<Topic>>> getTopics(String fieldSlug) async => const Ok([]);
}

/// A [SearchCubit] over [repo], recent searches in [store] (in memory), and a real [FollowsCubit] when none is given.
SearchCubit searchCubit(FakeSearchRepository repo, {KeyValueStore? store, FollowsCubit? follows}) => SearchCubit(
      SearchContent(repo),
      RecentSearchesStore(store ?? InMemoryKeyValueStore()),
      GetFields(SampleFieldsRepository()),
      follows ?? FollowsCubit(SetFollowing(MockFollowRepository())),
    );

/// A repository with every tab answering [searchQueryFor] [language] (one page each).
FakeSearchRepository fullSearchRepository({String language = 'ar-EG'}) {
  final q = searchQueryFor(language == 'en' ? 'en' : 'ar');
  return FakeSearchRepository(
    articlePages: {q: [searchArticles(language: language)]},
    userPages: {q: [searchWriters()]},
    topicPages: {q: [searchTopics(language: language)]},
    tagPages: {q: [searchTags()]},
  );
}
