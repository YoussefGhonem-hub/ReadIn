import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/home/data/datasources/feed_api.dart';
import 'package:readin/features/home/data/repositories/feed_repository_impl.dart';
import 'package:readin/features/paths/data/datasources/paths_api.dart';
import 'package:readin/features/paths/data/repositories/paths_repository_impl.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/path_fixtures.dart';

/// Every F09 endpoint the app calls, and `GET /me/continue-reading` (F03), against the contract: method, path, query
/// and how the answer (200, 204 or an error) comes back.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late Dio dio;

  setUp(() {
    requests = [];
    respond = (_) => null;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = ScriptedAdapter((options) {
        requests.add(options);
        final body = respond(options);
        if (body is (int, Object?)) return body;
        return (200, body);
      });
  });

  String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';

  PathsRepositoryImpl repository() => PathsRepositoryImpl(PathsApi(dio));

  group('GET /paths', () {
    test('lists the cards in editorial order; no field = no query', () async {
      respond = (_) => [pathCardJson(), pathCardJson(id: 'p-2', slug: 'ai-agents-101')];

      final paths = (await repository().getPaths()).valueOrNull!;

      expect(call(0), 'GET /paths');
      expect(requests[0].queryParameters, isEmpty);
      expect(paths.map((p) => p.slug), ['aspnet-core-basics', 'ai-agents-101']);
    });

    test('field filter', () async {
      respond = (_) => <Object>[];
      await repository().getPaths(fieldSlug: 'dotnet');
      expect(requests[0].queryParameters, {'field': 'dotnet'});
    });
  });

  group('GET /paths/{slug}', () {
    test('parses PathDetailsDto', () async {
      respond = (_) => pathDetailsJson(read: {1, 2});

      final details = (await repository().getPath('aspnet-core-basics')).valueOrNull!;

      expect(call(0), 'GET /paths/aspnet-core-basics');
      expect(details.items.where((i) => i.isRead).length, 2);
    });

    test('404 path.not_found', () async {
      respond = (_) => (404, {'status': 404, 'code': 'path.not_found', 'title': 'Not found'});

      final failure = (await repository().getPath('gone')).failureOrNull!;

      expect(failure.code, FailureCodes.pathNotFound);
      expect(failure.statusCode, 404);
    });
  });

  group('GET /articles/{id}/path', () {
    test('200: where the article sits', () async {
      respond = (_) => articlePathJson();

      final articlePath = (await repository().getArticlePath('art-2')).valueOrNull!;

      expect(call(0), 'GET /articles/art-2/path');
      expect(articlePath.position, 2);
      expect(articlePath.next!.slug, 'article-3');
    });

    test('204: in no published path', () async {
      respond = (_) => (204, null);

      final result = await repository().getArticlePath('art-9');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });

  group('GET /users/{username}/paths', () {
    test('the handle goes bare and lower-case', () async {
      respond = (_) => [pathCardJson(progress: progressJson(), enrollment: enrollmentJson())];

      final paths = (await repository().getUserPaths('@Mona_Dev')).valueOrNull!;

      expect(call(0), 'GET /users/mona_dev/paths');
      expect(paths.single.isEnrolled, isTrue);
    });

    test('403 profile.stats_private', () async {
      respond = (_) => (403, {'status': 403, 'code': 'profile.stats_private'});

      final failure = (await repository().getUserPaths('mona')).failureOrNull!;

      expect(failure.code, FailureCodes.profileStatsPrivate);
    });
  });

  test('GET /me/paths', () async {
    respond = (_) => [pathCardJson(progress: progressJson(), enrollment: enrollmentJson())];

    final paths = (await repository().getMyPaths()).valueOrNull!;

    expect(call(0), 'GET /me/paths');
    expect(paths, hasLength(1));
  });

  group('GET /me/paths/active', () {
    test('200: the path in progress with its next article', () async {
      respond = (_) => pathCardJson(progress: progressJson(readCount: 2, next: pathRefJson(3, position: 3)), enrollment: enrollmentJson());

      final path = (await repository().getActivePath()).valueOrNull!;

      expect(call(0), 'GET /me/paths/active');
      expect(path.progress!.next!.slug, 'article-3');
    });

    test('204: nothing in progress', () async {
      respond = (_) => (204, null);

      final result = await repository().getActivePath();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });

  test('PUT /me/paths/{pathId} enrolls and returns the card', () async {
    respond = (_) => pathCardJson(progress: progressJson(readCount: 0, next: pathRefJson(1, position: 1)), enrollment: enrollmentJson());

    final path = (await repository().enroll('p-1')).valueOrNull!;

    expect(call(0), 'PUT /me/paths/p-1');
    expect(path.isEnrolled, isTrue);
    expect(path.progress!.next!.position, 1);
  });

  test('DELETE /me/paths/{pathId} leaves (204)', () async {
    respond = (_) => (204, null);

    final result = await repository().leave('p-1');

    expect(call(0), 'DELETE /me/paths/p-1');
    expect(result.isOk, isTrue);
  });

  test('GET /me/continue-reading?limit=3', () async {
    respond = (_) => [continueReadingJson(1), continueReadingJson(2, percent: 12, language: 'ar-EG')];

    final items = (await FeedRepositoryImpl(FeedApi(dio)).getContinueReading()).valueOrNull!;

    expect(call(0), 'GET /me/continue-reading');
    expect(requests[0].queryParameters, {'limit': 3});
    expect(items.map((i) => (i.article.id, i.language, i.percent)), [('art-1', 'en', 42), ('art-2', 'ar-EG', 12)]);
  });
}
