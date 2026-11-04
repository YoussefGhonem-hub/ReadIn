import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/follow/data/datasources/follow_api.dart';
import 'package:readin/features/follow/data/repositories/follow_repository_impl.dart';
import 'package:readin/features/home/data/datasources/feed_api.dart';
import 'package:readin/features/home/data/repositories/feed_repository_impl.dart';
import 'package:readin/features/reactions/data/datasources/reactions_api.dart';
import 'package:readin/features/reactions/data/repositories/reactions_repository_impl.dart';
import 'package:readin/features/reactions/domain/entities/reactions.dart';
import 'package:readin/features/saved/data/datasources/saved_api.dart';
import 'package:readin/features/saved/data/models/saved_models.dart';

import '../helpers/fake_auth.dart';
import '../helpers/social_fakes.dart';

/// Every wave 1 endpoint against the contract: method, path, query, body, and how the answer parses.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late Dio dio;

  setUp(() {
    requests = [];
    respond = (_) => null;
    final adapter = ScriptedAdapter((options) {
      requests.add(options);
      final body = respond(options);
      if (body is (int, Object?)) return body;
      return (200, body);
    });
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = adapter;
  });

  String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';

  final reactions = {'reactions': {'insightful': 3, 'love': 1, 'fire': 0, 'mindBlown': 0}, 'total': 4, 'myReaction': 'love'};
  final author = {'id': 'u-2', 'displayName': 'Omar', 'username': 'omar', 'avatarUrl': null, 'isVerified': false};

  group('reactions (F10)', () {
    test('PUT and DELETE /articles/{id}/reaction', () async {
      respond = (_) => reactions;
      final repository = ReactionsRepositoryImpl(ReactionsApi(dio));

      final set = (await repository.react('a-1', ReactionType.mindBlown)).valueOrNull!;
      await repository.removeReaction('a-1');

      expect(call(0), 'PUT /articles/a-1/reaction');
      expect(requests[0].data, {'type': 'mindBlown'});
      expect(call(1), 'DELETE /articles/a-1/reaction');
      expect(set, const ArticleReactions(reactions: ReactionCounts(insightful: 3, love: 1), total: 4, myReaction: ReactionType.love));
    });

    test('GET /articles/{id}/reactions filters by type and pages; unknown types are skipped', () async {
      respond = (_) => {
            'items': [
              {'user': author, 'type': 'fire', 'reactedAt': '2026-11-02T08:00:00Z'},
              {'user': author, 'type': 'clap', 'reactedAt': '2026-11-02T07:00:00Z'},
            ],
            'nextCursor': 'c2',
          };
      final repository = ReactionsRepositoryImpl(ReactionsApi(dio));

      final page = (await repository.getReactors('a-1', type: ReactionType.fire, cursor: 'c1')).valueOrNull!;

      expect(call(0), 'GET /articles/a-1/reactions');
      expect(requests[0].queryParameters, {'type': 'fire', 'cursor': 'c1', 'limit': 20});
      expect(page.items.single.type, ReactionType.fire);
      expect(page.nextCursor, 'c2');
    });

    test('400 with reaction.invalid in errors', () async {
      respond = (_) => (400, {'status': 400, 'code': 'validation.failed', 'errors': {'type': ['reaction.invalid']}});
      final failure = (await ReactionsRepositoryImpl(ReactionsApi(dio)).react('a-1', ReactionType.love)).failureOrNull!;
      expect(failure.code, FailureCodes.validationFailed);
      expect(failure.fieldErrors['type'], [FailureCodes.reactionInvalid]);
    });
  });

  group('saved and collections (F13)', () {
    test('every endpoint', () async {
      respond = (options) => switch ('${options.method} ${options.path}') {
            'PUT /me/saved/a-1' || 'DELETE /me/saved/a-1' => {'isSaved': options.method == 'PUT', 'saveCount': 5},
            'GET /me/saved' => {
                'items': [
                  {'savedAt': '2026-11-02T08:00:00Z', 'collectionIds': ['c-1'], 'article': detailsJson(1)},
                ],
                'nextCursor': null,
              },
            'GET /me/collections' => [
                {'id': 'c-1', 'name': 'Interview prep', 'articleCount': 2, 'createdAt': '2026-10-01T00:00:00Z'},
              ],
            'POST /me/collections' || 'PATCH /me/collections/c-1' => (options.method == 'POST' ? 201 : 200, {
                'id': 'c-1',
                'name': (options.data as Map)['name'],
                'articleCount': 0,
                'createdAt': '2026-10-01T00:00:00Z',
              }),
            _ => (204, null),
          };
      final api = SavedApi(dio);

      expect((await api.save('a-1')).isSaved, isTrue);
      expect((await api.unsave('a-1')).isSaved, isFalse);
      final page = await api.getSaved('dotnet', 'di', 'c-1', 'cur', 20);
      final collections = await api.getCollections();
      final created = await api.createCollection(const CollectionNameRequest(name: 'Interview prep'));
      await api.renameCollection('c-1', const CollectionNameRequest(name: 'Interviews'));
      await api.deleteCollection('c-1');
      await api.addToCollection('c-1', 'a-1');
      await api.removeFromCollection('c-1', 'a-1');

      expect([for (var i = 0; i < requests.length; i++) call(i)], [
        'PUT /me/saved/a-1',
        'DELETE /me/saved/a-1',
        'GET /me/saved',
        'GET /me/collections',
        'POST /me/collections',
        'PATCH /me/collections/c-1',
        'DELETE /me/collections/c-1',
        'PUT /me/collections/c-1/articles/a-1',
        'DELETE /me/collections/c-1/articles/a-1',
      ]);
      expect(requests[2].queryParameters, {'field': 'dotnet', 'q': 'di', 'collection': 'c-1', 'cursor': 'cur', 'limit': 20});
      expect(requests[5].data, {'name': 'Interviews'});
      expect(page.items.single.toEntity().collectionIds, ['c-1']);
      expect(page.items.single.toEntity().article.isSaved, isTrue);
      expect(collections.single.name, 'Interview prep');
      expect(created.name, 'Interview prep');
    });

    test('a GET /me/saved without filters sends only the paging', () async {
      respond = (_) => {'items': <Object>[]};
      await SavedApi(dio).getSaved(null, null, null, null, 20);
      expect(requests.single.queryParameters, {'limit': 20});
    });
  });

  group('follow (F12)', () {
    test('every endpoint', () async {
      final summary = {...author, 'bio': 'Flutter', 'isFollowing': true, 'followsYou': false};
      respond = (options) => switch ('${options.method} ${options.path}') {
            'PUT /users/u-2/follow' || 'DELETE /users/u-2/follow' => {'isFollowing': options.method == 'PUT', 'followerCount': 9},
            'GET /users/suggested' => [summary],
            'GET /users/u-2/followers' || 'GET /users/u-2/following' => {'items': [summary], 'nextCursor': null},
            _ => {'fieldIds': ['f-1', 'f-2', 'f-3'], 'topicIds': <String>[]},
          };
      final repository = FollowRepositoryImpl(FollowApi(dio));

      expect((await repository.follow('u-2')).valueOrNull!.isFollowing, isTrue);
      expect((await repository.unfollow('u-2')).valueOrNull!.followerCount, 9);
      expect((await repository.getSuggested()).valueOrNull!.single.isFollowing, isTrue);
      await repository.getFollowers('u-2', query: ' om ');
      await repository.getFollowing('u-2', query: '  ');
      await repository.setFieldFollowed('f-1', followed: true);
      await repository.setFieldFollowed('f-1', followed: false);
      await repository.setTopicFollowed('t-1', followed: true);
      final interests = (await repository.setTopicFollowed('t-1', followed: false)).valueOrNull!;

      expect([for (var i = 0; i < requests.length; i++) call(i)], [
        'PUT /users/u-2/follow',
        'DELETE /users/u-2/follow',
        'GET /users/suggested',
        'GET /users/u-2/followers',
        'GET /users/u-2/following',
        'PUT /me/interests/fields/f-1',
        'DELETE /me/interests/fields/f-1',
        'PUT /me/interests/topics/t-1',
        'DELETE /me/interests/topics/t-1',
      ]);
      expect(requests[2].queryParameters, {'limit': 10});
      expect(requests[3].queryParameters, {'q': 'om', 'limit': 20});
      expect(requests[4].queryParameters, {'limit': 20}, reason: 'a blank search is no search');
      expect(interests.fieldIds, hasLength(3));
    });

    test('400 follow.self and user.interests.min_three', () async {
      respond = (options) => (400, {'status': 400, 'code': options.path.contains('follow') ? 'follow.self' : 'user.interests.min_three'});
      final repository = FollowRepositoryImpl(FollowApi(dio));
      expect((await repository.follow('u-1')).failureOrNull!.code, FailureCodes.followSelf);
      expect((await repository.setFieldFollowed('f-1', followed: false)).failureOrNull!.code, FailureCodes.interestsMinThree);
    });

    test('GET /feed/following', () async {
      respond = (_) => {'items': [detailsJson(2)], 'nextCursor': 'n'};
      final page = (await FeedRepositoryImpl(FeedApi(dio)).getFollowing(cursor: 'c')).valueOrNull!;
      expect(call(0), 'GET /feed/following');
      expect(requests[0].queryParameters, {'cursor': 'c', 'limit': 20});
      expect(page.items.single.reactions.total, 16);
    });
  });

  group('deleted author (SPEC §9.6)', () {
    test("today, the feeds and Saved parse author: null; the article isn't dropped", () async {
      respond = (options) => switch (options.path) {
            '/feed/today' => detailsJson(0, authorDeleted: true),
            '/me/saved' => {
                'items': [
                  {'savedAt': '2026-11-02T08:00:00Z', 'article': detailsJson(1, authorDeleted: true)},
                ],
              },
            _ => {'items': [detailsJson(2, authorDeleted: true), detailsJson(3)], 'nextCursor': null},
          };
      final feeds = FeedRepositoryImpl(FeedApi(dio));

      expect((await feeds.getToday()).valueOrNull!.author, isNull);
      expect([for (final card in (await feeds.getForYou()).valueOrNull!.items) card.author?.username], [null, 'editorial']);
      expect((await feeds.getFollowing()).valueOrNull!.items.first.author, isNull);
      final saved = await SavedApi(dio).getSaved(null, null, null, null, 20);
      expect(saved.items.single.toEntity().article.author, isNull);
    });
  });
}
