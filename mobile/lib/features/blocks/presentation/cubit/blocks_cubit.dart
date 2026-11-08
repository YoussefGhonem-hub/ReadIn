import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../domain/entities/blocks.dart';
import '../../domain/usecases/block_usecases.dart';

/// The people the viewer blocked or unblocked in this app session (F36). Screens loaded before a block still show
/// that person's cards and comments; they ask here and leave them out at once.
class BlocksState extends Equatable {
  const BlocksState({this.users = const {}, this.pending = const {}});

  /// Blocked (true) or unblocked (false) since the session started.
  final Map<String, bool> users;

  /// Requests in flight, by user id.
  final Set<String> pending;

  bool isBlocked(String userId, {bool fallback = false}) => users[userId] ?? fallback;

  bool isPending(String userId) => pending.contains(userId);

  /// A list leaves [card] out: its writer, or the reposter who placed it, was blocked in this session.
  bool hides(ArticleCard card) =>
      (card.author != null && isBlocked(card.author!.id)) ||
      (card.repostedBy != null && card.repostedBy!.othersCount == 0 && isBlocked(card.repostedBy!.user.id));

  BlocksState copyWith({Map<String, bool>? users, Set<String>? pending}) =>
      BlocksState(users: users ?? this.users, pending: pending ?? this.pending);

  @override
  List<Object?> get props => [users, pending];
}

/// Block and unblock (F36), shared by every screen: the person's cards and comments leave what is on screen at once,
/// their profile and articles read "isn't available" with Unblock, and a block ends the follows both ways
/// ([FollowsCubit.apply]); the Undo of a block that ended the viewer's follow restores it. Changes apply at once and
/// roll back when the API refuses them. Signing out or switching accounts clears it.
@lazySingleton
class BlocksCubit extends Cubit<BlocksState> {
  BlocksCubit(this._setBlocked, SessionCubit session, this._follows) : super(const BlocksState()) {
    _onSession(session.state);
    _session = session.stream.listen(_onSession);
  }

  final SetUserBlocked _setBlocked;
  final FollowsCubit _follows;
  StreamSubscription<SessionState>? _session;
  String? _userId;
  bool _known = false;

  // Bumped when the account changes, so an answer for the previous account is dropped.
  int _version = 0;

  /// A failure for a second tap while the first request runs; [showActionFailure] shows nothing for it.
  static const _busy = Failure(FailureCodes.requestCancelled);

  void _onSession(SessionState session) {
    if (session.status == SessionStatus.unknown) return;
    if (session.isAuthenticated && session.me == null) return;
    final userId = session.isAuthenticated ? session.me!.id : null;
    if (_known && userId == _userId) return;
    final switched = _known;
    _known = true;
    _userId = userId;
    if (switched) {
      _version++;
      emit(const BlocksState());
    }
  }

  /// A block the API already made, with a report (`alsoBlock`, F22): the screens follow it at once.
  void markBlocked(String userId) {
    emit(state.copyWith(users: {...state.users, userId: true}));
    _follows.apply(userId, isFollowing: false);
  }

  /// `PUT /users/{id}/block`: their content leaves the screens at once and the follows end both ways.
  Future<Result<UserBlockState>> block(String userId) => _set(userId, blocked: true);

  /// `DELETE /users/{id}/block`; [restoreFollow] follows them again (the toast's Undo).
  Future<Result<UserBlockState>> unblock(String userId, {bool restoreFollow = false}) =>
      _set(userId, blocked: false, restoreFollow: restoreFollow);

  Future<Result<UserBlockState>> _set(String userId, {required bool blocked, bool restoreFollow = false}) async {
    if (state.isPending(userId)) return const Err(_busy);
    final before = state.users[userId];
    final version = _version;
    emit(state.copyWith(users: {...state.users, userId: blocked}, pending: {...state.pending, userId}));
    final result = await _setBlocked(userId, blocked: blocked, restoreFollow: restoreFollow);
    if (isClosed || version != _version) return result;
    final pending = {...state.pending}..remove(userId);
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(users: {...state.users, userId: value.isBlocked}, pending: pending));
        if (value.isBlocked) {
          _follows.apply(userId, isFollowing: false);
        } else if (restoreFollow) {
          _follows.apply(userId, isFollowing: true);
        }
      case Err():
        final users = {...state.users};
        if (before == null) {
          users.remove(userId);
        } else {
          users[userId] = before;
        }
        emit(state.copyWith(users: users, pending: pending));
    }
    return result;
  }

  @override
  Future<void> close() async {
    await _session?.cancel();
    return super.close();
  }
}
