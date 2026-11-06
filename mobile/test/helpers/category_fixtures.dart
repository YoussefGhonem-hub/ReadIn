import 'dart:async';

import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/categories/domain/entities/writer_category.dart';
import 'package:readin/features/categories/domain/repositories/categories_repository.dart';
import 'package:readin/features/categories/domain/services/category_names.dart';
import 'package:readin/features/categories/domain/usecases/category_usecases.dart';

import 'post_card_fixtures.dart';
import 'social_fakes.dart';

/// Writer categories (F31) the way the API sends them: Arabic, English and mixed names, an Arabic slug.
const backendTips = WriterCategory(id: 'c-1', slug: 'نصايح-backend', name: 'نصايح Backend', articleCount: 7, sortOrder: 1);
const efCore = WriterCategory(id: 'c-2', slug: 'ef-core', name: 'EF Core', articleCount: 3, sortOrder: 2);
const careerAr = WriterCategory(id: 'c-3', slug: 'شغل-وكارير', name: 'شغل وكارير', articleCount: 1, sortOrder: 3);
const draftsOnly = WriterCategory(id: 'c-4', slug: 'flutter-notes', name: 'Flutter notes (soon)', sortOrder: 4);

const enCategories = [
  WriterCategory(id: 'c-1', slug: 'backend-tips', name: 'Backend tips', articleCount: 7, sortOrder: 1),
  WriterCategory(id: 'c-2', slug: 'ef-core', name: 'EF Core', articleCount: 3, sortOrder: 2),
  WriterCategory(id: 'c-3', slug: 'career', name: 'Career & هندسة', articleCount: 1, sortOrder: 3),
];

/// The visitor's list (non-empty only) and the owner's (an empty one too), in the UI language.
List<WriterCategory> visitorCategories(String language) => language == 'en' ? enCategories : const [backendTips, efCore, careerAr];

List<WriterCategory> ownCategories(String language) => [
      ...visitorCategories(language),
      if (language == 'en') const WriterCategory(id: 'c-4', slug: 'flutter-notes', name: 'Flutter notes', sortOrder: 4) else draftsOnly,
    ];

/// The writer whose categories these are.
const categoryWriter = writerAr;

/// The signed-in user of an own Categories tab, as `sampleMe` (`reader1`) but allowed to write (`articles.create`),
/// so the tab manages the categories.
const writerMe = Me(
  id: 'u-1',
  phoneNumber: '+12025550110',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  onboardingCompleted: true,
  permissions: [Permissions.articlesCreate, Permissions.reportsCreate],
);

/// The category page's header.
WriterCategoryPage categoryPageOf(WriterCategory category, {Author author = categoryWriter}) =>
    WriterCategoryPage(id: category.id, slug: category.slug, name: category.name, articleCount: category.articleCount, author: author);

/// "مقالات أخرى": `_other`, no id and no name.
WriterCategoryPage otherPage({int count = 4, Author author = categoryWriter}) =>
    WriterCategoryPage(slug: '_other', articleCount: count, author: author);

/// The post cards of a category page: [count] cards from [first], in the page's language, by its writer.
List<ArticleCard> categoryCards({int first = 1, int count = 2, String language = 'ar-EG', Author author = categoryWriter}) => [
      for (var i = first; i < first + count; i++) postCard(i, language: language, cover: false, author: author, tagCount: 3),
    ];

/// `WriterCategoryDto` JSON.
Map<String, dynamic> categoryJson(WriterCategory c) =>
    {'id': c.id, 'slug': c.slug, 'name': c.name, 'articleCount': c.articleCount, 'sortOrder': c.sortOrder};

/// `WriterCategoryListDto` JSON.
Map<String, dynamic> categoryListJson(List<WriterCategory> items, {int uncategorized = 0}) =>
    {'items': [for (final c in items) categoryJson(c)], 'uncategorizedCount': uncategorized};

/// Scriptable [CategoriesRepository] holding one writer's categories in memory ([mine], the `/me` list), what visitors
/// see of them, the page headers ([pages], 404 for any other slug) and the articles of a slug ([articles], a list of
/// pages with cursors `c1`, `c2`, …). Every call is recorded; writes change [mine] like the API would.
class FakeCategoriesRepository implements CategoriesRepository {
  FakeCategoriesRepository({
    List<WriterCategory> mine = const [],
    this.uncategorized = 0,
    this.pages = const {},
    this.articles = const {},
  }) : mine = [...mine];

  List<WriterCategory> mine;
  int uncategorized;
  final Map<String, WriterCategoryPage> pages;
  final Map<String, List<List<ArticleCard>>> articles;
  final calls = <String>[];

  /// Answers every call with this failure instead (e.g. offline).
  Failure? failure;

  /// Fails only these calls (by their name in [calls], e.g. `reorder`, `set art-1`).
  final failures = <String, Failure>{};

