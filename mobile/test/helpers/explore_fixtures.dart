import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/explore/domain/entities/explore.dart';
import 'package:readin/features/explore/domain/repositories/explore_repository.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/onboarding/domain/usecases/set_interest.dart';
import 'package:readin/features/paths/domain/entities/learning_path.dart';

import 'fixtures.dart';
import 'path_fixtures.dart';
import 'post_card_fixtures.dart';
import 'social_fakes.dart';

/// Explore and field pages (F15) the way the API sends them: names in the UI language (Arabic with English runs, and
/// English), field colors from the tokens, and a sensitive field.

class MockSetInterest extends Mock implements SetInterest {}

/// A session holding [me], or a guest's.
MockSessionCubit sessionOf(Me? me) {
  final session = MockSessionCubit();
  whenListen(
    session,
    const Stream<SessionState>.empty(),
    initialState: me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me),
  );
  return session;
}

/// A reader with [count] interests, the .NET field and its ASP.NET Core topic among them.
Me readerWith(int count) => Me(
      id: sampleMe.id,
      displayName: sampleMe.displayName,
      username: sampleMe.username,
      onboardingCompleted: true,
      interestFieldIds: ['f-dotnet', for (var i = 1; i < count - 1; i++) 'f-$i'],
      interestTopicIds: const ['t-aspnet-core'],
    );

/// Every enabled field in display order, in the UI language [lang] (`ar` | `en`).
List<FieldSummary> exploreFields({String lang = 'ar'}) {
  final en = lang == 'en';
  FieldSummary field(String slug, String ar, String english, String icon, String color, int count) => FieldSummary(
        id: 'f-$slug',
        slug: slug,
        name: en ? english : ar,
        nameAr: ar,
        nameEn: english,
        icon: icon,
        color: color,
        articleCount: count,
      );
  return [
    field('ai-fundamentals', 'أساسيات الـ AI', 'AI Fundamentals', 'sparkles', 'primary', 42),
    field('machine-learning', 'Machine Learning', 'Machine Learning', 'brain-circuit', 'callout-info-accent', 18),
    field('deep-learning-llms', 'Deep Learning و LLMs', 'Deep Learning & LLMs', 'network', 'callout-info-accent', 23),
    field('claude-ai-tools', 'Claude وأدوات الـ AI للبرمجة', 'Claude & AI coding tools', 'bot', 'accent', 31),
    field('dotnet', '.NET', '.NET', 'code-xml', 'primary', 64),
    field('frontend', 'Frontend', 'Frontend', 'layout-template', 'callout-warning-accent', 27),
    field('medicine', 'الطب', 'Medicine', 'stethoscope', 'callout-danger-accent', 9),
    field('law', 'القانون', 'Law', 'scale', 'success', 0),
  ];
}

const _enTitles = [
  'What is Dependency Injection in .NET, and why does everyone talk about it?',
  'Transient or Scoped: which lifetime fits your service?',
  'How AI Agents will change the way you work',
  'EF Core: writing fast queries without hurting the database',
];

/// A card of an Explore list in [language] (`ar-EG` | `en`), by writer [author], with [saves] saves.
ArticleCard exploreCard(int i, {String language = 'ar-EG', Author author = writerAr, int saves = 0, bool isSaved = false}) {
  final base = postCard(i, language: language, author: author, reactionCount: 12 + (i * 7) % 30, commentCount: (i * 3) % 10, isSaved: isSaved);
  return ArticleCard(
    id: base.id,
    slug: base.slug,
    language: base.language,
    title: language == 'en' ? _enTitles[i % _enTitles.length] : sampleTitles[i % sampleTitles.length],
    field: base.field,
    author: base.author,
    readingTimeMinutes: base.readingTimeMinutes,
    publishedAt: base.publishedAt,
    coverUrl: i.isEven ? null : base.coverUrl,
    reactionCount: base.reactionCount,
    commentCount: base.commentCount,
    reactions: const ReactionCounts(insightful: 12, love: 6),
    isSaved: base.isSaved,
    saveCount: saves,
    excerpt: base.excerpt,
    hasMore: base.hasMore,
    tags: base.tags,
    tagCount: base.tagCount,
  );
}

