import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/explore/data/datasources/explore_api.dart';
import 'package:readin/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:readin/features/explore/domain/entities/explore.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/path_fixtures.dart';
import '../../helpers/tag_fixtures.dart';

/// Explore and the field pages (F15) against the contract (docs/api/contract-v1.md, "Explore and field pages"):
/// method, path, query, and how the answers parse.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late ExploreRepositoryImpl repository;

  setUp(() {
    requests = [];
    respond = (_) => null;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = ScriptedAdapter((options) {
        requests.add(options);
        final body = respond(options);
        if (body is (int, Object?)) return body;
        return (200, body);
      });
    repository = ExploreRepositoryImpl(ExploreApi(dio));
  });

  String call(int i) => '${requests[i].method} ${Uri.decodeComponent(requests[i].uri.path.replaceFirst('/api/v1', ''))}';

  Map<String, dynamic> userJson(String id, {bool isFollowing = false}) => {
        'id': id,
        'displayName': 'Sara (.NET)',
        'username': 'sara_net',
        'avatarUrl': null,
        'isVerified': false,
        'bio': 'Backend و .NET',
        'isFollowing': isFollowing,
        'followsYou': false,
      };

  Map<String, dynamic> fieldSummaryJson() => {
        'id': 'f-dotnet',
        'slug': 'dotnet',
        'name': '.NET',
        'nameAr': '.NET',
        'nameEn': '.NET',
        'icon': 'code-xml',
        'color': 'primary',
        'articleCount': 64,
      };

  test('GET /explore: every section, each card, writer and path as the other lists send them', () async {
    respond = (_) => {
          'fields': [fieldSummaryJson()],
          'trending': [taggedCardJson(1)],
          'mostSaved': [taggedCardJson(2), taggedCardJson(3)],
          'newWriters': [userJson('w-3', isFollowing: true)],
          'featuredPaths': [pathCardJson(progress: progressJson())],
        };
    final explore = (await repository.getExplore()).valueOrNull!;
    expect(call(0), 'GET /explore');
    expect(requests[0].uri.queryParameters, isEmpty);
    expect(explore.fields.single, const FieldSummary(
      id: 'f-dotnet',
      slug: 'dotnet',
      name: '.NET',
      nameAr: '.NET',
      nameEn: '.NET',
      icon: 'code-xml',
      articleCount: 64,
    ));
    expect(explore.trending.single.id, 'art-1');
    expect(explore.mostSaved.map((a) => a.id), ['art-2', 'art-3']);
    expect(explore.newWriters.single.isFollowing, isTrue);
    expect(explore.featuredPaths.single.slug, 'aspnet-core-basics');
    expect(explore.featuredPaths.single.progress?.readCount, 1);
    expect(explore.isEmpty, isFalse);
  });

  test('GET /explore: an empty section is [] (and a missing one too)', () async {
    respond = (_) => {'fields': <Object>[], 'trending': <Object>[], 'mostSaved': <Object>[], 'newWriters': <Object>[]};
    final explore = (await repository.getExplore()).valueOrNull!;
    expect(explore.isEmpty, isTrue);
    expect(explore.featuredPaths, isEmpty);
  });

  test('GET /explore/trending and /explore/most-saved: CursorPage<ArticleCardDto> with the cursor and the limit', () async {
    respond = (_) => {'items': [taggedCardJson(1), taggedCardJson(2)], 'nextCursor': 'c1'};
    final trending = (await repository.getRanking(ExploreRanking.trending)).valueOrNull!;
    expect(call(0), 'GET /explore/trending');
    expect(requests[0].uri.queryParameters, {'limit': '20'});
    expect(trending.items.map((a) => a.id), ['art-1', 'art-2']);
    expect(trending.nextCursor, 'c1');

    respond = (_) => {'items': <Object>[], 'nextCursor': null};
    final saved = (await repository.getRanking(ExploreRanking.mostSaved, cursor: 'c1')).valueOrNull!;
    expect(call(1), 'GET /explore/most-saved');
    expect(requests[1].uri.queryParameters, {'cursor': 'c1', 'limit': '20'});
    expect(saved.hasMore, isFalse);
  });

  test('GET /fields/{slug}: the header with its id, counts, the follow state and the topic chips', () async {
    respond = (_) => {
          'id': 'f-medicine',
          'slug': 'medicine',
          'name': 'الطب',
          'nameAr': 'الطب',
          'nameEn': 'Medicine',
          'icon': 'stethoscope',
          'color': 'callout-danger-accent',
          'isSensitive': true,
          'articleCount': 9,
          'followerCount': 130,
          'isFollowing': true,
          'topics': [
            {'id': 't-1', 'slug': 'cardiology', 'name': 'القلب', 'nameAr': 'القلب', 'nameEn': 'Cardiology', 'articleCount': 4, 'isFollowing': true},
            {'id': 't-2', 'slug': 'nutrition', 'name': 'التغذية', 'nameAr': 'التغذية', 'nameEn': 'Nutrition', 'articleCount': 0, 'isFollowing': false},
          ],
        };
    final field = (await repository.getField('medicine')).valueOrNull!;
    expect(call(0), 'GET /fields/medicine');
    expect(field.id, 'f-medicine');
    expect(field.name, 'الطب');
    expect(field.isSensitive, isTrue);
    expect((field.articleCount, field.followerCount, field.isFollowing), (9, 130, true));
    expect(field.topics.map((t) => (t.id, t.slug, t.articleCount, t.isFollowing)), [
      ('t-1', 'cardiology', 4, true),
      ('t-2', 'nutrition', 0, false),
    ]);
    expect(field.topicOf('CARDIOLOGY')?.id, 't-1', reason: 'topics match ignoring case, like the API');
    expect(field.topicOf(null), isNull);
  });

  test('GET /fields/{slug}/articles: the whole field, or ?topic=, with the cursor and the limit', () async {
    respond = (_) => {'items': [taggedCardJson(1)], 'nextCursor': 'c1'};
    final all = (await repository.getFieldArticles('dotnet')).valueOrNull!;
    expect(call(0), 'GET /fields/dotnet/articles');
    expect(requests[0].uri.queryParameters, {'limit': '20'});
    expect(all.items.single.id, 'art-1');

    await repository.getFieldArticles('dotnet', topic: 'ef-core', cursor: 'c1');
    expect(requests[1].uri.queryParameters, {'topic': 'ef-core', 'cursor': 'c1', 'limit': '20'});

    await repository.getFieldArticles('dotnet', topic: '');
    expect(requests[2].uri.queryParameters, {'limit': '20'}, reason: 'an empty topic is the whole field');
  });

  test('GET /fields/{slug}/writers: UserSummaryDto[] with isFollowing, at most 10', () async {
    respond = (_) => [userJson('w-3'), userJson('w-4', isFollowing: true)];
    final writers = (await repository.getFieldWriters('dotnet')).valueOrNull!;
    expect(call(0), 'GET /fields/dotnet/writers');
    expect(requests[0].uri.queryParameters, {'limit': '10'});
    expect(writers.map((u) => (u.id, u.isFollowing)), [('w-3', false), ('w-4', true)]);
  });

  test('404 field.not_found on the three field reads, 404 topic.not_found for a topic of another field', () async {
    respond = (_) => (404, {'status': 404, 'code': 'field.not_found', 'title': 'Field not found.'});
    for (final result in [
      (await repository.getField('nope')).failureOrNull,
      (await repository.getFieldArticles('nope')).failureOrNull,
      (await repository.getFieldWriters('nope')).failureOrNull,
    ]) {
      expect(result?.code, FailureCodes.fieldNotFound);
      expect(result?.statusCode, 404);
    }

    respond = (_) => (404, {'status': 404, 'code': 'topic.not_found', 'title': 'Topic not found.'});
    final topic = (await repository.getFieldArticles('dotnet', topic: 'react')).failureOrNull!;
    expect(topic.code, FailureCodes.topicNotFound);
  });
}
