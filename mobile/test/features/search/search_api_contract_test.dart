import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/search/data/datasources/search_api.dart';
import 'package:readin/features/search/data/repositories/search_repository_impl.dart';
import 'package:readin/features/search/domain/entities/search.dart';
import 'package:readin/features/tags/domain/entities/tag.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/tag_fixtures.dart';

/// `GET /search` (F16) against the contract (docs/api/contract-v1.md, "Search (F16)"): the query string of each tab
/// and its filters, the cursor and the limit, how the answers parse, and the error codes.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late SearchRepositoryImpl repository;

  setUp(() {
    requests = [];
    respond = (_) => {'items': <Object>[], 'nextCursor': null};
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = ScriptedAdapter((options) {
        requests.add(options);
        final body = respond(options);
        if (body is (int, Object?)) return body;
        return (200, body);
      });
    repository = SearchRepositoryImpl(SearchApi(dio));
  });

  String path(int i) => requests[i].uri.path.replaceFirst('/api/v1', '');

  group('type=articles', () {
    test('sends q, the type and the limit; no filter is sent unset', () async {
      await repository.articles('docker');
      expect(requests.single.method, 'GET');
      expect(path(0), '/search');
      expect(requests[0].uri.queryParameters, {'q': 'docker', 'type': 'articles', 'limit': '20'});
    });

    test('the field, the language and each reading-time chip, then the cursor', () async {
      await repository.articles(
        'ذكاء',
        filters: const ArticleSearchFilters(fieldSlug: 'ai', language: 'ar-EG', readingTime: ReadingTimeFilter.upTo5),
      );
      expect(requests[0].uri.queryParameters, {
        'q': 'ذكاء',
        'type': 'articles',
        'field': 'ai',
        'lang': 'ar-EG',
        'maxMinutes': '5',
        'limit': '20',
      });
      expect(requests[0].uri.toString(), contains('q=${Uri.encodeQueryComponent('ذكاء')}'));

      await repository.articles('docker', filters: const ArticleSearchFilters(readingTime: ReadingTimeFilter.from5To10));
      expect(requests[1].uri.queryParameters, {'q': 'docker', 'type': 'articles', 'minMinutes': '6', 'maxMinutes': '10', 'limit': '20'});

      await repository.articles('docker', filters: const ArticleSearchFilters(language: 'en', readingTime: ReadingTimeFilter.over10), cursor: 'c1');
      expect(requests[2].uri.queryParameters, {'q': 'docker', 'type': 'articles', 'lang': 'en', 'minMinutes': '11', 'cursor': 'c1', 'limit': '20'});
    });

    test('parses SearchArticleDto: the card and where it matched', () async {
      Map<String, dynamic> hit(int i, String? matchedIn) => {
            'article': taggedCardJson(i),
            'matchedIn': ?matchedIn,
          };
      respond = (_) => {
            'items': [hit(1, 'title'), hit(2, 'text'), hit(3, 'attachment'), hit(4, 'somewhere-new'), hit(5, null)],
            'nextCursor': 'c1',
          };
      final page = (await repository.articles('docker')).valueOrNull!;
      expect(page.items.map((r) => r.matchedIn), [
        SearchMatch.title,
        SearchMatch.text,
        SearchMatch.attachment,
        SearchMatch.text, // a value this app doesn't know: no hint
        SearchMatch.text,
      ]);
      expect(page.items[2].foundInAttachment, isTrue);
      expect(page.items.first.article.id, 'art-1');
      expect(page.items.first.article.tags.first, const TagRef(slug: 'csharp', name: 'C#'));
      expect(page.nextCursor, 'c1');
    });
  });

  test('type=users: UserSummaryDto rows', () async {
    respond = (_) => {
          'items': [
            {
              'id': 'w-1',
              'displayName': 'منى عبد الله',
              'username': 'mona_dev',
              'avatarUrl': null,
              'isVerified': true,
              'bio': 'بكتب عن .NET',
              'isFollowing': true,
              'followsYou': false,
            },
          ],
          'nextCursor': null,
        };
    final page = (await repository.users('mona', cursor: 'c2')).valueOrNull!;
    expect(requests[0].uri.queryParameters, {'q': 'mona', 'type': 'users', 'cursor': 'c2', 'limit': '20'});
    expect(page.items.single.username, 'mona_dev');
    expect(page.items.single.isFollowing, isTrue);
    expect(page.hasMore, isFalse);
  });

  test('type=topics: a field and a topic, with where each opens', () async {
    respond = (_) => {
          'items': [
            {
              'kind': 'field',
              'id': 'f-ai',
              'name': 'AI',
              'nameAr': 'الذكاء الاصطناعي',
              'nameEn': 'AI',
              'fieldSlug': 'ai',
              'topicSlug': null,
              'fieldName': 'AI',
              'icon': 'sparkles',
              'color': 'accent',
              'articleCount': 57,
            },
            {
              'kind': 'topic',
              'id': 't-agents',
              'name': 'AI Agents',
              'nameAr': 'AI Agents',
              'nameEn': 'AI Agents',
              'fieldSlug': 'ai',
              'topicSlug': 'ai-agents',
              'fieldName': 'AI',
              'icon': 'sparkles',
              'color': 'accent',
              'articleCount': 12,
            },
          ],
          'nextCursor': null,
        };
    final page = (await repository.topics('ai')).valueOrNull!;
    expect(requests[0].uri.queryParameters, {'q': 'ai', 'type': 'topics', 'limit': '20'});
    final [field, topic] = page.items;
    expect(field.isField, isTrue);
    expect(field.location, '/f/ai');
    expect(field.articleCount, 57);
    expect(topic.kind, SearchTopicKind.topic);
    expect(topic.location, '/f/ai?topic=ai-agents');
    expect(topic.fieldName, 'AI');
    expect(topic.icon, 'sparkles');
  });

  test('type=tags: TagDto rows', () async {
    respond = (_) => {
          'items': [tagJson(aiArTag), tagJson(csharpTag)],
          'nextCursor': 'c1',
        };
    final page = (await repository.tags('#ai')).valueOrNull!;
    expect(requests[0].uri.queryParameters, {'q': '#ai', 'type': 'tags', 'limit': '20'});
    expect(page.items, [aiArTag, csharpTag]);
    expect(page.nextCursor, 'c1');
  });

  test('the error codes come through as failures', () async {
    for (final (status, code) in [
      (400, 'search.query_invalid'),
      (400, 'search.type_invalid'),
      (400, 'search.filter_invalid'),
      (400, 'request.invalid'),
      (429, 'rate_limited'),
    ]) {
      respond = (_) => (status, {'status': status, 'code': code, 'title': 'x'});
      final failure = (await repository.articles('docker')).failureOrNull!;
      expect(failure.code, code);
      expect(failure.statusCode, status);
    }
    expect(FailureCodes.searchQueryInvalid, 'search.query_invalid');
    expect(FailureCodes.searchTypeInvalid, 'search.type_invalid');
    expect(FailureCodes.searchFilterInvalid, 'search.filter_invalid');
  });
}
