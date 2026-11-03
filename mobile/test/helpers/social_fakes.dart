import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/data/datasources/article_offline_store.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/follow/domain/repositories/follow_repository.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/reactions/domain/entities/reactions.dart';
import 'package:readin/features/reactions/domain/repositories/reactions_repository.dart';
import 'package:readin/features/saved/domain/entities/saved.dart';
import 'package:readin/features/saved/domain/repositories/saved_repository.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/saved_list_cubit.dart';

import 'fixtures.dart';

class MockReactionsRepository extends Mock implements ReactionsRepository {}

class MockSavedRepository extends Mock implements SavedRepository {}

class MockFollowRepository extends Mock implements FollowRepository {}

class MockRealtimeService extends Mock implements RealtimeService {}

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

class MockEngagementCubit extends MockCubit<EngagementState> implements EngagementCubit {}

class MockFollowsCubit extends MockCubit<FollowsState> implements FollowsCubit {}

class MockCollectionsCubit extends MockCubit<CollectionsState> implements CollectionsCubit {}

class MockSavedListCubit extends MockCubit<SavedListState> implements SavedListCubit {}

/// [ArticleOfflineStore] backed by a map: `id|language` → copy.
class FakeArticleOfflineStore implements ArticleOfflineStore {
  final copies = <String, OfflineArticle>{};
  final _recent = <String, ArticleDetailsModel>{};
  String? owner;
  int claims = 0;

  @override
  Future<void> put(ArticleDetailsModel article, {DateTime? savedAt}) async {
    final existing = copies.values.where((c) => c.article.id == article.id).firstOrNull;
    copies['${article.id}|${article.language}'] =
        OfflineArticle(article: article, savedAt: savedAt ?? existing?.savedAt ?? DateTime.utc(2026, 11, 1));
  }

  @override
  Future<ArticleDetailsModel?> find(String slug, {String? language}) async {
    final matches = copies.values.where((c) => c.article.slug == slug).map((c) => c.article).toList();
    return matches.where((a) => a.language == language).firstOrNull ?? matches.firstOrNull;
  }

  @override
  Future<bool> contains(String articleId) async => copies.values.any((c) => c.article.id == articleId);

  @override
  Future<void> remove(String articleId) async => copies.removeWhere((_, c) => c.article.id == articleId);

