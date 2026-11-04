import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'live_connection.dart';
import 'realtime_token_api.dart';

enum ReactionType { insightful, love, fire, mindBlown }

/// Live counters of one article (`/live/articles/{id}`). They are totals, not
/// deltas, so the user's own optimistic changes are never counted twice. A
/// field is null until the API has published it; callers keep the REST value.
class LiveArticleCounts extends Equatable {
  const LiveArticleCounts({this.reactions, this.commentCount, this.saveCount});

  final Map<ReactionType, int>? reactions;
  final int? commentCount;
  final int? saveCount;

  int? get reactionCount => reactions?.values.fold<int>(0, (sum, count) => sum + count);

  @override
  List<Object?> get props => [reactions, commentCount, saveCount];
}

enum CommentEventType {
  created('comment.created'),
  updated('comment.updated'),
  deleted('comment.deleted'),
  replyCreated('reply.created'),
  liked('comment.liked'),
  pinned('comment.pinned');

  const CommentEventType(this.wire);

  final String wire;
}

/// A signal that a comment changed. It never carries the text: the comment is fetched from the REST API.
class CommentEvent extends Equatable {
  const CommentEvent({required this.id, required this.type, required this.commentId, this.parentId, required this.at});

  final String id;
  final CommentEventType type;
  final String commentId;
  final String? parentId;
  final int at;

  @override
  List<Object?> get props => [id, type, commentId, parentId, at];
}

/// Live updates from the Firebase Realtime Database (SPEC §21.2, F27): article
/// counters, comment events, the "new articles" signal and the signed-in user's
/// unread-notification badge. The database carries signals only; content always
/// comes from the REST API, and everything keeps working through REST without it.
@lazySingleton
class RealtimeService {
  RealtimeService(this._connector, this._tokens);

  final LiveConnector _connector;
  final RealtimeTokenApi _tokens;

  /// Article and user ids become database path segments, so anything outside a GUID's alphabet is refused.
  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  Future<LiveConnection?>? _connection;
  Future<void> _authQueue = Future.value();
  String? _userId;
  int _generation = 0;
  StreamSubscription<Object?>? _userSubscription;

  /// `/live/users/{id}/unreadNotifications`; 0 for guests and until the first value arrives.
  final ValueNotifier<int> unreadNotifications = ValueNotifier(0);

  /// True once the signed-in user's [unreadNotifications] arrived from the database, until the user changes or the
  /// listener ends (e.g. permission denied). While false the badge comes from `GET /me/notifications/unread-count`.
  final ValueNotifier<bool> unreadLive = ValueNotifier(false);

  /// Live counters of an article while the stream is listened to.
  Stream<LiveArticleCounts> watchArticle(String articleId) {
    if (!_safeId.hasMatch(articleId)) return const Stream.empty();
    final base = 'live/articles/$articleId';
    // Separate listeners, so the article's event list is never downloaded with its counters.
    return _live((connection) {
      Map<ReactionType, int>? reactions;
      int? comments;
      int? saves;
      final subscriptions = <StreamSubscription<Object?>>[];
      late final StreamController<LiveArticleCounts> controller;
      void emit() => controller.add(LiveArticleCounts(reactions: reactions, commentCount: comments, saveCount: saves));
      controller = StreamController(
        onListen: () => subscriptions.addAll([
          connection.onValue('$base/reactions').listen((value) {
            reactions = _toReactions(value);
            emit();
          }),
          connection.onValue('$base/commentCount').listen((value) {
            comments = _toCount(value);
            emit();
          }),
          connection.onValue('$base/saveCount').listen((value) {
            saves = _toCount(value);
            emit();
          }),
        ]),
        onCancel: () => Future.wait(subscriptions.map((subscription) => subscription.cancel())),
      );
      return controller.stream;
    });
  }

  /// Comment events of an article from now on (older ones are skipped).
  Stream<CommentEvent> commentEvents(String articleId) {
    if (!_safeId.hasMatch(articleId)) return const Stream.empty();
    // asyncExpand rather than `await for`: cancelling must stop the listener at once, not after the next event.
    return _live(
      (connection) => Stream.fromFuture(connection.serverTime())
          .asyncExpand((since) => connection.onChildAddedSince('live/articles/$articleId/events', 'at', since))
          .expand((child) => [?_toCommentEvent(child.$1, child.$2)]),
    );
  }

  /// `/live/feed/latestPublishedAt` as epoch ms, or null when unknown.
  Stream<int?> latestPublished() => _live((connection) => connection.onValue('live/feed/latestPublishedAt').map(_toTimestamp));

  /// Follows the badge of [userId] (null = signed out). Signing out of ReadIn also signs out of Firebase.
  Future<void> followUser(String? userId) async {
    if (userId == _userId) return;
    final generation = ++_generation;
    _userId = userId;
    await _userSubscription?.cancel();
    _userSubscription = null;
    unreadNotifications.value = 0;
    unreadLive.value = false;
    bool isCurrent() => generation == _generation;

    if (userId == null && _connection == null) return; // never connected: nothing to sign out of
    final connection = await _connect();
    if (connection == null || !isCurrent()) return;
    await _enqueue(connection.signOut).catchError((Object _) {});
    if (userId == null || !_safeId.hasMatch(userId)) return;
    try {
      final token = await _tokens.token();
      if (!isCurrent()) return;
      await _enqueue(() => connection.signIn(token.token));
    } catch (_) {
      return; // no token (offline, older API): the badge waits for the next sign-in, REST still works
    }
    if (!isCurrent()) return;
    _userSubscription = connection.onValue('live/users/$userId/unreadNotifications').listen(
      (value) {
        if (!isCurrent()) return;
        unreadNotifications.value = _toCount(value) ?? 0;
        unreadLive.value = true;
      },
      onDone: () {
        if (isCurrent()) unreadLive.value = false;
      },
    );
  }

  /// Pauses the socket while the app is in the background (SPEC §21.2).
  Future<void> setForeground(bool foreground) async => (await _connection)?.setOnline(foreground);

  Stream<T> _live<T>(Stream<T> Function(LiveConnection connection) open) async* {
    final connection = await _connect();
    if (connection != null) yield* open(connection);
  }

  Future<LiveConnection?> _connect() => _connection ??= _connector.open().then<LiveConnection?>(
        (connection) => connection,
        onError: (Object error) {
          debugPrint('Realtime Database unavailable, staying on REST: $error');
          return null;
        },
      );

  /// Custom-token sign-ins and sign-outs run one after another, so a quick account switch cannot interleave them.
  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _authQueue.then((_) => operation());
    _authQueue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}

int? _toCount(Object? value) => value is num && value.isFinite && value >= 0 ? value.floor() : null;

int? _toTimestamp(Object? value) => switch (value) {
      final num number when number.isFinite => number.toInt(),
      final String text => DateTime.tryParse(text)?.millisecondsSinceEpoch,
      _ => null,
    };

Map<ReactionType, int>? _toReactions(Object? value) {
  if (value is! Map) return null;
  return {for (final type in ReactionType.values) type: _toCount(value[type.name]) ?? 0};
}

CommentEvent? _toCommentEvent(String key, Object? value) {
  if (value is! Map) return null;
  final type = CommentEventType.values.where((t) => t.wire == value['type']).firstOrNull;
  final commentId = value['commentId'];
  if (type == null || commentId is! String) return null;
  final parentId = value['parentId'];
  return CommentEvent(
    id: key,
    type: type,
    commentId: commentId,
    parentId: parentId is String ? parentId : null,
    at: _toTimestamp(value['at']) ?? 0,
  );
}