/// [count] cards from [first] (ids `art-{first}`…), the writers taking turns.
List<ArticleCard> exploreCards({int first = 1, int count = 6, String language = 'ar-EG'}) => [
      for (var i = first; i < first + count; i++)
        exploreCard(i, language: language, author: const [writerAr, writerEn, writerMixed][i % 3], saves: 30 - i),
    ];

/// New writers: an Arabic name, an English one, a mixed one, one more and the viewer.
List<UserSummary> exploreWriters() => [
      ...sampleWriters.take(2),
      const UserSummary(id: 'w-3', displayName: 'Sara (.NET)', username: 'sara_net', bio: 'Backend, .NET و Azure'),
      const UserSummary(id: 'w-4', displayName: 'كريم سامي', username: 'karim.ml', bio: 'ML engineer, بكتب عن الـ MLOps'),
      UserSummary(id: sampleMe.id, displayName: sampleMe.displayName, username: sampleMe.username),
    ];

/// Featured paths: the editorial ones, in their order.
List<LearningPath> featuredPaths({String language = 'ar-EG'}) {
  final en = language == 'en';
  return [
    samplePath(title: en ? 'ASP.NET Core basics' : 'أساسيات ASP.NET Core', description: en ? 'From Dependency Injection to a full API.' : null),
    samplePath(
      id: 'p-2',
      slug: 'ai-agents-101',
      title: en ? 'AI Agents from scratch' : 'AI Agents من الصفر',
      description: en ? 'Build an agent that uses tools and remembers context.' : 'إزاي تبني agent بيستخدم tools ويفتكر السياق.',
      field: aiField,
      total: 5,
    ),
  ];
}

/// Every section of Explore in the UI language [lang] and the article language that goes with it.
ExploreSections sampleExplore({String lang = 'ar'}) {
  final language = lang == 'en' ? 'en' : 'ar-EG';
  return ExploreSections(
    fields: exploreFields(lang: lang),
    trending: exploreCards(language: language),
    mostSaved: exploreCards(first: 11, count: 4, language: language),
    newWriters: exploreWriters(),
    featuredPaths: featuredPaths(language: language),
  );
}

/// The .NET field page: two followers short of round numbers, topics with Arabic and English names.
FieldDetails dotnetDetails({String lang = 'ar', bool isFollowing = false, int followerCount = 129}) {
  final en = lang == 'en';
  FieldTopic topic(String slug, String ar, String english, int count, {bool following = false}) => FieldTopic(
        id: 't-$slug',
        slug: slug,
        name: en ? english : ar,
        nameAr: ar,
        nameEn: english,
        articleCount: count,
        isFollowing: following,
      );
  return FieldDetails(
    id: 'f-dotnet',
    slug: 'dotnet',
    name: '.NET',
    nameAr: '.NET',
    nameEn: '.NET',
    icon: 'code-xml',
    color: 'primary',
    articleCount: 64,
    followerCount: followerCount,
    isFollowing: isFollowing,
    topics: [
      topic('csharp', 'C#', 'C#', 21),
      topic('aspnet-core', 'ASP.NET Core', 'ASP.NET Core', 17, following: true),
      topic('ef-core', 'EF Core', 'EF Core', 12),
      topic('dotnet-testing', 'Testing في .NET', 'Testing in .NET', 6),
      topic('mapster', 'Mapster', 'Mapster', 0),
    ],
  );
}

/// Medicine: a sensitive field (the health note), in Arabic or English.
FieldDetails medicineDetails({String lang = 'ar'}) => FieldDetails(
      id: 'f-medicine',
      slug: 'medicine',
      name: lang == 'en' ? 'Medicine' : 'الطب',
      nameAr: 'الطب',
      nameEn: 'Medicine',
      icon: 'stethoscope',
      color: 'callout-danger-accent',
      isSensitive: true,
      articleCount: 9,
      followerCount: 1,
      topics: [
        FieldTopic(id: 't-cardiology', slug: 'cardiology', name: lang == 'en' ? 'Cardiology' : 'القلب', articleCount: 4),
        FieldTopic(id: 't-nutrition', slug: 'nutrition', name: lang == 'en' ? 'Nutrition' : 'التغذية', articleCount: 5),
      ],
    );

