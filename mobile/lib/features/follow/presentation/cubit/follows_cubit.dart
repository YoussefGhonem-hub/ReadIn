import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/usecases/follow_usecases.dart';

/// Whether the viewer follows one user, and the follower count when the API said it.
class FollowEntry extends Equatable {
  const FollowEntry({required this.isFollowing, this.followerCount, this.pending = false});

  final bool isFollowing;
  final int? followerCount;

  /// A follow / unfollow request is in flight: the button ignores taps (no double submits).
  final bool pending;

  @override
  List<Object?> get props => [isFollowing, followerCount, pending];
}

class FollowsState extends Equatable {
  const FollowsState([this.users = const {}]);

  final Map<String, FollowEntry> users;

  /// [fallback] is what the screen loaded (e.g. `isFollowingAuthor`), for users this store hasn't heard of.
  bool isFollowing(String userId, {bool fallback = false}) => users[userId]?.isFollowing ?? fallback;

  bool isPending(String userId) => users[userId]?.pending ?? false;

  @override
  List<Object?> get props => [users];
}

/// A follow or unfollow the API confirmed.
class FollowChange extends Equatable {
  const FollowChange(this.userId, {required this.isFollowing});

  final String userId;
  final bool isFollowing;

  @override
  List<Object?> get props => [userId, isFollowing];
}

/// The viewer's follows across every screen (F12): the reader's author row, suggested writers and later the profile.
/// Changes apply at once and roll back when the API refuses them.
@lazySingleton
class FollowsCubit extends Cubit<FollowsState> {
  FollowsCubit(this._setFollowing) : super(const FollowsState());

  final SetFollowing _setFollowing;
  final _changes = StreamController<FollowChange>.broadcast();

  /// Follows and unfollows the API confirmed (the Following feed reloads after them).
  Stream<FollowChange> get changes => _changes.stream;

  /// What a screen just loaded, unless a request for that user is in flight.
  void seed(Map<String, bool> following) {
    final next = {...state.users};
    var changed = false;
    following.forEach((userId, isFollowing) {
      final current = next[userId];
      if ((current?.pending ?? false) || current?.isFollowing == isFollowing) return;
      next[userId] = FollowEntry(isFollowing: isFollowing, followerCount: current?.followerCount);
      changed = true;
    });
    if (changed) emit(FollowsState(next));
  }

  Future<Failure?> toggle(String userId, {bool fallback = false}) =>
      setFollowing(userId, follow: !state.isFollowing(userId, fallback: fallback));

  /// Null on success (or nothing to do), else the failure after rolling back.
  Future<Failure?> setFollowing(String userId, {required bool follow}) async {
    final before = state.users[userId];
    if ((before?.pending ?? false) || before?.isFollowing == follow) return null;
    _put(userId, FollowEntry(isFollowing: follow, followerCount: before?.followerCount, pending: true));
    final result = await _setFollowing(userId, follow: follow);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        final users = {...state.users};
        if (before == null) {
          users.remove(userId);
        } else {
          users[userId] = before;
        }
        emit(FollowsState(users));
        return failure;
      },
      (followState) {
        _put(userId, FollowEntry(isFollowing: followState.isFollowing, followerCount: followState.followerCount));
        _changes.add(FollowChange(userId, isFollowing: followState.isFollowing));
        return null;
      },
    );
  }

  /// A follow another action changed on the server (F28: muting a writer ends the follow, its Undo restores it), with
  /// the writer's new follower count. Ignored while a follow request for that user is in flight.
  void apply(String userId, {required bool isFollowing, int? followerCount}) {
    final current = state.users[userId];
    if (current?.pending ?? false) return;
    _put(userId, FollowEntry(isFollowing: isFollowing, followerCount: followerCount ?? current?.followerCount));
  }

  /// Another account (or a guest) is using the app.
  void reset() => emit(const FollowsState());

  void _put(String userId, FollowEntry entry) {
    if (!isClosed) emit(FollowsState({...state.users, userId: entry}));
  }

  @override
  Future<void> close() async {
    await _changes.close();
    return super.close();
  }
}
