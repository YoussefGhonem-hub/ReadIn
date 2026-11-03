import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../domain/entities/saved.dart';
import '../../domain/usecases/saved_usecases.dart';
import 'collections_cubit.dart';

enum SavedListStatus { loading, ready, failure }

class SavedListState extends Equatable {
  const SavedListState({
    this.status = SavedListStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.filter = const SavedFilter(),
    this.loadingMore = false,
    this.failure,
    this.loadMoreFailure,
    this.offline = false,
    this.fields = const [],
  });

  final SavedListStatus status;
  final List<SavedArticle> items;
  final String? nextCursor;
  final SavedFilter filter;
  final bool loadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  /// The API was unreachable: [items] are the copies kept on this device.
  final bool offline;

  /// Field chips.
  final List<Field> fields;

  bool get hasMore => nextCursor != null;

  SavedListState copyWith({
    SavedListStatus? status,
    List<SavedArticle>? items,
    String? Function()? nextCursor,
    SavedFilter? filter,
    bool? loadingMore,
    Failure? Function()? failure,
    Failure? Function()? loadMoreFailure,
    bool? offline,
    List<Field>? fields,
  }) =>
      SavedListState(
        status: status ?? this.status,
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        filter: filter ?? this.filter,
        loadingMore: loadingMore ?? this.loadingMore,
        failure: failure != null ? failure() : this.failure,
        loadMoreFailure: loadMoreFailure != null ? loadMoreFailure() : this.loadMoreFailure,
        offline: offline ?? this.offline,
        fields: fields ?? this.fields,
      );

  @override
  List<Object?> get props => [status, items, nextCursor, filter, loadingMore, failure, loadMoreFailure, offline, fields];
}

/// The Saved tab's list (F13): newest saved first, filtered by field, title search (debounced) or one collection,
/// paged. Offline it shows the device copies (F25). Follows saves, unsaves and collection changes made anywhere.
@injectable
class SavedListCubit extends Cubit<SavedListState> {
  SavedListCubit(this._getSaved, this._getFields, this._engagement, this._collections) : super(const SavedListState()) {
    _subscriptions = [
      _engagement.savedChanges.listen(_onSavedChange),
      _collections.changes.listen(_onMembershipChange),
    ];
  }

  final GetSavedArticles _getSaved;
  final GetFields _getFields;
  final EngagementCubit _engagement;
  final CollectionsCubit _collections;
  late final List<StreamSubscription<Object>> _subscriptions;

  static const searchDebounce = Duration(milliseconds: 350);

  Timer? _debounce;

  /// Incremented on every reset so responses for an older filter are dropped.
  int _generation = 0;

  Future<void> load() async {
    _debounce?.cancel();
    final generation = ++_generation;
    emit(SavedListState(filter: state.filter, fields: state.fields));
    if (state.fields.isEmpty) unawaited(_loadFields());
    final result = await _getSaved(filter: state.filter);
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: SavedListStatus.failure, failure: () => failure)),
      (page) {
        _accept(page);
        emit(state.copyWith(status: SavedListStatus.ready, items: page.items, nextCursor: () => page.nextCursor, offline: page.offline));
      },
    );
  }

  Future<void> _loadFields() async {
    final fields = (await _getFields()).valueOrNull;
    if (fields != null && !isClosed) emit(state.copyWith(fields: fields));
  }

  /// Title search; runs [searchDebounce] after the last keystroke.
  void search(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query == (state.filter.query ?? '')) return;
    _debounce = Timer(searchDebounce, () => _setFilter(_with(query: query.isEmpty ? null : query)));
  }

  Future<void> selectField(String? fieldSlug) => _setFilter(_with(fieldSlug: fieldSlug));

  /// Only the articles of one collection (null: every saved article).
  Future<void> selectCollection(String? collectionId) => _setFilter(_with(collectionId: collectionId));

  SavedFilter _with({Object? fieldSlug = _keep, Object? query = _keep, Object? collectionId = _keep}) => SavedFilter(
        fieldSlug: identical(fieldSlug, _keep) ? state.filter.fieldSlug : fieldSlug as String?,
        query: identical(query, _keep) ? state.filter.query : query as String?,
        collectionId: identical(collectionId, _keep) ? state.filter.collectionId : collectionId as String?,
      );

  static const _keep = Object();

  Future<void> _setFilter(SavedFilter filter) async {
    if (filter == state.filter && state.status == SavedListStatus.ready) return;
    emit(state.copyWith(filter: filter));
    await load();
  }

  /// Pull to refresh: the current items stay until the new page arrives.
  Future<void> refresh() async {
    final generation = ++_generation;
    final result = await _getSaved(filter: state.filter);
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) => emit(state.items.isEmpty
          ? state.copyWith(status: SavedListStatus.failure, failure: () => failure)
          : state.copyWith(loadMoreFailure: () => failure)),
      (page) {
        _accept(page);
        emit(state.copyWith(
          status: SavedListStatus.ready,
          items: page.items,
          nextCursor: () => page.nextCursor,
          offline: page.offline,
          failure: () => null,
          loadMoreFailure: () => null,
        ));
      },
    );
  }

  Future<void> loadMore() async {
    if (state.status != SavedListStatus.ready || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailure: () => null));
    final result = await _getSaved(filter: state.filter, cursor: state.nextCursor);
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(loadingMore: false, loadMoreFailure: () => failure)),
      (page) {
        _accept(page);
        emit(state.copyWith(loadingMore: false, items: [...state.items, ...page.items], nextCursor: () => page.nextCursor));
      },
    );
  }

  /// Fresh API values become the newest everywhere; device copies are older than anything the app knows.
  void _accept(SavedArticlesPage page) {
    if (page.offline) return;
    _engagement.seed(page.items.map((item) => item.article));
    _collections.seedMembership(page.items);
  }

  void _onSavedChange(SavedChange change) {
    if (isClosed || state.status != SavedListStatus.ready) return;
    if (!change.isSaved) {
      emit(state.copyWith(items: [for (final item in state.items) if (item.article.id != change.article.id) item]));
    } else if (!state.items.any((item) => item.article.id == change.article.id)) {
      unawaited(refresh()); // saved somewhere else: it belongs at the top
    }
  }

  void _onMembershipChange(MembershipChange change) {
    if (isClosed || state.status != SavedListStatus.ready) return;
    final inList = state.items.any((item) => item.article.id == change.articleId);
    if (state.filter.collectionId == change.collectionId) {
      if (!change.added && inList) {
        emit(state.copyWith(items: [for (final item in state.items) if (item.article.id != change.articleId) item]));
      } else if (change.added && !inList) {
        unawaited(refresh());
      }
    }
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await Future.wait(_subscriptions.map((s) => s.cancel()));
    return super.close();
  }
}