/// A field nobody has published in yet.
FieldDetails emptyFieldDetails({String lang = 'ar'}) => FieldDetails(
      id: 'f-law',
      slug: 'law',
      name: lang == 'en' ? 'Law' : 'القانون',
      icon: 'scale',
      color: 'success',
      topics: [FieldTopic(id: 't-labor', slug: 'labor-law', name: lang == 'en' ? 'Labor law' : 'قانون العمل')],
    );

/// Scriptable [ExploreRepository]: [explore] for `GET /explore`, pages for each ranking and for a field's articles
/// (keyed `{slug}` or `{slug}?{topic}`; cursors `c1`, `c2`, …), [fields] by slug (404 `field.not_found` for others),
/// a field's topic not in [fields] is 404 `topic.not_found`, and [writers] by slug. Every call is recorded.
class FakeExploreRepository implements ExploreRepository {
  FakeExploreRepository({
    this.explore = const ExploreSections(),
    this.rankings = const {},
    this.fields = const [],
    this.articlePages = const {},
    this.writers = const {},
  });

  ExploreSections explore;
  final Map<ExploreRanking, List<List<ArticleCard>>> rankings;
  final List<FieldDetails> fields;
  final Map<String, List<List<ArticleCard>>> articlePages;
  final Map<String, List<UserSummary>> writers;
  final calls = <String>[];

  /// Set to answer with a failure instead (e.g. offline).
  Failure? failure;

  /// Holds the answers until completed, to see the loading states.
  Completer<void>? gate;

  static const fieldNotFound = Failure(FailureCodes.fieldNotFound, statusCode: 404);
  static const topicNotFound = Failure(FailureCodes.topicNotFound, statusCode: 404);

  Future<Failure?> _wait() async {
    await gate?.future;
    return failure;
  }

  static Result<CursorPage<ArticleCard>> _page(List<List<ArticleCard>> pages, String? cursor) {
    final index = cursor == null ? 0 : int.parse(cursor.substring(1));
    if (index >= pages.length) return const Ok(CursorPage(items: []));
    return Ok(CursorPage(items: pages[index], nextCursor: index + 1 < pages.length ? 'c${index + 1}' : null));
  }

  FieldDetails? _field(String slug) => fields.where((f) => f.slug == slug.toLowerCase()).firstOrNull;

  @override
  Future<Result<ExploreSections>> getExplore() async {
    calls.add('explore');
    if (await _wait() case final f?) return Err(f);
    return Ok(explore);
  }

  @override
  Future<Result<CursorPage<ArticleCard>>> getRanking(ExploreRanking ranking, {String? cursor, int limit = 20}) async {
    calls.add('${ranking.path}${cursor == null ? '' : ' $cursor'}');
    if (await _wait() case final f?) return Err(f);
    return _page(rankings[ranking] ?? const [[]], cursor);
  }

  @override
  Future<Result<FieldDetails>> getField(String slug) async {
    calls.add('field $slug');
    if (await _wait() case final f?) return Err(f);
    final field = _field(slug);
    return field == null ? const Err(fieldNotFound) : Ok(field);
  }

  @override
  Future<Result<CursorPage<ArticleCard>>> getFieldArticles(String slug, {String? topic, String? cursor, int limit = 20}) async {
    calls.add('articles $slug${topic == null ? '' : '?$topic'}${cursor == null ? '' : ' $cursor'}');
    if (await _wait() case final f?) return Err(f);
    final field = _field(slug);
    if (field == null) return const Err(fieldNotFound);
    if (topic != null && field.topicOf(topic) == null) return const Err(topicNotFound);
    final key = topic == null ? field.slug : '${field.slug}?${topic.toLowerCase()}';
    return _page(articlePages[key] ?? const [[]], cursor);
  }

  @override
  Future<Result<List<UserSummary>>> getFieldWriters(String slug, {int limit = 10}) async {
    calls.add('writers $slug');
    if (await _wait() case final f?) return Err(f);
    if (_field(slug) == null) return const Err(fieldNotFound);
    return Ok(writers[slug] ?? const []);
  }
}
