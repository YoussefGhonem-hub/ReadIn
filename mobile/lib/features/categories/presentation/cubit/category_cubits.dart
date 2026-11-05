import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../domain/entities/writer_category.dart';
import '../../domain/services/category_names.dart';
import '../../domain/usecases/category_usecases.dart';

enum CategoryLoadStatus { loading, ready, failure }

/// `404 category.not_found`: the writer has no category with that slug (any more: a moderator's clear changes it).
bool isCategoryNotFound(Failure? failure) =>
    failure?.code == FailureCodes.categoryNotFound || (failure?.statusCode == 404 && failure?.code != FailureCodes.userNotFound);

/// `404 user.not_found`: the writer deleted their account or is suspended.
bool isWriterNotFound(Failure? failure) => failure?.code == FailureCodes.userNotFound;

// ── The category page ───────────────────────────────────────────────────────

class CategoryPageState extends Equatable {
  const CategoryPageState({this.status = CategoryLoadStatus.loading, this.page, this.failure});

  final CategoryLoadStatus status;
  final WriterCategoryPage? page;
  final Failure? failure;

  bool get notFound => status == CategoryLoadStatus.failure && isCategoryNotFound(failure);
  bool get writerNotFound => status == CategoryLoadStatus.failure && isWriterNotFound(failure);

  @override
  List<Object?> get props => [status, page, failure];
}

/// The category page's header (F31): `GET /users/{username}/categories/{slug}`, its name, article count and writer.
@injectable
class CategoryPageCubit extends Cubit<CategoryPageState> {
  CategoryPageCubit(this._getPage) : super(const CategoryPageState());

  final GetCategoryPage _getPage;
  (String, String)? _target;

  /// Incremented on every load so an older answer is dropped.
  int _generation = 0;

  Future<void> load(String username, String slug) async {
    _target = (username, slug);
    final generation = ++_generation;
    emit(const CategoryPageState());
    final result = await _getPage(username, slug);
    if (generation != _generation || isClosed) return;
    emit(result.fold(
      (failure) => CategoryPageState(status: CategoryLoadStatus.failure, failure: failure),
      (page) => CategoryPageState(status: CategoryLoadStatus.ready, page: page),
    ));
  }

  /// Pull to refresh: the header stays until the new one arrives; a failed refresh keeps it.
  Future<void> refresh() async {
    final target = _target;
    if (target == null) return;
    if (state.page == null) return load(target.$1, target.$2);
    final generation = ++_generation;
    final result = await _getPage(target.$1, target.$2);
    if (generation != _generation || isClosed) return;
    if (result case Ok(value: final page)) emit(CategoryPageState(status: CategoryLoadStatus.ready, page: page));
  }
}

/// The category page's articles (F31): newest first, as post cards, with pull to refresh and infinite scroll.
@injectable
class CategoryArticlesCubit extends ArticleFeedCubit {
  CategoryArticlesCubit(this._getArticles, @factoryParam String username, @factoryParam String slug)
      : _username = username,
        _slug = slug;

  final GetCategoryArticles _getArticles;
  final String _username;
  final String _slug;

  @override
  Future<Result<CursorPage<ArticleCard>>> fetch({String? fieldSlug, String? cursor}) =>
      _getArticles(_username, _slug, cursor: cursor);
}

// ── A profile's Categories tab ──────────────────────────────────────────────

class CategoryListState extends Equatable {
  const CategoryListState({
    this.status = CategoryLoadStatus.loading,
    this.list = WriterCategoryList.empty,
    this.failure,
    this.busy = false,
  });

  final CategoryLoadStatus status;
  final WriterCategoryList list;
  final Failure? failure;

  /// A reorder is on its way to the API (the own list).
  final bool busy;

  List<WriterCategory> get items => list.items;
  int get uncategorizedCount => list.uncategorizedCount;

  /// The writer has reached 50 categories (`category.limit`).
  bool get full => items.length >= CategoryNames.maxPerWriter;

  CategoryListState copyWith({CategoryLoadStatus? status, WriterCategoryList? list, Failure? Function()? failure, bool? busy}) =>
      CategoryListState(
        status: status ?? this.status,
        list: list ?? this.list,
        failure: failure != null ? failure() : this.failure,
        busy: busy ?? this.busy,
      );

  @override
  List<Object?> get props => [status, list, failure, busy];
}

/// Someone's Categories tab (F31, guests too): `GET /users/{username}/categories`, the non-empty categories in the
/// writer's order, then "مقالات تانية".
@injectable
class ProfileCategoriesCubit extends Cubit<CategoryListState> {
  ProfileCategoriesCubit(this._getCategories, @factoryParam String username)
      : _username = username,
        super(const CategoryListState());

  final GetUserCategories _getCategories;
  final String _username;
  int _generation = 0;

