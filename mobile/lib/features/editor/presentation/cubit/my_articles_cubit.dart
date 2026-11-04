import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/editor_backup.dart';
import '../../domain/entities/editor_entities.dart';
import '../../domain/repositories/article_editor_repository.dart';
import '../../domain/usecases/editor_usecases.dart';

enum MyArticlesStatus { initial, loading, ready, failure }

/// One tab of "My articles": a cursor-paged list.
class MyArticlesTab extends Equatable {
  const MyArticlesTab({
    this.status = MyArticlesStatus.initial,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final MyArticlesStatus status;
  final List<MyArticle> items;
  final String? nextCursor;
  final bool loadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  bool get hasMore => nextCursor != null;

  MyArticlesTab copyWith({
    MyArticlesStatus? status,
    List<MyArticle>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Failure? Function()? failure,
    Failure? Function()? loadMoreFailure,
  }) =>
      MyArticlesTab(
        status: status ?? this.status,
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        loadingMore: loadingMore ?? this.loadingMore,
        failure: failure != null ? failure() : this.failure,
        loadMoreFailure: loadMoreFailure != null ? loadMoreFailure() : this.loadMoreFailure,
      );

  @override
  List<Object?> get props => [status, items, nextCursor, loadingMore, failure, loadMoreFailure];
}

class MyArticlesState extends Equatable {
  const MyArticlesState({
    this.drafts = const MyArticlesTab(),
    this.published = const MyArticlesTab(),
    this.deleting = const {},
    this.notice,
    this.noticeSeq = 0,
  });

  final MyArticlesTab drafts;
  final MyArticlesTab published;

  /// Articles being deleted (their rows are dimmed).
  final Set<String> deleting;

  /// A failed delete to explain once; [noticeSeq] changes with every one.
  final Failure? notice;
  final int noticeSeq;

  MyArticlesTab tab(ArticleLifecycle status) => status == ArticleLifecycle.draft ? drafts : published;

  MyArticlesState withTab(ArticleLifecycle status, MyArticlesTab tab) => MyArticlesState(
        drafts: status == ArticleLifecycle.draft ? tab : drafts,
        published: status == ArticleLifecycle.published ? tab : published,
        deleting: deleting,
        notice: notice,
        noticeSeq: noticeSeq,
      );

  MyArticlesState copyWith({Set<String>? deleting, Failure? notice}) => MyArticlesState(
        drafts: drafts,
        published: published,
        deleting: deleting ?? this.deleting,
        notice: notice ?? this.notice,
        noticeSeq: notice != null ? noticeSeq + 1 : noticeSeq,
      );

  @override
  List<Object?> get props => [drafts, published, deleting, notice, noticeSeq];
}

/// "My articles" (the Write entry, F05): the writer's drafts and published articles, each paged, with delete.
@injectable
class MyArticlesCubit extends Cubit<MyArticlesState> {
  MyArticlesCubit(this._list, this._delete, this._backups) : super(const MyArticlesState());

  final GetMyArticles _list;
  final DeleteArticle _delete;
  final EditorBackupStore _backups;

  final _generation = {ArticleLifecycle.draft: 0, ArticleLifecycle.published: 0};

  /// Loads [status] the first time its tab shows.
  Future<void> ensureLoaded(ArticleLifecycle status) async {
    if (state.tab(status).status == MyArticlesStatus.initial) await load(status);
  }

  /// (Re)loads the first page; rows already shown stay while it loads.
  Future<void> load(ArticleLifecycle status) async {
    final generation = _generation[status] = _generation[status]! + 1;
    final current = state.tab(status);
    emit(state.withTab(
      status,
      current.copyWith(
        status: current.items.isEmpty ? MyArticlesStatus.loading : current.status,
        failure: () => null,
        loadMoreFailure: () => null,
      ),
    ));
    final result = await _list(status);
    if (isClosed || generation != _generation[status]) return;
    emit(result.fold(
      (failure) => state.withTab(
        status,
        state.tab(status).items.isEmpty
            ? MyArticlesTab(status: MyArticlesStatus.failure, failure: failure)
            : state.tab(status).copyWith(status: MyArticlesStatus.ready, failure: () => failure),
      ),
      (page) => state.withTab(
        status,
        MyArticlesTab(status: MyArticlesStatus.ready, items: page.items, nextCursor: page.nextCursor),
      ),
    ));
  }

  Future<void> refreshAll() => Future.wait([
        for (final status in ArticleLifecycle.values)
          if (state.tab(status).status != MyArticlesStatus.initial) load(status),
      ]);

  Future<void> loadMore(ArticleLifecycle status) async {
    final tab = state.tab(status);
    if (tab.status != MyArticlesStatus.ready || tab.loadingMore || !tab.hasMore) return;
    final generation = _generation[status];
    emit(state.withTab(status, tab.copyWith(loadingMore: true, loadMoreFailure: () => null)));
    final result = await _list(status, cursor: tab.nextCursor);
    if (isClosed || generation != _generation[status]) return;
    final latest = state.tab(status);
    emit(result.fold(
      (failure) => state.withTab(status, latest.copyWith(loadingMore: false, loadMoreFailure: () => failure)),
      (page) {
        final known = {for (final a in latest.items) a.id};
        return state.withTab(
          status,
          latest.copyWith(
            loadingMore: false,
            items: [...latest.items, ...page.items.where((a) => !known.contains(a.id))],
            nextCursor: () => page.nextCursor,
          ),
        );
      },
    ));
  }

  /// Deletes [article] (after the page confirmed); its row goes at once and comes back if the API refuses.
  Future<bool> delete(MyArticle article) async {
    if (state.deleting.contains(article.id)) return false;
    final status = article.status;
    final before = state.tab(status);
    emit(state
        .withTab(status, before.copyWith(items: [...before.items.where((a) => a.id != article.id)]))
        .copyWith(deleting: {...state.deleting, article.id}));
    final result = await _delete(article.id);
    if (isClosed) return result.isOk;
    final deleting = {...state.deleting}..remove(article.id);
    if (result case Err(:final failure)) {
      final tab = state.tab(status);
      final restored = tab.items.any((a) => a.id == article.id) ? tab.items : _insertBack(tab.items, before.items, article);
      emit(state.withTab(status, tab.copyWith(items: restored)).copyWith(deleting: deleting, notice: failure));
      return false;
    }
    await _backups.delete(EditorBackup.keyFor(article.id));
    if (!isClosed) emit(state.copyWith(deleting: deleting));
    return true;
  }

  static List<MyArticle> _insertBack(List<MyArticle> now, List<MyArticle> before, MyArticle article) {
    final index = before.indexWhere((a) => a.id == article.id);
    final items = [...now];
    items.insert(index.clamp(0, items.length), article);
    return items;
  }
}