  /// Holds the answers until completed, to see the loading states.
  Completer<void>? gate;

  static const notFound = Failure(FailureCodes.categoryNotFound, statusCode: 404);
  static const userNotFound = Failure(FailureCodes.userNotFound, statusCode: 404);

  /// The articles' categories, as `PUT /articles/{id}/category` left them.
  final articleCategories = <String, String?>{};

  Future<Failure?> _answer(String call) async {
    calls.add(call);
    await gate?.future;
    return failure ?? failures[call.split(' ').first] ?? failures[call];
  }

  WriterCategoryList get _visible => WriterCategoryList(items: [...mine.where((c) => c.articleCount > 0)], uncategorizedCount: uncategorized);

  @override
  Future<Result<WriterCategoryList>> getUserCategories(String username) async {
    if (await _answer('user $username') case final f?) return Err(f);
    return Ok(_visible);
  }

  @override
  Future<Result<WriterCategoryPage>> getCategoryPage(String username, String slug) async {
    if (await _answer('page $username $slug') case final f?) return Err(f);
    final page = pages[slug];
    return page == null ? const Err(notFound) : Ok(page);
  }

  @override
  Future<Result<CursorPage<ArticleCard>>> getCategoryArticles(String username, String slug, {String? cursor, int limit = 20}) async {
    if (await _answer('articles $username $slug${cursor == null ? '' : ' $cursor'}') case final f?) return Err(f);
    final all = articles[slug];
    if (all == null) return const Err(notFound);
    final index = cursor == null ? 0 : int.parse(cursor.substring(1));
    final page = index < all.length ? all[index] : const <ArticleCard>[];
    return Ok(CursorPage(items: page, nextCursor: index + 1 < all.length ? 'c${index + 1}' : null));
  }

  @override
  Future<Result<WriterCategoryList>> getMyCategories() async {
    if (await _answer('mine') case final f?) return Err(f);
    return Ok(WriterCategoryList(items: [...mine], uncategorizedCount: uncategorized));
  }

  @override
  Future<Result<WriterCategory>> create(String name) async {
    if (await _answer('create $name') case final f?) return Err(f);
    if (mine.length >= CategoryNames.maxPerWriter) return const Err(Failure(FailureCodes.categoryLimit, statusCode: 400));
    if (CategoryNames.isTaken(mine, name)) return const Err(Failure(FailureCodes.categoryNameTaken, statusCode: 409));
    final created = WriterCategory(id: 'c-new-${mine.length + 1}', slug: 'new-${mine.length + 1}', name: name, sortOrder: mine.length + 1);
    mine = [...mine, created];
    return Ok(created);
  }

  @override
  Future<Result<WriterCategory>> rename(String id, String name) async {
    if (await _answer('rename $id $name') case final f?) return Err(f);
    final current = mine.where((c) => c.id == id).firstOrNull;
    if (current == null) return const Err(notFound);
    if (CategoryNames.isTaken(mine, name, exceptId: id)) return const Err(Failure(FailureCodes.categoryNameTaken, statusCode: 409));
    final renamed = current.copyWith(name: name);
    mine = [for (final c in mine) c.id == id ? renamed : c];
    return Ok(renamed);
  }

  @override
  Future<Result<void>> delete(String id) async {
    if (await _answer('delete $id') case final f?) return Err(f);
    final deleted = mine.where((c) => c.id == id).firstOrNull;
    if (deleted == null) return const Err(notFound);
    mine = [...mine.where((c) => c.id != id)];
    uncategorized += deleted.articleCount;
    return const Ok(null);
  }

  @override
  Future<Result<WriterCategoryList>> reorder(List<String> categoryIds) async {
    if (await _answer('reorder ${categoryIds.join(',')}') case final f?) return Err(f);
    final byId = {for (final c in mine) c.id: c};
    final ordered = [
      for (final id in categoryIds) ?byId.remove(id),
      ...byId.values,
    ];
    mine = [for (final (i, c) in ordered.indexed) c.copyWith(sortOrder: i + 1)];
    return Ok(WriterCategoryList(items: [...mine], uncategorizedCount: uncategorized));
  }

  @override
  Future<Result<void>> setArticleCategory(String articleId, String? categoryId) async {
    if (await _answer('set $articleId ${categoryId ?? 'none'}') case final f?) return Err(f);
    if (categoryId != null && !mine.any((c) => c.id == categoryId)) return const Err(notFound);
    articleCategories[articleId] = categoryId;
    return const Ok(null);
  }
}

/// The editor's category use cases over [repo]: `GetMyCategories`, `ManageCategories`, `SetArticleCategory`.
(GetMyCategories, ManageCategories, SetArticleCategory) editorCategoryUseCases(CategoriesRepository repo) =>
    (GetMyCategories(repo), ManageCategories(repo), SetArticleCategory(repo));