  Future<void> load() async {
    emit(const CategoryListState());
    await _fetch();
  }

  /// Pull to refresh: the list stays until the new one arrives; a failed refresh keeps it.
  Future<void> refresh() async {
    if (state.status != CategoryLoadStatus.ready) return load();
    await _fetch();
  }

  Future<void> _fetch() async {
    final generation = ++_generation;
    final result = await _getCategories(_username);
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) {
        if (state.status != CategoryLoadStatus.ready) emit(CategoryListState(status: CategoryLoadStatus.failure, failure: failure));
      },
      (list) => emit(CategoryListState(status: CategoryLoadStatus.ready, list: list)),
    );
  }
}

/// The writer's own Categories tab (F31): `GET /me/categories`, empty ones included, with create, rename, delete and
/// reorder. Every change applies to the list as soon as the API accepts it; a reorder shows at once and goes back if the
/// API refuses it.
@injectable
class MyCategoriesCubit extends Cubit<CategoryListState> {
  MyCategoriesCubit(this._getCategories, this._manage) : super(const CategoryListState());

  final GetMyCategories _getCategories;
  final ManageCategories _manage;
  int _generation = 0;

  Future<void> load() async {
    emit(const CategoryListState());
    await _fetch();
  }

  /// Pull to refresh, and when the tab shows again: the list stays until the new one arrives.
  Future<void> refresh() async {
    if (state.status != CategoryLoadStatus.ready) return load();
    await _fetch();
  }

  Future<void> _fetch() async {
    final generation = ++_generation;
    final result = await _getCategories();
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) {
        if (state.status != CategoryLoadStatus.ready) emit(CategoryListState(status: CategoryLoadStatus.failure, failure: failure));
      },
      (list) => emit(CategoryListState(status: CategoryLoadStatus.ready, list: list)),
    );
  }

  /// `POST /me/categories`: added last.
  Future<Result<WriterCategory>> create(String name) async {
    final result = await _manage.create(name);
    if (isClosed) return result;
    if (result case Ok(value: final category)) {
      _generation++; // a list fetched before it doesn't have it
      emit(state.copyWith(list: WriterCategoryList(items: [...state.items, category], uncategorizedCount: state.uncategorizedCount)));
    }
    return result;
  }

  /// `PATCH /me/categories/{id}`: the name changes, the slug (and its links) stay. Null when it worked.
  Future<Failure?> rename(String id, String name) async {
    final result = await _manage.rename(id, name);
    if (isClosed) return result.failureOrNull;
    if (result case Ok(value: final renamed)) {
      _generation++;
      emit(state.copyWith(
        list: WriterCategoryList(
          items: [for (final c in state.items) c.id == id ? c.copyWith(name: renamed.name) : c],
          uncategorizedCount: state.uncategorizedCount,
        ),
      ));
    }
    return result.failureOrNull;
  }

  /// `DELETE /me/categories/{id}`: its articles join "مقالات تانية". Null when it worked.
  Future<Failure?> delete(String id) async {
    final result = await _manage.delete(id);
    if (isClosed) return result.failureOrNull;
    if (result.isOk) {
      _generation++;
      final deleted = state.items.where((c) => c.id == id).firstOrNull;
      emit(state.copyWith(
        list: WriterCategoryList(
          items: [...state.items.where((c) => c.id != id)],
          uncategorizedCount: state.uncategorizedCount + (deleted?.articleCount ?? 0),
        ),
      ));
    } else if (result.failureOrNull?.code == FailureCodes.categoryNotFound) {
      // Already gone (another device): the list catches up.
      await _fetch();
    }
    return result.failureOrNull;
  }

  /// Moves the category at [from] to [to] (indexes after the move, as a drag or "Move up / down" gives them), then
  /// `PUT /me/categories/order`. Null when it worked; a refusal puts the old order back.
  Future<Failure?> move(int from, int to) async {
    final items = [...state.items];
    if (from < 0 || from >= items.length || to < 0 || to >= items.length || from == to || state.busy) return null;
    final before = state.list;
    items.insert(to, items.removeAt(from));
    final generation = ++_generation;
    emit(state.copyWith(
      list: WriterCategoryList(
        items: [for (final (i, c) in items.indexed) c.copyWith(sortOrder: i + 1)],
        uncategorizedCount: state.uncategorizedCount,
      ),
      busy: true,
    ));
    final result = await _manage.reorder([for (final c in items) c.id]);
    if (isClosed) return result.failureOrNull;
    if (generation != _generation) {
      emit(state.copyWith(busy: false));
      return result.failureOrNull;
    }
    emit(result.fold(
      (_) => state.copyWith(list: before, busy: false),
      (list) => state.copyWith(list: list, busy: false),
    ));
    return result.failureOrNull;
  }
}
