import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/profile_usecases.dart';

enum ProfileStatus { loading, ready, failure }

class ProfileState extends Equatable {
  const ProfileState({this.status = ProfileStatus.loading, this.profile, this.failure});

  final ProfileStatus status;
  final UserProfile? profile;
  final Failure? failure;

  /// Deleted, suspended or never existed (`404 user.not_found`).
  bool get notFound => status == ProfileStatus.failure && (failure?.code == FailureCodes.userNotFound || failure?.statusCode == 404);

  @override
  List<Object?> get props => [status, profile, failure];
}

/// One profile (F14): `GET /users/{username}`. The follower count follows the viewer's follow / unfollow here, and the
/// own profile's "following" count follows the follows made anywhere in the app.
@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._getProfile, this._follows) : super(const ProfileState()) {
    _subscription = _follows.changes.listen(_onFollowChange);
  }

  final GetProfile _getProfile;
  final FollowsCubit _follows;
  late final StreamSubscription<FollowChange> _subscription;
  String? _username;

  /// Incremented on every load so an older answer is dropped.
  int _generation = 0;

  Future<void> load(String username) async {
    _username = username;
    final generation = ++_generation;
    emit(const ProfileState());
    final result = await _getProfile(username);
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) => emit(ProfileState(status: ProfileStatus.failure, failure: failure)),
      _accept,
    );
  }

  /// Pull to refresh, or back from editing: the profile stays on screen until the new one arrives.
  Future<void> refresh() async {
    final username = state.profile?.username ?? _username;
    if (username == null) return;
    if (state.profile == null) return load(username);
    final generation = ++_generation;
    final result = await _getProfile(username);
    if (generation != _generation || isClosed) return;
    result.fold((_) {}, _accept); // a failed refresh keeps what is shown
  }

  void _accept(UserProfile profile) {
    if (!profile.isMe) _follows.seed({profile.id: profile.isFollowing});
    emit(ProfileState(status: ProfileStatus.ready, profile: profile));
  }

  void _onFollowChange(FollowChange change) {
    final profile = state.profile;
    if (profile == null || isClosed) return;
    final step = change.isFollowing ? 1 : -1;
    if (profile.isMe) {
      final following = profile.stats.following + step;
      emit(ProfileState(status: state.status, profile: profile.copyWith(stats: profile.stats.copyWith(following: following < 0 ? 0 : following))));
    } else if (change.userId == profile.id && change.isFollowing != profile.isFollowing) {
      final followers = _follows.state.users[profile.id]?.followerCount ?? profile.stats.followers + step;
      emit(ProfileState(
        status: state.status,
        profile: profile.copyWith(isFollowing: change.isFollowing, stats: profile.stats.copyWith(followers: followers < 0 ? 0 : followers)),
      ));
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
