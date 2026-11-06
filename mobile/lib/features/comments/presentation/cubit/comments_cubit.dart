import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/comment_text.dart';
import '../../domain/usecases/comment_usecases.dart';
import 'comment_drafts.dart';

enum CommentsStatus { loading, ready, failure }

enum ComposerIntent { reply, edit }

/// What the composer is doing besides writing a new comment: replying to [comment], or editing it.
class ComposerTarget extends Equatable {
  const ComposerTarget.reply(this.comment) : intent = ComposerIntent.reply;
  const ComposerTarget.edit(this.comment) : intent = ComposerIntent.edit;

  final ComposerIntent intent;
  final Comment comment;

  bool get isEdit => intent == ComposerIntent.edit;

  @override
  List<Object?> get props => [intent, comment];
}

/// A top-level comment and its replies (one level), paged like Facebook and LinkedIn: at first only the oldest reply
/// shows; "show N more replies" reveals up to [GetComments.repliesPageSize] more a tap (the loaded ones first, then
/// pages of `/comments/{id}/replies`); "Hide replies" goes back to the first one. New replies (the viewer's own and
/// live ones) always show, at the end of the thread.
class CommentThread extends Equatable {
  const CommentThread({
    required this.comment,
    this.replies = const [],
    this.shownCount = 1,
    this.alwaysShown = const {},
    this.repliesCursor,
    this.repliesFetched = false,
    this.loadingReplies = false,
    this.repliesFailure,
  });

  /// A comment from a list, with the replies the API included.
  factory CommentThread.of(Comment comment) =>
      CommentThread(comment: comment.copyWith(replies: const []), replies: comment.replies);

  final Comment comment;

  /// Every reply loaded so far, shown or not: oldest first, the viewer's pending ones last.
  final List<Comment> replies;

  /// How many of the older replies (all but [alwaysShown]) show, oldest first. More than are loaded is fine: the next
  /// ones loaded then show.
  final int shownCount;

  /// Replies that show whatever [shownCount] says: the viewer's new replies and replies that arrived live.
  final Set<String> alwaysShown;

  /// The next page of `/comments/{id}/replies`, once it was fetched.
  final String? repliesCursor;
  final bool repliesFetched;
  final bool loadingReplies;
  final Failure? repliesFailure;

  String get id => comment.id;

  /// The replies on screen, in order.
  List<Comment> get visibleReplies {
    final visible = <Comment>[];
    var older = 0;
    for (final reply in replies) {
      if (alwaysShown.contains(reply.id)) {
        visible.add(reply);
      } else if (older < shownCount) {
        visible.add(reply);
        older++;
      }
    }
    return visible;
  }

  /// Loaded replies that are hidden: "show more" reveals these before fetching.
  int get hiddenLoaded => replies.length - visibleReplies.length;

  /// The API has replies that aren't loaded yet.
  bool get hasUnloadedReplies => repliesFetched ? repliesCursor != null : comment.replyCount > replies.length;

  /// "Show N more replies" applies.
  bool get hasMoreReplies => hiddenLoaded > 0 || hasUnloadedReplies;

  /// The N of "show N more replies": the replies not on screen, loaded or not (0 when the count isn't known).
  int get moreReplies => math.max(0, math.max(comment.replyCount, replies.length) - visibleReplies.length);

  /// "Hide replies" applies: more than the first reply shows.
  bool get canHideReplies => visibleReplies.length > 1;

  bool get hasReplies => replies.isNotEmpty || comment.replyCount > 0;

  CommentThread copyWith({
    Comment? comment,
    List<Comment>? replies,
    int? shownCount,
    Set<String>? alwaysShown,
    String? Function()? repliesCursor,
    bool? repliesFetched,
    bool? loadingReplies,
    Failure? Function()? repliesFailure,
  }) =>
      CommentThread(
        comment: comment ?? this.comment,
        replies: replies ?? this.replies,
        shownCount: shownCount ?? this.shownCount,
        alwaysShown: alwaysShown ?? this.alwaysShown,
        repliesCursor: repliesCursor != null ? repliesCursor() : this.repliesCursor,
        repliesFetched: repliesFetched ?? this.repliesFetched,
        loadingReplies: loadingReplies ?? this.loadingReplies,
        repliesFailure: repliesFailure != null ? repliesFailure() : this.repliesFailure,
      );

