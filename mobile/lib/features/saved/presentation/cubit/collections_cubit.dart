import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../domain/entities/saved.dart';
import '../../domain/usecases/saved_usecases.dart';

enum CollectionsStatus { idle, loading, ready, failure }

class CollectionsState extends Equatable {
  const CollectionsState({
    this.status = CollectionsStatus.idle,
    this.items = const [],
    this.membership = const {},
    this.busy = const {},
    this.failure,
  });

  final CollectionsStatus status;

  /// In name order, like the API.
  final List<ArticleCollection> items;

  /// Article id → the collections it is in, as far as this device knows: the Saved list says it for its articles,
  /// and every change made here updates it. Unknown articles have no entry.
  final Map<String, Set<String>> membership;

  /// "collectionId|articleId" pairs with a request in flight (no double submits).
  final Set<String> busy;
  final Failure? failure;

  ArticleCollection? byId(String? id) => id == null ? null : items.where((c) => c.id == id).firstOrNull;

  Set<String> collectionsOf(String articleId) => membership[articleId] ?? const {};

  bool isBusy(String collectionId, String articleId) => busy.contains('$collectionId|$articleId');

  CollectionsState copyWith({
    CollectionsStatus? status,
    List<ArticleCollection>? items,
    Map<String, Set<String>>? membership,
    Set<String>? busy,
    Failure? Function()? failure,
  }) =>
      CollectionsState(
        status: status ?? this.status,
        items: items ?? this.items,
        membership: membership ?? this.membership,
        busy: busy ?? this.busy,
        failure: failure != null ? failure() : this.failure,
      );

  @override
  List<Object?> get props => [status, items, membership, busy, failure];
}

/// An article was put in a collection or taken out of it.
class MembershipChange extends Equatable {
  const MembershipChange({required this.collectionId, required this.articleId, required this.added});

  final String collectionId;
  final String articleId;
  final bool added;

  @override
  List<Object?> get props => [collectionId, articleId, added];
}

/// The viewer's collections (F13), shared by the Saved tab and the "add to collection" sheet.
@lazySingleton
class CollectionsCubit extends Cubit<CollectionsState> {
  CollectionsCubit(this._getCollections, this._manage, EngagementCubit engagement) : super(const CollectionsState()) {
    _savedChanges = engagement.savedChanges.listen(_onSavedChange);
  }

  final GetCollections _getCollections;
  final ManageCollections _manage;
  late final StreamSubscription<SavedChange> _savedChanges;
  final _changes = StreamController<MembershipChange>.broadcast();

  /// Articles put in or taken out of collections (the Saved list filtered by one follows them).
  Stream<MembershipChange> get changes => _changes.stream;

  /// Loads once; [force] reloads (pull to refresh, retry).
  Future<void> load({bool force = false}) async {
    if (!force && (state.status == CollectionsStatus.ready || state.status == CollectionsStatus.loading)) return;
    emit(state.copyWith(status: state.items.isEmpty ? CollectionsStatus.loading : state.status, failure: () => null));
    final result = await _getCollections();
    if (isClosed) return;
    emit(result.fold(
      (failure) => state.copyWith(status: state.items.isEmpty ? CollectionsStatus.failure : state.status, failure: () => failure),
      (items) => state.copyWith(status: CollectionsStatus.ready, items: items, failure: () => null),
    ));
  }

  /// What the Saved list says about its articles.
  void seedMembership(Iterable<SavedArticle> saved) =>
      _seed({for (final item in saved) item.article.id: item.collectionIds});

  /// What the reader loaded (`ArticleDetailsDto.collectionIds`), so "add to collection" opens with them ticked.
  void seedArticle(String articleId, List<String> collectionIds) => _seed({articleId: collectionIds});

  /// Fresh API values win, except for an article with an add or remove in flight (its optimistic state stays).
  /// Sets keep insertion order, so the API's oldest-first order holds and new additions go last.
  void _seed(Map<String, List<String>> byArticle) {
    if (isClosed) return;
    final next = {...state.membership};
    byArticle.forEach((articleId, collectionIds) {
      if (state.busy.any((key) => key.endsWith('|$articleId'))) return;
      next[articleId] = {...collectionIds};
    });
    emit(state.copyWith(membership: next));
  }

