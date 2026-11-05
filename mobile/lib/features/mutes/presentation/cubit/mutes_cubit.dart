import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../domain/entities/mutes.dart';
import '../../domain/usecases/mute_usecases.dart';

/// The viewer's mutes and "show less" marks as this app session changed them (F28). They are newer than what any
/// screen loaded (`isAuthorMuted`, `isFieldMuted`, `isTopicMuted`), so screens ask here first and fall back to their
/// own flags.
class MutesState extends Equatable {
  const MutesState({
    this.users = const {},
    this.fields = const {},
    this.topics = const {},
    this.showLess = const {},
    this.pending = const {},
  });

  /// Writers muted (true) or unmuted (false) since the session started.
  final Map<String, bool> users;

  /// Fields and topics muted (true) or unmuted (false): every id an answer named, and the ones it no longer names.
  final Map<String, bool> fields;
  final Map<String, bool> topics;

  /// Articles marked "قلّل من النوع ده" in this session (Undo takes them out again).
  final Set<String> showLess;

  /// Requests in flight, as `user:{id}`, `field:{id}`, `topic:{id}` and `article:{id}`.
  final Set<String> pending;

  bool isUserMuted(String userId, {bool fallback = false}) => users[userId] ?? fallback;

  bool isFieldMuted(String fieldId, {bool fallback = false}) => fields[fieldId] ?? fallback;

  bool isTopicMuted(String topicId, {bool fallback = false}) => topics[topicId] ?? fallback;

  bool isPending(String key) => pending.contains(key);

  /// Whether a list that applies mutes leaves [card] out now: its writer, field or topic is muted, or it was marked
  /// "show less". A field page shows its own field and the topic picked on it ([keepFieldId], [keepTopicId]).
  bool hides(ArticleCard card, {String? keepFieldId, String? keepTopicId}) {
    if (showLess.contains(card.id)) return true;
    if (card.author case final author? when isUserMuted(author.id, fallback: card.isAuthorMuted)) return true;
    if (card.field.id != keepFieldId && isFieldMuted(card.field.id, fallback: card.isFieldMuted)) return true;
    final topic = card.topic;
    return topic != null && topic.id != keepTopicId && isTopicMuted(topic.id, fallback: card.isTopicMuted);
  }

  MutesState copyWith({
    Map<String, bool>? users,
    Map<String, bool>? fields,
    Map<String, bool>? topics,
    Set<String>? showLess,
    Set<String>? pending,
  }) =>
      MutesState(
        users: users ?? this.users,
        fields: fields ?? this.fields,
        topics: topics ?? this.topics,
        showLess: showLess ?? this.showLess,
        pending: pending ?? this.pending,
      );

  @override
  List<Object?> get props => [users, fields, topics, showLess, pending];
}

/// Mute a writer, a field or a topic, and "show less" (F28), shared by every screen: lists hide the cards at once
/// ([MutesState.hides]) and bring them back in place on Undo, and the reader and profile show the "انت كاتم الكاتب ده"
/// banner. Changes apply at once and roll back when the API refuses them. A mute ends the viewer's follow and an Undo
/// can restore it ([FollowsCubit.apply]); following a writer ends their mute. Signing out or switching accounts
/// clears it.
@lazySingleton
class MutesCubit extends Cubit<MutesState> {
  MutesCubit(this._setUserMuted, this._setContentMuted, this._setShowLess, SessionCubit session, this._follows)
      : super(const MutesState()) {
    _onSession(session.state);
    _session = session.stream.listen(_onSession);
    _followChanges = _follows.changes.listen(_onFollowChange);
  }

  final SetUserMuted _setUserMuted;
  final SetContentMuted _setContentMuted;
  final SetShowLess _setShowLess;
  final FollowsCubit _follows;
  StreamSubscription<SessionState>? _session;
  StreamSubscription<FollowChange>? _followChanges;
  String? _userId;
  bool _known = false;

  // Bumped when the account changes, so an answer for the previous account is dropped.
  int _version = 0;

  /// A failure for a second tap while the first request runs; [showActionFailure] shows nothing for it.
  static const _busy = Failure(FailureCodes.requestCancelled);

  void _onSession(SessionState session) {
    if (session.status == SessionStatus.unknown) return; // the stored session isn't restored yet
    if (session.isAuthenticated && session.me == null) return; // restored offline: the account isn't known yet
    final userId = session.isAuthenticated ? session.me!.id : null;
    if (_known && userId == _userId) return;
    final switched = _known;
    _known = true;
    _userId = userId;
    if (switched) {
      _version++;
      emit(const MutesState());
    }
  }

  /// Following a writer ends their mute on the server (F28): every mute, also one this session only knows from a
  /// screen's flag (`isAuthorMuted`, `ProfileDto.isMuted`), so it is recorded as unmuted whatever was known before.
  void _onFollowChange(FollowChange change) {
    if (change.isFollowing && state.users[change.userId] != false) {
      emit(state.copyWith(users: {...state.users, change.userId: false}));
    }
  }

