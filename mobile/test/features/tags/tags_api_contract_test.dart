import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/tags/data/datasources/tags_api.dart';
import 'package:readin/features/tags/data/repositories/tags_repository_impl.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/tag_fixtures.dart';

/// The tag page's endpoints (F32) against the contract (docs/api/contract-v1.md, "Tags (F32)"): method, path, query,
/// and how the answers parse.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late TagsRepositoryImpl repository;

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
    repository = TagsRepositoryImpl(TagsApi(dio));
  });

  String call(int i) => '${requests[i].method} ${Uri.decodeComponent(requests[i].uri.path.replaceFirst('/api/v1', ''))}';

  test('GET /tags/{slug}: the header, with an Arabic slug percent-encoded in the path', () async {
    respond = (_) => tagJson(aiArTag);
    final tag = (await repository.getTag(aiArTag.slug)).valueOrNull!;
    expect(call(0), 'GET /tags/الذكاء-الاصطناعي');
    expect(requests[0].uri.toString(), contains('/tags/${Uri.encodeComponent(aiArTag.slug)}'));
    expect(tag, aiArTag);
  });

  test('GET /tags/{slug}/articles: post cards with their TagRefDto tags, a cursor and the limit', () async {
    respond = (_) => {
          'items': [taggedCardJson(1), taggedCardJson(2, tags: [aiArTag, csharpTag, dotnetTag], tagCount: 5)],
          'nextCursor': 'c1',
        };
    final page = (await repository.getArticles('csharp')).valueOrNull!;
    expect(call(0), 'GET /tags/csharp/articles');
    expect(requests[0].uri.queryParameters, {'limit': '20'});
    expect(page.nextCursor, 'c1');
    expect(page.items.first.tags, const [
      TagRef(slug: 'csharp', name: 'C#'),
      TagRef(slug: 'dotnet', name: '.NET'),
      TagRef(slug: 'cplusplus', name: 'C++'),
    ]);
    expect(page.items.last.tags.first, const TagRef(slug: 'الذكاء-الاصطناعي', name: 'الذكاء الاصطناعي'));
    expect(page.items.last.tagCount, 5);

    respond = (_) => {'items': <Object>[], 'nextCursor': null};
    final last = (await repository.getArticles('csharp', cursor: 'c1')).valueOrNull!;
    expect(requests[1].uri.queryParameters, {'cursor': 'c1', 'limit': '20'});
    expect(last.items, isEmpty);
    expect(last.hasMore, isFalse);
  });

  test('an unknown or hidden tag is 404 tag.not_found on both reads', () async {
    respond = (_) => (404, {'status': 404, 'code': 'tag.not_found', 'title': 'Tag not found.'});
    final header = (await repository.getTag(missingTagSlug)).failureOrNull!;
    final articles = (await repository.getArticles(missingTagSlug)).failureOrNull!;
    expect(header.code, FailureCodes.tagNotFound);
    expect(header.statusCode, 404);
    expect(articles.code, FailureCodes.tagNotFound);
  });
}