  @override
  Future<List<OfflineArticle>> all() async {
    final byId = <String, OfflineArticle>{};
    for (final copy in copies.values) {
      byId[copy.article.id] ??= copy;
    }
    return byId.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  @override
  Future<void> retainOnly(Set<String> articleIds) async => copies.removeWhere((_, c) => !articleIds.contains(c.article.id));

  @override
  Future<void> claim(String? userId) async {
    claims++;
    if (owner != userId) {
      copies.clear();
      _recent.clear();
    }
    owner = userId;
  }

  @override
  ArticleDetailsModel? recent(String articleId) => _recent[articleId];

  @override
  void remember(ArticleDetailsModel article) => _recent[article.id] = article;
}

/// `ArticleDetailsDto` JSON of [sampleCard] `i`, the way the API sends it. [authorDeleted]: `author: null` (SPEC §9.6).
Map<String, dynamic> detailsJson(
  int i, {
  String language = 'ar-EG',
  bool isSaved = false,
  bool withWave1 = true,
  List<String> collectionIds = const [],
  bool authorDeleted = false,
}) {
  final card = sampleCard(i, language: language, authorDeleted: authorDeleted);
  final author = card.author;
  return {
    'id': card.id,
    'slug': card.slug,
    'language': language,
    'title': card.title,
    'field': {'id': card.field.id, 'slug': card.field.slug, 'nameAr': card.field.nameAr, 'nameEn': card.field.nameEn},
    'author': author == null
        ? null
        : {'id': author.id, 'displayName': author.displayName, 'username': author.username, 'isVerified': true},
    'readingTimeMinutes': card.readingTimeMinutes,
    'publishedAt': '2026-10-12T00:00:00Z',
    'reactionCount': 16,
    'commentCount': 4,
    'availableLanguages': [language],
    'content': {
      'version': 1,
      'language': language,
      'blocks': [
        {'type': 'paragraph', 'id': 'p1', 'content': [{'type': 'text', 'text': 'Offline body'}]},
      ],
    },
    'saveCount': 7,
    if (withWave1) ...{
      'reactions': {'insightful': 12, 'love': 3, 'fire': 1, 'mindBlown': 0},
      'myReaction': 'love',
      'isSaved': isSaved,
      'isFollowingAuthor': author != null,
      'collectionIds': collectionIds,
    },
  };
}

ArticleDetailsModel detailsModel(int i, {String language = 'ar-EG', bool isSaved = false, bool authorDeleted = false}) =>
    ArticleDetailsModel.fromJson(detailsJson(i, language: language, isSaved: isSaved, authorDeleted: authorDeleted));

/// A card with per-type counts, the way wave 1 feeds send it.
ArticleCard engagedCard(
  int i, {
  ReactionType? myReaction,
  bool isSaved = false,
  String language = 'ar-EG',
  bool authorDeleted = false,
}) =>
    sampleCard(i, language: language, authorDeleted: authorDeleted).copyWithEngagement(
      reactions: const ReactionCounts(insightful: 12, love: 3, fire: 1),
      reactionCount: 16,
      commentCount: 4,
      saveCount: 7,
      myReaction: () => myReaction,
      isSaved: isSaved,
    );

const writerAr = Author(id: 'w-1', displayName: 'منى عبد الله', username: 'mona_dev', isVerified: true);
const writerEn = Author(id: 'w-2', displayName: 'Omar Khaled', username: 'omar.k');
const writerMixed = Author(id: 'w-3', displayName: 'Sara (.NET)', username: 'sara_net');

final sampleReactors = [
  Reactor(user: writerAr, type: ReactionType.insightful, reactedAt: DateTime.utc(2026, 11, 2, 9)),
  Reactor(user: writerEn, type: ReactionType.love, reactedAt: DateTime.utc(2026, 11, 2, 8)),
  Reactor(user: writerMixed, type: ReactionType.fire, reactedAt: DateTime.utc(2026, 11, 1, 20)),
  Reactor(user: editorial, type: ReactionType.insightful, reactedAt: DateTime.utc(2026, 11, 1, 18)),
];

const sampleWriters = [
  UserSummary(
    id: 'w-1',
    displayName: 'منى عبد الله',
    username: 'mona_dev',
    isVerified: true,
    bio: 'بكتب عن ASP.NET Core و Clean Architecture',
    followsYou: true,
  ),
  UserSummary(id: 'w-2', displayName: 'Omar Khaled', username: 'omar.k', bio: 'Flutter & mobile performance', isFollowing: true),
  UserSummary(id: 'a-1', displayName: 'ReadIn Editorial', username: 'editorial', isVerified: true),
];

final sampleCollections = [
  ArticleCollection(id: 'c-1', name: 'تحضير الإنترفيو', articleCount: 3, createdAt: DateTime.utc(2026, 10, 1)),
  ArticleCollection(id: 'c-2', name: 'Weekend reads', articleCount: 1, createdAt: DateTime.utc(2026, 10, 2)),
  ArticleCollection(id: 'c-3', name: 'AI agents', articleCount: 0, createdAt: DateTime.utc(2026, 10, 3)),
];

List<SavedArticle> sampleSaved({String language = 'ar-EG'}) => [
      for (var i = 0; i < 3; i++)
        SavedArticle(
          savedAt: DateTime.utc(2026, 11, 2 - i),
          collectionIds: i == 0 ? const ['c-1'] : const [],
          article: engagedCard(i, isSaved: true, language: language),
        ),
    ];