  Future<Result<ArticleCollection>> create(String name) async {
    final result = await _manage.create(name);
    if (result case Ok(value: final created) when !isClosed) {
      emit(state.copyWith(status: CollectionsStatus.ready, items: _sorted([...state.items, created])));
    }
    return result;
  }

  Future<Failure?> rename(String id, String name) async {
    final result = await _manage.rename(id, name);
    if (isClosed) return null;
    return result.fold(
      (failure) => _onFailure(id, failure),
      (renamed) {
        emit(state.copyWith(items: _sorted([for (final c in state.items) c.id == id ? renamed : c])));
        return null;
      },
    );
  }

  /// Removed at once; put back when the API refuses. The articles stay saved.
  Future<Failure?> delete(String id) async {
    final before = state;
    emit(state.copyWith(
      items: [for (final c in state.items) if (c.id != id) c],
      membership: {for (final e in state.membership.entries) e.key: {...e.value}..remove(id)},
    ));
    final result = await _manage.delete(id);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        if (failure.code == FailureCodes.collectionNotFound) return failure; // already gone
        emit(before);
        return failure;
      },
      (_) => null,
    );
  }

  /// Puts [articleId] in [collectionId] (the caller saves the article first). Optimistic, with rollback.
  Future<Failure?> add(String collectionId, String articleId) => _setMember(collectionId, articleId, member: true);

  /// Takes [articleId] out of [collectionId]; it stays saved.
  Future<Failure?> remove(String collectionId, String articleId) => _setMember(collectionId, articleId, member: false);

  Future<Failure?> _setMember(String collectionId, String articleId, {required bool member}) async {
    final key = '$collectionId|$articleId';
    final known = state.membership.containsKey(articleId);
    final wasMember = state.collectionsOf(articleId).contains(collectionId);
    if (state.busy.contains(key) || (known && wasMember == member)) return null;
    final before = state;
    emit(state.copyWith(
      busy: {...state.busy, key},
      membership: {...state.membership, articleId: {...state.collectionsOf(articleId)}..toggle(collectionId, member)},
      items: [
        for (final c in state.items)
          c.id == collectionId && wasMember != member
              ? c.copyWith(articleCount: math.max(0, c.articleCount + (member ? 1 : -1)))
              : c,
      ],
    ));
    final result = member ? await _manage.add(collectionId, articleId) : await _manage.remove(collectionId, articleId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        emit(before.copyWith(busy: {...state.busy}..remove(key)));
        return _onFailure(collectionId, failure);
      },
      (_) {
        emit(state.copyWith(busy: {...state.busy}..remove(key)));
        _changes.add(MembershipChange(collectionId: collectionId, articleId: articleId, added: member));
        return null;
      },
    );
  }

  /// `collection.not_found`: it was deleted elsewhere, so it leaves the list too.
  Failure _onFailure(String collectionId, Failure failure) {
    if (failure.code == FailureCodes.collectionNotFound) {
      emit(state.copyWith(items: [for (final c in state.items) if (c.id != collectionId) c]));
    }
    return failure;
  }

  /// Unsaving takes an article out of every collection.
  void _onSavedChange(SavedChange change) {
    if (change.isSaved || isClosed) return;
    final articleId = change.article.id;
    final inCollections = state.collectionsOf(articleId);
    emit(state.copyWith(
      membership: {...state.membership, articleId: const {}},
      items: [
        for (final c in state.items)
          inCollections.contains(c.id) ? c.copyWith(articleCount: c.articleCount > 0 ? c.articleCount - 1 : 0) : c,
      ],
    ));
  }

  /// Another account (or a guest) is using the app.
  void reset() {
    if (!isClosed) emit(const CollectionsState());
  }

  static List<ArticleCollection> _sorted(List<ArticleCollection> items) =>
      items..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Future<void> close() async {
    await _savedChanges.cancel();
    await _changes.close();
    return super.close();
  }
}

extension on Set<String> {
  void toggle(String value, bool present) => present ? add(value) : remove(value);
}
