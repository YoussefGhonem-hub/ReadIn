import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/article/data/datasources/article_offline_store.dart';
import '../features/article/presentation/cubit/engagement_cubit.dart';
import '../features/auth/presentation/session/session_cubit.dart';
import '../features/follow/presentation/cubit/follows_cubit.dart';
import '../features/saved/presentation/cubit/collections_cubit.dart';

/// Keeps the viewer's reactions, saves, follows, collections and offline copies with the account they belong to:
/// signing out or switching accounts clears them (F10, F12, F13, F25).
class SocialSessionBridge {
  SocialSessionBridge(this._session, this._engagement, this._follows, this._collections, this._offline);

  final SessionCubit _session;
  final EngagementCubit _engagement;
  final FollowsCubit _follows;
  final CollectionsCubit _collections;
  final ArticleOfflineStore _offline;
  StreamSubscription<SessionState>? _subscription;
  bool _known = false;
  String? _userId;

  /// The latest clean-up of the offline copies.
  @visibleForTesting
  Future<void>? lastClaim;

  void start() {
    _onSession(_session.state);
    _subscription = _session.stream.listen(_onSession);
  }

  void _onSession(SessionState state) {
    if (state.status == SessionStatus.unknown) return; // the stored session isn't restored yet
    // Restored offline: still signed in, but the account isn't known yet. Keep everything (offline reading).
    if (state.isAuthenticated && state.me == null) return;
    final userId = state.isAuthenticated ? state.me!.id : null;
    if (_known && userId == _userId) return;
    final switched = _known;
    _known = true;
    _userId = userId;
    if (switched) {
      _engagement.reset();
      _follows.reset();
      _collections.reset();
    }
    lastClaim = _offline.claim(userId).catchError((Object error) => debugPrint('Offline copies not cleared: $error'));
  }

  Future<void> dispose() async => _subscription?.cancel();
}