  /// `PUT /users/{id}/mute`: the writer's cards leave the lists at once. The answer says whether it ended a follow
  /// (`followRemoved`), for the Undo ([unmuteUser] with `restoreFollow`).
  Future<Result<UserMuteState>> muteUser(String userId) => _setUser(userId, muted: true);

  /// `DELETE /users/{id}/mute`; [restoreFollow] follows the writer again (the Undo of a mute that ended a follow).
  Future<Result<UserMuteState>> unmuteUser(String userId, {bool restoreFollow = false}) =>
      _setUser(userId, muted: false, restoreFollow: restoreFollow);

  Future<Result<UserMuteState>> _setUser(String userId, {required bool muted, bool restoreFollow = false}) async {
    final key = 'user:$userId';
    if (state.isPending(key)) return const Err(_busy);
    final before = state.users[userId];
    final version = _version;
    emit(state.copyWith(users: {...state.users, userId: muted}, pending: {...state.pending, key}));
    final result = await _setUserMuted(userId, muted: muted, restoreFollow: restoreFollow);
    if (isClosed || version != _version) return result;
    final pending = {...state.pending}..remove(key);
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(users: {...state.users, userId: value.isMuted}, pending: pending));
        _follows.apply(userId, isFollowing: value.isFollowing, followerCount: value.followerCount);
      case Err():
        emit(state.copyWith(users: _restore(state.users, userId, before), pending: pending));
    }
    return result;
  }

  /// `PUT|DELETE /me/mutes/fields/{id}`: the field's cards (its topics' too) leave the lists, or come back.
  Future<Failure?> setFieldMuted(String fieldId, {required bool muted}) =>
      _setContent('field:$fieldId', fieldId, muted: muted, topic: false);

  /// `PUT|DELETE /me/mutes/topics/{id}`.
  Future<Failure?> setTopicMuted(String topicId, {required bool muted}) =>
      _setContent('topic:$topicId', topicId, muted: muted, topic: true);

  Future<Failure?> _setContent(String key, String id, {required bool muted, required bool topic}) async {
    if (state.isPending(key)) return _busy;
    final current = topic ? state.topics : state.fields;
    final before = current[id];
    final version = _version;
    final next = {...current, id: muted};
    emit(topic
        ? state.copyWith(topics: next, pending: {...state.pending, key})
        : state.copyWith(fields: next, pending: {...state.pending, key}));
    final result = topic ? await _setContentMuted.topic(id, muted: muted) : await _setContentMuted.field(id, muted: muted);
    if (isClosed || version != _version) return result.failureOrNull;
    final pending = {...state.pending}..remove(key);
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(
          fields: _merge(state.fields, value.fieldIds),
          topics: _merge(state.topics, value.topicIds),
          pending: pending,
        ));
        return null;
      case Err(:final failure):
        final rolled = _restore(topic ? state.topics : state.fields, id, before);
        emit(topic ? state.copyWith(topics: rolled, pending: pending) : state.copyWith(fields: rolled, pending: pending));
        return failure;
    }
  }

  /// `PUT /articles/{id}/show-less`: the card leaves the lists at once.
  Future<Failure?> showLess(String articleId) => _setShowLessMark(articleId, marked: true);

  /// `DELETE /articles/{id}/show-less`: the toast's Undo brings the card back in place.
  Future<Failure?> undoShowLess(String articleId) => _setShowLessMark(articleId, marked: false);

  Future<Failure?> _setShowLessMark(String articleId, {required bool marked}) async {
    final key = 'article:$articleId';
    if (state.isPending(key)) return _busy;
    final version = _version;
    Set<String> withMark(bool on) => on ? {...state.showLess, articleId} : ({...state.showLess}..remove(articleId));
    final before = state.showLess.contains(articleId);
    emit(state.copyWith(showLess: withMark(marked), pending: {...state.pending, key}));
    final result = await _setShowLess(articleId, showLess: marked);
    if (isClosed || version != _version) return result.failureOrNull;
    final pending = {...state.pending}..remove(key);
    final failure = result.failureOrNull;
    emit(state.copyWith(showLess: failure == null ? null : withMark(before), pending: pending));
    return failure;
  }

  /// Every id in [muted] is muted; the ones [known] marked muted but [muted] no longer names are not.
  static Map<String, bool> _merge(Map<String, bool> known, List<String> muted) => {
        for (final id in known.keys) id: false,
        for (final id in muted) id: true,
      };

  static Map<String, bool> _restore(Map<String, bool> map, String id, bool? before) {
    final next = {...map};
    if (before == null) {
      next.remove(id);
    } else {
      next[id] = before;
    }
    return next;
  }

  @override
  Future<void> close() async {
    await _session?.cancel();
    await _followChanges?.cancel();
    return super.close();
  }
}
