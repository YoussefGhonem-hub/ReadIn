import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/categories/data/datasources/categories_api.dart';
import 'package:readin/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:readin/features/categories/domain/entities/writer_category.dart';

import '../../helpers/category_fixtures.dart';
import '../../helpers/fake_auth.dart';
import '../../helpers/social_fakes.dart';

/// Writer categories (F31) against the contract (docs/api/contract-v1.md, "Writer categories (F31)"): method, path,
/// query, body, and how the answers parse.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late CategoriesRepositoryImpl repository;

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
    repository = CategoriesRepositoryImpl(CategoriesApi(dio));
  });

  String call(int i) => '${requests[i].method} ${Uri.decodeComponent(requests[i].uri.path.replaceFirst('/api/v1', ''))}';
  Object? body(int i) => requests[i].data is String ? jsonDecode(requests[i].data as String) : requests[i].data;

  test('GET /users/{username}/categories: the cards in the writer\'s order and the uncategorized count', () async {
    respond = (_) => categoryListJson(const [backendTips, efCore], uncategorized: 4);
    final list = (await repository.getUserCategories('@Mona_Dev')).valueOrNull!;
    expect(call(0), 'GET /users/mona_dev/categories', reason: 'the bare lower-case handle');
    expect(list.items, const [backendTips, efCore]);
    expect(list.uncategorizedCount, 4);
  });

  test('GET /users/{username}/categories/{slug}: the header, an Arabic slug percent-encoded; _other has no id or name', () async {
    respond = (_) => {
          'id': backendTips.id,
          'slug': backendTips.slug,
          'name': backendTips.name,
          'articleCount': 7,
          'author': {'id': 'w-1', 'displayName': 'منى عبد الله', 'username': 'mona_dev', 'isVerified': true},
        };
    final page = (await repository.getCategoryPage('mona_dev', backendTips.slug)).valueOrNull!;
    expect(call(0), 'GET /users/mona_dev/categories/نصايح-backend');
    expect(requests[0].uri.toString(), contains('/categories/${Uri.encodeComponent(backendTips.slug)}'));
    expect(page, categoryPageOf(backendTips));
    expect(page.isOther, isFalse);

    respond = (_) => {
          'id': null,
          'slug': '_other',
          'name': null,
          'articleCount': 4,
          'author': {'id': 'w-1', 'displayName': 'منى عبد الله', 'username': 'mona_dev', 'isVerified': true},
        };
    final other = (await repository.getCategoryPage('mona_dev', '_other')).valueOrNull!;
    expect(call(1), 'GET /users/mona_dev/categories/_other');
    expect(other.isOther, isTrue);
    expect(other.articleCount, 4);
  });

  test('GET …/{slug}/articles: post cards with a cursor and the limit; the slug is matched ignoring case', () async {
    respond = (_) => {
          'items': [detailsJson(1), detailsJson(2)],
          'nextCursor': 'c1',
        };
    final page = (await repository.getCategoryArticles('mona_dev', 'EF-Core')).valueOrNull!;
    expect(call(0), 'GET /users/mona_dev/categories/ef-core/articles');
    expect(requests[0].uri.queryParameters, {'limit': '20'});
    expect(page.items.map((a) => a.id), ['art-1', 'art-2']);
    expect(page.nextCursor, 'c1');

    respond = (_) => {'items': <Object>[], 'nextCursor': null};
    final last = (await repository.getCategoryArticles('mona_dev', 'ef-core', cursor: 'c1')).valueOrNull!;
    expect(requests[1].uri.queryParameters, {'cursor': 'c1', 'limit': '20'});
    expect(last.hasMore, isFalse);
  });

  test('an unknown slug is 404 category.not_found, a deleted writer 404 user.not_found', () async {
    respond = (_) => (404, {'status': 404, 'code': 'category.not_found', 'title': 'Category not found.'});
    expect((await repository.getCategoryPage('mona_dev', 'old-name')).failureOrNull!.code, FailureCodes.categoryNotFound);
    expect((await repository.getCategoryArticles('mona_dev', 'old-name')).failureOrNull!.code, FailureCodes.categoryNotFound);

    respond = (_) => (404, {'status': 404, 'code': 'user.not_found', 'title': 'User not found.'});
    expect((await repository.getUserCategories('gone')).failureOrNull!.code, FailureCodes.userNotFound);
  });

  test('GET /me/categories: all of them, empty ones included', () async {
    respond = (_) => categoryListJson(const [backendTips, draftsOnly], uncategorized: 2);
    final list = (await repository.getMyCategories()).valueOrNull!;
    expect(call(0), 'GET /me/categories');
    expect(list.items.last.isEmpty, isTrue);
    expect(list.uncategorizedCount, 2);
  });

  test('POST /me/categories and PATCH /me/categories/{id} send { name }', () async {
    respond = (_) => (201, categoryJson(const WriterCategory(id: 'c-9', slug: 'rust', name: 'Rust 🚀', sortOrder: 5)));
    final created = (await repository.create('Rust 🚀')).valueOrNull!;
    expect(call(0), 'POST /me/categories');
    expect(body(0), {'name': 'Rust 🚀'});
    expect(created.id, 'c-9');
    expect(created.articleCount, 0);

    respond = (_) => categoryJson(efCore.copyWith(name: 'EF Core 10'));
    final renamed = (await repository.rename('c-2', 'EF Core 10')).valueOrNull!;
    expect(call(1), 'PATCH /me/categories/c-2');
    expect(body(1), {'name': 'EF Core 10'});
    expect(renamed.slug, 'ef-core', reason: 'a rename keeps the slug');
  });

  test('the name errors parse: 409 name_taken, 400 limit, 400 validation.failed with category.name_invalid', () async {
    respond = (_) => (409, {'status': 409, 'code': 'category.name_taken', 'title': 'You already have a category with this name.'});
    expect((await repository.create('ai')).failureOrNull!.code, FailureCodes.categoryNameTaken);

    respond = (_) => (400, {'status': 400, 'code': 'category.limit', 'title': 'You can have at most 50 categories.'});
    expect((await repository.create('One more')).failureOrNull!.code, FailureCodes.categoryLimit);

    respond = (_) => (400, {
          'status': 400,
          'code': 'validation.failed',
          'title': 'Validation failed.',
          'errors': {
            'name': ['category.name_invalid'],
          },
        });
    final invalid = (await repository.rename('c-1', '!!!')).failureOrNull!;
    expect(invalid.code, FailureCodes.validationFailed);
    expect(invalid.fieldErrors['name'], ['category.name_invalid']);
  });

  test('DELETE /me/categories/{id} → 204; PUT /me/categories/order sends the ids and answers the list', () async {
    respond = (_) => (204, null);
    expect((await repository.delete('c-3')).isOk, isTrue);
    expect(call(0), 'DELETE /me/categories/c-3');

    respond = (_) => categoryListJson([efCore.copyWith(sortOrder: 1), backendTips.copyWith(sortOrder: 2)], uncategorized: 1);
    final list = (await repository.reorder(['c-2', 'c-1'])).valueOrNull!;
    expect(call(1), 'PUT /me/categories/order');
    expect(body(1), {
      'categoryIds': ['c-2', 'c-1'],
    });
    expect(list.items.map((c) => c.id), ['c-2', 'c-1']);
  });

  test('PUT /articles/{id}/category sends the id, or an explicit null for none', () async {
    respond = (_) => (204, null);
    expect((await repository.setArticleCategory('art-1', 'c-2')).isOk, isTrue);
    expect(call(0), 'PUT /articles/art-1/category');
    expect(body(0), {'categoryId': 'c-2'});

    await repository.setArticleCategory('art-1', null);
    expect(body(1), {'categoryId': null}, reason: 'null is sent, not left out');
    expect(jsonEncode(body(1)), '{"categoryId":null}');

    respond = (_) => (403, {'status': 403, 'code': 'category.not_owner', 'title': "This category isn't yours."});
    expect((await repository.setArticleCategory('art-1', 'c-x')).failureOrNull!.code, FailureCodes.categoryNotOwner);
  });

  test('ArticleDetailsDto.category is the reader\'s "In {name}" link; null or missing is none', () {
    final withCategory = ArticleDetailsModel.fromJson({
      ...detailsJson(1),
      'category': {'slug': 'ef-core', 'name': 'EF Core'},
    }).toEntity();
    expect(withCategory.category, const WriterCategoryRef(slug: 'ef-core', name: 'EF Core'));
    expect(ArticleDetailsModel.fromJson({...detailsJson(1), 'category': null}).toEntity().category, isNull);
    expect(ArticleDetailsModel.fromJson(detailsJson(1)).toEntity().category, isNull);

    // The offline copy of a saved article keeps it.
    final model = ArticleDetailsModel.fromJson({
      ...detailsJson(1),
      'category': {'slug': 'ef-core', 'name': 'EF Core'},
    });
    expect(ArticleDetailsModel.fromJson(jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>).toEntity().category?.slug, 'ef-core');
  });
}
