import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/push/push_service.dart';
import '../core/realtime/realtime_service.dart';
import '../features/auth/presentation/session/session_cubit.dart';

/// Keeps Firebase in step with the ReadIn session (SPEC §21): the unread badge
/// and this device's push registration follow the signed-in user, and the
/// Realtime Database socket is paused while the app is in the background.
class LiveSessionBridge {
  LiveSessionBridge(this._session, this._realtime, this._push);

  final SessionCubit _session;
  final RealtimeService _realtime;
  final PushService _push;
  StreamSubscription<SessionState>? _subscription;
  AppLifecycleListener? _lifecycle;
  String? _userId;
  bool _following = false;

  void start() {
    _follow(_session.state);
    _subscription = _session.stream.listen(_follow);
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_realtime.setForeground(true)),
      onPause: () => unawaited(_realtime.setForeground(false)),
    );
  }

  void _follow(SessionState state) {
    if (state.status == SessionStatus.unknown) return; // the persisted session isn't restored yet
    final userId = state.isAuthenticated ? state.me?.id : null;
    if (_following && userId == _userId) return;
    _following = true;
    _userId = userId;
    unawaited(_realtime.followUser(userId));
    unawaited(_push.followUser(userId));
  }

  Future<void> dispose() async {
    _lifecycle?.dispose();
    await _subscription?.cancel();
  }
}