  @override
  List<Object?> get props =>
      [comment, replies, shownCount, alwaysShown, repliesCursor, repliesFetched, loadingReplies, repliesFailure];
}

class CommentsState extends Equatable {
  const CommentsState({
    this.status = CommentsStatus.loading,
    this.sort = CommentSort.top,
    this.threads = const [],
    this.nextCursor,
    this.total,
    this.loadingMore = false,
    this.refreshing = false,
    this.failure,
    this.loadMoreFailure,
    this.incoming = const [],
    this.highlighted = const {},
    this.pendingIds = const {},
    this.target,
    this.sending = false,
  });

  final CommentsStatus status;
  final CommentSort sort;
  final List<CommentThread> threads;
  final String? nextCursor;

  /// The article's comment count; null until the first page.
  final int? total;
  final bool loadingMore;
  final bool refreshing;
  final Failure? failure;
  final Failure? loadMoreFailure;

  /// New top-level comments waiting behind the "N new comments" pill (F27), newest first.
  final List<Comment> incoming;

  /// Comments that just arrived live: they get a short highlight.
  final Set<String> highlighted;

  /// The viewer's comments on their way to the API.
  final Set<String> pendingIds;
  final ComposerTarget? target;

  /// An edit is being saved.
  final bool sending;

  bool get hasMore => nextCursor != null;

  CommentsState copyWith({
    CommentsStatus? status,
    List<CommentThread>? threads,
    String? Function()? nextCursor,
    int? Function()? total,
    bool? loadingMore,
    bool? refreshing,
    Failure? Function()? loadMoreFailure,
    List<Comment>? incoming,
    Set<String>? highlighted,
    Set<String>? pendingIds,
    ComposerTarget? Function()? target,
    bool? sending,
  }) =>
      CommentsState(
        status: status ?? this.status,
        sort: sort,
        threads: threads ?? this.threads,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        total: total != null ? total() : this.total,
        loadingMore: loadingMore ?? this.loadingMore,
        refreshing: refreshing ?? this.refreshing,
        failure: failure,
        loadMoreFailure: loadMoreFailure != null ? loadMoreFailure() : this.loadMoreFailure,
        incoming: incoming ?? this.incoming,
        highlighted: highlighted ?? this.highlighted,
        pendingIds: pendingIds ?? this.pendingIds,
        target: target != null ? target() : this.target,
        sending: sending ?? this.sending,
      );

  @override
  List<Object?> get props => [
        status,
        sort,
        threads,
        nextCursor,
        total,
        loadingMore,
        refreshing,
        failure,
        loadMoreFailure,
        incoming,
        highlighted,
        pendingIds,
        target,
        sending,
      ];
}

/// One article's comments (F11) while the comments sheet is open, or the reader shows them under the article: Top /
/// Newest pages, threads with "show N more replies", the viewer's own actions and live events (F27).
///
/// The viewer's actions apply at once (a new comment shows as pending, a like counts at once) and roll back when the
/// API refuses them. Live events carry no content: the comment is fetched and inserted or replaced in place, deduped
/// by id, and events for the viewer's own in-flight changes are skipped, so nothing shows or counts twice.
@injectable
class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit(
    this._get,
    this._post,
    this._edit,
    this._delete,
    this._like,
    this._pin,
    this._moderate,
    this._realtime, {
    @ignoreParam DateTime Function()? clock,
    this._drafts,
  })  : _clock = clock ?? DateTime.now,
        super(const CommentsState());

  final GetComments _get;
  final PostComment _post;
  final EditComment _edit;
  final DeleteComment _delete;
  final SetCommentLiked _like;
  final SetCommentPinned _pin;
  final ModerateComment _moderate;
  final RealtimeService _realtime;
  final DateTime Function() _clock;
  final CommentDrafts? _drafts;

  /// How long a comment that arrived live stays highlighted.
  static const highlightFor = Duration(seconds: 2);

  String? _articleId;
  StreamSubscription<CommentEvent>? _events;
  bool _nearTop = true;
  int _pendingSeq = 0;
  int _postsInFlight = 0;
  int _generation = 0;

  /// Comments with one of the viewer's own changes in flight: live events for them are skipped.
  final _busy = <String>{};

  /// Comments being fetched for a "created" event (a repeated event fetches once).
  final _fetching = <String>{};

  /// The newest refetch of each comment, so an older answer never replaces a newer one.
  final _versions = <String, int>{};
  final _timers = <Timer>{};

  String? get articleId => _articleId;

  /// Loads the first page ([GetComments.firstPageSize] threads) and follows the article's comment events until [close].
  Future<void> load(String articleId) async {
    _articleId = articleId;
    _events ??= _realtime.commentEvents(articleId).listen(
          (event) => unawaited(_onEvent(event)),
          onError: (Object error) => debugPrint('Comment events stopped: $error'),
        );
    await _loadFirst(state.sort, refresh: false);
  }

  Future<void> retry() => _loadFirst(state.sort, refresh: false);

  /// Pull to refresh: the list stays while the first page reloads. The failure, if any, for a message.
  Future<Failure?> refresh() => _loadFirst(state.sort, refresh: state.status == CommentsStatus.ready);

  Future<void> changeSort(CommentSort sort) async {
    if (sort == state.sort && state.status == CommentsStatus.ready) return;
    await _loadFirst(sort, refresh: false);
  }

  Future<Failure?> _loadFirst(CommentSort sort, {required bool refresh}) async {
    final articleId = _articleId;
    if (articleId == null) return null;
    final generation = ++_generation;
    emit(refresh
        ? state.copyWith(refreshing: true)
        : CommentsState(sort: sort, total: state.total, target: state.target, pendingIds: state.pendingIds));
    final result = await _get(articleId, sort: sort, limit: GetComments.firstPageSize);
    if (isClosed || generation != _generation) return null;
    return result.fold(
      (failure) {
        emit(refresh
            ? state.copyWith(refreshing: false)
            : CommentsState(
                status: CommentsStatus.failure,
                sort: sort,
                total: state.total,
                failure: failure,
                target: state.target,
                pendingIds: state.pendingIds,
              ));
        return failure;
      },
      (page) {
        emit(CommentsState(
          status: CommentsStatus.ready,
          sort: sort,
          threads: [for (final c in page.items) CommentThread.of(c)],
          nextCursor: page.nextCursor,
          total: page.total,
          target: state.target,
          pendingIds: state.pendingIds,
          highlighted: state.highlighted,
          sending: state.sending,
        ));
        return null;
      },
    );
  }

  /// The next page of top-level comments, [GetComments.pageSize] of them (comments already shown, e.g. ones that
  /// arrived live, are skipped).
  Future<void> loadMore() async {
    final articleId = _articleId;
    if (articleId == null || state.status != CommentsStatus.ready || state.loadingMore || state.refreshing || !state.hasMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailure: () => null));
    final result = await _get(articleId, sort: state.sort, cursor: state.nextCursor, limit: GetComments.pageSize);
    if (isClosed || generation != _generation) return;
    result.fold(
      (failure) => emit(state.copyWith(loadingMore: false, loadMoreFailure: () => failure)),
      (page) {
        final known = _knownIds();
        emit(state.copyWith(
          threads: [...state.threads, for (final c in page.items) if (!known.contains(c.id)) CommentThread.of(c)],
          nextCursor: () => page.nextCursor,
          loadingMore: false,
        ));
      },
    );
  }

  /// "Show N more replies" (and its retry): up to [GetComments.repliesPageSize] more replies show. Hidden replies
  /// already loaded show first, at once; when they are fewer, the next page of the thread is fetched (the first page
  /// has no cursor and repeats the replies the list included: they are deduped) and its new replies make up the rest.
  Future<void> loadMoreReplies(String threadId) async {
    final thread = _thread(threadId);
    if (thread == null || thread.loadingReplies || !thread.hasMoreReplies) return;
    const step = GetComments.repliesPageSize;
    final fromMemory = math.min(step, thread.hiddenLoaded);
    final fetch = fromMemory < step && thread.hasUnloadedReplies;
    _updateThread(
      threadId,
      (t) => t.copyWith(shownCount: _olderShown(t) + fromMemory, loadingReplies: fetch, repliesFailure: () => null),
    );
    if (!fetch) return;
    final result = await _get.replies(threadId, cursor: thread.repliesFetched ? thread.repliesCursor : null);
    if (isClosed) return;
    result.fold(
      (failure) => _updateThread(threadId, (t) => t.copyWith(loadingReplies: false, repliesFailure: () => failure)),
      (page) => _updateThread(threadId, (t) {
        final merged = t.copyWith(
          replies: _mergeReplies(t.replies, page.items),
          repliesCursor: () => page.nextCursor,
          repliesFetched: true,
          loadingReplies: false,
        );
        return merged.copyWith(shownCount: _olderShown(merged) + math.min(step - fromMemory, merged.hiddenLoaded));
      }),
    );
  }

  /// "Hide replies": the thread goes back to its first reply (the viewer's replies on their way stay). Loaded replies
  /// stay loaded, so "show more" reveals them again before fetching.
  void hideReplies(String threadId) {
    final thread = _thread(threadId);
    if (thread == null || thread.loadingReplies) return;
    _updateThread(
      threadId,
      (t) => t.copyWith(shownCount: 1, alwaysShown: t.alwaysShown.intersection(state.pendingIds), repliesFailure: () => null),
    );
  }

  /// How many older replies (not [CommentThread.alwaysShown]) [thread] shows now: its [CommentThread.shownCount],
  /// unless fewer are loaded.
  static int _olderShown(CommentThread thread) =>
      thread.visibleReplies.where((r) => !thread.alwaysShown.contains(r.id)).length;

  // ── Composer ─────────────────────────────────────────────────────

  /// The viewer's unsent comment on this article, kept while the sheet was closed (F34).
  String get draft => _articleId == null ? '' : _drafts?.of(_articleId!) ?? '';

  /// Keeps the composer's text for the next time the sheet opens; blank text forgets it.
  void saveDraft(String text) {
    if (_articleId case final articleId?) _drafts?.put(articleId, text);
  }

  void startReply(Comment comment) => emit(state.copyWith(target: () => ComposerTarget.reply(comment)));

  void startEdit(Comment comment) => emit(state.copyWith(target: () => ComposerTarget.edit(comment)));

  void clearTarget() => emit(state.copyWith(target: () => null));

  /// Posts [text] as a new comment, a reply ([ComposerTarget.reply]) or an edit ([ComposerTarget.edit]). A new
  /// comment or reply shows at once as pending, by [author], and the API's comment replaces it. Null on success, else
  /// the failure (after removing the pending comment and restoring the reply target).
  Future<Failure?> submit(String text, {required Author author}) async {
    final articleId = _articleId;
    if (articleId == null) return null;
    final body = text.trim();
    if (body.isEmpty) return const Failure(FailureCodes.commentEmpty);
    if (body.length > CommentText.maxLength) return const Failure(FailureCodes.commentTooLong);
    final target = state.target;
    if (target != null && target.isEdit) return _saveEdit(target.comment, body);

    final replyTo = target?.comment;
    final pending = Comment(
      id: 'pending-${_pendingSeq++}',
      articleId: articleId,
      parentId: replyTo?.threadId,
      body: body,
      author: author,
      createdAt: _clock().toUtc(),
    );
    _postsInFlight++;
    emit(state.copyWith(
      threads: pending.isReply ? _withReply(state.threads, pending) : _insertTop(state.threads, [pending]),
      pendingIds: {...state.pendingIds, pending.id},
      total: () => _total(1),
      target: () => null,
    ));
    final result = await _post(articleId, body, replyToId: replyTo?.id);
    _postsInFlight--;
    if (isClosed) return null;
    return result.fold(
      (failure) {
        emit(state.copyWith(
          threads: _without(state.threads, pending),
          pendingIds: state.pendingIds.difference({pending.id}),
          total: () => _total(-1),
          target: () => state.target ?? target,
        ));
        return failure;
      },
      (comment) {
        emit(state.copyWith(
          threads: _confirm(state.threads, pending, comment),
          incoming: [for (final c in state.incoming) if (c.id != comment.id) c],
          pendingIds: state.pendingIds.difference({pending.id}),
        ));
        return null;
      },
    );
  }

  Future<Failure?> _saveEdit(Comment comment, String body) async {
    if (state.sending) return null;
    _busy.add(comment.id);
    emit(state.copyWith(sending: true));
    final result = await _edit(comment.id, body);
    _busy.remove(comment.id);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        emit(state.copyWith(sending: false));
        return failure;
      },
      (updated) {
        emit(state.copyWith(threads: _replace(state.threads, updated), sending: false, target: () => null));
        return null;
      },
    );
  }

  // ── Actions on a comment ─────────────────────────────────────────

  /// Likes or unlikes at once; rolls back when the API refuses. Null on success (or nothing to do).
  Future<Failure?> toggleLike(String commentId) async {
    final current = find(commentId);
    if (current == null || current.isPlaceholder || state.pendingIds.contains(commentId) || _busy.contains(commentId)) {
      return null;
    }
    final liked = !current.likedByMe;
    _busy.add(commentId);
    _patch(commentId, (c) => c.copyWith(likedByMe: liked, likeCount: math.max(0, c.likeCount + (liked ? 1 : -1))));
    final result = await _like(commentId, liked: liked);
    _busy.remove(commentId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        _patch(commentId, (c) => c.copyWith(likedByMe: current.likedByMe, likeCount: current.likeCount));
        return failure;
      },
      (like) {
        _patch(commentId, (c) => c.copyWith(likedByMe: like.liked, likeCount: like.likeCount));
        return null;
      },
    );
  }

  /// Deletes the viewer's own comment at once (a top-level comment with replies becomes a placeholder); restores it
  /// when the API refuses.
  Future<Failure?> delete(String commentId) => _removeOptimistically(commentId, () => _delete(commentId));

  /// The article's author pins (one at a time: the previous one is unpinned) or unpins a top-level comment. A pinned
  /// comment moves to the top.
  Future<Failure?> setPinned(String commentId, {required bool pinned}) async {
    if (_busy.contains(commentId)) return null;
    _busy.add(commentId);
    final result = await _pin(commentId, pinned: pinned);
    _busy.remove(commentId);
    if (isClosed) return null;
    return result.fold((failure) => failure, (comment) {
      var threads = _replace(_unpinOthers(state.threads, comment), comment);
      final index = threads.indexWhere((t) => t.id == comment.id);
      if (comment.isPinned && index > 0) threads = [threads[index], ...threads.where((t) => t.id != comment.id)];
      emit(state.copyWith(threads: threads));
      return null;
    });
  }

  /// Moderators (F22 hooks): hide and unhide apply once the API confirms (the moderator still sees the text); delete
  /// applies at once and is restored when refused.
  Future<Failure?> moderate(String commentId, ModerationAction action) async {
    if (action == ModerationAction.delete) {
      return _removeOptimistically(commentId, () => _moderate(commentId, action));
    }
    final current = find(commentId);
    if (current == null || _busy.contains(commentId)) return null;
    _busy.add(commentId);
    final result = await _moderate(commentId, action);
    _busy.remove(commentId);
    if (isClosed) return null;
    return result.fold((failure) => failure, (_) {
      final hide = action == ModerationAction.hide;
      final countChange = hide == current.isHidden ? 0 : (hide ? -1 : 1);
      emit(state.copyWith(
        threads: _patchIn(state.threads, commentId, (c) => c.copyWith(isHidden: hide)),
        total: () => _total(countChange),
      ));
      return null;
    });
  }

  Future<Failure?> _removeOptimistically(String commentId, Future<Result<void>> Function() call) async {
    final current = find(commentId);
    if (current == null || _busy.contains(commentId) || state.pendingIds.contains(commentId)) return null;
    final threadIndex = state.threads.indexWhere((t) => t.id == current.threadId);
    final before = threadIndex < 0 ? null : state.threads[threadIndex];
    final countChange = current.isHidden || current.isPlaceholder ? 0 : -1;
    _busy.add(commentId);
    emit(state.copyWith(threads: _removed(state.threads, current), total: () => _total(countChange)));
    final result = await call();
    _busy.remove(commentId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        if (before != null) {
          final threads = [...state.threads];
          final at = threads.indexWhere((t) => t.id == before.id);
          if (at >= 0) {
            threads[at] = before;
          } else {
            threads.insert(math.min(threadIndex, threads.length), before);
          }
          emit(state.copyWith(threads: threads, total: () => _total(-countChange)));
        }
        return failure;
      },
      (_) => null,
    );
  }

  /// The article's comment count from live counters (F27): it replaces [CommentsState.total].
  void syncTotal(int count) {
    if (state.total != null && state.total != count) emit(state.copyWith(total: () => count));
  }

  // ── Live (F27) ───────────────────────────────────────────────────

  /// The list is scrolled to (near) its top (the sheet), or its top is on screen (the reader's section): in "Newest",
  /// new comments then go straight to the top.
  void setNearTop(bool nearTop) => _nearTop = nearTop;

  /// The "N new comments" pill: they go to the top, highlighted.
  void showIncoming() {
    if (state.incoming.isEmpty) return;
    final known = _knownIds(includeIncoming: false);
    final fresh = [for (final c in state.incoming) if (!known.contains(c.id)) c]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final ids = {for (final c in fresh) c.id};
    emit(state.copyWith(threads: _insertTop(state.threads, fresh), incoming: const [], highlighted: {...state.highlighted, ...ids}));
    _unhighlightLater(ids);
  }

  Future<void> _onEvent(CommentEvent event) async {
    if (isClosed || state.status != CommentsStatus.ready) return;
    final id = event.commentId;
    if (_busy.contains(id)) return;
    switch (event.type) {
      case CommentEventType.created:
      case CommentEventType.replyCreated:
        if (_knownIds().contains(id) || !_fetching.add(id)) return;
        final result = await _get.one(id);
        _fetching.remove(id);
        final comment = result.valueOrNull;
        if (isClosed || comment == null || comment.isPlaceholder || state.status != CommentsStatus.ready) return;
        if (_knownIds().contains(comment.id)) return;
        // The viewer's own comment, posted from here: the POST answer puts it in place of the pending one.
        if (comment.canEdit && _postsInFlight > 0) return;
        _insertLive(comment);
      case CommentEventType.updated:
      case CommentEventType.deleted:
      case CommentEventType.liked:
      case CommentEventType.pinned:
        if (!_knownIds().contains(id)) return;
        final version = (_versions[id] ?? 0) + 1;
        _versions[id] = version;
        final result = await _get.one(id);
        if (isClosed || _versions[id] != version || _busy.contains(id) || state.status != CommentsStatus.ready) return;
        result.fold(
          (failure) {
            if (failure.statusCode == 404) _applyLive(id, null);
          },
          (comment) => _applyLive(id, comment),
        );
    }
  }

  void _insertLive(Comment comment) {
    if (comment.isReply) {
      if (_thread(comment.parentId!) == null) return; // a thread that isn't loaded here
      emit(state.copyWith(threads: _withReply(state.threads, comment), highlighted: {...state.highlighted, comment.id}));
      _unhighlightLater({comment.id});
    } else if (state.sort == CommentSort.newest && _nearTop) {
      emit(state.copyWith(threads: _insertTop(state.threads, [comment]), highlighted: {...state.highlighted, comment.id}));
      _unhighlightLater({comment.id});
    } else {
      emit(state.copyWith(incoming: [comment, ...state.incoming]));
    }
  }

  /// A refetched comment ([comment]), or null when it's gone, replaces what's shown. A placeholder without replies
  /// is left out, as in a fresh page.
  void _applyLive(String id, Comment? comment) {
    final incoming = [
      for (final c in state.incoming)
        if (c.id != id) c else if (comment != null && !comment.isPlaceholder) comment,
    ];
    final current = find(id);
    if (current == null) {
      emit(state.copyWith(incoming: incoming));
      return;
    }
    final List<CommentThread> threads;
    if (comment == null) {
      threads = _removed(state.threads, current);
    } else if (comment.isPlaceholder && (comment.isReply || !(_thread(id)?.hasReplies ?? false))) {
      threads = _removed(state.threads, current);
    } else {
      threads = _replace(_unpinOthers(state.threads, comment), comment);
    }
    emit(state.copyWith(threads: threads, incoming: incoming));
  }

  void _unhighlightLater(Set<String> ids) {
    late final Timer timer;
    timer = Timer(highlightFor, () {
      _timers.remove(timer);
      if (!isClosed) emit(state.copyWith(highlighted: state.highlighted.difference(ids)));
    });
    _timers.add(timer);
  }

  // ── Helpers ──────────────────────────────────────────────────────

  /// A comment shown in the list (top-level or reply), by id.
  Comment? find(String id) {
    for (final thread in state.threads) {
      if (thread.id == id) return thread.comment;
      for (final reply in thread.replies) {
        if (reply.id == id) return reply;
      }
    }
    return null;
  }

  CommentThread? _thread(String id) => state.threads.where((t) => t.id == id).firstOrNull;

  Set<String> _knownIds({bool includeIncoming = true}) => {
        for (final thread in state.threads) ...[thread.id, for (final r in thread.replies) r.id],
        if (includeIncoming) for (final c in state.incoming) c.id,
      };

  int? _total(int change) => state.total == null ? null : math.max(0, state.total! + change);

  void _updateThread(String id, CommentThread Function(CommentThread thread) change) =>
      emit(state.copyWith(threads: [for (final t in state.threads) t.id == id ? change(t) : t]));

  void _patch(String id, Comment Function(Comment comment) change) =>
      emit(state.copyWith(threads: _patchIn(state.threads, id, change)));

  static List<CommentThread> _patchIn(List<CommentThread> threads, String id, Comment Function(Comment comment) change) => [
        for (final t in threads)
          if (t.id == id)
            t.copyWith(comment: change(t.comment))
          else if (t.replies.any((r) => r.id == id))
            t.copyWith(replies: [for (final r in t.replies) r.id == id ? change(r) : r])
          else
            t,
      ];

  /// [comments] at the top, below a pinned comment.
  static List<CommentThread> _insertTop(List<CommentThread> threads, List<Comment> comments) {
    var at = threads.indexWhere((t) => !t.comment.isPinned);
    if (at < 0) at = threads.length;
    return [...threads.take(at), for (final c in comments) CommentThread.of(c), ...threads.skip(at)];
  }

  /// A new [reply] (the viewer's, or one that arrived live) added to its thread (counted in its `replyCount`), unless
  /// the thread already has it. It shows at once, even while older replies are hidden.
  List<CommentThread> _withReply(List<CommentThread> threads, Comment reply) => [
        for (final t in threads)
          if (t.id == reply.parentId && t.replies.every((r) => r.id != reply.id))
            t.copyWith(
              comment: t.comment.copyWith(replyCount: t.comment.replyCount + 1),
              replies: _mergeReplies(t.replies, [reply]),
              alwaysShown: {...t.alwaysShown, reply.id},
            )
          else
            t,
      ];

  /// Replies by id ([fetched] win, except over the viewer's in-flight changes), oldest first; pending ones last.
  List<Comment> _mergeReplies(List<Comment> current, List<Comment> fetched) {
    final byId = {for (final r in current) r.id: r};
    for (final r in fetched) {
      if (_busy.contains(r.id)) {
        byId.putIfAbsent(r.id, () => r);
      } else {
        byId[r.id] = r;
      }
    }
    final pending = state.pendingIds;
    return [
      ...byId.values.where((r) => !pending.contains(r.id)).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      ...byId.values.where((r) => pending.contains(r.id)),
    ];
  }

  /// [comment] replaces the shown one with the same id; a top-level comment keeps its thread's replies.
  static List<CommentThread> _replace(List<CommentThread> threads, Comment comment) =>
      _patchIn(threads, comment.id, (_) => comment.copyWith(replies: const []));

  /// When [comment] is pinned, no other comment is.
  static List<CommentThread> _unpinOthers(List<CommentThread> threads, Comment comment) => !comment.isPinned
      ? threads
      : [
          for (final t in threads)
            t.id != comment.id && t.comment.isPinned ? t.copyWith(comment: t.comment.copyWith(isPinned: false)) : t,
        ];

  /// [comment] gone from the list: a reply leaves its thread, a top-level comment with replies becomes a placeholder,
  /// one without replies leaves the list.
  static List<CommentThread> _removed(List<CommentThread> threads, Comment comment) {
    if (comment.isReply) {
      return [
        for (final t in threads)
          if (t.id == comment.parentId && t.replies.any((r) => r.id == comment.id))
            t.copyWith(
              comment: t.comment.copyWith(replyCount: math.max(0, t.comment.replyCount - 1)),
              replies: [for (final r in t.replies) if (r.id != comment.id) r],
              alwaysShown: t.alwaysShown.difference({comment.id}),
            )
          else
            t,
      ];
    }
    return [
      for (final t in threads)
        if (t.id != comment.id)
          t
        else if (t.hasReplies)
          t.copyWith(comment: t.comment.asDeletedPlaceholder().copyWith(replies: const [])),
    ];
  }

  /// [pending] taken out (it wasn't posted).
  static List<CommentThread> _without(List<CommentThread> threads, Comment pending) => pending.isReply
      ? _removed(threads, pending)
      : [for (final t in threads) if (t.id != pending.id) t];

  /// The API's [comment] in place of [pending]; when it's already shown (its live event came first) the pending one
  /// just goes, and when the pending one is gone (the list reloaded) it's added.
  List<CommentThread> _confirm(List<CommentThread> threads, Comment pending, Comment comment) {
    final shown = _knownIds(includeIncoming: false).contains(comment.id);
    if (shown) {
      // A reply page fetched meanwhile already had it: the viewer's reply still shows.
      final rest = _without(threads, pending);
      return !comment.isReply
          ? rest
          : [for (final t in rest) t.id == comment.parentId ? t.copyWith(alwaysShown: {...t.alwaysShown, comment.id}) : t];
    }
    final hasPending = threads.any((t) => t.id == pending.id || t.replies.any((r) => r.id == pending.id));
    if (!hasPending) return comment.isReply ? _withReply(threads, comment) : _insertTop(threads, [comment]);
    if (!comment.isReply) {
      return [for (final t in threads) t.id == pending.id ? CommentThread.of(comment) : t];
    }
    return [
      for (final t in threads)
        if (t.replies.any((r) => r.id == pending.id))
          t.copyWith(
            replies: [for (final r in t.replies) r.id == pending.id ? comment.copyWith(replies: const []) : r],
            alwaysShown: {...t.alwaysShown.difference({pending.id}), comment.id},
          )
        else
          t,
    ];
  }

  @override
  Future<void> close() async {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    await _events?.cancel();
    _events = null;
    return super.close();
  }
}
